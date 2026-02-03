#!/bin/bash
# Specification Status Report
# Shows overall status of all specifications in the project

set -e

SPEC_DIR="${1:-.spec}"

if [ ! -d "$SPEC_DIR" ]; then
    echo "Error: Specification directory not found: $SPEC_DIR"
    echo "Usage: $0 [spec-directory]"
    exit 1
fi

echo "Specification Status Report"
echo "========================================"
echo "Directory: $SPEC_DIR"
echo "Generated: $(date)"
echo "========================================"
echo

# Check for constitution
echo "Constitution"
echo "------------"
if [ -f "$SPEC_DIR/constitution.md" ]; then
    WORD_COUNT=$(wc -w < "$SPEC_DIR/constitution.md")
    echo "✓ Present ($WORD_COUNT words)"

    # Quick validation
    if command -v "$HOME/.claude/skills/specify-planning/scripts/validate-constitution.sh" &> /dev/null; then
        VALIDATION=$("$HOME/.claude/skills/specify-planning/scripts/validate-constitution.sh" "$SPEC_DIR/constitution.md" 2>&1 | grep "Validation" | tail -1)
        echo "  $VALIDATION"
    fi
else
    echo "✗ Not found"
    echo "  Run: /specify-constitution"
fi
echo

# Check features
echo "Features"
echo "--------"

if [ ! -d "$SPEC_DIR/features" ]; then
    echo "No features directory found"
    echo "  Run: /specify-requirements <feature-name>"
    exit 0
fi

FEATURE_COUNT=$(find "$SPEC_DIR/features" -maxdepth 1 -type d | tail -n +2 | wc -l)

if [ "$FEATURE_COUNT" -eq 0 ]; then
    echo "No features found"
    echo "  Run: /specify-requirements <feature-name>"
    exit 0
fi

echo "Total features: $FEATURE_COUNT"
echo

# Iterate through features
for feature_dir in "$SPEC_DIR/features"/*; do
    if [ ! -d "$feature_dir" ]; then
        continue
    fi

    FEATURE_NAME=$(basename "$feature_dir")
    echo "Feature: $FEATURE_NAME"
    echo "  Path: $feature_dir"

    # Check specification
    if [ -f "$feature_dir/specification.md" ]; then
        SPEC_WORDS=$(wc -w < "$feature_dir/specification.md")

        # Check status in file
        STATUS=$(grep "^\\*\\*Status\\*\\*:" "$feature_dir/specification.md" | head -1 | sed 's/.*: //' || echo "Unknown")

        # Check for open questions
        OPEN_QUESTIONS=$(grep -c "\[NEEDS CLARIFICATION\]" "$feature_dir/specification.md" || echo "0")

        echo "  Specification: ✓ ($SPEC_WORDS words, Status: $STATUS)"
        if [ "$OPEN_QUESTIONS" -gt 0 ]; then
            echo "    ⚠️  $OPEN_QUESTIONS open questions"
        fi
    else
        echo "  Specification: ✗ Missing"
    fi

    # Check plan
    if [ -f "$feature_dir/plan.md" ]; then
        PLAN_WORDS=$(wc -w < "$feature_dir/plan.md")
        PLAN_STATUS=$(grep "^\\*\\*Status\\*\\*:" "$feature_dir/plan.md" | head -1 | sed 's/.*: //' || echo "Unknown")
        echo "  Plan: ✓ ($PLAN_WORDS words, Status: $PLAN_STATUS)"
    else
        echo "  Plan: ✗ Missing"
        if [ -f "$feature_dir/specification.md" ]; then
            echo "    → Run: /specify-plan $FEATURE_NAME"
        fi
    fi

    # Check tasks
    if [ -f "$feature_dir/tasks.md" ]; then
        TASK_WORDS=$(wc -w < "$feature_dir/tasks.md")
        TASK_COUNT=$(grep -c "^#### Task [0-9]" "$feature_dir/tasks.md" || echo "0")
        TASKS_STATUS=$(grep "^\\*\\*Status\\*\\*:" "$feature_dir/tasks.md" | head -1 | sed 's/.*: //' || echo "Unknown")

        # Count completed tasks
        COMPLETED=$(grep -c "^\- \[x\].*Task [0-9]" "$feature_dir/tasks.md" || echo "0")

        echo "  Tasks: ✓ ($TASK_COUNT tasks, $COMPLETED completed, Status: $TASKS_STATUS)"
    else
        echo "  Tasks: ✗ Missing"
        if [ -f "$feature_dir/plan.md" ]; then
            echo "    → Run: /specify-tasks $FEATURE_NAME"
        fi
    fi

    # Check validation results
    if [ -d "$feature_dir/validation" ]; then
        VALIDATION_COUNT=$(find "$feature_dir/validation" -type f | wc -l)
        echo "  Validation: ✓ ($VALIDATION_COUNT reports)"
    fi

    # Check git branch
    if git rev-parse --git-dir > /dev/null 2>&1; then
        BRANCH_PATTERN="feature.*$FEATURE_NAME"
        if git branch | grep -q "$FEATURE_NAME"; then
            BRANCH=$(git branch | grep "$FEATURE_NAME" | sed 's/^[* ]*//')
            echo "  Git Branch: ✓ ($BRANCH)"
        else
            echo "  Git Branch: ✗ Not found"
        fi
    fi

    echo
done

# Summary statistics
echo "========================================"
echo "Summary"
echo "========================================"

SPECS_COUNT=$(find "$SPEC_DIR/features" -name "specification.md" 2>/dev/null | wc -l)
PLANS_COUNT=$(find "$SPEC_DIR/features" -name "plan.md" 2>/dev/null | wc -l)
TASKS_COUNT=$(find "$SPEC_DIR/features" -name "tasks.md" 2>/dev/null | wc -l)

echo "Specifications: $SPECS_COUNT"
echo "Plans:          $PLANS_COUNT"
echo "Task Breakdowns: $TASKS_COUNT"

# Completion percentage
if [ "$FEATURE_COUNT" -gt 0 ]; then
    SPEC_PCT=$((SPECS_COUNT * 100 / FEATURE_COUNT))
    PLAN_PCT=$((PLANS_COUNT * 100 / FEATURE_COUNT))
    TASKS_PCT=$((TASKS_COUNT * 100 / FEATURE_COUNT))

    echo
    echo "Completion:"
    echo "  Specifications: $SPEC_PCT%"
    echo "  Plans:          $PLAN_PCT%"
    echo "  Tasks:          $TASKS_PCT%"
fi

echo
echo "Overall Health:"
if [ "$SPECS_COUNT" -eq "$FEATURE_COUNT" ] && [ "$PLANS_COUNT" -eq "$FEATURE_COUNT" ] && [ "$TASKS_COUNT" -eq "$FEATURE_COUNT" ]; then
    echo "✓ All features have complete documentation"
elif [ "$SPECS_COUNT" -eq "$FEATURE_COUNT" ]; then
    echo "⚠️  All features have specifications, but planning/tasks are incomplete"
else
    echo "⚠️  Some features are missing specifications"
fi

echo
