#!/bin/bash

# Swarms Implementation Verification Script
# Checks if all components are properly installed

set -euo pipefail

COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[1;33m'
COLOR_RESET='\033[0m'

echo "🔍 Verifying Claude Code Swarms Implementation..."
echo ""

# Counters
PASS=0
FAIL=0

# Function to check file exists
check_file() {
    local file=$1
    local description=$2

    if [[ -f "$file" ]]; then
        echo -e "${COLOR_GREEN}✓${COLOR_RESET} $description"
        ((PASS++))
        return 0
    else
        echo -e "${COLOR_RED}✗${COLOR_RESET} $description (missing: $file)"
        ((FAIL++))
        return 1
    fi
}

# Function to check directory exists
check_dir() {
    local dir=$1
    local description=$2

    if [[ -d "$dir" ]]; then
        echo -e "${COLOR_GREEN}✓${COLOR_RESET} $description"
        ((PASS++))
        return 0
    else
        echo -e "${COLOR_RED}✗${COLOR_RESET} $description (missing: $dir)"
        ((FAIL++))
        return 1
    fi
}

# Function to check file is executable
check_executable() {
    local file=$1
    local description=$2

    if [[ -x "$file" ]]; then
        echo -e "${COLOR_GREEN}✓${COLOR_RESET} $description"
        ((PASS++))
        return 0
    else
        echo -e "${COLOR_YELLOW}⚠${COLOR_RESET} $description (not executable: $file)"
        echo "  Run: chmod +x $file"
        ((FAIL++))
        return 1
    fi
}

echo "📋 Checking Rules..."
check_file "$HOME/.claude/rules/orchestration.md" "Orchestration rule (extended with Mode 4)"
check_file "$HOME/.claude/rules/swarm-coordination.md" "Swarm coordination rule"
echo ""

echo "🤖 Checking Agents..."
check_file "$HOME/.claude/agents/security-sentinel.md" "Security Sentinel agent"
check_file "$HOME/.claude/agents/performance-oracle.md" "Performance Oracle agent"
check_file "$HOME/.claude/agents/architecture-strategist.md" "Architecture Strategist agent"
check_file "$HOME/.claude/agents/framework-researcher.md" "Framework Researcher agent"
check_file "$HOME/.claude/agents/service-architect.md" "Service Architect agent"
echo ""

echo "🔧 Checking Hooks..."
check_file "$HOME/.claude/hooks/swarm-coordinator.sh" "Swarm coordinator hook"
check_executable "$HOME/.claude/hooks/swarm-coordinator.sh" "Hook is executable"
echo ""

echo "📁 Checking Storage Directories..."
check_dir "$HOME/.claude/orchestration" "Orchestration directory"
check_dir "$HOME/.claude/orchestration/inbox" "Inbox directory"
check_dir "$HOME/.claude/orchestration/results" "Results directory"
check_dir "$HOME/.claude/orchestration/issues" "Issues directory"
check_dir "$HOME/.claude/orchestration/tasks" "Tasks directory"
check_dir "$HOME/.claude/orchestration/sync" "Sync directory"
echo ""

echo "📚 Checking Documentation..."
check_file "$HOME/.claude/swarms-implementation-guide.md" "Implementation guide"
check_file "$HOME/.claude/swarms-quick-reference.md" "Quick reference"
echo ""

echo "🔍 Checking orchestration.md for Mode 4..."
if grep -q "모드 4: Internal Swarms" "$HOME/.claude/rules/orchestration.md" 2>/dev/null; then
    echo -e "${COLOR_GREEN}✓${COLOR_RESET} Mode 4 found in orchestration.md"
    ((PASS++))
else
    echo -e "${COLOR_RED}✗${COLOR_RESET} Mode 4 not found in orchestration.md"
    ((FAIL++))
fi
echo ""

echo "═══════════════════════════════════════════════════"
echo "Summary:"
echo -e "${COLOR_GREEN}Passed: $PASS${COLOR_RESET}"
echo -e "${COLOR_RED}Failed: $FAIL${COLOR_RESET}"
echo ""

if [[ $FAIL -eq 0 ]]; then
    echo -e "${COLOR_GREEN}✓ All components verified successfully!${COLOR_RESET}"
    echo ""
    echo "🚀 Ready to use Internal Swarms!"
    echo ""
    echo "Try these commands:"
    echo '  "src/ 디렉토리를 보안, 성능 관점에서 리뷰해줘"'
    echo '  "GraphQL 서버 추천해줘: Apollo, Mercurius, Yoga"'
    echo '  "주문 서비스를 마이크로서비스로 설계해줘"'
    echo ""
    exit 0
else
    echo -e "${COLOR_RED}✗ Some components are missing or misconfigured.${COLOR_RESET}"
    echo "Please fix the issues above and run this script again."
    echo ""
    exit 1
fi
