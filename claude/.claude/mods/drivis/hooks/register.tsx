import type { EngineInterface, Register } from 'claude-code'

import { printable, renderMarkdown } from './markdown'

// Drivis i transkriptet, efter yugal1107/ui-themes: varje prompt och varje
// svar i en egen ruta, så att det syns var ens egen text slutar och Claudes
// börjar utan att man letar efter ›-tecknet.
//
// ui-themes har flera teman, en väljare och en egen statuslinje. Här finns
// bara drivis, och färgerna står i koden i stället för i JSON-filer under
// ~/.claude: riset har en palett, och den bor i ghostty/themes/drivis.
// Statuslinjen har vi redan, och den tar sina färger från terminalen.
//
// Prompten får markeringens bakgrund, så den läses som "det här valde du".
// Svaret får index 0, en nyans mörkare än terminalen, så rutan syns utan att
// ta över.
const PROMPT_BG = '#2b3342' // selection-background
const REPLY_BG = '#101216'  // palette 0
// Ett kommando i prompten får accenten, som Claude Code själv färgar dem.
const COMMAND = '#7fc8ff'   // palette 6

// /namn räknas bara som kommando när namnet finns i sessionens kommandolista,
// så att sökvägar (/tmp/x) och "och/eller" inte färgas. Det kan stå var som
// helst i prompten, inte bara först: "kör på /commit" kör /commit också.
// Listan hämtas om högst en gång i minuten; skills som dyker upp under
// sessionen kommer med vid nästa hämtning.
const SLASH = /(^|\s)(\/[\w:.-]+)/g
let commands = new Set<string>()
let fetchedAt = 0

async function knownCommands($: EngineInterface) {
  if (Date.now() - fetchedAt > 60_000) {
    fetchedAt = Date.now()
    try { commands = new Set((await $.command.list()).map(c => c.name)) } catch {}
  }
  return commands
}

function withCommands(text: string, known: Set<string>, Text: any) {
  const out: any[] = []
  let last = 0
  for (const m of text.matchAll(SLASH)) {
    const token = m[2] ?? ''
    if (!known.has(token.slice(1))) continue
    const at = (m.index ?? 0) + (m[1] ?? '').length
    if (at > last) out.push(text.slice(last, at))
    out.push(<Text key={`c${at}`} bold color={COMMAND}>{token}</Text>)
    last = at + token.length
  }
  if (last < text.length) out.push(text.slice(last))
  return out
}

export const register: Register = on => {
  on('ui.render', { component: 'UserMessage' }, async ($, e, next) => {
    // Bara det du själv skrev vid prompten får rutan. Allt annat som ritas som
    // ett användarmeddelande (bakgrundsjobb, andra agenter och sessioner,
    // kanaler, schemalagda körningar, plugins) ritar motorn med sin egen
    // märkning, så att det aldrig ser ut som något du har skrivit.
    if (e.props.origin.kind !== 'composer' || e.props.task || e.props.from) return next(e)
    const { Box, Text } = $.ui.resolve(e)
    return (
      <Box backgroundColor={PROMPT_BG} paddingX={2} paddingY={1} marginTop={1}>
        <Text>{withCommands(printable(e.props.text), await knownCommands($), Text)}</Text>
      </Box>
    )
  })

  on('ui.render', { component: 'AssistantMessage' }, ($, e, next) => {
    // Sammanfattningar ritar motorn: bara dess rad får ` · summary`-märket.
    if (e.props.isSummary) return next(e)
    const t = $.ui.resolve(e)
    const { Box } = t
    return (
      <Box backgroundColor={REPLY_BG} paddingX={2} paddingY={1} marginTop={1}>
        {renderMarkdown(e.props.text, t)}
      </Box>
    )
  })
}
