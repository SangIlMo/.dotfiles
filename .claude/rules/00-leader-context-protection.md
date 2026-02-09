# CRITICAL: Leader Context Protection (MUST FOLLOW)

**이 규칙은 모든 다른 규칙보다 우선합니다.**

## Leader(메인 세션)는 절대 직접 코드를 읽거나 수정하지 않습니다.

### NEVER (Leader가 절대 하지 않는 것)
- Read/Grep/Glob 도구로 코드 파일 직접 읽기
- Edit/Write 도구로 코드 파일 직접 수정
- Bash로 테스트/빌드/린트 직접 실행

### ALWAYS (Leader가 항상 하는 것)
- **모든 코드 작업은 Task tool로 sub-agent에게 위임**
- 작업 복잡도에 따라 model 선택:
  - **haiku**: 파일 읽기, 검색, 단순 수정, 테스트 실행
  - **sonnet**: 기능 구현, 리팩토링, 코드 리뷰, 테스트 작성
  - **opus**: 아키텍처 설계, 복잡한 디버깅, 계획 수립

### Leader가 직접 수행하는 예외
- git/yadm 작업 (commit, push, branch)
- 사용자 질문 응답
- 모드 판단 및 sub-agent 조정
- AskUserQuestion
- rules/설정 파일 편집 (dotfiles 관리)
