---
name: pr-with-screenshots
description: >-
  Open a pull request whose description is illustrated with screenshots of the
  UI you just changed, so reviewers see what changed without checking out the
  branch. Use this whenever the user wants to "make/open a PR" for frontend/UI
  work and show the result visually — phrasings like "skapa en PR med
  screenshots", "PR för de här ändringarna med bilder", "visa ändringarna i
  PR:en", "PR med skärmdumpar", "screenshot PR", "PR som förklarar vad jag
  ändrat", or any PR request right after visible UI edits. Works on GitHub and
  Gitea, Next.js and Vite. Prefer this over a plain text PR whenever the diff
  touches rendered UI (pages/components/styles) — a picture explains a layout
  or styling change far better than a diff. Skip only for backend-only or
  non-visual changes where there is nothing to show.
---

# PR with screenshots

Turn local UI changes into a pull request whose body shows the *result*: a
focused crop of the changed component per affected screen, plus a short written
summary. A diff of Tailwind classes is hard to read; one picture makes it obvious.

Screenshots are real PNG files taken headless with Playwright
([scripts/capture.mjs](scripts/capture.mjs)) against the local dev server. Browser
tools (Claude in Chrome, the built-in browser) are for verifying, not for PR
images: their screenshots only reach the model, never a file.

## Step 0 — Detect host and stack

Read these once, then load the matching references:

| Check | Result | Reference |
|---|---|---|
| `git remote get-url origin` host is `github.com` | GitHub (default) | [host-github.md](references/host-github.md) |
| other host answering `/api/v1/version` | Gitea | [host-gitea.md](references/host-gitea.md) |
| `next` in `package.json` | Next.js | [stack-nextjs.md](references/stack-nextjs.md) |
| `vite` in `src/frontend/package.json` + .NET backend | Vite/.NET (Reda) | [stack-vite-dotnet.md](references/stack-vite-dotnet.md) |

Always read [capture.md](references/capture.md). Follow the repo's own conventions
(CLAUDE.md, commit rules, language) over anything here.

## Step 1 — Scope the change

- Not on `main`? If you are, branch first.
- Diff = `git diff main...HEAD --stat` plus `git status`/`git diff` for
  uncommitted work.
- Keep the UI files (the stack reference says where they live). None changed →
  say there's nothing visual to shoot and offer a plain PR.

## Step 2 — Confirm the shot list + crop

Propose before launching anything, then wait for the user's answer:

- Routes: map each changed page to its route and each shared component to a
  route where it is visible (stack reference has the mapping). Include query
  params or a real `[id]` when the screen needs them.
- Crop anchors from the diff: changed `aria-label`, `data-testid`, distinctive
  text or a unique class. Nothing distinctive → full page, say so.
- Mobile width only when the change is about responsive/mobile behaviour.
- After-only by default. Before/after only when the change fixes how an existing
  component looks, or the user asks (recipe in capture.md).

> Ändrade filer → **/planning/plan-vs-actual** (Plan mot utfall). Crop på kortet "Team under plan". Mobil också? Stämmer det?

## Step 3 — Capture

Start or reuse the dev server, make sure there is a saved session, run
`capture.mjs`, then **open every PNG** and check it shows the right screen with
data (no spinner, skeleton, error overlay or login page). Details in
[capture.md](references/capture.md) and the stack reference.

If the app won't start or log in, stop and report it. Never open a PR with
missing or blank screenshots, and never fall back to an image-less PR without
telling the user.

## Step 4 — Open the PR

Commit and push only as the repo's conventions allow (some repos want the user's
`/commit`; ask if unsure). Create the PR with the written summary first; images
need the PR number. Host reference has the commands.

## Step 5 — Illustrate

Upload the shots (GitHub: orphan branch `pr-assets`; Gitea: issue assets), then
rewrite the body. Lead with the crop; put the full page in `<details>`:

```markdown
<2–4 meningar om vad som ändrats och varför>

## Skärmar
### Plan mot utfall (`/planning/plan-vs-actual`): kortet Team under plan
![Team under plan](<crop-url>)
Vad som ändrats och vad man ska titta på.

<details><summary>Hela vyn</summary>

![Plan mot utfall](<full-url>)
</details>
```

Captions point the reviewer's eye ("teamraden visar nu timmar per kund"), not
restate the title. Mobile and before/after go side by side in a table.

## Step 6 — Report

PR URL plus one line on what was shot; name any requested screen that couldn't
be captured and why. Stop any dev server you started.
