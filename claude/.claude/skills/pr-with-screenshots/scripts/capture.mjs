// capture.mjs — screenshot routes of the running Reda dev server, optionally
// cropped to the changed component.
//
// Usage:
//   node capture.mjs \
//     --base-url http://localhost:5173 \
//     --routes /,/transaktioner \
//     --out /tmp/reda-shots \
//     --viewport desktop \                        # desktop | mobile | both
//     --state ~/.claude/skills/pr-with-screenshots/.auth/state.json \
//     --crop-selectors '[aria-label="Föregående månad"]||[aria-label="Nästa månad"]||button:has-text("▾")' \
//     --crop-pad 48 \                              # px of context around the crop
//     --crop-slug period-nav                       # filename suffix for the crop
//
// Selectors are '||'-separated (commas clash with :has-text(",")). The crop is the
// union bounding box of every selector that matches, plus --crop-pad on each side —
// enough context to see where the change lives without the whole page as noise.
//
// Auth: reuses --state if it exists; else logs in with REDA_EMAIL / REDA_PASSWORD
// against <base-url>/api/auth/login and saves the session to --state. The password is
// read from the environment and never printed. Requires Playwright chromium.

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
const out = args.out || '/tmp/reda-shots'
const statePath = args.state
const viewports = args.viewport === 'both' ? ['desktop', 'mobile'] : [args.viewport || 'desktop']
const cropSelectors = (args['crop-selectors'] || '').split('||').map((s) => s.trim()).filter(Boolean)
const cropPad = Number(args['crop-pad'] ?? 48)
const cropSlug = args['crop-slug'] || 'crop'

const VIEWPORTS = { desktop: { width: 1440, height: 900 }, mobile: { width: 390, height: 844 } }
const slug = (r) => (r === '/' ? 'home' : r.replace(/^\//, '').replace(/\//g, '-'))

await mkdir(out, { recursive: true })

// --- auth: obtain a storageState carrying the reda.session cookie ---
async function login() {
  const email = process.env.REDA_EMAIL
  const password = process.env.REDA_PASSWORD
  if (!email || !password) {
    throw new Error('No saved --state and REDA_EMAIL/REDA_PASSWORD not set — cannot authenticate.')
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
async function cropBox(page, selectors, pad) {
  const boxes = []
  for (const sel of selectors) {
    const b = await page.locator(sel).first().boundingBox().catch(() => null)
    if (b) boxes.push(b)
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
    })
    const page = await ctx.newPage()
    for (const route of routes) {
      await page.goto(route, { waitUntil: 'networkidle', timeout: 30000 })
      if (new URL(page.url()).pathname === '/login' && route !== '/login') {
        throw new Error(`Not authenticated — ${route} redirected to /login. Refresh --state or check creds.`)
      }
      await page
        .waitForFunction(() => !document.querySelector('.animate-spin'), null, { timeout: 15000 })
        .catch(() => {})
      await page.waitForTimeout(400)
      const suffix = vp === 'mobile' ? '-mobile' : ''

      // 1) Full-page shot — context.
      const file = `${out}/${slug(route)}${suffix}.png`
      await page.screenshot({ path: file, fullPage: true })
      shots.push({ route, viewport: vp, kind: 'full', file })
      console.error(`shot ${route} [${vp}] full -> ${file}`)

      // 2) Focused crop — the changed component with breathing room.
      if (cropSelectors.length) {
        const box = await cropBox(page, cropSelectors, cropPad)
        if (box) {
          const cfile = `${out}/${slug(route)}-${cropSlug}${suffix}.png`
          await page.screenshot({ path: cfile, clip: { x: box.x, y: box.y, width: box.width, height: box.height } })
          shots.push({ route, viewport: vp, kind: 'crop', file: cfile })
          console.error(`shot ${route} [${vp}] crop(${box.matched} anchors, pad ${cropPad}) -> ${cfile}`)
        } else {
          console.error(`crop skipped for ${route} [${vp}]: no crop-selectors matched`)
        }
      }
    }
    await ctx.close()
  }
} finally {
  await browser.close()
}

process.stdout.write(JSON.stringify({ shots }, null, 2) + '\n')
