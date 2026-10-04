import { expect, mock, test } from 'claude-code/testing'
import type { On } from 'claude-code'
import type { Engine } from 'claude-code/testing'

const BAND = { plugin: 'sessions', surface: 'terminal', component: 'AbovePrompt', props: { bodyColumns: 120 } as never } as const

// Trädets text i läsordning, utan formatering.
function flatten(node: unknown): string {
  if (typeof node === 'string') return node
  if (Array.isArray(node)) return node.map(flatten).join('')
  if (node && typeof node === 'object' && 'children' in node) return flatten((node as { children: unknown }).children)
  return ''
}

// Bandets text: det som syns ovanför prompten.
async function bandText($: Engine) {
  const band = await $.ui.mount(BAND)
  const text = flatten(await band.drawn())
  await band.unmount()
  return text
}

type File = { pid: number; sessionId: string; cwd: string; name: string; status: string; statusUpdatedAt: number; entrypoint: string }

// Ljuden modden spelat, via afplay.
let sounds: string[] = []

// En maskin med tre sessionsfiler, varav en vars process är död.
function machine(on: On, files: Map<string, File>, alive: number[]) {
  mock.env(on, { HOME: '/h' })
  // Det motorn själv ritar när modden lämnar bandet.
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>motorns</Text>
  })
  on('session.start', (_$, e) => ({ cwd: e.cwd }))
  on('session.id', () => ({ value: 'self' }))
  on('command.register', () => ({ value: { command: 'sessions' } }))
  on('fs.list', () => ({
    value: [...files.keys()].map(name => ({ name, kind: 'file' as const, size: 1, mtimeMs: 0, isLink: false })),
  }))
  on('fs.read', (_$, e) => ({ value: JSON.stringify(files.get(e.path.split('/').pop() ?? '')) }))
  on('process.run', (_$, e) => {
    if (e.argv[0] === 'afplay') sounds.push(e.argv[1] ?? '')
    return { value: { exitCode: 0, stdout: alive.map(p => ` ${p}\n`).join(''), stderr: '' } }
  })
}

function file(pid: number, name: string, status: string, extra: Partial<File> = {}): File {
  return { pid, sessionId: `s${pid}`, cwd: `/h/Developer/${name}`, name, status, statusUpdatedAt: 0, entrypoint: 'cli', ...extra }
}

test('listar levande sessioner och visar en notis i bandet när en annan blir klar', { options: { showSessions: true } }, async ($, on) => {
  const clock = mock.clock(on, { now: 10 * 60_000 })
  const files = new Map([
    ['1.json', file(1, 'dotfiles-46', 'busy', { sessionId: 'self' })],
    ['2.json', file(2, 'api-4f', 'busy', { statusUpdatedAt: 5 * 60_000 })],
    ['3.json', file(3, 'gammal', 'idle')],
  ])
  machine(on, files, [1, 2])
  on('ui.panes', () => ({ value: [] }))
  on('ui.close', () => ({ value: undefined }))
  const toasts: string[] = []
  on('ui.toast', (_$, e) => {
    toasts.push(e.text)
    return { value: undefined }
  })

  await $.session.start({ cwd: '/h', surface: 'terminal', isInteractive: true })

  for (const surface of ['terminal', 'desktop'] as const) {
    const band = await $.ui.mount({ ...BAND, surface })
    expect(await band.find({ type: 'Text', text: /api-4f/ })).toBeDefined()
    expect(await band.find({ type: 'Text', text: /gammal/ })).toBeUndefined()
    await band.unmount()
  }
  expect(toasts).toEqual([])

  files.set('2.json', file(2, 'api-4f', 'idle', { statusUpdatedAt: 10 * 60_000 }))
  await clock.advance(5_000)
  expect(await bandText($)).toContain('✓ api-4f')
  expect(toasts).toEqual([])

  // Den egna sessionen får aldrig en notis.
  files.set('1.json', file(1, 'dotfiles-46', 'idle', { sessionId: 'self' }))
  await clock.advance(5_000)
  expect(await bandText($)).not.toContain('✓ dotfiles-46')
})

test('raderna: jobbar först, sedan väntar, den som behöver svar före de klara', { options: { showSessions: true } }, async ($, on) => {
  sounds = []
  const clock = mock.clock(on, { now: 10 * 60_000 })
  const files = new Map([
    ['1.json', file(1, 'klar', 'idle')],
    ['2.json', file(2, 'jobbar', 'busy')],
    ['3.json', file(3, 'fragar', 'busy')],
  ])
  machine(on, files, [1, 2, 3])
  on('ui.panes', () => ({ value: [] }))
  on('ui.close', () => ({ value: undefined }))
  const toasts: string[] = []
  on('ui.toast', (_$, e) => {
    toasts.push(e.text)
    return { value: undefined }
  })

  await $.session.start({ cwd: '/h', surface: 'terminal', isInteractive: true })
  files.set('3.json', { ...file(3, 'fragar', 'waiting'), waitingFor: 'dialog open' } as never)
  await clock.advance(5_000)
  expect(await bandText($)).toContain('▲ fragar behöver ditt svar')
  expect(await bandText($)).toContain('dialog open')
  expect(sounds).toEqual(['/System/Library/Sounds/Ping.aiff'])


  const text = await bandText($)
  const at = (needle: string, from = 0) => text.indexOf(needle, from)
  // Etiketten "jobbar" först, sedan sessionen som heter jobbar, sedan väntar.
  expect(at('jobbar') < at('jobbar', at('jobbar') + 1)).toBe(true)
  expect(at('jobbar', at('jobbar') + 1) < at('väntar')).toBe(true)
  // Notisen överst nämner också fragar; ordningen räknas inom väntar-raden.
  const row = at('väntar')
  expect(row < at('fragar', row)).toBe(true)
  expect(at('fragar', row) < at('klar', row)).toBe(true)
  // Besvarad fråga: notisen går bort.
  files.set('3.json', file(3, 'fragar', 'busy'))
  await clock.advance(5_000)
  expect(await bandText($)).not.toContain('behöver ditt svar')
})

test('/sessions med raden skriver ut listan och öppnar ingen panel', { options: { showSessions: true } }, async ($, on) => {
  mock.clock(on, { now: 10 * 60_000 })
  machine(on, new Map([['1.json', file(1, 'dotfiles-46', 'busy', { sessionId: 'self' })], ['2.json', file(2, 'api-4f', 'idle')]]), [1, 2])
  on('ui.panes', () => ({ value: [] }))
  on('ui.close', () => ({ value: undefined }))
  const opened: string[] = []
  on('ui.open', (_$, e) => {
    opened.push(e.id)
    return { value: { isPlaced: true } }
  })

  await $.session.start({ cwd: '/h', surface: 'terminal', isInteractive: true })
  const { text } = await $.command.run({ command: 'sessions', args: '' })
  expect(opened).toEqual([])
  expect(text).toContain('● dotfiles-46 (den här)')
  expect(text).toContain('○ api-4f · 10m · ~/Developer/api-4f')
  expect(text).toContain('ctrl+x ctrl+a')
})

const USAGE = { input_tokens: 10, output_tokens: 10, cache_read_input_tokens: 1000, cache_creation_input_tokens: 100, model: 'claude-opus-5-5' }
const MIN = 60_000

function turnDone($: Engine, agentId?: string) {
  return $.turn.complete({
    answer: 'klart',
    durationMs: 1,
    isAborted: false,
    turnId: 't',
    usage: USAGE,
    reason: 'answer',
    ...(agentId === undefined ? {} : { agentId }),
  })
}

test('cachen varnar i bandet med ljud tre minuter före, och säger sedan att den är kall', async ($, on) => {
  sounds = []
  const clock = mock.clock(on, { now: 1_000_000 })
  machine(on, new Map(), [])
  on('turn.complete', (_$, e) => ({ text: e.answer }))

  await $.session.start({ cwd: '/h', surface: 'terminal', isInteractive: true })
  await turnDone($)

  await clock.advance(56 * MIN)
  expect(await bandText($)).not.toContain('promptcachen')

  await clock.advance(1 * MIN)
  expect(await bandText($)).toContain('promptcachen går kall om 3 min')
  expect(sounds).toEqual(['/System/Library/Sounds/Glass.aiff'])

  await clock.advance(1 * MIN)
  expect(await bandText($)).toContain('promptcachen går kall om 2 min')

  await clock.advance(2 * MIN)
  expect(await bandText($)).toContain('promptcachen är kall')
})

test('en ny tur flyttar fram cachens varning, en subagents tur gör det inte', async ($, on) => {
  sounds = []
  const clock = mock.clock(on, { now: 1_000_000 })
  machine(on, new Map(), [])
  on('turn.complete', (_$, e) => ({ text: e.answer }))

  await $.session.start({ cwd: '/h', surface: 'terminal', isInteractive: true })
  await turnDone($)
  await clock.advance(30 * MIN)
  await turnDone($)
  await clock.advance(10 * MIN)
  await turnDone($, 'subagent-1')

  // 57 min efter första turen: den gamla varningen är inställd.
  await clock.advance(17 * MIN)
  expect(sounds).toEqual([])

  // 57 min efter huvudloopens andra tur, inte subagentens.
  await clock.advance(30 * MIN)
  expect(sounds.length).toBe(1)
})

test('pausad översikt: bandet visar bara cachen, inga sessioner', async ($, on) => {
  const clock = mock.clock(on, { now: 1_000_000 })
  machine(on, new Map([['2.json', file(2, 'api-4f', 'busy')]]), [2])
  on('turn.complete', (_$, e) => ({ text: e.answer }))

  await $.session.start({ cwd: '/h', surface: 'terminal', isInteractive: true })
  expect(await bandText($)).toBe('motorns')

  await turnDone($)
  await clock.advance(57 * MIN)
  const text = await bandText($)
  expect(text).toContain('promptcachen går kall om 3 min')
  expect(text).not.toContain('api-4f')
})
