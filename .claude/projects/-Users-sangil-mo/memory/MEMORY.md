# tmux send-keys 올바른 형식

## ⚠️ 중요: Enter 키 입력 문제

**틀린 형식 (안 먹음):**
```bash
tmux send-keys -t PANE -l "command" && tmux send-keys -t PANE Enter
```

**올바른 형식 (먹음):**
```bash
tmux send-keys -t PANE "command" C-m
# 또는
tmux send-keys -t PANE "command" Enter
```

### 핵심 포인트
- **`-l` 플래그 금지**: 리터럴 문자열로 처리되어 Enter 키가 안 먹힘
- **한 번의 send-keys**: "텍스트" 뒤에 `C-m` 또는 `Enter` 키를 붙여서 한 번에 실행
- **`&&` 체이닝 금지**: 첫 명령 실패 시 두 번째 미실행
- **일관성**: 모든 send-keys를 `C-m`으로 통일 (tmux 표준)

### 올바른 예제
```bash
# Executor에게 명령 전송
EXECUTOR_PANE=$(tmux list-panes -F '#{pane_index}:#{pane_id}' | grep '^0:' | cut -d: -f2)
tmux send-keys -t "$EXECUTOR_PANE" "/exec-ears spec.md" C-m

# Tester에게 메시지 전송
TESTER_PANE=$(jq -r '.tester.pane_id' "$ORCHESTRATE_SESSION_FILE")
tmux send-keys -t "$TESTER_PANE" "테스트 요청: SPEC-001" C-m
```

---

# Orchestrate Architecture - Session Registry Pattern

## 문제점 (해결됨)
- 환경변수로 pane ID 전달 → 변수 손실, 찾지 못함
- 윈도우명 파싱 불안정 → 여러 상황에서 헷갈림
- Leader-Executor-Tester 간 통신 불명확

## 해결책: 파일 기반 세션 레지스트리
모든 orchestrate 세션을 JSON 파일로 관리 → 안정적이고 명확함

### 구조
```
~/.claude/orchestrate/sessions/
├── orch-1707345600.json  (SPEC-001)
├── orch-1707345700.json  (SPEC-002)
└── orch-1707345800.json  (SPEC-003)
```

### 세션 파일 형식 (JSON)
```json
{
  "session_id": "orch-1707345600",
  "spec_id": "SPEC-001",
  "target_dir": "/path/to/repo",
  "status": "executor_active | tester_active | completed",
  "created_at": "2024-02-07T12:00:00+00:00",
  "leader": {
    "pane_id": "%123",
    "window_id": "@4",
    "pid": 12345
  },
  "executor": {
    "pane_id": "%124",
    "status": "executing | waiting_tester"
  },
  "tester": {
    "pane_id": "%125",
    "status": "idle | testing | failed"
  }
}
```

### 사용 방법
**Leader (orchestrate 스킬):**
1. `SESSION_ID="orch-$(date +%s)"` 생성
2. 세션 파일 생성 (leader, executor, tester 초기값 설정)
3. Executor pane 생성 후 `executor.pane_id` 업데이트
4. `export ORCHESTRATE_SESSION_ID`, `export ORCHESTRATE_SESSION_FILE` (Executor에 전달)

**Executor (exec-ears):**
1. 세션 파일 `$ORCHESTRATE_SESSION_FILE`에서 pane ID 확인
2. 구현 진행
3. 구현 완료 → Tester pane 생성
4. **Tester로부터 메시지 수신 (테스트 결과)**
5. **성공:** Leader에게 최종 완료 알림 전송
6. **실패:** 수정 후 다시 Tester에게 테스트 요청

**Tester:**
1. 세션 파일에서 `executor.pane_id` 확인
2. Executor로부터 테스트 요청 수신
3. 테스트 실행
4. **결과를 Executor에게만 전송 (Leader에게는 X)**
5. 세션 종료 (`/exit`)

### 메시지 흐름 (1:1 원칙)
```
Executor → Tester: "테스트 요청"
           ↓
        Tester → Executor: "성공/실패"
           ↓
        성공: Executor → Leader: "완료"
        실패: Executor → Tester: "재테스트" (반복)
```

**원칙:** 각 역할은 다음 역할과만 1:1 통신 (혼선 방지)

### 장점
✅ 파일에서 읽으므로 확실함
✅ 여러 orchestrate 동시 실행 가능 (세션 파일 분리)
✅ 각 역할이 자신의 정보와 상대 정보를 명확히 알 수 있음
✅ 메시지 흐름 명확 (1:1 통신)
✅ 디버깅 쉬움 (세션 파일로 상태 추적)

## ⚠️ 중요: Worktree 보안

**문제:** Executor가 메인 레포에서 작업 → 큰 위험
- orchestrate가 워크트리 생성 → Executor는 반드시 그 워크트리에서만 작업

**해결책:**
1. orchestrate 스킬: 워크트리 생성 시 `worktree_path` 저장
2. 세션 파일 포맷에 `worktree_path` 추가
3. **Executor 시작 시:** `cd $WORKTREE_PATH` 자동 실행
4. **Guard 검사:** 메인 레포 감지 시 즉시 exit

**세션 파일 포맷 (업데이트):**
```json
{
  "worktree_path": "/path/to/worktree",
  "worktree_branch": "feat/feature-name",
  ...
}
```

**Executor 첫 단계:**
```bash
# 세션 파일에서 worktree_path 읽기
WORKTREE_PATH=$(jq -r '.worktree_path' "$ORCHESTRATE_SESSION_FILE")

# 반드시 워크트리로 이동 (없으면 exit 1)
if [ -z "$WORKTREE_PATH" ] || [ "$WORKTREE_PATH" = "null" ]; then
  echo "❌ ERROR: worktree_path not found! Working in main repo is DANGEROUS."
  exit 1
fi

cd "$WORKTREE_PATH"

# 메인 레포 아닌지 확인 (double-check)
if [ "$(git rev-parse --is-inside-work-tree)" = "true" ]; then
  # .git/config 경로가 main/.git인지 확인
  exit 1  # 메인 레포면 즉시 중단
fi
```
