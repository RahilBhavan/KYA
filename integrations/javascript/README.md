# @kya-protocol/integrations

JavaScript/TypeScript SDK for integrating KYA Protocol with external services (Axiom, Brevis, UMA, Kleros, ERC-4337).

## Installation

```bash
npm install @kya-protocol/integrations
# or
yarn add @kya-protocol/integrations
```

## Quick Start

```typescript
import { AxiomClient, UMAClient, loadConfig } from '@kya-protocol/integrations';

// Load configuration from environment
const config = loadConfig();

// Initialize clients
const axiom = new AxiomClient(config.axiom!);
const uma = new UMAClient(config.uma!);

// Generate ZK proof
const proof = await axiom.generateProof({
  agentAddress: '0x...',
  proofType: 'UniswapVolume',
  queryData: { minVolume: 10000 }
});

// Submit claim to UMA
const requestId = await uma.submitClaim({
  claimId: '0x...',
  tokenId: 1,
  merchant: '0x...',
  amount: '1000000',
  reason: 'Malicious behavior'
});
```

## Features

- **ZK Proof Generation**: Axiom and Brevis integration
- **Oracle Resolution**: UMA and Kleros integration
- **ERC-4337 Support**: EntryPoint and Paymaster integration
- **Error Handling**: Retry logic and custom error classes
- **TypeScript**: Full type definitions

## Configuration

Set environment variables:

```bash
# ZK Coprocessors
AXIOM_API_KEY=your_axiom_api_key
BREVIS_API_KEY=your_brevis_api_key

# Oracles
UMA_API_KEY=your_uma_api_key
KLEROS_API_KEY=your_kleros_api_key

# Network
NETWORK=base-sepolia
RPC_URL=https://sepolia.base.org
ENTRY_POINT_ADDRESS=0x0000000071727De22E5E9d8BAf0edAc6f37da032
```

## Usage Examples

See `examples/basic-usage.ts` for complete examples.

### Axiom Integration

```typescript
import { AxiomClient, loadConfig } from '@kya-protocol/integrations';

const config = loadConfig();
const axiom = new AxiomClient(config.axiom!);

const proof = await axiom.generateProof({
  agentAddress: tbaAddress,
  proofType: 'UniswapVolume',
  queryData: {
    contract: 'UniswapV3Router',
    minVolume: 10000
  },
  startBlock: 10000000,
  endBlock: 11000000
});
```

### UMA Integration

```typescript
import { UMAClient, loadConfig } from '@kya-protocol/integrations';

const config = loadConfig();
const uma = new UMAClient(config.uma!);

// Submit claim
const requestId = await uma.submitClaim({
  claimId: '0x...',
  tokenId: 1,
  merchant: merchantAddress,
  amount: '1000000',
  reason: 'Malicious behavior',
  evidence: evidenceData
});

// Poll for resolution
const resolution = await uma.pollForResolution(requestId);
```

### Error Handling

```typescript
import { AxiomClient, AxiomError, retry } from '@kya-protocol/integrations';

try {
  const proof = await retry(
    () => axiom.generateProof(query),
    {
      maxAttempts: 5,
      delay: 2000,
      backoff: 'exponential'
    }
  );
} catch (error) {
  if (error instanceof AxiomError) {
    console.error('Axiom error:', error.message);
    console.error('Code:', error.code);
  }
}
```

## API Reference

### AxiomClient

- `generateProof(query: ProofQuery): Promise<ProofResult>`
- `getProofStatus(queryId: string): Promise<ProofResult>`

### BrevisClient

- `generateProof(query: ProofQuery): Promise<ProofResult>`
- `getProofStatus(queryId: string): Promise<ProofResult>`

### UMAClient

- `submitClaim(claimData: ClaimData): Promise<string>`
- `getClaimStatus(requestId: string): Promise<ResolutionResult>`
- `pollForResolution(requestId: string): Promise<ResolutionResult>`
- `challengeClaim(requestId: string, challenger: string, evidence: any): Promise<string>`

### KlerosClient

- `submitClaim(claimData: ClaimData): Promise<string>`
- `getClaimStatus(disputeId: string): Promise<ResolutionResult>`
- `pollForResolution(disputeId: string): Promise<ResolutionResult>`
- `appealDispute(disputeId: string, appellant: string, evidence: any): Promise<string>`

### EntryPointClient

- `createUserOperation(params): UserOperation`
- `submitUserOperation(userOp: UserOperation, bundlerUrl?: string): Promise<string>`
- `getUserOpHash(userOp: UserOperation): Promise<string>`
- `getNonce(sender: string, key?: number): Promise<number>`

## Error Handling

All clients use retry logic with exponential backoff. Custom error classes provide detailed error information:

- `KYASDKError`: Base error class
- `AxiomError`: Axiom-specific errors
- `BrevisError`: Brevis-specific errors
- `UMAError`: UMA-specific errors
- `KlerosError`: Kleros-specific errors
- `EntryPointError`: EntryPoint-specific errors

## Retry Logic

The SDK includes automatic retry logic:

```typescript
import { retry } from '@kya-protocol/integrations';

const result = await retry(
  () => apiCall(),
  {
    maxAttempts: 3,
    delay: 1000,
    backoff: 'exponential', // or 'linear'
    retryableErrors: ['ECONNRESET', 'ETIMEDOUT']
  }
);
```

## Development

```bash
# Install dependencies
npm install

# Build
npm run build

# Test
npm test

# Lint
npm run lint
```

## Status

✅ **Production Ready**: SDK is ready for production use with real service integrations.

## License

MIT

---

**Last Updated**: 2026-01-06
