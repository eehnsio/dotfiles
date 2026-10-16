# Stack: React + Vite frontend, .NET backend (Reda / economics)

UI files live under `src/frontend/src/`. Frontend on Vite (5173, may step to
5174/5175), backend `Economic.Api` on 5096; Vite proxies `/api`.

## Dev server — prefer one that's already running

Vite hot-reloads the working tree, so a running instance already shows the edits:
```bash
for p in 5173 5174 5175; do
  curl -sf "http://localhost:$p/" >/dev/null && echo "frontend on $p"; done
curl -sf http://localhost:5096/ | grep -q "Economic API" && echo "backend up"
```
Shoot through the Vite port (so `/api` is proxied and the cookie is host-scoped).

## Login — scripted

Session cookie `reda.session` from `POST /api/auth/login {email,password}`, 30-day
sliding. State file: `~/.claude/skills/pr-with-screenshots/.auth/state.json`.
If it's missing or expired, `capture.mjs` logs in with `REDA_EMAIL` /
`REDA_PASSWORD` from the environment. Ask the user to export them once; never
hard-code, print or echo the password, or write it to the repo or PR.

```bash
REDA_EMAIL="$REDA_EMAIL" REDA_PASSWORD="$REDA_PASSWORD" \
node ~/.claude/skills/pr-with-screenshots/scripts/capture.mjs \
  --base-url http://localhost:5173 --routes / --out "$SCRATCH/shots" \
  --state ~/.claude/skills/pr-with-screenshots/.auth/state.json \
  --crop-selectors '[aria-label="Föregående månad"]||[aria-label="Nästa månad"]||button:has-text("▾")' \
  --crop-pad 56 --crop-slug period-nav
```
The local DB dump excludes BYOK AI keys, so AI-generated prose may be blank —
expected. Don't shoot a screen whose only change is AI prose.

## Fallback — launch the full stack

Only if nothing runs. The restore is destructive to the **local** DB; confirm first.
```bash
docker compose up -d postgres                      # host port 5433
scripts/pull-my-db.sh -y --restore                 # prod snapshot -> local DB
Auth__InitialUser__Email="playwright@local" Auth__InitialUser__Password="<pick-one>" \
  dotnet run --project src/backend/Economic.Api &  # seeds an admin
until curl -sf http://localhost:5096/health >/dev/null; do sleep 1; done
( cd src/frontend && bun install && bun run dev ) & # read the port from stdout
```
Then use `REDA_EMAIL=playwright@local` and the password you picked. Stop the
servers you started when done. For a "before" server, `bun run dev -- --port 5180`.

## Route map — changed file → screenshot route(s)

Source of truth: `src/frontend/src/App.tsx` (routes) and
`src/frontend/src/components/AppShell.tsx` (nav labels). React Router 7,
`BrowserRouter`. Re-derive from `App.tsx` if this ever looks stale.

### Protected routes (the screenshottable app)

| URL path | Page file | Nav label |
|---|---|---|
| `/` | `src/frontend/src/pages/Periodoverview.tsx` | Periodöversikt |
| `/utveckling` | `src/frontend/src/pages/Utveckling.tsx` | Utveckling över tid |
| `/transaktioner` | `src/frontend/src/pages/Transactions.tsx` | Transaktioner |
| `/granska` | `src/frontend/src/pages/Review.tsx` | Granska |
| `/fasta-kostnader` | `src/frontend/src/pages/FixedCosts.tsx` | Fasta kostnader |
| `/normaliseringsregler` | `src/frontend/src/pages/NormalizationRules.tsx` | Normaliseringsregler |
| `/kategorier` | `src/frontend/src/pages/Categories.tsx` | Kategorier |
| `/installningar` | `src/frontend/src/pages/Settings.tsx` | Inställningar |
| `/anvandare` | `src/frontend/src/pages/Users.tsx` | Användare (**Admin-only** — non-admins redirect to `/`) |

### Public routes (rarely the subject of a PR, but shootable without login)

| URL path | Page file |
|---|---|
| `/login` | `pages/Login.tsx` |
| `/privacy-policy` · `/privacy-policy/sv` | `pages/PrivacyPolicyEn.tsx` · `pages/PrivacyPolicy.tsx` |
| `/terms-of-service` · `/terms-of-service/sv` | `pages/TermsOfServiceEn.tsx` · `pages/TermsOfService.tsx` |

### Resolving a changed file to routes

- **`src/pages/X.tsx`** → 1:1 with the table above. A changed page = its route.
  (Exception: `pages/PolicyPage.tsx` has no route — skip it.)
- **`src/components/*`** (e.g. `AppShell`, `Popover`, `TransactionDetailDrawer`)
  → **shared**. These render on many/all routes. Propose the route(s) where the
  component is actually visible and the change would show. If unsure which,
  that's exactly why Step 2 asks the user to confirm — list your best guess and
  let them prune. `AppShell` = the sidebar/shell, visible on every protected
  route (shoot `/` as representative unless the change is nav-specific).
- **`src/lib/*`** (formatters, api, analysis helpers) → logic, usually **not**
  visually distinct on their own. Only propose a route if a specific screen's
  numbers/labels visibly change; otherwise say there's nothing worth shooting.
- **`src/index.css` / theme tokens** → global. If a token/color changed, one
  representative screen (`/`) usually demonstrates it; ask the user if they want
  more.

When a change is about **responsive/mobile** behaviour, capture the affected
route at both desktop and mobile widths (`--viewport both`).
