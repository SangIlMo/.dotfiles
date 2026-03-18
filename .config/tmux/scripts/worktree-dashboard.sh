#!/usr/bin/env bash
# Worktree dashboard for tmux popup

# Get pane path: argument, or query tmux for the calling pane's path
if [[ -n "$1" && "$1" != *"#{"* ]]; then
  PANE_PATH="$1"
else
  # Inside popup, $PWD is home; get the originating pane's path via TMUX_PANE
  PANE_PATH=$(tmux display-message -p -t "${TMUX_PANE:-}" '#{pane_current_path}' 2>/dev/null || echo "$PWD")
fi

if ! git -C "$PANE_PATH" rev-parse --is-inside-work-tree &>/dev/null; then
  echo "Not a git repository"
  exit 0
fi

repo_root=$(git -C "$PANE_PATH" rev-parse --show-toplevel 2>/dev/null)
repo_name=$(basename "$repo_root")

# Parse worktree list
wt_data=$(git -C "$PANE_PATH" worktree list --porcelain 2>/dev/null)
wt_count=$(git -C "$PANE_PATH" worktree list 2>/dev/null | wc -l | tr -d ' ')

# Resolve current pane's real path for highlighting
real_pane=$(cd "$PANE_PATH" && pwd -P 2>/dev/null || echo "$PANE_PATH")

echo ""
echo -e " \033[1m Worktrees — ${repo_name} (${wt_count})\033[0m"
echo " ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

main_wt=""
current_path=""
current_branch=""
entries=()

while IFS= read -r line; do
  if [[ "$line" =~ ^worktree\ (.+) ]]; then
    current_path="${BASH_REMATCH[1]}"
    current_branch=""
  elif [[ "$line" =~ ^branch\ refs/heads/(.+) ]]; then
    current_branch="${BASH_REMATCH[1]}"
  elif [[ "$line" == "" && -n "$current_path" ]]; then
    # Determine source tag
    tag=""
    if [[ "$current_path" == *"/.claude/worktrees/"* ]]; then
      tag="claude"
    elif [[ "$current_path" == *"/.dmux/worktrees/"* || "$current_path" == *"/dmux-"* ]]; then
      tag="dmux"
    fi

    # First entry is main worktree
    if [[ -z "$main_wt" ]]; then
      main_wt="$current_path"
    fi

    entries+=("${current_path}|${current_branch}|${tag}")
    current_path=""
    current_branch=""
  fi
done <<< "$wt_data"

# Handle last entry (no trailing blank line)
if [[ -n "$current_path" ]]; then
  tag=""
  if [[ "$current_path" == *"/.claude/worktrees/"* ]]; then
    tag="claude"
  elif [[ "$current_path" == *"/.dmux/worktrees/"* || "$current_path" == *"/dmux-"* ]]; then
    tag="dmux"
  fi
  [[ -z "$main_wt" ]] && main_wt="$current_path"
  entries+=("${current_path}|${current_branch}|${tag}")
fi

for entry in "${entries[@]}"; do
  IFS='|' read -r wt_path branch tag <<< "$entry"
  real_wt=$(cd "$wt_path" 2>/dev/null && pwd -P || echo "$wt_path")

  # Highlight current
  if [[ "$real_pane" == "$real_wt" || "$real_pane" == "$real_wt/"* ]]; then
    marker=" \033[1;32m●\033[0m"
  elif [[ "$wt_path" == "$main_wt" ]]; then
    marker=" \033[37m●\033[0m"
  else
    marker=" \033[36m◆\033[0m"
  fi

  # Truncate branch
  display_branch="$branch"
  if (( ${#display_branch} > 22 )); then
    display_branch="${display_branch:0:20}.."
  fi

  # Tag display
  tag_str=""
  if [[ -n "$tag" ]]; then
    tag_str=" \033[33m[$tag]\033[0m"
  fi

  # Path display - relative to main or abbreviated
  if [[ "$wt_path" == "$main_wt" ]]; then
    display_path="$wt_path"
  else
    # Show relative to main repo parent
    display_path="${wt_path/#$HOME/~}"
    # Further abbreviate long paths
    if (( ${#display_path} > 35 )); then
      display_path="..${display_path: -33}"
    fi
  fi

  printf "${marker} %-24s${tag_str}  \033[2m%s\033[0m\n" "$display_branch" "$display_path"
done

echo ""
read -rsn1 -p " Press any key to close..."
