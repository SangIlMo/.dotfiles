#!/usr/bin/env python3
"""
Claude Code UserPromptSubmit Hook
Detects Korean phrase '브랜치 변경' (branch change) and provides guidance
for using the /branch-change command.
"""
import json
import sys
from datetime import datetime

def main():
    try:
        # Read JSON input from stdin
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError as e:
        # Invalid JSON - silently exit
        sys.exit(0)

    # Get the user's prompt
    prompt = input_data.get("prompt", "")

    # Check if the Korean phrase is in the prompt
    if "브랜치 변경" in prompt:
        # Get current date in MMDD format
        current_date = datetime.now().strftime("%m%d")

        # Output helpful guidance message
        message = f"""
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌿 브랜치 변경 (Branch Change) 감지
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

오늘 날짜: {current_date}

/branch-change 명령어를 사용하세요:

사용법:
  /branch-change <type> <name>

예시:
  /branch-change feature user-authentication
  → 생성될 브랜치: {current_date}/feature/user-authentication

  /branch-change bugfix login-error
  → 생성될 브랜치: {current_date}/bugfix/login-error

  /branch-change hotfix security-patch
  → 생성될 브랜치: {current_date}/hotfix/security-patch

브랜치 타입:
  • feature  - 새로운 기능
  • bugfix   - 버그 수정
  • hotfix   - 긴급 수정
  • refactor - 리팩토링
  • docs     - 문서 수정

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"""
        print(message)

    # Always exit with 0 (success, don't block)
    sys.exit(0)

if __name__ == "__main__":
    main()
