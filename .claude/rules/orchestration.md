# Claude Orchestration Rule

## 역할
작업을 분석하고 최적의 실행 모드를 자동 선택하는 오케스트레이터입니다.

## 실행 모드 (3가지)

### 모드 1: Sequential (순차)
- **조건**: 단순 작업, 의존성 있는 작업, 단일 파일 수정
- **도구**: 일반 Claude Code
- **예시**: 버그 수정, 단일 기능 추가, 코드 설명

### 모드 2: Internal Parallel (내장 병렬)
- **조건**: 탐색/분석 작업, 읽기 전용 병렬화
- **도구**: Claude Code Task tool (subagent)
- **예시**: 코드베이스 탐색, 다중 파일 분석, 패턴 검색

### 모드 3: Internal Swarms (내장 스웜)
- **조건**: 독립적인 다중 분석/리뷰 작업 (3개+), 결과 집계 필요
- **도구**: Task tool + Subagents + Shared Storage
- **예시**:
  - 다각도 코드 리뷰 (보안 + 성능 + 아키텍처)
  - 병렬 연구 (프레임워크 비교 3개+)
  - 대규모 테스트 생성 (여러 모듈 동시)
  - 서비스 아키텍처 분석 (여러 관점)

## 자동 판단 기준

| 작업 특성 | 권장 모드 |
|----------|----------|
| 파일 1-2개 수정 | Sequential |
| 여러 파일 읽기/분석 | Internal Parallel |
| 코드 리뷰만 | Internal Parallel |
| 다각도 코드 리뷰 (3개+ 관점) | Internal Swarms |
| 테스트 실행만 | Sequential |
| 병렬 연구 → 의사결정 | Internal Swarms |
| 대규모 생성 (10+ 파일) | Internal Swarms |
| 결과 집계 후 실행 | Internal Swarms |

## 모드 제안 형식

작업 분석 후 다음 형식으로 제안:

```
📊 작업 분석:
- 작업 유형: [유형]
- 수정 파일 수: [개수]
- 의존성: [있음/없음]

🎯 권장 모드: [Sequential/Internal Parallel/Internal Swarms]
이유: [간단한 설명]

진행할까요?
```

## 명령어 오버라이드

사용자가 명시적으로 요청 시 해당 모드 사용:
- "순차로 해줘" → Sequential
- "병렬로 분석해줘" → Internal Parallel
- "다각도로 리뷰해줘" / "종합 분석해줘" → Internal Swarms

## 세션 간 데이터 공유

Internal Swarms 모드에서 세션 간 데이터 공유:
- 공유 디렉토리: `~/.claude/orchestration/`
  - `issues/` - 리뷰에서 발견한 이슈
  - `tasks/` - 할당된 작업
  - `results/` - 완료된 결과
  - `sync/` - 세션 간 동기화 데이터
