# Integration Guides

## Overview

This guide covers integrating with external services: Axiom/Brevis (ZK proofs), UMA/Kleros (oracles), and ERC-4337 EntryPoint.

## Axiom/Brevis Integration

### Overview

Axiom and Brevis are ZK coprocessors that generate proofs of historical on-chain data. The KYA Protocol uses these proofs to verify agent reputation without revealing transaction details.

### Setup

#### 1. Get API Access

- **Axiom**: Sign up at [axiom.xyz](https://axiom.xyz)
- **Brevis**: Sign up at [brevis.network](https://brevis.network)

#### 2. Configure ReputationScore

```solidity
// Grant ZK_PROVER_ROLE to Axiom/Brevis address
reputationScore.grantRole(
    reputationScore.ZK_PROVER_ROLE(),
    axiomAddress // or brevisAddress
);
```

#### 3. Generate Proof

```javascript
// Example: Generate proof for Uniswap volume
const query = {
  blockNumber: latestBlock,
  address: agentTBAAddress,
  contract: "UniswapV3Router",
  function: "exactInputSingle",
  minVolume: 10000 // $10,000
};

const proof = await axiom.generateProof(query);
```

#### 4. Verify Proof On-Chain

```solidity
// Axiom/Brevis calls this function
reputationScore.verifyProof(
    tokenId,
    "UniswapVolume",
    proof,
    "Uniswap volume: $10000"
);
```

### Proof Types

Supported proof types:
- `UniswapVolume`: Uniswap trading volume
- `UniswapTrades`: Number of Uniswap trades
- `AaveBorrower`: Aave borrowing history
- `AaveLender`: Aave lending history
- `ChainlinkUser`: Chainlink oracle usage

### Adding New Proof Types

```solidity
// Set proof type score
reputationScore.setProofTypeScore("NewProofType", 100);

// Optionally add badge
reputationScore.setProofTypeBadge("NewProofType", "New Badge");
```

### Testing

See `test/integration/ZKProofIntegration.t.sol` for integration test examples.

## UMA/Kleros Integration

### Overview

UMA and Kleros provide oracle services for dispute resolution. The KYA Protocol uses these oracles to resolve claims when merchants report agent violations.

### Setup

#### 1. Get Oracle Access

- **UMA**: Sign up at [umaproject.org](https://umaproject.org)
- **Kleros**: Sign up at [kleros.io](https://kleros.io)

#### 2. Configure InsuranceVault

```solidity
// Grant ORACLE_ROLE to UMA/Kleros address
insuranceVault.grantRole(
    insuranceVault.ORACLE_ROLE(),
    umaAddress // or klerosAddress
);
```

#### 3. Submit Claim

```solidity
// Merchant submits claim
bytes32 claimId = insuranceVault.submitClaim(
    tokenId,
    claimAmount,
    "Malicious behavior: exceeded rate limit"
);
```

#### 4. Oracle Resolution

```solidity
// UMA/Kleros validates claim off-chain, then calls:
insuranceVault.resolveClaim(claimId, true); // or false
```

### Claim Flow

1. **Merchant submits claim** via `InsuranceVault.submitClaim()`
2. **24-hour challenge period** - Agent can challenge
3. **Oracle validation** - UMA/Kleros validates off-chain
4. **Resolution** - Oracle calls `resolveClaim()` with decision
5. **Slashing** - If approved, agent's stake is slashed

### Challenge Flow

If agent challenges:

1. Agent calls `challengeClaim()` within 24 hours
2. Claim status changes to "Challenged"
3. Escalates to human arbitration (Kleros court)
4. Final resolution via `resolveClaim()`

### Testing

See `test/integration/OracleIntegration.t.sol` for integration test examples.

## ERC-4337 EntryPoint Integration

### Overview

ERC-4337 enables account abstraction. The KYA Paymaster sponsors gas for new agents during their cold start period (first 7 days, first 50 transactions).

### Setup

#### 1. EntryPoint Address

Base Sepolia: `0x0000000071727De22E5E9d8BAf0edAc6f37da032`
Base Mainnet: `0x0000000071727De22E5E9d8BAf0edAc6f37da032`

#### 2. Deploy Paymaster

The Paymaster is deployed with EntryPoint address in constructor.

#### 3. Fund Paymaster

```solidity
// Deposit ETH to Paymaster for gas sponsorship
paymaster.deposit{value: 10 ether}();
```

#### 4. User Operation Flow

```javascript
// Create user operation
const userOp = {
  sender: agentTBAAddress,
  nonce: await entryPoint.getNonce(agentTBAAddress, 0),
  callData: encodeFunctionData(...),
  // ... other fields
};

// Add paymaster data
const paymasterData = {
  tokenId: agentTokenId,
  userOp: userOp,
  maxCost: 0.01 ether
};

// Submit to EntryPoint
await entryPoint.handleOps([userOp], beneficiary);
```

### Eligibility

Agents are eligible for gas sponsorship if:
- Agent created < 7 days ago
- Twitter verified
- < 50 sponsored transactions

### Testing

See `test/integration/PaymasterIntegration.t.sol` for integration test examples.

## Configuration Examples

### Axiom Configuration

```javascript
const axiomConfig = {
  apiKey: process.env.AXIOM_API_KEY,
  network: "base-sepolia",
  proofTypes: [
    "UniswapVolume",
    "AaveBorrower",
    "ChainlinkUser"
  ]
};
```

### UMA Configuration

```javascript
const umaConfig = {
  apiKey: process.env.UMA_API_KEY,
  network: "base-sepolia",
  oracleAddress: "0x...",
  challengePeriod: 24 * 60 * 60 // 24 hours
};
```

### EntryPoint Configuration

```javascript
const entryPointConfig = {
  address: "0x0000000071727De22E5E9d8BAf0edAc6f37da032",
  network: "base-sepolia",
  paymasterAddress: paymasterAddress
};
```

## Best Practices

### Security

1. **Verify Oracle Addresses**: Always verify oracle addresses before granting roles
2. **Monitor Oracle Calls**: Set up monitoring for oracle resolutions
3. **Rate Limiting**: Implement rate limiting for proof verification
4. **Access Control**: Only grant roles to trusted addresses

### Performance

1. **Batch Operations**: Batch multiple proofs when possible
2. **Caching**: Cache proof results to avoid redundant verification
3. **Async Processing**: Process proofs asynchronously when possible

### Error Handling

1. **Graceful Degradation**: Handle oracle failures gracefully
2. **Retry Logic**: Implement retry logic for failed proofs
3. **Fallback Mechanisms**: Use fallback mechanisms when oracles unavailable

## Troubleshooting

### Axiom/Brevis Issues

- **Proof Generation Fails**: Check API key, network, and query format
- **Verification Fails**: Verify proof format and on-chain verification logic
- **Rate Limits**: Implement rate limiting and retry logic

### UMA/Kleros Issues

- **Oracle Not Responding**: Check oracle address and network connectivity
- **Resolution Delays**: Monitor challenge periods and escalation
- **Dispute Resolution**: Follow dispute resolution process

### EntryPoint Issues

- **Gas Sponsorship Fails**: Check eligibility and paymaster balance
- **UserOp Rejected**: Verify user operation format and validation
- **EntryPoint Errors**: Check EntryPoint address and network

## Support

For integration issues:
- Check integration test examples
- Review service documentation
- Contact service support teams
- Consult development team

