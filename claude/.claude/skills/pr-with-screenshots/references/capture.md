# Capture — run the app and screenshot the new state

Goal: produce PNGs of the confirmed routes showing the **working-tree** version
with real data. A bundled script does the browser work:
[`scripts/capture.mjs`](../scripts/capture.mjs). Your job is to get a running
instance + valid auth, then call it.

## 1. Prefer an already-running dev server

Vite serves the working tree with hot-reload, so if the user is already running
the app (common — they've usually been looking at their change), it **already**
reflects the edits. Reuse it instead of launching a second stack.

Probe for it (Vite may increment past 5173 if busy — check a few):
```bash
for p in 5173 5174 5175; do
  curl -sf "http://localhost:$p/" >/dev/null && echo "frontend on $p"; done
curl -sf http://localhost:5096/ | grep -q "Economic API" && echo "backend up"
```
Use the frontend port as `--base-url` (screenshot through Vite so `/api` is
proxied and the cookie is host-scoped correctly). If nothing is running, launch
it (§4).

## 2. Ensure Playwright chromium is available

The script needs Playwright. If `node -e "require.resolve('playwright')"` fails,
install into a throwaway location and run from there, or reuse the environment's
Playwright (the `webapp-testing` skill ships it). Quick self-contained setup:
```bash
cd "$(dirname <skill>/scripts/capture.mjs)" && bun add playwright 2>/dev/null || npm i playwright
bunx playwright install chromium 2>/dev/null || npx playwright install chromium
```

## 3. Authenticate + capture

Auth is a session cookie (`reda.session`) from `POST /api/auth/login`
`{email,password}` — no dev bypass, so real credentials are needed. Handle them
safely:

- Prefer a **saved session**: pass `--state <path>` (default suggestion
  `~/.claude/skills/pr-with-screenshots/.auth/state.json`). If it exists and is
  still valid (30-day sliding cookie), no password is touched at all.
- First time / expired: the script logs in using `REDA_EMAIL` / `REDA_PASSWORD`
  from the environment and saves the session to `--state`. Ask the user to
  export those in their shell (once); **never** hard-code the password, print it,
  echo `$REDA_PASSWORD`, or write it to the repo or the PR.

Run it:
```bash
REDA_EMAIL="$REDA_EMAIL" REDA_PASSWORD="$REDA_PASSWORD" \
node <skill>/scripts/capture.mjs \
  --base-url http://localhost:5173 \
  --routes / \
  --out /tmp/reda-shots \
  --viewport desktop \
  --state ~/.claude/skills/pr-with-screenshots/.auth/state.json \
  --crop-selectors '[aria-label="Föregående månad"]||[aria-label="Nästa månad"]||button:has-text("▾")' \
  --crop-pad 56 \
  --crop-slug period-nav
```
- **`--crop-selectors`** (`||`-separated — commas clash with `:has-text(",")`)
  are the anchors for the changed component confirmed in Step 2. The crop is the
  union bounding box of every selector that matches, plus `--crop-pad` px of
  context on each side (default 48; ~56 gives a bit more breathing room). Output
  goes to `<route>-<crop-slug>.png` alongside the full-page `<route>.png`. Omit
  these flags to capture full-page only.
- Deriving anchors from the diff: prefer stable, semantic hooks — a new/changed
  `aria-label`, `data-testid`, distinctive visible text, or a unique class.
  Avoid brittle nth-child paths. If nothing distinctive changed, skip the crop
  and use full-page.
- `--viewport both` also grabs a 390px mobile shot — use it when the change is
  about responsive/mobile behaviour.
- The script prints a JSON `{ "shots": [{route, viewport, kind, file}] }` on
  stdout (`kind` is `full` or `crop`); use those file paths for the upload step.
- It **fails loudly** if a route bounces to `/login` (bad/expired session) rather
  than shipping a screenshot of the login form. If that happens, refresh the
  session (delete the state file, re-run with env creds) and retry.

Sanity-check the PNGs before proceeding: open them and confirm they show the
expected screen with data (not a spinner, empty state, or login). Note: the
local DB dump excludes BYOK AI keys, so **AI-generated prose** (e.g. period
summaries) may be blank — that's expected and fine; the authoritative numbers are
real. Don't shoot a screen whose only change is AI prose.

## 4. Fallback — launch the full stack

Only if nothing is running. This is heavier and the data restore is destructive
to the **local** DB, so confirm with the user first.

```bash
# 1. Postgres (host port 5433)
docker compose up -d postgres

# 2. Real data — restores the prod snapshot economic.dump (already in repo root).
#    DESTRUCTIVE to local DB only. Skip if the local DB already has data.
scripts/pull-my-db.sh -y --restore

# 3. Backend on :5096 — seed a known Playwright admin via env so we have creds
#    without secrets (AuthBootstrap creates it as Admin in the seeded household,
#    which is where the restored data lives). Run in background.
Auth__InitialUser__Email="playwright@local" Auth__InitialUser__Password="<pick-one>" \
  dotnet run --project src/backend/Economic.Api &
#    wait until ready:
until curl -sf http://localhost:5096/health >/dev/null; do sleep 1; done

# 4. Frontend — run in background, then read the actual port from its stdout.
( cd src/frontend && bun install && bun run dev ) &
```
Then set `REDA_EMAIL=playwright@local` / `REDA_PASSWORD=<the one you picked>` and
run the capture script from §3.

Clean up any servers you started once capture is done.
