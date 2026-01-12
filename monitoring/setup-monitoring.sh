#!/bin/bash

# KYA Protocol - Monitoring Setup Script
# Sets up Tenderly monitoring for KYA Protocol contracts

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}KYA Protocol - Monitoring Setup${NC}"
echo "========================================"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    echo "Please create .env file with required variables"
    exit 1
fi

# Load environment variables
source .env

# Check required variables
REQUIRED_VARS=(
    "TENDERLY_API_KEY"
    "TENDERLY_PROJECT_SLUG"
    "TENDERLY_USERNAME"
    "AGENT_LICENSE_ADDRESS"
    "AGENT_REGISTRY_ADDRESS"
    "REPUTATION_SCORE_ADDRESS"
    "INSURANCE_VAULT_ADDRESS"
    "PAYMASTER_ADDRESS"
    "MERCHANT_SDK_ADDRESS"
)

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}Error: $var not set in .env${NC}"
        exit 1
    fi
done

echo -e "${GREEN}✓ Environment variables loaded${NC}"
echo ""

# Check if Tenderly CLI is installed
if ! command -v tenderly &> /dev/null; then
    echo -e "${YELLOW}Tenderly CLI not found. Installing...${NC}"
    npm install -g @tenderly/cli
fi

echo -e "${GREEN}✓ Tenderly CLI ready${NC}"
echo ""

# Login to Tenderly
echo "Logging in to Tenderly..."
tenderly login --token "$TENDERLY_API_KEY"

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to login to Tenderly${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Logged in to Tenderly${NC}"
echo ""

# Initialize Tenderly project
echo "Initializing Tenderly project..."
tenderly init --project "$TENDERLY_PROJECT_SLUG" --username "$TENDERLY_USERNAME"

echo -e "${GREEN}✓ Project initialized${NC}"
echo ""

# Add contracts to monitoring
echo "Adding contracts to monitoring..."

CONTRACTS=(
    "AgentLicense:$AGENT_LICENSE_ADDRESS"
    "AgentRegistry:$AGENT_REGISTRY_ADDRESS"
    "ReputationScore:$REPUTATION_SCORE_ADDRESS"
    "InsuranceVault:$INSURANCE_VAULT_ADDRESS"
    "Paymaster:$PAYMASTER_ADDRESS"
    "MerchantSDK:$MERCHANT_SDK_ADDRESS"
)

for contract in "${CONTRACTS[@]}"; do
    IFS=':' read -r name address <<< "$contract"
    echo "  Adding $name at $address..."
    tenderly verify "$name" "$address" --network base-sepolia
done

echo -e "${GREEN}✓ Contracts added to monitoring${NC}"
echo ""

# Set up alerts (manual step - provide instructions)
echo -e "${YELLOW}Next Steps (Manual):${NC}"
echo "1. Go to https://dashboard.tenderly.co"
echo "2. Navigate to your project"
echo "3. Set up alerts using the configuration in monitoring/tenderly-config.json"
echo "4. Configure notification channels (email, Slack, etc.)"
echo ""

echo -e "${GREEN}Monitoring setup complete!${NC}"
echo ""
echo "Configuration file: monitoring/tenderly-config.json"
echo "Tenderly Dashboard: https://dashboard.tenderly.co"
