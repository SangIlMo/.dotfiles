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

### 1. Leader Pane 식별
현재 pane을 Leader pane으로 식별하고, 나중에 Executor/Tester가 찾을 수 있도록 합니다:
```bash
# 현재 pane ID를 Leader pane ID로 저장
LEADER_PANE_ID=$(tmux display-message -p '#{pane_id}')
LEADER_PID=$$

# 현재 윈도우 ID
LEADER_WINDOW=$(tmux display-message -p '#{window_id}')

# 나중에 Executor/Tester가 사용할 수 있도록 환경변수로 저장
export CLAUDE_LEADER_PANE_ID="$LEADER_PANE_ID"
export CLAUDE_LEADER_PID="$LEADER_PID"
export CLAUDE_LEADER_WINDOW="$LEADER_WINDOW"
```

✅ **Leader 식별 강화:**
- Executor/Tester 세션에서 `$CLAUDE_LEADER_PANE_ID` 환경변수로 Leader pane 직접 접근
- 윈도우명 파싱 불필요 (환경변수로 명시적 전달)

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

### 3. Executor Pane 생성
**현재 윈도우에서 오른쪽으로 수직 분할하여 Executor pane을 생성합니다:**
```bash
# 현재 탭 내에서 오른쪽(50%)으로 수직 분할
EXECUTOR_PANE=$(tmux split-window -h -c "$TARGET_DIR" -P -F '#{pane_id}' \
  "CLAUDE_LEADER_PANE_ID='$CLAUDE_LEADER_PANE_ID' CLAUDE_LEADER_PID='$CLAUDE_LEADER_PID' CLAUDE_LEADER_WINDOW='$CLAUDE_LEADER_WINDOW' $SHELL")

# 창 크기 조정 (Leader 70%, Executor 30%)
tmux resize-pane -t "$CLAUDE_LEADER_PANE_ID" -x 140  # 또는 사용자 선호에 따라
```

**구조:**
```
┌─ Pane 0 (Leader)      │ Pane 1 (Executor)
│ /orchestrate 실행     │ 대기 중
│ 70%                   │ 30%
└───────────────────────┴──────────────────
```

**Executor에서 환경변수 사용:**
- Executor/Tester는 `$CLAUDE_LEADER_PANE_ID`로 Leader pane 직접 접근
- 윈도우명 파싱 불필요

### 4. Executor에게 명령 전달
생성된 Executor pane에 `/exec-ears` 명령을 전송합니다:
```bash
# Executor pane은 스텝 3에서 반환된 $EXECUTOR_PANE
tmux send-keys -t "$EXECUTOR_PANE" -l '/exec-ears' && tmux send-keys -t "$EXECUTOR_PANE" Enter
```

**Executor pane 내부에서:**
- Executor는 환경변수 `$CLAUDE_LEADER_PANE_ID`로 Leader pane 참조
- Tester 필요 시 같은 창 내에서 아래쪽으로 분할 (`tmux split-window -v`)
- Tester → Leader 메시지 전송: `tmux send-keys -t "$CLAUDE_LEADER_PANE_ID"`

### 5. 진행 모니터링
사용자에게 안내합니다:
```
┌─────────────────────────────────────────────────────────┐
│ 📍 Orchestrate 시작                                      │
├─────────────────────────────────────────────────────────┤
│ 레포: {TARGET_DIR}                                      │
│ 브랜치: {BRANCH}                                        │
│ Pane: Leader (좌 70%) | Executor (우 30%)             │
├─────────────────────────────────────────────────────────┤
│ ✅ 스펙 저장: {SPEC_FILE}                              │
│ ✅ Executor pane 생성: {EXECUTOR_PANE}                 │
│ ⏳ /exec-ears 실행 중...                               │
│                                                         │
│ 진행 과정:                                              │
│  1. Executor가 스펙 구현 중                             │
│  2. 테스트 필요 시 Tester pane 자동 생성              │
│  3. Tester → Executor (E ↔ T 반복)                     │
│  4. 완료 시 여기(Leader pane)에 메시지 도착            │
│  5. /review-quick으로 최종 검증                         │
└─────────────────────────────────────────────────────────┘
```

**조작:**
- `Ctrl+B, {` / `Ctrl+B, }` — Pane 크기 조정
- Executor pane 클릭 → Executor와 상호작용
- Leader pane 클릭 → 메시지 대기

### 6. 완료 후 검증
Tester가 테스트 성공하면 이 세션에 메시지가 도착합니다.
메시지를 수신하면 다음을 순차 실행합니다:
1. `specs-status`로 완료 확인
2. `git diff`로 변경사항 확인
3. 변경사항이 있으면 `/review-quick`으로 코드 리뷰 실행
4. 리뷰 결과와 함께 사용자에게 최종 보고

## 주의사항

### 구조
```
현재 윈도우  ┌─ Leader (Pane 0, 70%)
  │         │ /orchestrate 실행
  │         │ 스펙 작성
  │         │ (메시지 수신 대기)
  │         │
  └─────────┼─ Executor (Pane 1, 30%)
            │ /exec-ears 실행
            │ 구현 진행
            │
            └─ Tester (Pane 2, 필요시)
              /exec-ears → Tester pane 분할

환경변수 연결:
  Leader → $CLAUDE_LEADER_PANE_ID
         → $CLAUDE_LEADER_WINDOW
         ↑ Executor/Tester가 이용
```

### 규칙
- **CRITICAL: Leader는 절대 스펙을 직접 구현하지 않습니다. 반드시 Executor에게 전달합니다.**
- **같은 탭(윈도우) 내 pane 분할** — Leader (Pane 0, 70%) | Executor (Pane 1, 30%)
- **환경변수로 명시적 전달** — `$CLAUDE_LEADER_PANE_ID`로 Leader pane을 환경변수로 참조 (윈도우명 파싱 불필요)
- **Executor 세션 위치** — 선택된 TARGET_DIR에서 열림
- **Tester 생성** — Executor가 구현 완료 후 현재 윈도우 내에서 아래쪽 분할로 생성
- **메시지 전달** — tmux send-keys로 Executor/Tester → Leader로 직접 송수신
- Executor → Tester 테스트 요청은 executor-mode 규칙에 의해 자동 수행
- Tester ↔ Executor 반복은 tester-mode 규칙에 의해 자동 수행
- Tester → Leader 완료 알림은 tester-mode 규칙에 의해 자동 수행
- Leader는 알림 수신 후 review-quick을 수동 또는 자동으로 실행
