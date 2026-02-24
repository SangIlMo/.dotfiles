#!/bin/bash
# claude-status.sh - Display active Claude sessions + daily usage % in tmux status bar

set -o pipefail

# Dracula theme colors
CYAN="#[fg=#8be9fd]"
GREEN="#[fg=#50fa7b]"
YELLOW="#[fg=#f1fa8c]"
RED="#[fg=#ff5555]"
GRAY="#[fg=#6272a4]"
RESET="#[fg=default]"

# Cache
CACHE_DIR="${HOME}/.cache/tmux"
CACHE_FILE="${CACHE_DIR}/claude-status-cache"
CACHE_AGE=5

mkdir -p "$CACHE_DIR"

is_cache_valid() {
    [ -f "$CACHE_FILE" ] || return 1
    now=$(date +%s)
    mtime=$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
    [ $((now - mtime)) -lt $CACHE_AGE ]
}

check_pane_activity() {
    content=$(tmux capture-pane -p -t "$1" -S -3 2>/dev/null)
    [ -z "$content" ] && echo "idle" && return
    if echo "$content" | grep -qE '(⠋|⠙|⠹|⠸|⠼|⠴|⠦|⠧|⠇|⠏|✻|⏺|Thinking|Reading|Editing|Writing|Searching|Running)'; then
        echo "working"
    else
        echo "idle"
    fi
}

# Calculate today's usage % against Max plan ($100/month, ~$3.33/day)
# Token pricing (per 1M, avg of input/output):
#   opus: ~$45, sonnet: ~$10, haiku: ~$3.5, glm: ~$5
calc_daily_usage_pct() {
    stats_file="$HOME/.claude/stats-cache.json"
    [ -f "$stats_file" ] || return

    today=$(date +%Y-%m-%d)
    token_data=$(jq -r --arg d "$today" '.dailyModelTokens[] | select(.date == $d) | .tokensByModel' "$stats_file" 2>/dev/null)

    # If no data for today, try yesterday (cache may lag)
    if [ -z "$token_data" ] || [ "$token_data" = "null" ]; then
        yesterday=$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d "yesterday" +%Y-%m-%d 2>/dev/null)
        token_data=$(jq -r --arg d "$yesterday" '.dailyModelTokens[] | select(.date == $d) | .tokensByModel' "$stats_file" 2>/dev/null)
        [ -z "$token_data" ] || [ "$token_data" = "null" ] && return
    fi

    # Calculate cost in cents (integer math, multiply by 100 first)
    # cost_cents = tokens * price_per_M * 100 / 1000000 = tokens * price_cents_per_M / 1000000
    opus=$(echo "$token_data" | jq -r '[ to_entries[] | select(.key | test("opus")) | .value ] | add // 0')
    sonnet=$(echo "$token_data" | jq -r '[ to_entries[] | select(.key | test("sonnet")) | .value ] | add // 0')
    haiku=$(echo "$token_data" | jq -r '[ to_entries[] | select(.key | test("haiku")) | .value ] | add // 0')
    other=$(echo "$token_data" | jq -r '[ to_entries[] | select(.key | test("opus|sonnet|haiku") | not) | .value ] | add // 0')

    # Cost in millicents for precision: price * 1000 per M tokens
    # opus=$45/M=45000mc, sonnet=$10/M=10000mc, haiku=$3.5/M=3500mc, other=$5/M=5000mc
    cost_mc=$(( opus * 45000 / 1000000 + sonnet * 10000 / 1000000 + haiku * 3500 / 1000000 + other * 5000 / 1000000 ))

    # Daily budget: $3.33 = 333000 millicents
    daily_budget_mc=333000
    pct=$((cost_mc * 100 / daily_budget_mc))

    echo "$pct"
}

generate_cache() {
    total=0
    working=0

    while IFS= read -r line; do
        [ -z "$line" ] && continue
        pane_id=$(echo "$line" | awk '{print $1}')
        cmd=$(echo "$line" | awk '{$1=""; print $0}' | xargs)

        if echo "$cmd" | grep -qE '([0-9]+\.[0-9]+\.[0-9]+|claude|mise)'; then
            pid=$(tmux list-panes -a -F "#{pane_id} #{pane_pid}" 2>/dev/null | grep "^${pane_id} " | awk '{print $2}')
            [ -z "$pid" ] && continue

            if ps -o command= -p "$pid" 2>/dev/null | grep -q claude || \
               pgrep -P "$pid" 2>/dev/null | xargs ps -o command= 2>/dev/null | grep -q claude; then
                total=$((total + 1))
                state=$(check_pane_activity "$pane_id")
                [ "$state" = "working" ] && working=$((working + 1))
            fi
        fi
    done < <(tmux list-panes -a -F '#{pane_id} #{pane_current_command}' 2>/dev/null)

    if [ "$total" -eq 0 ]; then
        echo ""
        return
    fi

    idle=$((total - working))
    parts=""
    [ "$working" -gt 0 ] && parts="⚙${working}"
    [ "$idle" -gt 0 ] && { [ -n "$parts" ] && parts="${parts}·◇${idle}" || parts="◇${idle}"; }

    # Session info
    session_str="⚡${total} ${parts}"

    # Usage %
    pct=$(calc_daily_usage_pct)
    if [ -n "$pct" ] && [ "$pct" -gt 0 ] 2>/dev/null; then
        # Color by threshold
        if [ "$pct" -ge 80 ]; then
            pct_color="$RED"
        elif [ "$pct" -ge 50 ]; then
            pct_color="$YELLOW"
        else
            pct_color="$GREEN"
        fi
        session_str="${session_str} ${pct_color}${pct}%${CYAN}"
    fi

    echo "$session_str"
}

if ! is_cache_valid; then
    generate_cache > "$CACHE_FILE"
fi

status=""
[ -f "$CACHE_FILE" ] && status=$(cat "$CACHE_FILE")

if [ -n "$status" ]; then
    echo "${CYAN}${status}${RESET}"
fi
