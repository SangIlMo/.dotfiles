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
1. `pending/` 스펙 목록 확인
2. 스펙 선택 → `doing/`으로 이동
3. 스펙의 Scope와 Requirements에 따라 구현
4. Acceptance Criteria 검증
5. `done/`으로 이동, 파일 하단에 결과 요약 추가
6. **Tester에게 테스트 요청**: tmux send-keys로 같은 윈도우 pane index 1 (tester)에 테스트 요청 전송

## 결과 요약 포맷
```
## Execution Result
- completed: {timestamp}
- status: success|partial|failed
- Changes: [list of files changed]
- Notes: (실행 중 발견된 사항)
```

## Tester에게 테스트 요청 방법
구현 완료 후 반드시 실행:
```bash
TESTER_PANE=$(tmux list-panes -F '#{pane_index}:#{pane_id}' | grep '^1:' | cut -d: -f2)
if [ -n "$TESTER_PANE" ]; then
  tmux send-keys -t "$TESTER_PANE" -l "테스트 요청: {SPEC-ID}. 구현 완료된 스펙을 테스트해주세요." && tmux send-keys -t "$TESTER_PANE" Enter
fi
```
- 같은 윈도우의 pane index 1이 Tester입니다 (2-pane 레이아웃: E(0) | T(1))
- 알림 전송 후 사용자에게 "tester에 테스트를 요청했습니다" 메시지 출력

## Tester로부터 수정 요청 수신 시
- Tester가 테스트 실패 내용과 함께 수정 요청을 보냅니다
- 에러 내용을 분석하고 코드를 수정합니다
- 수정 완료 후 다시 Tester에게 테스트 요청을 보냅니다 (위 방법 반복)
