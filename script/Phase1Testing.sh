#!/bin/bash
# Phase 1: Testing & Validation Script
# This script runs all Phase 1 testing tasks

set -e  # Exit on error

echo "=========================================="
echo "KYA Protocol - Phase 1: Testing & Validation"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if forge is installed
if ! command -v forge &> /dev/null; then
    echo -e "${RED}Error: forge command not found${NC}"
    echo "Please install Foundry: https://book.getfoundry.sh/getting-started/installation"
    exit 1
fi

echo -e "${GREEN}✓ Foundry installed${NC}"
echo ""

# Step 1: Build contracts
echo "Step 1: Building contracts..."
forge build
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Contracts built successfully${NC}"
else
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi
echo ""

# Step 2: Run all tests
echo "Step 2: Running test suite..."
forge test -vv
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed${NC}"
else
    echo -e "${YELLOW}⚠ Some tests failed - review output above${NC}"
fi
echo ""

# Step 3: Generate gas report
echo "Step 3: Generating gas report..."
forge test --gas-report > gas_report.txt 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Gas report generated: gas_report.txt${NC}"
    echo "Key operations:"
    grep -E "(stake|unstake|verifyProof|awardBadge)" gas_report.txt | head -20 || echo "  (Review gas_report.txt for details)"
else
    echo -e "${YELLOW}⚠ Gas report generation had issues${NC}"
fi
echo ""

# Step 4: Generate coverage report
echo "Step 4: Generating coverage report..."
if [ -f "script/coverage.sh" ]; then
    bash script/coverage.sh
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Coverage report generated${NC}"
    else
        echo -e "${YELLOW}⚠ Coverage script had issues${NC}"
    fi
else
    forge coverage
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Coverage report generated${NC}"
    else
        echo -e "${YELLOW}⚠ Coverage generation had issues${NC}"
    fi
fi
echo ""

# Step 5: Run specific test suites
echo "Step 5: Running specific test suites..."

echo "  - Unit tests..."
forge test --match-path test/unit/ -vv > unit_tests.txt 2>&1
if [ $? -eq 0 ]; then
    echo -e "    ${GREEN}✓ Unit tests passed${NC}"
else
    echo -e "    ${YELLOW}⚠ Some unit tests failed${NC}"
fi

echo "  - Integration tests..."
forge test --match-path test/integration/ -vv > integration_tests.txt 2>&1
if [ $? -eq 0 ]; then
    echo -e "    ${GREEN}✓ Integration tests passed${NC}"
else
    echo -e "    ${YELLOW}⚠ Some integration tests failed${NC}"
fi

echo "  - Fuzz tests..."
forge test --match-path test/fuzz/ -vv > fuzz_tests.txt 2>&1
if [ $? -eq 0 ]; then
    echo -e "    ${GREEN}✓ Fuzz tests passed${NC}"
else
    echo -e "    ${YELLOW}⚠ Some fuzz tests failed${NC}"
fi

echo "  - Invariant tests..."
forge test --match-path test/invariant/ -vv > invariant_tests.txt 2>&1
if [ $? -eq 0 ]; then
    echo -e "    ${GREEN}✓ Invariant tests passed${NC}"
else
    echo -e "    ${YELLOW}⚠ Some invariant tests failed${NC}"
fi
echo ""

# Step 6: Summary
echo "=========================================="
echo "Phase 1 Testing Summary"
echo "=========================================="
echo ""
echo "Generated files:"
echo "  - gas_report.txt (gas usage analysis)"
echo "  - unit_tests.txt (unit test results)"
echo "  - integration_tests.txt (integration test results)"
echo "  - fuzz_tests.txt (fuzz test results)"
echo "  - invariant_tests.txt (invariant test results)"
echo ""
echo "Next steps:"
echo "  1. Review test failures (if any)"
echo "  2. Analyze gas report for optimizations"
echo "  3. Check coverage report (target: 90%+)"
echo "  4. Fix any issues found"
echo "  5. Proceed to Phase 2: External Integrations"
echo ""
echo -e "${GREEN}Phase 1 testing complete!${NC}"

