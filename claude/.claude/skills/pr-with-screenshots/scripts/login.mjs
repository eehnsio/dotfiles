// login.mjs — one-time interactive login for apps whose auth can't be scripted
// (Azure AD/MSAL, SSO, MFA). Opens a visible Chromium at the local dev server,
// the user signs in themselves, and the session is saved as a Playwright
// storageState that capture.mjs reuses headless.
//
// Usage:
//   node login.mjs \
//     --base-url http://localhost:3000 \
//     --cookie session \                                   # cookie that proves login
//     --state ~/.claude/skills/pr-with-screenshots/.auth/dfteco.json \
//     --timeout 300                                        # seconds to wait (default 300)
//
// Never types credentials: the user does. Only localhost/127.0.0.1 is allowed, so a
// saved state never carries a session for a deployed environment.

import { chromium } from 'playwright'
import { mkdir } from 'node:fs/promises'
import { dirname } from 'node:path'

const argv = process.argv.slice(2)
const args = {}
for (let i = 0; i < argv.length; i++) {
  if (argv[i].startsWith('--')) { args[argv[i].slice(2)] = argv[i + 1]; i++ }
}

const baseURL = args['base-url'] || 'http://localhost:3000'
const cookieName = args.cookie || 'session'
const statePath = args.state
const timeoutMs = Number(args.timeout ?? 300) * 1000

if (!statePath) throw new Error('--state is required')
const { hostname, origin } = new URL(baseURL)
if (!['localhost', '127.0.0.1'].includes(hostname)) {
  throw new Error(`Refusing ${baseURL}: login.mjs only saves sessions for localhost.`)
}

const browser = await chromium.launch({ headless: false })
const ctx = await browser.newContext({ baseURL, viewport: { width: 1280, height: 860 } })
const page = await ctx.newPage()
await page.goto('/')
console.error(`Logga in i fönstret som öppnades (väntar upp till ${timeoutMs / 1000} s på cookien "${cookieName}")…`)

const deadline = Date.now() + timeoutMs
let ok = false
while (Date.now() < deadline) {
  const cookies = await ctx.cookies(origin)
  const back = page.url().startsWith(origin) && !new URL(page.url()).pathname.startsWith('/auth')
  if (back && cookies.some((c) => c.name === cookieName)) { ok = true; break }
  await page.waitForTimeout(1000)
}

if (ok) {
  await mkdir(dirname(statePath), { recursive: true })
  await ctx.storageState({ path: statePath })
  console.error(`Session sparad -> ${statePath}`)
}
await browser.close()
if (!ok) throw new Error(`Timed out: no "${cookieName}" cookie on ${origin}.`)
