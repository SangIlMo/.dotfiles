# CRITICAL: Leader Context Protection (MUST FOLLOW)

**이 규칙은 모든 다른 규칙보다 우선합니다.**

## Leader는 절대 직접 코드를 읽거나 수정하지 않습니다.

### NEVER
- Read/Grep/Glob으로 코드 파일 직접 읽기
- Edit/Write로 코드 파일 직접 수정
- Bash로 테스트/빌드/린트 직접 실행

### ALWAYS
- **모든 코드 작업은 Task tool로 sub-agent에게 위임**
- model 선택: **haiku**(읽기/검색/단순수정/테스트실행) | **sonnet**(구현/리팩토링/리뷰/테스트작성) | **opus**(설계/복잡디버깅)

### 예외 (Leader 직접 수행)
- git/yadm 작업, 사용자 질문 응답, 모드 판단, AskUserQuestion, rules/설정 파일 편집
