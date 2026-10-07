---
name: signum
description: Eriks avsändarblock för sidfoten på hans appar och sajter ("App av Erik Ehnsiö" + ikonerna mejl, GitHub, Buy me a coffee), likadant överallt. Använd när Erik ber om "signum", "App av Erik Ehnsiö", "mina ikoner i sidfoten", "mejl/GitHub/kaffe-ikonerna", eller vill lägga in, uppdatera eller rätta avsändaren på en sajt (matematiskt.se, oslipat.ehnsio.se, eve.ehnsio.se med flera). Gäller statisk HTML, React/Next och Astro.
---

# Signum

Ett avsändarblock som ser och beter sig likadant på alla Eriks sajter. Formen och
rörelsen är fasta; färgerna lånas från sajten via CSS-variabler.

## Delar

1. **Rad:** `App av <a href="https://ehnsio.se">Erik Ehnsiö</a>`. Namnet är en vanlig
   länk i sajtens länkstil (understruken). Engelska sajter: `App by Erik Ehnsiö`.
2. **Ikoner, i den här ordningen:**

| Ikon | Gör | Tooltip | aria-label |
| --- | --- | --- | --- |
| Mejl (Lucide `mail`) | **Kopierar** `e.ehnsio@gmail.com`, ingen mailto. Byts mot en grön bock och tooltipen säger "Kopierad!" i 2 s. Går kopieringen inte öppnas mailto som reserv | Kopiera e-post | Kopiera e-postadress |
| GitHub (Lucide `github`) | Länkar ut till https://github.com/eehnsio i ny flik | GitHub | Erik på GitHub |
| Kaffe (Lucide `coffee`) | Länkar ut till https://buymeacoffee.com/eehnsio i ny flik, ikonen blir guldbrun vid hover | Köp mig en kaffe | Köp mig en kaffe |

Engelska: "Copy email" / "Copied!", "GitHub", "Buy me a coffee".

Om sajten bara har plats för en ikon (t.ex. en meny eller ett sidoblad): ta bara kaffet,
men med samma `.signum-link`-markup så rörelsen följer med.

## Utseende och rörelse (fast, ändra inte per sajt)

- Ikon 20 px, stroke 2, i en 44×44 träffyta med 10 px rundning.
- Hover (bara mus): ljus bakgrund i rutan, ikonen tippar `rotate(8deg) scale(1.1)` med
  fjädrande kurva `cubic-bezier(0.34, 1.56, 0.64, 1)` på 300 ms. Samma som
  kontaktlänkarna på ehnsio.se (`.contact-link` i `src/styles/global.css`).
- Tryck: hela rutan `scale(0.95)`.
- Tooltip: mörk bubbla med pil ovanför ikonen, visas vid hover och tangentbordsfokus,
  och efter kopiering även på mobil.
- `prefers-reduced-motion`: ingen tippning, inga övergångar.

## Filer

Allt ligger i `assets/` bredvid den här filen. Kopiera, skriv inte om från minnet:

- `signum.css`: all stil. Variabler för färgerna står överst i filen.
- `signum.html` + `signum.js`: statisk HTML (och Astro).
- `Signum.tsx`: React/Next. Använder samma klasser, så `signum.css` behövs ändå.

## Lägga in på en sajt

1. Läs sajtens sidfot och färgvariabler först.
2. Kopiera `signum.css` in i sajtens stil (eget stycke i den globala CSS-filen, eller
   som egen fil som importeras globalt). Sätt bara de variabler som behövs för att
   passa sajten, oftast `--signum-fg` (sajtens sekundära textfärg), `--signum-fg-hover`
   (huvudtextfärgen) och kanske `--signum-ok` (sajtens gröna). Mörkt läge: sätt
   `--signum-tip-bg`/`--signum-tip-fg` om den mörka bubblan smälter in.
3. Markup:
   - **Statisk HTML:** klistra in `signum.html` efter "App av"-raden och lägg
     innehållet i `signum.js` i sajtens skript (eller som egen fil med `defer`).
   - **Astro:** gör en `Signum.astro` av `signum.html` med `signum.js` i en `<script>`.
   - **React/Next:** lägg `Signum.tsx` bland komponenterna och rendera `<Signum />`.
     Ersätt ui-bibliotekets `Tooltip` och `lucide-react`-ikoner i den gamla sidfoten;
     de behövs inte.
4. Ta bort den gamla varianten helt (gamla klasser, oanvända imports, serveranrop som
   bara fanns för att hämta adressen).
5. Lägg rad och ikoner bredvid varandra (`display: flex; align-items: center;
   justify-content: space-between` eller sajtens motsvarighet), ikonerna sist.
6. Prova i webbläsaren: hover på varje ikon, klick på mejlet (bock + "Kopierad!"),
   Tab genom ikonerna (tooltipen syns vid fokus), och smal skärm.

## Var det används

- eve.ehnsio.se (`~/Developer/eve-web`, statisk HTML)
- matematiskt.se (`~/Developer/Matteappen`, Next) — gammal variant i
  `src/components/layout/site-footer.tsx`
- oslipat.ehnsio.se (`~/Developer/oslipat`, Next) — bara kaffet, i sidobladet i
  `components/layout/app-header.tsx`

Ändras något i signumet: ändra här först, sedan på sajterna.
