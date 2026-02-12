---
name: orchestrate
description: Leader → Executor → Tester → Review 전체 워크플로우 실행
user-invocable: true
argument: [--new] 기능 설명 (예: "로그인 기능")
---

# /orchestrate

Leader가 직접 스펙을 작성하고 Executor 세션으로 실행합니다. Tester는 Executor가 필요 시 on-demand로 생성합니다.

## 전체 흐름
```
Leader (직접 스펙 작성 → pending/)
  │
  └──send-keys──→ Executor (exec-ears)
                      │
                      ├── 구현 → done/
                      └── Tester pane 생성 (on-demand)
                            │
                        ┌───┤
                        │   ├── 성공 → Leader (완료 알림)
                        │   │            └── review-quick 실행
                        │   └── 실패 → Executor (수정 요청)
                        └───────────────┘ (E ↔ T 반복)
```

## Arguments
- `기능 설명` — 구현할 기능 (필수)
- `--new` — 기존 dual 세션 무시하고 새로 생성 (선택)

## Instructions

### 0. 레포/Worktree/브랜치 선택
사용자에게 대화형으로 작업 환경을 선택하도록 합니다:

**1) 레포 선택**
- 현재 디렉토리가 git 레포인 경우: "현재 레포 사용" 또는 "다른 레포 선택"
- 현재 디렉토리가 git 레포가 아닌 경우: 사용 가능한 레포 목록 표시
  ```bash
  find ~ -maxdepth 3 -name ".git" -type d 2>/dev/null | xargs dirname | sort
  ```

**2) Worktree 선택** (선택된 레포에서)
- 현재 worktree 또는 사용 가능한 worktree 목록 제시
  ```bash
  git worktree list | awk '{print $1}'
  ```

**3) 브랜치 선택**
- 현재 브랜치 유지 또는 다른 브랜치로 변경
- 새 브랜치 생성 옵션 (MMDD/{type}/{name} 형식)
- 브랜치 목록:
  ```bash
  git branch -a | sed 's/^ *//' | grep -v "^*" | head -10
  ```

선택된 경로를 `TARGET_DIR`에 저장합니다.

### 1. Leader ID 결정
현재 윈도우 이름에서 Leader ID를 추출하거나 새로 할당합니다:
```bash
CURRENT_WIN=$(tmux display-message -p '#{window_name}')

# 이미 leaderN이면 그 번호 사용, 아니면 최대값+1
if echo "$CURRENT_WIN" | grep -qE '^leader[0-9]+$'; then
  LID=$(echo "$CURRENT_WIN" | sed 's/^leader//')
else
  MAX_ID=$(tmux list-windows -F '#{window_name}' | sed -n 's/^leader\([0-9]\{1,\}\)$/\1/p' | sort -n | tail -1)
  LID=$(( ${MAX_ID:-0} + 1 ))
fi
```

### 2. 스펙 작성 (Leader가 직접 수행하는 유일한 코드 관련 작업)
Leader가 EARS 스펙을 작성하여 `~/.claude/specs/{project}/pending/`에 저장합니다. **스펙 작성까지만 Leader의 역할이며, 구현은 반드시 Executor에게 위임합니다.**

**스펙 저장 위치:**
```bash
# TARGET_DIR의 basename을 project 이름으로 사용
PROJECT=$(basename "$TARGET_DIR")
SPEC_DIR="$HOME/.claude/specs/$PROJECT/pending"
mkdir -p "$SPEC_DIR"
# SPEC_FILE="$SPEC_DIR/{SPEC-ID}.md"에 저장
```

**스펙 작성 프로세스:**
- 코드베이스를 탐색 (sub-agent 위임)하여 필요한 컨텍스트 수집 (TARGET_DIR 기준)
- EARS 형식으로 스펙 작성 (Requirements, Scope, Acceptance Criteria)
- `pending/`에 저장

### 3. Executor 세션 확인/실행
**항상 새 dual 세션을 생성합니다** (orchestrate는 매번 새로운 작업이므로):
```bash
# 선택된 디렉토리(TARGET_DIR)로 이동하여 새 dual 세션 생성
cd "$TARGET_DIR"

# 새로운 dual 세션 생성
LEADER_ID=$LID mise run claude-dual
```

**만약 `--new` 플래그가 없고 기존 dual 세션이 있으면:**
- 사용자에게 "기존 dual 세션을 재사용할까요?" 확인
- 재사용하면: 기존 dual 윈도우를 재사용
- 새로 만들면: 위 명령으로 새 세션 생성

### 4. Executor에게 명령 전달
dual 윈도우의 executor pane(index 0)에 exec-ears 명령을 전송합니다:
```bash
DUAL_WIN=$(tmux list-windows -F '#{window_name}' | grep "^dual${LID}-" | tail -1)
if [ -z "$DUAL_WIN" ]; then echo "dual 윈도우를 찾을 수 없습니다"; exit 1; fi
EXECUTOR_PANE=$(tmux list-panes -t "$DUAL_WIN" -F '#{pane_id}' | head -1)
tmux send-keys -t "$EXECUTOR_PANE" -l '/exec-ears' && tmux send-keys -t "$EXECUTOR_PANE" Enter
```

### 5. 진행 모니터링
사용자에게 안내합니다:
- "📍 레포: {TARGET_DIR}, 브랜치: {BRANCH}"
- "스펙을 작성하여 pending/에 저장했습니다"
- "Executor 세션에서 구현을 시작했습니다 (dual${LID}-*)"
- "Executor 구현 완료 후 Tester pane을 생성하여 테스트합니다"
- "Tester가 테스트 실패 시 Executor에게 수정 요청합니다 (E ↔ T 반복)"
- "Tester가 테스트 성공 시 이 세션에 알림이 옵니다"
- "완료 알림 수신 후 /review-quick으로 검증을 실행합니다"

### 6. 완료 후 검증
Tester가 테스트 성공하면 이 세션에 메시지가 도착합니다.
메시지를 수신하면 다음을 순차 실행합니다:
1. `specs-status`로 완료 확인
2. `git diff`로 변경사항 확인
3. 변경사항이 있으면 `/review-quick`으로 코드 리뷰 실행
4. 리뷰 결과와 함께 사용자에게 최종 보고

## 주의사항
- **CRITICAL: Leader는 절대 스펙을 직접 구현하지 않습니다. 반드시 Executor에게 전달합니다.**
- **Executor 세션은 선택된 TARGET_DIR에서 열립니다** (사용자가 선택한 레포/worktree/브랜치)
- orchestrate 실행 시점에 레포/worktree/브랜치를 선택할 수 있으므로, 여러 프로젝트를 오가며 작업 가능합니다
- Tester는 Executor가 구현 완료 후 on-demand로 pane을 생성합니다
- Executor → Tester 테스트 요청은 executor-mode 규칙에 의해 자동 수행됩니다
- Tester ↔ Executor 반복은 tester-mode 규칙에 의해 자동 수행됩니다
- Tester → Leader 완료 알림은 tester-mode 규칙에 의해 자동 수행됩니다
- Leader는 알림 수신 후 review-quick을 수동 또는 자동으로 실행합니다
