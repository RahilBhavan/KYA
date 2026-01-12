#!/bin/bash
# Gas Benchmarking Script
# Generates gas reports for key operations

set -e

echo "=========================================="
echo "KYA Protocol - Gas Benchmarking"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Create reports directory
mkdir -p gas-reports

# Check if forge is available
if ! command -v forge &> /dev/null; then
    echo -e "${RED}Error: forge command not found${NC}"
    echo "Please install Foundry: https://book.getfoundry.sh/getting-started/installation"
    exit 1
fi

echo -e "${GREEN}✓ Foundry installed${NC}"
echo ""

# Function to run gas report for specific test
run_gas_report() {
    local test_name=$1
    local output_file=$2
    local description=$3

    echo "Generating gas report for: $description"
    forge test --gas-report --match-test "$test_name" > "$output_file" 2>&1 || true
    
    if [ -f "$output_file" ]; then
        echo -e "${GREEN}✓ Report generated: $output_file${NC}"
        
        # Extract key metrics
        echo "  Key operations:"
        grep -E "(stake|unstake|verifyProof|submitClaim|resolveClaim)" "$output_file" | head -10 || echo "    (Review $output_file for details)"
    else
        echo -e "${YELLOW}⚠ Report generation had issues${NC}"
    fi
    echo ""
}

# InsuranceVault Operations
echo "InsuranceVault Operations"
echo "----------------------------------------"
run_gas_report "test_stake" "gas-reports/stake.txt" "Staking operations"
run_gas_report "test_unstake" "gas-reports/unstake.txt" "Unstaking operations"
run_gas_report "test_submitClaim" "gas-reports/submit_claim.txt" "Claim submission"
run_gas_report "test_resolveClaim" "gas-reports/resolve_claim.txt" "Claim resolution"

# ReputationScore Operations
echo "ReputationScore Operations"
echo "----------------------------------------"
run_gas_report "test_verifyProof" "gas-reports/verify_proof.txt" "Proof verification"
run_gas_report "test_getTier" "gas-reports/get_tier.txt" "Tier calculation"

# Paymaster Operations
echo "Paymaster Operations"
echo "----------------------------------------"
run_gas_report "test_validatePaymasterUserOp" "gas-reports/paymaster_validation.txt" "Paymaster validation"
run_gas_report "test_postOp" "gas-reports/paymaster_postop.txt" "Paymaster post-op"

# Overall Report
echo "Overall Gas Report"
echo "----------------------------------------"
echo "Generating comprehensive gas report..."
forge test --gas-report > gas-reports/overall.txt 2>&1 || true

if [ -f "gas-reports/overall.txt" ]; then
    echo -e "${GREEN}✓ Overall report generated: gas-reports/overall.txt${NC}"
    
    # Summary
    echo ""
    echo "Gas Usage Summary:"
    echo "----------------------------------------"
    grep -E "Function Name|InsuranceVault|ReputationScore|Paymaster" gas-reports/overall.txt | head -20 || echo "  (Review gas-reports/overall.txt for details)"
else
    echo -e "${YELLOW}⚠ Overall report generation had issues${NC}"
fi

echo ""
echo "=========================================="
echo "Gas Benchmarking Complete"
echo "=========================================="
echo ""
echo "Reports generated in: gas-reports/"
echo ""
echo "Files:"
ls -lh gas-reports/ | tail -n +2 | awk '{print "  - " $9 " (" $5 ")"}'
echo ""
echo "Next steps:"
echo "  1. Review gas reports"
echo "  2. Compare with optimization targets"
echo "  3. Identify optimization opportunities"
echo "  4. Document findings"
echo ""

