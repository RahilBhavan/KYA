#!/bin/bash
# Monitoring Setup Script
# Sets up contract monitoring and alerts

set -e

echo "=========================================="
echo "KYA Protocol - Monitoring Setup"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if required environment variables are set
if [ -z "$CONTRACT_ADDRESSES" ] && [ -z "$AGENT_LICENSE" ]; then
    echo -e "${YELLOW}⚠ Contract addresses not set${NC}"
    echo "  Set environment variables or create monitoring-config.json"
    echo ""
fi

# Create monitoring directory
mkdir -p monitoring

echo "Monitoring Setup Options:"
echo "1. Tenderly (Recommended for Base)"
echo "2. OpenZeppelin Defender"
echo "3. Custom (Manual setup)"
echo ""
read -p "Select monitoring service (1-3): " choice

case $choice in
    1)
        echo ""
        echo "Tenderly Setup"
        echo "----------------------------------------"
        echo "1. Sign up at https://tenderly.co"
        echo "2. Create a project"
        echo "3. Add Base Sepolia network"
        echo "4. Get API key from Settings > Authorization"
        echo ""
        read -p "Enter Tenderly API key: " tenderly_key
        read -p "Enter Tenderly project slug: " tenderly_project
        read -p "Enter Tenderly username: " tenderly_username
        
        cat > monitoring/tenderly-config.json << EOF
{
  "apiKey": "${tenderly_key}",
  "project": "${tenderly_project}",
  "username": "${tenderly_username}",
  "network": "base-sepolia",
  "chainId": 84532
}
EOF
        
        echo -e "${GREEN}✓ Tenderly config saved${NC}"
        echo "  Config: monitoring/tenderly-config.json"
        ;;
    2)
        echo ""
        echo "OpenZeppelin Defender Setup"
        echo "----------------------------------------"
        echo "1. Sign up at https://defender.openzeppelin.com"
        echo "2. Create a team"
        echo "3. Get API key and secret"
        echo ""
        read -p "Enter Defender API key: " defender_key
        read -p "Enter Defender API secret: " defender_secret
        
        cat > monitoring/defender-config.json << EOF
{
  "apiKey": "${defender_key}",
  "apiSecret": "${defender_secret}",
  "network": "base-sepolia"
}
EOF
        
        echo -e "${GREEN}✓ Defender config saved${NC}"
        echo "  Config: monitoring/defender-config.json"
        ;;
    3)
        echo ""
        echo "Custom Monitoring Setup"
        echo "----------------------------------------"
        echo "  See docs/MONITORING.md for manual setup"
        ;;
esac

echo ""
echo "=========================================="
echo "Monitoring Setup Complete"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Configure contract addresses in monitoring-config.json"
echo "2. Set up event monitoring"
echo "3. Configure alerts"
echo "4. Create dashboard"
echo ""
echo "See docs/MONITORING.md for detailed instructions"
echo ""

