#!/bin/bash
# Contract Monitoring Script
# Monitors contract events and health

set -e

echo "=========================================="
echo "KYA Protocol - Contract Monitoring"
echo "=========================================="
echo ""

# Load configuration
if [ -f "monitoring/monitoring-config.json" ]; then
    source <(jq -r 'to_entries[] | "export \(.key)=\(.value)"' monitoring/monitoring-config.json)
fi

# Check if contract addresses are set
if [ -z "$AGENT_LICENSE" ] || [ -z "$INSURANCE_VAULT" ]; then
    echo "Error: Contract addresses not configured"
    echo "  Set AGENT_LICENSE, INSURANCE_VAULT, etc. in monitoring-config.json"
    exit 1
fi

# Function to check contract health
check_contract_health() {
    local contract=$1
    local name=$2
    
    echo "Checking $name ($contract)..."
    
    # Check if contract exists
    code_size=$(cast code $contract --rpc-url $BASE_SEPOLIA_RPC_URL 2>/dev/null | wc -c)
    if [ $code_size -lt 10 ]; then
        echo "  ⚠ Contract not found or empty"
        return 1
    fi
    
    echo "  ✓ Contract exists"
    return 0
}

# Function to monitor events
monitor_events() {
    local contract=$1
    local event_sig=$2
    local name=$3
    
    echo "Monitoring $name events..."
    
    # Get recent events (last 100 blocks)
    latest_block=$(cast block-number --rpc-url $BASE_SEPOLIA_RPC_URL)
    from_block=$((latest_block - 100))
    
    # This would use a proper event monitoring tool
    echo "  ℹ Use Tenderly or Defender for real-time event monitoring"
    echo "  Event: $event_sig"
    echo "  Contract: $contract"
    echo "  From block: $from_block"
}

# Check all contracts
echo "Contract Health Check"
echo "----------------------------------------"
check_contract_health $AGENT_LICENSE "AgentLicense"
check_contract_health $AGENT_REGISTRY "AgentRegistry"
check_contract_health $INSURANCE_VAULT "InsuranceVault"
check_contract_health $REPUTATION_SCORE "ReputationScore"
check_contract_health $PAYMASTER "Paymaster"

echo ""
echo "Event Monitoring"
echo "----------------------------------------"
monitor_events $AGENT_LICENSE "AgentMinted" "Agent Minting"
monitor_events $INSURANCE_VAULT "Staked" "Staking"
monitor_events $INSURANCE_VAULT "ClaimSubmitted" "Claims"
monitor_events $REPUTATION_SCORE "ProofVerified" "Proof Verification"

echo ""
echo "=========================================="
echo "Monitoring Complete"
echo "=========================================="
echo ""
echo "For real-time monitoring, use:"
echo "  - Tenderly: https://tenderly.co"
echo "  - OpenZeppelin Defender: https://defender.openzeppelin.com"
echo "  - Custom: See docs/MONITORING.md"
echo ""

