#!/bin/bash
# Security Analysis Script for KYA Protocol
# Runs multiple security analysis tools

set -e

echo "=========================================="
echo "KYA Protocol - Security Analysis"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if tools are installed
check_tool() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${YELLOW}⚠ $1 not found - skipping${NC}"
        return 1
    fi
    return 0
}

# Create output directory
mkdir -p security-reports

echo "Step 1: Running Slither (Static Analysis)"
echo "----------------------------------------"
if check_tool slither; then
    slither . \
        --exclude-dependencies \
        --exclude-informational \
        --exclude-optimization \
        --print human-summary \
        > security-reports/slither-report.txt 2>&1 || true
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Slither analysis complete${NC}"
        echo "  Report: security-reports/slither-report.txt"
    else
        echo -e "${YELLOW}⚠ Slither found issues - review report${NC}"
    fi
else
    echo "  Install: pip install slither-analyzer"
fi
echo ""

echo "Step 2: Running Mythril (Symbolic Execution)"
echo "----------------------------------------"
if check_tool myth; then
    echo "  Analyzing InsuranceVault..."
    myth analyze src/InsuranceVault.sol \
        --solc-json foundry.toml \
        > security-reports/mythril-insurancevault.txt 2>&1 || true
    
    echo "  Analyzing ReputationScore..."
    myth analyze src/ReputationScore.sol \
        --solc-json foundry.toml \
        > security-reports/mythril-reputationscore.txt 2>&1 || true
    
    echo "  Analyzing Paymaster..."
    myth analyze src/Paymaster.sol \
        --solc-json foundry.toml \
        > security-reports/mythril-paymaster.txt 2>&1 || true
    
    echo -e "${GREEN}✓ Mythril analysis complete${NC}"
    echo "  Reports: security-reports/mythril-*.txt"
else
    echo "  Install: pip install mythril"
fi
echo ""

echo "Step 3: Running Foundry Security Checks"
echo "----------------------------------------"
if command -v forge &> /dev/null; then
    # Check for common vulnerabilities
    echo "  Checking for common issues..."
    
    # Check for reentrancy guards
    echo "  - Reentrancy protection..."
    grep -r "nonReentrant" src/ > security-reports/reentrancy-checks.txt || echo "  No nonReentrant found" > security-reports/reentrancy-checks.txt
    
    # Check for access control
    echo "  - Access control..."
    grep -r "onlyRole\|onlyOwner" src/ > security-reports/access-control-checks.txt || echo "  No access control found" > security-reports/access-control-checks.txt
    
    # Check for safe transfers
    echo "  - Safe token transfers..."
    grep -r "safeTransfer\|SafeERC20" src/ > security-reports/safe-transfer-checks.txt || echo "  No safe transfers found" > security-reports/safe-transfer-checks.txt
    
    echo -e "${GREEN}✓ Foundry checks complete${NC}"
else
    echo -e "${YELLOW}⚠ Foundry not found${NC}"
fi
echo ""

echo "Step 4: Gas Optimization Analysis"
echo "----------------------------------------"
if command -v forge &> /dev/null; then
    forge test --gas-report > security-reports/gas-report.txt 2>&1 || true
    echo -e "${GREEN}✓ Gas report generated${NC}"
    echo "  Report: security-reports/gas-report.txt"
else
    echo -e "${YELLOW}⚠ Foundry not found${NC}"
fi
echo ""

echo "Step 5: Compilation Check"
echo "----------------------------------------"
if command -v forge &> /dev/null; then
    forge build > security-reports/compilation.txt 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ All contracts compile successfully${NC}"
    else
        echo -e "${RED}✗ Compilation errors found${NC}"
        cat security-reports/compilation.txt
    fi
else
    echo -e "${YELLOW}⚠ Foundry not found${NC}"
fi
echo ""

echo "=========================================="
echo "Security Analysis Summary"
echo "=========================================="
echo ""
echo "Reports generated in: security-reports/"
echo ""
echo "Files:"
ls -lh security-reports/ | tail -n +2 | awk '{print "  - " $9 " (" $5 ")"}'
echo ""
echo "Next steps:"
echo "  1. Review all reports"
echo "  2. Address critical issues"
echo "  3. Document findings"
echo "  4. Prepare for external audit"
echo ""
echo -e "${GREEN}Security analysis complete!${NC}"

