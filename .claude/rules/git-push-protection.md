# Git Push Protection Rule

## 목적
중요한 브랜치(main, dev 등)에 직접 푸시할 때 사용자에게 확인을 받아 실수로 인한 직접 푸시를 방지합니다.

---

## Protected 브랜치 목록

다음 브랜치들은 보호 대상입니다:
- `main`
- `master`
- `dev`
- `develop`
- `production`
- `prod`
- `release`
- `staging`

---

## Push 보호 규칙

### 1. Protected 브랜치 푸시 시

**언제**: 사용자가 다음 작업을 요청할 때
- `git push` 실행
- `gh pr create` 후 자동 push
- 기타 원격 저장소로 푸시하는 모든 작업

**동작**:
1. **현재 브랜치 확인**: `git branch --show-current`로 현재 브랜치 이름 확인
2. **Protected 브랜치 체크**: 브랜치 이름이 위 목록에 포함되는지 확인
3. **확인 요청**: Protected 브랜치인 경우 **반드시** `AskUserQuestion` 도구 사용
4. **사용자 승인 후에만 실행**: 사용자가 명시적으로 승인한 경우에만 push

**확인 질문 예시**:
```
⚠️ Protected 브랜치 푸시 경고

현재 브랜치: main
이 브랜치는 보호된 브랜치입니다.

정말로 main 브랜치에 직접 푸시하시겠습니까?
일반적으로 feature 브랜치를 만들어 작업 후 PR을 생성하는 것을 권장합니다.
```

### 2. Force Push 시 강화된 경고

**언제**: `--force`, `-f`, `--force-with-lease` 플래그가 포함된 경우

**동작**:
1. Protected 브랜치 여부와 관계없이 **항상 확인 요청**
2. Force push의 위험성 명시
3. 사용자 승인 후에만 실행

**확인 질문 예시**:
```
🚨 Force Push 경고

현재 브랜치: [브랜치명]
Force push는 원격 저장소의 히스토리를 덮어쓰며, 다른 사람의 작업을 잃을 수 있습니다.

정말로 force push를 실행하시겠습니까?
```

---

## 자동 허용 조건

다음 브랜치 패턴은 확인 없이 자동으로 푸시 가능:
- `feature/*`
- `bugfix/*`
- `hotfix/*`
- `fix/*`
- `feat/*`
- `[MMDD]/*` (예: `0120/feat/...`)
- `[사용자명]/*`
- 기타 개인 작업 브랜치

---

## 구현 가이드라인

### 1. Push 전 체크 로직

```pseudo
함수 beforeGitPush(command):
    현재브랜치 = getCurrentBranch()

    // Force push 체크
    if command.includes('--force') or command.includes('-f'):
        사용자확인 = askForceushConfirmation(현재브랜치)
        if not 사용자확인:
            return 취소

    // Protected 브랜치 체크
    if 현재브랜치 in PROTECTED_BRANCHES:
        if not isAutoAllowedPattern(현재브랜치):
            사용자확인 = askProtectedBranchConfirmation(현재브랜치)
            if not 사용자확인:
                return 취소

    // Push 실행
    executePush(command)
```

### 2. AskUserQuestion 사용 예시

Protected 브랜치 푸시 시:
```json
{
  "questions": [{
    "question": "정말로 main 브랜치에 직접 푸시하시겠습니까?",
    "header": "Push 확인",
    "options": [
      {
        "label": "취소 (권장)",
        "description": "Feature 브랜치를 생성하여 PR로 진행"
      },
      {
        "label": "푸시 실행",
        "description": "현재 브랜치에 직접 푸시"
      }
    ],
    "multiSelect": false
  }]
}
```

Force push 시:
```json
{
  "questions": [{
    "question": "Force push를 실행하시겠습니까? (히스토리 덮어쓰기)",
    "header": "Force Push",
    "options": [
      {
        "label": "취소 (권장)",
        "description": "일반 push 또는 새 브랜치로 진행"
      },
      {
        "label": "실행",
        "description": "Force push 강제 실행 (위험)"
      }
    ],
    "multiSelect": false
  }]
}
```

---

## 적용 범위

### 적용 대상
- `git push` 직접 실행
- `git push origin [브랜치명]`
- `git push --force`
- `gh pr create` 실행 시 자동 push
- 커밋 후 push를 포함하는 워크플로우

### 적용 제외
- `git pull`, `git fetch` 등 읽기 전용 작업
- 로컬 브랜치 전환 (`git checkout`, `git switch`)
- Feature 브랜치로의 일반 push

---

## 예외 처리

### 사용자가 명시적으로 요청한 경우
사용자가 다음과 같이 **명시적으로** 요청하면 확인 없이 실행:
- "확인 없이 푸시해줘"
- "바로 푸시"
- "Protected 브랜치에 직접 푸시"

이 경우에도 경고 메시지는 출력:
```
⚠️ Protected 브랜치 main에 직접 푸시합니다.
사용자가 명시적으로 요청하여 확인 절차를 건너뜁니다.
```

---

## 사용 예시

### 시나리오 1: Main 브랜치에서 푸시 시도
```
사용자: "커밋하고 푸시해줘"
Claude: [현재 브랜치 확인 → main]
        [AskUserQuestion으로 확인 요청]
        "⚠️ 현재 main 브랜치입니다. 정말로 직접 푸시하시겠습니까?"
사용자: [취소 선택]
Claude: "푸시가 취소되었습니다. Feature 브랜치를 생성할까요?"
```

### 시나리오 2: Feature 브랜치에서 푸시
```
사용자: "커밋하고 푸시해줘"
Claude: [현재 브랜치 확인 → feature/new-feature]
        [자동 허용 패턴 매칭 성공]
        [확인 없이 바로 실행]
        "feature/new-feature 브랜치에 푸시합니다."
```

### 시나리오 3: Force push 시도
```
사용자: "force push 해줘"
Claude: [현재 브랜치 확인 → feature/test]
        [Force push 감지]
        [AskUserQuestion으로 강화된 경고]
        "🚨 Force push는 히스토리를 덮어씁니다. 실행하시겠습니까?"
사용자: [실행 선택]
Claude: "Force push를 실행합니다."
```

---

## 주의사항

1. **항상 현재 브랜치 먼저 확인**: Push 명령 실행 전 반드시 `git branch --show-current`로 확인
2. **AskUserQuestion 필수 사용**: Protected 브랜치나 force push 시 반드시 사용자 확인
3. **명확한 경고 메시지**: 사용자가 위험성을 이해할 수 있도록 명확한 설명 제공
4. **권장 옵션 표시**: 안전한 옵션을 "(권장)"으로 표시
5. **자동 허용 패턴 정확히 체크**: Feature 브랜치 등은 불필요한 확인 방지

---

## 통합 가이드

이 Rule은 다음 파일들과 함께 작동합니다:
- `orchestration.md`: 작업 모드 선택 (Sequential/Parallel)
- 프로젝트별 `CLAUDE.md`: TDD 워크플로우, 커밋 규칙 등

모든 Rule은 독립적으로 동작하며, 충돌하지 않습니다.
