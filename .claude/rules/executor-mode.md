# Executor Mode

## 활성화 조건
이 규칙은 `ANTHROPIC_AUTH_TOKEN`이 설정된 세션(z.ai API)에서만 적용합니다.
해당되지 않으면 이 규칙을 무시하세요.

## 규칙
- `~/.claude/specs/{project}/pending/`에서 스펙을 읽음
- 실행 시작 시 `doing/`으로 이동
- 스펙에 따라 구현
- 완료 후 `done/`으로 이동 + 결과 요약 추가
- project = 현재 디렉토리의 basename

## 워크플로우
1. 세션 파일 읽기: `$ORCHESTRATE_SESSION_FILE`에서 Leader pane ID 확인
2. `pending/` 스펙 목록 확인
3. 스펙 선택 → `doing/`으로 이동
4. 스펙의 Scope와 Requirements에 따라 구현
5. Acceptance Criteria 검증
6. `done/`으로 이동, 파일 하단에 결과 요약 추가
7. **Tester pane을 on-demand 생성하고 세션 파일 업데이트, 테스트 요청 전송**

## 결과 요약 포맷
```
## Execution Result
- completed: {timestamp}
- status: success|partial|failed
- Changes: [list of files changed]
- Notes: (실행 중 발견된 사항)
```

## Tester pane 생성 및 테스트 요청 방법
구현 완료 후 반드시 실행:
```bash
# 세션 파일에서 Leader의 window ID 읽기
LEADER_WINDOW=$(jq -r '.leader.window_id' "$ORCHESTRATE_SESSION_FILE")

# Tester pane이 없으면 Leader 탭 내에서 아래로 분할 생성
TESTER_PANE=$(jq -r '.tester.pane_id' "$ORCHESTRATE_SESSION_FILE")
if [ "$TESTER_PANE" = "null" ] || [ -z "$TESTER_PANE" ]; then
  TESTER_PANE=$(tmux split-window -v -t "$LEADER_WINDOW" -c "$PWD" -P -F '#{pane_id}' \
    "ORCHESTRATE_SESSION_ID='$ORCHESTRATE_SESSION_ID' ORCHESTRATE_SESSION_FILE='$ORCHESTRATE_SESSION_FILE' CLAUDE_ROLE=tester mise run z.ai:claude -- --dangerously-skip-permissions")

  # 세션 파일 업데이트 (Tester pane ID 저장)
  jq ".tester.pane_id = \"$TESTER_PANE\" | .tester.status = \"ready\"" \
    "$ORCHESTRATE_SESSION_FILE" > "${ORCHESTRATE_SESSION_FILE}.tmp" && \
    mv "${ORCHESTRATE_SESSION_FILE}.tmp" "$ORCHESTRATE_SESSION_FILE"

  sleep 2  # Tester 초기화 대기
fi

# 테스트 요청 전송 (올바른 tmux send-keys 형식)
if [ -n "$TESTER_PANE" ] && [ "$TESTER_PANE" != "null" ]; then
  tmux send-keys -t "$TESTER_PANE" "테스트 요청: {SPEC-ID}. 구현 완료된 스펙을 테스트해주세요." Enter
fi
```

**메모:**
- Tester pane이 이미 존재하면 재사용합니다 (세션 파일에서 확인)
- `-l` 플래그 제거 (줄바꿈 문제 해결)
- `tmux send-keys -t PANE "메시지" Enter` 형식 (한 번에 전송)

## Tester로부터 메시지 수신 및 Leader에게 완료 알림
Tester가 테스트 결과를 보낸 후 Executor가 수행할 작업:

```bash
# Tester로부터 메시지 수신 (tmux send-keys로 입력됨)
# - 테스트 실패: Executor가 수정 후 다시 테스트 요청
# - 테스트 성공: 아래 실행

# 테스트 성공 시 Leader에게 최종 완료 알림
LEADER_PANE=$(jq -r '.leader.pane_id' "$ORCHESTRATE_SESSION_FILE")

if [ -n "$LEADER_PANE" ] && [ "$LEADER_PANE" != "null" ]; then
  tmux send-keys -t "$LEADER_PANE" "EARS 스펙 완료 (테스트 통과): {SPEC-ID}. /specs-status 로 확인 후 /review-quick 으로 검증하세요." Enter
fi
```

**흐름:**
1. Executor → Tester에게 테스트 요청
2. Tester → Executor에게 결과 전송
3. **성공:** Executor → Leader에게 최종 완료 알림
4. **실패:** Executor가 수정 후 2번 반복

## Tester로부터 수정 요청 수신 시
- Tester가 테스트 실패 내용과 함께 수정 요청을 보냅니다
- 에러 내용을 분석하고 코드를 수정합니다
- 수정 완료 후 다시 Tester에게 테스트 요청을 보냅니다 (기존 pane 재사용)
