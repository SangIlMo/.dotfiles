#!/usr/bin/env bash
# Worktree info for tmux status bar
# Shows worktree count when in a repo with active worktrees

PANE_PATH="${1:-$PWD}"
[ -d "$PANE_PATH" ] || exit 0
CACHE_DIR="$HOME/.cache/tmux"
CACHE_FILE="$CACHE_DIR/worktree-info-cache"
CACHE_AGE=5

mkdir -p "$CACHE_DIR"

is_cache_valid() {
  [[ -f "$CACHE_FILE" ]] || return 1
  local mod
  mod=$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
  local now
  now=$(date +%s)
  (( now - mod < CACHE_AGE ))
}

# Cache key = pane path; invalidate if path changed
if [[ -f "$CACHE_FILE" ]]; then
  cached_path=$(head -1 "$CACHE_FILE")
  if [[ "$cached_path" == "$PANE_PATH" ]] && is_cache_valid; then
    tail -1 "$CACHE_FILE"
    exit 0
  fi
fi

# Check if inside a git repo (exclude bare repos like yadm)
inside=$(git -C "$PANE_PATH" rev-parse --is-inside-work-tree 2>/dev/null)
if [[ "$inside" != "true" ]]; then
  printf '%s\n' "$PANE_PATH" "" > "$CACHE_FILE"
  exit 0
fi

# Get worktree list
wt_list=$(git -C "$PANE_PATH" worktree list 2>/dev/null)
wt_count=$(echo "$wt_list" | wc -l | tr -d ' ')

# Hide if only main worktree
if (( wt_count < 2 )); then
  printf '%s\n' "$PANE_PATH" "" > "$CACHE_FILE"
  exit 0
fi

# Check if current pane is inside a worktree (not the main repo)
main_wt=$(echo "$wt_list" | head -1 | awk '{print $1}')
toplevel=$(git -C "$PANE_PATH" rev-parse --show-toplevel 2>/dev/null)
real_toplevel=$(cd "$toplevel" && pwd -P 2>/dev/null || echo "$toplevel")
real_main=$(cd "$main_wt" && pwd -P 2>/dev/null || echo "$main_wt")

if [[ "$real_toplevel" != "$real_main" ]]; then
  # Inside a worktree - green
  result="#[fg=#50fa7b]🌲${wt_count} "
else
  # Main repo with worktrees - grey
  result="#[fg=#6272a4]🌲${wt_count} "
fi

printf '%s\n%s' "$PANE_PATH" "$result" > "$CACHE_FILE"
echo -n "$result"
