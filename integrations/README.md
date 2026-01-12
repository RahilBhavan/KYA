# External Integrations

This directory contains integration helpers and SDK code for connecting KYA Protocol with external services.

## Structure

```
integrations/
├── javascript/          # JavaScript/TypeScript SDK
│   ├── axiom/          # Axiom integration
│   ├── brevis/         # Brevis integration
│   ├── uma/            # UMA integration
│   ├── kleros/         # Kleros integration
│   └── entrypoint/     # ERC-4337 EntryPoint integration
└── python/             # Python SDK (optional)
```

## JavaScript SDK

### Installation

```bash
npm install @kya-protocol/integrations
```

### Usage

#### Axiom Integration

```javascript
import { AxiomClient } from '@kya-protocol/integrations/axiom';

const axiom = new AxiomClient({
  apiKey: process.env.AXIOM_API_KEY,
  network: 'base-sepolia'
});

// Generate proof for Uniswap volume
const proof = await axiom.generateProof({
  agentAddress: tbaAddress,
  proofType: 'UniswapVolume',
  query: {
    contract: 'UniswapV3Router',
    minVolume: 10000
  }
});

// Submit to ReputationScore
await reputationScore.verifyProof(
  tokenId,
  'UniswapVolume',
  proof.data,
  proof.metadata
);
```

#### UMA Integration

```javascript
import { UMAClient } from '@kya-protocol/integrations/uma';

const uma = new UMAClient({
  apiKey: process.env.UMA_API_KEY,
  network: 'base-sepolia'
});

// Submit claim
const claimId = await insuranceVault.submitClaim(
  tokenId,
  amount,
  'Malicious behavior detected'
);

// Submit to UMA
await uma.submitClaim({
  claimId,
  tokenId,
  merchant: merchantAddress,
  amount,
  reason: 'Malicious behavior',
  evidence: evidenceData
});
```

## Python SDK (Optional)

```python
from kya_integrations import AxiomClient, UMAClient

axiom = AxiomClient(api_key=os.getenv('AXIOM_API_KEY'))
proof = axiom.generate_proof(...)
```

## Configuration

Create `.env` file:

```bash
# Axiom
AXIOM_API_KEY=your_axiom_api_key
AXIOM_ADDRESS=0x...

# Brevis
BREVIS_API_KEY=your_brevis_api_key
BREVIS_ADDRESS=0x...

# UMA
UMA_API_KEY=your_uma_api_key
UMA_ADDRESS=0x...

# Kleros
KLEROS_API_KEY=your_kleros_api_key
KLEROS_ADDRESS=0x...

# EntryPoint
ENTRY_POINT_ADDRESS=0x0000000071727De22E5E9d8BAf0edAc6f37da032
```

## Smart Contract Adapters

The protocol includes on-chain adapter contracts:

- `ZKAdapter.sol`: Bridge for ZK coprocessors
- `OracleAdapter.sol`: Bridge for oracles

These adapters can be deployed and configured via `script/SetupIntegrations.s.sol`.

