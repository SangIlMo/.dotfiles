---
name: orchestrate
description: Leader → Executor → Tester → Review 전체 워크플로우 실행
user-invocable: true
argument: [--new] 기능 설명 (예: "로그인 기능")
---

# /orchestrate

Leader가 직접 스펙을 작성하고 Executor-Tester 듀얼 세션으로 실행합니다.

## 전체 흐름
```
Leader (직접 스펙 작성 → pending/)
  │
  └──send-keys──→ Executor (exec-ears)
                      │
                      ├── 구현 → done/
                      └──send-keys──→ Tester
                                        │
                                    ┌───┤
                                    │   ├── 성공 → Leader (완료 알림)
                                    │   │            └── review-team 실행
                                    │   └── 실패 → Executor (수정 요청)
                                    └───────────────┘ (E ↔ T 반복)
```

## Arguments
- `기능 설명` — 구현할 기능 (필수)
- `--new` — 기존 dual 세션 무시하고 새로 생성 (선택)

## Instructions

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

### 2. 스펙 작성
Leader가 직접 EARS 스펙을 작성하여 `~/.claude/specs/{project}/pending/`에 저장합니다:
- 코드베이스를 탐색 (sub-agent 위임)하여 필요한 컨텍스트 수집
- EARS 형식으로 스펙 작성 (Requirements, Scope, Acceptance Criteria)
- `pending/`에 저장

### 3. 듀얼 세션 확인/실행
`--new` 플래그가 있거나 매칭되는 dual 윈도우가 없으면 새로 생성합니다:
```bash
# 이 Leader의 dual 윈도우 목록 확인 (dual{N}-1, dual{N}-2, ...)
tmux list-windows -F '#{window_name}' | grep "^dual${LID}-"

# 새로 생성 (--new이거나 없을 때) — 자동으로 dual{N}-{M} 번호 증가
LEADER_ID=$LID mise run claude-dual
```
`--new`가 아니면 가장 최근 `dual{LID}-*` 윈도우를 재사용합니다.

### 4. Executor에게 명령 전달
dual 윈도우의 좌측 pane(executor, index 0)에 exec-ears 명령을 전송합니다:
```bash
DUAL_WIN=$(tmux list-windows -F '#{window_name}' | grep "^dual${LID}-" | tail -1)
if [ -z "$DUAL_WIN" ]; then echo "dual 윈도우를 찾을 수 없습니다"; exit 1; fi
EXECUTOR_PANE=$(tmux list-panes -t "$DUAL_WIN" -F '#{pane_id}' | head -1)
tmux send-keys -t "$EXECUTOR_PANE" -l '/exec-ears' && tmux send-keys -t "$EXECUTOR_PANE" Enter
```

### 5. 진행 모니터링
사용자에게 안내합니다:
- "스펙을 작성하여 pending/에 저장했습니다"
- "Executor에게 구현을 요청했습니다"
- "Executor 구현 완료 후 Tester에게 테스트를 요청합니다"
- "Tester가 테스트 실패 시 Executor에게 수정 요청합니다 (E ↔ T 반복)"
- "Tester가 테스트 성공 시 이 세션에 알림이 옵니다"
- "완료 알림 수신 후 /review-team으로 검증을 실행합니다"

### 6. 완료 후 검증
Tester가 테스트 성공하면 이 세션에 메시지가 도착합니다.
메시지를 수신하면 다음을 순차 실행합니다:
1. `specs-status`로 완료 확인
2. `git diff`로 변경사항 확인
3. 변경사항이 있으면 `/review-quick`으로 코드 리뷰 실행
4. 리뷰 결과와 함께 사용자에게 최종 보고

## 주의사항
- 듀얼 세션은 Leader와 동일한 디렉토리에서 열립니다
- 2-pane 레이아웃: E(0) | T(1)
- Executor → Tester 테스트 요청은 executor-mode 규칙에 의해 자동 수행됩니다
- Tester ↔ Executor 반복은 tester-mode 규칙에 의해 자동 수행됩니다
- Tester → Leader 완료 알림은 tester-mode 규칙에 의해 자동 수행됩니다
- Leader는 알림 수신 후 review-team을 수동 또는 자동으로 실행합니다
