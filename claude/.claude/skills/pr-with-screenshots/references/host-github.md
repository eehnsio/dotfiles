# GitHub — create the PR, host images, embed them

GitHub has no API for PR image uploads (drag-and-drop `user-attachments` is
web-UI only). Images therefore live on an **orphan branch `pr-assets`** in the
same repo:

- Members-only in a private repo, same as the code. Never a gist or anything
  public: shots contain real data.
- Never merged, so nothing lands on `main` or in the PR's diff.
- `blob/…?raw=true` renders inline in PR bodies for anyone who can read the repo.
- Files stay after merge so old PRs keep their pictures. Don't prune the branch.
- The root holds a `vercel.json` with `{"git": {"deploymentEnabled": false}}`.
  Without it Vercel builds every push to the branch as a preview, fails (there
  is no app, only PNGs) and mails about it. The script adds the file in the
  same commit as the first images and leaves an existing one alone.

`pr-assets` is the only name. Don't create other image branches (dfteco also
has an older `pr-bilder` from an ad-hoc run; leave it, push nothing new there).
A repo without `pr-assets` gets it from the script on first upload.

Rejected: committing images on the PR branch (they reach `main` on merge),
release assets (a fake release per PR), secret gists (public by link).

## A — push the branch, create the PR

```bash
git push -u origin HEAD
gh pr create --base main --title "<titel>" --body-file "$SCRATCH/body.md"
NUM=$(gh pr view --json number --jq .number)
```
Write `body.md` with the summary only; images come after. Title and language
follow the repo (dfteco: Swedish, `feat:`/`fix:`, no attribution lines).
PR already exists for the branch → `gh pr view --json number`.

## B — upload the shots

```bash
~/.claude/skills/pr-with-screenshots/scripts/push-pr-assets.sh "$NUM" \
  "$SCRATCH/shots/planning-plan-vs-actual-under-plan.png" "$SCRATCH/shots/planning-plan-vs-actual.png"
```
Prints one URL per file, in order:
`https://github.com/<owner>/<repo>/blob/pr-assets/<NUM>/<file>?raw=true`.
Uses git plumbing with a temporary index, so it doesn't touch the working tree
or current branch, and retries if another session pushed to `pr-assets` first.
`--dry-run` builds the commit without pushing and lists the branch's files on
stderr (`vercel.json` should be among them).

Give files descriptive names before uploading (`under-plan.png`, not
`shot-1.png`); the name is visible in the URL. Re-pushing a name replaces it.
GitHub may cache the old image for a few minutes; use a new name if a re-shoot
must show at once.

## C — embed

Append the "Skärmar" section (shape in SKILL.md) to `body.md`, then:
```bash
gh pr edit "$NUM" --body-file "$SCRATCH/body.md"
```
Use the full `https://github.com/...?raw=true` URL. Relative links don't resolve
in PR bodies.

## D — verify

`gh pr view "$NUM" --web` is for the user; you can check with
`gh api repos/<owner>/<repo>/contents/<NUM>?ref=pr-assets --jq '.[].name'`
that every file arrived. Report the PR URL.
