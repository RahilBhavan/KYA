# KYA Protocol - Complete Deployment Guide

**Version**: 2.0  
**Last Updated**: 2026-01-06  
**Status**: Production Ready

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Environment Setup](#environment-setup)
4. [Pre-Deployment Checks](#pre-deployment-checks)
5. [Testnet Deployment](#testnet-deployment)
6. [Mainnet Deployment](#mainnet-deployment)
7. [Post-Deployment Setup](#post-deployment-setup)
8. [Verification & Testing](#verification--testing)
9. [Monitoring & Maintenance](#monitoring--maintenance)
10. [Troubleshooting](#troubleshooting)
11. [Rollback Procedures](#rollback-procedures)

---

## Overview

This guide provides comprehensive instructions for deploying the KYA Protocol smart contracts to Base Sepolia testnet and Base mainnet. The protocol consists of 8 core contracts that work together to provide agent licensing, reputation scoring, insurance, and gas sponsorship.

### Deployment Architecture

The KYA Protocol deployment follows this dependency order:

1. **SimpleAccountImplementation** - ERC-6551 account implementation
2. **AgentLicense** - ERC-721 NFT for agent licenses
3. **AgentRegistry** - Agent registration and TBA creation
4. **ReputationScore** - Reputation and badge system
5. **InsuranceVault** - Staking and insurance pool
6. **Paymaster** - ERC-4337 gas sponsorship
7. **MerchantSDK** - Merchant integration contract
8. **Integration Adapters** (optional) - ZKAdapter, OracleAdapter

### Networks

- **Base Sepolia Testnet**: Chain ID `84532`
- **Base Mainnet**: Chain ID `8453`

---

## Prerequisites

### Required Tools

#### 1. Foundry

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Verify installation
forge --version
cast --version
```

#### 2. Git

```bash
# Clone repository
git clone <repository-url>
cd KYA

# Install dependencies
forge install
```

#### 3. Node.js (for SDK)

```bash
# Install Node.js 18+ (if using SDK)
node --version

# Install SDK dependencies (optional)
cd integrations/javascript
bun install
```

### Required Accounts & Services

#### 1. Deployer Account

- **Testnet**: Address with > 0.5 ETH on Base Sepolia
- **Mainnet**: Address with > 1 ETH on Base mainnet
- **Private Key**: Store securely (use environment variables, never commit)

**How to Get Deployer Address**:

1. **Create or Use Existing Wallet**:
   ```bash
   # Option A: Generate new wallet with cast
   cast wallet new
   # Save the private key and address securely
   
   # Option B: Use existing wallet
   # Export private key from MetaMask, Ledger, or other wallet
   ```

2. **Get Address from Private Key**:
   ```bash
   # If you have private key, get address
   cast wallet address $PRIVATE_KEY
   ```

3. **Fund Wallet**:
   - **Testnet**: Get ETH from Base Sepolia Faucet: https://www.coinbase.com/faucets/base-ethereum-goerli-faucet
   - **Mainnet**: Transfer ETH from exchange or another wallet
   - Verify balance: `cast balance $DEPLOYER_ADDRESS --rpc-url $RPC_URL`

#### 2. BaseScan API Key

Required for contract verification:

**How to Get BaseScan API Key**:

1. Go to https://basescan.org/myapikey
2. Create account (if needed) - sign up with email
3. Navigate to "API Keys" section
4. Click "Add" to create new API key
5. Copy the API key and save securely
6. Add to `.env` file: `BASESCAN_API_KEY=your_api_key_here`

**Note**: Free tier allows 5 calls/second. For higher limits, consider upgrading.

#### 3. External Contract Addresses (Pre-Deployed)

These contracts are already deployed on Base networks. Use the addresses below:

**Base Sepolia Testnet**:
- **USDC**: `0x036CbD53842c5426634e7929541eC2318f3dCF7e`
  - Verify: https://sepolia.basescan.org/address/0x036CbD53842c5426634e7929541eC2318f3dCF7e
  - Check: `cast code 0x036CbD53842c5426634e7929541eC2318f3dCF7e --rpc-url $BASE_SEPOLIA_RPC_URL`
  
- **EntryPoint (ERC-4337)**: `0x0000000071727De22E5E9d8BAf0edAc6f37da032`
  - Verify: https://sepolia.basescan.org/address/0x0000000071727De22E5E9d8BAf0edAc6f37da032
  - This is the standard ERC-4337 EntryPoint address
  
- **ERC6551 Registry**: `0x000000006551c19487814612e58FE06813775758`
  - Verify: https://sepolia.basescan.org/address/0x000000006551c19487814612e58FE06813775758
  - Standard ERC-6551 registry address

**Base Mainnet**:
- **USDC**: `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`
  - Verify: https://basescan.org/address/0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
  
- **EntryPoint**: `0x0000000071727De22E5E9d8BAf0edAc6f37da032`
  - Verify: https://basescan.org/address/0x0000000071727De22E5E9d8BAf0edAc6f37da032
  
- **ERC6551 Registry**: `0x000000006551c19487814612e58FE06813775758`
  - Verify: https://basescan.org/address/0x000000006551c19487814612e58FE06813775758

**How to Verify Addresses**:
```bash
# Check if contract exists (should return bytecode)
cast code $CONTRACT_ADDRESS --rpc-url $RPC_URL

# Get contract info from explorer
# Base Sepolia: https://sepolia.basescan.org/address/$ADDRESS
# Base Mainnet: https://basescan.org/address/$ADDRESS
```

#### 4. External Service Addresses (Optional)

For full functionality, you'll need addresses for:

**ZK Coprocessors**:

- **Axiom**:
  
  **Using Axiom CLI to Get Contract Address**:
  
  1. **Install Axiom CLI**:
     ```bash
     # Install cargo-axiom (requires Rust and Cargo)
     # If you don't have Rust, install it first: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
     cargo +1.86 install --locked --git https://github.com/axiom-crypto/axiom-api-cli.git --tag v1.0.1 cargo-axiom
     ```
  
  2. **Get API Key**:
     - Sign up at https://axiom.xyz
     - Navigate to Dashboard → API Keys
     - Generate new API key
     - Copy and save securely
  
  3. **Register with CLI**:
     ```bash
     # Set API key in environment
     export AXIOM_API_KEY=your_api_key_here
     
     # Register with Axiom CLI
     cargo axiom register --api-key $AXIOM_API_KEY
     ```
  
  4. **Get Contract Address**:
     ```bash
     # Get Axiom contract address for Base Sepolia
     cargo axiom get-address --chain-id 84532
     
     # Or for Base Mainnet
     cargo axiom get-address --chain-id 8453
     ```
  
     The output will provide the AxiomV2Query contract address for the specified network.
  
  5. **Add to `.env`**:
     ```bash
     # Copy the address from CLI output
     AXIOM_ADDRESS=0x...  # Address from CLI output
     ```
  
  **Alternative Method** (if CLI doesn't work):
  - Visit: https://docs.axiom.xyz/
  - Check "Contract Addresses" section
  - Find address for Base Sepolia (84532) or Base Mainnet (8453)
  - Add to `.env`: `AXIOM_ADDRESS=0x...`

- **Brevis**:
  
  **Method 1: Check Documentation**:
  
  1. Visit: https://docs.brevis.network/
  2. Navigate to "Deployments" or "Contract Addresses" section
  3. Look for Base Sepolia (Chain ID: 84532) or Base Mainnet (Chain ID: 8453)
  4. Find the Brevis ZK coprocessor contract address
  5. Add to `.env`: `BREVIS_ADDRESS=0x...`
  
  **Method 2: Contact Brevis Team**:
  
  1. Join Brevis Discord: https://discord.gg/brevis
  2. Ask in support channel for Base network contract addresses
  3. Or email: support@brevis.network
  
  **Method 3: Search BaseScan**:
  
  ```bash
  # Search for Brevis contracts on BaseScan
  # Go to: https://sepolia.basescan.org
  # Search: "Brevis" or "brevis"
  # Verify contract is official by checking with Brevis team
  ```
  
  **Verification**:
  ```bash
  # Verify contract exists
  cast code $BREVIS_ADDRESS --rpc-url $BASE_SEPOLIA_RPC_URL
  ```

**Oracles**:

- **UMA (Universal Market Access)**:
  
  **Method 1: Check UMA Documentation**:
  
  1. Visit: https://docs.umaproject.org/
  2. Navigate to "Contract Addresses" or "Deployments"
  3. Check if Optimistic Oracle is deployed on Base
  4. Look for Base Sepolia or Base Mainnet addresses
  5. Add to `.env`: `UMA_ADDRESS=0x...`
  
  **Method 2: Deploy UMA Contracts** (if not available on Base):
  
  If UMA contracts aren't deployed on Base, you may need to deploy them:
  
  1. **Clone UMA Contracts**:
     ```bash
     git clone https://github.com/UMAprotocol/protocol.git
     cd protocol
     ```
  
  2. **Install Dependencies**:
     ```bash
     npm install
     ```
  
  3. **Deploy Optimistic Oracle**:
     ```bash
     # Follow UMA deployment guide
     # See: https://docs.umaproject.org/developers/deployment
     ```
  
  4. **Save deployed address**:
     ```bash
     UMA_ADDRESS=<deployed_address>
     ```
  
  **Method 3: Use Cross-Chain Oracle**:
  
  If UMA isn't on Base, consider:
  - Using UMA's cross-chain capabilities
  - Deploying a minimal oracle adapter
  - Using alternative oracle service
  
  **Verification**:
  ```bash
  # Verify contract exists
  cast code $UMA_ADDRESS --rpc-url $BASE_SEPOLIA_RPC_URL
  
  # Check if it's an Optimistic Oracle
  cast call $UMA_ADDRESS "getCurrentTime()" --rpc-url $BASE_SEPOLIA_RPC_URL
  ```
  
  **Note**: UMA may not be deployed on Base yet. Check their documentation or contact UMA team for Base support.

- **Kleros**:
  
  **Method 1: Check Kleros Documentation**:
  
  1. Visit: https://docs.kleros.io/
  2. Navigate to "Deployments" or "Arbitrator Addresses"
  3. Check if Kleros arbitrator is deployed on Base
  4. Look for Base Sepolia or Base Mainnet addresses
  5. Add to `.env`: `KLEROS_ADDRESS=0x...`
  
  **Method 2: Deploy Kleros Contracts** (if not available on Base):
  
  If Kleros contracts aren't deployed on Base:
  
  1. **Clone Kleros Contracts**:
     ```bash
     git clone https://github.com/kleros/kleros-v2.git
     cd kleros-v2
     ```
  
  2. **Install Dependencies**:
     ```bash
     npm install
     # or
     yarn install
     ```
  
  3. **Deploy Arbitrator**:
     ```bash
     # Follow Kleros deployment guide
     # See: https://docs.kleros.io/developers/deployment
     ```
  
  4. **Save deployed address**:
     ```bash
     KLEROS_ADDRESS=<deployed_address>
     ```
  
  **Method 3: Use Kleros API** (if available):
  
  Some Kleros features may be accessible via API:
  
  1. Visit: https://docs.kleros.io/
  2. Check for REST API or GraphQL endpoints
  3. Get API credentials if needed
  4. Configure API in your integration (may not need contract address)
  
  **Method 4: Contact Kleros Team**:
  
  1. Join Kleros Discord: https://discord.gg/kleros
  2. Ask in support channel for Base network support
  3. Or email: support@kleros.io
  
  **Verification**:
  ```bash
  # Verify contract exists
  cast code $KLEROS_ADDRESS --rpc-url $BASE_SEPOLIA_RPC_URL
  
  # Check if it's an arbitrator contract
  cast call $KLEROS_ADDRESS "arbitrationCost(bytes)" "0x" --rpc-url $BASE_SEPOLIA_RPC_URL
  ```
  
  **Note**: Kleros may not be deployed on Base yet. Check their documentation or contact Kleros team for Base support.

### Quick Reference: Getting Optional Service Addresses

**Summary Table**:

| Service | Primary Method | Documentation | Support Contact |
|---------|---------------|--------------|-----------------|
| **Axiom** | CLI tool (`cargo axiom`) | https://docs.axiom.xyz/ | Discord/Email |
| **Brevis** | Documentation check | https://docs.brevis.network/ | Discord: brevis |
| **UMA** | Documentation or deploy | https://docs.umaproject.org/ | Discord/Email |
| **Kleros** | Documentation or deploy | https://docs.kleros.io/ | Discord: kleros |

**Step-by-Step Checklist**:

1. **Axiom** ✅
   - [ ] Install Rust (if needed): `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`
   - [ ] Install Axiom CLI: `cargo +1.86 install --locked --git https://github.com/axiom-crypto/axiom-api-cli.git --tag v1.0.1 cargo-axiom`
   - [ ] Sign up at https://axiom.xyz and get API key
   - [ ] Register CLI: `cargo axiom register --api-key $AXIOM_API_KEY`
   - [ ] Get address: `cargo axiom get-address --chain-id 84532` (or 8453 for mainnet)
   - [ ] Add to `.env`: `AXIOM_ADDRESS=<address_from_cli>`

2. **Brevis** ✅
   - [ ] Check https://docs.brevis.network/ for Base deployments
   - [ ] If not found, join Discord or contact support
   - [ ] Verify address on BaseScan
   - [ ] Add to `.env`: `BREVIS_ADDRESS=<address>`

3. **UMA** ✅
   - [ ] Check https://docs.umaproject.org/ for Base deployments
   - [ ] If not available, consider deploying UMA contracts
   - [ ] Or use alternative oracle solution
   - [ ] Add to `.env`: `UMA_ADDRESS=<address>`

4. **Kleros** ✅
   - [ ] Check https://docs.kleros.io/ for Base deployments
   - [ ] If not available, consider deploying Kleros contracts
   - [ ] Or use Kleros API (if available)
   - [ ] Add to `.env`: `KLEROS_ADDRESS=<address>`

**Verification Commands**:

```bash
# Verify all optional addresses are set (if configured)
echo "Axiom: ${AXIOM_ADDRESS:-NOT SET}"
echo "Brevis: ${BREVIS_ADDRESS:-NOT SET}"
echo "UMA: ${UMA_ADDRESS:-NOT SET}"
echo "Kleros: ${KLEROS_ADDRESS:-NOT SET}"

# Verify contracts exist on chain
for service in AXIOM BREVIS UMA KLEROS; do
  addr=$(eval echo \$${service}_ADDRESS)
  if [ -n "$addr" ]; then
    echo -n "$service ($addr): "
    cast code $addr --rpc-url $BASE_SEPOLIA_RPC_URL > /dev/null 2>&1 && echo "EXISTS" || echo "NOT FOUND"
  fi
done
```

**Troubleshooting**:

**Issue: Service not deployed on Base**

- **Solution 1**: Check if service supports Base network
- **Solution 2**: Deploy service contracts yourself (if open source)
- **Solution 3**: Use alternative service or skip optional features
- **Solution 4**: Contact service team for Base deployment timeline

**Issue: Can't find contract address in documentation**

- **Solution 1**: Search BaseScan for contract name
- **Solution 2**: Check service GitHub for deployment scripts
- **Solution 3**: Contact service support team
- **Solution 4**: Check service Discord/Telegram for community deployments

**Issue: Axiom CLI installation fails**

- **Solution 1**: Ensure Rust 1.86+ is installed: `rustc --version`
- **Solution 2**: Update Rust: `rustup update`
- **Solution 3**: Use alternative method: Check Axiom documentation directly
- **Solution 4**: Contact Axiom support for manual address lookup

**Issue: Contract address doesn't work**

- **Solution 1**: Verify network (Base Sepolia vs Base Mainnet)
- **Solution 2**: Check contract has bytecode: `cast code $ADDRESS --rpc-url $RPC_URL`
- **Solution 3**: Verify address format (should start with 0x and be 42 chars)
- **Solution 4**: Confirm with service team that address is correct

**Note**: External services are **optional**. The protocol works without them, but certain features require them:
- **Without Axiom/Brevis**: ZK proof verification features won't work
- **Without UMA**: Oracle-based claim resolution won't work
- **Without Kleros**: Dispute resolution features won't work

You can deploy and test the core protocol without these services, then add them later when needed.

#### 5. Deployed Contract Addresses (After Deployment)

These addresses are generated **after** you deploy the contracts. They will be printed in the deployment output.

**How to Get Deployed Addresses**:

1. **During Deployment**:
   ```bash
   # Addresses will be printed in console output
   forge script script/DeployBaseSepolia.s.sol \
     --rpc-url $BASE_SEPOLIA_RPC_URL \
     --broadcast \
     -vvv
   ```

2. **From Deployment Output**:
   ```
   [1/8] Deploying SimpleAccountImplementation...
   SimpleAccountImplementation: 0x1234...5678
   
   [2/8] Deploying AgentLicense...
   AgentLicense: 0xabcd...ef01
   ```

3. **From Broadcast Logs**:
   ```bash
   # Check broadcast logs
   cat broadcast/DeployBaseSepolia.s.sol/84532/run-latest.json
   # Look for "contractAddress" fields
   ```

4. **From BaseScan**:
   - Go to your deployer address on BaseScan
   - View "Internal Txns" or "Contract Creation" transactions
   - Click on each contract creation to see the deployed address

5. **Using Cast** (if you know transaction hash):
   ```bash
   # Get contract address from deployment transaction
   cast receipt $TX_HASH --rpc-url $RPC_URL | grep contractAddress
   ```

6. **Update `.env` File**:
   After getting all addresses, update your `.env`:
   ```bash
   AGENT_LICENSE=0x...
   AGENT_REGISTRY=0x...
   INSURANCE_VAULT=0x...
   REPUTATION_SCORE=0x...
   PAYMASTER=0x...
   MERCHANT_SDK=0x...
   SIMPLE_ACCOUNT_IMPL=0x...
   ```

**Verification Script**:
```bash
# Verify all addresses are set
forge script script/VerifyDeployment.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL
```

---

## Environment Setup

### Step 1: Create `.env` File

Create a `.env` file in the project root:

```bash
# ============================================
# DEPLOYMENT CONFIGURATION
# ============================================

# Deployer Private Key (NEVER commit this!)
PRIVATE_KEY=your_private_key_here

# Optional: Fee receiver (defaults to deployer)
FEE_RECEIVER=your_fee_receiver_address

# ============================================
# NETWORK CONFIGURATION
# ============================================

# Base Sepolia Testnet
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
BASESCAN_API_KEY=your_basescan_api_key

# Base Mainnet
BASE_RPC_URL=https://mainnet.base.org

# ============================================
# CONTRACT ADDRESSES (Set after deployment)
# ============================================
AGENT_LICENSE=
AGENT_REGISTRY=
INSURANCE_VAULT=
REPUTATION_SCORE=
PAYMASTER=
MERCHANT_SDK=
SIMPLE_ACCOUNT_IMPL=

# ============================================
# EXTERNAL CONTRACTS
# ============================================

# Base Sepolia
USDC_BASE_SEPOLIA=0x036CbD53842c5426634e7929541eC2318f3dCF7e
ENTRY_POINT_BASE_SEPOLIA=0x0000000071727De22E5E9d8BAf0edAc6f37da032
ERC6551_REGISTRY=0x000000006551c19487814612e58FE06813775758

# Base Mainnet
USDC_BASE_MAINNET=0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
ENTRY_POINT_BASE_MAINNET=0x0000000071727De22E5E9d8BAf0edAc6f37da032

# ============================================
# EXTERNAL SERVICES (Optional)
# ============================================
AXIOM_ADDRESS=
BREVIS_ADDRESS=
UMA_ADDRESS=
KLEROS_ADDRESS=

# ============================================
# CONFIGURATION
# ============================================
PAYMASTER_FUNDING=1000000000000000000  # 1 ETH in wei
```

### Step 2: Secure Your Environment

```bash
# Ensure .env is in .gitignore
echo ".env" >> .gitignore

# Set proper permissions (Unix/Mac)
chmod 600 .env

# Load environment variables
source .env

# Verify (don't print private key!)
echo "RPC URL: $BASE_SEPOLIA_RPC_URL"
echo "API Key: ${BASESCAN_API_KEY:0:10}..."
```

### Step 3: Verify Network Access

```bash
# Test Base Sepolia connection
cast block-number --rpc-url $BASE_SEPOLIA_RPC_URL

# Test Base mainnet connection
cast block-number --rpc-url $BASE_RPC_URL

# Check deployer balance
cast balance $(cast wallet address $PRIVATE_KEY) --rpc-url $BASE_SEPOLIA_RPC_URL
```

---

## Pre-Deployment Checks

### Step 1: Build Contracts

```bash
# Build all contracts
forge build

# Verify no errors
# Check output/ directory for compiled contracts
```

**Expected Output**:
- All contracts compile successfully
- No warnings (or acceptable warnings documented)
- Artifacts generated in `out/`

### Step 2: Run Test Suite

```bash
# Run all tests
forge test -vvv

# Run with gas report
forge test --gas-report > gas_report.txt

# Generate coverage report
forge coverage
```

**Verification**:
- ✅ All tests pass (target: 90%+ pass rate)
- ✅ Test coverage acceptable (target: 90%+)
- ✅ No critical test failures

### Step 3: Security Checks

```bash
# Run security checklist
./script/security-checklist.sh

# Run security analysis (if tools installed)
./script/security-analysis.sh
```

**Verification**:
- ✅ Security checklist passes
- ✅ No critical security issues
- ✅ All known issues documented

### Step 4: Pre-Deployment Script

```bash
# Run automated pre-deployment checks
forge script script/PreDeploymentCheck.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL
```

**Checks Performed**:
- ✅ Environment variables set
- ✅ Network accessible
- ✅ Sufficient balance (> 0.1 ETH)
- ✅ External contracts accessible (ERC6551Registry, USDC, EntryPoint)
- ✅ Contracts compile
- ✅ All dependencies available

---

## Testnet Deployment

### Option 1: Automated Deployment (Recommended)

```bash
# Make script executable
chmod +x script/deploy-testnet.sh

# Run automated deployment
./script/deploy-testnet.sh
```

**What It Does**:
1. Runs pre-deployment checks
2. Builds contracts
3. Deploys all contracts
4. Verifies contracts on BaseScan
5. Runs post-deployment setup
6. Runs health check
7. Saves deployment addresses

### Option 2: Manual Deployment

#### Step 1: Deploy Contracts

```bash
# Deploy to Base Sepolia
forge script script/DeployBaseSepolia.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY \
  -vvv
```

**During Deployment**:
- Watch for deployment addresses in console output
- Note any errors or warnings
- Save deployment output to file

**Expected Output**:
```
===========================================
KYA Protocol - Base Sepolia Deployment
===========================================
Deployer: 0x...
Chain ID: 84532
Network: Base Sepolia Testnet
===========================================

[1/8] Deploying SimpleAccountImplementation...
SimpleAccountImplementation: 0x...

[2/8] Deploying AgentLicense...
AgentLicense: 0x...

... (continues for all contracts)
```

#### Step 2: Save Contract Addresses

After deployment, update your `.env` file:

```bash
# From deployment output, update:
AGENT_LICENSE=<deployed_address>
AGENT_REGISTRY=<deployed_address>
INSURANCE_VAULT=<deployed_address>
REPUTATION_SCORE=<deployed_address>
PAYMASTER=<deployed_address>
MERCHANT_SDK=<deployed_address>
SIMPLE_ACCOUNT_IMPL=<deployed_address>
```

#### Step 3: Verify Contracts on BaseScan

For each contract, verify on BaseScan:

**Manual Verification**:
1. Go to: https://sepolia.basescan.org/address/<CONTRACT_ADDRESS>
2. Click "Contract" tab
3. Click "Verify and Publish"
4. Fill in:
   - Compiler: `v0.8.28+commit.xxx`
   - License: `MIT`
   - Optimization: `200`
   - Constructor arguments: (from deployment)

**Automated Verification** (if not done during deployment):

```bash
# For each contract
forge verify-contract <CONTRACT_ADDRESS> \
  <CONTRACT_NAME> \
  --chain-id 84532 \
  --etherscan-api-key $BASESCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(...)" <args>)
```

**Checklist**:
- [ ] SimpleAccountImplementation verified
- [ ] AgentLicense verified
- [ ] AgentRegistry verified
- [ ] ReputationScore verified
- [ ] InsuranceVault verified
- [ ] Paymaster verified
- [ ] MerchantSDK verified

---

## Mainnet Deployment

> ⚠️ **WARNING**: Mainnet deployment is irreversible. Ensure all tests pass, security audit is complete, and testnet deployment is thoroughly tested.

### Pre-Mainnet Checklist

Before deploying to mainnet, ensure:

- [ ] All testnet tests pass
- [ ] Security audit complete
- [ ] All audit findings addressed
- [ ] Testnet deployment tested for 2+ weeks
- [ ] Monitoring configured
- [ ] Incident response plan ready
- [ ] Team trained on procedures
- [ ] Rollback plan documented

### Step 1: Final Code Review

```bash
# Ensure you're on the correct branch
git checkout main
git pull origin main

# Verify no uncommitted changes
git status

# Run final tests
forge test
```

### Step 2: Deploy to Mainnet

```bash
# Set mainnet environment
export BASE_RPC_URL=https://mainnet.base.org
export USDC_ADDRESS=0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
export ENTRY_POINT_ADDRESS=0x0000000071727De22E5E9d8BAf0edAc6f37da032

# Deploy to Base mainnet
forge script script/DeployBase.s.sol \
  --rpc-url $BASE_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY \
  -vvv \
  --slow
```

**Note**: The `--slow` flag adds delays between transactions to avoid rate limiting.

### Step 3: Save Mainnet Addresses

Update your `.env` file with mainnet addresses:

```bash
# Create separate mainnet addresses section
AGENT_LICENSE_MAINNET=<deployed_address>
AGENT_REGISTRY_MAINNET=<deployed_address>
# ... (all contracts)
```

### Step 4: Verify on BaseScan

Verify all contracts on BaseScan mainnet:

- BaseScan Mainnet: https://basescan.org

---

## Post-Deployment Setup

### Step 1: Run Post-Deployment Script

```bash
# Automated post-deployment setup
forge script script/PostDeploymentSetup.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast \
  -vvv
```

**What It Does**:
- Deploys integration adapters (if configured)
- Grants roles to external services (if addresses set)
- Funds Paymaster (if funding set)

### Step 2: Grant Roles Manually

If external service addresses weren't set in `.env`, grant roles manually:

**Note**: If you haven't set `AXIOM_ADDRESS` yet, use the Axiom CLI to get it:
```bash
# Get Axiom contract address using CLI
cargo axiom get-address --chain-id 84532  # For Base Sepolia
# Then add to .env: AXIOM_ADDRESS=<address_from_cli>
```

#### Grant ZK_PROVER_ROLE

```bash
# Get role hash
ZK_ROLE=$(cast keccak "ZK_PROVER_ROLE()")

# Grant to Axiom (if configured)
# Make sure AXIOM_ADDRESS is set in .env (use CLI to get it if needed)
cast send $REPUTATION_SCORE \
  "grantRole(bytes32,address)" \
  $ZK_ROLE \
  $AXIOM_ADDRESS \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# Grant to Brevis (if configured)
cast send $REPUTATION_SCORE \
  "grantRole(bytes32,address)" \
  $ZK_ROLE \
  $BREVIS_ADDRESS \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

#### Grant ORACLE_ROLE

```bash
# Get role hash
ORACLE_ROLE=$(cast keccak "ORACLE_ROLE()")

# Grant to UMA (if configured)
cast send $INSURANCE_VAULT \
  "grantRole(bytes32,address)" \
  $ORACLE_ROLE \
  $UMA_ADDRESS \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# Grant to Kleros (if configured)
cast send $INSURANCE_VAULT \
  "grantRole(bytes32,address)" \
  $ORACLE_ROLE \
  $KLEROS_ADDRESS \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

### Step 3: Fund Paymaster

```bash
# Fund Paymaster with ETH
cast send $PAYMASTER \
  "deposit()" \
  --value 1ether \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# Check balance
cast call $PAYMASTER \
  "getDeposit()" \
  --rpc-url $BASE_SEPOLIA_RPC_URL
```

**Recommended Funding**:
- **Testnet**: 0.5-1 ETH
- **Mainnet**: 5-10 ETH (adjust based on expected usage)

### Step 4: Configure Integration Adapters

If using integration adapters:

```bash
# Deploy ZKAdapter
forge script script/SetupIntegrations.s.sol:DeployZKAdapter \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast

# Deploy OracleAdapter
forge script script/SetupIntegrations.s.sol:DeployOracleAdapter \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast
```

---

## Verification & Testing

### Step 1: Verify Deployment

```bash
# Run deployment verification script
forge script script/VerifyDeployment.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL
```

**Verification Checks**:
- ✅ All contracts deployed
- ✅ Roles assigned correctly
- ✅ Contract interactions work
- ✅ Configuration correct
- ✅ External contracts accessible

### Step 2: Health Check

```bash
# Run health check script
forge script script/HealthCheck.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL
```

**Health Check Validates**:
- ✅ All contracts deployed
- ✅ Contract state correct
- ✅ Roles assigned
- ✅ External contracts accessible
- ✅ Balances correct

### Step 3: Testnet Testing

```bash
# Run testnet test suite
forge script script/TestnetTesting.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast \
  -vvv
```

**Test Scenarios**:
- [ ] Agent minting works
- [ ] TBA creation works
- [ ] Staking works (if USDC available)
- [ ] Proof verification works (if role granted)
- [ ] Merchant verification works
- [ ] Paymaster eligibility works

**Note**: Some tests may require:
- Test USDC in TBA (get from faucet or mint)
- ZK_PROVER_ROLE granted to test address
- Sufficient ETH for gas

### Step 4: End-to-End Testing

Test complete user flows:

1. **Agent Registration Flow**:
   ```bash
   # Mint agent license
   cast send $AGENT_REGISTRY \
     "registerAgent(string)" \
     "test-agent" \
     --value 0.001ether \
     --rpc-url $BASE_SEPOLIA_RPC_URL \
     --private-key $PRIVATE_KEY
   ```

2. **Staking Flow**:
   ```bash
   # Approve USDC
   cast send $USDC_ADDRESS \
     "approve(address,uint256)" \
     $INSURANCE_VAULT \
     1000000000 \
     --rpc-url $BASE_SEPOLIA_RPC_URL \
     --private-key $PRIVATE_KEY
   
   # Stake USDC
   cast send $INSURANCE_VAULT \
     "stake(uint256)" \
     1000000000 \
     --rpc-url $BASE_SEPOLIA_RPC_URL \
     --private-key $PRIVATE_KEY
   ```

3. **Reputation Update Flow**:
   - Requires ZK proof (if using ZKAdapter)
   - Or manual update (if admin)

---

## Monitoring & Maintenance

### Step 1: Set Up Monitoring

#### Option A: Tenderly

1. Sign up at https://tenderly.co
2. Add project
3. Configure monitoring:
   - Contract addresses
   - Event monitoring
   - Alert rules

#### Option B: OpenZeppelin Defender

1. Sign up at https://defender.openzeppelin.com
2. Create project
3. Add contracts
4. Configure monitoring and alerts

#### Option C: Custom Monitoring

```bash
# Use monitoring script
./script/monitor-contracts.sh
```

### Step 2: Configure Alerts

Set up alerts for:

- **Critical Events**:
  - Agent registration
  - Large stakes/unstakes
  - Claim submissions
  - Role changes

- **Anomalies**:
  - Unusual gas usage
  - Failed transactions
  - Contract errors

### Step 3: Regular Health Checks

```bash
# Schedule regular health checks
# Add to cron or CI/CD pipeline
forge script script/HealthCheck.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL
```

### Step 4: Monitor Gas Usage

```bash
# Generate gas report
forge test --gas-report > gas_report.txt

# Compare with benchmarks
```

### Step 5: Track Metrics

Key metrics to track:

- Agent registrations per day
- Total staked USDC
- Active agents
- Claims submitted/resolved
- Paymaster usage
- Gas costs

---

## Troubleshooting

### Common Issues

#### Issue 1: Insufficient Balance

**Error**: `insufficient funds`

**Solution**:
```bash
# Check balance
cast balance $DEPLOYER_ADDRESS --rpc-url $BASE_SEPOLIA_RPC_URL

# Get more ETH from faucet
# Base Sepolia: https://www.coinbase.com/faucets/base-ethereum-goerli-faucet
```

#### Issue 2: Contract Verification Fails

**Error**: `Contract verification failed`

**Solution**:
1. Check constructor arguments match deployment
2. Verify compiler version matches
3. Check optimization settings (200 runs)
4. Try manual verification on BaseScan
5. Verify license is MIT

#### Issue 3: Role Granting Fails

**Error**: `AccessControl: account is missing role`

**Solution**:
```bash
# Verify deployer has admin role
cast call $CONTRACT \
  "hasRole(bytes32,address)" \
  $(cast keccak "DEFAULT_ADMIN_ROLE()") \
  $DEPLOYER_ADDRESS \
  --rpc-url $BASE_SEPOLIA_RPC_URL

# Grant role manually if needed
cast send $CONTRACT \
  "grantRole(bytes32,address)" \
  $(cast keccak "ROLE_NAME()") \
  $TARGET_ADDRESS \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

#### Issue 4: External Contracts Not Found

**Error**: `Contract not found`

**Solution**:
```bash
# Verify network
cast chain-id --rpc-url $BASE_SEPOLIA_RPC_URL
# Should return: 84532

# Check contract exists
cast code $CONTRACT_ADDRESS --rpc-url $BASE_SEPOLIA_RPC_URL
# Should return bytecode

# Verify addresses in .env match network
```

#### Issue 5: Tests Fail

**Error**: Test failures

**Solution**:
1. Check USDC balance in TBA
2. Verify roles granted
3. Check gas limits
4. Review test logs
5. Ensure test accounts have sufficient ETH

#### Issue 6: Deployment Script Fails

**Error**: Script execution fails

**Solution**:
1. Check RPC URL is accessible
2. Verify private key is correct
3. Check network connectivity
4. Review script logs (`-vvv` flag)
5. Ensure all dependencies installed

### Getting Help

1. **Check Logs**: Review deployment output and error messages
2. **Review Documentation**: Check `docs/` directory
3. **Verify Configuration**: Double-check `.env` file
4. **Test Network**: Verify RPC endpoint is working
5. **Community**: Check GitHub issues or Discord

---

## Rollback Procedures

### When to Rollback

Consider rollback if:

- Critical security vulnerability discovered
- Major functionality broken
- Unexpected behavior affecting users
- High-value funds at risk

### Rollback Process

#### Step 1: Assess Situation

```bash
# Check contract state
forge script script/HealthCheck.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL

# Review recent transactions
# Check monitoring alerts
```

#### Step 2: Pause Contracts (if supported)

```bash
# Pause contracts with pause functionality
cast send $CONTRACT \
  "pause()" \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

#### Step 3: Emergency Procedures

1. **Revoke Roles**: Remove problematic role grants
2. **Drain Funds**: Move funds to safe address (if needed)
3. **Notify Users**: Communicate issue and resolution plan

#### Step 4: Deploy Fixed Version

```bash
# After fixing issues, redeploy
forge script script/DeployBaseSepolia.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

### Rollback Script

```bash
# Run rollback script (if available)
forge script script/Rollback.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast
```

---

## Deployment Checklist

### Pre-Deployment

- [ ] Foundry installed and updated
- [ ] Dependencies installed (`forge install`)
- [ ] `.env` file created and configured
- [ ] Private key secured (not committed)
- [ ] Sufficient balance for deployment
- [ ] BaseScan API key obtained
- [ ] Network connectivity verified
- [ ] Contracts build successfully
- [ ] All tests pass
- [ ] Security checks pass
- [ ] Pre-deployment script passes

### Deployment

- [ ] Contracts deployed successfully
- [ ] All contract addresses saved
- [ ] Contracts verified on BaseScan
- [ ] Deployment verified
- [ ] Health check passes

### Post-Deployment

- [ ] Post-deployment setup complete
- [ ] Roles granted (if applicable)
- [ ] Paymaster funded
- [ ] Integration adapters deployed (if applicable)
- [ ] Testnet testing complete
- [ ] End-to-end flows tested
- [ ] Monitoring configured
- [ ] Alerts set up
- [ ] Documentation updated

### Mainnet (Additional)

- [ ] Security audit complete
- [ ] Testnet tested for 2+ weeks
- [ ] All issues resolved
- [ ] Team trained
- [ ] Incident response plan ready
- [ ] Rollback plan documented
- [ ] Final code review complete

---

## Address Acquisition Quick Reference

### Required Addresses Checklist

Use this checklist to ensure you have all required addresses before deployment:

#### ✅ Pre-Deployment (Required)

- [ ] **Deployer Account Address**
  - Method: `cast wallet address $PRIVATE_KEY` or from wallet
  - Balance: > 0.5 ETH (testnet) or > 1 ETH (mainnet)
  - Source: Your wallet or `cast wallet new`

- [ ] **BaseScan API Key**
  - Method: https://basescan.org/myapikey
  - Purpose: Contract verification
  - Format: Alphanumeric string

#### ✅ Pre-Deployed Contracts (Required - Use Provided Addresses)

- [ ] **USDC Address**
  - Base Sepolia: `0x036CbD53842c5426634e7929541eC2318f3dCF7e`
  - Base Mainnet: `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`
  - Verify: Check on BaseScan explorer

- [ ] **EntryPoint Address**
  - Both Networks: `0x0000000071727De22E5E9d8BAf0edAc6f37da032`
  - Verify: Standard ERC-4337 EntryPoint

- [ ] **ERC6551 Registry Address**
  - Both Networks: `0x000000006551c19487814612e58FE06813775758`
  - Verify: Standard ERC-6551 registry

#### ⚠️ Optional External Services

- [ ] **Axiom Address** (Optional)
  - **Primary Method**: Use Axiom CLI
    1. Install: `cargo +1.86 install --locked --git https://github.com/axiom-crypto/axiom-api-cli.git --tag v1.0.1 cargo-axiom`
    2. Get API key from https://axiom.xyz
    3. Register: `cargo axiom register --api-key $AXIOM_API_KEY`
    4. Get address: `cargo axiom get-address --chain-id 84532` (or 8453 for mainnet)
  - **Alternative**: Check https://docs.axiom.xyz/ or contact team
  - **Purpose**: ZK proof verification
  - **Add to `.env`**: `AXIOM_ADDRESS=0x...`

- [ ] **Brevis Address** (Optional)
  - **Method 1**: Check https://docs.brevis.network/ for Base deployments
  - **Method 2**: Join Brevis Discord or contact support@brevis.network
  - **Method 3**: Search BaseScan for Brevis contracts
  - **Purpose**: ZK proof verification
  - **Add to `.env`**: `BREVIS_ADDRESS=0x...`

- [ ] **UMA Address** (Optional)
  - **Method 1**: Check https://docs.umaproject.org/ for Base deployments
  - **Method 2**: Deploy UMA contracts yourself (if not available)
  - **Method 3**: Use alternative oracle service
  - **Purpose**: Oracle-based claims
  - **Add to `.env`**: `UMA_ADDRESS=0x...`
  - **Note**: May not be deployed on Base yet

- [ ] **Kleros Address** (Optional)
  - **Method 1**: Check https://docs.kleros.io/ for Base deployments
  - **Method 2**: Deploy Kleros contracts yourself (if not available)
  - **Method 3**: Use Kleros API (if available)
  - **Method 4**: Join Kleros Discord or contact support@kleros.io
  - **Purpose**: Dispute resolution
  - **Add to `.env`**: `KLEROS_ADDRESS=0x...`
  - **Note**: May not be deployed on Base yet

#### 📝 Post-Deployment (Generated After Deployment)

- [ ] **SimpleAccountImplementation**
  - Source: Deployment output
  - Save to: `SIMPLE_ACCOUNT_IMPL` in `.env`

- [ ] **AgentLicense**
  - Source: Deployment output
  - Save to: `AGENT_LICENSE` in `.env`

- [ ] **AgentRegistry**
  - Source: Deployment output
  - Save to: `AGENT_REGISTRY` in `.env`

- [ ] **ReputationScore**
  - Source: Deployment output
  - Save to: `REPUTATION_SCORE` in `.env`

- [ ] **InsuranceVault**
  - Source: Deployment output
  - Save to: `INSURANCE_VAULT` in `.env`

- [ ] **Paymaster**
  - Source: Deployment output
  - Save to: `PAYMASTER` in `.env`

- [ ] **MerchantSDK**
  - Source: Deployment output
  - Save to: `MERCHANT_SDK` in `.env`

### Quick Commands to Get Addresses

```bash
# Get deployer address from private key
cast wallet address $PRIVATE_KEY

# Check deployer balance
cast balance $(cast wallet address $PRIVATE_KEY) --rpc-url $BASE_SEPOLIA_RPC_URL

# Verify external contract exists
cast code $CONTRACT_ADDRESS --rpc-url $RPC_URL

# Get contract address from deployment transaction
cast receipt $TX_HASH --rpc-url $RPC_URL | grep contractAddress

# Extract all addresses from deployment logs
jq '.transactions[] | select(.contractName != null) | {name: .contractName, address: .contractAddress}' \
  broadcast/DeployBaseSepolia.s.sol/84532/run-latest.json
```

### Address Verification

After obtaining addresses, verify them:

```bash
# Verify all required addresses are set
grep -E "^(PRIVATE_KEY|BASESCAN_API_KEY|USDC|ENTRY_POINT|ERC6551)" .env

# Verify deployed contracts exist
for addr in $AGENT_LICENSE $AGENT_REGISTRY $INSURANCE_VAULT; do
  cast code $addr --rpc-url $BASE_SEPOLIA_RPC_URL && echo "$addr: OK" || echo "$addr: NOT FOUND"
done
```

---

## Quick Reference

### Deployment Commands

```bash
# Testnet
forge script script/DeployBaseSepolia.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY

# Mainnet
forge script script/DeployBase.s.sol \
  --rpc-url $BASE_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY \
  --slow
```

### Verification Commands

```bash
# Verify deployment
forge script script/VerifyDeployment.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL

# Health check
forge script script/HealthCheck.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL
```

### Useful Cast Commands

```bash
# Check balance
cast balance $ADDRESS --rpc-url $RPC_URL

# Get role hash
cast keccak "ROLE_NAME()"

# Check role
cast call $CONTRACT \
  "hasRole(bytes32,address)" \
  $ROLE_HASH \
  $ADDRESS \
  --rpc-url $RPC_URL

# Grant role
cast send $CONTRACT \
  "grantRole(bytes32,address)" \
  $ROLE_HASH \
  $ADDRESS \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY
```

---

## Network Information

### Base Sepolia Testnet

- **Chain ID**: 84532
- **RPC URL**: https://sepolia.base.org
- **Explorer**: https://sepolia.basescan.org
- **Faucet**: https://www.coinbase.com/faucets/base-ethereum-goerli-faucet

**Contract Addresses**:
- ERC6551 Registry: `0x000000006551c19487814612e58FE06813775758`
- USDC: `0x036CbD53842c5426634e7929541eC2318f3dCF7e`
- EntryPoint: `0x0000000071727De22E5E9d8BAf0edAc6f37da032`

### Base Mainnet

- **Chain ID**: 8453
- **RPC URL**: https://mainnet.base.org
- **Explorer**: https://basescan.org

**Contract Addresses**:
- ERC6551 Registry: `0x000000006551c19487814612e58FE06813775758`
- USDC: `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`
- EntryPoint: `0x0000000071727De22E5E9d8BAf0edAc6f37da032`

---

## Additional Resources

### Documentation

- **Technical Docs**: `docs/`
- **Security Guide**: `docs/SECURITY.md`
- **Integration Guide**: `docs/INTEGRATIONS.md`
- **Monitoring Guide**: `docs/MONITORING.md`
- **Testnet Deployment**: `docs/TESTNET_DEPLOYMENT.md`

### Scripts

- **Deployment**: `script/DeployBaseSepolia.s.sol`, `script/DeployBase.s.sol`
- **Verification**: `script/VerifyDeployment.s.sol`
- **Health Check**: `script/HealthCheck.s.sol`
- **Setup**: `script/PostDeploymentSetup.s.sol`

### External Resources

- **Foundry Book**: https://book.getfoundry.sh
- **Base Documentation**: https://docs.base.org
- **BaseScan**: https://basescan.org
- **OpenZeppelin**: https://docs.openzeppelin.com

---

## Support

### Getting Help

1. **Documentation**: Check `docs/` directory
2. **Issues**: Review GitHub issues
3. **Community**: Join Discord/Telegram
4. **Security**: security@kya.protocol

### Emergency Contacts

- **Security Issues**: security@kya.protocol
- **Technical Support**: team@kya.protocol

---

## Future Updates

### Planned Enhancements

#### Q1 2026
- [ ] Enhanced deployment automation with multi-sig support
- [ ] Improved verification scripts with retry logic
- [ ] Deployment monitoring dashboard
- [ ] Automated health check alerts

#### Q2 2026
- [ ] Cross-chain deployment support
- [ ] Upgradeable contract deployment patterns
- [ ] Enhanced rollback procedures
- [ ] Deployment cost optimization

#### Q3 2026
- [ ] Multi-network deployment automation
- [ ] Advanced monitoring and alerting
- [ ] Deployment analytics and reporting
- [ ] Enhanced security verification

### Known Limitations

1. **Manual Configuration**: Some deployment steps require manual configuration (API keys, addresses)
2. **Network-Specific**: Current deployment scripts are optimized for Base network
3. **Verification**: Contract verification requires BaseScan API keys

---

**Last Updated**: 2026-01-06  
**Version**: 2.0  
**Status**: Production Ready
