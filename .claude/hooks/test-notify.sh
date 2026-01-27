#!/bin/bash
# Claude Code 알림 진단 스크립트

echo "🔍 Claude Code 알림 진단 시작..."
echo ""

# 1. 현재 터미널 앱 확인
echo "1️⃣ 현재 사용 중인 터미널:"
if [ -n "$TERM_PROGRAM" ]; then
  echo "   → $TERM_PROGRAM"
else
  echo "   → 알 수 없음 (기본 Terminal일 수 있음)"
fi
echo ""

# 2. osascript 사용 가능 여부
echo "2️⃣ osascript 사용 가능:"
if command -v osascript &> /dev/null; then
  echo "   ✅ 설치됨"
else
  echo "   ❌ 없음"
fi
echo ""

# 3. jq 사용 가능 여부
echo "3️⃣ jq 사용 가능:"
if command -v jq &> /dev/null; then
  echo "   ✅ 설치됨 ($(jq --version))"
else
  echo "   ⚠️  없음 (설치 권장: brew install jq)"
fi
echo ""

# 4. 방해금지 모드 확인 (macOS 12+)
echo "4️⃣ 방해금지 모드 상태:"
if command -v shortcuts &> /dev/null; then
  DND_STATUS=$(shortcuts run "Get Focus" 2>/dev/null || echo "확인 불가")
  echo "   → $DND_STATUS"
else
  echo "   → 확인 불가 (shortcuts 명령어 없음)"
fi
echo ""

# 5. 알림 권한 확인 안내
echo "5️⃣ 알림 권한 확인이 필요합니다:"
echo "   macOS 시스템 설정 → 알림 → 터미널 앱 찾기"
echo "   - Warp 사용 시: '설정 → 알림 → Warp' 확인"
echo "   - Terminal 사용 시: '설정 → 알림 → Terminal' 확인"
echo "   - 알림 허용이 켜져 있는지 확인"
echo ""

# 6. 테스트 알림 전송
echo "6️⃣ 테스트 알림 전송 (3초 후)..."
sleep 1
echo "   3..."
sleep 1
echo "   2..."
sleep 1
echo "   1..."

# terminal-notifier 우선 사용 (더 안정적)
if command -v terminal-notifier &> /dev/null; then
  terminal-notifier \
    -title "Claude Code 테스트" \
    -subtitle "Notification Test" \
    -message "이 알림이 보이면 정상 작동입니다!" \
    -sound Glass 2>&1
else
  # terminal-notifier가 없으면 osascript 사용
  osascript -e 'display notification "이 알림이 보이면 정상 작동입니다!" with title "Claude Code 테스트" subtitle "Notification Test"' 2>&1
fi

if [ $? -eq 0 ]; then
  echo ""
  echo "✅ 알림 명령이 성공적으로 실행되었습니다."
  echo ""
  echo "📌 알림이 보였나요?"
  echo "   - 보였다면: ✅ 정상 작동"
  echo "   - 안 보였다면: ⚠️  아래 확인 필요"
  echo ""
  echo "❌ 알림이 표시되지 않는 경우:"
  echo "   1. 시스템 설정 → 알림 → 터미널 앱 → 알림 허용 ON"
  echo "   2. 방해금지 모드 OFF 확인"
  echo "   3. 터미널 앱 재시작"
  echo "   4. macOS 재부팅 (최후의 수단)"
  echo ""
  echo "📝 로그 확인:"
  echo "   log show --predicate 'subsystem == \"claude-notify\"' --last 5m"
else
  echo ""
  echo "❌ 알림 명령 실행 실패"
  echo "   위 오류 메시지를 확인하세요."
fi

echo ""
echo "🔔 실제 hook 테스트:"
echo "   다음 명령으로 실제 hook을 테스트할 수 있습니다:"
echo "   echo '{\"event\":\"notification\",\"cwd\":\"$(pwd)\"}' | bash ~/.claude/hooks/notify.sh"
echo ""
