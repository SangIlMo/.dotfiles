# Auto Commit After Tests

## 규칙
테스트 통과 + 변경사항 존재 → AskUserQuestion으로 커밋 여부 확인

## 조건
- **커밋 확인**: exit code 0 + git status에 변경 있음
- **건너뛰기**: 테스트 실패, 변경 없음, "커밋하지 마" 명시

## 커밋 메시지
- Conventional Commits 형식 (feat/fix/test/refactor/docs/perf)
- 민감 파일 자동 제외 (.env, *.key, *.pem, credentials)
- Push는 별도 (git-push-protection에 위임)
