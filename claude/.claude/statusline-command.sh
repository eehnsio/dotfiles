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
#   SOFT    BARA etiketter och avgransaren: "cache", "5h", "7d", strecket.
#           Raden var forst en mening ("Opus in ~/x (main) | 64% free") men
#           delarna laste man aldrig som en mening, bara var for sig. Som
#           avgransare provades en mittpunkt (vidrig) och bara mellanrum
#           (delarna flot ihop).
#
# Fran yugal1107/ui-themes kommer Nerd Font-ikonerna for katalog och gren,
# och anvandningsgranserna for 5h och 7d, hogerstallda med tid kvar till
# nollning. Modellen fick en ikon per familj ocksa, men namnet racker.
# Katalogikonen ar Material-varianten: Font Awesome-mappen var for liten i
# UbuntuMono bredvid de andra.
# Gransernas procent ar anvandning, inte "free" som kontextfonstret, for det
# ar sa Claude Code sjalv anger dem; troskeln ar densamma at andra hallet.
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

SEP=" ${SOFT}│${RESET} "

line=""
# Jobbkontot (claude-kurs i .zshrc) delar allt utom inloggningen med
# privatkontot, sa det ar bara har man ser vilket konto sessionen kor pa.
# Etiketten ar det enda i raden med bakgrundsfarg, och gul eftersom fel konto
# ar en varning.
if [[ "${CLAUDE_CONFIG_DIR%/}" == *.claude-kurs ]]; then
    line+=$(printf '\033[1;30;43m KURS \033[0m ')
fi
line+=$(printf "${MODEL_C}%s${RESET}" "$model_short")
[ -n "$effort" ] && line+=$(printf " ${MODEL_C}%s${RESET}" "$effort")
line+=$(printf "${SEP}${PATH_C}󰉋 %s${RESET}" "$dir_display")

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

            line+=$(printf "${SEP}${BRANCH_C} %s${RESET}%s%s" \
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

    line+=$(printf "${SEP}${context_color}%d%% free${RESET}" "$remaining")
fi

# Promptcachen: tid kvar tills den gar kall, eftersom nasta prompt da far
# skriva om hela prefixet. expires_at ar epoch-sekunder; raden ritas om var
# 30:e sekund (refreshInterval i settings.json) sa nedrakningen tickar aven
# nar man star still. Syns bara de sista 15 minuterna, i varnfarg, och nar
# den har gatt kall; en nedrakning fran en timme var mest brus.
# Saknas fore forsta API-svaret, och doljs om ingen caching har observerats.
cache=$(echo "$input" | jq -r '.prompt_cache // empty
    | select(.caching_observed)
    | if .warm and .expires_at then (.expires_at | floor | tostring) else "cold" end')

if [ -n "$cache" ] && [ "$cache" != "cold" ]; then
    left=$(( cache - $(date +%s) ))
    if [ $left -le 0 ]; then
        cache="cold"
    elif [ $left -lt 60 ]; then
        line+=$(printf "${SEP}${SOFT}cache${RESET} ${WARN}%ds${RESET}" "$left")
    elif [ $left -le 900 ]; then
        # Avrundat uppat: "1m" ska betyda att det finns minst en minut kvar.
        line+=$(printf "${SEP}${SOFT}cache${RESET} ${WARN}%dm${RESET}" $(( (left + 59) / 60 )))
    fi
fi

[ "$cache" = "cold" ] && line+=$(printf "${SEP}${SOFT}cache${RESET} ${WARN}cold${RESET}")

# Anvandningsgranserna. Bara med ett Claude.ai-abonnemang, och forst efter
# forsta API-svaret; annars saknas rate_limits och hogersidan blir tom.
# limit <etikett> <procent> <resets_at>  ->  "5h 18% 2h13m"
limit() {
    local used reset diff d h m color
    used=$(printf '%.0f' "$2")
    if [ "$used" -lt 50 ]; then color="$COUNT_C"
    elif [ "$used" -lt 80 ]; then color="$WARN"
    else color="$CRIT"; fi
    printf "${SOFT}%s${RESET} ${color}%d%%${RESET}" "$1" "$used"
    [ -n "$3" ] || return 0
    diff=$(( $3 - $(date +%s) ))
    [ $diff -lt 0 ] && diff=0
    d=$(( diff / 86400 )); h=$(( diff % 86400 / 3600 )); m=$(( diff % 3600 / 60 ))
    if [ $d -gt 0 ]; then reset="${d}d${h}h"
    elif [ $h -gt 0 ]; then reset="${h}h$(printf '%02d' $m)m"
    else reset="${m}m"; fi
    printf " ${COUNT_C}%s${RESET}" "$reset"
}

limits=""
# Bara siffror slapps igenom: vardena hamnar i $(( )), som kor det den far.
num() {
    local v
    v=$(echo "$input" | jq -r "$1 // empty | floor" 2>/dev/null)
    [[ $v =~ ^[0-9]+$ ]] && echo "$v"
}
five=$(num '.rate_limits.five_hour.used_percentage')
five_at=$(num '.rate_limits.five_hour.resets_at')
week=$(num '.rate_limits.seven_day.used_percentage')
week_at=$(num '.rate_limits.seven_day.resets_at')
[ -n "$five" ] && limits+=$(limit "5h" "$five" "$five_at")
[ -n "$week" ] && limits+="${limits:+$(printf "$SEP")}$(limit "7d" "$week" "$week_at")"

# Hogerstallt nar det far plats. COLUMNS satter Claude Code; marginalen ar
# radens egen indragning plus lite luft. Langden raknas i tecken (UTF-8), sa
# glyferna raknas som en kolumn var, vilket de ar i en Mono-Nerd Font.
if [ -n "$limits" ]; then
    strip() { printf '%s' "$1" | sed $'s/\033\\[[0-9;]*m//g'; }
    left_plain=$(strip "$line")
    right_plain=$(strip "$limits")
    pad=$(( ${COLUMNS:-0} - 6 - $(LC_ALL=en_US.UTF-8 bash -c 'echo ${#1}' _ "$left_plain") \
        - $(LC_ALL=en_US.UTF-8 bash -c 'echo ${#1}' _ "$right_plain") ))
    if [ $pad -ge 3 ]; then
        line+=$(printf "%*s" $pad "")
    else
        line+=$(printf "$SEP")
    fi
    line+="$limits"
fi

printf "%s" "$line"
