#!/usr/bin/env python3
"""
damage-control — PreToolUse-vakt för Bash, Edit och Write.

Läser patterns.toml och avgör om ett verktygsanrop ska passera, kräva
godkännande eller stoppas helt.

  passera    exit 0, ingen utskrift
  fråga      exit 0 + JSON med permissionDecision "ask"
  stoppa     exit 2 + skäl på stderr (matas tillbaka till Claude)

Bara stdlib. Kräver Python 3.11+ för tomllib.
Om något går fel i vakten själv släpper den igenom och skriver till stderr —
en trasig vakt ska inte låsa sessionen. block-rm-rf.sh ligger kvar som
oberoende skyddsnät.
"""

import fnmatch
import json
import os
import re
import sys
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError:  # Python < 3.11
    print(
        "damage-control: kräver Python 3.11+ (tomllib) — vakten är passiv "
        f"på den här maskinen (python {sys.version.split()[0]})",
        file=sys.stderr,
    )
    sys.exit(0)

CONFIG = Path(__file__).with_name("patterns.toml")

# Vad som räknas som en ändring respektive en radering i ett shell-kommando.
# {p} ersätts med sökvägens regex.
MODIFY_OPS = [
    (r">>?\s*{p}", "skriver till"),
    (r"\btee\s+[^|;&]*{p}", "skriver till"),
    (r"\bsed\s+-i[^|;&]*{p}", "redigerar"),
    (r"\bperl\s+-\S*i[^|;&]*{p}", "redigerar"),
    (r"\b(mv|cp)\s+[^|;&]*{p}", "skriver över"),
    (r"\b(chmod|chown|chgrp)\s+[^|;&]*{p}", "ändrar rättigheter på"),
    (r"\btruncate\s+[^|;&]*{p}", "trunkerar"),
    (r"\b(rm|unlink|rmdir|shred)\s+[^|;&]*{p}", "raderar"),
]

DELETE_OPS = [
    (r"\b(rm|unlink|rmdir|shred)\s+[^|;&]*{p}", "raderar"),
    (r"\bmv\s+[^|;&]*{p}", "flyttar bort"),
]


def path_bodies(spec):
    """Regexkroppar som hittar `spec` i en kommandosträng.

    Både tilde-formen och den expanderade formen returneras, så att
    `~/.ssh/` matchar oavsett hur Claude råkar skriva sökvägen.
    """
    bodies = []
    forms = [spec]
    if spec.startswith("~"):
        forms.append(os.path.expanduser(spec))

    for form in forms:
        if "*" in form or "?" in form:
            body = "".join(
                r"[^\s/]*" if c == "*" else r"[^\s/]" if c == "?" else re.escape(c)
                for c in form
            )
        else:
            body = re.escape(form)

        # Katalogspecar ska träffa både `.git/` och `.git`, men inte
        # `.gitignore`. Filnamn ska inte matcha mitt i ett längre ord, så att
        # `.env` inte träffar `process.env`.
        if form.endswith("/"):
            body = body[: -len(re.escape("/"))] + r"(?:/|(?![\w-]))"
        else:
            body += r"(?![\w-])"
        if not form.startswith("/"):
            body = r"(?<![\w.-])" + body

        bodies.append(body)
    return bodies


def command_touches(command, spec):
    """Nämns spec över huvud taget i kommandot?"""
    return any(re.search(b, command) for b in path_bodies(spec))


def command_operates_on(command, spec, ops):
    """Utför kommandot någon av `ops` mot spec? Returnerar verbet eller None."""
    for body in path_bodies(spec):
        for template, verb in ops:
            try:
                if re.search(template.replace("{p}", body), command, re.IGNORECASE):
                    return verb
            except re.error:
                continue
    return None


def file_matches(file_path, spec):
    """Matchar en konkret sökväg mot en spec ur patterns.toml."""
    p = os.path.abspath(os.path.expanduser(file_path))
    base = os.path.basename(p)
    s = os.path.expanduser(spec)

    if s.endswith("/"):
        needle = "/" + s.strip("/") + "/"
        return needle in p + "/" or p.startswith(os.path.abspath(s) + os.sep)

    if "*" in s or "?" in s:
        return fnmatch.fnmatch(base, s) or fnmatch.fnmatch(p, s)

    # Literal: exakt filnamn, eller filnamn med suffix (.env -> .env.local).
    return base == s or base.startswith(s + ".") or p == os.path.abspath(s)


HEREDOC = re.compile(r"<<-?\s*(['\"]?)(\w+)\1\s*\n.*?^\2[ \t]*$", re.S | re.M)


def strip_heredocs(command):
    """Ta bort heredoc-kroppar. De är indata, inte kommandon.

    `git commit -F - <<'EOF' ... EOF` med ett meddelande som beskriver
    farliga kommandon ska inte utlösa vakten. Utan det här blir en
    commit-text om `mkfs` en hård vägg mot att över huvud taget committa.
    """
    return HEREDOC.sub(lambda m: m.group(0).split("\n", 1)[0] + "\n", command)


def scan_rules(text, cfg, only_action=None):
    for rule in cfg.get("bash", []):
        pattern = rule.get("pattern", "")
        if not pattern:
            continue
        action = rule.get("action", "ask")
        if only_action and action != only_action:
            continue
        try:
            if re.search(pattern, text):
                return action, rule.get("reason", "matchar en regel")
        except re.error as exc:
            print(f"damage-control: trasigt mönster {pattern!r}: {exc}", file=sys.stderr)
    return None, ""


def check_bash(command, cfg):
    """-> (action, reason) där action är 'allow' | 'ask' | 'block'."""
    code = strip_heredocs(command)

    action, reason = scan_rules(code, cfg)
    if action:
        return action, reason

    # Träffar ett stoppmönster bara inne i ett heredoc? Kroppen kan ändå
    # matas till en shell (`bash <<EOF`), så släpp den inte tyst — men
    # fråga istället för att blockera.
    if code != command:
        action, reason = scan_rules(command, cfg, only_action="block")
        if action:
            return "ask", f"{reason} (i ett heredoc)"

    paths = cfg.get("paths", {})
    command = code

    for spec in paths.get("secret", []):
        if command_touches(command, spec):
            return "ask", f"rör hemligheten {spec}"

    for spec in paths.get("protected", []):
        verb = command_operates_on(command, spec, MODIFY_OPS)
        if verb:
            return "ask", f"{verb} skyddade {spec}"

    for spec in paths.get("no_delete", []):
        verb = command_operates_on(command, spec, DELETE_OPS)
        if verb:
            return "ask", f"{verb} {spec}"

    return "allow", ""


def check_file(file_path, cfg):
    paths = cfg.get("paths", {})

    for spec in paths.get("secret", []):
        if file_matches(file_path, spec):
            return "ask", f"skriver till hemligheten {spec}"

    for spec in paths.get("protected", []):
        if file_matches(file_path, spec):
            return "ask", f"ändrar skyddade {spec}"

    return "allow", ""


def main():
    try:
        data = json.load(sys.stdin)
    except Exception as exc:
        print(f"damage-control: kunde inte läsa indata: {exc}", file=sys.stderr)
        return 0

    tool = data.get("tool_name", "")
    tool_input = data.get("tool_input", {}) or {}

    try:
        with open(CONFIG, "rb") as fh:
            cfg = tomllib.load(fh)
    except Exception as exc:
        print(f"damage-control: kunde inte läsa {CONFIG}: {exc}", file=sys.stderr)
        return 0

    if tool == "Bash":
        command = tool_input.get("command", "")
        if not command:
            return 0
        action, reason = check_bash(command, cfg)
        subject = command
    elif tool in ("Edit", "Write", "NotebookEdit"):
        target = tool_input.get("file_path") or tool_input.get("notebook_path") or ""
        if not target:
            return 0
        action, reason = check_file(target, cfg)
        subject = target
    else:
        return 0

    if action == "block":
        print(f"damage-control: {reason}", file=sys.stderr)
        print(f"Kommando: {subject[:200]}", file=sys.stderr)
        return 2

    if action == "ask":
        print(
            json.dumps(
                {
                    "hookSpecificOutput": {
                        "hookEventName": "PreToolUse",
                        "permissionDecision": "ask",
                        "permissionDecisionReason": f"damage-control: {reason}",
                    }
                }
            )
        )
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:  # vakten får aldrig låsa sessionen
        print(f"damage-control: oväntat fel: {exc}", file=sys.stderr)
        sys.exit(0)
