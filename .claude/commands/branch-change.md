---
description: Create and checkout git branch with mmdd/{type}/{name} format
argument-hint: [type] [name]
---

# Create New Git Branch

Create a new git branch with the format: `mmdd/{type}/{name}` where mmdd is the current month and day.

## Current Branch
!`git branch --show-current`

## Instructions

When the user invokes this command with arguments:

1. **Get current date in MMDD format**
   - Use current date to generate MMDD format (e.g., December 26 = 1226, January 5 = 0105)

2. **Parse arguments**
   - First argument ($1): branch type
   - Remaining arguments ($2...): branch name (join with hyphens if multiple words)

3. **Validate branch type**
   - Must be one of: `feature`, `bugfix`, `hotfix`, `refactor`, `docs`
   - If invalid, show error with list of valid types

4. **Sanitize branch name**
   - Convert to lowercase
   - Replace spaces with hyphens
   - Remove special characters except hyphens and numbers
   - Join multiple arguments with hyphens

5. **Create the branch**
   - Format: `{mmdd}/{type}/{name}`
   - Example: `1226/feature/user-authentication`
   - Run: `git branch {mmdd}/{type}/{name}`

6. **Checkout the branch**
   - Run: `git checkout {mmdd}/{type}/{name}`

7. **Confirm**
   - Show the new branch name
   - Run: `git branch --show-current`

## Example Usage

```
/branch-change feature user-authentication
```
Creates and checks out: `1226/feature/user-authentication`

```
/branch-change bugfix login error
```
Creates and checks out: `1226/bugfix/login-error`

```
/branch-change hotfix critical-security-patch
```
Creates and checks out: `1226/hotfix/critical-security-patch`

## Valid Branch Types

- **feature**: New features or enhancements
- **bugfix**: Bug fixes
- **hotfix**: Critical production fixes
- **refactor**: Code refactoring
- **docs**: Documentation updates

## Error Handling

- If not in a git repository, show error
- If branch already exists, show error with existing branch name
- If no arguments provided, prompt for type and name
- If invalid type, show valid types list
