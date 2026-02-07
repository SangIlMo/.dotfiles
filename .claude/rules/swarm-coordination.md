# Agent Teams Coordination Rule

## 목적
네이티브 Agent Teams 기능을 활용하여 여러 전문 에이전트(teammates)를 조정하고, 독립적인 다중 분석/리뷰 작업을 병렬로 수행하며 결과를 집계합니다.

---

## Agent Teams 생명주기

### 1. 분석 (Analysis)
Leader가 사용자 요청을 분석하여 다음을 결정:
- 작업이 Agent Teams 모드에 적합한가?
- 몇 개의 전문 teammate가 필요한가?
- 각 teammate의 역할은 무엇인가?

**트리거 조건 (자동 감지)**:

**핵심 조건 (모두 충족 필요)**:
- 3개 이상의 독립적인 관점/작업
- 결과 집계가 필요함
- 병렬 실행 가능 (의존성 없음)

**자동 Agent Teams 선택 키워드**:

| 패턴 | 키워드/표현 | 예시 요청 |
|------|-------------|-----------|
| **다각도 분석** | "보안, 성능, 아키텍처", "여러 측면" | "현재 시스템을 보안, 성능, 아키텍처 측면에서 분석해줘" |
| **종합 리뷰** | "종합적으로", "다각도로", "전방위" | "인증 시스템을 종합적으로 리뷰해줘" |
| **3개 이상 비교** | "A, B, C 비교", "옵션들 비교" | "GraphQL, REST, gRPC를 비교해줘" |
| **대규모 생성** | "모든 ... 테스트", "전체 ... 생성" | "모든 API 엔드포인트에 테스트 생성해줘" |
| **다중 평가** | "평가", "검토", "분석" + 3개 이상 대상 | "3개 라이브러리를 평가해줘" |

**자동 감지 패턴**:
1. 쉼표로 구분된 3개 이상의 관점/대상
2. "종합", "다각도", "전방위" 등의 포괄적 키워드
3. 명시적으로 N개(3+) 비교/분석 요청
4. 대규모 작업 키워드 ("모든", "전체") + 생성/테스트

**orchestration.md 연계**:
- orchestration.md에서 Agent Teams 모드가 선택되면 이 rule 적용
- 자동 트리거 조건은 orchestration.md와 동기화됨

### 2. 팀 생성 (Team Creation)
TeamCreate로 팀을 생성하고, 각 역할에 맞는 teammate를 spawn:
```pseudo
TeamCreate(
    team_name: "review-team",
    description: "다각도 코드 리뷰"
)

for each perspective in [security, performance, architecture]:
    TaskCreate(
        subject: f"{perspective} review",
        description: "상세 작업 설명",
        activeForm: f"Reviewing {perspective}"
    )
```

### 3. Teammate 실행 (Execution)
Task tool로 전문 teammate를 spawn하여 팀에 합류:
```pseudo
for each task in tasks:
    Task(
        subagent_type: "general-purpose",  // 또는 커스텀 에이전트
        team_name: "review-team",
        name: f"{perspective}-reviewer",
        prompt: teammatePrompt(task),
        mode: "plan"  // 복잡한 작업 시 plan approval 요구
    )
```

**Teammate 책임**:
- TaskGet으로 할당된 작업 읽기
- 전문 분야 분석 수행
- SendMessage로 Leader에게 결과 전송
- TaskUpdate로 completed 상태 변경

### 4. 자동 집계 (Automatic Aggregation)
Leader가 teammate들의 메시지를 **자동으로 수신**하여 통합:
```pseudo
// 메시지는 자동 전달됨 (폴링 불필요)
// teammate가 SendMessage로 결과를 보내면 Leader에게 즉시 전달
// 모든 teammate 완료 시 (TaskList로 확인) 통합 리포트 생성

aggregate_report = combine_findings(received_messages)
```

### 5. 조치 (Action)
통합 리포트를 사용자에게 제시하고 후속 작업 수행:
- Critical/Important 이슈 우선순위 표시
- 사용자에게 수정 여부 확인
- 필요 시 teammate에게 수정 작업 위임 또는 Sequential 모드 전환

### 6. 정리 (Cleanup)
작업 완료 후 팀 정리:
```pseudo
// 각 teammate에게 shutdown 요청
for each teammate in team:
    SendMessage(
        type: "shutdown_request",
        recipient: teammate.name,
        content: "작업 완료, 종료합니다"
    )

// 모든 teammate 종료 후 팀 삭제
TeamDelete()
```

---

## 디스플레이 모드

**tmux 분할 패널 모드** (설정됨):
- 각 teammate가 별도 tmux 패널에서 실행
- 모든 teammate의 출력을 동시에 확인 가능
- 패널 클릭으로 특정 teammate와 직접 대화 가능

**대안 모드**:
- `in-process`: 단일 터미널 내에서 실행 (Shift+Up/Down으로 전환)
- `auto`: tmux 세션 내면 split, 아니면 in-process (기본값)

---

## 에이전트 타입

### 리뷰어 (Reviewer)
**목적**: 코드/설계를 특정 관점에서 분석

**전문 분야** (`~/.claude/agents/`에 정의):
- **security-sentinel**: 보안 취약점 (OWASP, 인증/인가, injection)
- **performance-oracle**: 성능 문제 (N+1 쿼리, 알고리즘 복잡도, 메모리)
- **architecture-strategist**: 아키텍처 품질 (SOLID, 결합도, 패턴)

**결과 메시지 포맷** (SendMessage로 Leader에게 전송):
```json
{
  "agent": "security-sentinel",
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

**평가 기준**:
- 성능 (벤치마크, 번들 크기)
- 개발자 경험 (DX, 러닝 커브, 문서)
- 커뮤니티 (활성도, 유지보수, GitHub stars)
- 생태계 (플러그인, 통합, 호환성)

**결과 메시지 포맷**:
```json
{
  "agent": "framework-researcher",
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

### 설계자 (Architect)
**목적**: 서비스/시스템 설계

**전문 분야**:
- **service-architect**: 마이크로서비스 설계 및 API 설계

---

## 통신 패턴 (Communication Patterns)

### Leader ↔ Teammate 통신

**Leader → Teammate** (작업 할당):
```pseudo
SendMessage(
    type: "message",
    recipient: "security-reviewer",
    content: "src/auth/ 디렉토리의 보안 리뷰를 진행해주세요. JWT 토큰 처리와 세션 관리에 집중해주세요.",
    summary: "보안 리뷰 작업 할당"
)
```

**Teammate → Leader** (결과 보고):
```pseudo
SendMessage(
    type: "message",
    recipient: "team-lead",
    content: JSON.stringify(findings),
    summary: "보안 리뷰 완료: 2 critical, 3 important"
)
```

**Teammate ↔ Teammate** (팀원 간 직접 대화):
```pseudo
// security-reviewer가 performance-reviewer에게 직접 메시지
SendMessage(
    type: "message",
    recipient: "performance-reviewer",
    content: "src/auth.ts:42의 쿼리 보안 이슈가 성능에도 영향을 미칠 수 있습니다. 확인 부탁드립니다.",
    summary: "보안-성능 교차 이슈 발견"
)
```

### Broadcast (주의: 비용 높음)
모든 teammate에게 동시 전송. 긴급 상황에서만 사용:
```pseudo
SendMessage(
    type: "broadcast",
    content: "Critical blocking issue 발견. 모든 리뷰 일시 중단.",
    summary: "긴급 중단 요청"
)
```

### 자동 메시지 전달
- Teammate가 메시지를 보내면 **자동으로 수신자에게 전달** (폴링 불필요)
- Teammate가 idle 상태가 되면 Leader에게 **자동 알림**
- idle 알림에는 teammate 간 DM 요약이 포함됨

---

## 조정 패턴 (Coordination Patterns)

### Pattern 1: 병렬 리뷰 (Parallel Review)
**사용 사례**: 코드/PR을 여러 관점에서 동시 리뷰

**워크플로우**:
```
User: "PR #123을 보안, 성능, 아키텍처 관점에서 리뷰해줘"

Leader:
  1. TeamCreate: "pr-review-team"
  2. TaskCreate x 3: security, performance, architecture
  3. Task tool로 3개 teammate spawn (team_name 지정)
  4. 각 teammate가 독립적으로 리뷰 수행
  5. Teammate들이 SendMessage로 결과 전송 (자동 수신)
  6. Leader가 통합 리포트 생성
  7. Teammate shutdown → TeamDelete

출력:
  📋 종합 리뷰 결과:

  🔴 Critical Issues (3):
  - [SQL Injection] src/auth.ts:42 (security-reviewer)
  - [N+1 Query] src/users.ts:78 (performance-reviewer)
  - [God Object] src/service.ts:15 (architecture-reviewer)

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
  1. TeamCreate: "framework-comparison"
  2. TaskCreate x 3: Apollo, Mercurius, Yoga 조사
  3. Task tool로 3개 researcher teammate spawn
  4. 각 researcher가 독립적으로 조사
  5. Teammate들이 SendMessage로 평가 결과 전송
  6. Leader가 비교표 생성 및 추천
  7. Teammate shutdown → TeamDelete

출력:
  📊 프레임워크 비교:
  | 항목 | Apollo | Mercurius | Yoga |
  |------|--------|-----------|------|
  | 성능 | 3/5 | 5/5 | 4/5 |
  | DX | 5/5 | 3/5 | 4/5 |

  💡 추천: Mercurius (권장)
  Mercurius로 진행할까요?
```

### Pattern 3: 경쟁 가설 디버깅 (Competing Hypotheses)
**사용 사례**: 루트 원인이 불명확한 버그를 병렬 조사

**워크플로우**:
```
User: "사용자가 한 메시지 후 연결이 끊기는 문제 조사해줘"

Leader:
  1. TeamCreate: "debug-team"
  2. TaskCreate x 3: WebSocket, Session, Race Condition 가설
  3. 각 teammate가 독립적으로 가설 검증
  4. Teammate 간 직접 대화로 가설 반박/토론
  5. 생존한 가설을 Leader가 종합

특징:
  - Teammate들이 SendMessage로 서로의 가설을 직접 반박
  - Leader는 토론 결과를 수신하여 최종 판단
```

### Pattern 4: 자기조직화 워커 (Self-Organizing Workers)
**사용 사례**: 대규모 작업을 자동으로 분할 및 병렬 처리

**워크플로우**:
```
User: "모든 API 엔드포인트에 대한 테스트 생성해줘"

Leader:
  1. 엔드포인트 목록 수집 (10개)
  2. TeamCreate: "test-generation"
  3. TaskCreate x 3-4: 엔드포인트 그룹별 태스크
  4. Task tool로 worker teammate spawn
  5. Worker들이 완료 후 SendMessage로 결과 보고
  6. 미할당 태스크가 있으면 worker가 TaskList로 자동 claim
  7. 모든 태스크 완료 시 통합 보고
```

---

## Teammate 제어 기능

### Plan Approval (작업 승인)
복잡하거나 위험한 작업에 대해 teammate가 계획을 세우고 Leader 승인 후 실행:
```pseudo
// Teammate spawn 시 plan mode 요구
Task(
    subagent_type: "general-purpose",
    team_name: "review-team",
    name: "refactoring-worker",
    prompt: "인증 모듈을 리팩토링해주세요.",
    mode: "plan"  // plan approval 필요
)

// Teammate가 ExitPlanMode로 계획 제출
// Leader가 SendMessage(type: "plan_approval_response")로 승인/거부
SendMessage(
    type: "plan_approval_response",
    request_id: "abc-123",
    recipient: "refactoring-worker",
    approve: true  // 또는 false + content로 피드백
)
```

### Delegate Mode
Leader가 직접 구현하지 않고 조정에만 집중:
- Shift+Tab으로 delegate 모드 전환
- Leader는 spawn, 메시지, 태스크 관리만 수행
- 모든 실제 작업은 teammate에게 위임

### Teammate 직접 대화
- **tmux 모드**: 패널 클릭으로 teammate와 직접 대화
- **in-process 모드**: Shift+Up/Down으로 teammate 선택
- Enter로 teammate 세션 확인, Escape로 인터럽트

---

## Teammate Prompt 템플릿

### 리뷰어 작업 Prompt:
```
당신은 {전문 분야} 전문가이며 {team_name} 팀의 teammate입니다.

## 작업
다음 파일들을 {관점}에서 리뷰하세요:
{파일 목록}

## 결과 보고
분석 완료 후 SendMessage로 Leader에게 결과를 보고하세요:
- recipient: Leader 이름
- summary: 핵심 발견 요약 (5-10 단어)
- content: JSON 형식 결과

## 결과 포맷
{
  "agent": "{agent-name}",
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

## 팀 협업
- 다른 teammate의 분석과 관련된 이슈 발견 시 해당 teammate에게 직접 SendMessage
- TaskUpdate로 작업 상태를 completed로 변경
- 완료 후 TaskList를 확인하여 미할당 작업이 있으면 자동으로 claim

## 중요
- Confidence >= 80인 이슈만 보고
- Critical은 즉시 수정 필요한 것만
- 파일이 없거나 읽기 실패 시 에러 기록
```

### 연구원 작업 Prompt:
```
당신은 기술 연구 전문가이며 {team_name} 팀의 teammate입니다.

## 작업
{프레임워크/라이브러리}를 다음 기준으로 평가하세요:
- 성능 (벤치마크, 번들 크기)
- 개발자 경험 (DX, 문서, 타입스크립트)
- 커뮤니티 (활성도, GitHub stars, 유지보수)
- 생태계 (플러그인, 통합)

## 결과 보고
분석 완료 후 SendMessage로 Leader에게 결과를 보고하세요.

## 결과 포맷
{
  "agent": "{agent-name}",
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

## 팀 협업
- 다른 researcher와 비교 관점에서 유용한 정보 발견 시 직접 SendMessage
- TaskUpdate로 작업 상태를 completed로 변경
```

---

## 결과 집계 포맷

### 리뷰 결과 집계:
```
📋 종합 {리뷰 타입} 결과

🔴 Critical Issues ({count}):
{for each critical finding:}
- [{category}] {file}:{line} ({teammate-name})
  {description}

🟡 Important Issues ({count}):
{for each important finding:}
- [{category}] {file}:{line} ({teammate-name})
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

### 연구 결과 집계:
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

고려사항:
- {trade-off 1}
- {trade-off 2}

{선택}으로 진행할까요?
```

---

## 기존 규칙 통합

### auto-commit-after-tests.md 통합
Agent Teams 리뷰 후 수정 → 테스트 → 자동 커밋 제안

**워크플로우**:
```
1. Agent Teams 리뷰 완료 → Critical 이슈 발견
2. 사용자 "수정해줘" 선택
3. Teammate에게 수정 위임 또는 Sequential 모드로 전환
4. 테스트 실행 (자동)
5. 테스트 통과 → auto-commit-after-tests 트리거
6. 커밋 메시지 제안 (리뷰 결과 반영)
```

### git-push-protection.md 통합
커밋 후 push 시 protected 브랜치 확인

**워크플로우**:
```
1. Agent Teams 리뷰 → 수정 → 커밋
2. 사용자 "푸시해줘"
3. git-push-protection 확인
4. Protected 브랜치면 경고 → Feature 브랜치 권장
5. Feature 브랜치로 push → PR 생성
```

### orchestration.md 통합
Agent Teams 완료 후 수정 작업은 적절한 모드 선택

**판단 로직**:
```
if findings.critical_count <= 2:
    mode = Sequential  # 소규모 수정
elif findings.files_affected >= 5:
    mode = Agent Teams  # 대규모 수정 (teammate에게 위임)
else:
    mode = Sequential  # 기본값
```

---

## 에러 처리

### Teammate 실행 실패
Teammate가 에러를 SendMessage로 보고:
```json
{
  "agent": "security-sentinel",
  "status": "error",
  "error": "Failed to read file: src/auth.ts (permission denied)",
  "partial_findings": [],
  "confidence": 0
}
```

**Leader 조치**:
- 부분 결과 사용 (가능한 경우)
- 사용자에게 에러 보고
- 대체 teammate spawn 또는 나머지 teammate 결과 정상 집계

### Teammate 정지
Teammate가 에러 후 정지할 수 있음:
- Shift+Up/Down 또는 패널 클릭으로 teammate 확인
- 추가 지시를 직접 전달하거나
- 대체 teammate를 spawn하여 작업 계속

### 팀 정리 실패
```pseudo
// 활성 teammate가 있으면 TeamDelete 실패
// 먼저 모든 teammate에게 shutdown_request 전송
for each active_teammate:
    SendMessage(type: "shutdown_request", recipient: teammate.name)
// 모든 teammate 종료 확인 후 TeamDelete
```

---

## 성능 최적화

### Teammate 수 제한
최대 5개 teammate 동시 실행 (토큰 비용 고려):
```pseudo
MAX_TEAMMATES = 5

if required_teammates > MAX_TEAMMATES:
    run_in_batches(teammates, batch_size=5)
```

### 태스크 크기 적정화
- **너무 작음**: 조정 오버헤드가 이점을 초과
- **너무 큼**: 확인 없이 너무 오래 작업, 낭비 위험
- **적정**: 명확한 결과물을 산출하는 자기완결적 단위
- teammate당 5-6개 태스크가 적정 (생산성 유지, 재할당 가능)

### 자동 태스크 claim
Teammate가 할당된 작업 완료 후:
1. TaskUpdate로 completed 처리
2. TaskList로 미할당/미차단 태스크 확인
3. 낮은 ID 순으로 자동 claim (TaskUpdate로 owner 설정)
4. 파일 락으로 race condition 방지

---

## 사용 예시

### 예시 1: 다각도 PR 리뷰
```
User: "PR #456을 보안, 성능, 테스트 관점에서 종합 리뷰해줘"

Claude:
  📊 작업 분석:
  - 작업 유형: 다각도 코드 리뷰
  - 관점: 3개 (보안, 성능, 테스트)

  🎯 권장 모드: Agent Teams
  이유: 독립적인 3개 관점, 결과 집계 필요

  진행할까요?

User: "네"

Claude:
  [TeamCreate: "pr-456-review"]
  [TaskCreate x 3: security, performance, test]
  [Task tool로 3개 teammate spawn → tmux 패널에 각각 표시]

  [각 teammate가 독립 리뷰 → SendMessage로 결과 전송]

  📋 종합 리뷰 결과:

  🔴 Critical Issues (2):
  - [SQL Injection] src/db/users.ts:45 (security-reviewer)
  - [N+1 Query] src/api/posts.ts:123 (performance-reviewer)

  🟡 Important Issues (6):
  - [Weak Password] src/auth/validate.ts:12 (security-reviewer)
  - [Missing Index] src/db/schema.ts:34 (performance-reviewer)
  - [Low Coverage] src/utils/format.ts (test-reviewer)

  📊 분석 요약:
  - 보안: 1 critical, 2 important
  - 성능: 1 critical, 3 important
  - 테스트: 0 critical, 1 important

  [shutdown_request → TeamDelete]

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
  🎯 권장 모드: Agent Teams

  진행할까요?

User: "응"

Claude:
  [TeamCreate: "auth-comparison"]
  [3개 researcher teammate spawn → 각각 별도 tmux 패널]

  [researcher들이 독립 조사 → SendMessage로 결과 전송]

  📊 인증 라이브러리 비교:

  | 항목 | Passport | NextAuth | Lucia |
  |------|----------|----------|-------|
  | 성능 | 3/5 | 4/5 | 5/5 |
  | DX | 3/5 | 5/5 | 4/5 |
  | 커뮤니티 | 5/5 | 5/5 | 3/5 |
  | 번들 크기 | 중간 | 큼 | 작음 |
  | 프레임워크 | Any | Next.js | Any |

  💡 추천: NextAuth (권장)

  [shutdown_request → TeamDelete]

  NextAuth로 진행할까요?
```

---

## 구현 체크리스트

Leader (Main Session):
- [ ] 작업 분석 → Agent Teams 조건 체크
- [ ] TeamCreate로 팀 생성
- [ ] 각 관점/작업에 대해 TaskCreate
- [ ] Task tool로 teammate spawn (team_name, name 지정)
- [ ] Teammate 메시지 자동 수신 (폴링 불필요)
- [ ] 모든 결과 수신 시 통합 리포트 생성
- [ ] 사용자에게 제시 및 후속 작업 확인
- [ ] shutdown_request → TeamDelete로 정리

Teammate:
- [ ] TaskGet으로 할당된 작업 읽기
- [ ] 팀 config 파일로 다른 teammate 확인 (`~/.claude/teams/{team-name}/config.json`)
- [ ] 전문 분야 분석 수행
- [ ] SendMessage로 Leader에게 결과 보고
- [ ] TaskUpdate로 completed 상태 변경
- [ ] TaskList로 추가 작업 확인 및 자동 claim
- [ ] 관련 이슈 발견 시 다른 teammate에게 직접 SendMessage

---

## 주의사항

1. **Confidence 필터링**: 모든 teammate는 confidence >= 80인 이슈만 보고
2. **False Positive 최소화**: Critical은 즉시 수정 필요한 것만 표시
3. **토큰 비용 인식**: Agent Teams는 단일 세션보다 토큰을 많이 사용 (teammate 수에 비례)
4. **에러 허용성**: 일부 teammate 실패해도 나머지 결과 활용
5. **사용자 의도 존중**: 명시적으로 특정 관점만 요청하면 해당 teammate만 spawn
6. **세션 복원 제한**: `/resume`으로 in-process teammate 복원 불가 (새 teammate spawn 필요)
7. **파일 충돌 방지**: 2개 이상 teammate가 동일 파일 편집하지 않도록 작업 분리
8. **1팀 1세션**: Leader는 한 번에 하나의 팀만 관리 가능 (기존 팀 정리 후 새 팀 생성)
9. **정리는 Leader만**: TeamDelete는 반드시 Leader가 실행 (teammate가 실행하면 불일치 발생 가능)

---

## v2.0 → v3.0 마이그레이션 요약

| 항목 | v2.0 (기존 Subagent 방식) | v3.0 (네이티브 Agent Teams) |
|------|--------------------------|---------------------------|
| 팀 생성 | 없음 (수동 관리) | TeamCreate 네이티브 API |
| 에이전트 실행 | Task(run_in_background: true) | Task(team_name, name) |
| 통신 | 파일 시스템 (`~/.claude/orchestration/results/`) | SendMessage 네이티브 메시징 |
| 결과 수집 | Leader가 파일 폴링 | 자동 메시지 전달 |
| 태스크 관리 | 수동 TaskList 폴링 | 자동 idle 알림 + 파일 락 claim |
| 디스플레이 | 없음 | tmux split pane / in-process |
| Teammate 대화 | 불가 | SendMessage / 직접 대화 |
| 작업 승인 | 없음 | Plan approval 지원 |
| 정리 | 수동 파일 삭제 | TeamDelete 네이티브 API |

---

**Last Updated**: 2026-02-07
**Version**: 3.0.0
**Status**: Production Ready
