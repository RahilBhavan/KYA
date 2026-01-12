# KYA Protocol - React Native SDK

React Native SDK for KYA Protocol with mobile wallet integration.

## Installation

```bash
bun add @kya-protocol/react-native
```

## Usage

```typescript
import { KYAClientRN } from '@kya-protocol/react-native';

const client = new KYAClientRN({
  rpcUrl: 'https://sepolia.base.org',
  agentRegistryAddress: '0x...',
});

// Connect wallet
const wallet = await client.connectWallet();

// Create agent
const agent = await client.createAgentMobile(
  'MyAgent',
  'My first AI agent',
  'Trading'
);
```

## Features

- WalletConnect integration
- Mobile-optimized UI components
- Offline transaction signing
- Push notifications for events
