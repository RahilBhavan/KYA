#!/bin/bash
# Security Checklist Script
# Verifies security best practices are followed

set -e

echo "=========================================="
echo "KYA Protocol - Security Checklist"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PASS=0
FAIL=0

check() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $1"
        ((PASS++))
    else
        echo -e "${RED}✗${NC} $1"
        ((FAIL++))
    fi
}

echo "Checking security best practices..."
echo ""

# Check for ReentrancyGuard
echo "1. Reentrancy Protection"
grep -r "nonReentrant" src/ > /dev/null
check "ReentrancyGuard used on external functions"

# Check for AccessControl
echo "2. Access Control"
grep -r "onlyRole\|AccessControl" src/ > /dev/null
check "AccessControl implemented"

# Check for SafeERC20
echo "3. Safe Token Transfers"
grep -r "SafeERC20\|safeTransfer" src/ > /dev/null
check "SafeERC20 used for token transfers"

# Check for zero address validation
echo "4. Input Validation"
grep -r "address(0)\|zero address" src/ > /dev/null
check "Zero address checks present"

# Check for Pausable
echo "5. Emergency Controls"
grep -r "Pausable\|pause()" src/ > /dev/null
check "Pausable implemented"

# Check for proof replay prevention
echo "6. Proof Replay Prevention"
grep -r "_verifiedProofs\|ProofAlreadyVerified" src/ > /dev/null
check "Proof replay prevention implemented"

# Check for fee caps
echo "7. Fee Caps"
grep -r "claimFeeBps.*<=.*1000\|fee.*cap" src/ > /dev/null
check "Fee caps enforced"

# Check for bounds checking
echo "8. Bounds Checking"
grep -r "require.*>.*0\|require.*<=.*" src/ > /dev/null
check "Bounds checking present"

echo ""
echo "=========================================="
echo "Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"
echo "=========================================="

if [ $FAIL -eq 0 ]; then
    exit 0
else
    exit 1
fi

