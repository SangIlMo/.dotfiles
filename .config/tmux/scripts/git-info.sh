#!/bin/bash
# git-info.sh - Display git branch and dirty status for tmux status bar
# Output:  main (clean) or  main± (dirty)
# Uses Nerd Font icons

dir="${1:-$(pwd)}"
[ -d "$dir" ] || exit 0

# #17: use git -C consistently, remove cd "$dir"
# Check if inside a git repo
git -C "$dir" rev-parse --is-inside-work-tree &>/dev/null || exit 0

# Get branch name
branch=$(git -C "$dir" symbolic-ref --short HEAD 2>/dev/null || git -C "$dir" rev-parse --short HEAD 2>/dev/null)
[ -z "$branch" ] && exit 0

# #18: use grep -qm1 to stop at first match (no head needed)
if git -C "$dir" status --porcelain 2>/dev/null | grep -qm1 .; then
    echo "#[fg=#f9e2af] ${branch}±"  # yellow for dirty
else
    echo "#[fg=#a6e3a1] ${branch}"   # green for clean
fi
