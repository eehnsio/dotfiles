#!/bin/bash

# ANSI color codes
CYAN='\033[36m'
BLUE='\033[34m'
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
MAGENTA='\033[35m'
WHITE='\033[37m'
GRAY='\033[90m'
RESET='\033[0m'

# Read JSON input from stdin
input=$(cat)

# Extract information from JSON
model_name=$(echo "$input" | jq -r '.model.display_name // "Claude"')
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // ""')
project_dir=$(echo "$input" | jq -r '.workspace.project_dir // ""')
session_id=$(echo "$input" | jq -r '.session_id // ""')

# Get current directory and replace home directory with ~
if [ -n "$current_dir" ]; then
    dir_display="$current_dir"
else
    dir_display="$(pwd)"
fi

# Replace home directory with ~
HOME_DIR="${HOME}"
if [[ "$dir_display" == "$HOME_DIR"* ]]; then
    dir_display="~${dir_display#$HOME_DIR}"
fi

# Truncate directory to last 2 levels
IFS='/' read -ra DIR_PARTS <<< "$dir_display"
num_parts=${#DIR_PARTS[@]}

if [ $num_parts -gt 2 ]; then
    # More than 2 parts, show ellipsis and last 2
    if [[ "$dir_display" == "~"* ]]; then
        # Home directory case: ~/…/second-to-last/last
        dir_display="~/…/${DIR_PARTS[$((num_parts-2))]}/${DIR_PARTS[$((num_parts-1))]}"
    else
        # Absolute path case: …/second-to-last/last
        dir_display="…/${DIR_PARTS[$((num_parts-2))]}/${DIR_PARTS[$((num_parts-1))]}"
    fi
fi

# Simplify model name (e.g., "Claude 3.5 Sonnet" -> "Sonnet 3.5", "Claude Opus 4.5" -> "Opus 4.5")
model_short=$(echo "$model_name" | sed -E 's/^Claude[[:space:]]+//' | sed -E 's/([0-9]+\.[0-9]+)[[:space:]]+([A-Z][a-z]+)/\2 \1/')

########################################
# LINE 1: Model | Path | Git | Tokens | Context
########################################
line1=""
line1+=$(printf "${YELLOW}%s${RESET}" "$model_short")
line1+=$(printf " in ${BLUE}%s${RESET}" "$dir_display")

# Get git branch and status if we're in a git repo
if [ -n "$project_dir" ] && cd "$project_dir" 2>/dev/null; then
    if git rev-parse --git-dir >/dev/null 2>&1; then
        branch=$(git -c gc.auto=0 symbolic-ref --short HEAD 2>/dev/null || git -c gc.auto=0 rev-parse --short HEAD 2>/dev/null)
        if [ -n "$branch" ]; then
            # Get commits ahead/behind remote
            ahead_behind=""
            upstream=$(git -c gc.auto=0 rev-parse --abbrev-ref @{upstream} 2>/dev/null)
            if [ -n "$upstream" ]; then
                counts=$(git -c gc.auto=0 rev-list --count --left-right @{upstream}...HEAD 2>/dev/null)
                if [ -n "$counts" ]; then
                    behind=$(echo "$counts" | awk '{print $1}')
                    ahead=$(echo "$counts" | awk '{print $2}')

                    [ "$ahead" != "0" ] && ahead_behind+=$(printf "${GREEN}↑%s${RESET}" "$ahead")
                    [ "$behind" != "0" ] && ahead_behind+=$(printf "${CYAN}↓%s${RESET}" "$behind")
                fi
            fi

            # Get actual lines added/removed from git diff (unstaged + staged)
            diff_stats=$(git -c gc.auto=0 diff --numstat HEAD 2>/dev/null | awk '{a+=$1; d+=$2} END {print a, d}')
            lines_added=$(echo "$diff_stats" | awk '{print $1}')
            lines_removed=$(echo "$diff_stats" | awk '{print $2}')

            # Build diff string
            git_diff_str=""
            if [ -n "$lines_added" ] && [ "$lines_added" != "0" ]; then
                git_diff_str+=$(printf "${GREEN}+%s${RESET}" "$lines_added")
                [ -n "$lines_removed" ] && [ "$lines_removed" != "0" ] && git_diff_str+=$(printf "/${RED}-%s${RESET}" "$lines_removed")
            elif [ -n "$lines_removed" ] && [ "$lines_removed" != "0" ]; then
                git_diff_str+=$(printf "${RED}-%s${RESET}" "$lines_removed")
            fi

            # Combine branch with ahead/behind and diff
            branch_display="$branch"
            [ -n "$ahead_behind" ] && branch_display="$branch $ahead_behind"

            if [ -n "$git_diff_str" ]; then
                line1+=$(printf " ${MAGENTA}(%s %s)${RESET}" "$branch_display" "$git_diff_str")
            else
                line1+=$(printf " ${MAGENTA}(%s)${RESET}" "$branch_display")
            fi
        fi
    fi
fi

########################################
# LINE 2: Session Time | Cost | Tokens | Context
########################################
line2=""

# Session timer - track session start time using session_id hash
SESSION_DIR="/tmp/claude-sessions"
mkdir -p "$SESSION_DIR" 2>/dev/null

if [ -n "$session_id" ]; then
    SESSION_FILE="$SESSION_DIR/$session_id"

    # Create session file with start time if it doesn't exist
    if [ ! -f "$SESSION_FILE" ]; then
        date +%s > "$SESSION_FILE"
    fi

    # Calculate session duration
    start_time=$(cat "$SESSION_FILE" 2>/dev/null || echo $(date +%s))
    current_time=$(date +%s)
    session_elapsed=$((current_time - start_time))

    # Format session time (HH:MM:SS)
    session_hours=$((session_elapsed / 3600))
    session_mins=$(((session_elapsed % 3600) / 60))
    session_secs=$((session_elapsed % 60))

    if [ $session_hours -gt 0 ]; then
        session_time=$(printf "%dh%02dm%02ds" $session_hours $session_mins $session_secs)
    elif [ $session_mins -gt 0 ]; then
        session_time=$(printf "%dm%02ds" $session_mins $session_secs)
    else
        session_time=$(printf "%ds" $session_secs)
    fi

    line2+=$(printf "${CYAN}%s${RESET}" "$session_time")
fi

# Add cost information from JSON
total_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty' 2>/dev/null)

if [ -n "$total_cost" ]; then
    # Format cost as currency
    cost_formatted=$(printf "%.2f" "$total_cost")
    line2+=$(printf " ${WHITE}|${RESET} ${GREEN}\$%s${RESET}" "$cost_formatted")
fi

# Get token usage information
usage=$(echo "$input" | jq '.context_window.current_usage')

if [ "$usage" != "null" ]; then
    # Current tokens sent (input + cache creation + cache read)
    input_tokens=$(echo "$usage" | jq '.input_tokens // 0')
    cache_creation=$(echo "$usage" | jq '.cache_creation_input_tokens // 0')
    cache_read=$(echo "$usage" | jq '.cache_read_input_tokens // 0')
    output_tokens=$(echo "$usage" | jq '.output_tokens // 0')

    total_sent=$((input_tokens + cache_creation + cache_read))

    # Format tokens sent/received
    if [ $total_sent -ge 1000 ]; then
        tokens_sent=$(awk "BEGIN {printf \"%.1fk\", $total_sent/1000}")
    else
        tokens_sent="$total_sent"
    fi

    if [ $output_tokens -ge 1000 ]; then
        tokens_received=$(awk "BEGIN {printf \"%.1fk\", $output_tokens/1000}")
    else
        tokens_received="$output_tokens"
    fi

    line2+=$(printf " ${WHITE}|${RESET} ${GREEN}%s↑${RESET}/${CYAN}%s↓${RESET}" "$tokens_sent" "$tokens_received")

    # Calculate context percentage
    context_size=$(echo "$input" | jq '.context_window.context_window_size // 0')
    if [ $context_size -gt 0 ]; then
        pct=$((total_sent * 100 / context_size))
        remaining=$((100 - pct))

        # Color code based on remaining context (green > 50%, yellow 20-50%, red < 20%)
        if [ $remaining -gt 50 ]; then
            context_color="$GREEN"
        elif [ $remaining -gt 20 ]; then
            context_color="$YELLOW"
        else
            context_color="$RED"
        fi

        line2+=$(printf " ${WHITE}|${RESET} ${context_color}%d%% free${RESET}" "$remaining")
    fi
fi


########################################
# Print both lines
########################################
printf "%s\n%s" "$line1" "$line2"
