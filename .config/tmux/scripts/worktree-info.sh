#!/usr/bin/env bash
# Worktree info for tmux status bar
# Shows worktree count when in a repo with active worktrees

PANE_PATH="${1:-$PWD}"
[ -d "$PANE_PATH" ] || exit 0
CACHE_DIR="$HOME/.cache/tmux"
CACHE_FILE="$CACHE_DIR/worktree-info-cache"
CACHE_AGE=5

mkdir -p "$CACHE_DIR"

# Source shared cache utility (#7)
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/cache.sh
source "$_SCRIPT_DIR/lib/cache.sh"

# Cache key = pane path; invalidate if path changed
if [[ -f "$CACHE_FILE" ]]; then
  # #10: read both lines in one pass
  { read -r cached_path; read -r cached_result; } < "$CACHE_FILE"
  if [[ "$cached_path" == "$PANE_PATH" ]] && tmux_cache_valid "$CACHE_FILE" "$CACHE_AGE"; then
    printf '%s' "$cached_result"
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

# #8: count lines without wc/tr subshell
wt_count=0
while IFS= read -r _; do (( wt_count++ )); done <<< "$wt_list"

# Hide if only main worktree
if (( wt_count < 2 )); then
  printf '%s\n' "$PANE_PATH" "" > "$CACHE_FILE"
  exit 0
fi

# #9: parse main worktree path without awk subshell
read -r main_wt _ <<< "$(head -1 <<< "$wt_list")"
toplevel=$(git -C "$PANE_PATH" rev-parse --show-toplevel 2>/dev/null)
# #9: use realpath instead of cd && pwd -P
real_toplevel=$(realpath "$toplevel" 2>/dev/null || echo "$toplevel")
real_main=$(realpath "$main_wt" 2>/dev/null || echo "$main_wt")

if [[ "$real_toplevel" != "$real_main" ]]; then
  # Inside a worktree - green
  result="#[fg=#50fa7b]🌲${wt_count} "
else
  # Main repo with worktrees - grey
  result="#[fg=#6272a4]🌲${wt_count} "
fi

printf '%s\n%s' "$PANE_PATH" "$result" > "$CACHE_FILE"
echo -n "$result"
