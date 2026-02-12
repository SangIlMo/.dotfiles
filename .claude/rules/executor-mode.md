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
# Tester pane이 없으면 생성
TESTER_PANE=$(tmux list-panes -F '#{pane_index}:#{pane_id}' | grep '^1:' | cut -d: -f2)
if [ -z "$TESTER_PANE" ]; then
  LID="${CLAUDE_LEADER_ID:-1}"
  tmux split-window -h -c "$PWD" "CLAUDE_LEADER_ID=${LID} CLAUDE_ROLE=tester ~/.config/mise/tasks/zai/claude --dangerously-skip-permissions"
  sleep 3
  TESTER_PANE=$(tmux list-panes -F '#{pane_index}:#{pane_id}' | grep '^1:' | cut -d: -f2)
fi

# 테스트 요청 전송
if [ -n "$TESTER_PANE" ]; then
  tmux send-keys -t "$TESTER_PANE" -l "테스트 요청: {SPEC-ID}. 구현 완료된 스펙을 테스트해주세요." && tmux send-keys -t "$TESTER_PANE" Enter
fi
```
- Tester pane이 이미 존재하면 재사용합니다
- 알림 전송 후 사용자에게 "tester에 테스트를 요청했습니다" 메시지 출력

## Tester로부터 수정 요청 수신 시
- Tester가 테스트 실패 내용과 함께 수정 요청을 보냅니다
- 에러 내용을 분석하고 코드를 수정합니다
- 수정 완료 후 다시 Tester에게 테스트 요청을 보냅니다 (기존 pane 재사용)
