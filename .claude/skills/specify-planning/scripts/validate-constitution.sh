#!/bin/bash
# Constitution Validation Script
# Checks constitution completeness and quality

set -e

CONSTITUTION_FILE="$1"

if [ -z "$CONSTITUTION_FILE" ]; then
    echo "Usage: $0 <constitution-file>"
    exit 1
fi

if [ ! -f "$CONSTITUTION_FILE" ]; then
    echo "Error: File not found: $CONSTITUTION_FILE"
    exit 1
fi

echo "Validating constitution: $CONSTITUTION_FILE"
echo "========================================"
echo

ERRORS=0
WARNINGS=0
INFO=0

# Check required core principle sections
echo "Checking core principle sections..."
REQUIRED_SECTIONS=(
    "Code Quality Standards"
    "Architecture Principles"
    "Security"
    "Tech Stack"
    "Quality Gates"
)

for section in "${REQUIRED_SECTIONS[@]}"; do
    if ! grep -qi "$section" "$CONSTITUTION_FILE"; then
        echo "❌ ERROR: Missing required section: $section"
        ((ERRORS++))
    else
        echo "✓ Found: $section"
    fi
done
echo

# Check for testing requirements
echo "Checking testing requirements..."
if ! grep -qi "test.*coverage\|testing.*requirement\|minimum.*coverage" "$CONSTITUTION_FILE"; then
    echo "⚠️  WARNING: No explicit testing coverage requirements found"
    ((WARNINGS++))
else
    echo "✓ Testing requirements present"
fi
echo

# Check for code review requirements
echo "Checking code review requirements..."
if ! grep -qi "code.*review\|review.*requirement\|pr.*approval" "$CONSTITUTION_FILE"; then
    echo "⚠️  WARNING: No code review requirements found"
    ((WARNINGS++))
else
    echo "✓ Code review requirements present"
fi
echo

# Check for performance targets
echo "Checking performance targets..."
if ! grep -Eq "([0-9]+ms|< [0-9]+.*second|latency|response time)" "$CONSTITUTION_FILE"; then
    echo "⚠️  WARNING: No specific performance targets found"
    ((WARNINGS++))
else
    echo "✓ Performance targets specified"
fi
echo

# Check for security standards
echo "Checking security standards..."
SECURITY_KEYWORDS=(
    "authentication"
    "authorization"
    "encryption"
)

SECURITY_FOUND=0
for keyword in "${SECURITY_KEYWORDS[@]}"; do
    if grep -qi "$keyword" "$CONSTITUTION_FILE"; then
        ((SECURITY_FOUND++))
    fi
done

if [ $SECURITY_FOUND -lt 2 ]; then
    echo "⚠️  WARNING: Security section may be incomplete (found $SECURITY_FOUND/3 key areas)"
    ((WARNINGS++))
else
    echo "✓ Security standards comprehensive ($SECURITY_FOUND/3 key areas)"
fi
echo

# Check for approved technologies
echo "Checking technology specifications..."
if ! grep -qi "approved.*technolog\|tech.*stack\|framework" "$CONSTITUTION_FILE"; then
    echo "⚠️  WARNING: No approved technologies specified"
    ((WARNINGS++))
else
    echo "✓ Technology specifications present"
fi
echo

# Check for quality gates
echo "Checking quality gates..."
QUALITY_GATES=(
    "pre-commit\|before.*commit"
    "pre-pr\|before.*pull\|before.*pr"
    "pre-release\|before.*release"
)

GATES_FOUND=0
for gate in "${QUALITY_GATES[@]}"; do
    if grep -qiE "$gate" "$CONSTITUTION_FILE"; then
        ((GATES_FOUND++))
    fi
done

if [ $GATES_FOUND -lt 3 ]; then
    echo "⚠️  WARNING: Quality gates incomplete (found $GATES_FOUND/3)"
    ((WARNINGS++))
else
    echo "✓ Quality gates comprehensive ($GATES_FOUND/3)"
fi
echo

# Check for ambiguous terms (should be specific)
echo "Checking for ambiguous terms..."
AMBIGUOUS_TERMS=(
    "good quality"
    "fast enough"
    "secure"
    "properly"
    "adequate"
)

AMBIGUOUS_FOUND=0
for term in "${AMBIGUOUS_TERMS[@]}"; do
    count=$(grep -ci "$term" "$CONSTITUTION_FILE" || echo "0")
    if [ "$count" -gt 0 ]; then
        echo "ℹ️  INFO: Found potentially ambiguous term '$term' ($count times)"
        echo "   Consider replacing with specific, measurable criteria"
        ((INFO++))
        AMBIGUOUS_FOUND=1
    fi
done

if [ $AMBIGUOUS_FOUND -eq 0 ]; then
    echo "✓ No obviously ambiguous terms found"
fi
echo

# Check for monitoring/observability
echo "Checking for monitoring and observability..."
if ! grep -qi "monitoring\|observability\|logging\|metrics\|alerting" "$CONSTITUTION_FILE"; then
    echo "ℹ️  INFO: No monitoring/observability requirements (consider adding)"
    ((INFO++))
else
    echo "✓ Monitoring/observability requirements present"
fi
echo

# Check for version history
echo "Checking for version history..."
if ! grep -q "Version\|Change.*Log\|Amendment" "$CONSTITUTION_FILE"; then
    echo "ℹ️  INFO: No version history (add to track constitutional changes)"
    ((INFO++))
else
    echo "✓ Version tracking present"
fi
echo

# Check for amendment process
echo "Checking for amendment process..."
if ! grep -qi "amendment\|change.*process\|update.*process" "$CONSTITUTION_FILE"; then
    echo "ℹ️  INFO: No amendment process defined (how to update constitution?)"
    ((INFO++))
else
    echo "✓ Amendment process defined"
fi
echo

# File completeness check
WORD_COUNT=$(wc -w < "$CONSTITUTION_FILE")
if [ "$WORD_COUNT" -lt 1000 ]; then
    echo "⚠️  WARNING: Constitution seems incomplete ($WORD_COUNT words)"
    echo "   A comprehensive constitution is usually 1500-3000 words"
    ((WARNINGS++))
else
    echo "✓ Constitution appears comprehensive ($WORD_COUNT words)"
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
    echo "✅ Validation PASSED: Constitution looks solid!"
    exit 0
fi
