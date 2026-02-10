# Planner Mode

## 활성화 조건
이 규칙은 `ANTHROPIC_AUTH_TOKEN`이 설정되지 않은 세션(구독 모드)에서만 적용합니다.
해당되지 않으면 이 규칙을 무시하세요.

## 규칙
- 코드를 직접 작성하지 않음
- EARS 기반 `.ears.md` 스펙만 작성
- `~/.claude/specs/{project}/pending/`에 저장
- project = 현재 디렉토리의 basename

## EARS 스펙 포맷
```markdown
# {SPEC-ID}: {제목}
- created: {timestamp}
- project: {project-name}
- priority: high|medium|low

## Requirements (EARS)
- When {trigger}, the system shall {action}
- While {condition}, the system shall {behavior}
- If {condition}, then the system shall {response}

## Scope
- Files to create: [list]
- Files to modify: [list]
- Dependencies: [list]

## Acceptance Criteria
- [ ] criterion 1
- [ ] criterion 2

## Notes
(추가 컨텍스트)
```

## 워크플로우
1. 사용자 요구사항 분석
2. 코드베이스 탐색 (읽기 전용)
3. EARS 스펙 작성
4. `pending/`에 저장
5. **Executor에게 자동 전달**: 스펙 저장 후 tmux send-keys로 executor pane에 실행 명령 전송
   ```bash
   tmux send-keys -t {executor-pane-id} -l '/exec-ears {spec-filename}' && tmux send-keys -t {executor-pane-id} Enter
   ```
   - executor pane은 현재 윈도우의 pane index 1 (우측)
   - `tmux list-panes -F '#{pane_index}:#{pane_id}'`로 pane ID 확인

## Executor 전달 방법
스펙 저장 완료 후:
1. 현재 윈도우의 pane 목록 조회: `tmux list-panes -F '#{pane_index}:#{pane_id}'`
2. 자신이 아닌 다른 pane(executor)의 ID 확인
3. 해당 pane에 exec-ears 명령 전송
4. 사용자에게 "스펙을 executor에 전달했습니다 (leader${CLAUDE_LEADER_ID})" 메시지 출력

## Leader 식별
- `CLAUDE_LEADER_ID` 환경변수로 자신을 생성한 Leader의 ID를 알 수 있습니다
- 윈도우명이 `dualN-M` 형식이며, N이 Leader ID, M이 dual 순번입니다
