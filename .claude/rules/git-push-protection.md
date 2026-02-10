# Git Push Protection

## Protected 브랜치
main, master, dev, develop, production, prod, release, staging

## 규칙
- **Protected 브랜치 push**: 반드시 AskUserQuestion으로 확인 (취소 권장)
- **Force push**: 모든 브랜치에서 항상 확인
- **자동 허용**: feature/*, bugfix/*, hotfix/*, fix/*, feat/*, [MMDD]/*
- **yadm push**: main 직접 push 허용 (개인 dotfiles, 푸시 실행 권장)
