# KYA Protocol - API Reference

**Purpose**: Complete API reference for KYA Protocol smart contracts.

---

## AgentRegistry

### Functions

#### `mintAgent(string name, string description, string category) returns (bytes32)`

Creates a new agent identity.

**Parameters**:
- `name` (string): Agent name
- `description` (string): Agent description  
- `category` (string): Agent category (e.g., "Trading", "Lending")

**Returns**: `bytes32` - Agent ID

**Events**:
- `AgentMinted(bytes32 indexed agentId, uint256 indexed tokenId, address indexed owner, string name)`

**Requirements**:
- Must pay minting fee
- Name must not be empty

**Gas**: ~200k

---

#### `computeTBAAddress(uint256 tokenId) returns (address)`

Computes the Token Bound Account address for an agent.

**Parameters**:
- `tokenId` (uint256): Agent token ID

**Returns**: `address` - TBA address

**Gas**: ~5k (view function)

---

#### `totalAgents() returns (uint256)`

Gets the total number of agents minted.

**Returns**: `uint256` - Total agent count

**Gas**: ~2k (view function)

---

## InsuranceVault

### Functions

#### `stake(uint256 tokenId, uint256 amount)`

Stakes USDC to become verified.

**Parameters**:
- `tokenId` (uint256): Agent token ID
- `amount` (uint256): USDC amount (minimum: 1000 USDC)

**Requirements**:
- Agent must exist
- Amount >= minimum stake
- Sufficient USDC balance and allowance
- Called from agent's TBA

**Events**:
- `Staked(uint256 indexed tokenId, uint256 amount)`
- `AgentVerified(uint256 indexed tokenId)`

**Gas**: ~150k

---

#### `unstake(uint256 tokenId, uint256 amount)`

Unstakes USDC.

**Parameters**:
- `tokenId` (uint256): Agent token ID
- `amount` (uint256): Amount to unstake

**Requirements**:
- Agent must exist
- Amount <= staked amount
- If verified: 7-day cooldown must have passed
- Called from agent's TBA

**Events**:
- `Unstaked(uint256 indexed tokenId, uint256 amount)`
- `UnstakeRequested(uint256 indexed tokenId, uint256 timestamp)` (if cooldown active)

**Gas**: ~120k

---

#### `submitClaim(uint256 tokenId, uint256 amount, string reason) returns (bytes32)`

Submits a claim against an agent.

**Parameters**:
- `tokenId` (uint256): Agent token ID
- `amount` (uint256): Claim amount
- `reason` (string): Claim reason/description

**Returns**: `bytes32` - Claim ID

**Requirements**:
- Agent must exist
- Agent must be verified
- Amount > 0
- Called by merchant

**Events**:
- `ClaimSubmitted(bytes32 indexed claimId, uint256 indexed tokenId, uint256 amount, address indexed merchant)`

**Gas**: ~100k

---

#### `resolveClaim(bytes32 claimId, bool approved)`

Resolves a claim via oracle.

**Parameters**:
- `claimId` (bytes32): Claim ID
- `approved` (bool): Whether claim is approved

**Requirements**:
- Claim must exist
- Challenge period must have passed (or waived)
- Called by oracle (ORACLE_ROLE)

**Events**:
- `ClaimResolved(bytes32 indexed claimId, bool approved, uint256 slashedAmount)`
- `Slashed(uint256 indexed tokenId, uint256 amount, address recipient)`

**Gas**: ~80k

---

#### `getStakeInfo(uint256 tokenId) returns (StakeInfo)`

Gets stake information for an agent.

**Parameters**:
- `tokenId` (uint256): Agent token ID

**Returns**: `StakeInfo` struct:
- `amount` (uint256): Staked amount
- `stakedAt` (uint256): Timestamp when first staked
- `tbaAddress` (address): Cached TBA address
- `isVerified` (bool): Whether agent is verified

**Gas**: ~5k (view function)

---

## ReputationScore

### Functions

#### `verifyProof(uint256 tokenId, string proofType, bytes proof, string metadata) returns (ProofResult)`

Verifies a ZK proof and updates reputation.

**Parameters**:
- `tokenId` (uint256): Agent token ID
- `proofType` (string): Proof type (e.g., "UniswapVolume")
- `proof` (bytes): ZK proof data
- `metadata` (string): Proof metadata

**Returns**: `ProofResult` struct:
- `proofType` (string): Proof type
- `verified` (bool): Whether proof is verified
- `scoreIncrease` (uint256): Score increase amount
- `metadata` (string): Metadata

**Requirements**:
- Agent must exist
- Proof type must be supported
- Proof must not be already verified (replay prevention)
- Called by ZK prover (ZK_PROVER_ROLE)

**Events**:
- `ProofVerified(uint256 indexed tokenId, string proofType, uint256 scoreIncrease)`
- `ReputationUpdated(uint256 indexed tokenId, uint256 oldScore, uint256 newScore, uint8 newTier)`
- `BadgeAwarded(uint256 indexed tokenId, string badgeName)` (if badge earned)

**Gas**: ~100k

---

#### `getReputation(uint256 tokenId) returns (ReputationData)`

Gets reputation data for an agent.

**Parameters**:
- `tokenId` (uint256): Agent token ID

**Returns**: `ReputationData` struct:
- `tokenId` (uint256): Agent token ID
- `score` (uint224): Reputation score
- `tier` (uint8): Reputation tier (0-5)
- `verifiedProofs` (uint32): Number of verified proofs
- `lastUpdated` (uint32): Last update timestamp

**Gas**: ~5k (view function)

---

#### `getTier(uint224 score) returns (uint8)`

Gets the tier for a given score.

**Parameters**:
- `score` (uint224): Reputation score

**Returns**: `uint8` - Tier (0=None, 1=Bronze, 2=Silver, 3=Gold, 4=Platinum, 5=Whale)

**Gas**: ~2k (pure function)

---

#### `getBadges(uint256 tokenId) returns (string[])`

Gets all badges for an agent.

**Parameters**:
- `tokenId` (uint256): Agent token ID

**Returns**: `string[]` - Array of badge names

**Gas**: ~10k (view function, depends on badge count)

---

#### `hasBadge(uint256 tokenId, string badgeName) returns (bool)`

Checks if an agent has a specific badge.

**Parameters**:
- `tokenId` (uint256): Agent token ID
- `badgeName` (string): Badge name

**Returns**: `bool` - Whether agent has the badge

**Gas**: ~5k (view function)

---

## Paymaster

### Functions

#### `validatePaymasterUserOp(uint8 mode, bytes calldata userOp, bytes calldata paymasterAndData) returns (bytes memory, uint256)`

Validates a user operation for gas sponsorship.

**Parameters**:
- `mode` (uint8): Validation mode
- `userOp` (bytes): User operation data
- `paymasterAndData` (bytes): Paymaster data

**Returns**: 
- `bytes` - Context data
- `uint256` - Validation data

**Requirements**:
- Agent must be eligible (created < 7 days, Twitter verified, < 50 tx)
- Paymaster must have sufficient deposit
- Called by EntryPoint

**Gas**: ~50k

---

#### `postOp(uint8 mode, bytes calldata context, uint256 actualGasCost)`

Post-operation hook for gas payment.

**Parameters**:
- `mode` (uint8): Operation mode
- `context` (bytes): Context from validation
- `actualGasCost` (uint256): Actual gas cost

**Requirements**:
- Called by EntryPoint
- Sufficient deposit

**Events**:
- `GasSponsored(uint256 indexed tokenId, uint256 cost, bytes32 context)`

**Gas**: ~30k

---

#### `isEligible(uint256 tokenId) returns (bool, uint256)`

Checks if an agent is eligible for gas sponsorship.

**Parameters**:
- `tokenId` (uint256): Agent token ID

**Returns**:
- `bool` - Whether eligible
- `uint256` - Remaining transactions

**Gas**: ~5k (view function)

---

## MerchantSDK

### Functions

#### `verifyAgent(uint256 tokenId, address tbaAddress) returns (VerificationResult)`

Verifies an agent's status.

**Parameters**:
- `tokenId` (uint256): Agent token ID
- `tbaAddress` (address): Agent TBA address

**Returns**: `VerificationResult` struct:
- `isVerified` (bool): Whether agent is verified
- `stakeAmount` (uint256): Staked amount
- `reputationScore` (uint256): Reputation score
- `tier` (uint8): Reputation tier
- `isActive` (bool): Whether agent is active

**Gas**: ~10k (view function)

---

#### `reportViolation(uint256 tokenId, string violation, bytes evidence)`

Reports a violation (for future use).

**Parameters**:
- `tokenId` (uint256): Agent token ID
- `violation` (string): Violation type
- `evidence` (bytes): Evidence data

**Gas**: ~50k

---

## Events

### AgentRegistry Events

```solidity
event AgentMinted(
    bytes32 indexed agentId,
    uint256 indexed tokenId,
    address indexed owner,
    string name
);
```

### InsuranceVault Events

```solidity
event Staked(uint256 indexed tokenId, uint256 amount);
event Unstaked(uint256 indexed tokenId, uint256 amount);
event UnstakeRequested(uint256 indexed tokenId, uint256 timestamp);
event ClaimSubmitted(
    bytes32 indexed claimId,
    uint256 indexed tokenId,
    uint256 amount,
    address indexed merchant
);
event ClaimResolved(
    bytes32 indexed claimId,
    bool approved,
    uint256 slashedAmount
);
event Slashed(
    uint256 indexed tokenId,
    uint256 amount,
    address indexed recipient
);
event FeesWithdrawn(address indexed recipient, uint256 amount);
```

### ReputationScore Events

```solidity
event ProofVerified(
    uint256 indexed tokenId,
    string proofType,
    uint256 scoreIncrease
);
event ReputationUpdated(
    uint256 indexed tokenId,
    uint256 oldScore,
    uint256 newScore,
    uint8 newTier
);
event BadgeAwarded(uint256 indexed tokenId, string badgeName);
```

### Paymaster Events

```solidity
event GasSponsored(
    uint256 indexed tokenId,
    uint256 cost,
    bytes32 context
);
event DepositUpdated(uint256 newDeposit);
```

---

## Error Codes

### Common Errors

- `InsufficientStake`: Stake amount below minimum
- `CooldownActive`: Unstake cooldown not expired
- `ProofAlreadyVerified`: Proof already verified
- `NotAuthorized`: Missing required role
- `InvalidProofType`: Proof type not supported
- `ClaimNotFound`: Claim does not exist
- `InvalidEntryPoint`: Not called by EntryPoint
- `InsufficientDeposit`: Paymaster deposit too low

---

## Gas Estimates

| Operation | Gas Cost |
|-----------|----------|
| `mintAgent()` | ~200k |
| `stake()` | ~150k |
| `unstake()` | ~120k |
| `submitClaim()` | ~100k |
| `resolveClaim()` | ~80k |
| `verifyProof()` | ~100k |
| `validatePaymasterUserOp()` | ~50k |
| `postOp()` | ~30k |

---

## Network Information

### Base Sepolia (Testnet)

- **Chain ID**: 84532
- **RPC URL**: https://sepolia.base.org
- **Explorer**: https://sepolia.basescan.org
- **USDC**: `0x036CbD53842c5426634e7929541eC2318f3dCF7e`
- **EntryPoint**: `0x0000000071727De22E5E9d8BAf0edAc6f37da032`

### Base (Mainnet)

- **Chain ID**: 8453
- **RPC URL**: https://mainnet.base.org
- **Explorer**: https://basescan.org
- **USDC**: `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`
- **EntryPoint**: `0x0000000071727De22E5E9d8BAf0edAc6f37da032`

---

**Last Updated**: 2026-01-06

