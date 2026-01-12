# KYA Protocol - Deployment Checklist

**Network**: Base Sepolia Testnet  
**Date**: 2026-01-06  
**Status**: Ready for Deployment

---

## 📋 Pre-Deployment Checklist

### 1. Prerequisites

#### Required Tools
- [ ] **Foundry Installed**
  ```bash
  curl -L https://foundry.paradigm.xyz | bash
  foundryup
  ```
  Verify: `forge --version`

- [ ] **Git Repository Cloned**
  ```bash
  git clone <repository-url>
  cd KYA
  ```

- [ ] **Dependencies Installed**
  ```bash
  forge install
  ```

#### Required Accounts & Services
- [ ] **Deployer Account**
  - Address: `_________________`
  - Balance: Need > 0.5 ETH on Base Sepolia
  - Private Key: Store securely (use environment variable)

- [ ] **BaseScan API Key** (for contract verification)
  - Get from: https://basescan.org/myapikey
  - API Key: `_________________`

- [ ] **External Service Addresses** (Optional, can configure later)
  - Axiom Address: `_________________` (optional)
  - Brevis Address: `_________________` (optional)
  - UMA Address: `_________________` (optional)
  - Kleros Address: `_________________` (optional)

---

### 2. Environment Setup

#### Create `.env` File

Create a `.env` file in the project root:

```bash
# ============================================
# DEPLOYMENT CONFIGURATION
# ============================================

# Deployer Private Key (NEVER commit this!)
PRIVATE_KEY=your_private_key_here

# Network Configuration
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
BASESCAN_API_KEY=your_basescan_api_key

# ============================================
# CONTRACT ADDRESSES (Set after deployment)
# ============================================
AGENT_LICENSE=
AGENT_REGISTRY=
INSURANCE_VAULT=
REPUTATION_SCORE=
PAYMASTER=
MERCHANT_SDK=

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
USDC_ADDRESS=0x036CbD53842c5426634e7929541eC2318f3dCF7e
ENTRY_POINT_ADDRESS=0x0000000071727De22E5E9d8BAf0edAc6f37da032
PAYMASTER_FUNDING=1000000000000000000  # 1 ETH in wei
```

#### Verify Environment Variables

```bash
# Load environment variables
source .env

# Verify they're set (don't print private key!)
echo "RPC URL: $BASE_SEPOLIA_RPC_URL"
echo "API Key: ${BASESCAN_API_KEY:0:10}..."
```

**Checklist**:
- [ ] `.env` file created
- [ ] `PRIVATE_KEY` set (keep secure!)
- [ ] `BASE_SEPOLIA_RPC_URL` set
- [ ] `BASESCAN_API_KEY` set
- [ ] `.env` added to `.gitignore` (IMPORTANT!)

---

### 3. Pre-Deployment Verification

#### Step 1: Build Contracts

```bash
forge build
```

**Verify**:
- [ ] Contracts compile without errors
- [ ] No warnings (or acceptable warnings documented)

#### Step 2: Run Tests

```bash
forge test
```

**Verify**:
- [ ] All tests pass
- [ ] Test coverage acceptable

#### Step 3: Run Security Checks

```bash
# Security checklist
./script/security-checklist.sh

# Security analysis (if tools installed)
./script/security-analysis.sh
```

**Verify**:
- [ ] Security checklist passes
- [ ] No critical security issues

#### Step 4: Pre-Deployment Check

```bash
forge script script/PreDeploymentCheck.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL
```

**Verify**:
- [ ] Environment variables set
- [ ] Network accessible
- [ ] Sufficient balance (> 0.1 ETH)
- [ ] External contracts accessible
- [ ] All checks pass

---

## 🚀 Deployment Steps

### Step 1: Deploy Contracts

#### Option A: Automated Deployment (Recommended)

```bash
./script/deploy-testnet.sh
```

This will:
1. Run pre-deployment checks
2. Build contracts
3. Deploy all contracts
4. Verify deployment
5. Run post-deployment setup
6. Run health check

#### Option B: Manual Deployment

```bash
forge script script/DeployBaseSepolia.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY \
  -vvv
```

**During Deployment**:
- [ ] Watch for deployment addresses
- [ ] Note any errors or warnings
- [ ] Save deployment output

**After Deployment**:
- [ ] Copy all contract addresses from output
- [ ] Save to `.env` file
- [ ] Save to deployment log

---

### Step 2: Save Contract Addresses

Update your `.env` file with deployed addresses:

```bash
# From deployment output, update:
AGENT_LICENSE=<deployed_address>
AGENT_REGISTRY=<deployed_address>
INSURANCE_VAULT=<deployed_address>
REPUTATION_SCORE=<deployed_address>
PAYMASTER=<deployed_address>
MERCHANT_SDK=<deployed_address>
```

**Checklist**:
- [ ] All addresses saved to `.env`
- [ ] Addresses verified on BaseScan
- [ ] Deployment info saved (check `deployments/` folder)

---

### Step 3: Verify Contracts on BaseScan

For each contract, verify on BaseScan:

1. Go to: https://sepolia.basescan.org/address/<CONTRACT_ADDRESS>
2. Click "Contract" tab
3. Click "Verify and Publish"
4. Fill in:
   - Compiler: `v0.8.28+commit.xxx`
   - License: `MIT`
   - Optimization: `200`
   - Constructor arguments: (from deployment)

**Or use Foundry**:

```bash
# For each contract, run:
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

### Step 4: Verify Deployment

```bash
# Reload environment
source .env

# Run verification script
forge script script/VerifyDeployment.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL
```

**Verify**:
- [ ] All contracts deployed
- [ ] Roles assigned correctly
- [ ] Contract interactions work
- [ ] Configuration correct
- [ ] External contracts accessible

---

### Step 5: Post-Deployment Setup

#### Run Post-Deployment Script

```bash
forge script script/PostDeploymentSetup.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast \
  -vvv
```

This will:
- Deploy integration adapters
- Grant roles (if addresses set)
- Fund Paymaster (if funding set)

#### Manual Role Granting (if needed)

If external service addresses weren't set in `.env`, grant roles manually:

**Grant ZK_PROVER_ROLE**:

```bash
# Get role hash
ROLE=$(cast keccak "ZK_PROVER_ROLE()")

# Grant to Axiom
cast send $REPUTATION_SCORE \
  "grantRole(bytes32,address)" \
  $ROLE \
  $AXIOM_ADDRESS \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# Grant to Brevis (if applicable)
cast send $REPUTATION_SCORE \
  "grantRole(bytes32,address)" \
  $ROLE \
  $BREVIS_ADDRESS \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

**Grant ORACLE_ROLE**:

```bash
# Get role hash
ROLE=$(cast keccak "ORACLE_ROLE()")

# Grant to UMA
cast send $INSURANCE_VAULT \
  "grantRole(bytes32,address)" \
  $ROLE \
  $UMA_ADDRESS \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# Grant to Kleros (if applicable)
cast send $INSURANCE_VAULT \
  "grantRole(bytes32,address)" \
  $ROLE \
  $KLEROS_ADDRESS \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

**Fund Paymaster**:

```bash
cast send $PAYMASTER \
  "deposit()" \
  --value 1ether \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

**Checklist**:
- [ ] Integration adapters deployed
- [ ] ZK_PROVER_ROLE granted (if applicable)
- [ ] ORACLE_ROLE granted (if applicable)
- [ ] Paymaster funded
- [ ] Setup verified

---

### Step 6: Health Check

```bash
forge script script/HealthCheck.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL
```

**Verify**:
- [ ] All contracts deployed
- [ ] Contract state correct
- [ ] Roles assigned
- [ ] External contracts accessible
- [ ] Balances correct

---

### Step 7: Testnet Testing

```bash
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

---

## ✅ Post-Deployment Checklist

### Verification
- [ ] All contracts deployed
- [ ] All contracts verified on BaseScan
- [ ] All addresses saved
- [ ] Deployment verified
- [ ] Health check passed

### Configuration
- [ ] Roles granted
- [ ] Paymaster funded
- [ ] Integration adapters deployed
- [ ] External services configured

### Testing
- [ ] Basic functionality tested
- [ ] End-to-end flows tested
- [ ] Edge cases tested
- [ ] Integration tests passed

### Documentation
- [ ] Deployment addresses documented
- [ ] Deployment date recorded
- [ ] Network confirmed
- [ ] Team notified

### Monitoring
- [ ] Monitoring set up
- [ ] Alerts configured
- [ ] Health check scheduled
- [ ] Activity tracking enabled

---

## 📊 Deployment Information

### Contract Addresses

Save these after deployment:

```
SimpleAccountImplementation: _________________
AgentLicense: _________________
AgentRegistry: _________________
ReputationScore: _________________
InsuranceVault: _________________
Paymaster: _________________
MerchantSDK: _________________
ZKAdapter: _________________ (if deployed)
OracleAdapter: _________________ (if deployed)
```

### Deployment Details

- **Network**: Base Sepolia Testnet
- **Chain ID**: 84532
- **Deployment Date**: _________________
- **Deployer Address**: _________________
- **Transaction Hash**: _________________
- **Gas Used**: _________________

### External Contracts

- **ERC6551 Registry**: `0x000000006551c19487814612e58FE06813775758`
- **USDC**: `0x036CbD53842c5426634e7929541eC2318f3dCF7e`
- **EntryPoint**: `0x0000000071727De22E5E9d8BAf0edAc6f37da032`

---

## 🚨 Troubleshooting

### Common Issues

#### Issue: Insufficient Balance
**Error**: "insufficient funds"
**Solution**: 
- Get more ETH from faucet: https://www.coinbase.com/faucets/base-ethereum-goerli-faucet
- Check balance: `cast balance $DEPLOYER_ADDRESS --rpc-url $BASE_SEPOLIA_RPC_URL`

#### Issue: Contract Verification Fails
**Error**: "Contract verification failed"
**Solution**:
- Check constructor arguments
- Verify compiler version matches
- Try manual verification on BaseScan

#### Issue: Role Granting Fails
**Error**: "AccessControl: account is missing role"
**Solution**:
- Verify deployer has admin role
- Check role hash: `cast keccak "ROLE_NAME()"`
- Grant role manually via cast

#### Issue: External Contracts Not Found
**Error**: "Contract not found"
**Solution**:
- Verify network (Base Sepolia)
- Check contract addresses
- Verify contracts exist on network

#### Issue: Tests Fail
**Error**: Test failures
**Solution**:
- Check USDC balance in TBA
- Verify roles granted
- Check gas limits
- Review test logs

---

## 📞 Support

### Resources
- **Documentation**: `docs/TESTNET_DEPLOYMENT.md`
- **Security Guide**: `docs/SECURITY.md`
- **Integration Guide**: `docs/INTEGRATIONS.md`

### Getting Help
- Check logs and error messages
- Review contract verification
- Check network connectivity
- Verify environment variables

### Emergency Contacts
- **Security**: security@kya.protocol
- **Technical**: team@kya.protocol

---

## 🎯 Next Steps After Deployment

1. **Monitor Activity**
   - Watch for agent minting
   - Monitor staking activity
   - Track gas usage

2. **Test Integrations**
   - Test with Axiom/Brevis (if configured)
   - Test with UMA/Kleros (if configured)
   - Test EntryPoint integration

3. **Gather Feedback**
   - Collect user feedback
   - Monitor for issues
   - Document findings

4. **Prepare for Mainnet**
   - Address any issues found
   - Optimize based on testnet usage
   - Finalize mainnet deployment plan

---

## 📝 Deployment Log

Use this section to track your deployment:

### Pre-Deployment
- [ ] Prerequisites met
- [ ] Environment configured
- [ ] Pre-deployment checks passed
- [ ] Ready to deploy

### Deployment
- [ ] Contracts deployed
- [ ] Addresses saved
- [ ] Contracts verified
- [ ] Deployment verified

### Post-Deployment
- [ ] Setup complete
- [ ] Roles granted
- [ ] Paymaster funded
- [ ] Health check passed
- [ ] Tests passed

### Notes
```
Date: _________________
Deployer: _________________
Issues Encountered: _________________
_________________
_________________
Resolution: _________________
_________________
_________________
```

---

**Last Updated**: 2026-01-06  
**Status**: Ready for Deployment

