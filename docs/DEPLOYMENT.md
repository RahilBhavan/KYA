# Deployment Documentation

## Overview

This guide covers deploying the KYA Protocol v2.0 contracts to Base Sepolia testnet and Base mainnet.

## Prerequisites

### Required Tools

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Private key with sufficient ETH for deployment
- BaseScan API key (for verification)

### Environment Variables

Create a `.env` file:

```bash
# Deployment
PRIVATE_KEY=your_private_key_here
FEE_RECEIVER=your_fee_receiver_address

# Base Sepolia
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
BASESCAN_API_KEY=your_basescan_api_key
USDC_ADDRESS=0x036CbD53842c5426634e7929541eC2318f3dCF7e
ENTRY_POINT_ADDRESS=0x0000000071727De22E5E9d8BAf0edAc6f37da032

# Base Mainnet
BASE_RPC_URL=https://mainnet.base.org
USDC_ADDRESS=0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
ENTRY_POINT_ADDRESS=0x0000000071727De22E5E9d8BAf0edAc6f37da032
```

## Manual Deployment

### Base Sepolia Testnet

#### Step 1: Install Dependencies

```bash
forge install OpenZeppelin/openzeppelin-contracts
forge install erc6551/reference
forge install foundry-rs/forge-std
```

#### Step 2: Build Contracts

```bash
forge build
```

#### Step 3: Run Tests

```bash
forge test
```

#### Step 4: Deploy Contracts

```bash
forge script script/DeployBaseSepolia.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY
```

#### Step 5: Verify Deployment

```bash
# Set contract addresses from deployment output
export AGENT_LICENSE=<address>
export AGENT_REGISTRY=<address>
export INSURANCE_VAULT=<address>
export REPUTATION_SCORE=<address>
export PAYMASTER=<address>
export MERCHANT_SDK=<address>

# Run verification script
forge script script/VerifyDeployment.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL
```

#### Step 6: Post-Deployment Setup

```bash
# Grant ZK_PROVER_ROLE to Axiom/Brevis
cast send $REPUTATION_SCORE \
  "grantRole(bytes32,address)" \
  $(cast sig "ZK_PROVER_ROLE()") \
  <axiom_address> \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# Grant ORACLE_ROLE to UMA/Kleros
cast send $INSURANCE_VAULT \
  "grantRole(bytes32,address)" \
  $(cast sig "ORACLE_ROLE()") \
  <uma_address> \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# Fund Paymaster
cast send $PAYMASTER \
  "deposit()" \
  --value 1ether \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

### Base Mainnet

**WARNING**: Only deploy to mainnet after thorough testing and security audit.

```bash
forge script script/DeployBase.s.sol \
  --rpc-url $BASE_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY
```

## Automated Deployment

### GitHub Actions

Deployment is automated via GitHub Actions on tag push:

1. Create a release tag: `git tag v1.0.0`
2. Push tag: `git push origin v1.0.0`
3. GitHub Actions will:
   - Run all tests
   - Deploy to Base Sepolia
   - Verify contracts
   - Run post-deployment tests

### CI/CD Configuration

See `.github/workflows/deploy-testnet.yml` for configuration.

Required secrets:
- `DEPLOYER_PRIVATE_KEY`: Deployment private key
- `BASE_SEPOLIA_RPC_URL`: Base Sepolia RPC endpoint
- `BASESCAN_API_KEY`: BaseScan API key for verification

## Deployment Verification

### Verify Contracts

```bash
# Verify all contracts
forge verify-contract <address> <contract_name> \
  --chain base-sepolia \
  --etherscan-api-key $BASESCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(...)" <args>)
```

### Run Verification Script

```bash
forge script script/VerifyDeployment.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL
```

This checks:
- Contract deployments
- Role assignments
- Contract interactions
- Configuration values
- External contract references

## Post-Deployment Checklist

- [ ] All contracts deployed successfully
- [ ] Contracts verified on BaseScan
- [ ] ZK_PROVER_ROLE granted to Axiom/Brevis
- [ ] ORACLE_ROLE granted to UMA/Kleros
- [ ] Paymaster funded
- [ ] Whitelisted contracts configured
- [ ] Deployment verification script passed
- [ ] Test minting an agent
- [ ] Test staking flow
- [ ] Test reputation proof
- [ ] Test merchant verification

## Contract Addresses

### Base Sepolia

After deployment, addresses are saved to `deployments/base-sepolia-<timestamp>.md`.

### Base Mainnet

After deployment, addresses are saved to `deployments/base-<timestamp>.md`.

## Troubleshooting

### Deployment Fails

- Check RPC URL is correct
- Verify private key has sufficient ETH
- Check contract compilation
- Review error messages

### Verification Fails

- Check BaseScan API key
- Verify constructor arguments
- Ensure contracts are deployed
- Check network matches

### Post-Deployment Issues

- Verify role grants
- Check contract interactions
- Review deployment logs
- Run verification script

## Security Considerations

1. **Private Key Security**: Never commit private keys
2. **Multi-sig**: Use multi-sig for mainnet deployments
3. **Timelock**: Consider timelock for admin functions
4. **Audit**: Complete security audit before mainnet
5. **Monitoring**: Set up monitoring for deployed contracts

## Rollback Plan

If issues are discovered post-deployment:

1. Pause contracts (if pausable)
2. Investigate issue
3. Deploy fixes if needed
4. Update documentation

## Support

For deployment issues:
- Check deployment logs
- Review contract verification
- Consult team documentation
- Contact development team

