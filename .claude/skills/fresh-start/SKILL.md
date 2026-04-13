---
name: fresh-start
description: Checkout to main branch and pull latest changes. Use when starting a new task or work session.
version: 1.0.0
---

# Fresh Start — New Work Session

Checkout to main branch and pull latest changes from remote. Perfect for starting a fresh task or work session.

## Workflow

1. Check if current directory is a git repository:
   ```bash
   git rev-parse --git-dir > /dev/null 2>&1
   ```
   If not, inform the user: "Not a git repository. Cannot proceed."

2. Get current branch name:
   ```bash
   git branch --show-current
   ```

3. Check for uncommitted changes:
   ```bash
   git status --porcelain
   ```
   If there are uncommitted changes, ask the user:
   ```
   You have uncommitted changes. Options:
   1. Stash changes (git stash)
   2. Discard changes (git reset --hard)
   3. Cancel and handle manually

   Which option? (1/2/3)
   ```

4. Checkout to main branch (try common names):
   ```bash
   git checkout main 2>/dev/null || git checkout master 2>/dev/null || git checkout dev 2>/dev/null || {
     echo "No main/master/dev branch found. Available branches:"
     git branch -a
     exit 1
   }
   ```

5. Pull latest changes:
   ```bash
   git pull origin $(git branch --show-current)
   ```

6. Show summary:
   ```bash
   echo "✓ Now on $(git branch --show-current)"
   echo "✓ Latest changes pulled"
   echo ""
   git log -1 --oneline
   echo ""
   echo "Ready for a fresh start! 🚀"
   ```

## Important Notes

- If git pull fails (e.g., diverged branches), inform the user and suggest manual resolution.
- If the user chose to stash changes in step 3, remind them: "Your changes are stashed. Use `git stash pop` to restore."
- This skill respects git-push-protection rules — main is a protected branch but checkout/pull is allowed.
