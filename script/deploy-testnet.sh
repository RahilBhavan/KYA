#!/bin/bash
# Complete Testnet Deployment Script
# Handles full deployment process with checks

set -e

echo "=========================================="
echo "KYA Protocol - Testnet Deployment"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check environment
if [ -z "$PRIVATE_KEY" ]; then
    echo -e "${RED}Error: PRIVATE_KEY not set${NC}"
    exit 1
fi

if [ -z "$BASE_SEPOLIA_RPC_URL" ]; then
    echo -e "${RED}Error: BASE_SEPOLIA_RPC_URL not set${NC}"
    exit 1
fi

# Step 1: Pre-deployment check
echo "Step 1: Pre-deployment checks..."
forge script script/PreDeploymentCheck.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL
if [ $? -ne 0 ]; then
    echo -e "${RED}Pre-deployment checks failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Pre-deployment checks passed${NC}"
echo ""

# Step 2: Build contracts
echo "Step 2: Building contracts..."
forge build
if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Contracts built${NC}"
echo ""

# Step 3: Deploy contracts
echo "Step 3: Deploying contracts..."
forge script script/DeployBaseSepolia.s.sol \
    --rpc-url $BASE_SEPOLIA_RPC_URL \
    --broadcast \
    --verify \
    --etherscan-api-key ${BASESCAN_API_KEY:-""} \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}Deployment failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Contracts deployed${NC}"
echo ""

# Step 4: Extract addresses (from deployment output or .env)
echo "Step 4: Setting up environment..."
echo "  Please set contract addresses in .env:"
echo "  - AGENT_LICENSE=<address>"
echo "  - AGENT_REGISTRY=<address>"
echo "  - INSURANCE_VAULT=<address>"
echo "  - REPUTATION_SCORE=<address>"
echo "  - PAYMASTER=<address>"
echo "  - MERCHANT_SDK=<address>"
echo ""

read -p "Press enter after setting addresses in .env..."

# Step 5: Verify deployment
echo "Step 5: Verifying deployment..."
forge script script/VerifyDeployment.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}⚠ Verification had issues - review output${NC}"
else
    echo -e "${GREEN}✓ Deployment verified${NC}"
fi
echo ""

# Step 6: Post-deployment setup
echo "Step 6: Post-deployment setup..."
read -p "Configure integrations? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    forge script script/PostDeploymentSetup.s.sol \
        --rpc-url $BASE_SEPOLIA_RPC_URL \
        --broadcast \
        -vvv
    echo -e "${GREEN}✓ Post-deployment setup complete${NC}"
else
    echo "  Skipping post-deployment setup"
fi
echo ""

# Step 7: Health check
echo "Step 7: Running health check..."
forge script script/HealthCheck.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL
echo ""

# Step 8: Testnet testing
echo "Step 8: Testnet testing..."
read -p "Run testnet tests? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    forge script script/TestnetTesting.s.sol \
        --rpc-url $BASE_SEPOLIA_RPC_URL \
        --broadcast \
        -vvv
    echo -e "${GREEN}✓ Testnet tests complete${NC}"
else
    echo "  Skipping testnet tests"
fi
echo ""

echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Next Steps:"
echo "1. Verify contracts on BaseScan"
echo "2. Grant roles to external services"
echo "3. Fund Paymaster"
echo "4. Test end-to-end flows"
echo "5. Monitor contract activity"
echo ""

