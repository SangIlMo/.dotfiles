# yadm Dotfiles Management

## 자동 동기화 체크
도구 설정 추가/수정 시 자동 확인:
1. config 파일이 yadm 추적 중인가? → `yadm list | grep [config]`
2. bootstrap에 설치 단계가 있는가? → 없으면 추가 제안
3. 의존성 순서 올바른가? → brew → 도구 → config
4. `bash -n bootstrap` 문법 체크 통과?

## Bootstrap 멱등성
모든 설치 단계는 `if ! command -v [tool]; then ... fi` 패턴 사용

## git-push-protection 연동
yadm push는 개인 dotfiles이므로 main 직접 push 권장
