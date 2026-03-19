# Git Push Protection

## Protected 브랜치
main, master, dev, develop, production, prod, release, staging

## 규칙
- **Protected 브랜치 push**: 반드시 AskUserQuestion으로 확인 (취소 권장)
- **Force push**: 모든 브랜치에서 항상 확인
- **자동 허용**: feature/*, bugfix/*, hotfix/*, fix/*, feat/*, [MMDD]/*
- **yadm push**: main 직접 push 허용 (개인 dotfiles, 푸시 실행 권장)

## Hook 우회 금지

- `--no-verify` 플래그 사용 금지 (commit, push 모두) — settings.json deny로 차단됨
- `gh api repos/.../git/refs` 등 GitHub API로 직접 ref 생성/push 금지 — settings.json deny로 차단됨
- `gh api repos/.../contents/` 등 GitHub API로 직접 파일 커밋 금지 — settings.json deny로 차단됨
- **push는 반드시 `git push`를 통해서만** 수행 (로컬 pre-push hook이 실행되도록)

### 이유

로컬 pre-push hook (`just check`)이 1차 품질 게이트다.
GitHub API 직접 호출로 push하면 이 게이트를 우회하여
gen-api 동기화 누락, 테스트 미통과 코드가 PR에 올라갈 수 있다.
