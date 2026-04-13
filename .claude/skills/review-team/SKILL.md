---
name: review-team
description: Full team code review with cross-review using security-sentinel, performance-oracle, and architecture-strategist agents as a coordinated team. Use when the user wants a thorough review with inter-reviewer discussion. Accepts optional target argument (file path, directory, or git range like main..HEAD).
version: 1.0.0
---

# Full Team Review with Cross-Review

Deep review using Agent Teams pattern with inter-reviewer discussion.

## Arguments
- `target` (optional): git diff target. Examples:
  - (empty) → `git diff HEAD`
  - `main..HEAD` → git range
  - `src/` → directory filter
  - `path/to/file.ts` → specific file

## Workflow

**Step 0 — Prepare diff:**
```bash
# Default (no target):
git diff HEAD
git diff HEAD --name-only

# With git range target (contains ".."):
git diff {target}
git diff {target} --name-only

# With file/directory target:
git diff HEAD -- {target}
git diff HEAD --name-only -- {target}
```
If no changes found, inform the user and stop.

**Step 1 — Create team:**
```
TeamCreate(team_name="code-review", description="Code review team")
```

**Step 2 — Create tasks:**
```
TaskCreate(subject="Security review", description="Analyze diff for security vulnerabilities", activeForm="Reviewing security")
TaskCreate(subject="Performance review", description="Analyze diff for performance issues", activeForm="Reviewing performance")
TaskCreate(subject="Architecture review", description="Analyze diff for architecture quality", activeForm="Reviewing architecture")
```

**Step 3 — Spawn teammates (parallel):**

All three use `model=sonnet`.

```
Task(subagent_type=security-sentinel, team_name=code-review, name=security, model=sonnet, mode=bypassPermissions)
  prompt: |
    You are the security reviewer on a code review team.

    ## Phase 1: Independent Analysis
    Review the diff below for security vulnerabilities (injection, auth, data exposure, OWASP top 10).
    When done, send your findings to the leader using SendMessage.
    Format findings as:
    [{"severity": "critical|important|minor", "category": "security", "file": "path", "line": N, "description": "...", "recommendation": "...", "confidence": N}]
    Only include confidence >= 80.

    ## Phase 2: Cross-Review
    After the leader shares other reviewers' findings with you, review them from a security perspective.
    Specifically look for:
    - Performance optimizations that might introduce security risks
    - Architecture changes that affect security boundaries
    Send your cross-review insights to the leader.

    Changed files: {file_list}
    Diff: {diff_content}

Task(subagent_type=performance-oracle, team_name=code-review, name=performance, model=sonnet, mode=bypassPermissions)
  prompt: |
    You are the performance reviewer on a code review team.

    ## Phase 1: Independent Analysis
    Review the diff below for performance issues (N+1 queries, complexity, memory leaks, allocations).
    When done, send your findings to the leader using SendMessage.
    Format findings as:
    [{"severity": "critical|important|minor", "category": "performance", "file": "path", "line": N, "description": "...", "recommendation": "...", "confidence": N}]
    Only include confidence >= 80.

    ## Phase 2: Cross-Review
    After the leader shares other reviewers' findings with you, review them from a performance perspective.
    Specifically look for:
    - Security mitigations that might cause performance degradation
    - Architecture changes that affect performance characteristics
    Send your cross-review insights to the leader.

    Changed files: {file_list}
    Diff: {diff_content}

Task(subagent_type=architecture-strategist, team_name=code-review, name=architecture, model=sonnet, mode=bypassPermissions)
  prompt: |
    You are the architecture reviewer on a code review team.

    ## Phase 1: Independent Analysis
    Review the diff below for architecture quality (SOLID, coupling, patterns, organization).
    When done, send your findings to the leader using SendMessage.
    Format findings as:
    [{"severity": "critical|important|minor", "category": "architecture", "file": "path", "line": N, "description": "...", "recommendation": "...", "confidence": N}]
    Only include confidence >= 80.

    ## Phase 2: Cross-Review
    After the leader shares other reviewers' findings with you, review them from an architecture perspective.
    Specifically look for:
    - How security and performance findings affect overall system structure
    - Whether proposed fixes align with existing architecture patterns
    Send your cross-review insights to the leader.

    Changed files: {file_list}
    Diff: {diff_content}
```

**Step 4 — Phase 1 (Independent Analysis):**
Wait for all 3 teammates to send their findings via SendMessage. Collect all findings.

**Step 5 — Phase 2 (Cross-Review):**
Share collected findings with each reviewer:
```
SendMessage(type=message, recipient=security, content="Here are findings from other reviewers for cross-review:\n\nPerformance: {perf_findings}\nArchitecture: {arch_findings}\n\nPlease review from security perspective and send insights.")
SendMessage(type=message, recipient=performance, content="Here are findings from other reviewers for cross-review:\n\nSecurity: {sec_findings}\nArchitecture: {arch_findings}\n\nPlease review from performance perspective and send insights.")
SendMessage(type=message, recipient=architecture, content="Here are findings from other reviewers for cross-review:\n\nSecurity: {sec_findings}\nPerformance: {perf_findings}\n\nPlease review from architecture perspective and send insights.")
```
Wait for all 3 cross-review responses.

**Step 6 — Phase 3 (Final Report):**
Generate the integrated report:

```markdown
# Code Review Report

## Critical Findings (즉시 수정 필요)
| # | Category | File:Line | Description | Cross-review |
|---|----------|-----------|-------------|--------------|
| 1 | security | src/auth.ts:42 | SQL injection risk | [perf] query change adds latency |

## Important Findings
| # | Category | File:Line | Description | Cross-review |
|---|----------|-----------|-------------|--------------|

## Minor Findings
| # | Category | File:Line | Description |
|---|----------|-----------|-------------|

## Cross-Review Insights
- [security x performance] "This query optimization removes parameterized queries — injection risk"
- [performance x security] "Adding JWT validation on every request — consider caching tokens"
- [architecture x security] "New service boundary needs auth middleware"

## Summary
| Reviewer | Critical | Important | Minor |
|----------|----------|-----------|-------|
| Security | N | N | N |
| Performance | N | N | N |
| Architecture | N | N | N |

Total cross-review insights: N
```

**Step 7 — Cleanup:**
```
SendMessage(type=shutdown_request, recipient=security)
SendMessage(type=shutdown_request, recipient=performance)
SendMessage(type=shutdown_request, recipient=architecture)
TeamDelete()
```
Mark all tasks as completed before shutdown.

## Important Notes

- The Leader NEVER reads code files directly. All code analysis is delegated to teammates.
- The Leader collects git diff via Bash, then passes diff content in prompts.
- If diff is extremely large (>500 lines), split by file groups and mention to reviewers which files to focus on.
- All reviewer findings must have `confidence >= 80` to be included in the final report.
- Critical findings should only be truly critical issues requiring immediate fixes.
