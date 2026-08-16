#!/usr/bin/env bash
# SessionStart: säg till om ~/.claude/settings.json har slutat vara en
# symlänk in i dotfiles.
#
# Claude Code skriver om settings.json när man ändrar något i /config, och
# har minst en gång ersatt stow-länken med en vanlig fil (mode 600). Då
# börjar live-konfigurationen och flottans baslinje glida isär utan att
# någon märker det. Den här kollen gör det synligt nästa gång du startar.

# Av-knapp per maskin. ~/.claude/hooks ar en stow-symlank in i repot, sa
# markeringen far INTE ligga dar — den hade folgt med i git. ~/.claude ar
# daremot en riktig katalog.
[ -e "$HOME/.claude/hooks.disabled" ] && exit 0

set -uo pipefail

live="$HOME/.claude/settings.json"

# Följ symlänkar i skriptets egen sökväg, så att repo-filen hittas även när
# hooken körs via ~/.claude/hooks -> dotfiles.
here=$(cd -P "$(dirname "$0")" && pwd) || exit 0
repo="$here/../settings.json"

[ -f "$repo" ] || exit 0
[ -L "$live" ] && exit 0   # länken håller, inget att säga

if [ ! -e "$live" ]; then
  msg="~/.claude/settings.json saknas. Återställ med: ln -sfn ../Developer/dotfiles/claude/.claude/settings.json ~/.claude/settings.json"
elif diff -q "$live" "$repo" >/dev/null 2>&1; then
  msg="~/.claude/settings.json är inte längre en symlänk till dotfiles (innehållet matchar än). Återställ: ln -sfn ../Developer/dotfiles/claude/.claude/settings.json ~/.claude/settings.json"
else
  msg="~/.claude/settings.json har glidit isär från dotfiles. Jämför med: diff ~/.claude/settings.json $repo"
fi

if command -v jq >/dev/null 2>&1; then
  jq -nc --arg m "$msg" '{systemMessage: $m}'
else
  printf '%s\n' "$msg" >&2
fi
