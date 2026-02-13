# git-changes-summary — Branch Changes Overview

현재 브랜치에서 base 브랜치(기본값: main)와 비교하여 변경된 모든 파일을 보여주고 통계를 제공합니다.

## Usage

```bash
/git-changes-summary [BASE_BRANCH]
```

**기본값:** main 브랜치와 비교
**예시:**
```bash
/git-changes-summary              # main과 비교
/git-changes-summary develop      # develop과 비교
/git-changes-summary origin/main  # origin/main과 비교
```

## Output Example

```
📊 Git Branch Changes Summary
==============================

Current Branch: feat/add-auth
Base Branch: main
Total Changes: 5 file(s)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 src/auth/login.ts
   Lines added: +45, Lines removed: -8

📝 src/auth/user.model.ts
   Lines added: +23, Lines removed: -5

📝 src/auth/password.service.ts
   Lines added: +31, Lines removed: -12

📝 src/middleware/auth.middleware.ts
   Lines added: +18, Lines removed: -3

📝 tests/auth.test.ts
   Lines added: +67, Lines removed: -2

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Statistics
───────────────────────────────────────────────────────
Total additions:  +184
Total deletions:  -30
Files changed:    5

💡 Tip: Run 'git-changes-summary-detail' for file-by-file breakdown
```

## Two Modes

### 1️⃣ `/git-changes-summary` (Fast)
- 파일 목록 + 라인 통계 (빠름)
- 변경된 파일과 각 파일의 +/- 라인 수 표시
- 전체 추가/삭제 라인 합계

### 2️⃣ `/git-changes-summary-detail` (Detailed)
- 각 파일의 실제 diff 내용 표시
- AI 요약을 위한 전체 변경 내용 제공
- 더 자세한 분석이 필요할 때 사용

## Features

✅ **파일 목록** — 모든 변경 파일을 한눈에 표시
✅ **라인 통계** — 파일별 추가/제거 라인 수
✅ **전체 통계** — 전체 코드 변화량
✅ **빠른 실행** — 큰 브랜치도 빠르게 분석

## Related Skills

- `/review-quick` — 스테이징된 변경사항의 코드 리뷰
- `/review-team` — 팀 기반 종합 리뷰
- `/git-changes-summary-detail` — 파일별 상세 내용

## Notes

- Base branch 기본값은 `main`
- 커밋된 변경만 포함 (스테이징 안 된 변경 제외)
- 바이너리 파일도 포함 (통계만 표시)
- 새로 추가된 파일/삭제된 파일 모두 포함
