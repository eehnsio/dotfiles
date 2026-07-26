# Gitea — create the PR, upload images, embed them

Verified against this instance: **Gitea 1.26.2**. A PR is an issue, so its
`number` is also its issue `index`. Screenshots go up as issue **assets** and
embed by their `browser_download_url`. Those URLs are **members-only** (anonymous
→ 404), so real data in the shots stays inside the repo — no public leak.

## Auth + repo identity

```bash
CRED=$(printf "protocol=https\nhost=gitea.shcizo.se\n\n" | git credential fill)
USER=$(printf "%s" "$CRED" | sed -n 's/^username=//p')
TOKEN=$(printf "%s" "$CRED" | sed -n 's/^password=//p')
# Derive owner/repo from origin (works if the remote is this Gitea repo):
SLUG=$(git remote get-url origin | sed -E 's#.*/([^/]+/[^/]+?)(\.git)?$#\1#')  # -> shcizo/economics
HOST=$(git remote get-url origin | sed -E 's#https?://([^/]+)/.*#\1#')          # -> gitea.shcizo.se
API="https://$HOST/api/v1/repos/$SLUG"
```
Basic-auth-with-password is unscoped and works as long as the user has write on
the repo. (A fine-grained PAT would need `write:repository`.)

## Step A — make sure the branch is pushed

The PR needs the head branch on the remote. If the feature branch has unpushed
commits, `git push -u origin <branch>` first. Never open the PR from `main`.

## Step B — create the PR (summary body first)

```bash
NUM=$(curl -s -u "$USER:$TOKEN" -X POST -H "Content-Type: application/json" \
  "$API/pulls" \
  --data "$(jq -n --arg t "<title>" --arg h "<head-branch>" --arg b "<summary>" \
    '{title:$t, head:$h, base:"main", body:$b}')" \
  | jq -r '.number')
```
- `title`: Swedish `feat:`/`fix:` prefix, matching repo convention.
- `body` (summary): 2–4 sentences on *what* changed and *why*. Images get added
  in Step D — write the prose now so the PR is coherent even before shots upload.
- If creation fails, inspect the JSON (`message`) — common causes: PR already
  exists for this head (then fetch its number via
  `GET "$API/pulls?state=open&head=$SLUG_OWNER:<branch>"`), or head not pushed.

## Step C — upload each screenshot as an asset

```bash
upload() {  # $1 = png path, $2 = display name -> prints browser_download_url
  curl -s -u "$USER:$TOKEN" -X POST \
    -F "attachment=@$1;type=image/png" \
    "$API/issues/$NUM/assets?name=$2" | jq -r '.browser_download_url'
}
URL_HOME=$(upload /tmp/reda-shots/home.png periodoversikt.png)
URL_TX=$(upload /tmp/reda-shots/transaktioner.png transaktioner.png)
```
- Field name is `attachment`; the `?name=` keeps a real `.png` extension so it
  renders inline.
- Endpoint returns **201** with `{ id, uuid, browser_download_url, ... }`. Embed
  `browser_download_url` verbatim.
- One asset per shot. Keep the returned URLs paired with their route/caption.

## Step D — embed the images in the PR body

Rebuild the body = summary + a "Skärmar" section, one subsection per shot, then
PATCH it in. Order to match the user's shot list.

```bash
BODY=$(printf '%s\n\n## Skärmar\n\n### Periodöversikt (`/`)\n![Periodöversikt](%s)\n%s\n\n### Transaktioner (`/transaktioner`)\n![Transaktioner](%s)\n%s\n' \
  "<summary>" \
  "$URL_HOME" "Bildtext: vad som ändrats och vad man ska titta på." \
  "$URL_TX"   "Bildtext: …")

curl -s -u "$USER:$TOKEN" -X PATCH -H "Content-Type: application/json" \
  "$API/pulls/$NUM" \
  --data "$(jq -n --arg b "$BODY" '{body:$b}')" >/dev/null
```
Each caption should name the screen and point at what changed ("vänsterkolumnen
slutar nu vid sista kategorin"), not just restate the title — the whole value of
the screenshot is directing the reviewer's eye.

## Step E — report

Print the PR URL: `https://$HOST/$SLUG/pulls/$NUM`. Recap which routes were shot,
and flag any the user asked for that couldn't be captured.

## Notes

- **Mobile shots**: when `--viewport both` produced `-mobile.png` files, upload
  them too and put desktop + mobile side by side under the same screen heading.
- **Idempotency**: re-running on the same PR appends new assets and overwrites
  the body via PATCH — fine for iterating, but old assets stay attached
  (harmless). If you re-shoot, upload fresh and rebuild the body from the new
  URLs.
- **Fallback (not needed on 1.26.2)**: if the assets endpoint were unavailable,
  commit the PNGs into the branch and reference
  `https://$HOST/$SLUG/raw/branch/<branch>/<path>` (also members-only, also
  inline) — but that pollutes the diff with binaries, so prefer assets.
