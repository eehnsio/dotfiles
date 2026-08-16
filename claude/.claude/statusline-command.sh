#!/bin/bash

# Fargerna anges som ANSI-koder, inte hex, sa statuslinjen foljer terminalens
# aktiva tema — samma princip som lsd och zsh-prompten.
#
# Fyra nivaer, och bara den lagsta ar riktigt dampad:
#
#   ACCENT  katalogen. Det man faktiskt letar efter i raden, och i
#           noctalia-paletten ar cyan #7dcfff, alltsa samma bla som niris
#           fokusring.
#   FG      modell och gren — radens innehall, i normal ljusstyrka.
#   SOFT    siffror: radantal, pilar, procent. Lasbara men underordnade.
#   DIM     BARA bindeord och skiljetecken: "in", parenteser, stapeln.
#
# DIM ar \033[90m, vilket i den har paletten ar #414868 — nastan bakgrunds-
# farg. Den duger for tecken man aldrig behover lasa, men allt som bar
# information maste ligga hogre. Ett forsta forsok satte hela raden pa DIM
# och blev oläsbart.
#
# Gult och rott ar reserverat for kontextfonstret, och bara nar det borjar ta
# slut. Semantisk farg och accentfarg ar tva olika saker: radantal fargas inte
# gront och rott, for tillagda rader ar inte "bra" och borttagna inte "daliga".

ACCENT='\033[36m'
FG='\033[39m'
SOFT='\033[37m'
DIM='\033[90m'
WARN='\033[33m'
CRIT='\033[31m'
RESET='\033[0m'

input=$(cat)

model_name=$(echo "$input" | jq -r '.model.display_name // "Claude"')
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // ""')
project_dir=$(echo "$input" | jq -r '.workspace.project_dir // ""')

if [ -n "$current_dir" ]; then
    dir_display="$current_dir"
else
    dir_display="$(pwd)"
fi

HOME_DIR="${HOME}"
if [[ "$dir_display" == "$HOME_DIR"* ]]; then
    dir_display="~${dir_display#$HOME_DIR}"
fi

IFS='/' read -ra DIR_PARTS <<< "$dir_display"
num_parts=${#DIR_PARTS[@]}

if [ $num_parts -gt 2 ]; then
    if [[ "$dir_display" == "~"* ]]; then
        dir_display="~/…/${DIR_PARTS[$((num_parts-2))]}/${DIR_PARTS[$((num_parts-1))]}"
    else
        dir_display="…/${DIR_PARTS[$((num_parts-2))]}/${DIR_PARTS[$((num_parts-1))]}"
    fi
fi

model_short=$(echo "$model_name" | sed -E 's/^Claude[[:space:]]+//' | sed -E 's/([0-9]+\.[0-9]+)[[:space:]]+([A-Z][a-z]+)/\2 \1/')

line=""
line+=$(printf "${FG}%s${RESET}${DIM} in${RESET}" "$model_short")
line+=$(printf " ${ACCENT}%s${RESET}" "$dir_display")

if [ -n "$project_dir" ] && cd "$project_dir" 2>/dev/null; then
    if git rev-parse --git-dir >/dev/null 2>&1; then
        branch=$(git -c gc.auto=0 symbolic-ref --short HEAD 2>/dev/null || git -c gc.auto=0 rev-parse --short HEAD 2>/dev/null)
        if [ -n "$branch" ]; then
            ahead_behind=""
            upstream=$(git -c gc.auto=0 rev-parse --abbrev-ref @{upstream} 2>/dev/null)
            if [ -n "$upstream" ]; then
                counts=$(git -c gc.auto=0 rev-list --count --left-right @{upstream}...HEAD 2>/dev/null)
                if [ -n "$counts" ]; then
                    behind=$(echo "$counts" | awk '{print $1}')
                    ahead=$(echo "$counts" | awk '{print $2}')

                    [ "$ahead" != "0" ] && ahead_behind+=$(printf " ${SOFT}↑%s${RESET}" "$ahead")
                    [ "$behind" != "0" ] && ahead_behind+=$(printf " ${SOFT}↓%s${RESET}" "$behind")
                fi
            fi

            diff_stats=$(git -c gc.auto=0 diff --numstat HEAD 2>/dev/null | awk '{a+=$1; d+=$2} END {print a, d}')
            lines_added=$(echo "$diff_stats" | awk '{print $1}')
            lines_removed=$(echo "$diff_stats" | awk '{print $2}')

            git_diff_str=""
            if [ -n "$lines_added" ] && [ "$lines_added" != "0" ]; then
                git_diff_str+=$(printf " ${SOFT}+%s${RESET}" "$lines_added")
                [ -n "$lines_removed" ] && [ "$lines_removed" != "0" ] && git_diff_str+=$(printf "${SOFT}/-%s${RESET}" "$lines_removed")
            elif [ -n "$lines_removed" ] && [ "$lines_removed" != "0" ]; then
                git_diff_str+=$(printf " ${SOFT}-%s${RESET}" "$lines_removed")
            fi

            line+=$(printf " ${DIM}(${RESET}${FG}%s${RESET}%s%s${DIM})${RESET}" \
                "$branch" "$ahead_behind" "$git_diff_str")
        fi
    fi
fi

usage=$(echo "$input" | jq '.context_window.current_usage')
context_size=$(echo "$input" | jq '.context_window.context_window_size // 0')

if [ "$usage" != "null" ] && [ "$context_size" -gt 0 ]; then
    input_tokens=$(echo "$usage" | jq '.input_tokens // 0')
    cache_creation=$(echo "$usage" | jq '.cache_creation_input_tokens // 0')
    cache_read=$(echo "$usage" | jq '.cache_read_input_tokens // 0')

    total_sent=$((input_tokens + cache_creation + cache_read))
    pct=$((total_sent * 100 / context_size))
    remaining=$((100 - pct))

    # Grtt sa lange det inte ar ett problem. Farg bara nar det borjar bli det.
    if [ $remaining -gt 50 ]; then
        context_color="$SOFT"
    elif [ $remaining -gt 20 ]; then
        context_color="$WARN"
    else
        context_color="$CRIT"
    fi

    line+=$(printf " ${DIM}|${RESET} ${context_color}%d%% free${RESET}" "$remaining")
fi

printf "%s" "$line"
