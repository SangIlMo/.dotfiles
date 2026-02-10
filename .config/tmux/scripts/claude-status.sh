#!/bin/bash
# claude-status.sh - Display Claude Code and Agent Teams status for tmux status bar
# Output: Claude:active Team:review 3/5  or  Claude:idle

# Check if Claude Code is running
if pgrep -f "claude" &>/dev/null; then
    claude_status="#[fg=#50fa7b]Claude:active"  # Dracula green
else
    claude_status="#[fg=#6272a4]Claude:idle"     # Dracula gray
fi

# Check Agent Teams status
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
                team_str=" #[fg=#bd93f9]Team:${team_name} ${completed_tasks}/${total_tasks}"  # Dracula purple
            fi
        fi

        # Only show the first active team
        break
    done
fi

echo "${claude_status}${team_str}"
