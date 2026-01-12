# KYA Protocol - The Graph Subgraph

This subgraph indexes KYA Protocol events for analytics and querying.

## Setup

1. Install dependencies:
```bash
bun install
```

2. Generate ABIs (contract artifacts):
```bash
# Copy contract ABIs from build artifacts
cp ../out/AgentRegistry.sol/AgentRegistry.json abis/
cp ../out/ReputationScore.sol/ReputationScore.json abis/
cp ../out/InsuranceVault.sol/InsuranceVault.json abis/
# ... etc
```

3. Update `subgraph.yaml` with contract addresses:
```yaml
address: "0x..." # Replace {{AGENT_REGISTRY_ADDRESS}} etc.
startBlock: 12345678 # Replace {{START_BLOCK}}
```

4. Generate code:
```bash
bun run codegen
```

5. Build:
```bash
bun run build
```

## Deployment

### Local (for testing)

```bash
# Start local graph node
docker-compose up

# Create subgraph
bun run create:local

# Deploy
bun run deploy:local
```

### The Graph Hosted Service

```bash
bun run deploy
```

## Query Examples

```graphql
# Get all agents
{
  agents {
    id
    tokenId
    tbaAddress
    owner
    reputation {
      score
      tier
      badges {
        name
      }
    }
  }
}

# Get agent by tokenId
{
  agent(id: "1") {
    reputation {
      score
      categoryScores {
        category
        score
      }
    }
    stakes {
      amount
      isVerified
    }
  }
}

# Get protocol stats
{
  protocolStats(id: "global") {
    totalAgents
    totalStaked
    totalReputationScore
    totalVerifiedAgents
  }
}
```

## Schema

See `schema.graphql` for the complete data model.

## Development

- Event handlers: `src/*.ts`
- Schema: `schema.graphql`
- Configuration: `subgraph.yaml`
