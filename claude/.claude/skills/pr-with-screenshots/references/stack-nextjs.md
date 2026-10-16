# Stack: Next.js (App Router) + Bun — e.g. dfteco / Amealyze 3

UI files: `app/**` (pages, layouts, `*-client.tsx`), `components/**`, and `lib/**`
only when a screen's numbers or labels visibly change. Read the repo's CLAUDE.md
first; dfteco's says: Swedish UI and PR text, no attribution lines, commits only
via `/commit`, and verify UI in Claude in Chrome (still do that; this skill only
adds the PR images).

## Dev server

`.claude/launch.json` (per worktree, gitignored) has `dev` → `bun run dev` on 3000.
Start it with `preview_start` `name: "dev"`, or reuse one that's running. With
parallel worktrees, port 3000 is often taken and Next steps to 3001, 3002…, so
check which checkout a port serves before shooting it:
```bash
for p in 3000 3001 3002 3003; do
  pid=$(lsof -tiTCP:$p -sTCP:LISTEN 2>/dev/null | head -1) || continue
  [ -n "$pid" ] && echo "$p -> $(lsof -a -p $pid -d cwd -Fn | sed -n 's/^n//p')"
done
```
Shoot the port whose cwd is the worktree with the changes. A worktree without
`.claude/launch.json`: run `bun run dev -- --port <free>` in the background and
stop it afterwards. The worktree needs `.env.local` and `node_modules`.

`next dev` appends an agent-rules block to `CLAUDE.md` on branches that lack
it. If you started the server in a checkout that isn't yours, restore it
afterwards (`git checkout -- CLAUDE.md`, only if that block is the sole change);
don't sneak it into the PR.

The first request to a route compiles it (10–30 s); `capture.mjs` waits up to
60 s. The Next dev indicator (`nextjs-portal`) is hidden by default.

## Login — interactive, once

Azure AD (MSAL) + PKCE, then a signed `session` cookie (HS256, 24 h, renewed
after 12 h on use). It can't be scripted, and the cookie in the user's Chrome
is httpOnly and can't be read out. So the user signs in once:
```bash
node ~/.claude/skills/pr-with-screenshots/scripts/login.mjs \
  --base-url http://localhost:3000 --cookie session \
  --state ~/.claude/skills/pr-with-screenshots/.auth/dfteco.json
```
Run it against port 3000 (the redirect URI Azure knows), whichever worktree
serves it. Cookies are per host, not per port, so the state then works on
3001, 3002… too. `capture.mjs` saves the renewed cookie after each run, so the
session lives as long as it's used at least once a day. Roles come from
`PeopleTable` by email on every request, so the shots show what the user sees.

Don't create or edit data just to get a nicer screenshot without asking. The dev
DB is shared, and prod is read-only.

## Route map

Derive from the file tree; there's no central route table:
```bash
find app -name page.tsx | sed -E 's#^app##; s#/page.tsx$##; s#/\([^)]*\)##g; s#^$#/#' | sort
```
- Route groups `(amealyze3)`, `(clients)`… vanish from the URL:
  `app/(amealyze3)/planning/plan-vs-actual/page.tsx` → `/planning/plan-vs-actual`.
- `[id]` / `[role]` need a real value. Take one from a link in the UI (e.g.
  `/clients` → a client) and confirm it in Step 2.
- Many screens read state from `searchParams` (month, team, filters). Put them in
  the route (`/planning/plan-vs-actual?month=2026-09`) so the shot shows the case
  the PR is about.
- Shared components (`components/**`, `app/**/_components`): grep for imports to
  find the pages that render them and propose one where the change is visible.
- `layout.tsx` / sidebar / `globals.css` / colour tokens: one representative page.
- Admin-only pages (`/admin/**`) need an admin user; say so if the shot bounces.
