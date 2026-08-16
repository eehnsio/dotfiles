#!/usr/bin/env bash
# PreToolUse/Bash guard: never let Claude Code run a recursive+force delete
# without a manual approval prompt, regardless of permission mode.
#
# Flags any `rm` invocation that ends up with BOTH a recursive flag
# (-r / -R / --recursive) and a force flag (-f / --force), in any order or
# spelling, anywhere in the command line -- including behind sudo, xargs,
# find -exec, or inside a quoted `bash -c "..."`.
#
# Emits an "ask" decision so the command still runs after you approve it.

# Av-knapp per maskin. ~/.claude/hooks ar en stow-symlank in i repot, sa
# markeringen far INTE ligga dar — den hade folgt med i git. ~/.claude ar
# daremot en riktig katalog.
[ -e "$HOME/.claude/hooks.disabled" ] && exit 0

set -uo pipefail

payload=$(cat)
cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
[ -z "$cmd" ] && exit 0

# Put shell separators on their own token so flag state resets between commands.
spaced=$(printf '%s' "$cmd" \
  | tr '\n\t' '  ' \
  | sed -E 's/&&/ \&\& /g; s/\|\|/ \|\| /g; s/([;&|()])/ \1 /g')

read -ra toks <<<"$spaced"

in_rm=0 rec=0 frc=0 hit=0
for t in "${toks[@]}"; do
  case "$t" in
    ';' | '&' | '&&' | '|' | '||' | '(' | ')')
      in_rm=0 rec=0 frc=0
      continue
      ;;
  esac

  # Strip surrounding quotes so `"rm"` and `'-rf'` still match.
  t=${t#[\"\']}
  t=${t%[\"\']}

  if [ "${t##*/}" = "rm" ]; then
    in_rm=1 rec=0 frc=0
    continue
  fi

  [ "$in_rm" -eq 1 ] || continue

  case "$t" in
    --recursive | --recursive=*) rec=1 ;;
    --force | --force=*) frc=1 ;;
    --*) ;;
    -*)
      case "$t" in *[rR]*) rec=1 ;; esac
      case "$t" in *f*) frc=1 ;; esac
      ;;
  esac

  if [ "$rec" -eq 1 ] && [ "$frc" -eq 1 ]; then
    hit=1
    break
  fi
done

[ "$hit" -eq 1 ] || exit 0

jq -nc --arg cmd "$cmd" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "ask",
    permissionDecisionReason: ("Recursive force delete (rm -rf) requires manual approval. Command: " + $cmd)
  }
}'
