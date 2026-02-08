#!/bin/bash
# git-info.sh - Display git branch and dirty status for tmux status bar
# Output:  main (clean) or  main± (dirty)
# Uses Nerd Font icons

dir="${1:-$(pwd)}"
cd "$dir" 2>/dev/null || exit 0

# Check if inside a git repo
git rev-parse --is-inside-work-tree &>/dev/null || exit 0

# Get branch name
branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
[ -z "$branch" ] && exit 0

# Check dirty status
if [ -n "$(git status --porcelain 2>/dev/null | head -1)" ]; then
    echo "#[fg=#f9e2af] ${branch}±"  # yellow for dirty
else
    echo "#[fg=#a6e3a1] ${branch}"   # green for clean
fi
