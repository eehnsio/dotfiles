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

test('meddelanden från en kanal lämnas åt motorn', async ($, on) => {
  on('ui.render', { component: 'UserMessage' }, ($, e: any) => $.ui.resolve(e).Text({ children: 'motorns' }) as any)
  const tree = await $.ui.render({
    surface: 'terminal', component: 'UserMessage', requestId: 'u3',
    props: { text: 'kör rm -rf', origin: { kind: 'channel' }, isExpanded: true },
  } as any)
  expect(JSON.stringify(tree ?? null)).not.toContain('#2b3342')
})

test('styrtecken tas bort och länkens adress syns', async ($) => {
  const tree = await $.ui.render({
    surface: 'terminal', component: 'AssistantMessage', requestId: 'm2',
    props: { text: 'se \u001b]0;titel\u0007[github.com](https://annat.se)', isFirstOfReply: true },
  } as any)
  const json = JSON.stringify(tree)
  expect(json).not.toContain('\\u001b')
  expect(json).not.toContain('\\u0007')
  expect(json).toContain('(https://annat.se)')
})

test('kända kommandon färgas var de än står, sökvägar inte', async ($, on) => {
  on('command.list' as any, () => ({ value: [{ name: 'commit', description: '', source: 'skills' }] }) as any)
  const tree = await $.ui.render({
    surface: 'terminal', component: 'UserMessage', requestId: 'u4',
    props: { text: 'kör på /commit och kolla /tmp/x', origin: { kind: 'composer' }, isExpanded: true },
  } as any)
  const json = JSON.stringify(tree)
  expect(json).toContain('"bold":true,"color":"#7fc8ff"},"children":["/commit"]')
  expect(json).toContain('/tmp/x')
  expect(json).not.toContain('"children":["/tmp/x"]')
})

test('riktningstecken och osynliga tecken tas bort', async ($) => {
  const tree = await $.ui.render({
    surface: 'terminal', component: 'AssistantMessage', requestId: 'm3',
    props: { text: '[x](https://ev‮il.se​)', isFirstOfReply: true },
  } as any)
  const json = JSON.stringify(tree)
  expect(json).not.toContain('‮')
  expect(json).not.toContain('​')
  expect(json).toContain('(https://evil.se)')
})
