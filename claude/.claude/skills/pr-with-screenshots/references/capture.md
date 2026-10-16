# Capture — screenshot the working tree headless

`SKILL` below means `~/.claude/skills/pr-with-screenshots`. The stack reference
says how to start the dev server and log in; this file covers the shooting.

## 1. Playwright

The scripts import `playwright` from `SKILL/scripts/node_modules`. If
`node -e "import('playwright')"` fails from that directory:
```bash
cd ~/.claude/skills/pr-with-screenshots/scripts && npm ci
npx playwright install chromium
```

## 2. Session

Sessions are Playwright storageState files in `SKILL/.auth/<repo>.json`
(gitignored, never inside the target repo). Two ways to get one:

- **Interactive login** (SSO/Azure AD/MFA, anything that can't be scripted). The
  user signs in themselves in a visible window; nothing types credentials:
  ```bash
  node ~/.claude/skills/pr-with-screenshots/scripts/login.mjs \
    --base-url http://localhost:3000 --cookie session \
    --state ~/.claude/skills/pr-with-screenshots/.auth/<repo>.json
  ```
  Tell the user a Chromium window is opening and wait for it to return.
- **Scripted login** (Reda only): `capture.mjs` posts `REDA_EMAIL`/`REDA_PASSWORD`
  when no state file exists. See stack-vite-dotnet.md.

`capture.mjs` writes the state back after each run, so sliding sessions that the
server renews stay alive. If a run fails with "Not authenticated", run
`login.mjs` again. A session in the user's Chrome can't be reused: the cookie is
httpOnly and Chrome's cookie store is off-limits.

## 3. Shoot

```bash
node ~/.claude/skills/pr-with-screenshots/scripts/capture.mjs \
  --base-url http://localhost:3000 \
  --routes /planning/plan-vs-actual \
  --out "$SCRATCH/shots" \
  --viewport desktop \
  --state ~/.claude/skills/pr-with-screenshots/.auth/<repo>.json \
  --crop-selectors ':text-is("Team under plan") >> xpath=ancestor::*[contains(@class,"rounded")][1]||:text-is("Outnyttjad kapacitet") >> xpath=ancestor::*[contains(@class,"rounded")][1]' \
  --crop-pad 24 --crop-slug nyckeltal
```

- `--out`: use the session's scratchpad, not the repo.
- `--crop-selectors`: `||`-separated Playwright selectors; the crop is the union
  box of every match plus `--crop-pad` px. Output `<route>-<crop-slug>.png` next
  to the full-page `<route>.png`. Anchoring on bare text cuts cards in half:
  select the label, then climb to the card with
  `>> xpath=ancestor::*[contains(@class,"rounded")][1]` (or the card's own
  `data-testid`/tag).
- `--viewport mobile|both`: 390×844 with mobile emulation (`-mobile.png`).
  No window resizing involved, so it works regardless of the user's browser.
- `--settle`: waits until none of these selectors exist (default
  `.animate-spin, .animate-pulse`, i.e. spinners and Tailwind skeletons).
- `--hide`: CSS selectors hidden before shooting (default `nextjs-portal`, the
  Next dev indicator).
- `--tag before|after`: extra filename suffix for before/after pairs.
- Built in: `reducedMotion: 'reduce'` (Recharts and transitions render their
  final state, no half-drawn bars), and the viewport grows to the document
  height before the full shot so `h-screen` sidebars reach the bottom.
- Stdout is JSON `{ "shots": [{route, viewport, kind, file}] }`; `kind` is
  `full` or `crop`.
- Only `localhost`/`127.0.0.1` are accepted.

Then open each PNG with Read and check it. Fix and re-shoot rather than ship a
wrong one.

## 4. Before/after (optional)

Only when Step 2 decided on it. Shoot "before" from `main` in a throwaway
worktree on another port; cookies are per host, not per port, so the same
state file works:
```bash
git worktree add "$SCRATCH/before" main
# copy untracked config the app needs (e.g. .env.local), install deps,
# start the dev server on a free port (stack reference has the command)
node .../capture.mjs --base-url http://localhost:3001 --tag before ...
node .../capture.mjs --base-url http://localhost:3000 --tag after  ...
```
Stop that server and `git worktree remove "$SCRATCH/before"` afterwards. In the
body, put the pair in a table: `| Före | Efter |`.

## 5. Mobile/narrow checks while developing

To *look* at a narrow layout (not for PR images), the built-in browser can
emulate it: `resize_window` with `preset: "mobile"`, then reload; reset with
`preset: "desktop"`. Claude in Chrome can't shrink below the window's minimum.
