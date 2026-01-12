# External Integrations Setup Guide

**Purpose**: Guide for setting up and testing real integrations with Axiom/Brevis, UMA/Kleros, and ERC-4337 EntryPoint.

---

## Overview

The KYA Protocol integrates with external services for:
1. **ZK Coprocessors** (Axiom/Brevis) - Private reputation verification
2. **Oracles** (UMA/Kleros) - Claim dispute resolution
3. **ERC-4337 EntryPoint** - Account abstraction and gas sponsorship

---

## ZK Coprocessor Integration

### Axiom Integration

#### 1. Sign Up for Axiom Testnet

1. Visit: https://axiom.xyz
2. Sign up for testnet access
3. Get API keys from dashboard
4. Note your testnet credentials

#### 2. Configure Environment

Add to `.env`:
```bash
AXIOM_API_KEY=your_axiom_api_key
AXIOM_TESTNET_URL=https://testnet.axiom.xyz
AXIOM_CHAIN_ID=84532  # Base Sepolia
```

#### 3. Implement Real API Calls

Update `integrations/javascript/axiom/client.ts`:

```typescript
import axios from 'axios';

export class AxiomClient {
  private apiKey: string;
  private baseUrl: string;
  private chainId: number;

  constructor(config: {
    apiKey: string;
    baseUrl?: string;
    chainId?: number;
  }) {
    this.apiKey = config.apiKey;
    this.baseUrl = config.baseUrl || 'https://testnet.axiom.xyz';
    this.chainId = config.chainId || 84532;
  }

  async generateProof(query: {
    agentAddress: string;
    proofType: string;
    query: {
      contract: string;
      minVolume?: number;
      minTrades?: number;
    };
  }): Promise<{
    proof: string;
    data: string;
    metadata: string;
  }> {
    const response = await axios.post(
      `${this.baseUrl}/api/v1/proofs/generate`,
      {
        chainId: this.chainId,
        address: query.agentAddress,
        proofType: query.proofType,
        query: query.query,
      },
      {
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
        },
      }
    );

    return {
      proof: response.data.proof,
      data: response.data.data,
      metadata: response.data.metadata,
    };
  }

  async verifyProof(proof: string): Promise<boolean> {
    const response = await axios.post(
      `${this.baseUrl}/api/v1/proofs/verify`,
      {
        proof,
        chainId: this.chainId,
      },
      {
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
        },
      }
    );

    return response.data.verified;
  }
}
```

#### 4. Test Integration

```typescript
import { AxiomClient } from './integrations/javascript/axiom/client';

const axiom = new AxiomClient({
  apiKey: process.env.AXIOM_API_KEY!,
  chainId: 84532, // Base Sepolia
});

// Generate proof for Uniswap volume
const proof = await axiom.generateProof({
  agentAddress: tbaAddress,
  proofType: 'UniswapVolume',
  query: {
    contract: 'UniswapV3Router',
    minVolume: 10000,
  },
});

// Submit to ReputationScore via ZKAdapter
await reputationScore.verifyProof(
  tokenId,
  'UniswapVolume',
  proof.data,
  proof.metadata
);
```

### Brevis Integration

#### 1. Sign Up for Brevis Testnet

1. Visit: https://brevis.network
2. Sign up for testnet access
3. Get API keys from dashboard
4. Note your testnet credentials

#### 2. Configure Environment

Add to `.env`:
```bash
BREVIS_API_KEY=your_brevis_api_key
BREVIS_TESTNET_URL=https://testnet.brevis.network
BREVIS_CHAIN_ID=84532  # Base Sepolia
```

#### 3. Implement Real API Calls

Similar structure to Axiom client. Update `integrations/javascript/brevis/client.ts` with Brevis-specific API endpoints.

---

## Oracle Integration

### UMA Integration

#### 1. Sign Up for UMA Testnet

1. Visit: https://umaproject.org
2. Sign up for testnet access
3. Get oracle contract addresses for Base Sepolia
4. Note your credentials

#### 2. Configure Environment

Add to `.env`:
```bash
UMA_API_KEY=your_uma_api_key
UMA_ORACLE_ADDRESS=0x...  # Base Sepolia oracle address
UMA_CHAIN_ID=84532
```

#### 3. Implement Real API Calls

Update `integrations/javascript/uma/client.ts`:

```typescript
import axios from 'axios';
import { ethers } from 'ethers';

export class UMAClient {
  private apiKey: string;
  private oracleAddress: string;
  private chainId: number;
  private provider: ethers.Provider;

  constructor(config: {
    apiKey: string;
    oracleAddress: string;
    chainId?: number;
    provider: ethers.Provider;
  }) {
    this.apiKey = config.apiKey;
    this.oracleAddress = config.oracleAddress;
    this.chainId = config.chainId || 84532;
    this.provider = config.provider;
  }

  async submitClaim(claim: {
    claimId: string;
    tokenId: number;
    merchant: string;
    amount: string;
    reason: string;
    evidence: any;
  }): Promise<string> {
    // Submit to UMA API
    const response = await axios.post(
      'https://api.umaproject.org/v1/claims',
      {
        chainId: this.chainId,
        claimId: claim.claimId,
        tokenId: claim.tokenId,
        merchant: claim.merchant,
        amount: claim.amount,
        reason: claim.reason,
        evidence: claim.evidence,
      },
      {
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
        },
      }
    );

    return response.data.requestId;
  }

  async resolveClaim(requestId: string): Promise<{
    resolved: boolean;
    result: boolean;
  }> {
    const response = await axios.get(
      `https://api.umaproject.org/v1/claims/${requestId}`,
      {
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
        },
      }
    );

    return {
      resolved: response.data.resolved,
      result: response.data.result,
    };
  }
}
```

#### 4. Test Integration

```typescript
import { UMAClient } from './integrations/javascript/uma/client';

const uma = new UMAClient({
  apiKey: process.env.UMA_API_KEY!,
  oracleAddress: process.env.UMA_ORACLE_ADDRESS!,
  provider: provider,
});

// Submit claim
const claimId = await insuranceVault.submitClaim(
  tokenId,
  amount,
  'Malicious behavior detected'
);

// Submit to UMA
const requestId = await uma.submitClaim({
  claimId,
  tokenId,
  merchant: merchantAddress,
  amount: amount.toString(),
  reason: 'Malicious behavior',
  evidence: evidenceData,
});

// Wait for resolution
const resolution = await uma.resolveClaim(requestId);

// Resolve on-chain via OracleAdapter
if (resolution.resolved) {
  await insuranceVault.resolveClaim(claimId, resolution.result);
}
```

### Kleros Integration

#### 1. Sign Up for Kleros Testnet

1. Visit: https://kleros.io
2. Sign up for testnet access
3. Get arbitration contract addresses
4. Note your credentials

#### 2. Configure Environment

Add to `.env`:
```bash
KLEROS_API_KEY=your_kleros_api_key
KLEROS_ARBITRATOR_ADDRESS=0x...  # Base Sepolia arbitrator
KLEROS_CHAIN_ID=84532
```

#### 3. Implement Real API Calls

Similar structure to UMA client. Update `integrations/javascript/kleros/client.ts` with Kleros-specific API endpoints.

---

## ERC-4337 EntryPoint Integration

### EntryPoint Configuration

#### 1. Verify EntryPoint Address

Base Sepolia EntryPoint: `0x0000000071727De22E5E9d8BAf0edAc6f37da032`

Verify on BaseScan:
```bash
# Check EntryPoint on BaseScan
https://sepolia.basescan.org/address/0x0000000071727De22E5E9d8BAf0edAc6f37da032
```

#### 2. Configure Paymaster

The Paymaster is already configured with EntryPoint address in deployment script.

#### 3. Test User Operations

Update `integrations/javascript/entrypoint/client.ts`:

```typescript
import { ethers } from 'ethers';
import { UserOperation } from '@account-abstraction/sdk';

export class EntryPointClient {
  private entryPointAddress: string;
  private provider: ethers.Provider;
  private signer: ethers.Signer;

  constructor(config: {
    entryPointAddress: string;
    provider: ethers.Provider;
    signer: ethers.Signer;
  }) {
    this.entryPointAddress = config.entryPointAddress;
    this.provider = config.provider;
    this.signer = config.signer;
  }

  async createUserOperation(op: {
    sender: string;
    nonce: bigint;
    callData: string;
    callGasLimit: bigint;
    verificationGasLimit: bigint;
    preVerificationGas: bigint;
    maxFeePerGas: bigint;
    maxPriorityFeePerGas: bigint;
    paymasterAndData: string;
  }): Promise<UserOperation> {
    // Create user operation
    const userOp: UserOperation = {
      sender: op.sender,
      nonce: op.nonce,
      callData: op.callData,
      callGasLimit: op.callGasLimit,
      verificationGasLimit: op.verificationGasLimit,
      preVerificationGas: op.preVerificationGas,
      maxFeePerGas: op.maxFeePerGas,
      maxPriorityFeePerGas: op.maxPriorityFeePerGas,
      paymasterAndData: op.paymasterAndData,
      signature: '0x', // Will be signed
    };

    // Sign user operation
    const hash = await this.getUserOpHash(userOp);
    userOp.signature = await this.signer.signMessage(ethers.getBytes(hash));

    return userOp;
  }

  async getUserOpHash(userOp: UserOperation): Promise<string> {
    // Get user operation hash from EntryPoint
    const entryPoint = new ethers.Contract(
      this.entryPointAddress,
      ['function getUserOpHash(UserOperation calldata) view returns (bytes32)'],
      this.provider
    );

    return await entryPoint.getUserOpHash(userOp);
  }

  async submitUserOperation(userOp: UserOperation): Promise<string> {
    // Submit to bundler (e.g., via Pimlico, Alchemy, etc.)
    // This is a placeholder - use actual bundler API
    const response = await fetch('https://bundler.example.com/rpc', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        jsonrpc: '2.0',
        id: 1,
        method: 'eth_sendUserOperation',
        params: [userOp, this.entryPointAddress],
      }),
    });

    const data = await response.json();
    return data.result;
  }
}
```

---

## Integration Testing

### Update Integration Tests

Update `test/integration/ZKProofIntegration.t.sol` to use real adapters:

```solidity
function test_axiom_realIntegration() public {
    // This test requires:
    // 1. Axiom testnet access
    // 2. ZKAdapter deployed
    // 3. ZK_PROVER_ROLE granted to Axiom address
    
    // Generate proof via Axiom (off-chain)
    // Then verify on-chain via ZKAdapter
    bytes memory axiomProof = abi.encode("real-axiom-proof");
    
    vm.prank(axiomAddress); // Axiom address with ZK_PROVER_ROLE
    reputationScore.verifyProof(
        tokenId,
        TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
        axiomProof,
        "Real Axiom proof"
    );
    
    // Verify reputation updated
    IReputationScore.ReputationData memory rep = reputationScore.getReputation(tokenId);
    assertGt(rep.score, 0, "Reputation should increase");
}
```

### Test Checklist

- [ ] Axiom testnet account created
- [ ] Brevis testnet account created
- [ ] UMA testnet account created
- [ ] Kleros testnet account created
- [ ] API keys configured
- [ ] Real API calls implemented
- [ ] Integration tests updated
- [ ] End-to-end flow tested

---

## Troubleshooting

### API Key Issues

**Issue**: Invalid API key

**Solution**: 
- Verify API key is correct
- Check API key has testnet access
- Ensure API key is not expired

### Network Issues

**Issue**: Cannot connect to service

**Solution**:
- Verify network configuration
- Check chain ID matches
- Ensure testnet is accessible

### Integration Failures

**Issue**: Integration not working

**Solution**:
- Check adapter contracts deployed
- Verify roles granted
- Test with mock data first
- Review error messages

---

## Next Steps

1. Set up testnet accounts
2. Configure API keys
3. Implement real API calls
4. Test integrations
5. Update documentation
6. Proceed to security audit

---

**Last Updated**: 2026-01-06

