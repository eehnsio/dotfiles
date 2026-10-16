// capture.mjs — screenshot routes of a running local dev server, optionally
// cropped to the changed component.
//
// Usage:
//   node capture.mjs \
//     --base-url http://localhost:3000 \
//     --routes /,/planning/plan \
//     --out /tmp/pr-shots \
//     --viewport desktop \                        # desktop | mobile | both
//     --state ~/.claude/skills/pr-with-screenshots/.auth/<repo>.json \
//     --crop-selectors '[aria-label="Föregående månad"]||[aria-label="Nästa månad"]' \
//     --crop-pad 48 \                              # px of context around the crop
//     --crop-slug period-nav \                     # filename suffix for the crop
//     --tag before                                 # optional extra filename suffix (before/after shots)
//     --settle '.animate-spin, .animate-pulse' \   # wait until none of these exist
//     --hide 'nextjs-portal'                       # hide dev overlays before shooting
//
// Selectors are '||'-separated (commas clash with :has-text(",")). The crop is the
// union bounding box of every selector that matches, plus --crop-pad on each side.
//
// Auth: reuses --state if it exists (from login.mjs, or an earlier run). Without a
// state file it logs in with REDA_EMAIL / REDA_PASSWORD against
// <base-url>/api/auth/login (the Reda/.NET flow) and saves the result to --state.
// After a run the state is written back, so sliding sessions renewed by the server
// stay fresh. Passwords are read from the environment and never printed.
// Only localhost/127.0.0.1 is allowed. Requires Playwright chromium.

import { chromium, request } from 'playwright'
import { mkdir, writeFile } from 'node:fs/promises'
import { existsSync } from 'node:fs'
import { dirname } from 'node:path'

const argv = process.argv.slice(2)
const args = {}
for (let i = 0; i < argv.length; i++) {
  if (argv[i].startsWith('--')) { args[argv[i].slice(2)] = argv[i + 1]; i++ }
}

const baseURL = args['base-url'] || 'http://localhost:5173'
const routes = (args.routes || '/').split(',').map((s) => s.trim()).filter(Boolean)
const out = args.out || '/tmp/pr-shots'
const statePath = args.state
const viewports = args.viewport === 'both' ? ['desktop', 'mobile'] : [args.viewport || 'desktop']
const cropSelectors = (args['crop-selectors'] || '').split('||').map((s) => s.trim()).filter(Boolean)
const cropPad = Number(args['crop-pad'] ?? 48)
const cropSlug = args['crop-slug'] || 'crop'
const tag = args.tag ? `-${args.tag}` : ''
const settle = args.settle ?? '.animate-spin, .animate-pulse'
const hide = args.hide ?? 'nextjs-portal'

const { hostname, origin } = new URL(baseURL)
if (!['localhost', '127.0.0.1'].includes(hostname)) {
  throw new Error(`Refusing ${baseURL}: capture.mjs only shoots local dev servers.`)
}

const VIEWPORTS = { desktop: { width: 1440, height: 900 }, mobile: { width: 390, height: 844 } }
const slug = (r) => (r === '/' ? 'home' : r.replace(/^\//, '').replace(/[^a-zA-Z0-9]+/g, '-').replace(/-+$/, ''))

await mkdir(out, { recursive: true })

// --- auth: obtain a storageState carrying the session cookie ---
async function login() {
  const email = process.env.REDA_EMAIL
  const password = process.env.REDA_PASSWORD
  if (!email || !password) {
    throw new Error('No saved --state and REDA_EMAIL/REDA_PASSWORD not set. Run login.mjs first for interactive (SSO) logins.')
  }
  const api = await request.newContext({ baseURL })
  const res = await api.post('/api/auth/login', { data: { email, password } })
  if (!res.ok()) throw new Error(`Login failed: ${res.status()} ${await res.text()}`)
  const state = await api.storageState()
  await api.dispose()
  return state
}

let storageState
if (statePath && existsSync(statePath)) {
  storageState = statePath
} else {
  const state = await login()
  if (statePath) {
    await mkdir(dirname(statePath), { recursive: true })
    await writeFile(statePath, JSON.stringify(state))
    storageState = statePath
  } else {
    storageState = state
  }
}

// Union bounding box of every matching selector, expanded by pad on each side.
// boundingBox() is viewport-relative; the full-page clip wants document coordinates.
async function cropBox(page, selectors, pad) {
  const { sx, sy } = await page.evaluate(() => ({ sx: window.scrollX, sy: window.scrollY }))
  const boxes = []
  for (const sel of selectors) {
    const b = await page.locator(sel).first().boundingBox().catch(() => null)
    if (b) boxes.push({ ...b, x: b.x + sx, y: b.y + sy })
  }
  if (!boxes.length) return null
  const x0 = Math.max(0, Math.min(...boxes.map((b) => b.x)) - pad)
  const y0 = Math.max(0, Math.min(...boxes.map((b) => b.y)) - pad)
  const x1 = Math.max(...boxes.map((b) => b.x + b.width)) + pad
  const y1 = Math.max(...boxes.map((b) => b.y + b.height)) + pad
  return { x: x0, y: y0, width: x1 - x0, height: y1 - y0, matched: boxes.length }
}

const browser = await chromium.launch()
const shots = []
try {
  for (const vp of viewports) {
    const ctx = await browser.newContext({
      baseURL,
      storageState,
      viewport: VIEWPORTS[vp],
      deviceScaleFactor: 2, // retina-crisp screenshots
      isMobile: vp === 'mobile',
      hasTouch: vp === 'mobile',
      reducedMotion: 'reduce', // charts (Recharts 'auto') and transitions render final state at once
    })
    const page = await ctx.newPage()
    for (const route of routes) {
      await page.goto(route, { waitUntil: 'networkidle', timeout: 60000 }) // Next dev compiles on first hit
      const landed = new URL(page.url())
      if (landed.origin !== origin || (landed.pathname === '/login' && route !== '/login')) {
        throw new Error(`Not authenticated — ${route} ended up at ${landed.origin}${landed.pathname}. Run login.mjs again.`)
      }
      if (settle) {
        await page
          .waitForFunction((s) => !document.querySelector(s), settle, { timeout: 20000 })
          .catch(() => console.error(`warning: ${route} still shows "${settle}" after 20 s`))
      }
      if (hide) await page.addStyleTag({ content: `${hide} { display: none !important; }` })
      await page.waitForTimeout(400)
      const suffix = `${vp === 'mobile' ? '-mobile' : ''}${tag}`

      // 1) Full-page shot — context. Grow the viewport to the document height first so
      // h-screen layouts (sidebars, shells) stretch to the bottom instead of ending at
      // the first fold.
      const height = await page.evaluate(() => document.documentElement.scrollHeight)
      await page.setViewportSize({ width: VIEWPORTS[vp].width, height: Math.min(height, 12000) })
      await page.waitForTimeout(300)
      const file = `${out}/${slug(route)}${suffix}.png`
      await page.screenshot({ path: file, fullPage: true })
      shots.push({ route, viewport: vp, kind: 'full', file })
      console.error(`shot ${route} [${vp}] full -> ${file}`)

      // 2) Focused crop — the changed component with breathing room.
      if (cropSelectors.length) {
        const box = await cropBox(page, cropSelectors, cropPad)
        if (box) {
          const cfile = `${out}/${slug(route)}-${cropSlug}${suffix}.png`
          await page.screenshot({ path: cfile, fullPage: true, clip: { x: box.x, y: box.y, width: box.width, height: box.height } })
          shots.push({ route, viewport: vp, kind: 'crop', file: cfile })
          console.error(`shot ${route} [${vp}] crop(${box.matched} anchors, pad ${cropPad}) -> ${cfile}`)
        } else {
          console.error(`crop skipped for ${route} [${vp}]: no crop-selectors matched`)
        }
      }
      await page.setViewportSize(VIEWPORTS[vp])
    }
    if (statePath) await ctx.storageState({ path: statePath }) // keep renewed session cookies
    await ctx.close()
  }
} finally {
  await browser.close()
}

process.stdout.write(JSON.stringify({ shots }, null, 2) + '\n')
