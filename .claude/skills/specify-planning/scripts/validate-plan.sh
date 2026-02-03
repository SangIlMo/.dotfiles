#!/bin/bash
# Technical Plan Validation Script
# Checks technical plan completeness and constitutional compliance

set -e

PLAN_FILE="$1"
CONSTITUTION_FILE="${2:-.spec/constitution.md}"

if [ -z "$PLAN_FILE" ]; then
    echo "Usage: $0 <plan-file> [constitution-file]"
    exit 1
fi

if [ ! -f "$PLAN_FILE" ]; then
    echo "Error: File not found: $PLAN_FILE"
    exit 1
fi

echo "Validating technical plan: $PLAN_FILE"
if [ -f "$CONSTITUTION_FILE" ]; then
    echo "Using constitution: $CONSTITUTION_FILE"
fi
echo "========================================"
echo

ERRORS=0
WARNINGS=0
INFO=0

# Check required sections
echo "Checking required sections..."
REQUIRED_SECTIONS=(
    "Constitutional Compliance"
    "Architecture Overview"
    "Technology Choices"
    "Data Model"
    "API Contracts"
    "Security Design"
    "Testing Strategy"
    "Monitoring"
)

for section in "${REQUIRED_SECTIONS[@]}"; do
    if ! grep -qi "$section" "$PLAN_FILE"; then
        echo "❌ ERROR: Missing required section: $section"
        ((ERRORS++))
    else
        echo "✓ Found: $section"
    fi
done
echo

# Check constitutional compliance section
echo "Checking constitutional compliance..."
if grep -q "Constitutional Compliance" "$PLAN_FILE"; then
    CHECKBOXES=$(grep -A 20 "Constitutional Compliance" "$PLAN_FILE" | grep -c "\[ \]\|\[x\]" || echo "0")
    if [ "$CHECKBOXES" -lt 3 ]; then
        echo "⚠️  WARNING: Constitutional compliance section has few checkboxes ($CHECKBOXES)"
        echo "   Ensure all constitutional requirements are verified"
        ((WARNINGS++))
    else
        CHECKED=$(grep -A 20 "Constitutional Compliance" "$PLAN_FILE" | grep -c "\[x\]" || echo "0")
        echo "✓ Constitutional compliance checklist present ($CHECKED/$CHECKBOXES checked)"
    fi
else
    echo "❌ ERROR: Constitutional Compliance section missing"
    ((ERRORS++))
fi
echo

# Check for technology rationales
echo "Checking technology choices have rationales..."
if grep -q "Technology Choices\|Technology Stack" "$PLAN_FILE"; then
    if ! grep -qi "rationale\|reason\|why" "$PLAN_FILE"; then
        echo "⚠️  WARNING: Technology choices lack rationales"
        echo "   Explain why each technology was chosen"
        ((WARNINGS++))
    else
        echo "✓ Technology rationales present"
    fi
else
    echo "❌ ERROR: Technology Choices section missing"
    ((ERRORS++))
fi
echo

# Check for database schema
echo "Checking data model specification..."
if grep -qi "data model\|database schema\|entity" "$PLAN_FILE"; then
    if grep -q "CREATE TABLE\|Table:" "$PLAN_FILE"; then
        echo "✓ Database schema defined"
    else
        echo "ℹ️  INFO: Data model mentioned but no schema provided"
        echo "   Consider adding table definitions"
        ((INFO++))
    fi
else
    echo "ℹ️  INFO: No data model section (skip if not applicable)"
    ((INFO++))
fi
echo

# Check for API contracts
echo "Checking API contract specifications..."
if grep -q "API Contracts\|API Endpoints" "$PLAN_FILE"; then
    if grep -Eq "(GET|POST|PUT|DELETE|PATCH) /" "$PLAN_FILE"; then
        ENDPOINTS=$(grep -Ec "(GET|POST|PUT|DELETE|PATCH) /" "$PLAN_FILE")
        echo "✓ API endpoints defined ($ENDPOINTS found)"
    else
        echo "⚠️  WARNING: API Contracts section exists but no endpoints specified"
        ((WARNINGS++))
    fi

    # Check for request/response schemas
    if ! grep -qi "request.*schema\|response.*schema\|request body\|response body" "$PLAN_FILE"; then
        echo "⚠️  WARNING: API contracts lack request/response schemas"
        ((WARNINGS++))
    fi
else
    echo "ℹ️  INFO: No API contracts section (skip if not applicable)"
    ((INFO++))
fi
echo

# Check for security design
echo "Checking security design..."
SECURITY_ASPECTS=(
    "authentication"
    "authorization"
    "encryption"
)

SECURITY_FOUND=0
for aspect in "${SECURITY_ASPECTS[@]}"; do
    if grep -qi "$aspect" "$PLAN_FILE"; then
        ((SECURITY_FOUND++))
    fi
done

if [ $SECURITY_FOUND -lt 2 ]; then
    echo "⚠️  WARNING: Security design may be incomplete (found $SECURITY_FOUND/3 aspects)"
    ((WARNINGS++))
else
    echo "✓ Security design comprehensive ($SECURITY_FOUND/3 aspects)"
fi
echo

# Check for testing strategy
echo "Checking testing strategy..."
TEST_TYPES=(
    "unit.*test"
    "integration.*test"
    "e2e\|end.*to.*end"
)

TEST_FOUND=0
for test_type in "${TEST_TYPES[@]}"; do
    if grep -qiE "$test_type" "$PLAN_FILE"; then
        ((TEST_FOUND++))
    fi
done

if [ $TEST_FOUND -eq 0 ]; then
    echo "❌ ERROR: No testing strategy found"
    ((ERRORS++))
elif [ $TEST_FOUND -lt 2 ]; then
    echo "⚠️  WARNING: Testing strategy incomplete (found $TEST_FOUND/3 test types)"
    ((WARNINGS++))
else
    echo "✓ Testing strategy comprehensive ($TEST_FOUND/3 test types)"
fi
echo

# Check for monitoring and observability
echo "Checking monitoring and observability..."
OBSERVABILITY_ASPECTS=(
    "logging"
    "metrics\|monitoring"
    "alerting\|alerts"
)

OBS_FOUND=0
for aspect in "${OBSERVABILITY_ASPECTS[@]}"; do
    if grep -qiE "$aspect" "$PLAN_FILE"; then
        ((OBS_FOUND++))
    fi
done

if [ $OBS_FOUND -lt 2 ]; then
    echo "⚠️  WARNING: Monitoring/observability incomplete (found $OBS_FOUND/3 aspects)"
    ((WARNINGS++))
else
    echo "✓ Monitoring/observability comprehensive ($OBS_FOUND/3 aspects)"
fi
echo

# Check for risk assessment
echo "Checking risk assessment..."
if ! grep -qi "risk\|mitigation" "$PLAN_FILE"; then
    echo "ℹ️  INFO: No risk assessment section (consider adding)"
    ((INFO++))
else
    echo "✓ Risk assessment present"
fi
echo

# Check for implementation phases
echo "Checking implementation phases..."
if ! grep -qi "phase\|milestone" "$PLAN_FILE"; then
    echo "ℹ️  INFO: No implementation phases defined"
    echo "   Consider breaking down into phases/milestones"
    ((INFO++))
else
    echo "✓ Implementation phases defined"
fi
echo

# Check for rollback plan
echo "Checking rollback plan..."
if ! grep -qi "rollback\|revert" "$PLAN_FILE"; then
    echo "⚠️  WARNING: No rollback plan specified"
    ((WARNINGS++))
else
    echo "✓ Rollback plan present"
fi
echo

# Validate against constitution if available
if [ -f "$CONSTITUTION_FILE" ]; then
    echo "Cross-checking with constitution..."

    # Check if plan mentions constitutional patterns
    if grep -q "repository pattern\|factory pattern\|observer pattern" "$CONSTITUTION_FILE"; then
        if grep -qi "design.*pattern" "$PLAN_FILE"; then
            echo "✓ Plan addresses design patterns"
        else
            echo "⚠️  WARNING: Constitution specifies design patterns but plan doesn't address them"
            ((WARNINGS++))
        fi
    fi

    # Check if plan uses approved technologies
    # (This is simplified; a full implementation would parse tech stack from both files)
    echo "ℹ️  INFO: Manual review recommended to verify tech stack compliance"
    ((INFO++))
else
    echo "ℹ️  INFO: Constitution file not found, skipping cross-check"
    ((INFO++))
fi
echo

# File completeness
WORD_COUNT=$(wc -w < "$PLAN_FILE")
if [ "$WORD_COUNT" -lt 1500 ]; then
    echo "⚠️  WARNING: Plan seems incomplete ($WORD_COUNT words)"
    echo "   A comprehensive technical plan is usually 2000-4000 words"
    ((WARNINGS++))
else
    echo "✓ Plan appears comprehensive ($WORD_COUNT words)"
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
    echo "✅ Validation PASSED: Technical plan looks solid!"
    exit 0
fi
