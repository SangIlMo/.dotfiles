#!/bin/bash
# Claude Code 알림 스크립트
# 입력: JSON (event, cwd)
# 출력: 데스크톱 알림 + 사운드

set -eo pipefail

# 1. JSON 입력 읽기
INPUT=$(cat)

# 2. 이벤트 타입과 작업 디렉토리 파싱 (jq 사용)
if command -v jq &> /dev/null; then
  EVENT=$(echo "$INPUT" | jq -r '.event // "unknown"')
  CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
else
  # jq 없으면 기본값
  EVENT="notification"
  CWD=""
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
  notification)
    TITLE="사용자 입력 필요"
    SUBTITLE="Input Required"
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
# 우선순위: osascript (항상 가능) → terminal-notifier (향상된 아이콘)
if command -v osascript &> /dev/null; then
  # macOS 기본 알림 (가장 안정적)
  MESSAGE="${TITLE} ${CONTEXT}"
  osascript -e "display notification \"${CONTEXT}\" with title \"${TITLE}\" subtitle \"${SUBTITLE}\"" \
    2>/dev/null || true
elif command -v terminal-notifier &> /dev/null; then
  # terminal-notifier fallback
  terminal-notifier \
    -sender com.anthropic.claudefordesktop \
    -title "$TITLE" \
    -subtitle "$SUBTITLE" \
    -message "$CONTEXT" \
    2>/dev/null || true
fi

# 6. 사운드 재생 (백그라운드)
if [ -f "$SOUND" ]; then
  afplay "$SOUND" &
fi

# 7. 항상 성공으로 종료 (hook은 실패하면 안됨)
exit 0
