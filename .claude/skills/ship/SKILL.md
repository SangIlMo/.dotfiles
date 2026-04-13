---
name: ship
description: commit, push, PR을 차례대로 진행. Use when you want to ship your changes end-to-end.
version: 1.0.0
user-invocable: true
---

# Ship — Commit, Push, PR 순차 실행

현재 브랜치의 변경사항을 commit → push → PR 생성까지 한 번에 진행합니다.

## Workflow

### 1. Git 상태 확인

```bash
git rev-parse --git-dir > /dev/null 2>&1
```
git repo가 아니면 중단.

### 2. 현재 브랜치 확인

```bash
git branch --show-current
```
- main/master/dev/develop/production/prod/release/staging 브랜치면 경고 후 중단: "Protected 브랜치에서는 ship할 수 없습니다."

### 3. Commit (변경사항이 있을 때만)

1. `git status`로 변경사항 확인
2. `git diff`와 `git diff --staged`로 변경 내용 파악
3. `git log -5 --oneline`으로 최근 커밋 스타일 확인
4. 변경사항이 있으면:
   - staged + unstaged 모든 변경사항을 분석하여 커밋 메시지 작성
   - Conventional Commits 형식 (feat/fix/test/refactor/docs/perf)
   - 민감 파일 제외 (.env, *.key, *.pem, credentials)
   - 관련 파일을 `git add`로 staging
   - 커밋 실행 (Co-Authored-By 포함)
5. 변경사항이 없으면 기존 커밋이 push 안 된 것인지 확인 후 진행

### 4. Push

```bash
git push -u origin $(git branch --show-current)
```
- remote에 브랜치가 없으면 자동 생성
- push 실패 시 원인 안내 (behind remote 등)

### 5. PR 생성

1. 이미 PR이 있는지 확인:
   ```bash
   gh pr view --json number,url 2>/dev/null
   ```
2. PR이 이미 있으면 URL 표시 후 종료
3. PR이 없으면:
   - `git log main..HEAD --oneline`과 `git diff main...HEAD`로 전체 변경 분석
   - PR 제목 (70자 이내) + 본문 작성
   - `gh pr create` 실행:
     ```bash
     gh pr create --title "제목" --body "$(cat <<'EOF'
     ## Summary
     - 변경사항 요약

     ## Test plan
     - [ ] 테스트 항목

     🤖 Generated with [Claude Code](https://claude.com/claude-code)
     EOF
     )"
     ```

### 6. 완료 요약

PR URL을 표시합니다.

## Important Notes

- Protected 브랜치 (main, master 등)에서는 실행 불가
- 각 단계 실패 시 해당 단계에서 중단하고 원인 안내
- commit이 없고 push할 것도 없으면 "ship할 변경사항이 없습니다" 안내
