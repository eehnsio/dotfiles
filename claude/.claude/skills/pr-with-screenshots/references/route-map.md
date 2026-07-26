# Route map — changed file → screenshot route(s)

Source of truth: `src/frontend/src/App.tsx` (routes) and
`src/frontend/src/components/AppShell.tsx` (nav labels). React Router 7,
`BrowserRouter`. Re-derive from `App.tsx` if this ever looks stale.

## Protected routes (the screenshottable app)

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

## Public routes (rarely the subject of a PR, but shootable without login)

| URL path | Page file |
|---|---|
| `/login` | `pages/Login.tsx` |
| `/privacy-policy` · `/privacy-policy/sv` | `pages/PrivacyPolicyEn.tsx` · `pages/PrivacyPolicy.tsx` |
| `/terms-of-service` · `/terms-of-service/sv` | `pages/TermsOfServiceEn.tsx` · `pages/TermsOfService.tsx` |

## Resolving a changed file to routes

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
route at both desktop and mobile widths (see `capture.md`).
