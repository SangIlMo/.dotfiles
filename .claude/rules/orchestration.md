# Orchestration Rule (v4.0)

## 핵심 원칙
1. **기본값은 병렬** — 병렬 가능하면 항상 병렬
2. **모든 실행은 sub-agent 위임** — Leader는 조정/판단/git만 직접 수행
3. **Agent Teams는 3개+ 독립 관점 + 집계 필요 시만**

---

## 모드 선택

| 모드 | 조건 | 도구 |
|------|------|------|
| **Internal Parallel** (기본) | 읽기/분석, 독립적 다중 작업, 1-2개 관점 | Task tool (sub-agent) |
| **Agent Teams** | 3개+ 독립 관점, 결과 집계, teammate 간 토론 필요 | TeamCreate + Task(team_name) + SendMessage |
| **Sequential** (예외) | 파일 간 의존성, 디버깅, 트랜잭션 | Sub-agent 체인 (순차 위임) |

### 자동 감지 키워드
- **Parallel**: "분석", "조사", "찾아", "비교", "리뷰", "모든", "전체"
- **Agent Teams**: "보안,성능,아키텍처", "종합적으로", "다각도", 3개+ 비교, 대규모 생성(10개+)
- **Sequential**: "디버깅", "버그 수정", "단계별로", "순서대로"
- **사용자 명시 오버라이드**: "병렬로"/"팀으로"/"순차로" → 강제 적용

---

## Sequential 위임 패턴 (Delegated Sequential)

Leader가 직접 실행하지 않고 sub-agent 체인으로 위임:
```
1. Leader: 작업 분석 → 단계 분해 → 모델 선택
2. Task(model=haiku) → 코드 분석/읽기
3. Task(model=sonnet) → 코드 수정 (이전 결과를 prompt에 포함)
4. Task(model=haiku) → 테스트 실행
5. Leader: 결과 집계 → 사용자 보고 → git 작업 (직접)
```

---

## Agent Teams Teammate

| Teammate | 역할 | model |
|----------|------|-------|
| security-sentinel | 보안 취약점 | sonnet |
| performance-oracle | 성능 분석 | sonnet |
| architecture-strategist | 아키텍처 품질 | sonnet |
| framework-researcher | 프레임워크 평가 | sonnet |
| service-architect | 서비스 설계 | opus |

Agent Teams 흐름: TeamCreate → TaskCreate x N → Task(team_name, name, model) x N → teammate SendMessage → Leader 집계 → shutdown_request → TeamDelete
