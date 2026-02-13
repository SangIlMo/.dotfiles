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
1. **세션 파일 읽기 + 워크트리 체크**
   ```bash
   # 세션 파일에서 worktree_path 읽기
   WORKTREE_PATH=$(jq -r '.worktree_path' "$ORCHESTRATE_SESSION_FILE")

   # 워크트리 경로로 이동 (반드시 필수)
   if [ -n "$WORKTREE_PATH" ] && [ "$WORKTREE_PATH" != "null" ]; then
     cd "$WORKTREE_PATH"
   else
     # 워크트리 경로 없음 = 메인 레포 작업 위험!
     echo "❌ ERROR: worktree_path not found in session file!"
     echo "   This means you're working in the main repo, which is DANGEROUS."
     echo "   orchestrate must create a worktree first."
     exit 1
   fi

   # 현재 디렉토리가 메인 레포가 아닌지 확인
   if [ -f ".git/config" ]; then
     REPO_MAIN=$(git rev-parse --git-common-dir)
     CURRENT_MAIN=$(pwd)/.git
     if [ "$REPO_MAIN" = "$CURRENT_MAIN" ]; then
       echo "❌ SECURITY ERROR: Working in main repository!"
       echo "   Current dir: $(pwd)"
       echo "   Executor must only work in worktree."
       exit 1
     fi
   fi
   ```

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
# 세션 파일에서 Leader의 pane ID 읽기 (같은 윈도우에 생성하기 위해)
LEADER_PANE=$(jq -r '.leader.pane_id' "$ORCHESTRATE_SESSION_FILE")
LEADER_WINDOW=$(tmux display-message -p -t "$LEADER_PANE" '#{window_id}')

# Tester pane이 없으면 Leader 탭 내에서 아래로 분할 생성
TESTER_PANE=$(jq -r '.tester.pane_id' "$ORCHESTRATE_SESSION_FILE")
if [ "$TESTER_PANE" = "null" ] || [ -z "$TESTER_PANE" ]; then
  TESTER_PANE=$(tmux split-window -v -t "$LEADER_PANE" -c "$PWD" -P -F '#{pane_id}' \
    "ORCHESTRATE_SESSION_ID='$ORCHESTRATE_SESSION_ID' ORCHESTRATE_SESSION_FILE='$ORCHESTRATE_SESSION_FILE' CLAUDE_ROLE=tester mise run z.ai:claude -- --dangerously-skip-permissions")

  # 세션 파일 업데이트 (Tester pane ID 저장)
  jq ".tester.pane_id = \"$TESTER_PANE\" | .tester.status = \"ready\"" \
    "$ORCHESTRATE_SESSION_FILE" > "${ORCHESTRATE_SESSION_FILE}.tmp" && \
    mv "${ORCHESTRATE_SESSION_FILE}.tmp" "$ORCHESTRATE_SESSION_FILE"

  sleep 2  # Tester 초기화 대기
fi

# 테스트 요청 전송 (올바른 tmux send-keys 형식)
if [ -n "$TESTER_PANE" ] && [ "$TESTER_PANE" != "null" ]; then
  tmux send-keys -t "$TESTER_PANE" "테스트 요청: {SPEC-ID}. 구현 완료된 스펙을 테스트해주세요." C-m
fi
```

**메모:**
- Tester pane이 **같은 윈도우**에 생성됩니다 (Leader pane 아래로 분할)
- Tester pane이 이미 존재하면 재사용합니다 (세션 파일에서 확인)
- `tmux send-keys -t PANE "메시지" C-m` 형식 (Enter 대신 C-m 사용)

## Tester로부터 메시지 수신 및 Executor 역할
Tester가 테스트 결과를 보낸 후 Executor가 수행할 작업:

```bash
# Tester로부터 메시지 수신 (tmux send-keys로 입력됨)
# - 테스트 실패: Executor가 수정 후 다시 테스트 요청
# - 테스트 성공: 세션 파일 업데이트

# 테스트 성공 시 세션 파일만 업데이트 (Leader에게 보고는 Tester가 함)
jq ".executor.status = \"completed\"" \
  "$ORCHESTRATE_SESSION_FILE" > "${ORCHESTRATE_SESSION_FILE}.tmp" && \
  mv "${ORCHESTRATE_SESSION_FILE}.tmp" "$ORCHESTRATE_SESSION_FILE"
```

**흐름:**
1. Executor → Tester에게 테스트 요청
2. Tester → Leader에게 결과 직접 보고 (다음 섹션 참조)
3. Tester → Executor에게 수정 요청만 전송 (실패 시)
4. **성공:** Executor는 세션 파일 업데이트만 수행
5. **실패:** Executor가 수정 후 2번 반복

## Tester로부터 수정 요청 수신 시
- Tester가 테스트 실패 내용과 함께 수정 요청을 보냅니다
- 에러 내용을 분석하고 코드를 수정합니다
- 수정 완료 후 다시 Tester에게 테스트 요청을 보냅니다 (기존 pane 재사용)
