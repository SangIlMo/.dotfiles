# Auto Commit After Tests Rule

## 목적
테스트 실행 완료 후 자동으로 커밋 여부를 확인하여 작업 흐름을 개선하고, 성공적인 테스트 결과를 즉시 버전 관리에 반영합니다.

---

## 적용 대상 테스트

다음 테스트 실행 후 커밋 여부를 확인합니다:

### 1. 언어별 테스트 프레임워크
- **JavaScript/TypeScript**: `npm test`, `yarn test`, `jest`, `vitest`, `mocha`
- **Python**: `pytest`, `python -m unittest`, `nose2`, `tox`
- **Go**: `go test`, `go test ./...`
- **Rust**: `cargo test`
- **Java**: `mvn test`, `gradle test`, `./gradlew test`
- **Ruby**: `rspec`, `rake test`, `rails test`
- **PHP**: `phpunit`, `pest`
- **C#/.NET**: `dotnet test`

### 2. 통합 테스트 도구
- **CI/CD 로컬 실행**: `act`, `gitlab-runner exec`
- **E2E 테스트**: `cypress run`, `playwright test`
- **Linting**: `eslint`, `pylint`, `rubocop` (통과 시)
- **Type Checking**: `tsc --noEmit`, `mypy`

### 3. 복합 테스트 명령
- `npm run test:all`
- `make test`
- `./scripts/test.sh`
- 여러 테스트를 순차 실행하는 경우 (`&&`로 연결된 명령)

---

## 커밋 확인 트리거 조건

### ✅ 커밋 여부를 확인하는 경우

1. **모든 테스트 통과**
   - Exit code 0
   - 실패한 테스트 없음
   - 에러 메시지 없음

2. **변경사항 존재**
   - `git status`에서 변경된 파일 감지
   - Staged 또는 Unstaged 파일이 있음

3. **최근 커밋 없음**
   - 테스트 실행 전후로 새 커밋이 생성되지 않음

### ❌ 커밋 확인을 건너뛰는 경우

1. **테스트 실패**
   - Exit code != 0
   - 실패한 테스트 존재
   - 에러 발생

2. **변경사항 없음**
   - Working directory clean
   - 커밋할 내용 없음

3. **사용자가 명시적으로 거부**
   - "커밋하지 마"
   - "테스트만 실행해줘"
   - "확인만 해줘"

4. **읽기 전용 작업**
   - 코드 분석만 수행
   - 파일 탐색만 수행

---

## 커밋 확인 프로세스

### 1. 테스트 완료 후 자동 체크

```pseudo
함수 afterTestCompletion(testResult, command):
    // 테스트 실패 시 종료
    if testResult.exitCode != 0:
        return reportTestFailure(testResult)

    // 변경사항 확인
    gitStatus = executeCommand("git status --short")
    if gitStatus.isEmpty():
        return "변경사항이 없어 커밋이 필요하지 않습니다."

    // 커밋 여부 확인
    askCommitConfirmation(gitStatus, testResult)
```

### 2. AskUserQuestion 사용

테스트 성공 후 다음 형식으로 확인:

```json
{
  "questions": [{
    "question": "테스트가 모두 통과했습니다. 변경사항을 커밋하시겠습니까?",
    "header": "커밋 확인",
    "options": [
      {
        "label": "커밋 생성 (권장)",
        "description": "테스트 통과한 코드를 즉시 커밋"
      },
      {
        "label": "추가 작업 후 커밋",
        "description": "나중에 수동으로 커밋"
      },
      {
        "label": "커밋하지 않음",
        "description": "변경사항 유지, 커밋 생략"
      }
    ],
    "multiSelect": false
  }]
}
```

### 3. 커밋 메시지 자동 생성

사용자가 커밋을 승인하면 자동으로 적절한 커밋 메시지 제안:

#### 커밋 메시지 생성 로직

1. **변경사항 분석**
   - `git diff --staged`
   - `git diff` (unstaged 포함)
   - `git status`로 파일 목록 확인

2. **테스트 결과 포함**
   - 통과한 테스트 수
   - 실행된 테스트 파일
   - 테스트 커버리지 변화 (있는 경우)

3. **커밋 메시지 포맷**
   ```
   [타입]: [간단한 설명]

   [상세 설명]
   - 변경된 주요 내용
   - 테스트 결과 요약

   Tests: [통과한 테스트 수] passed

   Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
   ```

#### 커밋 타입 자동 판단

| 변경 내용 | 커밋 타입 | 예시 |
|----------|----------|------|
| 새 기능 추가 | `feat` | feat: add user authentication |
| 버그 수정 | `fix` | fix: resolve login timeout issue |
| 테스트 추가/수정 | `test` | test: add unit tests for auth module |
| 리팩토링 | `refactor` | refactor: simplify error handling |
| 문서 수정 | `docs` | docs: update API documentation |
| 스타일 변경 | `style` | style: format code with prettier |
| 성능 개선 | `perf` | perf: optimize database queries |

---

## 사용 시나리오

### 시나리오 1: TDD 워크플로우

```
사용자: "테스트 작성하고 구현해줘"
Claude: [테스트 작성]
        [테스트 실행 → 실패]
        "테스트가 실패했습니다. 구현을 진행하겠습니다."
        [기능 구현]
        [테스트 재실행 → 성공]
        [AskUserQuestion]
        "✅ 모든 테스트가 통과했습니다. 변경사항을 커밋하시겠습니까?"
사용자: [커밋 생성 선택]
Claude: [커밋 메시지 생성 및 커밋 실행]
        "feat: implement user login feature

        - Add login endpoint
        - Implement JWT token generation
        - Add input validation

        Tests: 8 passed

        Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

### 시나리오 2: 버그 수정 후 테스트

```
사용자: "버그 수정하고 테스트해줘"
Claude: [버그 수정]
        [테스트 실행 → 성공]
        [AskUserQuestion]
        "✅ 테스트 통과! 변경사항을 커밋하시겠습니까?"
사용자: [추가 작업 후 커밋 선택]
Claude: "알겠습니다. 추가 작업 후 커밋해주세요."
```

### 시나리오 3: 테스트 실패 시

```
사용자: "테스트 실행해줘"
Claude: [테스트 실행 → 실패]
        "❌ 테스트가 실패했습니다.

        Failed tests:
        - test/auth.test.js:42 - should validate email format

        커밋 확인을 건너뜁니다. 테스트를 수정하시겠습니까?"
```

### 시나리오 4: 변경사항 없음

```
사용자: "테스트 실행해줘"
Claude: [테스트 실행 → 성공]
        [git status 확인 → clean]
        "✅ 모든 테스트 통과!
        변경사항이 없어 커밋이 필요하지 않습니다."
```

---

## 커밋 실행 프로세스

사용자가 커밋을 승인하면 다음 단계를 자동 수행:

### 1. 변경사항 확인 및 스테이징

```bash
# 현재 상태 확인
git status

# 변경된 파일 자동 스테이징 (신중하게)
# 테스트 관련 파일과 구현 파일만 포함
git add [관련 파일들]
```

### 2. 커밋 생성

```bash
# 생성된 커밋 메시지로 커밋
git commit -m "$(cat <<'EOF'
[자동 생성된 커밋 메시지]

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

### 3. 커밋 후 상태 확인

```bash
# 커밋 성공 확인
git log -1 --oneline

# 현재 상태 재확인
git status
```

---

## 통합 규칙

### Git Push Protection Rule과의 통합

1. **커밋 후 자동으로 Push 여부 확인하지 않음**
   - 커밋만 수행하고 push는 별도 확인
   - `git-push-protection.md` 규칙이 push 시점에 작동

2. **Protected 브랜치에서도 커밋은 허용**
   - 로컬 커밋은 안전하므로 항상 허용
   - Push 시에만 보호 규칙 적용

### Orchestration Rule과의 통합

1. **모든 실행 모드에서 작동**
   - Sequential: 직접 테스트 후 커밋 확인
   - Internal Parallel: Task 완료 후 커밋 확인
   - Internal Swarms: 각 에이전트 작업 완료 후 커밋 확인

---

## 예외 처리

### 사용자 명시적 요청 시 자동 커밋

사용자가 다음과 같이 요청하면 확인 없이 자동 커밋:
- "테스트 통과하면 자동으로 커밋해줘"
- "테스트 후 바로 커밋"
- "테스트 성공 시 커밋 생성"

이 경우에도 정보 메시지 출력:
```
✅ 테스트 통과! 자동으로 커밋을 생성합니다.
커밋 메시지: [생성된 메시지]
```

### Dry Run 모드

사용자가 요청 시 커밋 없이 메시지만 생성:
- "커밋 메시지만 보여줘"
- "어떤 커밋 메시지가 생성될지 확인"

```
📝 생성될 커밋 메시지 미리보기:
[커밋 메시지]

실제로 커밋하시겠습니까?
```

---

## 민감한 파일 필터링

커밋 시 다음 파일들은 자동으로 제외하고 경고:

### 제외 대상
- `.env`, `.env.local`, `.env.*`
- `*_credentials.json`, `*.key`, `*.pem`
- `config/secrets.yml`, `secrets/*`
- `node_modules/`, `vendor/`, `dist/` (gitignore에 있는 경우)

### 경고 메시지
```
⚠️ 민감한 파일 감지:
- .env (환경 변수)
- credentials.json (인증 정보)

이 파일들은 커밋에서 제외됩니다.
계속 진행하시겠습니까?
```

---

## 설정 옵션

사용자가 프로젝트별로 `.claude/project-config.json`에서 설정 가능:

```json
{
  "autoCommitAfterTests": {
    "enabled": true,
    "autoStage": "test-related-only",
    "commitMessageFormat": "conventional",
    "excludePatterns": [".env*", "*.key"],
    "alwaysAsk": true,
    "skipIfNoTests": false
  }
}
```

### 옵션 설명
- `enabled`: 이 기능 활성화 여부 (기본: true)
- `autoStage`: 자동 스테이징 전략
  - `"test-related-only"`: 테스트와 관련된 파일만
  - `"all"`: 모든 변경사항
  - `"manual"`: 수동으로만 추가
- `commitMessageFormat`: 커밋 메시지 형식
  - `"conventional"`: Conventional Commits
  - `"simple"`: 간단한 형식
- `excludePatterns`: 추가 제외 패턴
- `alwaysAsk`: 항상 사용자 확인 (기본: true)
- `skipIfNoTests`: 테스트 파일이 없으면 건너뛰기

---

## 구현 체크리스트

Claude가 이 rule을 따를 때 확인해야 할 사항:

- [ ] 테스트 실행 완료 감지 (exit code 확인)
- [ ] 테스트 성공/실패 판단
- [ ] `git status` 실행하여 변경사항 확인
- [ ] 변경사항이 있고 테스트 성공 시 AskUserQuestion 호출
- [ ] 사용자 승인 시 적절한 커밋 메시지 생성
- [ ] 관련 파일만 선별하여 `git add` 실행
- [ ] 민감한 파일 필터링 및 경고
- [ ] 커밋 실행 및 결과 확인
- [ ] 커밋 후 `git status`로 상태 재확인
- [ ] Push는 별도로 처리 (git-push-protection rule에 위임)

---

## 주의사항

1. **테스트 성공 확인 필수**: Exit code가 0이고 실제로 테스트가 통과했는지 확인
2. **민감한 파일 보호**: 절대로 credentials, secrets를 커밋하지 않도록 필터링
3. **사용자 의도 존중**: 명시적으로 "커밋하지 마"라고 했으면 확인하지 않음
4. **적절한 파일만 스테이징**: 테스트와 무관한 파일은 제외
5. **명확한 커밋 메시지**: 변경사항을 정확하게 반영하는 메시지 생성

---

## 통합 워크플로우 예시

전체 TDD 워크플로우에서 모든 rule이 함께 작동:

```
사용자: "새 기능을 TDD로 개발해줘"

Claude: 📊 작업 분석 (orchestration.md)
        → Sequential 모드 선택 (테스트 작성 → 구현)

사용자: "좋아"

Claude: [테스트 작성]
        → [기능 구현]
        → 테스트 실행 → 성공
        → ✅ 테스트 커밋 확인 (auto-commit-after-tests.md)

사용자: [커밋 생성 선택]

Claude: → 커밋 생성
        → ⚠️ Protected 브랜치 푸시 확인 (git-push-protection.md)

사용자: [취소, feature 브랜치로 변경]

Claude: → Feature 브랜치 생성
        → Push 실행 (자동 허용)
        → PR 생성
```

---

## 마무리

이 rule은 테스트 주도 개발(TDD)과 지속적 통합(CI) 워크플로우를 지원하여:
- 성공적인 테스트 결과를 즉시 버전 관리
- 작업 흐름 중단 최소화
- 일관된 커밋 이력 유지
- 안전한 코드 변경 추적

기존 `git-push-protection.md`와 `orchestration.md`와 완벽하게 통합됩니다.
