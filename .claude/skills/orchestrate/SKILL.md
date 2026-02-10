---
name: orchestrate
description: Leader → Planner → Executor → Review 전체 워크플로우 실행
user-invocable: true
argument: [--new] 기능 설명 (예: "로그인 기능")
---

# /orchestrate

Planner-Executor 듀얼 세션 워크플로우를 실행합니다.

## 전체 흐름
```
Leader ──send-keys──→ Planner (plan-ears)
                         │
                         ├── spec → pending/
                         └──send-keys──→ Executor (exec-ears)
                                            │
                                            ├── 구현 → done/
                                            └──send-keys──→ Leader
                                                              │
                                                              └── review-team 실행
```

## Arguments
- `기능 설명` — 구현할 기능 (필수)
- `--new` — 기존 dual 세션 무시하고 새로 생성 (선택)

## Instructions

### 1. 듀얼 세션 확인/실행
`--new` 플래그가 있거나 dual 윈도우가 없으면 새로 생성합니다:
```bash
# 기존 dual 확인
tmux list-windows -F '#{window_name}' | grep '^dual'

# 새로 생성 (--new이거나 없을 때)
mise run claude-dual
```
기존 dual이 있고 `--new`가 아니면 가장 최근 dual 윈도우를 재사용합니다.

### 2. Planner에게 명령 전달
dual 윈도우의 좌측 pane(planner)에 plan-ears 명령을 전송합니다:
```bash
DUAL_WIN=$(tmux list-windows -F '#{window_name}' | grep '^dual' | tail -1)
PLANNER_PANE=$(tmux list-panes -t "$DUAL_WIN" -F '#{pane_id}' | head -1)
tmux send-keys -t "$PLANNER_PANE" -l '/plan-ears "{기능 설명}"' && tmux send-keys -t "$PLANNER_PANE" Enter
```

### 3. 진행 모니터링
사용자에게 안내합니다:
- "Planner에게 명령을 전달했습니다"
- "Planner가 스펙 작성 후 자동으로 Executor에게 전달합니다"
- "Executor 완료 시 이 세션에 알림이 옵니다"
- "완료 알림 수신 후 /review-team으로 검증을 실행합니다"

### 4. 완료 후 검증
Executor가 완료하면 이 세션에 메시지가 도착합니다.
메시지를 수신하면 다음을 순차 실행합니다:
1. `specs-status`로 완료 확인
2. `git diff`로 변경사항 확인
3. 변경사항이 있으면 `/review-quick`으로 코드 리뷰 실행
4. 리뷰 결과와 함께 사용자에게 최종 보고

## 주의사항
- 듀얼 세션은 Leader와 동일한 디렉토리에서 열립니다
- Planner → Executor 전달은 planner-mode 규칙에 의해 자동 수행됩니다
- Executor → Leader 알림은 executor-mode 규칙에 의해 자동 수행됩니다
- Leader는 알림 수신 후 review-team을 수동 또는 자동으로 실행합니다
