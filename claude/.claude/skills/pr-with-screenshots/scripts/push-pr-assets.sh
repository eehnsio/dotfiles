#!/usr/bin/env bash
# push-pr-assets.sh — put PR screenshots on the orphan branch `pr-assets` and print
# a Markdown-ready URL per file. Never touches the working tree, the index or the
# current branch (pure git plumbing with a throwaway index), so it is safe from any
# worktree and never puts images on main.
#
# Usage: push-pr-assets.sh [--dry-run] <pr-number> <file.png>...
#   --dry-run  build the commit but push nothing; list its files on stderr and
#              print the URLs the files would get.
#
# Files land at pr-assets:<pr-number>/<basename>. Re-pushing a name replaces it.
# The branch root always gets a vercel.json with git.deploymentEnabled=false, in
# the same commit as the images: otherwise Vercel tries to build the app from a
# branch holding only PNGs and mails a failed preview build.
# Retries on non-fast-forward, since parallel sessions push to the same branch.
set -euo pipefail

BRANCH=pr-assets
dry=0
if [[ "${1:-}" == "--dry-run" ]]; then dry=1; shift; fi
[[ $# -ge 2 ]] || { echo "usage: $0 [--dry-run] <pr-number> <file>..." >&2; exit 2; }
pr=$1; shift

remote_url=$(git remote get-url origin)
host=$(sed -E 's#^(https?://|git@)([^/:]+).*#\2#' <<<"$remote_url")
slug=$(sed -E 's#^(https?://[^/]+/|git@[^:]+:)##; s#\.git$##' <<<"$remote_url")

idx=$(mktemp -t pr-assets-index.XXXXXX)
trap 'rm -f "$idx"' EXIT

for attempt in 1 2 3; do
  rm -f "$idx"
  parent=""
  if git fetch -q origin "$BRANCH" 2>/dev/null; then
    parent=$(git rev-parse FETCH_HEAD)
    GIT_INDEX_FILE=$idx git read-tree "$parent"
  else
    GIT_INDEX_FILE=$idx git read-tree --empty
  fi
  if [[ -z $(GIT_INDEX_FILE=$idx git ls-files vercel.json) ]]; then
    blob=$(printf '{"git": {"deploymentEnabled": false}}\n' | git hash-object -w --stdin)
    GIT_INDEX_FILE=$idx git update-index --add --cacheinfo "100644,$blob,vercel.json"
  fi
  for f in "$@"; do
    blob=$(git hash-object -w "$f")
    GIT_INDEX_FILE=$idx git update-index --add --cacheinfo "100644,$blob,$pr/$(basename "$f")"
  done
  tree=$(GIT_INDEX_FILE=$idx git write-tree)
  commit=$(git commit-tree "$tree" ${parent:+-p "$parent"} -m "chore: skärmbilder för PR #$pr")
  if (( dry )); then
    echo "dry run: $commit not pushed, files on $BRANCH:" >&2
    git ls-tree -r --name-only "$commit" >&2
    break
  fi
  if git push -q origin "$commit:refs/heads/$BRANCH"; then break; fi
  (( attempt == 3 )) && { echo "push to $BRANCH failed 3 times" >&2; exit 1; }
  echo "push rejected, retrying ($attempt)…" >&2
done

for f in "$@"; do
  name=$(basename "$f")
  if [[ "$host" == "github.com" ]]; then
    echo "https://github.com/$slug/blob/$BRANCH/$pr/$name?raw=true"
  else
    echo "https://$host/$slug/raw/branch/$BRANCH/$pr/$name"
  fi
done
