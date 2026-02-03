#!/bin/bash
# Specification Validation Script
# Checks specification completeness, format, and quality

set -e

SPEC_FILE="$1"

if [ -z "$SPEC_FILE" ]; then
    echo "Usage: $0 <specification-file>"
    exit 1
fi

if [ ! -f "$SPEC_FILE" ]; then
    echo "Error: File not found: $SPEC_FILE"
    exit 1
fi

echo "Validating specification: $SPEC_FILE"
echo "========================================"
echo

# Initialize counters
ERRORS=0
WARNINGS=0
INFO=0

# Required sections check
echo "Checking required sections..."
REQUIRED_SECTIONS=(
    "Overview"
    "What are we building"
    "Why are we building it"
    "Success Criteria"
    "User Stories"
    "Functional Requirements"
    "Must Have (P0)"
    "Non-Functional Requirements"
    "Performance"
    "Security"
)

for section in "${REQUIRED_SECTIONS[@]}"; do
    if ! grep -q "^##.*$section" "$SPEC_FILE"; then
        echo "❌ ERROR: Missing required section: $section"
        ((ERRORS++))
    else
        echo "✓ Found: $section"
    fi
done
echo

# Check for implementation details (anti-pattern)
echo "Checking for implementation details (should not be in spec)..."
IMPL_KEYWORDS=(
    "class "
    "function "
    "database table"
    "API endpoint"
    "import "
    "const "
    "def "
    "interface "
)

IMPL_FOUND=0
for keyword in "${IMPL_KEYWORDS[@]}"; do
    count=$(grep -ci "$keyword" "$SPEC_FILE" || echo "0")
    if [ "$count" -gt 0 ]; then
        echo "⚠️  WARNING: Found implementation keyword '$keyword' ($count times)"
        ((WARNINGS++))
        IMPL_FOUND=1
    fi
done

if [ $IMPL_FOUND -eq 0 ]; then
    echo "✓ No implementation details found"
fi
echo

# Check for unresolved questions
echo "Checking for unresolved questions..."
OPEN_QUESTIONS=$(grep -c "\[NEEDS CLARIFICATION\]" "$SPEC_FILE" || echo "0")

if [ "$OPEN_QUESTIONS" -gt 0 ]; then
    echo "⚠️  WARNING: $OPEN_QUESTIONS unresolved questions found"
    echo "Questions:"
    grep "\[NEEDS CLARIFICATION\]" "$SPEC_FILE" | sed 's/^/  - /'
    ((WARNINGS++))
else
    echo "✓ No unresolved questions"
fi
echo

# Check for measurable success criteria
echo "Checking for measurable success criteria..."
if grep -q "Success Criteria" "$SPEC_FILE"; then
    # Look for metrics (numbers, percentages, time units)
    METRICS_FOUND=$(grep -A 10 "Success Criteria" "$SPEC_FILE" | grep -E "([0-9]+%|[0-9]+ users|[0-9]+ms|< [0-9]+|> [0-9]+)" | wc -l)
    if [ "$METRICS_FOUND" -lt 3 ]; then
        echo "⚠️  WARNING: Success criteria may not be measurable (found $METRICS_FOUND metrics)"
        ((WARNINGS++))
    else
        echo "✓ Success criteria appear measurable ($METRICS_FOUND metrics found)"
    fi
else
    echo "❌ ERROR: Success Criteria section missing"
    ((ERRORS++))
fi
echo

# Check for acceptance criteria in user stories
echo "Checking user story acceptance criteria..."
if grep -q "User Stories" "$SPEC_FILE"; then
    ACCEPTANCE_CRITERIA=$(grep -c "Acceptance Criteria" "$SPEC_FILE" || echo "0")
    if [ "$ACCEPTANCE_CRITERIA" -eq 0 ]; then
        echo "⚠️  WARNING: No acceptance criteria found in user stories"
        ((WARNINGS++))
    else
        echo "✓ Found $ACCEPTANCE_CRITERIA acceptance criteria sections"
    fi
else
    echo "❌ ERROR: User Stories section missing"
    ((ERRORS++))
fi
echo

# Check for out-of-scope section
echo "Checking for explicit out-of-scope section..."
if ! grep -q "Out of Scope\|Won't Have" "$SPEC_FILE"; then
    echo "ℹ️  INFO: No explicit out-of-scope section (recommended to prevent scope creep)"
    ((INFO++))
else
    echo "✓ Out-of-scope section present"
fi
echo

# Check for security considerations
echo "Checking security considerations..."
if ! grep -qi "security\|threat\|authentication\|authorization" "$SPEC_FILE"; then
    echo "⚠️  WARNING: No security considerations found"
    ((WARNINGS++))
else
    echo "✓ Security considerations present"
fi
echo

# Check for testing strategy
echo "Checking testing strategy..."
if ! grep -qi "testing\|test coverage\|test scenarios" "$SPEC_FILE"; then
    echo "ℹ️  INFO: No testing strategy mentioned (consider adding)"
    ((INFO++))
else
    echo "✓ Testing strategy mentioned"
fi
echo

# Check for dependencies
echo "Checking for dependency documentation..."
if ! grep -q "Dependencies\|External Dependencies" "$SPEC_FILE"; then
    echo "ℹ️  INFO: No dependencies section (add if applicable)"
    ((INFO++))
else
    echo "✓ Dependencies documented"
fi
echo

# Check for data requirements
echo "Checking for data requirements..."
if ! grep -q "Data Requirements\|Data Entities" "$SPEC_FILE"; then
    echo "ℹ️  INFO: No data requirements section (add if applicable)"
    ((INFO++))
else
    echo "✓ Data requirements present"
fi
echo

# File size check (too short might be incomplete)
WORD_COUNT=$(wc -w < "$SPEC_FILE")
if [ "$WORD_COUNT" -lt 500 ]; then
    echo "⚠️  WARNING: Specification seems very short ($WORD_COUNT words)"
    echo "   Consider adding more detail"
    ((WARNINGS++))
elif [ "$WORD_COUNT" -gt 5000 ]; then
    echo "ℹ️  INFO: Specification is quite long ($WORD_COUNT words)"
    echo "   Consider if some details belong in technical plan instead"
    ((INFO++))
else
    echo "✓ Specification length appropriate ($WORD_COUNT words)"
fi
echo

# Stakeholder sign-off check
echo "Checking for stakeholder sign-off..."
if ! grep -q "Sign-off\|Approved" "$SPEC_FILE"; then
    echo "ℹ️  INFO: No sign-off section (add before implementation)"
    ((INFO++))
else
    if grep -q "\[ \].*Approved\|\[x\].*Approved" "$SPEC_FILE"; then
        APPROVED=$(grep -c "\[x\].*Approved" "$SPEC_FILE" || echo "0")
        PENDING=$(grep -c "\[ \].*Approved" "$SPEC_FILE" || echo "0")
        echo "✓ Sign-off section present ($APPROVED approved, $PENDING pending)"
    else
        echo "✓ Sign-off section present"
    fi
fi
echo

# Summary
echo "========================================"
echo "Validation Summary"
echo "========================================"
echo "Errors:   $ERRORS"
echo "Warnings: $WARNINGS"
echo "Info:     $INFO"
echo

if [ $ERRORS -gt 0 ]; then
    echo "❌ Validation FAILED: $ERRORS errors must be fixed"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo "⚠️  Validation PASSED with warnings: $WARNINGS warnings should be addressed"
    exit 0
else
    echo "✅ Validation PASSED: Specification looks good!"
    exit 0
fi
