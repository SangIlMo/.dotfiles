---
name: sync-main
description: Merge or rebase current branch with origin/main. Use when you want to sync your current branch with the latest main branch.
version: 1.0.0
---

# Sync Main — Sync Current Branch with Origin/Main

Apply origin/main changes to your current branch. Choose between merge or rebase workflow.

## Workflow

1. Check if current directory is a git repository:
   ```bash
   git rev-parse --git-dir > /dev/null 2>&1
   ```
   If not, inform the user: "Not a git repository. Cannot proceed."

2. Fetch latest changes from remote:
   ```bash
   git fetch origin
   ```

3. Get current branch name:
   ```bash
   git branch --show-current
   ```

4. Check for uncommitted changes:
   ```bash
   git status --porcelain
   ```
   If there are uncommitted changes, inform the user:
   ```
   You have uncommitted changes. Please commit or stash them first.
   Use: git commit / git stash
   ```

5. Ask user which method to use:
   ```
   How do you want to sync with origin/main?

   1. Merge (merge origin/main into current branch)
   2. Rebase (rebase current branch on top of origin/main)
   3. Reset (hard reset to origin/main — WARNING: discards local changes)

   Which option? (1/2/3)
   ```

6. Execute based on user choice:

   **Option 1 — Merge:**
   ```bash
   git merge origin/main
   ```

   **Option 2 — Rebase:**
   ```bash
   git rebase origin/main
   ```
   If rebase fails with conflicts, inform the user:
   ```
   Rebase conflict detected. Fix conflicts and:
   - git add <resolved files>
   - git rebase --continue
   Or abort with: git rebase --abort
   ```

   **Option 3 — Reset:**
   ```bash
   git reset --hard origin/main
   ```

7. Show summary:
   ```bash
   echo "✓ Synced with origin/main"
   echo "Current branch: $(git branch --show-current)"
   echo ""
   git log -3 --oneline
   ```

## Important Notes

- **Merge**: Creates a merge commit, preserves full history. Good for teams.
- **Rebase**: Linear history, cleaner but rewrites history. Use with caution on shared branches.
- **Reset**: Destroys local commits not in origin/main. Only for personal/feature branches.
- If merge/rebase has conflicts, help the user resolve them interactively.
