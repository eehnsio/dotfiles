import { test, expect } from 'claude-code/testing'

test('svaret ritas i en ruta med drivisens markdown-färger', async ($) => {
  const tree = await $.ui.render({
    surface: 'terminal', component: 'AssistantMessage', requestId: 'm1',
    props: { text: '### Rubrik\n\nKör `foo()` och **fet**.\n\n- punkt', isFirstOfReply: true },
  } as any)
  const json = JSON.stringify(tree)
  expect(json).toContain('#101216')
  expect(json).toContain('#7fc8ff')
  expect(json).toContain('#8fb4e4')
})

test('egen prompt ritas i markeringens färg', async ($) => {
  const tree = await $.ui.render({
    surface: 'terminal', component: 'UserMessage', requestId: 'u1',
    props: { text: 'hej', origin: { kind: 'composer' }, isExpanded: true },
  } as any)
  expect(JSON.stringify(tree)).toContain('#2b3342')
})

test('notiser från bakgrundsjobb lämnas åt motorn', async ($, on) => {
  // Står för motorns egen rad.
  on('ui.render', { component: 'UserMessage' }, ($, e: any) => $.ui.resolve(e).Text({ children: 'motorns' }) as any)
  const tree = await $.ui.render({
    surface: 'terminal', component: 'UserMessage', requestId: 'u2',
    props: { text: 'klart', origin: { kind: 'task-notification' }, isExpanded: true, task: { id: 't1' } },
  } as any)
  expect(JSON.stringify(tree ?? null)).not.toContain('#2b3342')
})
