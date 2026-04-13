# fix-pr-ci — PR CI Failures Auto-Fix with Ralph Loop

PR의 CI 실패를 감지하고 ralph-loop을 사용하여 모든 체크가 통과할 때까지 자동으로 수정합니다.

## Usage

```bash
/fix-pr-ci {PR_NUMBER}
```

**예시:**
```bash
/fix-pr-ci 123
/fix-pr-ci 456 --max-iterations 30
```

## Workflow

1. **PR 정보 확인**
   - `gh pr view {PR_NUMBER}` 로 PR 세부사항 확인
   - 현재 브랜치가 PR 브랜치인지 확인

2. **CI 상태 확인**
   - `gh pr checks {PR_NUMBER}` 로 모든 체크 상태 조회
   - 실패한 체크 목록 추출

3. **Ralph Loop 시작**
   - PROMPT.md 생성 (PR 정보 + 실패 분석)
   - `/ralph-loop` 로 자동 루프 시작
   - `--completion-promise "ALL CHECKS PASSED"` 설정

4. **각 루프 반복 (Ralph가 자동 수행)**
   - CI 실패 원인 분석 (로그 확인)
   - 코드 수정 (테스트, 린트, 빌드 등)
   - 커밋 및 푸시
   - 새로운 CI 상태 확인
   - 모든 체크 통과 시 `<promise>ALL CHECKS PASSED</promise>` 출력

## States

- **PENDING**: PR 생성 중, 초기 체크 대기
- **RUNNING**: 일부 체크 실행 중
- **PASSED**: 모든 체크 통과 ✅
- **FAILED**: 실패한 체크 있음 ❌

## Output Example

```
PR #123 Analysis
================

Current Status:
- tests: ❌ FAILED
- lint: ⚠️  SKIPPED
- build: ❌ FAILED

Failed Checks Details:
1. tests — npm test failed with exit code 1
   Error: Cannot find module 'lodash'

2. build — npm run build failed
   Error: Type error in src/index.ts:42

Fixing Strategy:
1. Install missing dependencies: lodash
2. Fix type error in src/index.ts line 42
3. Run npm test to verify
4. Run npm run build to verify
5. Commit and push

<promise>ALL CHECKS PASSED</promise>
```

## Notes

- ralph-loop이 자동으로 PR을 모니터링하고 반복 수정합니다
- 각 반복마다 새로운 CI 실행을 트리거합니다
- 30회 반복 후에도 통과 못하면 실패로 간주합니다
- 수정 불가능한 오류는 수동 개입이 필요합니다
