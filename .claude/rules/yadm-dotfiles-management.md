# yadm Dotfiles Management Rule

## 목적
yadm 작업 시 bootstrap 스크립트와 config 파일의 동기화를 자동으로 확인하고, 새 환경에서의 이식성을 보장합니다.

---

## 트리거 조건

### 자동 감지 키워드

| 패턴 | 키워드/표현 | 예시 요청 |
|------|-------------|-----------|
| **도구 추가** | "설치", "setup", "dotfile 추가", "config 추가" | "starship config를 dotfiles에 추가해줘" |
| **Bootstrap 수정** | "bootstrap", "설치 스크립트", "초기 설정" | "bootstrap에 fzf 설치 추가해줘" |
| **환경 이식** | "새 맥", "재설치", "환경 복원", "동기화" | "새 맥에서 환경 재현 가능한지 확인해줘" |
| **yadm 관리** | "yadm add", "yadm commit", "dotfiles 관리" | "yadm으로 zshrc 추적해줘" |

### 트리거 시 자동 수행

1. **config 파일 추가 시** → bootstrap에 대응하는 설치 단계가 있는지 확인
2. **bootstrap 수정 시** → 대응하는 config 파일이 yadm 추적 중인지 확인
3. **도구 설치/설정 요청 시** → config + bootstrap 양쪽 모두 갱신 필요 여부 확인

---

## Bootstrap 동기화 체크리스트

Claude가 yadm 관련 작업 시 자동으로 수행하는 체크리스트:

### ✅ 필수 확인 항목

```pseudo
함수 yadmSyncCheck(tool, configFile):
    1. 도구가 bootstrap에 설치 단계가 있는가?
       → 없으면: "bootstrap에 [tool] 설치 단계를 추가할까요?" 제안

    2. 의존성 도구도 bootstrap에 있는가?
       → 예: starship → 의존성: brew, nerd-font
       → 없으면: 의존성 설치 단계 추가 제안

    3. 설치 순서가 의존성 순서를 따르는가?
       → 예: brew → git → tool → config 복사 순서
       → 순서 오류 시: 수정 제안

    4. config 파일을 yadm add로 추적 중인가?
       → yadm list | grep [configFile]
       → 추적 안 되면: "yadm add [configFile]" 제안

    5. bash -n bootstrap 문법 체크 통과하는가?
       → 실패 시: 문법 오류 위치 표시 및 수정 제안
```

### 확인 실행 명령

```bash
# bootstrap 파일 위치 확인
yadm bootstrap

# 현재 추적 중인 파일 목록
yadm list

# bootstrap 문법 체크
bash -n ~/.config/yadm/bootstrap

# config 파일 추적 여부 확인
yadm list | grep -i [config-name]
```

---

## 설치 패턴 템플릿

### 도구 타입별 Bootstrap 패턴

| 도구 타입 | 설치 방법 | 체크 조건 | Bootstrap 예시 |
|----------|----------|----------|----------------|
| CLI 도구 | `brew install` | `command -v [tool]` | `brew install fzf` |
| GUI 앱 | `brew install --cask` | `/Applications/[App].app` | `brew install --cask iterm2` |
| 플러그인 | `git clone` | 디렉토리 존재 여부 | `git clone ... ~/.oh-my-zsh/plugins/` |
| Script | `curl \| sh` | `command -v [tool]` | `curl -sS https://... \| sh` |
| 언어 도구 | `pip/npm/cargo install` | `command -v [tool]` | `pip install black` |

### 멱등성(Idempotent) 패턴

Bootstrap은 반복 실행에 안전해야 합니다:

```bash
# ✅ GOOD: 멱등성 보장
if ! command -v fzf &>/dev/null; then
    brew install fzf
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
fi

# ❌ BAD: 중복 설치 시 에러
brew install fzf
git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
```

---

## 불일치 감지

### Config ↔ Bootstrap 정합성 검증

```pseudo
함수 detectMismatch():
    trackedConfigs = yadm list로 추적 중인 config 파일 목록
    bootstrapTools = bootstrap에서 설치하는 도구 목록

    // Case 1: config는 있는데 bootstrap에 없음
    for config in trackedConfigs:
        tool = configToTool(config)  // 예: .config/starship.toml → starship
        if tool not in bootstrapTools:
            ⚠️ "config가 추적되지만 bootstrap에 설치 단계가 없습니다."
            → "bootstrap에 [tool] 설치 단계를 추가할까요?" 제안

    // Case 2: bootstrap에 있는데 config가 없음
    for tool in bootstrapTools:
        expectedConfig = toolToConfig(tool)
        if expectedConfig and expectedConfig not in trackedConfigs:
            ⚠️ "bootstrap에 설치 단계가 있지만 config 파일이 추적되지 않습니다."
            → "yadm add [config] 실행할까요?" 제안
```

### 일반적인 도구-Config 매핑

| 도구 | Config 파일 경로 |
|------|------------------|
| zsh | `~/.zshrc`, `~/.zshenv` |
| starship | `~/.config/starship.toml` |
| tmux | `~/.tmux.conf` |
| vim/neovim | `~/.vimrc`, `~/.config/nvim/init.lua` |
| git | `~/.gitconfig`, `~/.gitignore_global` |
| alacritty | `~/.config/alacritty/alacritty.toml` |
| fzf | `~/.fzf.zsh`, `~/.fzf.bash` |
| bat | `~/.config/bat/config` |
| lazygit | `~/.config/lazygit/config.yml` |

---

## 기존 Rule 통합

### auto-commit-after-tests.md 통합

Bootstrap 수정 후 문법 검증을 "테스트"로 취급:

```pseudo
1. bootstrap 수정 완료
2. bash -n bootstrap 실행 (문법 체크)
3. 문법 체크 통과 → auto-commit-after-tests 트리거
4. "✅ bootstrap 문법 체크 통과! 변경사항을 커밋하시겠습니까?"
```

### git-push-protection.md 통합

yadm dotfiles repo의 특성 반영:

- yadm repo는 일반적으로 **main 브랜치에 직접 push** (개인 dotfiles)
- `yadm push` 시 protected 브랜치 경고를 **완화** (확인은 하되 권장 옵션 변경)

```json
{
  "questions": [{
    "question": "yadm dotfiles를 main 브랜치에 푸시하시겠습니까?",
    "header": "yadm Push",
    "options": [
      {
        "label": "푸시 실행 (권장)",
        "description": "개인 dotfiles repo이므로 main 직접 푸시 일반적"
      },
      {
        "label": "취소",
        "description": "푸시하지 않음"
      }
    ],
    "multiSelect": false
  }]
}
```

### orchestration.md 통합

- yadm 작업은 기본 **Sequential** 모드 (config → bootstrap → 검증 순서 의존성)
- 단, 환경 재현 검증(yadm list vs bootstrap 일치 검증)은 **Internal Parallel** 가능

---

## 사용 시나리오

### 시나리오 1: 새 도구 설정 추가

```
사용자: "starship 설정을 dotfiles에 추가해줘"

Claude: 🤖 자동 모드 선택: Sequential
        이유: config → bootstrap → 검증 순서 의존성

        [Step 1] starship config 확인
        → ~/.config/starship.toml 존재 확인

        [Step 2] yadm 추적 여부 확인
        → yadm list | grep starship
        → ❌ 추적 안 됨
        → yadm add ~/.config/starship.toml 실행

        [Step 3] bootstrap 동기화 확인
        → bootstrap에 starship 설치 단계 있는가?
        → ❌ 없음

        ⚠️ Bootstrap 불일치 감지:
        - config: ~/.config/starship.toml (추적 중)
        - bootstrap: starship 설치 단계 없음

        bootstrap에 다음 설치 단계를 추가할까요?

        ```bash
        # Starship prompt
        if ! command -v starship &>/dev/null; then
            brew install starship
        fi
        ```

사용자: "응, 추가해줘"

Claude: [bootstrap 수정]
        [bash -n bootstrap → 문법 체크 통과]
        ✅ bootstrap 문법 체크 통과!
        변경사항을 커밋하시겠습니까?
```

### 시나리오 2: Bootstrap만 수정

```
사용자: "bootstrap에 ripgrep 설치 추가해줘"

Claude: 🤖 자동 모드 선택: Sequential
        이유: bootstrap 수정 → 검증 순서 의존성

        [Step 1] bootstrap에 ripgrep 설치 단계 추가
        ```bash
        if ! command -v rg &>/dev/null; then
            brew install ripgrep
        fi
        ```

        [Step 2] 문법 체크
        → bash -n bootstrap → ✅ 통과

        [Step 3] 대응 config 확인
        → ripgrep config 파일: ~/.config/ripgrep/config (선택적)
        → ℹ️ ripgrep config는 선택사항입니다.
           커스텀 설정이 있으면 추가할 수 있습니다.

        ✅ bootstrap 수정 완료!
        변경사항을 커밋하시겠습니까?
```

### 시나리오 3: 환경 재현 검증

```
사용자: "새 맥에서 환경 재현 가능한지 확인해줘"

Claude: 🤖 자동 모드 선택: Internal Parallel
        이유: 독립적인 검증 작업, 병렬 처리 가능

        [Agent 1] yadm list 분석 → 추적 중인 config 파일 목록
        [Agent 2] bootstrap 분석 → 설치하는 도구 목록
        [Agent 3] 의존성 순서 검증

        📋 환경 재현 검증 결과:

        ✅ 정상 (12개):
        - zsh: config ✅ bootstrap ✅
        - starship: config ✅ bootstrap ✅
        - tmux: config ✅ bootstrap ✅
        [...]

        ⚠️ 불일치 (2개):
        - bat: config ✅ bootstrap ❌
          → bootstrap에 `brew install bat` 추가 필요
        - lazygit: bootstrap ✅ config ❌
          → config 파일이 추적되지 않음

        ❌ 의존성 순서 문제 (1개):
        - oh-my-zsh 플러그인이 oh-my-zsh 설치보다 먼저 위치

        수정을 진행할까요?
```

---

## 주의사항

1. **멱등성 필수**: bootstrap의 모든 설치 단계는 반복 실행에 안전해야 함
2. **의존성 순서**: brew → 기본 도구 → 플러그인 → config 적용 순서 유지
3. **민감 정보 주의**: `.env`, API 키 등은 yadm encrypt 사용 권장
4. **OS 분기 처리**: macOS/Linux 분기가 필요한 설치는 `uname` 체크 포함
5. **문법 체크 필수**: bootstrap 수정 후 반드시 `bash -n` 실행

---

**Last Updated**: 2026-02-06
**Version**: 1.0.0
**Status**: Production Ready ✅
