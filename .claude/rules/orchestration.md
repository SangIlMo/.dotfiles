# Claude Orchestration Rule (v3.1 - Native Agent Teams)

## 핵심 원칙

**작업을 분석하고 최적의 실행 모드를 자동 선택하는 오케스트레이터입니다.**

1. **기본값은 병렬**: 병렬 가능하면 항상 병렬 실행
2. **Sequential은 예외**: 명확한 의존성이 있을 때만 순차 실행
3. **자동 감지 우선**: 사용자가 명시하지 않아도 자동으로 병렬 선택
4. **Agent Teams 활용**: 다각도 분석/비교 시 네이티브 Agent Teams 사용

---

## 실행 모드 우선순위

### 1. Internal Parallel (기본)
- **조건**: 읽기/분석 작업, 독립적인 다중 작업
- **도구**: Claude Code Task tool (subagent)
- **예시**: 코드베이스 탐색, 다중 파일 분석, 패턴 검색, 단일 관점 리뷰

### 2. Agent Teams (집계 필요 시)
- **조건**: 독립적인 다중 분석/리뷰 작업 (3개+), 결과 집계 필요, teammate 간 토론/협업 필요
- **도구**: TeamCreate + Task(team_name, name) + SendMessage
- **디스플레이**: tmux split pane (각 teammate 별도 패널)
- **Teammate**: security-sentinel, performance-oracle, architecture-strategist, framework-researcher, service-architect
- **특징**:
  - TeamCreate로 팀 생성, Task tool로 teammate spawn
  - teammate별 tool 제한 및 model 선택 (`~/.claude/agents/`)
  - SendMessage로 네이티브 메시징 (자동 전달, 폴링 불필요)
  - 공유 TaskList로 자동 태스크 관리 (파일 락 기반 claim)
  - teammate 간 직접 대화 (tmux 패널 클릭 또는 Shift+Up/Down)
  - Plan approval로 복잡한 작업 승인 관리
  - Delegate mode로 Leader 조정 전용 모드
  - Persistent Memory로 세션 간 학습
- **예시**:
  - 다각도 코드 리뷰 (보안 + 성능 + 아키텍처)
  - 병렬 연구 (프레임워크 비교 3개+)
  - 대규모 테스트 생성 (여러 모듈 동시)
  - 경쟁 가설 디버깅 (teammate 간 토론)

### 3. Sequential (예외적 사용만)
- **조건**: 파일 간 의존성 명확, 디버깅, 트랜잭션 작업
- **도구**: Sub-agent 체인 (Task tool로 순차 위임)
- **예시**: 버그 수정, 단계별 디버깅, 의존성 있는 수정

---

## Leader Context Protection 원칙

**Leader(메인 세션)는 context window를 보호하기 위해 조정/판단만 수행하고, 실행 작업은 sub-agent에게 위임합니다.**

### Leader 직접 수행 (예외)
- git 작업: commit, push, branch, yadm
- 사용자 질문 응답 (간단한 설명)
- 모드 판단 및 sub-agent 조정
- AskUserQuestion으로 사용자 확인

### Sub-agent 위임 (기본)
모든 코드 읽기, 수정, 분석, 테스트 실행은 sub-agent에게 위임:

| 작업 | subagent_type | model | 이유 |
|------|---------------|-------|------|
| 파일 탐색/검색 | Explore | haiku | 단순 읽기, 빠른 응답 |
| 코드 읽기/분석 | Explore | haiku | 단순 읽기, 빠른 응답 |
| 단순 수정 (오타, 린트) | general-purpose | haiku | 패턴 기반 단순 변경 |
| 기능 구현 | general-purpose | sonnet | 중간 복잡도 코딩 |
| 리팩토링 | general-purpose | sonnet | 구조 변경 판단 필요 |
| 테스트 작성 | general-purpose | sonnet | 테스트 설계 필요 |
| 테스트 실행 | Bash | haiku | 명령 실행만 |
| 코드 리뷰 | 전문 agent | sonnet | 분석 판단 필요 |
| 아키텍처 설계 | Plan / general-purpose | opus | 고수준 추론 필요 |
| 복잡한 디버깅 | general-purpose | opus | 다단계 추론 필요 |
| 계획 수립 | Plan | opus | 고수준 설계 |

### 모델 선택 기준 요약

| 복잡도 | 모델 | 기준 |
|--------|------|------|
| 낮음 | haiku | 파일 읽기, 단순 수정, 패턴 검색, 린트 수정, 명령 실행 |
| 중간 | sonnet | 기능 구현, 리팩토링, 코드 리뷰, 테스트 작성 |
| 높음 | opus | 아키텍처 설계, 복잡한 디버깅, 다단계 추론, 계획 수립 |

### Sequential 위임 패턴 (Delegated Sequential)

기존 Sequential에서 Leader가 직접 실행하던 것을 sub-agent 체인으로 변경:

```
1. Leader: 작업 분석 → 단계 분해 → 모델 선택
2. Step 1: Task(model=haiku) → 코드 분석/읽기
3. Step 2: Task(model=sonnet) → 코드 수정 (Step 1 결과를 prompt에 포함)
4. Step 3: Task(model=haiku) → 테스트 실행
5. Leader: 결과 집계 → 사용자 보고 → git 작업 (직접 수행)
```

**핵심**: 이전 단계의 결과를 다음 sub-agent의 prompt에 전달하여 연속성 유지

---

## Internal Parallel vs Agent Teams 선택 기준

| 기준 | Internal Parallel | Agent Teams |
|------|-------------------|-------------|
| **관점 수** | 1-2개 | 3개 이상 |
| **통신 필요** | 불필요 (결과만 반환) | 필요 (teammate 간 토론/공유) |
| **결과 형태** | 단순 집계 | 종합 분석 리포트 |
| **토큰 비용** | 낮음 | 높음 (teammate 수에 비례) |
| **작업 시간** | 짧음 (단일 요청) | 중-장 (복수 턴) |
| **디스플레이** | 없음 | tmux split pane |

---

## 자동 병렬 실행 트리거

### 즉시 Parallel 선택 키워드

다음 키워드가 포함된 요청은 자동으로 **Internal Parallel** 선택:

| 카테고리 | 키워드 | 예시 요청 |
|----------|--------|-----------|
| **조사/탐색** | "분석", "조사", "찾아", "확인", "검색" | "코드베이스를 분석해줘" |
| **비교** | "비교", "차이", "대안" | "두 방식의 차이점 찾아줘" |
| **리뷰** | "리뷰", "검토", "평가" | "코드 리뷰해줘" |
| **범위** | "모든", "전체", "각각", "여러" | "모든 Controller 확인해줘" |
| **읽기** | "읽어", "확인", "보여", "목록" | "전체 파일 목록 보여줘" |

### 즉시 Agent Teams 선택 키워드

다음 조건은 자동으로 **Agent Teams** 선택:

| 패턴 | 예시 요청 |
|------|-----------|
| **다각도 분석** | "보안, 성능, 아키텍처 측면에서 분석해줘" |
| **3개 이상 비교** | "A, B, C 라이브러리 비교해줘" |
| **종합 리뷰** | "종합적으로 리뷰해줘", "다각도로 평가해줘" |
| **대규모 생성** | "모든 API 엔드포인트에 테스트 생성해줘" (10개+) |
| **경쟁 가설** | "여러 가설로 조사해줘", "토론하면서 분석해줘" |

### Sequential 예외 키워드

다음 키워드는 **Sequential** 선택:

| 카테고리 | 키워드 | 예시 요청 |
|----------|--------|-----------|
| **디버깅** | "디버깅", "디버그", "에러 추적" | "로그인 에러를 디버깅해줘" |
| **수정** | "버그 수정", "에러 해결", "고쳐" | "NullPointerException 고쳐줘" |
| **순차 명시** | "단계별로", "순차적으로", "하나씩" | "단계별로 리팩토링해줘" |
| **의존성** | "A 다음에 B", "순서대로" | "먼저 A 수정 후 B 수정해줘" |

---

## 자동 판단 알고리즘

```
┌─────────────────────────────────────────┐
│ 1. 키워드 매칭 (자동 트리거)           │
│    → Parallel/Agent Teams 키워드 있음? │
│       YES: 해당 모드 선택             │
│       NO: Step 2                      │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 2. Sequential 예외 체크                │
│    → 의존성/디버깅 키워드 있음?       │
│       YES: Sequential                 │
│       NO: Step 3                      │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 3. 작업 타입 분석                      │
│    → 읽기 작업? → Internal Parallel   │
│    → 쓰기 작업? → Step 4              │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 4. 의존성 분석                         │
│    → 파일 간 의존성 있음?             │
│       YES: Sequential                 │
│       NO: Internal Parallel           │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 기본값: Internal Parallel              │
└─────────────────────────────────────────┘
```

---

## 자동 판단 기준

| 작업 특성 | 자동 선택 모드 | 트리거 조건 |
|----------|----------------|-------------|
| **읽기 전용 작업** | Internal Parallel | 파일 읽기, 코드 분석, 패턴 검색 |
| **여러 파일 분석** | Internal Parallel | 2개 이상 파일 |
| **단일 관점 리뷰** | Internal Parallel | "리뷰해줘", "검토해줘" |
| **다각도 분석** | Agent Teams | 3개 이상 독립적 관점 |
| **비교 작업** | Agent Teams | 3개 이상 옵션 비교 |
| **대규모 생성** | Agent Teams | 10개 이상 파일/테스트 |
| **경쟁 가설 조사** | Agent Teams | teammate 간 토론 필요 |
| **단일 파일 수정** | Internal Parallel | 의존성 없는 단순 수정 (병렬 가능) |
| **디버깅/수정** | Sequential | 에러 추적, 단계별 수정 |
| **의존성 있는 작업** | Sequential | A → B → C 순서 필수 |

---

## 모드 선택 시 피드백 형식

작업 분석 후 다음 형식으로 자동 선택을 명시:

```
🤖 자동 모드 선택: [Internal Parallel/Agent Teams/Sequential]

분석:
- 작업 유형: [읽기/쓰기/혼합]
- 파일/작업 수: [개수]
- 의존성: [없음/있음]
- 트리거 키워드: [발견된 키워드]

선택 이유:
[간단한 설명 1-2줄]

이 모드로 진행할까요? (아니면 다른 모드를 지정해주세요)
```

**간결한 형식 (선택적)**:

```
🎯 Internal Parallel로 진행합니다
이유: 여러 파일 읽기 작업, 병렬 처리 가능

[즉시 실행 또는 사용자 확인]
```

---

## 예시 시나리오

### 자동 Parallel 선택

**요청**: "Admin 도메인의 모든 Mapper 파일을 확인해줘"

**Claude 응답**:
```
🤖 자동 모드 선택: Internal Parallel

분석:
- 작업 유형: 읽기 (파일 분석)
- 파일 수: 5개 이상 예상
- 의존성: 없음
- 트리거 키워드: "모든", "확인"

선택 이유: 여러 파일 읽기 작업, 병렬 처리 가능

[3개 Explore 에이전트를 병렬 실행합니다]
```

### 자동 Agent Teams 선택

**요청**: "현재 인증 시스템을 보안, 성능, 유지보수성 측면에서 평가해줘"

**Claude 응답**:
```
🤖 자동 모드 선택: Agent Teams

분석:
- 작업 유형: 다각도 분석
- 관점 수: 3개 (보안, 성능, 유지보수성)
- 의존성: 독립적인 분석
- 트리거 키워드: "평가", 다중 관점

선택 이유: 3개 독립적 관점, 전문 teammate 활용, 결과 집계 필요

[TeamCreate → 3개 전문 teammate spawn → tmux split pane 표시]
Teammate:
- security-reviewer (security-sentinel)
- performance-reviewer (performance-oracle)
- architecture-reviewer (architecture-strategist)
```

### Sequential 예외

**요청**: "login API에서 500 에러가 나는데 디버깅해줘"

**Claude 응답**:
```
🤖 자동 모드 선택: Sequential

분석:
- 작업 유형: 디버깅
- 의존성: 단계별 추적 필요
- 트리거 키워드: "디버깅", "에러"

선택 이유: 에러 원인을 단계별로 추적해야 함

[순차적으로 진행합니다]
```

---

## Sequential 모드 (예외적 사용)

**다음 경우에만 Sequential 사용**:

- **파일 간 의존성이 명확함** (A 수정 후 B 수정 필요)
- **디버깅 중** (에러 추적, 단계별 수정)
- **트랜잭션 작업** (DB 마이그레이션, 설정 변경)
- **사용자가 명시** ("순차로", "단계별로")

**Sequential이 아닌 경우**:

- 단순히 "파일 1-2개"라는 이유만으로 (병렬 가능하면 Parallel)
- 테스트 실행만 하는 경우 (병렬 실행 가능)
- 단일 파일 수정이지만 의존성 없는 경우

---

## 명령어 오버라이드

사용자가 명시적으로 모드를 지정하면 항상 우선:

| 사용자 명령 | 강제 모드 | 예시 |
|-------------|-----------|------|
| "순차로 해줘", "단계별로" | Sequential | 자동 판단 무시하고 Sequential 실행 |
| "병렬로 해줘", "동시에" | Internal Parallel | 강제로 병렬 실행 |
| "팀으로", "다각도로", "에이전트 팀으로" | Agent Teams | 강제로 Agent Teams 모드 |

---

## Agent Teams Teammate 목록

Agent Teams 모드에서 사용 가능한 전문 teammate (`~/.claude/agents/`에 정의):

| Teammate | 역할 | 자동 위임 트리거 |
|----------|------|-----------------|
| `security-sentinel` | 보안 취약점 리뷰 | "보안", "security", "취약점" |
| `performance-oracle` | 성능 분석 | "성능", "performance", "최적화" |
| `architecture-strategist` | 아키텍처 품질 분석 | "아키텍처", "설계", "SOLID" |
| `framework-researcher` | 프레임워크/라이브러리 평가 | "비교", "추천", "프레임워크" |
| `service-architect` | 마이크로서비스 설계 | "서비스 설계", "API 설계" |

### Agent Teams 실행 흐름

```
1. TeamCreate(team_name, description)
2. TaskCreate x N (각 관점/작업별)
3. Task(subagent_type, team_name, name, prompt) x N → tmux split pane
4. Teammate들이 독립 작업 → SendMessage로 결과 전송 (자동 수신)
5. Leader가 통합 리포트 생성
6. SendMessage(type: "shutdown_request") → TeamDelete()
```

---

## 검증 및 모니터링

### 성공 기준

- 읽기 작업의 80% 이상이 Parallel 선택
- 3개 이상 독립 작업은 자동으로 Agent Teams 선택
- Sequential은 전체의 20% 이하로 감소
- 사용자가 모드 선택 이유를 명확히 이해

### 모드 선택 통계 (참고)

| 모드 | 목표 비율 | 실제 사용 사례 |
|------|-----------|----------------|
| Internal Parallel | 60-70% | 읽기, 분석, 단일 관점 리뷰 |
| Agent Teams | 10-20% | 다각도 분석, 비교, 대규모 생성, 경쟁 가설 |
| Sequential | 10-20% | 디버깅, 의존성 작업 |

---

## 참고사항

### 기존 Rule과의 호환성

- **swarm-coordination.md**: 네이티브 Agent Teams 조정 패턴, 통신 패턴, 결과 집계 포맷
- **auto-commit-after-tests.md**: 모든 모드와 호환 (변경 불필요)
- **git-push-protection.md**: 모든 모드와 호환 (변경 불필요)

### 버전 히스토리

- **v1.0**: Sequential 우선 (기존 방식)
- **v2.0**: Parallel-First 원칙 도입
- **v3.0**: Agent Teams 통합 (Internal Swarms 대체)
- **v3.1**: 네이티브 Agent Teams 완전 도입 (TeamCreate, SendMessage, tmux split pane)
- **v3.2**: Leader Context Protection 도입 (모든 실행 작업 sub-agent 위임, 모델 선택 매트릭스)

---

**Last Updated**: 2026-02-09
**Version**: 3.2.0
**Status**: Production Ready
