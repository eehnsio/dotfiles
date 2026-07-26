---
name: pr-with-screenshots
description: >-
  Open a pull request whose description is illustrated with screenshots of the
  UI you just changed, so reviewers see what changed without checking out the
  branch. Use this whenever the user wants to "make/open a PR" for frontend/UI
  work and show the result visually — phrasings like "skapa en PR med
  screenshots", "PR för de här ändringarna med bilder", "visa ändringarna i
  PR:en", "screenshot PR", "PR som förklarar vad jag ändrat", or any PR request
  right after visible UI edits. Prefer this over a plain text PR whenever the
  diff touches rendered UI (pages/components/styles) — a picture explains a
  layout or styling change far better than a diff. Skip only for backend-only
  or non-visual changes where there is nothing to show.
---

# PR with screenshots

Turn a set of local UI changes into a pull request whose body shows the *result*
— annotated screenshots of the affected screens in their new state — alongside a
short written summary. The point is reviewer empathy: a diff of Tailwind classes
or a flex tweak is hard to read, but one screenshot of the screen makes the
change obvious.

This skill is for **this repo's** stack (React + Vite frontend, .NET backend,
Gitea remote). It captures the **after** state with real data from the running
instance and embeds the images in a Gitea PR.

## When to reach for it

Trigger when there are uncommitted or freshly-committed **frontend** changes and
the user wants a PR that explains them visually. If the diff is backend-only or
has no rendered surface, a normal PR is enough — say so instead of forcing
screenshots.

## Workflow overview

1. **Scope the change** — figure out the branch, the diff, and which screens are affected.
2. **Confirm the shot list + crop** — propose the routes *and* the focused crop of the changed component from the diff; let the user adjust before spending time launching the app.
3. **Capture** — launch the app (with the working-tree changes), log in, screenshot each confirmed route: a full-page shot plus a focused crop of the change.
4. **Open the PR** — commit/push if needed, create the Gitea PR.
5. **Illustrate** — upload the screenshots to the PR and embed them in the body with captions + a short written summary.
6. **Report** — give the user the PR URL.

Do the cheap, reversible thinking (steps 1–2) before the expensive part (step 3
launches a dev server and a browser). Never capture screens the user didn't
confirm — it wastes time and may shoot the wrong route.

---

## Step 1 — Scope the change

- Confirm the current branch is **not** `main`. If it is, create a feature
  branch off `main` first (ask for or infer a name from the change).
- Get the diff that will become the PR: everything on the branch since `main`
  plus any uncommitted working-tree changes. Use both
  `git diff main...HEAD --stat` and `git status`/`git diff` so nothing is missed.
- Restrict attention to the frontend: files under `src/frontend/src/`. If none
  changed, tell the user there's nothing visual to shoot and offer a plain PR.

## Step 2 — Confirm the shot list + crop (auto-suggest, then confirm)

From the changed frontend files, propose which routes to screenshot **and which
part of each screen to focus on**, then **let the user confirm or edit** before
launching anything.

- Map each changed **page** file to its route, and each changed **shared
  component** to every route that renders it. See
  [references/route-map.md](references/route-map.md) for the route table and how
  to resolve a component to its routes.
- **Propose a focused crop.** A full-page shot is usually too much noise — the
  reviewer wants to see *the changed component*. Read the diff for stable anchors
  to crop around: new/changed `aria-label=`, `data-testid=`, distinctive visible
  text, or a unique class. Propose them; the user knows the UI and can correct.
  (E.g. a period-stepper change → anchors `[aria-label="Föregående månad"]`,
  `[aria-label="Nästa månad"]`, the month `button`.) If nothing distinctive
  exists, fall back to full-page and say so.
- Present the proposal concisely, e.g.:
  > Ändrade filer → vy **/** (Periodöversikt). Fokus-crop på period-stegaren (‹ › + månadsdropdown). Ser det rätt ut? Lägg till/ta bort vyer eller ändra fokus?
- Wait for the user's answer. Keep their final routes + crop anchors.

## Step 3 — Capture the screenshots (after state)

Launch the app so it serves the **working-tree** version (the changes must be
visible), authenticate a headless browser, and screenshot each route on the shot
list. Full recipe — commands, ports, login, Playwright script — in
[references/capture.md](references/capture.md).

Key points:
- Screenshot the **new** state only (v1 is after-only, no before/after).
- Capture **both** a full-page shot (context) **and a focused crop** of the
  changed component when crop anchors were confirmed in Step 2. The crop is the
  union box of the anchors plus context padding (`--crop-pad`, ~48px default) so
  the change is legible without the whole page — the crop is what leads the PR.
- Use a consistent viewport so shots look uniform (desktop width; also grab a
  mobile-width shot when the change is about responsive/mobile behaviour).
- Save images to a temp dir; name them after the route so captions are obvious
  (e.g. `home.png`, `home-period-nav.png` for the crop).
- If the app fails to start or log in, stop and report the blocker — do **not**
  open a PR with missing/blank screenshots.

## Step 4 — Open the PR

- If there are uncommitted changes, commit them on the feature branch with a
  clear message (Swedish `feat:`/`fix:` prefix matching repo convention), then
  push with `-u`.
- Create the PR against `main` on Gitea. Full API recipe (auth, endpoints) in
  [references/gitea-pr.md](references/gitea-pr.md).
- Write the body summary first (2–4 sentences on *what* changed and *why*),
  before adding images.

## Step 5 — Illustrate the PR

- Upload each screenshot to the PR and embed it in the body under a caption that
  names the screen and what to look at. Exact upload + embed mechanism in
  [references/gitea-pr.md](references/gitea-pr.md).
- **Lead with the focused crop** — it's what explains the change. Offer the
  full-page shot as secondary context (a `<details>` block) so reviewers can see
  the change in situ without it dominating.
- Suggested body shape:
  ```markdown
  <2–4 sentence summary of the change and its motivation>

  ## Skärmar
  ### Periodöversikt (/) — period-stegaren
  ![Period-stegaren](<crop-url>)
  Kort bildtext: vad som ändrats och vad man ska titta på.

  <details><summary>Hela vyn</summary>

  ![Periodöversikt](<full-url>)
  </details>
  ```
- Order screens to match the user's shot list.

## Step 6 — Report

Give the user the PR URL and a one-line recap of what was captured. Mention any
route the user asked for that couldn't be shot and why.

---

## References

- [references/route-map.md](references/route-map.md) — path → page-file table and component→route resolution.
- [references/capture.md](references/capture.md) — launch the app, log in, drive Playwright, save shots.
- [references/gitea-pr.md](references/gitea-pr.md) — create the PR, upload images, embed in the body.
