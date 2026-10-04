import type { ElementConstructor, EngineInterface, Register, TextProps, Timer } from 'claude-code'

import type { CacheNotice, SessionNotice, SessionRow } from '../types'

// Ghostty har ingen överblick över flikar och splits, så den här modden ger en
// åtminstone för Claude-sessionerna, som herdrs: ett band ovanför prompten med
// en rad per grupp. Läget bärs av färgen på namnet, åldern står direkt efter.
// En tabell med jämna kolumner prövades och var svårare att läsa: det längsta
// namnet satte bredden och åldrarna hamnade långt från sina namn.
//
//   ◷ promptcachen går kall om 3 min   ▲ api-4f behöver ditt svar · dialog open
//   jobbar   devops-5b nyss
//   väntar   Claude Mods 16m   web-9c app 52m   infra-39 1h   vilande blog-74 app 2d
//
// Det fanns en ruta och en dockad sidopanel också. Bandet är lika brett som
// terminalen, så rutan lämnade död yta bredvid sig; panelen fick dockans egen
// bakgrund och kan bara ligga till höger. Raderna vann.
//
// Varje session skriver ~/.claude/sessions/<pid>.json med namn, katalog och
// läge; filerna ligger kvar när en process dör, så pid:en kollas mot ps innan
// raden visas.
//
// Samma pollning märker när en ANNAN session ställer en fråga eller jobbar
// klart och lägger det som en notis överst i bandet (sessions.notifyIdle).
// Först var det en toast, men den hamnar i ett hörn där man inte tittar,
// glider in med en animation och har en egen svart kant.
//
// Promptcachen varnar i samma notisrad: tre minuter innan den går kall, med
// ljud, och sedan att den är kall tills nästa prompt. Det var en egen mod
// (cache-alarm), men bara en mod kan rita bandet, så de bor ihop här.
const POLL_MS = 5_000
// Klar längre än så räknas som vilande och får en egen rad.
const DORMANT_MS = 12 * 3600_000
// En klar-notis står kvar så här länge; en fråga står kvar tills den besvarats.
const DONE_NOTICE_MS = 10 * 60_000
const MAX_NOTICES = 3
const LABEL_COLUMNS = 8

// Moddarnas API har ingen expires_at som statusraden, så cachens utgång
// räknas från när huvudloopens senaste tur tog slut. TTL:en är en timme,
// vad sessionen kör med; i overage sjunker den till fem minuter och då
// kommer varningen för sent.
const CACHE_TTL_MS = 60 * 60_000
const CACHE_LEAD_MS = 3 * 60_000

const rowsRef = { plugin: 'sessions', key: 'rows' } as const
const noticesRef = { plugin: 'sessions', key: 'notices' } as const
const cacheRef = { plugin: 'sessions', key: 'cache' } as const
const lastTurnAtRef = { plugin: 'sessions', key: 'lastTurnAt' } as const

let selfId: string | null = null
// Null tills första pollningen: den sår bara läget, annars får varje
// session som redan är klar en notis när modden laddas.
let seen: Map<number, string> | null = null
let cacheTimers: Timer[] = []

type SessionFile = {
  pid?: number
  sessionId?: string
  cwd?: string
  name?: string
  status?: string
  waitingFor?: string
  statusUpdatedAt?: number
  updatedAt?: number
  entrypoint?: string
}

async function poll($: EngineInterface, notify: boolean) {
  const home = (await $.env.get('HOME')) ?? ''
  const dir = `${home}/.claude/sessions`
  const entries = await $.fs.list(dir).catch(() => [])

  const files: SessionFile[] = []
  for (const entry of entries) {
    if (!entry.name.endsWith('.json')) continue
    const text = await $.fs.read(`${dir}/${entry.name}`).catch(() => '')
    try {
      files.push(JSON.parse(text) as SessionFile)
    } catch {
      // En fil mitt i en skrivning; nästa varv läser den hel.
    }
  }

  const pids = files.map(f => f.pid).filter((p): p is number => typeof p === 'number')
  const alive = new Set<number>()
  if (pids.length > 0) {
    const ps = await $.process.run(['ps', '-o', 'pid=', '-p', pids.join(',')]).catch(() => null)
    for (const line of ps?.stdout.split('\n') ?? []) {
      const pid = Number(line.trim())
      if (pid > 0) alive.add(pid)
    }
  }

  const rows: SessionRow[] = files
    .filter(f => typeof f.pid === 'number' && alive.has(f.pid))
    .map(f => ({
      pid: f.pid as number,
      name: f.name ?? String(f.pid),
      cwd: home && f.cwd?.startsWith(home) ? `~${f.cwd.slice(home.length)}` : (f.cwd ?? ''),
      status: f.status ?? 'okänd',
      ...(f.status === 'waiting' && f.waitingFor ? { waitingFor: f.waitingFor } : {}),
      since: f.statusUpdatedAt ?? f.updatedAt ?? 0,
      isSelf: f.sessionId === selfId,
      isApp: f.entrypoint === 'claude-desktop',
    }))
    .sort((a, b) => b.since - a.since)

  // Notiserna: nya byten läggs till, och en notis försvinner när sessionen
  // byter läge igen, försvinner helt, eller (klar) blir för gammal.
  const now = await $.clock.now()
  const { value: noticesBefore = [] } = await $.state.get(noticesRef)
  const byPid = new Map(rows.map(row => [row.pid, row]))
  let notices: SessionNotice[] = noticesBefore.filter(notice => {
    const row = byPid.get(notice.pid)
    if (row === undefined) return false
    if (notice.kind === 'waiting') return row.status === 'waiting'

    return row.status === 'idle' && now - notice.at < DONE_NOTICE_MS
  })
  if (notify && seen !== null) {
    for (const row of rows) {
      const was = seen.get(row.pid)
      if (row.isSelf || was === undefined || was === row.status) continue
      const notice: SessionNotice | null =
        row.status === 'waiting'
          ? { pid: row.pid, name: row.name, kind: 'waiting', detail: row.waitingFor ?? 'väntar på svar', at: now }
          : isWorking(was) && row.status === 'idle'
            ? { pid: row.pid, name: row.name, kind: 'done', detail: 'klar', at: now }
            : null
      if (notice) notices = [notice, ...notices.filter(one => one.pid !== row.pid)]
      // En fråga blockerar sessionen tills du svarar: den får ljud, en klar
      // gör det inte (med många sessioner igång blir det annars ett plingande).
      if (notice?.kind === 'waiting') {
        void $.process.run(['afplay', '/System/Library/Sounds/Ping.aiff']).catch(() => {})
      }
    }
  }
  notices = notices.slice(0, MAX_NOTICES)
  if (JSON.stringify(noticesBefore) !== JSON.stringify(notices)) await $.state.set(noticesRef, notices)

  seen = new Map(rows.map(row => [row.pid, row.status]))

  // Skriv bara när något ändrats, annars ritas bandet om var femte sekund.
  const { value: before = [] } = await $.state.get(rowsRef)
  if (JSON.stringify(before) !== JSON.stringify(rows)) await $.state.set(rowsRef, rows)
}

// busy är en tur, shell ett !-kommando; båda betyder att den inte väntar.
function isWorking(status: string) {
  return status !== 'idle' && status !== 'waiting'
}

function age(ms: number) {
  const s = Math.max(0, Math.floor(ms / 1000))
  if (s < 60) return 'nyss'
  if (s < 3600) return `${Math.floor(s / 60)}m`
  if (s < 86_400) return `${Math.floor(s / 3600)}h`

  return `${Math.floor(s / 86_400)}d`
}

// Tre grupper: de som jobbar, de som väntar på dig (de som står på en fråga
// först), och de som varit klara i över tolv timmar.
function arrange(rows: SessionRow[], now: number) {
  const isDormant = (row: SessionRow) =>
    !row.isSelf && row.status === 'idle' && now - row.since > DORMANT_MS
  const active = rows.filter(row => isWorking(row.status))
  const waiting = rows
    .filter(row => !isWorking(row.status) && !isDormant(row))
    .sort((x, y) => Number(y.status === 'waiting') - Number(x.status === 'waiting'))
  const dormant = rows.filter(isDormant)

  return { active, waiting, dormant }
}

// Namnet som det står i bandet: desktop-appens sessioner märks, så man vet
// att man ska leta i appen och inte bland terminalfönstren.
function label(row: SessionRow) {
  return row.isApp ? `${row.name} app` : row.name
}

// Listan som text, för /sessions: samma grupper och tecken, plus katalogen.
function listText(rows: SessionRow[], now: number) {
  const { active, waiting, dormant } = arrange(rows, now)
  const line = (row: SessionRow) =>
    `${dotFor(row).glyph} ${label(row)}${row.isSelf ? ' (den här)' : ''} · ${age(now - row.since)} · ${row.cwd}`
  const parts = [
    active.length > 0 ? `jobbar\n${active.map(line).join('\n')}` : '',
    waiting.length > 0 ? `väntar\n${waiting.map(line).join('\n')}` : '',
    dormant.length > 0 ? `vilande\n${dormant.map(line).join('\n')}` : '',
  ].filter(Boolean)

  return parts.length > 0 ? parts.join('\n\n') : 'Inga sessioner.'
}

function disarmCache() {
  for (const timer of cacheTimers) timer.cancel()
  cacheTimers = []
}

// Ställer timrarna för en tur som tog slut vid turnEndedAt. Under de sista
// minuterna skrivs nedräkningen om varje halvminut, så raden visar rätt.
async function armCache($: EngineInterface, turnEndedAt: number) {
  disarmCache()
  const expiresAt = turnEndedAt + CACHE_TTL_MS
  const now = await $.clock.now()
  const minutesLeft = async () => Math.max(1, Math.ceil((expiresAt - (await $.clock.now())) / 60_000))

  if (expiresAt - CACHE_LEAD_MS > now) {
    cacheTimers.push(
      $.clock.after(expiresAt - CACHE_LEAD_MS - now, () => {
        void $.state.set(cacheRef, { kind: 'warn', minutesLeft: CACHE_LEAD_MS / 60_000 })
        // Systemljudet direkt, så ingen av Apples filer hamnar i repot. Finns
        // bara på macOS; på Arch blir det tyst och raden får räcka.
        void $.process.run(['afplay', '/System/Library/Sounds/Glass.aiff']).catch(() => {})
        cacheTimers.push(
          $.clock.every(30_000, () => {
            void minutesLeft().then(left => $.state.set(cacheRef, { kind: 'warn', minutesLeft: left }))
          }),
        )
      }),
    )
  }
  if (expiresAt > now) {
    cacheTimers.push(
      $.clock.after(expiresAt - now, () => {
        disarmCache()
        void $.state.set(cacheRef, { kind: 'cold', minutesLeft: 0 })
      }),
    )
  } else {
    await $.state.set(cacheRef, { kind: 'cold', minutesLeft: 0 })
  }
}

export const register: Register = (on, options) => {
  const notify = options.notifyIdle !== false
  // Sessionsöversikten är pausad som standard; cachevarningen gäller alltid.
  const showSessions = options.showSessions === true

  on('session.start', async ($, e, next) => {
    const started = await next(e)
    if (showSessions) {
      selfId = await $.session.id()
      await $.command.register({
        name: 'sessions',
        description: 'Lista alla Claude-sessioner på maskinen, med katalog',
      })
      await poll($, notify)
      $.clock.every(POLL_MS, () => {
        void poll($, notify)
      })
    }
    // En omladdning tappar timrarna men inte $.state: ställ om dem.
    const { value: lastTurnAt } = await $.state.get(lastTurnAtRef)
    if (lastTurnAt != null) await armCache($, lastTurnAt)

    return started
  })

  // Medan en tur kör hålls cachen varm av anropen själva.
  on('prompt.submit', async ($, e, next) => {
    disarmCache()
    await $.state.set(cacheRef, null)

    return next(e)
  })

  // Subagenternas turer har egna prefix, och ett avbrott före första svaret
  // har inget usage och förnyade ingenting.
  on('turn.complete', async ($, e, next) => {
    const done = await next(e)
    if (e.agentId === undefined && e.usage !== undefined) {
      const now = await $.clock.now()
      await $.state.set(lastTurnAtRef, now)
      await $.state.set(cacheRef, null)
      await armCache($, now)
    }

    return done
  })

  // Bandet kan fällas ihop med [-] eller ctrl+x ctrl+a, och det är Claude
  // Codes eget: en mod kan inte fälla ut det igen. /sessions ger listan ändå.
  on('command.run', { command: 'sessions' }, async $ => {
    await poll($, notify)
    const { value: rows = [] } = await $.state.get(rowsRef)

    return {
      text: `${listText(rows, await $.clock.now())}\n\nctrl+x ctrl+a fäller ut bandet ovanför prompten igen.`,
    }
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    // Pausad översikt: det som ligger kvar i state från förut ritas inte.
    const { value: storedRows = [] } = await $.state.get(rowsRef)
    const { value: storedNotices = [] } = await $.state.get(noticesRef)
    const rows = showSessions ? storedRows : []
    const notices = showSessions ? storedNotices : []
    const { value: cache = null } = await $.state.get(cacheRef)
    const hasNotices = notices.length > 0 || cache !== null
    if (e.props.hasSurvey || (rows.length === 0 && !hasNotices)) return next(e)

    const { Box, Text } = $.ui.resolve(e)
    const now = await $.clock.now()
    const { active, waiting, dormant } = arrange(rows, now)

    const chip = (row: SessionRow) => sessionChip(Text, row, now)
    const group = (title: string, members: SessionRow[], tail: SessionRow[] = []) => (
      <Box key={title} flexDirection="row">
        <Box width={LABEL_COLUMNS} flexShrink={0}>
          <Text dimColor>{title}</Text>
        </Box>
        <Box flexDirection="row" flexWrap="wrap" columnGap={3} flexShrink={1}>
          {members.map(chip)}
          {tail.length > 0 && (
            <Text key="dormant-label" dimColor>
              vilande
            </Text>
          )}
          {tail.map(row => sessionChip(Text, row, now, true))}
        </Box>
      </Box>
    )

    return (
      <Box flexDirection="column">
        {hasNotices && (
          <Box key="notices" flexDirection="row" flexWrap="wrap" columnGap={3}>
            {cache !== null && cacheChip(Text, cache)}
            {notices.map(notice => noticeChip(Text, notice, now))}
          </Box>
        )}
        {active.length > 0 && group('jobbar', active)}
        {(waiting.length > 0 || dormant.length > 0) && group('väntar', waiting, dormant)}
      </Box>
    )
  })
}

// Gult för den som behöver dig: varm färg är varning, som i statusraden.
// Grönt för jobbar. Grått för klar.
function dotFor(row: SessionRow) {
  if (row.status === 'waiting') return { glyph: '●', color: 'yellow' }
  if (isWorking(row.status)) return { glyph: '●', color: 'green' }

  return { glyph: '○', color: undefined }
}

// Färgerna skrivs ansi:<namn>: ett bart namn som 'green' går genom Claude
// Codes tema (dark-daltonized här) och blir en annan nyans än statusradens.
// ansi: är terminalens egen palett, samma som statusraden använder.
//
// Notiserna är etiketter: terminalens egen färg omvänd, så de syns i
// ögonvrån men följer temat. Rött för en fråga (den blockerar), gult för
// cachen, grönt för klar. En kall cache är bara nedtonad text.
function cacheChip(Text: ElementConstructor<TextProps>, cache: CacheNotice) {
  return cache.kind === 'warn' ? (
    <Text key="cache" color="yellow" inverse bold>
      {` ◷ promptcachen går kall om ${cache.minutesLeft} min `}
    </Text>
  ) : (
    <Text key="cache" dimColor>
      ◷ promptcachen är kall
    </Text>
  )
}

function noticeChip(Text: ElementConstructor<TextProps>, notice: SessionNotice, now: number) {
  const isQuestion = notice.kind === 'waiting'

  return (
    <Text key={`notice-${notice.pid}`}>
      <Text color={isQuestion ? 'red' : 'green'} inverse bold>
        {isQuestion ? ` ▲ ${notice.name} behöver ditt svar ` : ` ✓ ${notice.name} är klar `}
      </Text>
      <Text dimColor>
        {isQuestion ? ` ${notice.detail} · ` : ' '}
        {age(now - notice.at)}
      </Text>
    </Text>
  )
}

// En session i bandet: namnet i lägets färg, "app" och åldern nedtonade
// direkt efter. Grönt jobbar, gult väntar på din nästa prompt, fet röd står
// på en fråga och blockerar, grått vilar. Den egna i fet cyan, som i
// statusraden.
//
// Namnen ritas nedtonade: Claude Code tonar ner hela statusraden, så samma
// ANSI-färger ser ut som där först med dim. Notiserna ovanför är inte
// nedtonade, de ska dra blicken.
function sessionChip(Text: ElementConstructor<TextProps>, row: SessionRow, now: number, isDormant = false) {
  const color = row.isSelf
    ? 'cyan'
    : row.status === 'waiting'
      ? 'red'
      : isWorking(row.status)
        ? 'green'
        : isDormant
          ? undefined
          : 'yellow'

  return (
    <Text key={String(row.pid)}>
      <Text color={color} dimColor bold={row.isSelf || row.status === 'waiting'}>
        {row.name}
      </Text>
      {row.isApp && <Text dimColor> app</Text>}
      <Text dimColor> {age(now - row.since)}</Text>
    </Text>
  )
}
