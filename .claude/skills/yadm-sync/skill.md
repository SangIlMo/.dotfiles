---
name: yadm-sync
description: yadm dotfiles 변경사항 커밋 및 푸시. Use when syncing home directory dotfiles.
version: 1.0.0
---

# yadm-sync — Dotfiles Commit & Push

홈 디렉토리의 yadm 추적 파일 변경사항을 커밋하고 푸시합니다.

## Workflow

1. yadm 상태 확인:
   ```bash
   cd ~ && yadm status --short
   ```
   변경사항이 없으면: "No changes to commit." 출력 후 종료.

2. 변경 내용 확인:
   ```bash
   cd ~ && yadm diff --stat
   ```

3. 변경된 파일만 개별 add (절대 `yadm add -A` 사용 금지 — untracked 파일 스캔으로 타임아웃 발생):
   ```bash
   cd ~ && yadm add <changed-file-1> <changed-file-2> ...
   ```
   삭제된 파일도 동일하게 `yadm add`로 staging.

4. 민감 파일 체크:
   - `.env`, `*.key`, `*.pem`, `credentials*` 파일이 포함되어 있으면 경고 후 제외.

5. Conventional Commits 형식으로 커밋 메시지 작성:
   ```bash
   cd ~ && yadm commit -m "$(cat <<'EOF'
   {type}: {description}

   Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
   EOF
   )"
   ```

6. 푸시 (yadm은 개인 dotfiles이므로 main 직접 push 허용):
   ```bash
   cd ~ && yadm push
   ```

7. 결과 요약:
   ```bash
   cd ~ && yadm log --oneline -1
   ```

## Important Notes

- **절대 `yadm add -A` 사용 금지**: `.vscode/extensions` 등 대량 untracked 파일로 인해 타임아웃됨. 반드시 변경된 파일만 개별 지정.
- yadm push는 git-push-protection 규칙에 따라 main 직접 push 허용 (개인 dotfiles).
- 인자가 주어지면 커밋 메시지로 사용. 없으면 변경 내용을 분석하여 자동 생성.
