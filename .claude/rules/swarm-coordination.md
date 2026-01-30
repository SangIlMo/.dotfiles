# Swarm Coordination Rule

## 목적
여러 전문 에이전트를 조정하여 독립적인 다중 분석/리뷰 작업을 병렬로 수행하고 결과를 집계합니다.

---

## Swarm 생명주기

### 1. 분석 (Analysis)
Leader가 사용자 요청을 분석하여 다음을 결정:
- 작업이 Internal Swarms 모드에 적합한가?
- 몇 개의 전문 에이전트가 필요한가?
- 각 에이전트의 역할은 무엇인가?

**트리거 조건**:
- 3개 이상의 독립적인 관점/작업
- 결과 집계가 필요함
- 병렬 실행 가능 (의존성 없음)

### 2. 생성 (Creation)
각 전문 작업에 대해 Task 생성:
```pseudo
for each perspective in [security, performance, architecture]:
    TaskCreate(
        subject: f"{perspective} review",
        description: "상세 작업 설명",
        activeForm: f"Reviewing {perspective}"
    )
```

### 3. 실행 (Execution)
병렬로 전문 에이전트 실행:
```pseudo
for each task in tasks:
    Task(
        subagent_type: "general-purpose",
        prompt: agentTemplate(task),
        run_in_background: true
    )
```

**에이전트 책임**:
- TaskGet으로 할당된 작업 읽기
- 전문 분야 분석 수행
- `~/.claude/orchestration/results/{agent}-{task-id}.json`에 결과 작성
- TaskUpdate로 completed 상태 변경

### 4. 집계 (Aggregation)
Leader가 모든 결과 수집 및 통합:
```pseudo
while not all_tasks_completed():
    TaskList()
    sleep(1)

results = []
for task in completed_tasks:
    result = read(f"~/.claude/orchestration/results/{task.owner}-{task.id}.json")
    results.append(result)

aggregate_report = combine_findings(results)
```

### 5. 조치 (Action)
통합 리포트를 사용자에게 제시하고 후속 작업 수행:
- Critical/Important 이슈 우선순위 표시
- 사용자에게 수정 여부 확인
- 필요 시 Sequential 모드로 전환하여 이슈 수정

---

## 에이전트 타입

### 리뷰어 (Reviewer)
**목적**: 코드/설계를 특정 관점에서 분석

**전문 분야**:
- **security-sentinel**: 보안 취약점 (OWASP, 인증/인가, injection)
- **performance-oracle**: 성능 문제 (N+1 쿼리, 알고리즘 복잡도, 메모리)
- **architecture-strategist**: 아키텍처 품질 (SOLID, 결합도, 패턴)
- **test-guardian**: 테스트 커버리지 및 품질

**출력 포맷**:
```json
{
  "agent": "security-sentinel",
  "task_id": "task-1",
  "findings": [
    {
      "severity": "critical",
      "category": "SQL Injection",
      "file": "src/auth.ts",
      "line": 42,
      "description": "User input directly concatenated into SQL query",
      "recommendation": "Use parameterized queries or ORM",
      "confidence": 95
    }
  ],
  "summary": "Found 2 critical, 5 important security issues",
  "confidence": 90
}
```

### 연구원 (Researcher)
**목적**: 프레임워크/라이브러리/기술 조사 및 비교

**전문 분야**:
- **framework-researcher**: 프레임워크 평가 및 비교
- **library-analyst**: 라이브러리 선정 및 추천
- **tech-scout**: 새로운 기술 트렌드 조사

**평가 기준**:
- 성능 (벤치마크, 번들 크기)
- 개발자 경험 (DX, 러닝 커브, 문서)
- 커뮤니티 (활성도, 유지보수, GitHub stars)
- 생태계 (플러그인, 통합, 호환성)

**출력 포맷**:
```json
{
  "agent": "framework-researcher",
  "task_id": "task-2",
  "subject": "Apollo Server",
  "evaluation": {
    "performance": {"score": 3, "notes": "Moderate performance"},
    "dx": {"score": 5, "notes": "Excellent TypeScript support"},
    "community": {"score": 5, "notes": "Very active, 13k stars"},
    "ecosystem": {"score": 5, "notes": "Rich plugin ecosystem"},
    "bundle_size": "Large (150kb)"
  },
  "pros": ["Mature", "Great DX", "Wide adoption"],
  "cons": ["Large bundle", "Slower than alternatives"],
  "recommendation": "Use if DX is priority over performance",
  "confidence": 85
}
```

### 생성기 (Generator)
**목적**: 대규모 코드/테스트/문서 생성

**전문 분야**:
- **test-generator**: 테스트 케이스 대량 생성
- **service-architect**: 마이크로서비스 설계 및 생성
- **api-designer**: REST/GraphQL API 스키마 설계

**출력 포맷**:
```json
{
  "agent": "test-generator",
  "task_id": "task-3",
  "generated_files": [
    "tests/auth.test.ts",
    "tests/users.test.ts"
  ],
  "summary": "Generated 45 test cases covering 8 modules",
  "coverage_estimate": "85%",
  "confidence": 80
}
```

---

## 조정 패턴 (Coordination Patterns)

### Pattern 1: 병렬 리뷰 (Parallel Review)
**사용 사례**: 코드/PR을 여러 관점에서 동시 리뷰

**워크플로우**:
```
User: "PR #123을 보안, 성능, 아키텍처 관점에서 리뷰해줘"

Leader:
  1. TaskCreate: security-sentinel
  2. TaskCreate: performance-oracle
  3. TaskCreate: architecture-strategist
  4. 병렬 실행
  5. 결과 집계
  6. 통합 리포트 생성

출력:
  📋 종합 리뷰 결과:

  🔴 Critical Issues (3):
  - [SQL Injection] src/auth.ts:42 (보안)
  - [N+1 Query] src/users.ts:78 (성능)
  - [God Object] src/service.ts:15 (아키텍처)

  🟡 Important Issues (8):
  - [상세 목록...]

  수정을 진행할까요?
```

### Pattern 2: 병렬 연구 → 의사결정 (Parallel Research)
**사용 사례**: 여러 옵션 조사 후 최적 선택

**워크플로우**:
```
User: "GraphQL 서버 프레임워크 추천해줘. Apollo, Mercurius, Yoga 비교"

Leader:
  1. TaskCreate: Apollo Server 조사
  2. TaskCreate: Mercurius 조사
  3. TaskCreate: GraphQL Yoga 조사
  4. 병렬 실행
  5. 결과 비교
  6. 추천 및 근거 제시

출력:
  📊 프레임워크 비교:

  | 항목 | Apollo | Mercurius | Yoga |
  |------|--------|-----------|------|
  | 성능 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
  | DX | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
  | 번들 크기 | 큼 | 작음 | 중간 |

  💡 추천: Mercurius (권장)
  이유: Fastify 기반 고성능, 작은 번들, 타입스크립트 지원

  Mercurius로 진행할까요?
```

### Pattern 3: 자기조직화 워커 (Self-Organizing Workers)
**사용 사례**: 대규모 작업을 자동으로 분할 및 병렬 처리

**워크플로우**:
```
User: "모든 API 엔드포인트에 대한 테스트 생성해줘"

Leader:
  1. 엔드포인트 목록 수집 (10개)
  2. 3-4개씩 묶어서 TaskCreate (3개 태스크)
  3. 각 워커가 할당된 엔드포인트 테스트 생성
  4. 결과 집계
  5. 전체 테스트 스위트 통합

출력:
  ✅ 테스트 생성 완료:
  - Worker 1: GET /users, POST /users, DELETE /users (15 tests)
  - Worker 2: GET /posts, POST /posts, PUT /posts (12 tests)
  - Worker 3: GET /auth, POST /auth/login, POST /auth/logout (10 tests)

  총 37개 테스트 생성, 예상 커버리지: 92%
```

---

## 메시지 포맷

### Task Description 템플릿

리뷰어 작업:
```
당신은 {전문 분야} 전문가입니다.

## 작업
다음 파일들을 {관점}에서 리뷰하세요:
{파일 목록}

## 출력 위치
~/.claude/orchestration/results/{agent-name}-{task-id}.json

## 출력 포맷
{
  "agent": "{agent-name}",
  "task_id": "{task-id}",
  "findings": [
    {
      "severity": "critical|important|minor",
      "category": "...",
      "file": "...",
      "line": 123,
      "description": "...",
      "recommendation": "...",
      "confidence": 0-100
    }
  ],
  "summary": "...",
  "confidence": 0-100
}

## 중요
- Confidence >= 80인 이슈만 보고
- Critical은 즉시 수정 필요한 것만
- 파일이 없거나 읽기 실패 시 에러 기록
```

연구원 작업:
```
당신은 기술 연구 전문가입니다.

## 작업
{프레임워크/라이브러리} 를 다음 기준으로 평가하세요:
- 성능 (벤치마크, 번들 크기)
- 개발자 경험 (DX, 문서, 타입스크립트)
- 커뮤니티 (활성도, GitHub stars, 유지보수)
- 생태계 (플러그인, 통합)

## 출력 위치
~/.claude/orchestration/results/{agent-name}-{task-id}.json

## 출력 포맷
{
  "agent": "{agent-name}",
  "task_id": "{task-id}",
  "subject": "{평가 대상}",
  "evaluation": {
    "performance": {"score": 1-5, "notes": "..."},
    "dx": {"score": 1-5, "notes": "..."},
    "community": {"score": 1-5, "notes": "..."},
    "ecosystem": {"score": 1-5, "notes": "..."}
  },
  "pros": ["...", "..."],
  "cons": ["...", "..."],
  "recommendation": "...",
  "confidence": 0-100
}
```

### 결과 집계 포맷

리뷰 결과 집계:
```
📋 종합 {리뷰 타입} 결과

🔴 Critical Issues ({count}):
{for each critical finding:}
- [{category}] {file}:{line} ({agent})
  {description}

🟡 Important Issues ({count}):
{for each important finding:}
- [{category}] {file}:{line} ({agent})
  {description}

📊 분석 요약:
- 보안: {critical} critical, {important} important
- 성능: {critical} critical, {important} important
- 아키텍처: {critical} critical, {important} important

다음 단계:
1. Critical 이슈 우선 수정
2. Important 이슈 검토 및 수정
3. 테스트 실행 및 검증

Critical 이슈를 수정할까요?
```

연구 결과 집계:
```
📊 {주제} 비교 분석

| 항목 | {Option 1} | {Option 2} | {Option 3} |
|------|-----------|-----------|-----------|
| 성능 | {stars} | {stars} | {stars} |
| DX | {stars} | {stars} | {stars} |
| 커뮤니티 | {stars} | {stars} | {stars} |
| 번들 크기 | {size} | {size} | {size} |

💡 추천: {선택} (권장)
이유:
- {이유 1}
- {이유 2}
- {이유 3}

고려사항:
- {trade-off 1}
- {trade-off 2}

{선택}으로 진행할까요?
```

---

## 기존 규칙 통합

### auto-commit-after-tests.md 통합
Swarm 실행 후 수정 → 테스트 → 자동 커밋 제안

**워크플로우**:
```
1. Swarm 리뷰 완료 → Critical 이슈 발견
2. 사용자 "수정해줘" 선택
3. Sequential 모드로 이슈 수정
4. 테스트 실행 (자동)
5. 테스트 통과 → auto-commit-after-tests 트리거
6. 커밋 메시지 제안 (Swarm 리뷰 결과 반영)
```

### git-push-protection.md 통합
커밋 후 push 시 protected 브랜치 확인

**워크플로우**:
```
1. Swarm 리뷰 → 수정 → 커밋
2. 사용자 "푸시해줘"
3. git-push-protection 확인
4. Protected 브랜치면 경고 → Feature 브랜치 권장
5. Feature 브랜치로 push → PR 생성
```

### orchestration.md 통합
Swarm 완료 후 수정 작업은 적절한 모드 선택

**판단 로직**:
```
if swarm_findings.critical_count <= 2:
    mode = Sequential  # 소규모 수정
elif swarm_findings.files_affected >= 5:
    mode = Internal Swarms  # 대규모 수정 (병렬 처리)
else:
    mode = Sequential  # 기본값
```

---

## 에러 처리

### Agent 실행 실패
```json
{
  "agent": "security-sentinel",
  "task_id": "task-1",
  "status": "error",
  "error": "Failed to read file: src/auth.ts (permission denied)",
  "partial_findings": [...],
  "confidence": 0
}
```

**Leader 조치**:
- 부분 결과 사용 (가능한 경우)
- 사용자에게 에러 보고
- 나머지 agent 결과는 정상 집계

### Timeout
각 agent는 10분 타임아웃:
```
if agent_runtime > 10 minutes:
    TaskUpdate(task_id, status: "timeout")
    warn_user("Agent timeout, using partial results")
```

### 결과 파일 없음
```pseudo
if not exists(result_file):
    log_error(f"Agent {agent} did not produce results")
    continue  # 다음 결과 처리
```

---

## 성능 최적화

### 병렬 실행 제한
최대 5개 agent 동시 실행:
```pseudo
MAX_CONCURRENT_AGENTS = 5

if agent_count > MAX_CONCURRENT_AGENTS:
    # 우선순위 높은 것부터 실행
    run_in_batches(agents, batch_size=5)
```

### 결과 폴링 간격
```pseudo
POLL_INTERVAL = 2  # seconds

while not all_completed():
    TaskList()
    sleep(POLL_INTERVAL)
```

### 조기 종료
Critical 이슈 발견 시 조기 보고 옵션:
```pseudo
if any_agent_found_critical() and user_preference_early_report:
    report_immediate_findings()
    continue_other_agents_in_background()
```

---

## 사용 예시

### 예시 1: 다각도 PR 리뷰
```
User: "PR #456을 보안, 성능, 테스트 관점에서 종합 리뷰해줘"

Claude:
  📊 작업 분석:
  - 작업 유형: 다각도 코드 리뷰
  - 관점: 3개 (보안, 성능, 테스트)

  🎯 권장 모드: Internal Swarms
  이유: 독립적인 3개 관점, 결과 집계 필요

  진행할까요?

User: "네"

Claude:
  [TaskCreate: Security review]
  [TaskCreate: Performance review]
  [TaskCreate: Test coverage review]

  [3개 agent 병렬 실행...]

  📋 종합 리뷰 결과:

  🔴 Critical Issues (2):
  - [SQL Injection] src/db/users.ts:45 (보안)
    User input in SQL query without sanitization

  - [N+1 Query] src/api/posts.ts:123 (성능)
    Loading comments in loop, use JOIN or eager loading

  🟡 Important Issues (6):
  - [Weak Password] src/auth/validate.ts:12 (보안)
  - [Missing Index] src/db/schema.ts:34 (성능)
  - [Low Coverage] src/utils/format.ts (테스트)
  - [상세 목록 생략...]

  📊 분석 요약:
  - 보안: 1 critical, 2 important
  - 성능: 1 critical, 3 important
  - 테스트: 0 critical, 1 important

  Critical 이슈를 수정할까요?

User: "네, 수정해줘"

Claude:
  [Sequential 모드로 전환]
  [SQL Injection 수정...]
  [N+1 Query 수정...]
  [테스트 실행]

  ✅ Critical 이슈 수정 완료

  [auto-commit-after-tests 트리거]
  테스트가 모두 통과했습니다. 변경사항을 커밋하시겠습니까?
```

### 예시 2: 프레임워크 비교 연구
```
User: "인증 라이브러리를 선택해야 해. Passport, NextAuth, Lucia 비교해줘"

Claude:
  📊 작업 분석:
  - 작업 유형: 병렬 연구
  - 대상: 3개 라이브러리

  🎯 권장 모드: Internal Swarms
  이유: 독립적인 3개 조사, 비교 분석 필요

  진행할까요?

User: "응"

Claude:
  [TaskCreate: Passport.js 조사]
  [TaskCreate: NextAuth 조사]
  [TaskCreate: Lucia 조사]

  [3개 researcher 병렬 실행...]

  📊 인증 라이브러리 비교:

  | 항목 | Passport | NextAuth | Lucia |
  |------|----------|----------|-------|
  | 성능 | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
  | DX | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
  | 커뮤니티 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
  | 번들 크기 | 중간 | 큼 | 작음 |
  | 프레임워크 | Any | Next.js | Any |

  상세 비교:

  **Passport.js** (전통적 선택)
  ✅ Pros: 매우 성숙함, 500+ 전략, 대규모 커뮤니티
  ❌ Cons: 구식 API, 콜백 기반, TypeScript 지원 약함

  **NextAuth** (Next.js 최적화)
  ✅ Pros: Next.js 네이티브, 훌륭한 DX, 다양한 provider
  ❌ Cons: Next.js 전용, 큰 번들

  **Lucia** (현대적 선택)
  ✅ Pros: 작고 빠름, 타입 세이프, 프레임워크 독립적
  ❌ Cons: 신규 라이브러리 (상대적으로 작은 커뮤니티)

  💡 추천: NextAuth (권장)
  이유:
  - Next.js 프로젝트에 최적
  - 훌륭한 문서 및 DX
  - 주요 provider 모두 지원 (Google, GitHub, etc.)

  고려사항:
  - 다른 프레임워크 사용 시 Lucia 고려
  - 번들 크기가 critical하면 Lucia 선택

  NextAuth로 진행할까요?
```

---

## 구현 체크리스트

Leader (Main Session):
- [ ] 작업 분석 → Internal Swarms 조건 체크
- [ ] 각 관점/작업에 대해 TaskCreate
- [ ] 전문 agent 템플릿으로 Task tool 실행 (background)
- [ ] TaskList로 완료 상태 폴링
- [ ] 모든 완료 시 results/ 디렉토리 읽기
- [ ] 결과 집계 및 통합 리포트 생성
- [ ] 사용자에게 제시 및 후속 작업 확인

Agent (Subagent):
- [ ] TaskGet으로 할당된 작업 읽기
- [ ] 전문 분야 분석 수행
- [ ] 결과를 `~/.claude/orchestration/results/{agent}-{task-id}.json`에 작성
- [ ] TaskUpdate로 completed 상태 변경
- [ ] 에러 발생 시 에러 정보 기록

---

## 주의사항

1. **Confidence 필터링**: 모든 agent는 confidence >= 80인 이슈만 보고
2. **False Positive 최소화**: Critical은 즉시 수정 필요한 것만 표시
3. **파일 시스템 동기화**: 결과 파일 쓰기 후 충분한 시간 대기 (최소 100ms)
4. **에러 허용성**: 일부 agent 실패해도 나머지 결과 활용
5. **사용자 의도 존중**: 명시적으로 특정 관점만 요청하면 해당 agent만 실행

---

## 마무리

이 rule은 orchestration.md의 Mode 4로 작동하며:
- 다각도 코드 리뷰 지원
- 병렬 연구 및 의사결정 가속화
- 대규모 생성 작업 병렬화
- 기존 auto-commit, git-push-protection과 완벽히 통합

Native TeammateTool 없이도 Task system + Subagents + Shared Storage로 95% 동등한 기능 제공합니다.
