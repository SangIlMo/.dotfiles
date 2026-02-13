# Tester Mode

## 활성화 조건
이 규칙은 `ANTHROPIC_AUTH_TOKEN`이 설정되고 `CLAUDE_ROLE=tester`인 세션에서만 적용합니다.
해당되지 않으면 이 규칙을 무시하세요.

## 역할
- Executor가 구현한 코드의 테스트를 실행합니다
- Executor가 on-demand로 이 pane을 생성합니다 (Leader 윈도우 아래로 분할)
- **테스트 성공 시:** Leader에게 직접 보고
- **테스트 실패 시:**
  - Executor에게 수정 요청 (구현 수정 요청)
  - Leader에게 실패 내용 보고

## 워크플로우
1. 세션 파일 읽기: `$ORCHESTRATE_SESSION_FILE`에서 Executor/Leader pane ID 확인
2. Executor로부터 테스트 요청 수신 (tmux send-keys)
3. 프로젝트의 테스트 실행 (자동 감지)
4. **성공:**
   - 세션 파일 업데이트
   - Leader에게 "테스트 성공" 보고 전송 (다음 섹션 참조)
5. **실패:**
   - 세션 파일에 에러 기록
   - Executor에게 "수정 요청" 전송
   - Leader에게 "테스트 실패" 보고
6. Executor가 수정 후 다시 테스트 요청 → 3번으로 돌아감 (반복)

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

### 테스트 성공 시: Leader에게 직접 보고
```bash
# 세션 파일에서 Leader/Executor pane ID 읽기
LEADER_PANE=$(jq -r '.leader.pane_id' "$ORCHESTRATE_SESSION_FILE")
EXECUTOR_PANE=$(jq -r '.executor.pane_id' "$ORCHESTRATE_SESSION_FILE")
SPEC_ID=$(jq -r '.spec_id' "$ORCHESTRATE_SESSION_FILE")

# 세션 파일 업데이트
jq ".tester.status = \"completed\" | .status = \"completed\"" \
  "$ORCHESTRATE_SESSION_FILE" > "${ORCHESTRATE_SESSION_FILE}.tmp" && \
  mv "${ORCHESTRATE_SESSION_FILE}.tmp" "$ORCHESTRATE_SESSION_FILE"

# Leader에게 성공 보고
if [ -n "$LEADER_PANE" ] && [ "$LEADER_PANE" != "null" ]; then
  tmux send-keys -t "$LEADER_PANE" "✅ 테스트 성공: ${SPEC_ID}. /specs-status 로 확인 후 /review-quick 으로 검증하세요." C-m
fi
```

### 테스트 실패 시: Executor 수정 요청 + Leader 보고
```bash
# 세션 파일에서 pane ID들 읽기
EXECUTOR_PANE=$(jq -r '.executor.pane_id' "$ORCHESTRATE_SESSION_FILE")
LEADER_PANE=$(jq -r '.leader.pane_id' "$ORCHESTRATE_SESSION_FILE")
SPEC_ID=$(jq -r '.spec_id' "$ORCHESTRATE_SESSION_FILE")

# 세션 파일에 에러 기록
jq ".tester.status = \"failed\" | .tester.error = \"{에러 요약}\"" \
  "$ORCHESTRATE_SESSION_FILE" > "${ORCHESTRATE_SESSION_FILE}.tmp" && \
  mv "${ORCHESTRATE_SESSION_FILE}.tmp" "$ORCHESTRATE_SESSION_FILE"

# Executor에게 수정 요청
if [ -n "$EXECUTOR_PANE" ] && [ "$EXECUTOR_PANE" != "null" ]; then
  tmux send-keys -t "$EXECUTOR_PANE" "❌ 테스트 실패: ${SPEC_ID}. 에러: {에러 요약}. 수정 후 다시 테스트 요청해주세요." C-m
fi

# Leader에게 실패 보고
if [ -n "$LEADER_PANE" ] && [ "$LEADER_PANE" != "null" ]; then
  tmux send-keys -t "$LEADER_PANE" "⚠️  테스트 실패: ${SPEC_ID}. Executor가 수정 중입니다. (재시도 진행 중)" C-m
fi
```

**메모:**
- Tester는 **Leader와 Executor** 두 곳에 메시지 전송
- 성공: Leader에게만, 실패: Executor(수정 요청) + Leader(상황 보고)
- `tmux send-keys -t PANE "메시지" C-m` 형식 (Enter 대신 C-m 사용)

## 종료 조건
- **테스트 성공**: Leader에게 성공 보고 후 `/exit`으로 세션 종료 (pane 자동 닫힘)
  - Tester pane이 자동으로 닫힘 (같은 윈도우 유지)
- **E ↔ T 반복 3회 실패**: Executor와 Leader 모두에게 알림 후 `/exit`으로 세션 종료
  ```bash
  EXECUTOR_PANE=$(jq -r '.executor.pane_id' "$ORCHESTRATE_SESSION_FILE")
  LEADER_PANE=$(jq -r '.leader.pane_id' "$ORCHESTRATE_SESSION_FILE")

  tmux send-keys -t "$EXECUTOR_PANE" "⛔ 테스트 반복 실패 (3회). 수동 개입이 필요합니다." C-m
  tmux send-keys -t "$LEADER_PANE" "⛔ 테스트 반복 실패. ${SPEC_ID} 수동 검토가 필요합니다." C-m
  ```

## 주의사항
- 테스트만 실행하고 코드를 직접 수정하지 않습니다
- 테스트 실패 시 에러 메시지를 명확하게 Executor에게 전달합니다
- 역할 완료 후 반드시 세션을 종료하여 리소스를 해제합니다
