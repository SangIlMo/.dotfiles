---
name: dispatch
description: 분석 후 worktree에 plan을 넘기고 독립 개발 위임
user-invocable: true
argument: feature description
---

# Dispatch: Worktree-based Autonomous Development

## 워크플로우

1. `{argument}`로 요구사항 수신
2. Task(Explore)로 코드베이스 분석 위임
3. Task(Plan)으로 구현 계획 설계 위임
4. plan.md 작성 (아래 포맷)
5. worktree 생성
6. plan.md를 worktree에 복사
7. mise trust + tmux new-window로 claude 자동 실행
8. 완료 — 메인 claude는 다른 작업 가능

## 실행 단계

### Step 1: 코드베이스 분석
```
Task(subagent_type=Explore, model=haiku)
prompt: "{argument}와 관련된 코드베이스 구조, 패턴, 관련 파일을 분석하라"
```

### Step 2: 구현 계획 설계
```
Task(subagent_type=Plan, model=sonnet)
prompt: "분석 결과를 바탕으로 {argument} 구현 계획을 설계하라"
```

### Step 3: plan.md 작성
분석 + 설계 결과를 아래 포맷으로 작성:

```markdown
# Plan: {feature title}
- created: {timestamp}
- branch: {branch-name}
- base: {base-branch}

## Goal
{1-2문장 목표}

## Analysis
{코드베이스 분석 결과 요약}

## Implementation
### Files to create
- path/to/new/file.ts — 설명

### Files to modify
- path/to/existing.ts — 변경 내용

### Dependencies
- 필요한 패키지/도구

## Test Plan
- [ ] 테스트 항목 1
- [ ] 테스트 항목 2

## Acceptance Criteria
- [ ] 기준 1
- [ ] 기준 2

## Notes
{추가 컨텍스트, 제약사항}
```

### Step 4: Worktree 생성 + Claude 실행
```bash
# 브랜치명 생성
BRANCH="feat/$(echo "{argument}" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g' | cut -c1-40)"
WT_PATH=".claude/worktrees/$(basename $BRANCH)"

# worktree 생성
git worktree add "$WT_PATH" -b "$BRANCH"

# plan.md 복사
mkdir -p "$WT_PATH/.claude"
cp plan.md "$WT_PATH/.claude/plan.md"

# mise trust
mise trust "$WT_PATH"

# 브랜치 짧은 이름 (tmux window name용)
BRANCH_SHORT=$(basename "$BRANCH" | cut -c1-20)

# 절대경로 변환
WT_ABS="$(cd "$WT_PATH" && pwd -P)"

# tmux new-window로 claude 자동 실행
tmux new-window -c "$WT_ABS" -n "$BRANCH_SHORT" \
  "claude --dangerously-skip-permissions 'Read .claude/plan.md and implement the plan. After implementation: run tests, commit changes, push, and create a PR. Then wait for review.'"
```

## 완료 메시지
```
Dispatched to worktree: {WT_PATH}
Branch: {BRANCH}
tmux window: {BRANCH_SHORT}

worktree claude가 독립적으로 구현 → 테스트 → 커밋 → PR을 진행합니다.
tmux에서 해당 window로 이동하여 진행 상황을 확인하세요.
```

## 주의사항
- plan.md 작성 시 충분한 컨텍스트를 포함할 것 (worktree claude는 분석 결과를 모름)
- worktree claude는 완전히 독립적 — 메인 claude와 통신하지 않음
- 완료 후 worktree-dashboard(`/wd`)에서 확인 가능
