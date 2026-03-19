# Run Plan

`.claude/plan.md`를 읽고 구현을 실행하라.

## 워크플로우

1. `.claude/plan.md` 파일을 읽어라
2. Plan의 Goal과 Implementation 섹션에 따라 구현하라
3. 구현 완료 후 Test Plan에 명시된 테스트를 실행하라
4. 테스트가 통과하면:
   - Conventional Commits 형식으로 커밋 (feat/fix/test/refactor 등)
   - 현재 브랜치를 push
   - `gh pr create`로 PR 생성 (plan의 Goal을 PR 설명에 포함)
5. 테스트가 실패하면:
   - 실패 원인을 분석하고 수정
   - 다시 테스트 실행 (최대 3회 반복)
   - 3회 실패 시 현재 상태를 커밋하고 PR에 WIP 표시
6. 완료 메시지 출력 후 대기

## PR 생성 포맷
```bash
gh pr create --title "{conventional commit style title}" --body "$(cat <<'EOF'
## Summary
{plan의 Goal}

## Changes
{구현된 변경사항 요약}

## Test
{테스트 실행 결과}

---
Dispatched via `/dispatch`
EOF
)"
```

## 주의사항
- `.claude/plan.md`가 없으면 에러 메시지 출력 후 중단
- Acceptance Criteria를 모두 충족하는지 확인
- 민감 파일(.env, *.key, credentials) 커밋 제외
