# Debugging Workflow

## 원칙
- **구체적 가설로 시작** — 광범위 탐색 금지
- **중단 시 즉시 멈추기** — 사용자 의도 확인
- **테스트 실패와 버그 수정 분리** — 타임아웃은 별도 이슈

## Blockchain/Transaction 체크리스트
- null requestId 이벤트 처리 (`*EventHandler.java`)
- atomic increment 경쟁 조건 (`incrementCompletedTransactionsAtomic`)
- 이벤트 필터링 로직 (`DEPLOY_CONTRACT`)
- Step N-1 → N+1 건너뛰기 패턴

## 세션 종료 시 체크포인트 기록
조사 대상, 현재 가설, 확인/미확인 내용, 다음 단계
