# KYA Protocol - Developer Guide

**Purpose**: Guide for developers integrating KYA Protocol into their applications.

---

## Overview

KYA Protocol provides:
- **Smart Contracts**: On-chain protocol logic
- **JavaScript SDK**: Off-chain integration tools
- **APIs**: External service integrations

---

## Architecture

### Core Contracts

1. **AgentLicense** (ERC-721): Agent identity NFTs
2. **AgentRegistry**: Factory for agent creation
3. **SimpleAccountImplementation** (ERC-6551): Token Bound Accounts
4. **InsuranceVault**: Staking and slashing mechanism
5. **ReputationScore**: Reputation scoring system
6. **Paymaster**: ERC-4337 gas sponsorship
7. **MerchantSDK**: Merchant verification interface

### Integration Points

- **ZK Coprocessors**: Axiom/Brevis for proof generation
- **Oracles**: UMA/Kleros for dispute resolution
- **ERC-4337**: EntryPoint for account abstraction

---

## Installation

### Smart Contracts

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Clone repository
git clone [repository-url]
cd KYA

# Install dependencies
forge install
```

### JavaScript SDK

```bash
npm install @kya-protocol/integrations
# or
yarn add @kya-protocol/integrations
```

---

## Smart Contract Integration

### Agent Creation

```solidity
import {IAgentRegistry} from "@kya-protocol/interfaces/IAgentRegistry.sol";

IAgentRegistry registry = IAgentRegistry(registryAddress);

bytes32 agentId = registry.mintAgent(
    "MyAgent",
    "Agent description",
    "Trading"
);

uint256 tokenId = uint256(agentId);
address tbaAddress = registry.computeTBAAddress(tokenId);
```

### Staking

```solidity
import {IInsuranceVault} from "@kya-protocol/interfaces/IInsuranceVault.sol";
import {IAgentAccount} from "@kya-protocol/interfaces/IAgentAccount.sol";

// Approve USDC
IERC20(usdcAddress).approve(insuranceVaultAddress, stakeAmount);

// Stake via TBA
IAgentAccount(tbaAddress).execute(
    insuranceVaultAddress,
    0,
    abi.encodeWithSignature("stake(uint256,uint256)", tokenId, stakeAmount)
);
```

### Reputation Verification

```solidity
import {IReputationScore} from "@kya-protocol/interfaces/IReputationScore.sol";

// Verify proof (called by ZK prover)
IReputationScore.ProofResult memory result = reputationScore.verifyProof(
    tokenId,
    "UniswapVolume",
    proofData,
    "Metadata"
);
```

### Merchant Verification

```solidity
import {IMerchantSDK} from "@kya-protocol/interfaces/IMerchantSDK.sol";

IMerchantSDK.VerificationResult memory result = merchantSDK.verifyAgent(
    tokenId,
    tbaAddress
);

if (result.isVerified && result.tier >= 3) {
    // Accept agent (Gold tier or above)
}
```

---

## JavaScript SDK Integration

### Setup

```typescript
import { loadConfig, AxiomClient, UMAClient } from '@kya-protocol/integrations';
import { ethers } from 'ethers';

// Load configuration
const config = loadConfig();

// Initialize provider
const provider = new ethers.JsonRpcProvider(config.rpcUrl);
```

### Agent Operations

```typescript
import { ethers } from 'ethers';

// Connect to contracts
const agentRegistry = new ethers.Contract(
  registryAddress,
  ['function mintAgent(string,string,string) returns (bytes32)'],
  signer
);

// Mint agent
const agentId = await agentRegistry.mintAgent(
  'MyAgent',
  'Description',
  'Trading'
);

// Get TBA address
const tbaAddress = await agentRegistry.computeTBAAddress(
  ethers.toBigInt(agentId)
);
```

### ZK Proof Generation

```typescript
import { AxiomClient } from '@kya-protocol/integrations';

const axiom = new AxiomClient(config.axiom!);

// Generate proof
const proof = await axiom.generateProof({
  agentAddress: tbaAddress,
  proofType: 'UniswapVolume',
  queryData: {
    contract: 'UniswapV3Router',
    minVolume: 10000,
  },
  startBlock: 10000000,
  endBlock: 11000000,
});

// Submit to ReputationScore (via ZK prover)
// This requires ZK_PROVER_ROLE
```

### Claim Submission

```typescript
import { UMAClient } from '@kya-protocol/integrations';

const uma = new UMAClient(config.uma!);

// Submit claim on-chain
const insuranceVault = new ethers.Contract(
  insuranceVaultAddress,
  ['function submitClaim(uint256,uint256,string) returns (bytes32)'],
  signer
);

const claimId = await insuranceVault.submitClaim(
  tokenId,
  claimAmount,
  'Malicious behavior'
);

// Submit to UMA
const requestId = await uma.submitClaim({
  claimId,
  tokenId,
  merchant: merchantAddress,
  amount: claimAmount.toString(),
  reason: 'Malicious behavior',
  evidence: evidenceData,
});

// Poll for resolution
const resolution = await uma.pollForResolution(requestId);
```

---

## API Reference

### AgentRegistry

#### `mintAgent(string name, string description, string category) returns (bytes32)`

Creates a new agent.

**Parameters**:
- `name`: Agent name
- `description`: Agent description
- `category`: Agent category

**Returns**: Agent ID (bytes32)

#### `computeTBAAddress(uint256 tokenId) returns (address)`

Computes the TBA address for an agent.

**Parameters**:
- `tokenId`: Agent token ID

**Returns**: TBA address

### InsuranceVault

#### `stake(uint256 tokenId, uint256 amount)`

Stakes USDC to become verified.

**Parameters**:
- `tokenId`: Agent token ID
- `amount`: USDC amount (minimum: 1000 USDC)

#### `unstake(uint256 tokenId, uint256 amount)`

Unstakes USDC.

**Parameters**:
- `tokenId`: Agent token ID
- `amount`: Amount to unstake

**Note**: 7-day cooldown for verified agents.

#### `submitClaim(uint256 tokenId, uint256 amount, string reason) returns (bytes32)`

Submits a claim against an agent.

**Parameters**:
- `tokenId`: Agent token ID
- `amount`: Claim amount
- `reason`: Claim reason

**Returns**: Claim ID

### ReputationScore

#### `verifyProof(uint256 tokenId, string proofType, bytes proof, string metadata) returns (ProofResult)`

Verifies a ZK proof and updates reputation.

**Parameters**:
- `tokenId`: Agent token ID
- `proofType`: Proof type (e.g., "UniswapVolume")
- `proof`: ZK proof data
- `metadata`: Proof metadata

**Returns**: Proof result with score increase

#### `getReputation(uint256 tokenId) returns (ReputationData)`

Gets reputation data for an agent.

**Parameters**:
- `tokenId`: Agent token ID

**Returns**: Reputation data (score, tier, badges, etc.)

### MerchantSDK

#### `verifyAgent(uint256 tokenId, address tbaAddress) returns (VerificationResult)`

Verifies an agent's status.

**Parameters**:
- `tokenId`: Agent token ID
- `tbaAddress`: Agent TBA address

**Returns**: Verification result (verified, stake, reputation, tier)

---

## Integration Examples

### Example 1: Merchant Integration

```typescript
import { MerchantSDK } from '@kya-protocol/sdk'; // Future SDK

// Verify agent before accepting transaction
const result = await merchantSDK.verifyAgent(tokenId, tbaAddress);

if (result.isVerified && result.stakeAmount >= minimumStake) {
  // Accept agent
  await executeTransaction(tbaAddress);
} else {
  // Reject agent
  throw new Error('Agent not verified');
}
```

### Example 2: Agent Dashboard

```typescript
// Get agent information
const agentInfo = await getAgentInfo(tokenId);

console.log('Agent:', agentInfo.name);
console.log('Verified:', agentInfo.verified);
console.log('Stake:', agentInfo.stakeAmount);
console.log('Reputation:', agentInfo.reputationScore);
console.log('Tier:', agentInfo.tier);
console.log('Badges:', agentInfo.badges);
```

### Example 3: Reputation Tracking

```typescript
// Monitor reputation changes
reputationScore.on('ReputationUpdated', (tokenId, oldScore, newScore, tier) => {
  console.log(`Agent ${tokenId} reputation updated:`);
  console.log(`  Old: ${oldScore}, New: ${newScore}`);
  console.log(`  Tier: ${tier}`);
});
```

---

## Error Handling

### Common Errors

#### `InsufficientStake`
**Cause**: Stake amount below minimum  
**Solution**: Stake at least 1000 USDC

#### `CooldownActive`
**Cause**: Unstake cooldown not expired  
**Solution**: Wait 7 days

#### `ProofAlreadyVerified`
**Cause**: Same proof verified twice  
**Solution**: Use different proof data

#### `NotAuthorized`
**Cause**: Missing required role  
**Solution**: Grant appropriate role

### Error Handling Pattern

```typescript
try {
  await insuranceVault.stake(tokenId, amount);
} catch (error: any) {
  if (error.code === 'InsufficientStake') {
    console.error('Stake amount too low');
  } else if (error.code === 'NotAuthorized') {
    console.error('Not authorized to stake');
  } else {
    console.error('Unexpected error:', error);
  }
}
```

---

## Testing

### Local Testing

```bash
# Start local node
anvil

# Deploy contracts
forge script script/DeployLocal.s.sol --rpc-url http://localhost:8545 --broadcast

# Run tests
forge test
```

### Testnet Testing

```bash
# Deploy to testnet
forge script script/DeployBaseSepolia.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast

# Test integration
forge script script/TestnetTesting.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast
```

---

## Best Practices

1. **Always Verify**: Check agent status before accepting
2. **Handle Errors**: Implement proper error handling
3. **Monitor Events**: Listen to contract events
4. **Test Thoroughly**: Test on testnet first
5. **Stay Updated**: Follow protocol updates

---

## Resources

- **API Reference**: See contract interfaces
- **Examples**: `integrations/javascript/examples/`
- **Documentation**: `docs/`
- **GitHub**: [Repository URL]

---

## Future Updates

### Planned Enhancements

#### Q1 2026
- [ ] Enhanced SDK with additional helper functions
- [ ] Improved error handling and retry logic
- [ ] Additional integration examples
- [ ] TypeScript type improvements

#### Q2 2026
- [ ] React hooks library for frontend integration
- [ ] WebSocket support for real-time updates
- [ ] Enhanced documentation with interactive examples
- [ ] Developer tools and utilities

#### Q3 2026
- [ ] Multi-chain SDK support
- [ ] Advanced query builders
- [ ] Performance optimizations
- [ ] Enhanced testing utilities

### Known Limitations

1. **External Services**: SDK requires external service accounts (Axiom, Brevis, UMA, Kleros) for full functionality
2. **Network Support**: Currently optimized for Base network
3. **Documentation**: Some advanced features may need additional examples

---

**Last Updated**: 2026-01-06

