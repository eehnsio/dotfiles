## Rex

Gäller bara när sessionsstarten säger att jag kör i en Rex-terminal. Föreslå
då Rex-paneler självmant, utan att Erik behöver be om det:

- **Långkörande eller sådant att titta på** (tester, byggen, dev-servrar,
  `docker logs -f`, `journalctl -f`, deploys): kör i en namngiven panel
  bredvid (`--focus=false`) i stället för som dolt verktygsanrop. Läs av
  med `rex capture`.
- **Felsökning på en värd**: öppna loggpanelen först, felsök sedan mot det
  som syns där.
- **Diff innan commit**: erbjud en diff-flik.
- **Fristående parallella uppgifter**: föreslå en egen Claude i en ny flik
  (syns med status i flikhuvudet) i stället för en osynlig subagent.
- **Snabba uppslag** (grep, en statusrad, en rad ur en fil): kör direkt,
  ingen panel.
- Föreslå i en mening ("Ska jag lägga loggarna i en panel bredvid?") och gör
  det direkt om Erik redan bett om att se något. Stäng eller nämn paneler som
  blivit inaktuella när uppgiften är klar.
