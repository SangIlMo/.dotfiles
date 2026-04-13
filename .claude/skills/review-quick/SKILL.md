---
name: review-quick
description: Quick parallel code review of staged changes using security-sentinel, performance-oracle, and architecture-strategist agents. Use when the user wants a fast review of staged git changes.
version: 1.0.0
---

# Quick Parallel Review (Staged Changes)

Fast review using Internal Parallel pattern. No team creation, no cross-review.

## Workflow

1. Get staged changes:
   ```bash
   git diff --staged
   git diff --staged --name-only
   ```
   If no staged changes, inform the user and stop.

2. Launch 3 sub-agents in parallel using Task tool (all `model=sonnet`):

   **Task 1 — Security Review:**
   ```
   subagent_type: security-sentinel
   model: sonnet
   prompt: |
     Review the following staged git diff for security vulnerabilities.
     Focus on: injection flaws, auth issues, data exposure, OWASP top 10.

     Changed files: {file_list}

     Diff:
     {diff_content}

     Report findings as JSON array:
     [{"severity": "critical|important|minor", "category": "security", "file": "path", "line": N, "description": "...", "recommendation": "...", "confidence": N}]
     Only report findings with confidence >= 80.
   ```

   **Task 2 — Performance Review:**
   ```
   subagent_type: performance-oracle
   model: sonnet
   prompt: |
     Review the following staged git diff for performance issues.
     Focus on: N+1 queries, algorithm complexity, memory leaks, unnecessary allocations.

     Changed files: {file_list}

     Diff:
     {diff_content}

     Report findings as JSON array:
     [{"severity": "critical|important|minor", "category": "performance", "file": "path", "line": N, "description": "...", "recommendation": "...", "confidence": N}]
     Only report findings with confidence >= 80.
   ```

   **Task 3 — Architecture Review:**
   ```
   subagent_type: architecture-strategist
   model: sonnet
   prompt: |
     Review the following staged git diff for architecture quality.
     Focus on: SOLID violations, coupling, design patterns, code organization.

     Changed files: {file_list}

     Diff:
     {diff_content}

     Report findings as JSON array:
     [{"severity": "critical|important|minor", "category": "architecture", "file": "path", "line": N, "description": "...", "recommendation": "...", "confidence": N}]
     Only report findings with confidence >= 80.
   ```

3. Collect all 3 results and output a summary:

```markdown
# Quick Review (Staged Changes)

## Findings
| # | Severity | Category | File:Line | Description | Recommendation |
|---|----------|----------|-----------|-------------|----------------|
| 1 | critical | security | src/auth.ts:42 | ... | ... |

## Summary
| Reviewer | Critical | Important | Minor |
|----------|----------|-----------|-------|
| Security | N | N | N |
| Performance | N | N | N |
| Architecture | N | N | N |
```

If no findings from any reviewer, output: "No significant issues found."

## Important Notes

- The Leader NEVER reads code files directly. All code analysis is delegated to sub-agents.
- The Leader collects git diff via Bash, then passes diff content in prompts.
- If diff is extremely large (>500 lines), split by file groups and mention to reviewers which files to focus on.
- All reviewer findings must have `confidence >= 80` to be included in the final report.
- Critical findings should only be truly critical issues requiring immediate fixes.
