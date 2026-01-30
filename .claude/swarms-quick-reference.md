# Claude Code Swarms - Quick Reference

## When to Use Swarms

Use Internal Swarms mode when:
- ✅ 3+ independent perspectives/tasks
- ✅ Results need aggregation
- ✅ Parallel execution possible
- ✅ Multi-angle analysis beneficial

Examples:
- "다각도 코드 리뷰" (보안 + 성능 + 아키텍처)
- "프레임워크 비교" (3개+ 옵션 조사)
- "서비스 아키텍처 설계" (여러 관점)

## Available Agents

| Agent | Specialty | Output |
|-------|-----------|--------|
| security-sentinel | Security vulnerabilities | Critical/Important issues |
| performance-oracle | Performance bottlenecks | N+1 queries, O(n²), memory leaks |
| architecture-strategist | Code structure | SOLID violations, god objects |
| framework-researcher | Tech evaluation | 5-star ratings, pros/cons |
| service-architect | Service design | APIs, schemas, events |

## Command Patterns

### Multi-Perspective Review
```
"[파일/PR]을 보안, 성능, 아키텍처 관점에서 리뷰해줘"
"다각도로 리뷰해줘"
"종합 분석해줘"
```

### Framework Comparison
```
"[기술] 비교해줘: [옵션1], [옵션2], [옵션3]"
"GraphQL 서버 추천해줘"
"인증 라이브러리 비교"
```

### Service Design
```
"[도메인] 마이크로서비스로 설계해줘"
"[시스템] 아키텍처 설계"
```

## Typical Output

```
📊 작업 분석:
- 작업 유형: [유형]
- 관점: X개

🎯 권장 모드: Internal Swarms
이유: [설명]

진행할까요?

[After execution]

📋 종합 결과:

🔴 Critical Issues (X):
[목록...]

🟡 Important Issues (Y):
[목록...]

다음 단계: [액션]
```

## Result Locations

```bash
# View agent results
ls ~/.claude/orchestration/results/

# Agent output files
~/.claude/orchestration/results/security-{task-id}.json
~/.claude/orchestration/results/performance-{task-id}.json
~/.claude/orchestration/results/architecture-{task-id}.json
```

## Confidence Levels

All agents filter findings by confidence:
- **Critical**: >= 90% confidence
- **Important**: >= 80% confidence
- **Minor**: < 80% (not reported)

## Integration

Swarms work with:
- ✅ auto-commit-after-tests.md (auto commit after fixes)
- ✅ git-push-protection.md (protect main branch)
- ✅ orchestration.md (auto mode selection)

## Troubleshooting

### Tasks not completing
```bash
claude /tasks list
# Cancel stuck tasks
```

### No results found
```bash
ls -la ~/.claude/orchestration/results/
# Check if files exist
```

### Want sequential instead
Say: "순차로 해줘" to override

## Performance

- **Sequential**: 9 minutes (3 × 3 min)
- **Swarms**: 3-4 minutes (parallel)
- **Speedup**: ~3x

## Limits

- Max concurrent agents: 5
- Confidence threshold: >= 80%
- Polling interval: 2 seconds
