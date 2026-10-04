#!/bin/bash

# Fargerna anges som ANSI-koder, inte hex, sa statuslinjen foljer terminalens
# aktiva tema — samma princip som lsd och zsh-prompten.
#
# Tre nivaer, och ingen av dem ar dampad pa riktigt:
#
# De tre vardena man laser far var sin farg, men ur samma kalla familj sa
# raden hanger ihop i stallet for att bli en regnbage:
#
#   PATH    katalogen, cyan. Ankaret — #7dcfff ar samma bla som niris
#           fokusring, sa raden knyts till resten av riset.
#   BRANCH  grenen, bla. Granne med cyan i paletten: tydligt en egen sak,
#           men uppenbart slakt. Bada svarar pa "var ar jag".
#   MODEL   modellen, magenta. Ett annat SLAGS uppgift — vem, inte var —
#           och far darfor en farg utanfor det blagrona paret. Effort-nivan
#           hor till samma fraga och delar fargen.
#
#   COUNT   siffrorna, gront: commits att pusha eller hamta, andrade rader,
#           och kontextfonstret sa lange det mar bra. En hue for hela
#           "hur mycket"-familjen.
#
#   SOFT    BARA bindeord och skiljetecken: "in", parenteser, stapeln.
#
# Regeln ar att ALLT som ar ett varde far en kulor. Ingenting ligger kvar pa
# \033[39m: den fargen ar terminalens standardforgrund utan egen ton, och
# eftersom Claude Code redan ritar hela raden nedtonad tappar just den mest.
# "13 commits att pusha" forsvann pa exakt det sattet.
#
# De fyra hue:erna ar alla kalla. Det ar med flit: gult och rott anvands ingen
# annanstans i raden, sa nar kontextfonstret borjar ta slut eller cachen gatt
# kall ar det den enda varma farg som finns och gar inte att missa.
#
# Har fanns tidigare ett fjarde steg pa \033[90m. Det ar #414868 i den har
# paletten, och statuslinjen ritas dessutom redan nedtonad av Claude Code —
# tillsammans blev det osynligt. Aven \033[37m visade sig for svagt for
# siffror. Slutsatsen: i en rad som redan ar nedtonad av varden finns det
# bara plats for EN nivas skillnad, och den far ligga pa skiljetecknen.
#
# Gult och rott ar reserverat for varningar: kontextfonstret nar det borjar ta
# slut, och gult aven for en kall promptcache. Semantisk farg och accentfarg
# ar tva olika saker: radantal fargas inte gront och rott, for tillagda rader
# ar inte "bra" och borttagna inte "daliga".

PATH_C='\033[36m'
BRANCH_C='\033[34m'
MODEL_C='\033[35m'
COUNT_C='\033[32m'
SOFT='\033[37m'
WARN='\033[33m'
CRIT='\033[31m'
RESET='\033[0m'

input=$(cat)

model_name=$(echo "$input" | jq -r '.model.display_name // "Claude"')
# Saknas nar modellen inte stoder effort-parametern.
effort=$(echo "$input" | jq -r '.effort.level // empty')
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

# Sessionens namn forst, i fet stil: det ar vad man letar efter nar man hoppar
# mellan terminalfonster. Namnet tas ur ~/.claude/sessions/<pid>.json, inte ur
# session_name (som ar titeln), sa det ar samma namn som sessions-modden och
# SendMessage anvander for att peka ut den.
#
# Ett namn man satt sjalv med /rename (nameSource "user") ritar Claude Code
# redan i promptens ram, sa da hoppas det over har i stallet for att sta
# tva ganger. Det ar de genererade namnen (dotfiles-46) som annars inte syns.
session_id=$(echo "$input" | jq -r '.session_id // empty')
session_label=""
if [ -n "$session_id" ]; then
    session_file=$(grep -l "\"sessionId\":\"$session_id\"" "$HOME"/.claude/sessions/*.json 2>/dev/null | head -1)
    [ -n "$session_file" ] && session_label=$(jq -r 'select(.nameSource != "user") | .name // empty' "$session_file" 2>/dev/null)
fi

line=""
[ -n "$session_label" ] && line+=$(printf "\033[1m${PATH_C}%s${RESET}${SOFT} ·${RESET} " "$session_label")
line+=$(printf "${MODEL_C}%s${RESET}" "$model_short")
[ -n "$effort" ] && line+=$(printf " ${MODEL_C}%s${RESET}" "$effort")
line+=$(printf "${SOFT} in${RESET}")
line+=$(printf " ${PATH_C}%s${RESET}" "$dir_display")

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

                    [ "$ahead" != "0" ] && ahead_behind+=$(printf " ${COUNT_C}↑%s${RESET}" "$ahead")
                    [ "$behind" != "0" ] && ahead_behind+=$(printf " ${COUNT_C}↓%s${RESET}" "$behind")
                fi
            fi

            diff_stats=$(git -c gc.auto=0 diff --numstat HEAD 2>/dev/null | awk '{a+=$1; d+=$2} END {print a, d}')
            lines_added=$(echo "$diff_stats" | awk '{print $1}')
            lines_removed=$(echo "$diff_stats" | awk '{print $2}')

            git_diff_str=""
            if [ -n "$lines_added" ] && [ "$lines_added" != "0" ]; then
                git_diff_str+=$(printf " ${COUNT_C}+%s${RESET}" "$lines_added")
                [ -n "$lines_removed" ] && [ "$lines_removed" != "0" ] && git_diff_str+=$(printf "${COUNT_C}/-%s${RESET}" "$lines_removed")
            elif [ -n "$lines_removed" ] && [ "$lines_removed" != "0" ]; then
                git_diff_str+=$(printf " ${COUNT_C}-%s${RESET}" "$lines_removed")
            fi

            line+=$(printf " ${SOFT}(${RESET}${BRANCH_C}%s${RESET}%s%s${SOFT})${RESET}" \
                "$branch" "$ahead_behind" "$git_diff_str")
        fi
    fi
fi

# Null fore forsta API-svaret och efter /compact. Doljs hellre an att visa
# 100%: efter en compact ar fonstret inte tomt, bara okant tills nasta svar.
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty | floor')

if [ -n "$remaining" ]; then
    # Normal ljusstyrka sa lange det inte ar ett problem. Farg forst nar det ar det.
    if [ $remaining -gt 50 ]; then
        context_color="$COUNT_C"
    elif [ $remaining -gt 20 ]; then
        context_color="$WARN"
    else
        context_color="$CRIT"
    fi

    line+=$(printf " ${SOFT}|${RESET} ${context_color}%d%% free${RESET}" "$remaining")
fi

# Promptcachen: tid kvar tills den gar kall, eftersom nasta prompt da far
# skriva om hela prefixet. expires_at ar epoch-sekunder; raden ritas om var
# 30:e sekund (refreshInterval i settings.json) sa nedrakningen tickar aven
# nar man star still. Varnfarg de sista fem minuterna och nar den ar kall.
# Saknas fore forsta API-svaret, och doljs om ingen caching har observerats.
cache=$(echo "$input" | jq -r '.prompt_cache // empty
    | select(.caching_observed)
    | if .warm and .expires_at then (.expires_at | floor | tostring) else "cold" end')

if [ -n "$cache" ] && [ "$cache" != "cold" ]; then
    left=$(( cache - $(date +%s) ))
    if [ $left -le 0 ]; then
        cache="cold"
    elif [ $left -lt 60 ]; then
        line+=$(printf " ${SOFT}| cache${RESET} ${WARN}%ds${RESET}" "$left")
    else
        # Avrundat uppat: "1m" ska betyda att det finns minst en minut kvar.
        [ $left -le 300 ] && cache_color="$WARN" || cache_color="$COUNT_C"
        line+=$(printf " ${SOFT}| cache${RESET} ${cache_color}%dm${RESET}" $(( (left + 59) / 60 )))
    fi
fi

[ "$cache" = "cold" ] && line+=$(printf " ${SOFT}| cache${RESET} ${WARN}cold${RESET}")

printf "%s" "$line"
