#!/usr/bin/env bash
# find-leader.sh — Leader pane ID를 찾아 출력
# Usage: LEADER_PANE=$(~/.claude/lib/find-leader.sh [LEADER_ID])
# LEADER_ID: 환경변수 CLAUDE_LEADER_ID 또는 인자로 전달, 없으면 윈도우명에서 추출

LID="${1:-${CLAUDE_LEADER_ID:-}}"

# 환경변수/인자 없으면 윈도우명(dualN-M)에서 추출
if [ -z "$LID" ]; then
  LID=$(tmux display-message -p '#{window_name}' | sed -n 's/^dual\([0-9]\{1,\}\)-.*/\1/p')
fi

# 숫자 검증
if [ -n "$LID" ] && ! echo "$LID" | grep -qE '^[0-9]+$'; then
  exit 1
fi

# 매칭되는 leaderN 찾기
if [ -n "$LID" ]; then
  LEADER_PANE=$(tmux list-panes -t "leader${LID}" -F '#{pane_id}' 2>/dev/null | head -1)
fi

# fallback: 아무 leader 윈도우
if [ -z "$LEADER_PANE" ]; then
  LEADER_PANE=$(tmux list-panes -s -F '#{window_name}:#{pane_id}' | grep '^leader' | head -1 | cut -d: -f2)
fi

echo "$LEADER_PANE"
