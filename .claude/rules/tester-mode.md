# Tester Mode

## 활성화 조건
이 규칙은 `ANTHROPIC_AUTH_TOKEN`이 설정되고 `CLAUDE_ROLE=tester`인 세션에서만 적용합니다.
해당되지 않으면 이 규칙을 무시하세요.

## 역할
- Executor가 구현한 코드의 테스트를 실행합니다
- Executor가 on-demand로 이 pane을 생성합니다
- **테스트 실패 시:** Executor에게 수정 요청을 보냅니다
- **테스트 성공 시:**
  1. 먼저 Executor에게 완료 알림을 보냅니다
  2. 그 다음 Leader에게 완료 알림을 보냅니다

## 워크플로우
1. 세션 파일 읽기: `$ORCHESTRATE_SESSION_FILE`에서 Leader/Executor pane ID 확인
2. Executor로부터 테스트 요청 수신 (tmux send-keys)
3. 프로젝트의 테스트 실행 (자동 감지)
4. **성공:**
   - 세션 파일 업데이트
   - Executor에게 "완료" 알림 전송
   - Leader에게 "완료" 알림 전송
5. **실패:**
   - 세션 파일에 에러 기록
   - Executor에게 수정 요청 전송
6. Executor가 수정 후 다시 테스트 요청 → 2번으로 돌아감 (반복)

## 테스트 실행
프로젝트 타입에 따라 자동 감지:
- `package.json` → `npm test` 또는 `pnpm test`
- `pom.xml` → `mvn test`
- `build.gradle` → `./gradlew test`
- `Cargo.toml` → `cargo test`
- `go.mod` → `go test ./...`
- `pytest.ini` / `pyproject.toml` → `pytest`
- Acceptance Criteria가 스펙에 명시되어 있으면 해당 기준으로 검증

## 테스트 결과 전달

### 테스트 실패 시: Executor에게 수정 요청
```bash
# 세션 파일에서 Executor pane ID 읽기
EXECUTOR_PANE=$(jq -r '.executor.pane_id' "$ORCHESTRATE_SESSION_FILE")

if [ -n "$EXECUTOR_PANE" ] && [ "$EXECUTOR_PANE" != "null" ]; then
  tmux send-keys -t "$EXECUTOR_PANE" "테스트 실패: {SPEC-ID}. 에러: {에러 요약}. 수정 후 다시 테스트 요청해주세요." Enter
fi
```

### 테스트 성공 시: Executor & Leader에게 알림
**중요:** 테스트 성공 시 **먼저 Executor에게 알린 후** Leader에게 알립니다.

```bash
# 세션 파일에서 pane ID 읽기
EXECUTOR_PANE=$(jq -r '.executor.pane_id' "$ORCHESTRATE_SESSION_FILE")
LEADER_PANE=$(jq -r '.leader.pane_id' "$ORCHESTRATE_SESSION_FILE")

# 1) Executor에게 먼저 테스트 성공 알림
if [ -n "$EXECUTOR_PANE" ] && [ "$EXECUTOR_PANE" != "null" ]; then
  tmux send-keys -t "$EXECUTOR_PANE" "테스트 성공: {SPEC-ID} 구현 완료됨." Enter
fi

# 2) 그 다음 Leader에게 완료 알림
if [ -n "$LEADER_PANE" ] && [ "$LEADER_PANE" != "null" ]; then
  tmux send-keys -t "$LEADER_PANE" "EARS 스펙 완료 (테스트 통과): {SPEC-ID}. /specs-status 로 확인 후 /review-quick 으로 검증하세요." Enter
fi
```

**순서:**
1. Executor에게 먼저 알림 (구현자가 바로 알 수 있도록)
2. 이후 Leader에게 알림 (검토자 확인)

**메모:**
- `-l` 플래그 제거 (줄바꿈 문제 해결)
- `tmux send-keys -t PANE "메시지" Enter` 형식 (한 번에 전송)

## 종료 조건
- **테스트 성공**: Executor → Leader 순서로 완료 알림 전송 후 `/exit`으로 세션 종료 (pane 자동 닫힘)
- **E ↔ T 반복 3회 실패**: Executor & Leader에게 개입 요청 알림 전송 후 `/exit`으로 세션 종료

## 주의사항
- 테스트만 실행하고 코드를 직접 수정하지 않습니다
- 테스트 실패 시 에러 메시지를 명확하게 Executor에게 전달합니다
- 역할 완료 후 반드시 세션을 종료하여 리소스를 해제합니다
