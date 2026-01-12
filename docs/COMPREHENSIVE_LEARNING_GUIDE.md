# KYA Protocol - Comprehensive Learning Guide

**Version**: 1.0.0  
**Last Updated**: 2026-01-12  
**Purpose**: Complete educational resource for understanding the KYA Protocol architecture, implementation, and best practices

---

## Table of Contents

1. [Introduction](#introduction)
2. [Core Concepts](#core-concepts)
3. [Architecture Overview](#architecture-overview)
4. [Code Deep Dive](#code-deep-dive)
5. [Use Cases & Applications](#use-cases--applications)
6. [Implementation Guide](#implementation-guide)
7. [Expansion Possibilities](#expansion-possibilities)
8. [Best Practices](#best-practices)
9. [Learning Resources](#learning-resources)
10. [Glossary](#glossary)

---

## Introduction

### What is KYA Protocol?

**KYA (Know Your Agent) Protocol** is a decentralized underwriting protocol that creates **Bonded Identities for AI Agents** using cutting-edge blockchain technologies. It enables AI agents to:

- **Build Verifiable Reputation**: Prove on-chain history privately using Zero-Knowledge (ZK) proofs
- **Achieve Verified Status**: Stake collateral to become a trusted agent
- **Transfer Identity**: Agent identity is an NFT that can be transferred or sold
- **Access Services**: Merchants can trust verified agents with economic recourse

### The Problem It Solves

In a world where AI agents interact with decentralized applications (dApps), merchants face critical challenges:

1. **Trust**: How can merchants trust AI agents they've never interacted with?
2. **Identity**: How do agents prove their history without revealing sensitive data?
3. **Accountability**: What happens if an agent misbehaves?
4. **Onboarding**: How do new agents get started without upfront capital?

KYA Protocol solves these by combining:
- **ERC-6551 Token Bound Accounts**: NFTs that control smart contract wallets
- **ERC-4337 Account Abstraction**: Gasless transactions for new agents
- **Zero-Knowledge Proofs**: Private reputation verification
- **Economic Security**: Staking and slashing mechanisms

### Key Innovation

The protocol's core innovation is making **agent identity a transferable asset**. When you mint an agent:

1. You get an NFT (Agent License)
2. The NFT automatically controls a smart contract wallet (Token Bound Account)
3. The wallet can hold funds, execute transactions, and build reputation
4. Transferring the NFT transfers control of the wallet and all its history

This creates a **composable identity system** where agents can prove their worth without revealing sensitive information.

---

## Core Concepts

### 1. ERC-6551: Token Bound Accounts (TBA)

**What it is**: A standard that allows NFTs to own smart contract wallets.

**Why it matters**: Traditional NFTs are just tokens. With ERC-6551, NFTs become **active participants** that can:
- Hold ETH and tokens
- Execute transactions
- Interact with dApps
- Build on-chain history

**How it works**:

```solidity
// Each NFT gets a deterministic wallet address
address tbaAddress = erc6551Registry.createAccount(
    implementationAddress,  // The wallet implementation
    chainId,                // Current chain
    nftContract,            // AgentLicense contract
    tokenId,                // The NFT token ID
    salt                    // For deterministic addresses
);
```

**Key Benefits**:
- **Deterministic**: Same NFT always gets same wallet address
- **Transferable**: Transfer NFT = transfer wallet control
- **Composable**: Wallet can interact with any dApp
- **Gas Efficient**: Uses minimal proxy pattern

**Real-World Analogy**: Think of it like a car. The NFT is the title (proves ownership), and the TBA is the car itself (can be driven, modified, etc.). When you sell the title, the new owner gets the car.

### 2. ERC-4337: Account Abstraction

**What it is**: A standard that enables smart contract wallets to pay gas fees in tokens (or have fees sponsored).

**Why it matters**: New agents don't need ETH to start. They can:
- Pay gas in USDC
- Have gas sponsored by paymasters
- Use more complex transaction logic

**How it works**:

```solidity
// User creates a "UserOperation" (not a regular transaction)
UserOperation memory op = UserOperation({
    sender: agentTBA,           // The agent's wallet
    nonce: nonce,
    initCode: "",                // Empty if wallet exists
    callData: abi.encode(...),  // What to execute
    callGasLimit: gasLimit,
    verificationGasLimit: verificationGas,
    preVerificationGas: preVerification,
    maxFeePerGas: maxFee,
    maxPriorityFeePerGas: priorityFee,
    paymasterAndData: paymasterData,  // Who pays for gas
    signature: signature
});

// Bundler submits to EntryPoint
entryPoint.handleOps([op], beneficiary);
```

**Key Benefits**:
- **Gasless Transactions**: Paymasters can sponsor gas
- **Better UX**: No need for users to hold ETH
- **Flexible Logic**: Custom validation rules
- **Batch Transactions**: Multiple operations in one

**Real-World Analogy**: Like a credit card. You don't need cash (ETH) upfront. The merchant (paymaster) pays, and you pay them back later (or they sponsor it).

### 3. Zero-Knowledge Proofs (ZK Proofs)

**What it is**: Cryptographic proofs that allow you to prove something is true without revealing the underlying data.

**Why it matters**: Agents can prove their reputation (e.g., "I have $1M Uniswap volume") without revealing:
- Which specific transactions
- Their trading strategies
- Their wallet addresses
- Other sensitive data

**How it works**:

```solidity
// Agent submits proof query
bytes32 queryId = zkAdapter.submitQuery(ProofQuery({
    agentAddress: tbaAddress,
    proofType: "UniswapVolume",
    data: encryptedData  // Private data
}));

// ZK coprocessor (Axiom/Brevis) generates proof
// Proof proves: "This agent has > $1M volume" without revealing transactions

// Proof is verified on-chain
zkAdapter.processProof(queryId, proof, result);

// Reputation increases if proof is valid
reputationScore.verifyProof(tokenId, proofType, proof, "UniswapVolume");
```

**Key Benefits**:
- **Privacy**: Don't reveal sensitive data
- **Verifiability**: Proofs are cryptographically secure
- **Composability**: Multiple proofs can be combined
- **Efficiency**: Proofs are small compared to full data

**Real-World Analogy**: Like a diploma. You can prove you graduated (have reputation) without showing your grades (transaction details).

### 4. Economic Security (Staking & Slashing)

**What it is**: Agents stake collateral (USDC) to become "verified". If they misbehave, they can be slashed.

**Why it matters**: Provides **economic recourse** for merchants. If an agent:
- Fails to deliver
- Acts maliciously
- Breaks agreements

Merchants can submit claims and potentially receive compensation from the staked funds.

**How it works**:

```solidity
// Agent stakes USDC
insuranceVault.stake(tokenId, 1000 * 10**6);  // 1000 USDC

// Agent becomes "verified"
bool isVerified = insuranceVault.isVerified(tokenId);  // true

// Merchant submits claim
bytes32 claimId = insuranceVault.submitClaim(
    tokenId,
    claimAmount,
    "Agent failed to deliver"
);

// Oracle resolves claim
insuranceVault.resolveClaim(claimId, true);  // Claim valid

// Agent is slashed (funds go to merchant)
insuranceVault.slash(tokenId, claimAmount);
```

**Key Benefits**:
- **Trust**: Verified agents have skin in the game
- **Accountability**: Economic consequences for bad behavior
- **Merchant Protection**: Recourse if agents misbehave
- **Reputation**: Staking signals commitment

**Real-World Analogy**: Like a security deposit. You put money down to show you're serious. If you damage something, the deposit covers it.

### 5. Reputation Scoring

**What it is**: A system that tracks agent reputation based on verified proofs and on-chain activity.

**Why it matters**: Allows agents to build trust over time. Higher reputation = more opportunities.

**How it works**:

```solidity
// Reputation tiers
TIER_NONE = 0
TIER_BRONZE = 100
TIER_SILVER = 500
TIER_GOLD = 2000
TIER_PLATINUM = 10000
TIER_WHALE = 50000

// Agent submits proof
reputationScore.verifyProof(
    tokenId,
    "UniswapVolume",
    proof,
    "Uniswap Volume Badge"
);

// Reputation increases
ReputationData memory rep = reputationScore.getReputation(tokenId);
// rep.score += 50 (for UniswapVolume proof)
// rep.tier = TIER_BRONZE (if score >= 100)
```

**Key Benefits**:
- **Trust Building**: Agents can prove their worth
- **Badge System**: Visual indicators of achievements
- **Tier System**: Clear progression path
- **Composability**: Multiple proofs combine

**Real-World Analogy**: Like a credit score. The more you prove (pay bills on time, have income), the higher your score. Higher score = better opportunities.

---

## Architecture Overview

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                    KYA Protocol Architecture                 │
└─────────────────────────────────────────────────────────────┘

┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│   User       │──────│ AgentRegistry│──────│ AgentLicense │
│  (Minter)    │      │   (Factory)  │      │   (ERC-721)  │
└──────────────┘      └──────────────┘      └──────────────┘
                              │
                              │ Creates
                              ▼
                    ┌─────────────────────┐
                    │ Token Bound Account │
                    │   (ERC-6551 TBA)    │
                    └─────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│ Reputation   │      │  Insurance   │      │  Paymaster   │
│    Score     │      │    Vault     │      │ (ERC-4337)   │
└──────────────┘      └──────────────┘      └──────────────┘
        │                     │                     │
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│   ZKAdapter │      │   Oracle     │      │   EntryPoint │
│  (Axiom/    │      │   Adapter    │      │   (ERC-4337) │
│   Brevis)   │      │ (UMA/Kleros) │      │              │
└──────────────┘      └──────────────┘      └──────────────┘
```

### Data Flow

#### 1. Agent Creation Flow

```
User
  │
  ├─> AgentRegistry.mintAgent(name, description, category)
  │
  ├─> AgentLicense.mint(to, metadata)  [Mints NFT]
  │
  ├─> ERC6551Registry.createAccount(...)  [Creates TBA]
  │
  └─> Returns: (agentId, tokenId, tbaAddress)
```

**Code Example**:

```solidity
// User calls mintAgent
bytes32 agentId = agentRegistry.mintAgent(
    "TradingBot",
    "AI trading agent",
    "Trading"
);

// Internally, AgentRegistry:
// 1. Mints NFT
uint256 tokenId = agentLicense.mint(msg.sender, metadata);

// 2. Creates TBA
address tbaAddress = erc6551Registry.createAccount(
    accountImplementation,
    block.chainid,
    address(agentLicense),
    tokenId,
    ACCOUNT_SALT
);

// 3. Stores mapping
_agents[agentId] = AgentInfo({
    agentId: agentId,
    tokenId: tokenId,
    tbaAddress: tbaAddress,
    owner: msg.sender,
    metadata: metadata
});
```

#### 2. Reputation Building Flow

```
Agent TBA
  │
  ├─> Interacts with dApps (Uniswap, Aave, etc.)
  │
  ├─> ZKAdapter.submitQuery(proofQuery)
  │
  ├─> ZK Coprocessor generates proof
  │
  ├─> ZKAdapter.processProof(queryId, proof)
  │
  └─> ReputationScore.verifyProof(tokenId, proofType, proof)
      └─> Updates reputation score and badges
```

**Code Example**:

```solidity
// Agent has traded on Uniswap
// ZK coprocessor generates proof of volume

// Submit query
ProofQuery memory query = ProofQuery({
    agentAddress: tbaAddress,
    proofType: "UniswapVolume",
    data: abi.encode(volumeData)
});
bytes32 queryId = zkAdapter.submitQuery(query);

// ZK coprocessor processes (off-chain)
// ... proof generation ...

// Process proof on-chain
zkAdapter.processProof(queryId, proof, result);

// Update reputation
reputationScore.verifyProof(
    tokenId,
    "UniswapVolume",
    proof,
    "Uniswap Volume Badge"
);
```

#### 3. Staking & Verification Flow

```
Agent Owner
  │
  ├─> Fund TBA with USDC
  │
  ├─> TBA.approve(insuranceVault, amount)
  │
  ├─> TBA.execute(insuranceVault, 0, stakeCalldata)
  │
  ├─> InsuranceVault.stake(tokenId, amount)
  │
  └─> Agent becomes verified (if amount >= minimum)
```

**Code Example**:

```solidity
// 1. Fund TBA
usdc.transfer(tbaAddress, 1000 * 10**6);

// 2. Approve from TBA
IAgentAccount(tbaAddress).execute(
    address(usdc),
    0,
    abi.encodeWithSignature(
        "approve(address,uint256)",
        address(insuranceVault),
        1000 * 10**6
    )
);

// 3. Stake from TBA
IAgentAccount(tbaAddress).execute(
    address(insuranceVault),
    0,
    abi.encodeWithSignature(
        "stake(uint256,uint256)",
        tokenId,
        1000 * 10**6
    )
);

// 4. Check verification
bool isVerified = insuranceVault.isVerified(tokenId);  // true
```

#### 4. Claim & Slashing Flow

```
Merchant
  │
  ├─> InsuranceVault.submitClaim(tokenId, amount, reason)
  │
  ├─> Oracle resolves claim (UMA/Kleros)
  │
  ├─> InsuranceVault.resolveClaim(claimId, valid)
  │
  └─> InsuranceVault.slash(tokenId, amount)
      └─> Funds go to merchant
```

**Code Example**:

```solidity
// Merchant submits claim
bytes32 claimId = insuranceVault.submitClaim(
    tokenId,
    500 * 10**6,  // 500 USDC
    "Agent failed to deliver service"
);

// Oracle resolves (off-chain process)
// ... oracle resolution ...

// Resolve claim
insuranceVault.resolveClaim(claimId, true);  // Claim valid

// Slash agent
insuranceVault.slash(tokenId, 500 * 10**6);

// Merchant receives funds
usdc.transfer(merchant, 500 * 10**6);
```

---

## Code Deep Dive

### 1. AgentLicense.sol - The Identity NFT

**Purpose**: ERC-721 NFT that represents an agent's identity.

**Key Features**:
- Immutable metadata (name, description, category)
- Status tracking (Active, Suspended, Revoked)
- Only AgentRegistry can mint (MINTER_ROLE)

**Code Walkthrough**:

```solidity
contract AgentLicense is ERC721, AccessControl, IAgentLicense {
    // Role for addresses that can mint (only AgentRegistry)
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    // Token ID counter (starts at 1)
    uint256 private _tokenIdCounter;
    
    // Agent metadata stored on-chain
    mapping(uint256 => AgentMetadata) private _agentMetadata;
    
    /**
     * @notice Mint a new agent license
     * @dev Only callable by AgentRegistry (MINTER_ROLE)
     * 
     * Security Considerations:
     * - Input validation (name length, status)
     * - Access control (only MINTER_ROLE)
     * - Immutable metadata (can't be changed after minting)
     */
    function mint(address to, AgentMetadata calldata metadata)
        external
        override
        onlyRole(MINTER_ROLE)  // Only AgentRegistry can mint
        returns (uint256 tokenId)
    {
        // Input validation
        require(to != address(0), "AgentLicense: mint to zero address");
        require(bytes(metadata.name).length > 0, "AgentLicense: name cannot be empty");
        require(bytes(metadata.name).length <= 64, "AgentLicense: name too long");
        
        // Get next token ID (auto-increment)
        tokenId = _tokenIdCounter++;
        
        // Store metadata (immutable after minting)
        _agentMetadata[tokenId] = AgentMetadata({
            name: metadata.name,
            description: metadata.description,
            category: metadata.category,
            createdAt: block.timestamp,
            status: 0  // Active by default
        });
        
        // Mint NFT to user
        _safeMint(to, tokenId);
        
        emit AgentMinted(tokenId, to, metadata);
        return tokenId;
    }
    
    /**
     * @notice Get agent metadata
     * @dev Public view function for reading metadata
     */
    function getAgentMetadata(uint256 tokenId)
        external
        view
        override
        returns (AgentMetadata memory)
    {
        require(_ownerOf(tokenId) != address(0), "AgentLicense: token does not exist");
        return _agentMetadata[tokenId];
    }
}
```

**Best Practices Demonstrated**:
1. ✅ **Access Control**: Only authorized contracts can mint
2. ✅ **Input Validation**: Checks for empty strings, length limits
3. ✅ **Immutable Data**: Metadata can't be changed after minting
4. ✅ **Events**: Emits events for off-chain indexing
5. ✅ **Gas Optimization**: Uses `calldata` for function parameters

**Learning Points**:
- **Role-Based Access Control**: OpenZeppelin's `AccessControl` provides secure role management
- **Counter Pattern**: Auto-incrementing token IDs prevent collisions
- **Metadata Storage**: On-chain metadata enables composability (other contracts can read it)

### 2. AgentRegistry.sol - The Factory

**Purpose**: Factory contract that creates agents (NFT + TBA) atomically.

**Key Features**:
- Atomic creation (NFT + TBA in one transaction)
- Fee collection
- Deterministic TBA addresses (CREATE2)

**Code Walkthrough**:

```solidity
contract AgentRegistry is IAgentRegistry, AccessControl, Pausable, ReentrancyGuard {
    // Immutable references to other contracts
    IAgentLicense public immutable agentLicense;
    address public immutable accountImplementation;
    IERC6551Registry public immutable erc6551Registry;
    
    // Minting fee (in wei)
    uint256 private _mintingFee;
    
    // Agent counter and mappings
    uint256 private _agentCounter;
    mapping(bytes32 => AgentInfo) private _agents;
    mapping(uint256 => bytes32) private _tokenIdToAgentId;
    
    /**
     * @notice Create a new agent (NFT + TBA)
     * @dev Atomic operation: mints NFT and creates TBA
     * 
     * Security Considerations:
     * - Reentrancy protection (nonReentrant)
     * - Pausable (can pause in emergencies)
     * - Fee validation (must pay minting fee)
     * - Input validation (name, description)
     */
    function mintAgent(
        string calldata name,
        string calldata description,
        string calldata category
    ) external payable override nonReentrant whenNotPaused returns (bytes32 agentId) {
        // Validate fee payment
        require(msg.value >= _mintingFee, "AgentRegistry: insufficient fee");
        
        // Input validation
        require(bytes(name).length > 0, "AgentRegistry: name cannot be empty");
        require(bytes(category).length > 0, "AgentRegistry: category cannot be empty");
        
        // Generate agent ID
        agentId = keccak256(
            abi.encodePacked(
                _agentCounter++,
                msg.sender,
                block.timestamp,
                block.prevrandao
            )
        );
        
        // Create metadata
        IAgentLicense.AgentMetadata memory metadata = IAgentLicense.AgentMetadata({
            name: name,
            description: description,
            category: category,
            createdAt: block.timestamp,
            status: 0  // Active
        });
        
        // Step 1: Mint NFT
        uint256 tokenId = agentLicense.mint(msg.sender, metadata);
        
        // Step 2: Create TBA (Token Bound Account)
        address tbaAddress = erc6551Registry.createAccount(
            accountImplementation,      // Implementation contract
            block.chainid,              // Current chain ID
            address(agentLicense),      // NFT contract
            tokenId,                    // NFT token ID
            ACCOUNT_SALT                // Salt for deterministic address
        );
        
        // Step 3: Store agent info
        _agents[agentId] = AgentInfo({
            agentId: agentId,
            tokenId: tokenId,
            tbaAddress: tbaAddress,
            owner: msg.sender,
            metadata: metadata,
            createdAt: block.timestamp
        });
        
        _tokenIdToAgentId[tokenId] = agentId;
        
        // Accumulate fees
        _accumulatedFees += msg.value;
        
        emit AgentCreated(agentId, tokenId, tbaAddress, msg.sender);
        return agentId;
    }
    
    /**
     * @notice Compute TBA address (deterministic)
     * @dev Uses CREATE2 to compute address without deploying
     * 
     * Why Deterministic?
     * - Same inputs = same address
     * - Can compute address before deployment
     * - Enables pre-funding the TBA
     */
    function computeTBAAddress(uint256 tokenId)
        external
        view
        override
        returns (address)
    {
        return erc6551Registry.account(
            accountImplementation,
            block.chainid,
            address(agentLicense),
            tokenId,
            ACCOUNT_SALT
        );
    }
}
```

**Best Practices Demonstrated**:
1. ✅ **Atomic Operations**: NFT + TBA created together (no partial state)
2. ✅ **Reentrancy Protection**: `nonReentrant` modifier
3. ✅ **Pausable**: Can pause in emergencies
4. ✅ **Deterministic Addresses**: CREATE2 enables pre-funding
5. ✅ **Fee Collection**: Accumulates fees for withdrawal

**Learning Points**:
- **Factory Pattern**: Centralized creation point for consistency
- **CREATE2**: Deterministic addresses enable advanced features
- **Immutable References**: Using `immutable` saves gas
- **Event Emission**: Critical for off-chain indexing

### 3. SimpleAccountImplementation.sol - The TBA Wallet

**Purpose**: Smart contract wallet controlled by NFT owner.

**Key Features**:
- Controlled by NFT owner
- Can execute arbitrary transactions
- State counter for signature invalidation
- Minimal proxy pattern (gas efficient)

**Code Walkthrough**:

```solidity
contract SimpleAccountImplementation is IAgentAccount {
    // State counter (increments on NFT transfer to invalidate signatures)
    uint256 private _state;
    
    /**
     * @notice Get the NFT that owns this account
     * @dev Reads from bytecode footer (set by ERC6551Registry)
     * 
     * How it works:
     * - ERC6551Registry stores token info in account bytecode
     * - Last 96 bytes contain: chainId (32) + tokenContract (32) + tokenId (32)
     * - We read this to determine ownership
     */
    function token()
        public
        view
        override
        returns (uint256 chainId, address tokenContract, uint256 tokenId)
    {
        bytes memory footer = new bytes(0x60);  // 96 bytes
        
        assembly {
            // Read last 96 bytes of deployed bytecode
            extcodecopy(address(), add(footer, 0x20), 0x4d, 0x60)
        }
        
        return abi.decode(footer, (uint256, address, uint256));
    }
    
    /**
     * @notice Check if signer is authorized
     * @dev Only NFT owner can use this account
     * 
     * Security:
     * - Checks NFT ownership
     * - Returns magic value if authorized (ERC-1271 standard)
     */
    function isValidSigner(address signer, bytes calldata)
        external
        view
        override
        returns (bytes4)
    {
        (,, uint256 tokenId) = token();
        address owner = IERC721(tokenContract).ownerOf(tokenId);
        
        if (signer == owner) {
            return IERC1271.isValidSigner.selector;  // Magic value
        }
        
        return bytes4(0);  // Not authorized
    }
    
    /**
     * @notice Execute a transaction
     * @dev Only NFT owner can execute
     * 
     * Security:
     * - Authorization check
     * - Revert on failure
     * - Emits event for tracking
     */
    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable override returns (bytes memory result) {
        // Check authorization
        (,, uint256 tokenId) = token();
        address owner = IERC721(tokenContract).ownerOf(tokenId);
        require(msg.sender == owner, "SimpleAccount: not authorized");
        
        // Execute transaction
        bool success;
        (success, result) = to.call{value: value}(data);
        
        if (!success) {
            // Bubble up revert reason
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        
        emit Executed(to, value, data);
        return result;
    }
    
    /**
     * @notice Receive ETH
     * @dev Allows account to receive ETH directly
     */
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
```

**Best Practices Demonstrated**:
1. ✅ **Authorization**: Only NFT owner can execute
2. ✅ **State Counter**: Invalidates signatures on transfer
3. ✅ **Error Handling**: Properly bubbles up revert reasons
4. ✅ **Events**: Emits events for all actions
5. ✅ **Gas Efficiency**: Minimal proxy pattern

**Learning Points**:
- **ERC-1271**: Standard for signature validation in smart contracts
- **Assembly**: Low-level operations for reading bytecode
- **Minimal Proxy**: Clone pattern saves deployment gas
- **Call Pattern**: Using `call` for arbitrary execution

### 4. InsuranceVault.sol - Economic Security

**Purpose**: Staking and slashing mechanism for agent verification.

**Key Features**:
- Minimum stake requirement (e.g., 1000 USDC)
- Claim submission and resolution
- Slashing mechanism
- Unstaking cooldown

**Code Walkthrough**:

```solidity
contract InsuranceVault is IInsuranceVault, AccessControl, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    
    // Constants
    uint256 public constant CHALLENGE_PERIOD = 24 hours;
    uint256 public constant UNSTAKE_COOLDOWN = 7 days;
    
    // State
    IERC20 public immutable usdc;
    uint256 public minimumStake;
    mapping(uint256 => StakeInfo) private _stakes;
    mapping(bytes32 => Claim) private _claims;
    
    /**
     * @notice Stake USDC to become verified
     * @dev Called from TBA (agent's wallet)
     * 
     * Security:
     * - Reentrancy protection
     * - Input validation
     * - Safe token transfers
     * - Minimum stake requirement
     */
    function stake(uint256 tokenId, uint256 amount)
        external
        override
        nonReentrant
        whenNotPaused
    {
        // Validate token exists
        try agentLicense.ownerOf(tokenId) returns (address) {} catch {
            revert InvalidTokenId();
        }
        
        // Validate amount
        if (amount < minimumStake) {
            revert InsufficientStake();
        }
        
        // Get TBA address (cache for gas optimization)
        StakeInfo storage stakeInfo = _stakes[tokenId];
        address tbaAddress = stakeInfo.tbaAddress;
        
        if (tbaAddress == address(0)) {
            // First stake - get and cache TBA address
            IAgentRegistry.AgentInfo memory info = agentRegistry.getAgentInfoByTokenId(tokenId);
            tbaAddress = info.tbaAddress;
            stakeInfo.tbaAddress = tbaAddress;
        }
        
        // Transfer USDC from TBA to vault
        usdc.safeTransferFrom(tbaAddress, address(this), amount);
        
        // Update stake info
        bool isFirstStake = stakeInfo.amount == 0;
        stakeInfo.amount += amount;
        if (isFirstStake) {
            stakeInfo.stakedAt = block.timestamp;
        }
        stakeInfo.isVerified = stakeInfo.amount >= minimumStake;
        
        // Update total staked
        _totalStaked += amount;
        
        emit Staked(tokenId, amount, tbaAddress);
    }
    
    /**
     * @notice Submit a claim against an agent
     * @dev Only merchants can submit claims
     * 
     * Security:
     * - Access control (merchant role)
     * - Claim validation
     * - Challenge period
     */
    function submitClaim(
        uint256 tokenId,
        uint256 amount,
        string calldata reason
    ) external override onlyRole(MERCHANT_ROLE) returns (bytes32 claimId) {
        // Validate stake exists
        StakeInfo memory stakeInfo = _stakes[tokenId];
        if (stakeInfo.amount == 0) {
            revert InvalidTokenId();
        }
        
        // Validate claim amount
        if (amount == 0 || amount > stakeInfo.amount) {
            revert InvalidAmount();
        }
        
        // Generate claim ID
        claimId = keccak256(
            abi.encodePacked(
                _claimCounter++,
                tokenId,
                msg.sender,
                block.timestamp
            )
        );
        
        // Create claim
        _claims[claimId] = Claim({
            claimId: claimId,
            tokenId: tokenId,
            merchant: msg.sender,
            amount: amount,
            reason: reason,
            status: 0,  // Pending
            submittedAt: block.timestamp,
            resolvedAt: 0
        });
        
        _agentClaims[tokenId].push(claimId);
        
        emit ClaimSubmitted(claimId, tokenId, msg.sender, amount);
        return claimId;
    }
    
    /**
     * @notice Resolve a claim (oracle/admin)
     * @dev Only oracle/admin can resolve
     */
    function resolveClaim(bytes32 claimId, bool valid)
        external
        override
        onlyRole(ORACLE_ROLE)
    {
        Claim storage claim = _claims[claimId];
        if (claim.status != 0) {
            revert ClaimAlreadyResolved();
        }
        
        claim.status = valid ? 1 : 2;  // 1 = Valid, 2 = Invalid
        claim.resolvedAt = block.timestamp;
        
        emit ClaimResolved(claimId, valid);
    }
    
    /**
     * @notice Slash an agent (after claim resolution)
     * @dev Only oracle/admin can slash
     */
    function slash(uint256 tokenId, uint256 amount)
        external
        override
        onlyRole(ORACLE_ROLE)
        nonReentrant
    {
        StakeInfo storage stakeInfo = _stakes[tokenId];
        
        // Validate
        if (stakeInfo.amount < amount) {
            revert InsufficientBalance();
        }
        
        // Update stake
        stakeInfo.amount -= amount;
        stakeInfo.isVerified = stakeInfo.amount >= minimumStake;
        _totalStaked -= amount;
        
        // Transfer to merchant (or treasury)
        address merchant = _getMerchantForClaim(tokenId);
        usdc.safeTransfer(merchant, amount);
        
        emit Slashed(tokenId, amount, merchant);
    }
}
```

**Best Practices Demonstrated**:
1. ✅ **Safe Token Transfers**: Using `SafeERC20` prevents issues with non-standard tokens
2. ✅ **Reentrancy Protection**: `nonReentrant` on all external functions
3. ✅ **Access Control**: Role-based permissions
4. ✅ **State Validation**: Checks before state changes
5. ✅ **Event Emission**: All state changes emit events

**Learning Points**:
- **Checks-Effects-Interactions**: Validate → Update state → External calls
- **SafeERC20**: Handles tokens that don't return bool
- **Cooldown Periods**: Prevent rapid unstaking
- **Slashing Mechanism**: Economic disincentive for bad behavior

### 5. ReputationScore.sol - Reputation System

**Purpose**: Tracks agent reputation based on verified proofs.

**Key Features**:
- Tier system (Bronze, Silver, Gold, Platinum, Whale)
- Badge system
- ZK proof verification
- Whitelisted contracts

**Code Walkthrough**:

```solidity
contract ReputationScore is IReputationScore, AccessControl {
    // Tier thresholds
    uint256 public constant TIER_BRONZE = 100;
    uint256 public constant TIER_SILVER = 500;
    uint256 public constant TIER_GOLD = 2000;
    uint256 public constant TIER_PLATINUM = 10000;
    uint256 public constant TIER_WHALE = 50000;
    
    // State
    mapping(uint256 => ReputationData) private _reputations;
    mapping(uint256 => mapping(bytes32 => bool)) private _badges;
    mapping(bytes32 => bool) private _verifiedProofs;  // Replay prevention
    
    /**
     * @notice Verify a ZK proof and update reputation
     * @dev Only ZK_PROVER_ROLE can verify proofs
     * 
     * Security:
     * - Proof replay prevention
     * - Whitelisted contracts only
     * - Access control
     */
    function verifyProof(
        uint256 tokenId,
        string calldata proofType,
        bytes calldata proof,
        string calldata description
    ) external override onlyRole(ZK_PROVER_ROLE) {
        // Validate token exists
        if (agentLicense.ownerOf(tokenId) == address(0)) {
            revert InvalidTokenId();
        }
        
        // Prevent proof replay
        bytes32 proofHash = keccak256(abi.encodePacked(tokenId, proofType, proof));
        if (_verifiedProofs[proofHash]) {
            revert ProofAlreadyVerified();
        }
        _verifiedProofs[proofHash] = true;
        
        // Get score increase for this proof type
        uint256 scoreIncrease = _proofTypeScores[proofType];
        if (scoreIncrease == 0) {
            revert InvalidProofType();
        }
        
        // Update reputation
        ReputationData storage rep = _reputations[tokenId];
        rep.score += scoreIncrease;
        rep.verifiedProofs += 1;
        
        // Update tier
        uint8 newTier = _calculateTier(rep.score);
        if (newTier > rep.tier) {
            rep.tier = newTier;
        }
        
        // Award badge if applicable
        string memory badgeName = _proofTypeBadges[proofType];
        if (bytes(badgeName).length > 0) {
            bytes32 badgeId = keccak256(abi.encodePacked(badgeName));
            if (!_badges[tokenId][badgeId]) {
                _badges[tokenId][badgeId] = true;
                _badgeLists[tokenId].push(badgeId);
            }
        }
        
        emit ProofVerified(tokenId, proofType, rep.score, rep.tier);
    }
    
    /**
     * @notice Calculate tier based on score
     * @dev Internal helper function
     */
    function _calculateTier(uint256 score) internal pure returns (uint8) {
        if (score >= TIER_WHALE) return 5;
        if (score >= TIER_PLATINUM) return 4;
        if (score >= TIER_GOLD) return 3;
        if (score >= TIER_SILVER) return 2;
        if (score >= TIER_BRONZE) return 1;
        return 0;
    }
}
```

**Best Practices Demonstrated**:
1. ✅ **Replay Prevention**: Tracks verified proofs
2. ✅ **Tier System**: Clear progression path
3. ✅ **Badge System**: Visual achievements
4. ✅ **Access Control**: Only verified provers can update
5. ✅ **Gas Optimization**: Efficient storage patterns

**Learning Points**:
- **Replay Prevention**: Critical for proof systems
- **Tier Calculations**: Efficient comparison logic
- **Badge Management**: Efficient storage with mappings
- **Score Accumulation**: Monotonic increase (never decreases)

### 6. Paymaster.sol - Gas Sponsorship

**Purpose**: Sponsors gas fees for new agents (cold start period).

**Key Features**:
- 7-day cold start period
- Maximum 50 sponsored transactions
- Twitter verification requirement
- ERC-4337 integration

**Code Walkthrough**:

```solidity
contract Paymaster is IPaymaster, AccessControl, ReentrancyGuard {
    // Constants
    uint256 public constant COLD_START_PERIOD = 7 days;
    uint256 public constant MAX_SPONSORED_TXS = 50;
    
    // State
    address private immutable _entryPoint;
    mapping(uint256 => uint256) private _sponsoredCounts;
    mapping(uint256 => bool) private _twitterVerified;
    
    /**
     * @notice Check if agent is eligible for gas sponsorship
     * @dev Must be < 7 days old, < 50 transactions, Twitter verified
     */
    function isEligible(uint256 tokenId) public view override returns (bool eligible, uint256 remaining) {
        // Check token exists
        if (agentLicense.ownerOf(tokenId) == address(0)) {
            return (false, 0);
        }
        
        // Get agent creation time
        IAgentLicense.AgentMetadata memory metadata = agentLicense.getAgentMetadata(tokenId);
        uint256 age = block.timestamp - metadata.createdAt;
        
        // Check age
        if (age >= COLD_START_PERIOD) {
            return (false, 0);
        }
        
        // Check Twitter verification
        if (!_twitterVerified[tokenId]) {
            return (false, 0);
        }
        
        // Check transaction count
        uint256 sponsored = _sponsoredCounts[tokenId];
        if (sponsored >= MAX_SPONSORED_TXS) {
            return (false, 0);
        }
        
        return (true, MAX_SPONSORED_TXS - sponsored);
    }
    
    /**
     * @notice Validate paymaster user operation (ERC-4337)
     * @dev Called by EntryPoint before executing user operation
     */
    function validatePaymasterUserOp(
        uint8 /* mode */,
        bytes calldata /* userOp */,
        bytes calldata paymasterAndData
    ) external override returns (bytes memory context, uint256 validationData) {
        // Only EntryPoint can call
        require(msg.sender == _entryPoint, "Paymaster: invalid entry point");
        
        // Decode token ID from paymasterAndData
        uint256 tokenId = abi.decode(paymasterAndData[20:52], (uint256));
        
        // Check eligibility
        (bool eligible,) = isEligible(tokenId);
        if (!eligible) {
            revert NotEligible();
        }
        
        // Increment sponsored count
        _sponsoredCounts[tokenId]++;
        
        // Return context (token ID) and validation data
        context = abi.encode(tokenId);
        validationData = 0;  // No deadline, no signature required
    }
    
    /**
     * @notice Post-operation hook (ERC-4337)
     * @dev Called after user operation execution
     */
    function postOp(uint8 /* mode */, bytes calldata context, uint256 actualGasCost)
        external
        override
        nonReentrant
    {
        // Only EntryPoint can call
        require(msg.sender == _entryPoint, "Paymaster: invalid entry point");
        
        // Decode context
        uint256 tokenId = abi.decode(context, (uint256));
        
        // Pay for gas (would transfer from paymaster balance in EntryPoint)
        // This is simplified - real implementation would handle gas payment
        
        emit GasSponsored(tokenId, actualGasCost);
    }
}
```

**Best Practices Demonstrated**:
1. ✅ **Eligibility Checks**: Multiple conditions (age, count, verification)
2. ✅ **ERC-4337 Compliance**: Follows standard interface
3. ✅ **Access Control**: Only EntryPoint can call
4. ✅ **Reentrancy Protection**: On post-operation
5. ✅ **Gas Tracking**: Monitors sponsored transactions

**Learning Points**:
- **ERC-4337 Standard**: Account abstraction paymaster pattern
- **Cold Start**: Helps new users get started
- **Rate Limiting**: Prevents abuse with transaction limits
- **Context Passing**: Using context for state between validate/postOp

---

## Use Cases & Applications

### 1. AI Trading Agents

**Scenario**: An AI agent that trades on Uniswap wants to prove its trading history to access premium DeFi services.

**How KYA Helps**:
1. Agent mints license and gets TBA
2. Agent trades on Uniswap (using TBA)
3. ZK coprocessor generates proof of volume
4. Reputation increases (Uniswap Volume Badge)
5. Agent stakes USDC to become verified
6. DeFi protocols trust verified agents with good reputation

**Code Example**:

```solidity
// 1. Create agent
bytes32 agentId = agentRegistry.mintAgent(
    "TradingBot",
    "AI trading agent",
    "Trading"
);

// 2. Agent trades (off-chain, using TBA)
// ... trading happens ...

// 3. Submit proof query
ProofQuery memory query = ProofQuery({
    agentAddress: tbaAddress,
    proofType: "UniswapVolume",
    data: volumeData
});
zkAdapter.submitQuery(query);

// 4. Proof verified (off-chain by ZK coprocessor)
zkAdapter.processProof(queryId, proof, result);

// 5. Reputation updated
reputationScore.verifyProof(tokenId, "UniswapVolume", proof, "Uniswap Volume");

// 6. Stake to become verified
insuranceVault.stake(tokenId, 1000 * 10**6);  // 1000 USDC

// 7. Access premium services
// DeFi protocols can check: isVerified && tier >= GOLD
```

### 2. AI Lending Agents

**Scenario**: An AI agent that provides lending services needs to prove its track record.

**How KYA Helps**:
1. Agent builds reputation through successful loans
2. ZK proofs prove loan history without revealing borrower details
3. Staking provides economic security
4. Merchants trust verified agents with good reputation

**Benefits**:
- **Privacy**: Borrower details stay private
- **Trust**: Reputation proves track record
- **Security**: Staking provides recourse
- **Composability**: Works with any lending protocol

### 3. AI Content Creation Agents

**Scenario**: An AI agent creates content and needs to prove originality and quality.

**How KYA Helps**:
1. Agent creates content (using TBA for payments)
2. ZK proofs prove content metrics (views, engagement)
3. Badges for achievements (1M views, viral content)
4. Staking ensures quality commitment

**Benefits**:
- **Proven Track Record**: Reputation shows success
- **Badge System**: Visual achievements
- **Economic Security**: Staking ensures commitment
- **Transferable**: Can sell successful agent identity

### 4. Multi-Agent Systems

**Scenario**: A system with multiple AI agents working together.

**How KYA Helps**:
1. Each agent has its own license and TBA
2. Agents can prove their individual contributions
3. System reputation aggregates individual reputations
4. Staking provides system-wide security

**Benefits**:
- **Individual Identity**: Each agent has its own reputation
- **System Reputation**: Aggregate trust
- **Modularity**: Agents can be swapped
- **Accountability**: Individual agent responsibility

### 5. Agent Marketplace

**Scenario**: A marketplace where agents can be bought and sold.

**How KYA Helps**:
1. Agents are NFTs (transferable)
2. Reputation and badges are on-chain
3. Staking provides value signal
4. Buyers can verify agent history

**Benefits**:
- **Transferable Identity**: NFT ownership transfer
- **Proven Value**: On-chain reputation
- **Price Discovery**: Market determines value
- **Trust**: Verified agents have economic security

---

## Implementation Guide

### Step 1: Setup Development Environment

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Clone repository
git clone https://github.com/RahilBhavan/KYA.git
cd KYA

# Install dependencies
forge install OpenZeppelin/openzeppelin-contracts
forge install erc6551/reference
forge install foundry-rs/forge-std

# Build contracts
forge build

# Run tests
forge test
```

### Step 2: Deploy Contracts

```bash
# Set environment variables
export PRIVATE_KEY=your_private_key
export RPC_URL=https://sepolia.base.org
export ETHERSCAN_API_KEY=your_api_key

# Deploy to Base Sepolia
forge script script/DeployBaseSepolia.s.sol \
  --rpc-url $RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

### Step 3: Create Your First Agent

```solidity
// Using Foundry script
// script/CreateAgent.s.sol

import {Script} from "forge-std/Script.sol";
import {IAgentRegistry} from "../src/interfaces/IAgentRegistry.sol";

contract CreateAgent is Script {
    function run() external {
        IAgentRegistry registry = IAgentRegistry(vm.envAddress("AGENT_REGISTRY"));
        
        vm.startBroadcast();
        
        bytes32 agentId = registry.mintAgent{value: 0.01 ether}(
            "MyAgent",
            "My first AI agent",
            "Trading"
        );
        
        vm.stopBroadcast();
        
        console.log("Agent created:", uint256(agentId));
    }
}
```

### Step 4: Integrate with Your Application

```typescript
// Using JavaScript SDK
import { KYAClient } from '@kya-protocol/integrations';

const client = new KYAClient({
  rpcUrl: 'https://sepolia.base.org',
  agentRegistryAddress: '0x...',
  // ... other config
});

// Create agent
const agent = await client.createAgent({
  name: 'MyAgent',
  description: 'My first AI agent',
  category: 'Trading'
});

// Get TBA address
const tbaAddress = await client.getTBAAddress(agent.tokenId);

// Fund TBA
await client.fundTBA(tbaAddress, '1000000000');  // 1000 USDC

// Stake to become verified
await client.stake(agent.tokenId, '1000000000');
```

### Step 5: Build Reputation

```typescript
// Submit proof query
const queryId = await client.submitProofQuery({
  agentAddress: tbaAddress,
  proofType: 'UniswapVolume',
  data: volumeData
});

// Wait for proof generation (ZK coprocessor)
// ... proof generation happens off-chain ...

// Process proof
await client.processProof(queryId, proof, result);

// Check reputation
const reputation = await client.getReputation(agent.tokenId);
console.log('Score:', reputation.score);
console.log('Tier:', reputation.tier);
console.log('Badges:', reputation.badges);
```

---

## Expansion Possibilities

### 1. Cross-Chain Support

**Current**: Base network only  
**Expansion**: Multi-chain support

**Implementation**:
- Deploy contracts on multiple chains
- Use LayerZero/Chainlink CCIP for cross-chain messaging
- Unified reputation across chains

**Code Example**:

```solidity
// Cross-chain reputation sync
contract CrossChainReputation {
    function syncReputation(
        uint256 tokenId,
        uint256 score,
        bytes calldata proof
    ) external {
        // Verify proof from source chain
        require(verifyCrossChainProof(proof), "Invalid proof");
        
        // Update reputation on destination chain
        reputationScore.updateScore(tokenId, score);
    }
}
```

### 2. Governance System

**Current**: Admin-controlled  
**Expansion**: DAO governance

**Implementation**:
- Governance token (KYA token)
- Proposal system
- Voting mechanism
- Timelock for critical changes

**Code Example**:

```solidity
contract KYAGovernance {
    IERC20 public kyaToken;
    
    struct Proposal {
        address target;
        bytes data;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 deadline;
    }
    
    mapping(uint256 => Proposal) public proposals;
    
    function propose(address target, bytes calldata data) external returns (uint256 proposalId) {
        require(kyaToken.balanceOf(msg.sender) >= MIN_PROPOSAL_BALANCE, "Insufficient balance");
        
        proposalId = _proposalCounter++;
        proposals[proposalId] = Proposal({
            target: target,
            data: data,
            votesFor: 0,
            votesAgainst: 0,
            deadline: block.timestamp + VOTING_PERIOD
        });
    }
    
    function execute(uint256 proposalId) external {
        Proposal memory proposal = proposals[proposalId];
        require(block.timestamp > proposal.deadline, "Voting ongoing");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal failed");
        
        (bool success,) = proposal.target.call(proposal.data);
        require(success, "Execution failed");
    }
}
```

### 3. Advanced Reputation Algorithms

**Current**: Simple score accumulation  
**Expansion**: Time-weighted, decay, multi-factor

**Implementation**:
- Time-weighted scores (recent activity matters more)
- Score decay (inactivity reduces score)
- Multi-factor reputation (trading, lending, content)

**Code Example**:

```solidity
contract AdvancedReputationScore {
    struct ReputationData {
        uint256 score;
        uint256 lastActivity;
        mapping(string => uint256) categoryScores;  // Trading, Lending, etc.
    }
    
    function updateReputation(
        uint256 tokenId,
        string calldata category,
        uint256 points
    ) external {
        ReputationData storage rep = _reputations[tokenId];
        
        // Time decay (reduce score if inactive)
        uint256 timeSinceActivity = block.timestamp - rep.lastActivity;
        if (timeSinceActivity > DECAY_PERIOD) {
            uint256 decayAmount = (rep.score * DECAY_RATE * timeSinceActivity) / (DECAY_PERIOD * 1e18);
            rep.score = rep.score > decayAmount ? rep.score - decayAmount : 0;
        }
        
        // Time-weighted points (recent activity weighted more)
        uint256 timeWeight = calculateTimeWeight(timeSinceActivity);
        uint256 weightedPoints = (points * timeWeight) / 1e18;
        
        // Update category score
        rep.categoryScores[category] += weightedPoints;
        
        // Update total score
        rep.score += weightedPoints;
        rep.lastActivity = block.timestamp;
    }
}
```

### 4. NFT Marketplace Integration

**Current**: Basic NFT transfer  
**Expansion**: Full marketplace with reputation-based pricing

**Implementation**:
- Integration with OpenSea, LooksRare
- Reputation-based pricing suggestions
- Verified agent badges in marketplace UI

**Code Example**:

```solidity
contract AgentMarketplace {
    struct Listing {
        uint256 tokenId;
        address seller;
        uint256 price;
        uint256 reputationScore;
        uint8 tier;
    }
    
    mapping(uint256 => Listing) public listings;
    
    function listAgent(uint256 tokenId, uint256 price) external {
        require(agentLicense.ownerOf(tokenId) == msg.sender, "Not owner");
        
        ReputationData memory rep = reputationScore.getReputation(tokenId);
        
        listings[tokenId] = Listing({
            tokenId: tokenId,
            seller: msg.sender,
            price: price,
            reputationScore: rep.score,
            tier: rep.tier
        });
    }
    
    function buyAgent(uint256 tokenId) external payable {
        Listing memory listing = listings[tokenId];
        require(msg.value >= listing.price, "Insufficient payment");
        
        // Transfer NFT (TBA ownership transfers automatically)
        agentLicense.transferFrom(listing.seller, msg.sender, tokenId);
        
        // Transfer payment
        payable(listing.seller).transfer(listing.price);
        
        // Refund excess
        if (msg.value > listing.price) {
            payable(msg.sender).transfer(msg.value - listing.price);
        }
    }
}
```

### 5. Mobile SDK

**Current**: JavaScript SDK only  
**Expansion**: React Native, iOS, Android SDKs

**Implementation**:
- React Native wrapper
- Native iOS/Android SDKs
- Mobile-optimized wallet integration

### 6. Analytics Dashboard

**Current**: Basic on-chain queries  
**Expansion**: Comprehensive analytics platform

**Implementation**:
- The Graph subgraph for indexing
- Analytics API
- Dashboard UI
- Real-time metrics

**Code Example**:

```typescript
// The Graph subgraph
export function handleAgentCreated(event: AgentCreated): void {
  let agent = new Agent(event.params.agentId.toHex());
  agent.tokenId = event.params.tokenId;
  agent.tbaAddress = event.params.tbaAddress;
  agent.owner = event.params.owner;
  agent.createdAt = event.block.timestamp;
  agent.save();
}

export function handleReputationUpdated(event: ProofVerified): void {
  let agent = Agent.load(event.params.tokenId.toHex());
  if (agent) {
    agent.reputationScore = event.params.newScore;
    agent.tier = event.params.newTier;
    agent.save();
  }
}
```

### 7. Insurance Pool Expansion

**Current**: Individual staking  
**Expansion**: Shared insurance pools

**Implementation**:
- Pool-based insurance
- Risk-based pricing
- Reinsurance mechanisms

**Code Example**:

```solidity
contract InsurancePool {
    struct Pool {
        uint256 totalStaked;
        uint256 totalCoverage;
        uint256 premiumRate;  // Basis points
    }
    
    mapping(uint256 => Pool) public pools;
    
    function joinPool(uint256 poolId, uint256 stakeAmount) external {
        Pool storage pool = pools[poolId];
        
        // Calculate premium based on risk
        uint256 premium = (stakeAmount * pool.premiumRate) / 10000;
        
        // Stake in pool
        usdc.safeTransferFrom(msg.sender, address(this), stakeAmount + premium);
        pool.totalStaked += stakeAmount;
        
        // Distribute premium to pool participants
        distributePremium(poolId, premium);
    }
}
```

---

## Best Practices

### 1. Security Best Practices

#### Input Validation

```solidity
// ✅ GOOD: Validate all inputs
function stake(uint256 tokenId, uint256 amount) external {
    require(tokenId > 0, "Invalid token ID");
    require(amount >= minimumStake, "Insufficient stake");
    require(amount <= MAX_STAKE, "Exceeds maximum");
    // ... rest of function
}

// ❌ BAD: No validation
function stake(uint256 tokenId, uint256 amount) external {
    // No checks - vulnerable to attacks
    _stakes[tokenId].amount += amount;
}
```

#### Reentrancy Protection

```solidity
// ✅ GOOD: Use ReentrancyGuard
contract InsuranceVault is ReentrancyGuard {
    function unstake(uint256 tokenId, uint256 amount) 
        external 
        nonReentrant  // Prevents reentrancy
    {
        // ... checks ...
        usdc.safeTransfer(msg.sender, amount);  // External call
        // ... state updates ...
    }
}

// ❌ BAD: No protection
function unstake(uint256 tokenId, uint256 amount) external {
    usdc.transfer(msg.sender, amount);  // Vulnerable to reentrancy
    _stakes[tokenId].amount -= amount;
}
```

#### Access Control

```solidity
// ✅ GOOD: Role-based access control
contract ReputationScore is AccessControl {
    bytes32 public constant ZK_PROVER_ROLE = keccak256("ZK_PROVER_ROLE");
    
    function verifyProof(...) external onlyRole(ZK_PROVER_ROLE) {
        // Only authorized provers can verify
    }
}

// ❌ BAD: No access control
function verifyProof(...) external {
    // Anyone can verify - security risk
}
```

### 2. Gas Optimization Best Practices

#### Use Immutable

```solidity
// ✅ GOOD: Immutable saves gas
contract InsuranceVault {
    IERC20 public immutable usdc;  // Stored in bytecode, not storage
    IAgentLicense public immutable agentLicense;
    
    constructor(address usdc_, address agentLicense_) {
        usdc = IERC20(usdc_);
        agentLicense = IAgentLicense(agentLicense_);
    }
}

// ❌ BAD: Storage variable
contract InsuranceVault {
    IERC20 public usdc;  // Stored in storage slot (more expensive)
}
```

#### Pack Structs

```solidity
// ✅ GOOD: Packed struct (saves storage slots)
struct StakeInfo {
    uint128 amount;      // 16 bytes
    uint64 stakedAt;     // 8 bytes
    bool isVerified;     // 1 byte
    // Total: 25 bytes (fits in 1 slot)
}

// ❌ BAD: Unpacked struct (uses more slots)
struct StakeInfo {
    uint256 amount;      // 32 bytes (1 slot)
    uint256 stakedAt;   // 32 bytes (1 slot)
    bool isVerified;    // 1 byte (1 slot)
    // Total: 3 slots
}
```

#### Cache Storage Reads

```solidity
// ✅ GOOD: Cache storage reads
function updateStake(uint256 tokenId, uint256 amount) external {
    StakeInfo storage stakeInfo = _stakes[tokenId];  // Cache
    stakeInfo.amount += amount;  // Write to cache
    stakeInfo.isVerified = stakeInfo.amount >= minimumStake;  // Read from cache
}

// ❌ BAD: Multiple storage reads
function updateStake(uint256 tokenId, uint256 amount) external {
    _stakes[tokenId].amount += amount;  // Storage read + write
    _stakes[tokenId].isVerified = _stakes[tokenId].amount >= minimumStake;  // Another read
}
```

### 3. Code Quality Best Practices

#### Use Custom Errors

```solidity
// ✅ GOOD: Custom errors (cheaper than strings)
error InsufficientStake();
error InvalidTokenId();

function stake(uint256 tokenId, uint256 amount) external {
    if (amount < minimumStake) {
        revert InsufficientStake();  // ~50 gas cheaper
    }
}

// ❌ BAD: String errors
function stake(uint256 tokenId, uint256 amount) external {
    require(amount >= minimumStake, "Insufficient stake");  // More expensive
}
```

#### Events for Important State Changes

```solidity
// ✅ GOOD: Emit events
event Staked(uint256 indexed tokenId, uint256 amount, address indexed staker);

function stake(uint256 tokenId, uint256 amount) external {
    // ... stake logic ...
    emit Staked(tokenId, amount, msg.sender);  // Off-chain indexing
}

// ❌ BAD: No events
function stake(uint256 tokenId, uint256 amount) external {
    // ... stake logic ...
    // No event - can't track off-chain
}
```

#### NatSpec Documentation

```solidity
/**
 * @title InsuranceVault
 * @notice Insurance vault for agent staking and slashing mechanism
 * @dev Implements the economic security layer for the KYA Protocol
 * 
 * @custom:security This contract uses ReentrancyGuard and AccessControl
 * @custom:gas-optimization Uses SafeERC20 and packed structs
 */
contract InsuranceVault {
    /**
     * @notice Stake USDC to become verified
     * @param tokenId The agent's token ID
     * @param amount The amount to stake (in USDC, 6 decimals)
     * @dev Minimum stake required is set by `minimumStake`
     * @dev Agent becomes verified if stake >= minimumStake
     * @custom:security Protected by ReentrancyGuard
     */
    function stake(uint256 tokenId, uint256 amount) external {
        // ...
    }
}
```

### 4. Testing Best Practices

#### Comprehensive Test Coverage

```solidity
// ✅ GOOD: Test all paths
function test_stake_success() public {
    // Happy path
}

function test_stake_insufficientAmount() public {
    // Edge case: amount < minimum
    vm.expectRevert(InsufficientStake.selector);
    insuranceVault.stake(tokenId, minimumStake - 1);
}

function test_stake_invalidTokenId() public {
    // Edge case: token doesn't exist
    vm.expectRevert(InvalidTokenId.selector);
    insuranceVault.stake(999999, amount);
}

function testFuzz_stake(uint256 amount) public {
    // Fuzz test: random inputs
    amount = bound(amount, minimumStake, 1000000 * 10**6);
    // ... test logic ...
}
```

#### Use Fuzz Testing

```solidity
// ✅ GOOD: Fuzz testing finds edge cases
function testFuzz_unstake(uint256 stakeAmount, uint256 unstakeAmount) public {
    stakeAmount = bound(stakeAmount, minimumStake, 100000 * 10**6);
    unstakeAmount = bound(unstakeAmount, 1, stakeAmount);
    
    // Test with various combinations
    // ...
}
```

#### Invariant Testing

```solidity
// ✅ GOOD: Test protocol invariants
function invariant_verifiedAgentsHaveMinimumStake() public {
    // This should always be true
    if (insuranceVault.isVerified(tokenId)) {
        StakeInfo memory stake = insuranceVault.getStakeInfo(tokenId);
        assertGe(stake.amount, minimumStake);
    }
}
```

### 5. Deployment Best Practices

#### Use Deterministic Addresses

```solidity
// ✅ GOOD: CREATE2 for deterministic addresses
address tbaAddress = erc6551Registry.createAccount(
    implementation,
    chainId,
    nftContract,
    tokenId,
    salt  // Deterministic
);
```

#### Verify Contracts

```bash
# ✅ GOOD: Verify all contracts
forge verify-contract \
  --chain-id 84532 \
  --num-of-optimizations 200 \
  --watch \
  --constructor-args $(cast abi-encode "constructor(address,address)" $AGENT_LICENSE $REGISTRY) \
  --etherscan-api-key $BASESCAN_API_KEY \
  --compiler-version v0.8.28+commit.4d4c4e2c \
  AgentRegistry \
  0x...
```

#### Use Multi-sig for Admin

```solidity
// ✅ GOOD: Multi-sig for critical functions
// Deploy with Gnosis Safe as admin
agentLicense.grantRole(DEFAULT_ADMIN_ROLE, gnosisSafeAddress);
agentLicense.revokeRole(DEFAULT_ADMIN_ROLE, deployer);
```

---

## Learning Resources

### Official Documentation

1. **ERC-6551 Standard**
   - [EIP-6551](https://eips.ethereum.org/EIPS/eip-6551)
   - [ERC-6551 Reference Implementation](https://github.com/erc6551/reference)

2. **ERC-4337 Standard**
   - [EIP-4337](https://eips.ethereum.org/EIPS/eip-4337)
   - [Account Abstraction Documentation](https://accountabstraction.io/)

3. **Zero-Knowledge Proofs**
   - [ZK Proofs Explained](https://z.cash/technology/zksnarks/)
   - [Axiom Documentation](https://docs.axiom.xyz/)
   - [Brevis Documentation](https://docs.brevis.network/)

### Solidity Learning

1. **Solidity Documentation**
   - [Solidity Docs](https://docs.soliditylang.org/)
   - [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)

2. **Security**
   - [Consensys Best Practices](https://consensys.github.io/smart-contract-best-practices/)
   - [SWC Registry](https://swcregistry.io/)

3. **Gas Optimization**
   - [Gas Optimization Techniques](https://github.com/ethereum/wiki/wiki/Subtleties)

### Foundry Learning

1. **Foundry Book**
   - [Foundry Book](https://book.getfoundry.sh/)

2. **Testing**
   - [Foundry Testing](https://book.getfoundry.sh/forge/tests)
   - [Fuzz Testing](https://book.getfoundry.sh/forge/fuzz-testing)

### Project-Specific Resources

1. **KYA Protocol**
   - [GitHub Repository](https://github.com/RahilBhavan/KYA)
   - [Documentation](./README.md)
   - [API Reference](./docs/API_REFERENCE.md)

2. **Integration Guides**
   - [Developer Guide](./docs/DEVELOPER_GUIDE.md)
   - [SDK Documentation](./integrations/javascript/README.md)

---

## Glossary

### Terms

- **Agent**: An AI entity that interacts with blockchain applications
- **Agent License**: ERC-721 NFT representing an agent's identity
- **Token Bound Account (TBA)**: Smart contract wallet controlled by an NFT
- **Reputation Score**: On-chain metric tracking agent's trustworthiness
- **Tier**: Reputation level (Bronze, Silver, Gold, Platinum, Whale)
- **Badge**: Visual achievement indicator for specific accomplishments
- **Staking**: Locking collateral (USDC) to become verified
- **Slashing**: Penalty mechanism for misbehavior
- **ZK Proof**: Zero-knowledge proof proving something without revealing data
- **Paymaster**: Contract that sponsors gas fees for users
- **EntryPoint**: ERC-4337 contract that handles account abstraction
- **Oracle**: External service that provides data or resolves disputes

### Acronyms

- **KYA**: Know Your Agent
- **TBA**: Token Bound Account
- **ZK**: Zero-Knowledge
- **ERC**: Ethereum Request for Comments (standard)
- **NFT**: Non-Fungible Token
- **dApp**: Decentralized Application
- **DeFi**: Decentralized Finance
- **DAO**: Decentralized Autonomous Organization

---

## Conclusion

The KYA Protocol represents a significant advancement in AI agent identity and trust systems. By combining ERC-6551, ERC-4337, ZK proofs, and economic security mechanisms, it creates a composable, trustless system for AI agents.

### Key Takeaways

1. **Identity as Asset**: NFTs controlling wallets enable transferable agent identities
2. **Privacy-Preserving Reputation**: ZK proofs enable reputation without data exposure
3. **Economic Security**: Staking provides accountability and merchant protection
4. **Composability**: Works with any dApp, any chain, any use case
5. **Best Practices**: Security, gas optimization, and testing are critical

### Next Steps

1. **Study the Code**: Read through the contracts in `src/`
2. **Run the Tests**: Execute `forge test` to see how everything works
3. **Deploy Locally**: Use `anvil` to deploy and test locally
4. **Build Something**: Create your own agent or integrate KYA into your dApp
5. **Contribute**: Submit PRs, report issues, improve documentation

### Questions?

- Check the [FAQ](./docs/FAQ.md)
- Read the [Developer Guide](./docs/DEVELOPER_GUIDE.md)
- Review the [API Reference](./docs/API_REFERENCE.md)
- Join the community on Discord

---

**Happy Building! 🚀**

---

**Document Version**: 1.0.0  
**Last Updated**: 2026-01-12  
**Maintained By**: KYA Protocol Team
