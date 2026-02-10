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
6. **Leader에게 완료 알림**: tmux send-keys로 leader pane에 알림 전송

## 결과 요약 포맷
```
## Execution Result
- completed: {timestamp}
- status: success|partial|failed
- Changes: [list of files changed]
- Notes: (실행 중 발견된 사항)
```

## Leader 알림 방법
구현 완료 후 반드시 실행:
```bash
LEADER_PANE=$(~/.claude/lib/find-leader.sh)
if [ -n "$LEADER_PANE" ]; then
  tmux send-keys -t "$LEADER_PANE" -l "EARS 스펙 완료: {SPEC-ID}. /specs-status 로 확인 후 /review-quick 으로 검증하세요." && tmux send-keys -t "$LEADER_PANE" Enter
fi
```
- `~/.claude/lib/find-leader.sh`가 CLAUDE_LEADER_ID 또는 윈도우명에서 Leader를 자동 식별합니다
- 알림 전송 후 사용자에게 "leader에 완료를 알렸습니다" 메시지 출력
