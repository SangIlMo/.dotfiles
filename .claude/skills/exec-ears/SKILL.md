---
name: exec-ears
description: pending EARS 스펙을 선택하여 구현 실행
user-invocable: true
argument: (선택) 특정 스펙 파일명
---

# /exec-ears

pending 스펙을 실행합니다.

## Instructions

1. 현재 프로젝트의 pending 스펙을 확인합니다:
   ```bash
   PROJECT=$(basename "$PWD")
   ls ~/.claude/specs/$PROJECT/pending/
   ```
2. 스펙이 여러 개면 목록을 보여주고 AskUserQuestion으로 선택받습니다
3. 인자로 특정 스펙이 지정되면 해당 스펙을 바로 실행합니다
4. 선택된 스펙을 `doing/`으로 이동합니다:
   ```bash
   mv ~/.claude/specs/$PROJECT/pending/{spec} ~/.claude/specs/$PROJECT/doing/
   ```
5. 스펙 파일을 읽고 Requirements, Scope, Acceptance Criteria에 따라 구현합니다
6. 구현 완료 후 스펙 파일 하단에 실행 결과를 추가합니다:
   ```markdown
   ## Execution Result
   - completed: {timestamp}
   - status: success|partial|failed
   - Changes: [list of files changed]
   - Notes: (실행 중 발견된 사항)
   ```
7. 스펙을 `done/`으로 이동합니다:
   ```bash
   mv ~/.claude/specs/$PROJECT/doing/{spec} ~/.claude/specs/$PROJECT/done/
   ```
8. **Leader에게 완료 알림 전송**:
   ```bash
   # 현재 세션의 모든 pane에서 leader(leader-* 윈도우) 찾기
   LEADER_PANE=$(tmux list-panes -s -F '#{window_name}:#{pane_id}' | grep '^leader' | head -1 | cut -d: -f2)
   if [ -n "$LEADER_PANE" ]; then
     tmux send-keys -t "$LEADER_PANE" -l "EARS 스펙 완료: {spec-id}. /specs-status 로 확인 후 /review-quick 으로 검증하세요." && tmux send-keys -t "$LEADER_PANE" Enter
   fi
   ```

## 주의사항
- 스펙의 Scope에 명시된 파일만 수정합니다
- Acceptance Criteria를 모두 충족하는지 확인합니다
- 테스트가 있으면 실행하여 검증합니다
- 완료 후 반드시 Leader에게 알림을 보냅니다
