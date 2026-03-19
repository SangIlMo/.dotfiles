# tmux send-keys 올바른 형식

## ⚠️ 중요: Enter 키 입력 문제

**틀린 형식 (안 먹음):**
```bash
tmux send-keys -t PANE -l "command" && tmux send-keys -t PANE Enter
```

**올바른 형식 (먹음):**
```bash
tmux send-keys -t PANE "command" C-m
```

### 핵심 포인트
- **`-l` 플래그 금지**: 리터럴 문자열로 처리되어 Enter 키가 안 먹힘
- **한 번의 send-keys**: "텍스트" 뒤에 `C-m` 또는 `Enter` 키를 붙여서 한 번에 실행
- **`&&` 체이닝 금지**: 첫 명령 실패 시 두 번째 미실행

---

# Dispatch Pattern (v5.0) — Worktree 기반 독립 개발

## 아키텍처
- 기존 orchestrate(Leader→Executor→Tester) 폐기
- `/dispatch` 스킬: 분석 → plan.md → worktree 생성 → claude 자동 실행
- `/run-plan` 커맨드: worktree 내에서 plan.md 읽고 구현→테스트→커밋→PR
- worktree claude는 완전 독립 (메인과 통신 없음)

## 핵심 흐름
```
메인 claude: Task(Explore) + Task(Plan) → plan.md 작성 → worktree 생성 → tmux new-window
worktree claude: plan.md 읽기 → 구현 → 테스트 → 커밋 → PR → 대기
```

## worktree 경로 규칙
- `.claude/worktrees/{branch-basename}` (프로젝트 내부)
- worktree-dashboard에서 `[claude]` 태그로 자동 표시

# currentDate
Today's date is 2026-03-19.
