# Orchestrate Skill Requirements

orchestrate 스킬을 사용할 때 **반드시 지켜야 할 보안 요구사항**입니다.

## ⚠️ 핵심: Worktree 격리 (MANDATORY)

**문제:** Executor가 메인 레포에서 작업하면 큰 위험
- 의도하지 않은 파일 수정
- 병렬 작업으로 인한 충돌
- 부주의로 인한 메인 브랜치 오염

**해결책:** worktree 격리
- Leader: 워크트리 생성 → 세션 파일에 경로 저장
- Executor: 세션 파일에서 경로 읽고 **자동으로 cd**
- Guard: 메인 레포 감지 시 **즉시 exit**

---

## Orchestrate 스킬 구현 (Leader)

orchestrate 스킬에서 다음을 **반드시** 수행해야 합니다:

```bash
# 1. Worktree 생성
WORKTREE_PATH=$(mktemp -d)
WORKTREE_BRANCH="feat/$(date +%s)"

git worktree add "$WORKTREE_PATH" -b "$WORKTREE_BRANCH" main

# 2. 세션 파일에 worktree_path 저장
SESSION_ID="orch-$(date +%s)"
SESSION_FILE="~/.claude/orchestrate/sessions/${SESSION_ID}.json"

jq -n \
  --arg session_id "$SESSION_ID" \
  --arg spec_id "{SPEC-ID}" \
  --arg target_dir "$PWD" \
  --arg worktree_path "$WORKTREE_PATH" \
  --arg worktree_branch "$WORKTREE_BRANCH" \
  --arg leader_pane "$LEADER_PANE" \
  --arg leader_window "$LEADER_WINDOW" \
  '{
    session_id: $session_id,
    spec_id: $spec_id,
    target_dir: $target_dir,
    worktree_path: $worktree_path,
    worktree_branch: $worktree_branch,
    status: "executor_active",
    created_at: now | todate,
    leader: {
      pane_id: $leader_pane,
      window_id: $leader_window,
      pid: env.PPID
    },
    executor: {
      pane_id: null,
      status: "pending"
    },
    tester: {
      pane_id: null,
      status: "pending"
    }
  }' > "$SESSION_FILE"

# 3. Executor pane 생성 시 환경변수 전달
EXECUTOR_PANE=$(tmux split-window -v \
  -t "$LEADER_PANE" \
  -c "$WORKTREE_PATH" \  # 반드시 worktree_path로 시작!
  -e "ORCHESTRATE_SESSION_ID=$SESSION_ID" \
  -e "ORCHESTRATE_SESSION_FILE=$SESSION_FILE" \
  -P -F '#{pane_id}' \
  "mise run z.ai:claude -- --dangerously-skip-permissions")

# 4. 세션 파일에 Executor pane ID 저장
jq ".executor.pane_id = \"$EXECUTOR_PANE\"" \
  "$SESSION_FILE" > "${SESSION_FILE}.tmp" && \
  mv "${SESSION_FILE}.tmp" "$SESSION_FILE"
```

---

## Executor 시작 가드 (executor-mode.md)

Executor는 **세션 파일에서 worktree_path를 읽고 자동으로 cd**합니다:

```bash
# 1. 세션 파일 읽기
WORKTREE_PATH=$(jq -r '.worktree_path' "$ORCHESTRATE_SESSION_FILE")

# 2. Worktree로 이동 (필수!)
if [ -z "$WORKTREE_PATH" ] || [ "$WORKTREE_PATH" = "null" ]; then
  echo "❌ SECURITY ERROR: worktree_path not found in session file!"
  echo "   orchestrate must create a worktree first."
  exit 1
fi

cd "$WORKTREE_PATH"

# 3. 메인 레포가 아닌지 확인 (double-check)
REPO_ROOT=$(git rev-parse --show-toplevel)
if [ "$(basename "$REPO_ROOT")" = "$(basename $(git rev-parse --git-common-dir))" ]; then
  # .git이 현재 디렉토리의 부모가 아님 = worktree OK
  :
else
  echo "❌ SECURITY ERROR: Working in main repository!"
  echo "   Executor must only work in worktree."
  exit 1
fi

echo "✅ Working in worktree: $WORKTREE_PATH"
```

---

## 세션 파일 포맷

```json
{
  "session_id": "orch-1707345600",
  "spec_id": "SPEC-001",
  "target_dir": "/path/to/main/repo",
  "worktree_path": "/tmp/worktree-xyz",
  "worktree_branch": "feat/1707345600",
  "status": "executor_active|tester_active|completed",
  "created_at": "2024-02-07T12:00:00+00:00",
  "leader": {
    "pane_id": "%123",
    "window_id": "@4",
    "pid": 12345
  },
  "executor": {
    "pane_id": "%124",
    "status": "executing|completed"
  },
  "tester": {
    "pane_id": "%125",
    "status": "idle|testing|completed"
  }
}
```

---

## Cleanup (Leader)

orchestrate 완료 후 **반드시 worktree 정리**:

```bash
# 1. Executor/Tester pane 종료
tmux kill-pane -t "$EXECUTOR_PANE"
tmux kill-pane -t "$TESTER_PANE"

# 2. Worktree 제거
WORKTREE_PATH=$(jq -r '.worktree_path' "$SESSION_FILE")
WORKTREE_BRANCH=$(jq -r '.worktree_branch' "$SESSION_FILE")

git worktree remove "$WORKTREE_PATH"
git branch -d "$WORKTREE_BRANCH"

# 3. 세션 파일 정리
rm "$SESSION_FILE"
```

---

## Checklist

- [ ] orchestrate 시작 시 worktree 생성
- [ ] 세션 파일에 `worktree_path` 저장
- [ ] Executor pane 생성 시 `-c "$WORKTREE_PATH"` 지정
- [ ] 환경변수 `ORCHESTRATE_SESSION_FILE` 전달
- [ ] Executor는 첫 단계에서 워크트리 경로 확인 후 cd
- [ ] 메인 레포 감지 시 즉시 exit
- [ ] 완료 후 worktree 정리

---

## 주의사항

**절대 금지:**
- ❌ Executor를 메인 레포에서 실행
- ❌ 세션 파일 없이 Executor 실행
- ❌ worktree_path 없이 orchestrate 진행

**권장:**
- ✅ 항상 워크트리에서 작업
- ✅ 세션 파일로 상태 추적
- ✅ 자동 Guard 체크
