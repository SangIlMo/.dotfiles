# Agent Teams Coordination Rule (v4.0)

## 핵심: Agent Teams 생명주기
1. **분석**: 3개+ 독립 관점 & 결과 집계 필요 → Agent Teams
2. **팀 생성**: TeamCreate → TaskCreate x N
3. **실행**: Task(subagent_type, team_name, name, model) → teammate spawn
4. **결과 수신**: teammate가 SendMessage → Leader 자동 수신 (폴링 불필요)
5. **집계**: 통합 리포트 생성 → 사용자 제시
6. **정리**: shutdown_request → TeamDelete

---

## 단일 Sub-agent 위임 패턴

Agent Teams 외에도 모든 작업을 sub-agent로 위임 (Leader context 보호):

**Delegated Sequential**: Leader → Task(haiku:분석) → Task(sonnet:수정) → Task(haiku:테스트) → Leader(git)
**Single Delegation**: 단일 작업도 Task tool로 위임

---

## Teammate 모델 선택

| 역할 | model |
|------|-------|
| 코드 리뷰 (security/performance/architecture) | sonnet |
| 프레임워크 연구 | sonnet |
| 서비스 설계 | opus |
| 단순 수정/보일러플레이트 워커 | haiku |
| 기능 구현/테스트 생성 워커 | sonnet |

---

## 결과 포맷

리뷰어 findings: `{severity, category, file, line, description, recommendation, confidence}`
- confidence >= 80만 보고, critical은 즉시 수정 필요한 것만

연구원 evaluation: `{performance, dx, community, ecosystem}` (각 1-5점) + pros/cons/recommendation

---

## 주의사항
- 최대 5개 teammate 동시 실행
- 파일 충돌 방지: 동일 파일 편집하지 않도록 작업 분리
- 1팀 1세션, 정리는 Leader만 TeamDelete
- teammate 간 직접 대화 가능 (SendMessage)
