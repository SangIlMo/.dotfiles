#!/usr/bin/env bash
# Shared cache validation for tmux status scripts
tmux_cache_valid() {
  local f="$1" age="${2:-5}"
  [[ -f "$f" ]] || return 1
  local mod
  mod=$(stat -f %m "$f" 2>/dev/null) || return 1
  local now
  now=$(date +%s)
  (( now - mod < age ))
}
