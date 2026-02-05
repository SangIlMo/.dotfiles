# Debugging Workflow Rule (Insights-Based)

## 목적
블록체인/트랜잭션 이슈 디버깅과 Claude와의 효율적인 협업을 위한 가이드라인입니다.
Usage Insights 분석 결과를 기반으로 작성되었습니다.

---

## Blockchain/Transaction 디버깅 체크리스트

**트랜잭션/스텝 카운팅 이슈 디버깅 시 다음 패턴을 우선 확인합니다:**

| 확인 항목 | 설명 | 주요 파일 패턴 |
|-----------|------|----------------|
| **null requestId 이벤트** | 이벤트 핸들러에서 requestId가 null인 경우 처리 확인 | `*EventHandler.java` |
| **atomic increment 경쟁 조건** | `incrementCompletedTransactionsAtomic` 메서드의 동시성 이슈 | `*Service.java` |
| **이벤트 필터링 로직** | `DEPLOY_CONTRACT` 등 특정 트랜잭션 타입 필터링 확인 | `*Filter.java` |
| **스텝 건너뛰기 패턴** | Step N-1 → N+1 건너뛰기 (예: 7/9 → 9/9) 로그 확인 | 로그 분석 |

### 디버깅 체크리스트

1. [ ] `incrementCompletedTransactionsAtomic` 호출자 모두 확인
2. [ ] null requestId를 허용하는 코드 경로 추적
3. [ ] `DEPLOY_CONTRACT` 필터링 로직 검증
4. [ ] Step 전환 로그에서 N-1 → N+1 패턴 검색

### 로그 분석 명령어

```bash
# Step 진행 상황 추출 (예: 7/9 → 8/9 → 9/9)
grep -E "Step [0-9]+/[0-9]+" /tmp/e2e_test.log | head -50

# 트랜잭션 카운트 점프 확인
grep -E "(completedTransactions|incrementCompletedTransactions)" /tmp/e2e_test.log

# null requestId 이벤트 검색
grep -i "requestId.*null" /tmp/e2e_test.log
```

---

## Known Flaky Tests

**알려진 불안정한 테스트 목록:**

| 테스트 | 알려진 이슈 | 해결 방법 |
|--------|-------------|-----------|
| **E2E Step 4** | 타임아웃 발생 가능 (블록체인 네트워크 지연) | 타임아웃을 조사 대상 버그와 분리하여 처리 |
| **DeploymentApiE2ETest** | 간헐적 타임아웃 | 백그라운드 실행 + 로그 파일 분석 권장 |

**중요 원칙:**
- **E2E 테스트 타임아웃 시**: 원래 조사하던 버그 수정과 분리하여 별도 이슈로 기록
- **버그 수정 검증**: 타임아웃이 발생해도, 해당 Step 이전까지 로그 분석으로 수정 여부 확인 가능
- **타겟 테스트 우선**: 전체 E2E 대신 특정 Step만 검증하는 테스트 실행 권장

---

## Workflow Preferences

### 분석 중단 시 즉시 멈추기

사용자가 분석/테스트 실행 중 중단하면, **즉시 멈추고** 사용자가 원하는 구체적인 질문이 무엇인지 확인합니다.

```
❌ BAD: 사용자가 중단해도 계속 광범위한 조사 진행
✅ GOOD: 즉시 멈추고 "어떤 구체적인 부분을 확인해 드릴까요?" 질문
```

### 구체적인 가설로 시작하기

디버깅 세션은 광범위한 탐색보다 **구체적인 가설**로 시작하는 것이 효율적입니다.

```
❌ BAD: "왜 Z가 발생하는지 디버깅해줘"
✅ GOOD: "X가 Y를 유발한다고 생각해. 이 특정 경로만 확인해줘"
```

**효율적인 디버깅 프롬프트 예시:**

```
# 구체적인 가설 기반 요청
"incrementCompletedTransactionsAtomic가 어딘가에서 null requestId로
호출되고 있다고 생각해. null을 허용하는 특정 호출 지점을 찾아서
해당 코드 경로만 보여줘."

# 테스트 범위 제한 요청
"Step 8 트랜잭션 필터링만 검증하는 테스트만 실행해줘.
통과하면 수정된 것으로 기록해. 전체 E2E는 실행하지 마 -
Step 4에 알려진 타임아웃 이슈가 있어."
```

### 테스트 실패와 버그 수정 분리

테스트 타임아웃이나 관련 없는 실패가 발생해도, **원래 조사하던 버그 수정과 분리**하여 처리합니다.

| 상황 | 처리 방법 |
|------|-----------|
| E2E 타임아웃 발생 | 타임아웃 전 로그 분석으로 원래 버그 수정 여부 확인 |
| 다른 Step 실패 | 해당 Step 실패는 별도 이슈로 기록, 원래 버그 검증 계속 |
| 환경 문제 | 환경 이슈와 코드 버그 분리하여 각각 처리 |

### 세션 종료 시 체크포인트

디버깅 세션 종료 시 다음 정보를 기록하여 후속 세션에서 이어갈 수 있도록 합니다:

```markdown
## 조사 상태 체크포인트
- **조사 대상**: [버그/이슈 설명]
- **현재 가설**: [가장 유력한 원인]
- **확인한 내용**: [조사 완료 항목]
- **미확인 내용**: [아직 조사 필요 항목]
- **다음 단계**: [다음 세션에서 시작할 작업]
```

---

## 참고사항

- 이 rule은 Usage Insights 분석 결과를 기반으로 작성되었습니다
- 기존 orchestration.md, swarm-coordination.md와 함께 작동합니다
- 디버깅 효율성 향상을 위한 가이드라인입니다

---

**Last Updated**: 2026-02-05
**Version**: 1.0.0
**Source**: Claude Code Usage Insights Report
