import QtQuick
import Quickshell
import qs.Services

// Kalkylator för DMS-launchern.
//
// Tolkar uttrycket själv med en tokenizer och shunting-yard i stället för att
// anropa eval(). Launchern kör getItems() på varje tangenttryckning, så det
// som skrivs in är delvis skräp hela tiden — eval() på den strömmen vore både
// en säkerhetsrisk och opålitligt. Parsern här kan bara räkna, och returnerar
// null på allt den inte förstår.
Item {
    id: root

    property var pluginService: null
    property string trigger: ""

    signal itemsChanged()

    readonly property var _constants: ({
        "pi": Math.PI,
        "e": Math.E,
        "tau": Math.PI * 2
    })

    // Antal argument per funktion. Ligger i en tabell så att parsern kan
    // avvisa okända namn direkt — det är den som gör att "firefox" inte
    // råkar tolkas som matematik.
    readonly property var _funcs: ({
        "sqrt": 1, "cbrt": 1, "abs": 1, "sign": 1,
        "round": 1, "floor": 1, "ceil": 1,
        "ln": 1, "log": 1, "log2": 1, "log10": 1, "exp": 1,
        "sin": 1, "cos": 1, "tan": 1, "asin": 1, "acos": 1, "atan": 1,
        "min": 2, "max": 2, "pow": 2, "mod": 2, "hypot": 2, "atan2": 2
    })

    Component.onCompleted: {
        if (pluginService)
            trigger = pluginService.loadPluginData("dankCalc", "trigger", "")
    }

    onTriggerChanged: {
        if (pluginService)
            pluginService.savePluginData("dankCalc", "trigger", trigger)
    }

    function getItems(query) {
        var q = (query || "").trim()

        if (trigger && trigger.length > 0) {
            if (q.indexOf(trigger) !== 0)
                return []
            q = q.substring(trigger.length).trim()
        }

        if (!_looksLikeMath(q))
            return []

        var value = _evaluate(q)
        if (value === null)
            return []

        var raw = _formatRaw(value)
        if (raw === null)
            return []

        return [{
            name: "= " + _formatDisplay(value),
            icon: "material:calculate",
            comment: q + "  ·  Enter kopierar " + raw,
            action: "copy:" + raw,
            categories: ["Kalkylator"]
        }]
    }

    function executeItem(item) {
        if (!item || !item.action)
            return

        var idx = item.action.indexOf(":")
        if (idx < 0)
            return

        var type = item.action.substring(0, idx)
        var data = item.action.substring(idx + 1)

        if (type === "copy") {
            Quickshell.execDetached(["dms", "cl", "copy", data])
            if (typeof ToastService !== "undefined")
                ToastService.showInfo("Kalkylator", "Kopierade " + data)
        }
    }

    // Shift+Enter klistrar in resultatet i fönstret under i stället.
    function getPasteText(item) {
        if (!item || !item.action || item.action.indexOf("copy:") !== 0)
            return null
        return item.action.substring(5)
    }

    // Grovsållning innan parsern körs. Utan trigger anropas getItems() för
    // varenda sökning i launchern, så allt som inte uppenbart är räkning
    // måste bort här — annars dyker en kalkylatorrad upp när man söker appar.
    function _looksLikeMath(q) {
        if (!q || q.length === 0)
            return false

        if (/^0[xb]/i.test(q))
            return true

        var hasDigit = /[0-9]/.test(q)
        var hasCall = /[a-z][a-z0-9]*\s*\(/i.test(q)
        var hasOp = /[+\-*/^%()]/.test(q)

        // Rena appnamn saknar både siffror och funktionsanrop och åker ut här.
        // Något som ser ut som ett anrop släpps förbi utan siffror, så att
        // sqrt(pi) och ln(e) fungerar; parsern avvisar det ändå om namnet
        // inte är en känd funktion.
        if (!hasDigit && !hasCall)
            return false

        return hasOp || hasCall
    }

    function _evaluate(src) {
        var text = src

        // Svensk decimalkomma. Bara när uttrycket saknar bokstäver, annars
        // krockar det med kommat som argumentavskiljare i min(1, 2).
        if (!/[a-z]/i.test(text))
            text = text.replace(/,/g, ".")

        // Siffergruppering med 1_000 eller 1'000. Måste bort före tokenizern,
        // annars blir "1_000" två separata tal. Mellanslag används medvetet
        // INTE som avskiljare: "1 000" går inte att skilja från två tal, och
        // då är det säkrare att uttrycket avvisas än att det gissas fel.
        text = text.replace(/(\d)[_'](?=\d)/g, "$1")

        var tokens = _tokenize(text)
        if (tokens === null || tokens.length === 0)
            return null

        var rpn = _toRpn(tokens)
        if (rpn === null)
            return null

        var value = _evalRpn(rpn)
        if (value === null || !isFinite(value))
            return null

        return value
    }

    function _tokenize(src) {
        var tokens = []
        var i = 0

        while (i < src.length) {
            var c = src.charAt(i)

            if (c === " " || c === "\t") {
                i++
                continue
            }

            var rest = src.substring(i)

            if (/[0-9]/.test(c) || (c === "." && /[0-9]/.test(src.charAt(i + 1)))) {
                var num = /^(0[xX][0-9a-fA-F]+|0[bB][01]+|[0-9]*\.?[0-9]+([eE][+-]?[0-9]+)?)/.exec(rest)
                if (num === null)
                    return null
                var parsed = Number(num[0])
                if (isNaN(parsed))
                    return null
                tokens.push({ t: "num", v: parsed })
                i += num[0].length
                continue
            }

            if (/[a-zA-Z]/.test(c)) {
                var ident = /^[a-zA-Z][a-zA-Z0-9]*/.exec(rest)
                tokens.push({ t: "ident", v: ident[0].toLowerCase() })
                i += ident[0].length
                continue
            }

            if ("+-*/^%(),".indexOf(c) >= 0) {
                tokens.push({ t: c })
                i++
                continue
            }

            return null
        }

        return tokens
    }

    function _prec(op) {
        if (op === "neg" || op === "pos")
            return 4
        if (op === "^")
            return 3
        if (op === "*" || op === "/")
            return 2
        if (op === "+" || op === "-")
            return 1
        return 0
    }

    function _leftAssoc(op) {
        return op !== "^" && op !== "neg" && op !== "pos"
    }

    function _toRpn(tokens) {
        var out = []
        var ops = []
        var prev = "start"

        for (var i = 0; i < tokens.length; i++) {
            var tk = tokens[i]

            if (tk.t === "num") {
                out.push(tk)
                prev = "val"
            } else if (tk.t === "ident") {
                if (_constants.hasOwnProperty(tk.v)) {
                    out.push({ t: "num", v: _constants[tk.v] })
                    prev = "val"
                } else if (_funcs.hasOwnProperty(tk.v)) {
                    ops.push({ t: "func", v: tk.v })
                    prev = "op"
                } else {
                    return null
                }
            } else if (tk.t === "(") {
                ops.push({ t: "(" })
                prev = "op"
            } else if (tk.t === ")") {
                while (ops.length > 0 && ops[ops.length - 1].t !== "(")
                    out.push(ops.pop())
                if (ops.length === 0)
                    return null
                ops.pop()
                if (ops.length > 0 && ops[ops.length - 1].t === "func")
                    out.push(ops.pop())
                prev = "val"
            } else if (tk.t === ",") {
                while (ops.length > 0 && ops[ops.length - 1].t !== "(")
                    out.push(ops.pop())
                if (ops.length === 0)
                    return null
                prev = "op"
            } else if (tk.t === "%") {
                // Postfix. Procentens innebörd avgörs först vid uträkningen,
                // eftersom "200+10%" ska bli 220 men "200*10%" ska bli 20.
                if (prev !== "val")
                    return null
                out.push({ t: "pct" })
                prev = "val"
            } else {
                var op = tk.t
                if ((op === "-" || op === "+") && prev !== "val")
                    op = (op === "-") ? "neg" : "pos"

                while (ops.length > 0) {
                    var top = ops[ops.length - 1]
                    if (top.t === "(")
                        break
                    if (top.t === "func") {
                        out.push(ops.pop())
                        continue
                    }
                    var tp = _prec(top.t)
                    var p = _prec(op)
                    if (tp > p || (tp === p && _leftAssoc(op)))
                        out.push(ops.pop())
                    else
                        break
                }

                ops.push({ t: op })
                prev = "op"
            }
        }

        while (ops.length > 0) {
            var last = ops.pop()
            if (last.t === "(")
                return null
            out.push(last)
        }

        return out
    }

    function _evalRpn(rpn) {
        var stack = []
        var isPct = []

        for (var i = 0; i < rpn.length; i++) {
            var tk = rpn[i]

            if (tk.t === "num") {
                stack.push(tk.v)
                isPct.push(false)
            } else if (tk.t === "pct") {
                if (stack.length < 1)
                    return null
                var pv = stack.pop()
                isPct.pop()
                stack.push(pv / 100)
                isPct.push(true)
            } else if (tk.t === "pos") {
                if (stack.length < 1)
                    return null
            } else if (tk.t === "neg") {
                if (stack.length < 1)
                    return null
                var nv = stack.pop()
                isPct.pop()
                stack.push(-nv)
                isPct.push(false)
            } else if (tk.t === "func") {
                var arity = _funcs[tk.v]
                if (stack.length < arity)
                    return null
                var args = []
                for (var a = 0; a < arity; a++) {
                    args.unshift(stack.pop())
                    isPct.pop()
                }
                var fr = _applyFunc(tk.v, args)
                if (fr === null)
                    return null
                stack.push(fr)
                isPct.push(false)
            } else {
                if (stack.length < 2)
                    return null
                var bPct = isPct[isPct.length - 1]
                var b = stack.pop()
                isPct.pop()
                var av = stack.pop()
                isPct.pop()

                var r
                switch (tk.t) {
                case "+":
                    // b är redan delad med 100 av pct-steget ovan.
                    r = bPct ? av + av * b : av + b
                    break
                case "-":
                    r = bPct ? av - av * b : av - b
                    break
                case "*":
                    r = av * b
                    break
                case "/":
                    r = av / b
                    break
                case "^":
                    r = Math.pow(av, b)
                    break
                default:
                    return null
                }

                stack.push(r)
                isPct.push(false)
            }
        }

        if (stack.length !== 1)
            return null

        return stack[0]
    }

    function _applyFunc(name, a) {
        switch (name) {
        case "sqrt": return Math.sqrt(a[0])
        case "cbrt": return Math.cbrt(a[0])
        case "abs": return Math.abs(a[0])
        case "sign": return Math.sign(a[0])
        case "round": return Math.round(a[0])
        case "floor": return Math.floor(a[0])
        case "ceil": return Math.ceil(a[0])
        case "ln": return Math.log(a[0])
        case "log": return Math.log(a[0]) / Math.LN10
        case "log10": return Math.log(a[0]) / Math.LN10
        case "log2": return Math.log(a[0]) / Math.LN2
        case "exp": return Math.exp(a[0])
        case "sin": return Math.sin(a[0])
        case "cos": return Math.cos(a[0])
        case "tan": return Math.tan(a[0])
        case "asin": return Math.asin(a[0])
        case "acos": return Math.acos(a[0])
        case "atan": return Math.atan(a[0])
        case "min": return Math.min(a[0], a[1])
        case "max": return Math.max(a[0], a[1])
        case "pow": return Math.pow(a[0], a[1])
        case "mod": return a[0] % a[1]
        case "hypot": return Math.sqrt(a[0] * a[0] + a[1] * a[1])
        case "atan2": return Math.atan2(a[0], a[1])
        }
        return null
    }

    // Städar bort flyttalsbrus (0.1+0.2 ska bli 0.3, inte 0.30000000000000004)
    // utan att förstöra värden som verkligen behöver många decimaler.
    function _round(n) {
        if (n === 0 || !isFinite(n))
            return n
        var rounded = Number(n.toPrecision(12))
        return rounded === 0 ? n : rounded
    }

    // Värdet som kopieras: rent maskinläsbart, inga tusentalsavskiljare.
    function _formatRaw(n) {
        var r = _round(n)
        if (!isFinite(r))
            return null
        if (r !== 0 && (Math.abs(r) >= 1e15 || Math.abs(r) < 1e-9))
            return r.toExponential(6)
        return String(r)
    }

    // Värdet som visas: grupperat med tunt mellanslag för läsbarhet.
    function _formatDisplay(n) {
        var raw = _formatRaw(n)
        if (raw === null)
            return ""
        if (raw.indexOf("e") >= 0)
            return raw

        var neg = raw.charAt(0) === "-"
        var body = neg ? raw.substring(1) : raw
        var dot = body.indexOf(".")
        var intPart = dot < 0 ? body : body.substring(0, dot)
        var frac = dot < 0 ? "" : body.substring(dot)

        if (intPart.length > 4)
            intPart = intPart.replace(/\B(?=(\d{3})+(?!\d))/g, " ")

        return (neg ? "-" : "") + intPart + frac
    }
}
