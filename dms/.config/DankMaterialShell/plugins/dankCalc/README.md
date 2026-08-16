# dankCalc

Kalkylator i DMS-launchern, i stil med Spotlight på macOS. Skriv ett uttryck i
spotlight (`Mod+Space`) så ligger svaret överst. Enter kopierar resultatet,
Shift+Enter klistrar in det i fönstret under.

## Varför en egen parser

Launchern anropar `getItems()` vid varje tangenttryckning, så plugin-koden får
se allt som skrivs in — inklusive halvfärdiga ord och appnamn. Att skicka den
strömmen genom `eval()` vore både en säkerhetsrisk och opålitligt. I stället
tokeniseras uttrycket och körs genom shunting-yard till RPN. Parsern kan bara
räkna, och returnerar `null` på allt annat, vilket också är det som gör att
`firefox` och `wine-9.0` inte ger någon kalkylatorrad.

## Utan prefix

Triggern är tom som standard, alltså aktiv för varje sökning. För att inte
förorena appsökningen sållas frågan först i `_looksLikeMath()`: den kräver
antingen en siffra eller ett funktionsanrop, plus en operator eller parentes.
Passerar något ändå får parsern avvisa det.

Vill du ha ett prefix i stället sätts det under Settings → Plugins → Kalkylator.

## Kan hantera

| | |
|---|---|
| Räknesätt, parenteser | `(2+3)*4` → 20 |
| Potens, högerassociativ | `2^3^2` → 512 |
| Procent | `200+10%` → 220, `200*10%` → 20, `50%` → 0.5 |
| Funktioner | `sqrt` `cbrt` `abs` `sign` `round` `floor` `ceil` `ln` `log` `log2` `log10` `exp` `sin` `cos` `tan` `asin` `acos` `atan` `min` `max` `pow` `mod` `hypot` `atan2` |
| Konstanter | `pi` `e` `tau` |
| Hex och binärt | `0x1f` → 31, `0b1010` → 10 |
| Svensk decimalkomma | `1,5*2` → 3 |
| Siffergruppering | `1_000` och `1'000` |

Mellanslag duger medvetet **inte** som siffergruppering: `1 000` går inte att
skilja från två separata tal, och då avvisas uttrycket hellre än att gissas
fel.

Flyttalsbrus städas bort — `0.1+0.2` visar `0.3`, inte `0.30000000000000004`.
Det som visas grupperas med mellanslag för läsbarhet, men det som kopieras är
alltid det råa värdet.

## Slå av och på

```bash
dms ipc call plugins disable dankCalc
dms ipc call plugins enable dankCalc
dms ipc call plugins list
```
