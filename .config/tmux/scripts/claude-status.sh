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

# #11: Source shared cache utility
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/cache.sh
source "$_SCRIPT_DIR/lib/cache.sh"

check_pane_activity() {
    content=$(tmux capture-pane -p -t "$1" -S -3 2>/dev/null)
    [ -z "$content" ] && echo "idle" && return
    # #16: use bash regex instead of echo | grep
    if [[ "$content" =~ (⠋|⠙|⠹|⠸|⠼|⠴|⠦|⠧|⠇|⠏|✻|⏺|Thinking|Reading|Editing|Writing|Searching|Running) ]]; then
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

    # #13: merge today/yesterday jq calls into one with fallback logic
    yesterday=$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d "yesterday" +%Y-%m-%d 2>/dev/null)
    token_data=$(jq -r --arg today "$today" --arg yesterday "$yesterday" '
      (.dailyModelTokens[] | select(.date == $today) | .tokensByModel) //
      (.dailyModelTokens[] | select(.date == $yesterday) | .tokensByModel) //
      empty
    ' "$stats_file" 2>/dev/null | head -1)

    [ -z "$token_data" ] || [ "$token_data" = "null" ] && return

    # #12: merge 4 jq calls into one
    read -r opus sonnet haiku other < <(echo "$token_data" | jq -r '
      [ to_entries[] | select(.key | test("opus"))                          | .value ] | add // 0,
      [ to_entries[] | select(.key | test("sonnet"))                        | .value ] | add // 0,
      [ to_entries[] | select(.key | test("haiku"))                         | .value ] | add // 0,
      [ to_entries[] | select(.key | test("opus|sonnet|haiku") | not)       | .value ] | add // 0
      | @tsv' 2>/dev/null | tr '\t' ' ')

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

    # #15: include pane_pid in format string, read all three fields in loop
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        # #14: use read instead of awk for field splitting
        read -r pane_id pane_pid cmd <<< "$line"

        if [[ "$cmd" =~ ([0-9]+\.[0-9]+\.[0-9]+|claude|mise) ]]; then
            [ -z "$pane_pid" ] && continue

            if ps -o command= -p "$pane_pid" 2>/dev/null | grep -q claude || \
               pgrep -P "$pane_pid" 2>/dev/null | xargs ps -o command= 2>/dev/null | grep -q claude; then
                total=$((total + 1))
                state=$(check_pane_activity "$pane_id")
                [ "$state" = "working" ] && working=$((working + 1))
            fi
        fi
    done < <(tmux list-panes -a -F '#{pane_id} #{pane_pid} #{pane_current_command}' 2>/dev/null)

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

# #11: use tmux_cache_valid from lib/cache.sh
if ! tmux_cache_valid "$CACHE_FILE" "$CACHE_AGE"; then
    generate_cache > "$CACHE_FILE"
fi

status=""
[ -f "$CACHE_FILE" ] && status=$(cat "$CACHE_FILE")

if [ -n "$status" ]; then
    echo "${CYAN}${status}${RESET}"
fi
