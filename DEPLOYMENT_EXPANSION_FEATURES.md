# KYA Protocol - Expansion Features Deployment Guide

**Date**: 2026-01-12  
**Status**: Ready for Deployment

---

## Pre-Deployment Checklist

- [x] All contracts implemented
- [x] Tests passing (167/168 - 99.4%)
- [x] Security review recommended
- [ ] Multi-sig wallet configured
- [ ] External service accounts set up (LayerZero, The Graph)
- [ ] Environment variables configured

---

## Deployment Steps

### 1. Testnet Deployment (Base Sepolia)

#### Prerequisites

```bash
# Set environment variables
export PRIVATE_KEY=your_testnet_private_key
export MULTISIG_ADDRESS=0x... # Testnet multi-sig
export RPC_URL=https://sepolia.base.org
export AGENT_LICENSE_ADDRESS=0x... # Existing core contracts
export AGENT_REGISTRY_ADDRESS=0x...
export REPUTATION_SCORE_ADDRESS=0x...
export INSURANCE_VAULT_ADDRESS=0x...
export USDC_ADDRESS=0x... # Testnet USDC
export LAYERZERO_ENDPOINT=0x... # LayerZero testnet endpoint
```

#### Deploy

```bash
# Deploy all expansion features
forge script script/DeployTestnet.s.sol \
  --rpc-url $RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY
```

#### Verify Contracts

After deployment, verify on BaseScan:
- ReputationScoreV2
- KYAToken
- KYAGovernance
- TimelockController
- AgentMarketplace
- InsurancePool
- RiskCalculator
- CrossChainReputation
- LayerZeroAdapter

### 2. Mainnet Deployment (Base)

#### Prerequisites

```bash
# Set environment variables
export PRIVATE_KEY=your_mainnet_private_key
export MULTISIG_ADDRESS=0x... # Mainnet multi-sig
export RPC_URL=https://mainnet.base.org
export CONFIRM_MAINNET_DEPLOYMENT=YES_I_CONFIRM_MAINNET_DEPLOYMENT
# ... other addresses
```

#### Deploy

```bash
# Deploy all expansion features
forge script script/DeployMainnet.s.sol \
  --rpc-url $RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY
```

---

## Post-Deployment Setup

### 1. Subgraph Deployment

```bash
cd subgraph

# Update subgraph.yaml with deployed contract addresses
# Replace {{AGENT_REGISTRY_ADDRESS}}, etc.

# Deploy to The Graph
bun run codegen
bun run build
bun run deploy
```

### 2. Dashboard Deployment

```bash
cd dashboard

# Set environment variables
export NEXT_PUBLIC_GRAPH_URL=https://api.thegraph.com/subgraphs/name/kya-protocol/kya

# Deploy to Vercel
vercel deploy --prod
```

### 3. Mobile SDKs

Publish to package managers:
- React Native: `npm publish`
- iOS: Update CocoaPods spec
- Android: Publish to Maven

### 4. Role Management

Transfer all admin roles to multi-sig:
- KYAToken: DEFAULT_ADMIN_ROLE
- KYAGovernance: DEFAULT_ADMIN_ROLE
- AgentMarketplace: DEFAULT_ADMIN_ROLE
- InsurancePool: DEFAULT_ADMIN_ROLE
- CrossChainReputation: DEFAULT_ADMIN_ROLE
- TimelockController: DEFAULT_ADMIN_ROLE

### 5. Monitoring Setup

Configure monitoring for:
- Contract events
- Transaction failures
- Gas usage
- Protocol metrics

---

## Contract Addresses

After deployment, update these in documentation:
- ReputationScoreV2: `0x...`
- KYAToken: `0x...`
- KYAGovernance: `0x...`
- AgentMarketplace: `0x...`
- InsurancePool: `0x...`
- CrossChainReputation: `0x...`

---

## Verification

### Testnet Verification

```bash
# Run integration tests
forge test --match-contract IntegrationTest

# Test governance
forge script script/TestGovernance.s.sol --rpc-url $RPC_URL

# Test marketplace
forge script script/TestMarketplace.s.sol --rpc-url $RPC_URL
```

### Mainnet Verification

1. Verify all contracts on BaseScan
2. Test with small amounts first
3. Monitor for 24-48 hours
4. Gradually increase usage

---

## Rollback Plan

If issues are discovered:

1. Pause affected contracts (if pause functionality exists)
2. Transfer admin roles to emergency multi-sig
3. Deploy fixed versions
4. Migrate data if needed

---

## Support

For deployment issues:
- Check contract verification on BaseScan
- Review transaction logs
- Check multi-sig approvals
- Verify environment variables

---

**Last Updated**: 2026-01-12
