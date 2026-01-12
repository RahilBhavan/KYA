# Testnet Deployment Guide

**Network**: Base Sepolia Testnet  
**Status**: Ready for Deployment

---

## Overview

This guide covers the complete process of deploying KYA Protocol v2.0 to Base Sepolia testnet, including pre-deployment checks, deployment, post-deployment setup, and testing.

---

## Prerequisites

### Required Tools

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Private key with sufficient ETH (recommended: > 0.5 ETH)
- BaseScan API key (for contract verification)

### Required Accounts

- **Deployer Account**: Address with ETH for deployment
- **Test Account**: Address for testing (optional)
- **Axiom/Brevis**: ZK coprocessor addresses (optional, for integration)
- **UMA/Kleros**: Oracle addresses (optional, for integration)

### Environment Setup

Create `.env` file:

```bash
# Deployment
PRIVATE_KEY=your_private_key_here
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
BASESCAN_API_KEY=your_basescan_api_key

# Contract Addresses (set after deployment)
AGENT_LICENSE=
AGENT_REGISTRY=
INSURANCE_VAULT=
REPUTATION_SCORE=
PAYMASTER=
MERCHANT_SDK=

# External Services (optional)
AXIOM_ADDRESS=
BREVIS_ADDRESS=
UMA_ADDRESS=
KLEROS_ADDRESS=

# Configuration
USDC_ADDRESS=0x036CbD53842c5426634e7929541eC2318f3dCF7e
ENTRY_POINT_ADDRESS=0x0000000071727De22E5E9d8BAf0edAc6f37da032
PAYMASTER_FUNDING=1000000000000000000  # 1 ETH in wei
```

---

## Deployment Process

### Option 1: Automated Deployment (Recommended)

```bash
# Run complete deployment script
./script/deploy-testnet.sh
```

This script will:
1. Run pre-deployment checks
2. Build contracts
3. Deploy contracts
4. Verify deployment
5. Run post-deployment setup
6. Run health check
7. Run testnet tests

### Option 2: Manual Deployment

#### Step 1: Pre-Deployment Check

```bash
forge script script/PreDeploymentCheck.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL
```

**Verify**:
- ✓ Environment variables set
- ✓ Network accessible
- ✓ Sufficient balance (> 0.1 ETH)
- ✓ External contracts accessible
- ✓ Contracts compile
- ✓ Tests pass

#### Step 2: Build Contracts

```bash
forge build
```

#### Step 3: Deploy Contracts

```bash
forge script script/DeployBaseSepolia.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY \
  -vvv
```

**Expected Output**:
- Contract addresses for all deployed contracts
- Deployment info saved to `deployments/base-sepolia-<timestamp>.md`

#### Step 4: Set Environment Variables

After deployment, update `.env` with contract addresses:

```bash
export AGENT_LICENSE=<address>
export AGENT_REGISTRY=<address>
export INSURANCE_VAULT=<address>
export REPUTATION_SCORE=<address>
export PAYMASTER=<address>
export MERCHANT_SDK=<address>
```

#### Step 5: Verify Deployment

```bash
forge script script/VerifyDeployment.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL
```

**Verify**:
- ✓ All contracts deployed
- ✓ Roles assigned correctly
- ✓ Contract interactions work
- ✓ Configuration correct
- ✓ External contracts accessible

#### Step 6: Post-Deployment Setup

```bash
forge script script/PostDeploymentSetup.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast \
  -vvv
```

**This will**:
- Deploy integration adapters (ZKAdapter, OracleAdapter)
- Grant ZK_PROVER_ROLE to Axiom/Brevis (if addresses set)
- Grant ORACLE_ROLE to UMA/Kleros (if addresses set)
- Fund Paymaster (if PAYMASTER_FUNDING set)

#### Step 7: Health Check

```bash
forge script script/HealthCheck.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL
```

**Check**:
- Contract deployment status
- Contract state
- Role assignments
- External contracts
- Contract balances
- Recent activity

#### Step 8: Testnet Testing

```bash
forge script script/TestnetTesting.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast \
  -vvv
```

**Tests**:
- Agent minting
- TBA funding
- Staking
- Proof verification
- Merchant verification
- Paymaster eligibility

---

## Post-Deployment Tasks

### 1. Verify Contracts on BaseScan

For each contract:

```bash
forge verify-contract <CONTRACT_ADDRESS> \
  <CONTRACT_NAME> \
  --chain-id 84532 \
  --etherscan-api-key $BASESCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(...)" <args>)
```

### 2. Grant Roles Manually (if not done in setup)

#### Grant ZK_PROVER_ROLE

```bash
cast send $REPUTATION_SCORE \
  "grantRole(bytes32,address)" \
  $(cast keccak "ZK_PROVER_ROLE()") \
  $AXIOM_ADDRESS \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

#### Grant ORACLE_ROLE

```bash
cast send $INSURANCE_VAULT \
  "grantRole(bytes32,address)" \
  $(cast keccak "ORACLE_ROLE()") \
  $UMA_ADDRESS \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

### 3. Fund Paymaster

```bash
cast send $PAYMASTER \
  "deposit()" \
  --value 1ether \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

### 4. Test End-to-End Flows

See `script/TestnetTesting.s.sol` for test examples.

---

## Monitoring

### Health Checks

Run regularly:

```bash
forge script script/HealthCheck.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL
```

### Monitor Events

Use BaseScan or block explorer to monitor:
- Agent minting events
- Staking events
- Claim submissions
- Proof verifications
- Gas sponsorship

### Key Metrics

- Total agents minted
- Total USDC staked
- Active verified agents
- Claims submitted/resolved
- Gas sponsored

---

## Troubleshooting

### Deployment Fails

**Issue**: Insufficient gas
**Solution**: Increase gas limit or gas price

```bash
forge script ... --gas-limit 10000000 --gas-price 1000000000
```

**Issue**: Contract verification fails
**Solution**: Verify manually on BaseScan or check constructor arguments

### Verification Fails

**Issue**: Roles not granted
**Solution**: Grant roles manually (see Post-Deployment Tasks)

**Issue**: External contracts not found
**Solution**: Verify network and contract addresses

### Testing Fails

**Issue**: Insufficient USDC
**Solution**: Get test USDC from faucet or mint test tokens

**Issue**: ZK_PROVER_ROLE not granted
**Solution**: Grant role to test address or use admin account

---

## Emergency Procedures

### Pause Protocol

```bash
cast send $INSURANCE_VAULT \
  "pause()" \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

Or use rollback script:

```bash
forge script script/Rollback.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast
```

### Revoke Roles

```bash
cast send $CONTRACT \
  "revokeRole(bytes32,address)" \
  $ROLE \
  $ADDRESS \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

### Unpause (After Fix)

```bash
cast send $INSURANCE_VAULT \
  "unpause()" \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

---

## Deployment Checklist

### Pre-Deployment

- [ ] Environment variables configured
- [ ] Pre-deployment checks passed
- [ ] Contracts compiled
- [ ] Tests passing
- [ ] Security analysis complete
- [ ] Sufficient ETH balance

### Deployment

- [ ] Contracts deployed
- [ ] Contract addresses saved
- [ ] Contracts verified on BaseScan
- [ ] Deployment verified

### Post-Deployment

- [ ] Integration adapters deployed
- [ ] Roles granted
- [ ] Paymaster funded
- [ ] Health check passed
- [ ] Testnet tests passed

### Monitoring

- [ ] Monitoring set up
- [ ] Alerts configured
- [ ] Documentation updated
- [ ] Team notified

---

## Expected Gas Costs

### Deployment (Estimated)

- SimpleAccountImplementation: ~1.5M gas
- AgentLicense: ~3M gas
- AgentRegistry: ~2M gas
- ReputationScore: ~2.5M gas
- InsuranceVault: ~3.5M gas
- Paymaster: ~2M gas
- MerchantSDK: ~1.5M gas
- ZKAdapter: ~1M gas
- OracleAdapter: ~1M gas

**Total**: ~18M gas (~0.18 ETH at 10 gwei)

### Operations (Estimated)

- Mint agent: ~200k gas
- Stake: ~150k gas
- Unstake: ~120k gas
- Submit claim: ~100k gas
- Resolve claim: ~80k gas
- Verify proof: ~100k gas

---

## Next Steps After Deployment

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

## Support

For deployment issues:
- Check logs and error messages
- Review contract verification
- Check network connectivity
- Verify environment variables

**Contact**: team@kya.protocol

---

**Last Updated**: 2026-01-06

