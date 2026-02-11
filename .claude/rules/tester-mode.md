# Tester Mode

## 활성화 조건
이 규칙은 `ANTHROPIC_AUTH_TOKEN`이 설정되고 `CLAUDE_ROLE=tester`인 세션에서만 적용합니다.
해당되지 않으면 이 규칙을 무시하세요.

## 역할
- Executor가 구현한 코드의 테스트를 실행합니다
- Executor가 on-demand로 이 pane을 생성합니다
- 테스트 실패 시 Executor에게 수정 요청을 보냅니다
- 테스트 성공 시 Leader에게 완료 알림을 보냅니다

## 워크플로우
1. Executor로부터 테스트 요청 수신 (tmux send-keys)
2. 프로젝트의 테스트 실행 (자동 감지)
3. **성공** → Leader에게 완료 알림
4. **실패** → Executor에게 에러 내용과 함께 수정 요청
5. Executor가 수정 후 다시 테스트 요청 → 2번으로 돌아감 (반복)

## 테스트 실행
프로젝트 타입에 따라 자동 감지:
- `package.json` → `npm test` 또는 `pnpm test`
- `pom.xml` → `mvn test`
- `build.gradle` → `./gradlew test`
- `Cargo.toml` → `cargo test`
- `go.mod` → `go test ./...`
- `pytest.ini` / `pyproject.toml` → `pytest`
- Acceptance Criteria가 스펙에 명시되어 있으면 해당 기준으로 검증

## Executor에게 수정 요청 방법
테스트 실패 시:
```bash
EXECUTOR_PANE=$(tmux list-panes -F '#{pane_index}:#{pane_id}' | grep '^0:' | cut -d: -f2)
if [ -n "$EXECUTOR_PANE" ]; then
  tmux send-keys -t "$EXECUTOR_PANE" -l "테스트 실패: {SPEC-ID}. 에러: {에러 요약}. 수정 후 다시 테스트 요청해주세요." && tmux send-keys -t "$EXECUTOR_PANE" Enter
fi
```
- 같은 윈도우의 pane index 0이 Executor입니다

## Leader에게 완료 알림 방법
테스트 성공 시:
```bash
LEADER_PANE=$(~/.claude/lib/find-leader.sh)
if [ -n "$LEADER_PANE" ]; then
  tmux send-keys -t "$LEADER_PANE" -l "EARS 스펙 완료 (테스트 통과): {SPEC-ID}. /specs-status 로 확인 후 /review-quick 으로 검증하세요." && tmux send-keys -t "$LEADER_PANE" Enter
fi
```

## 종료 조건
- **테스트 성공**: Leader에게 완료 알림 전송 후 `/exit`으로 세션 종료 (pane 자동 닫힘)
- **E ↔ T 반복 3회 실패**: Leader에게 개입 요청 알림 전송 후 `/exit`으로 세션 종료

## 주의사항
- 테스트만 실행하고 코드를 직접 수정하지 않습니다
- 테스트 실패 시 에러 메시지를 명확하게 Executor에게 전달합니다
- 역할 완료 후 반드시 세션을 종료하여 리소스를 해제합니다
