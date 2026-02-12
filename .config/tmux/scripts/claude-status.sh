#!/bin/bash
# claude-status.sh - Display Claude Code sessions and Agent Teams status for tmux status bar
# Features:
#   - Detects all tmux panes running Claude via mise process
#   - Extracts model name and context usage from Claude status line
#   - Shows working/idle state by detecting activity indicators
#   - Displays compact summary: C:5 H1·O4 avg:68%  or  C:5 ▰▰▱ 65%
#   - Keeps Agent Teams task progress
# Output example: C:5 H1·O4 avg:68% | Team:my-team 2/5

set -o pipefail

# Dracula theme colors
DRACULA_GREEN="#[fg=#50fa7b]"
DRACULA_CYAN="#[fg=#8be9fd]"
DRACULA_PURPLE="#[fg=#bd93f9]"
DRACULA_YELLOW="#[fg=#f1fa8c]"
DRACULA_RED="#[fg=#ff5555]"
DRACULA_GRAY="#[fg=#6272a4]"
DRACULA_RESET="#[fg=default]"

# Cache file for context data (refresh every 5 seconds)
CACHE_DIR="${HOME}/.cache/tmux"
CACHE_FILE="${CACHE_DIR}/claude-status-cache"
CACHE_AGE=5  # seconds

mkdir -p "$CACHE_DIR"

# Function to detect if cache is still valid
is_cache_valid() {
    [ -f "$CACHE_FILE" ] || return 1
    local now=$(date +%s)
    local mtime=$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
    [ $((now - mtime)) -lt $CACHE_AGE ]
}

# Function to extract Claude status line from pane content
extract_claude_status() {
    local pane_id="$1"
    local content

    # Capture last 5 lines of pane (enough for status line + some context)
    content=$(tmux capture-pane -p -t "$pane_id" -S -5)

    # Look for Claude status line pattern:
    # "Model in /path | Context: XX% | Style: default"
    # or simpler: "Context: XX%"
    if echo "$content" | grep -q "Context:"; then
        echo "$content"
        return 0
    fi
    return 1
}

# Function to parse model name from status line
get_model() {
    local content="$1"

    # Try to extract model from "Model in /path" pattern
    if echo "$content" | grep -q "Model in"; then
        echo "$content" | grep "Model in" | sed -E 's/.*Model in ([^ |]+).*/\1/' | xargs basename
        return 0
    fi

    # Fallback: check for model names in common patterns
    if echo "$content" | grep -qi "haiku"; then
        echo "H"
        return 0
    elif echo "$content" | grep -qi "opus"; then
        echo "O"
        return 0
    elif echo "$content" | grep -qi "sonnet"; then
        echo "S"
        return 0
    fi

    return 1
}

# Function to parse context percentage from status line
get_context_pct() {
    local content="$1"

    # Extract XX from "Context: XX%"
    echo "$content" | grep -oE "Context: [0-9]+" | grep -oE "[0-9]+" || echo "0"
}

# Function to detect if Claude pane is working (vs idle)
is_working() {
    local content="$1"

    # Working indicators: spinner chars, activity verbs
    if echo "$content" | grep -qE "(✻|✽|⏺|Bloviating|Crunching|Sautéed|Thinking|Processing|Generating)"; then
        return 0
    fi

    # Idle indicator: prompt line "❯" without active work
    if echo "$content" | grep -q "❯"; then
        return 1
    fi

    # Default: if contains status line, assume idle (prompt not visible in last 5 lines)
    return 1
}

# Main detection and caching logic
if ! is_cache_valid; then
    # Regenerate cache
    {
        # Get all panes and find those running Claude
        local total_panes=0
        local working_count=0
        declare -A model_count
        local context_values=()
        local context_sum=0
        local context_count=0

        # Find all panes with mise process (Claude runs via mise)
        while IFS= read -r pane_line; do
            [ -z "$pane_line" ] && continue

            local pane_id=$(echo "$pane_line" | awk '{print $1}')
            local command=$(echo "$pane_line" | awk '{$1=""; print $0}' | xargs)

            # Check if this pane is running mise or claude
            if echo "$command" | grep -qE "(mise|claude|z\.ai)"; then
                content=$(extract_claude_status "$pane_id")

                if [ -n "$content" ]; then
                    total_panes=$((total_panes + 1))

                    # Extract model and context
                    model=$(get_model "$content")
                    model=${model:-"U"}
                    ((model_count[$model]++))

                    context=$(get_context_pct "$content")
                    context_values+=("$context")
                    context_sum=$((context_sum + context))
                    context_count=$((context_count + 1))

                    # Check if working
                    if is_working "$content"; then
                        working_count=$((working_count + 1))
                    fi
                fi
            fi
        done < <(tmux list-panes -a -F '#{pane_id} #{pane_current_command}')

        # Generate output
        if [ "$total_panes" -eq 0 ]; then
            echo "C:0"
        else
            # Calculate average context
            local avg_context=0
            if [ "$context_count" -gt 0 ]; then
                avg_context=$((context_sum / context_count))
            fi

            # Build compact display
            local status_str="C:$total_panes"

            # Try detailed model breakdown if space allows
            local has_models=false
            local model_str=""
            for model in H S O U; do
                count=${model_count[$model]:-0}
                if [ "$count" -gt 0 ]; then
                    has_models=true
                    [ -z "$model_str" ] && model_str="$model$count" || model_str="$model_str·$model$count"
                fi
            done

            # If we have model breakdown and it's short, use it; otherwise use visual bar
            if [ "$has_models" = true ] && [ ${#model_str} -le 15 ]; then
                status_str="$status_str $model_str avg:${avg_context}%"
            else
                # Fallback to simple visual bar (4 blocks, 25% each)
                local bar=""
                local filled=$((avg_context / 25))
                [ "$filled" -gt 4 ] && filled=4
                for ((i=0; i<filled; i++)); do bar="${bar}▰"; done
                for ((i=filled; i<4; i++)); do bar="${bar}▱"; done
                status_str="$status_str ${bar} ${avg_context}%"
            fi

            # Add working indicator if needed
            if [ "$working_count" -gt 0 ]; then
                status_str="${status_str} ✻${working_count}"
            fi

            echo "$status_str"
        fi
    } > "$CACHE_FILE"
fi

# Read from cache
claude_status=""
if [ -f "$CACHE_FILE" ]; then
    claude_status=$(cat "$CACHE_FILE")
    if [ -n "$claude_status" ]; then
        claude_status="${DRACULA_CYAN}${claude_status}${DRACULA_RESET}"
    fi
fi

# Check Agent Teams status (lightweight, not cached)
team_str=""
teams_dir="$HOME/.claude/teams"

if [ -d "$teams_dir" ]; then
    # Find the most recent team config
    for team_dir in "$teams_dir"/*/; do
        [ -d "$team_dir" ] || continue
        config_file="${team_dir}config.json"
        [ -f "$config_file" ] || continue

        # Extract team name from directory
        team_name=$(basename "$team_dir")

        # Count members
        member_count=$(jq -r '.members | length' "$config_file" 2>/dev/null || echo 0)

        # Count tasks
        tasks_dir="$HOME/.claude/tasks/${team_name}"
        if [ -d "$tasks_dir" ]; then
            total_tasks=0
            completed_tasks=0
            for task_file in "$tasks_dir"/*.json; do
                [ -f "$task_file" ] || continue
                total_tasks=$((total_tasks + 1))
                status=$(jq -r '.status // empty' "$task_file" 2>/dev/null)
                [ "$status" = "completed" ] && completed_tasks=$((completed_tasks + 1))
            done

            if [ "$total_tasks" -gt 0 ]; then
                team_str=" ${DRACULA_PURPLE}Team:${team_name} ${completed_tasks}/${total_tasks}${DRACULA_RESET}"
            fi
        fi

        # Only show the first active team
        break
    done
fi

# Output combined status
if [ -n "$claude_status" ]; then
    echo -n "$claude_status"
fi
if [ -n "$team_str" ]; then
    echo -n "$team_str"
fi
[ -n "$claude_status" ] || [ -n "$team_str" ] && echo ""
