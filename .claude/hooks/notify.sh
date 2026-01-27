#!/bin/bash
# Claude Code 알림 스크립트
# 입력: JSON (event, cwd)
# 출력: 데스크톱 알림 + 사운드

set -eo pipefail

# 1. JSON 입력 읽기
INPUT=$(cat)

# 2. 이벤트 타입과 작업 디렉토리 파싱 (jq 사용)
if command -v jq &> /dev/null; then
  EVENT=$(echo "$INPUT" | jq -r '.event // .hook_event_name // "unknown"')
  CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
  # Claude Code의 message 필드 추출
  CLAUDE_MESSAGE=$(echo "$INPUT" | jq -r '.message // ""')
  NOTIFICATION_TYPE=$(echo "$INPUT" | jq -r '.notification_type // ""')
else
  # jq 없으면 기본값
  EVENT="notification"
  CWD=""
  CLAUDE_MESSAGE=""
  NOTIFICATION_TYPE=""
fi

# 3. Git 컨텍스트 감지
CONTEXT=""
if [ -n "$CWD" ] && [ -d "$CWD" ]; then
  cd "$CWD"
  if git rev-parse --git-dir > /dev/null 2>&1; then
    REPO=$(basename $(git rev-parse --show-toplevel))
    BRANCH=$(git branch --show-current)
    CONTEXT="[$REPO:$BRANCH]"
  fi
fi

# 4. 이벤트별 메시지 및 사운드 설정
case "$EVENT" in
  Notification|notification)
    TITLE="Claude Code"
    SUBTITLE="${NOTIFICATION_TYPE:-Input Required}"
    SOUND="/System/Library/Sounds/Ping.aiff"
    ;;
  stop)
    TITLE="작업 완료"
    SUBTITLE="Task Completed"
    SOUND="/System/Library/Sounds/Glass.aiff"
    ;;
  *)
    TITLE="Claude Code"
    SUBTITLE="Notification"
    SOUND="/System/Library/Sounds/Ping.aiff"
    ;;
esac

# 5. 알림 전송
# 우선순위: terminal-notifier (더 안정적인 배너) → osascript (fallback)
# 메시지 준비
if [ -n "$CLAUDE_MESSAGE" ]; then
  MESSAGE="$CLAUDE_MESSAGE"
elif [ -n "$CONTEXT" ]; then
  MESSAGE="$CONTEXT"
else
  MESSAGE="Claude Code is waiting for you"
fi

if command -v terminal-notifier &> /dev/null; then
  # terminal-notifier 사용 (배너가 더 잘 표시됨)
  terminal-notifier \
    -sender com.anthropic.claudefordesktop \
    -title "$TITLE" \
    -subtitle "$SUBTITLE" \
    -message "$MESSAGE" \
    -sound "${SOUND##*/}" \
    2>&1 | logger -t claude-notify || true
elif command -v osascript &> /dev/null; then
  # osascript fallback (terminal-notifier가 없는 경우)
  osascript -e "display notification \"${MESSAGE}\" with title \"${TITLE}\" subtitle \"${SUBTITLE}\" sound name \"${SOUND##*/}\"" 2>&1 | logger -t claude-notify || {
    # osascript 실패 시 더 간단한 형식으로 재시도
    osascript -e "display notification \"${MESSAGE}\" with title \"${TITLE}\"" 2>&1 | logger -t claude-notify || true
  }
fi

# 6. 사운드 재생 (백그라운드)
# terminal-notifier는 -sound 옵션으로 사운드를 재생하므로 별도 재생 불필요
# osascript fallback인 경우에만 사운드 재생
if ! command -v terminal-notifier &> /dev/null && [ -f "$SOUND" ]; then
  # terminal-notifier가 없고 osascript를 사용한 경우에만 백업 사운드 재생
  (sleep 0.1 && afplay "$SOUND" 2>/dev/null) &
fi

# 7. 항상 성공으로 종료 (hook은 실패하면 안됨)
exit 0
