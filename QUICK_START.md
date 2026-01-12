# Quick Start: Local Deployment

## 🚀 3-Step Local Deployment

### Step 1: Start Anvil

```bash
anvil
```

Keep this terminal open. Anvil runs on `http://localhost:8545`.

### Step 2: Set Private Key

In a **new terminal**:

```bash
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

This is the default Anvil account with 10,000 ETH.

### Step 3: Deploy

```bash
forge script script/DeployLocal.s.sol --rpc-url http://localhost:8545 --broadcast
```

That's it! All contracts are deployed. The script will output all addresses.

## 📝 Test the Deployment

### Quick Test Script

```bash
# Set addresses from deployment output
export AGENT_REGISTRY=<address_from_output>
export INSURANCE_VAULT=<address_from_output>
export MOCK_USDC=<address_from_output>
export REPUTATION_SCORE=<address_from_output>
export MERCHANT_SDK=<address_from_output>

# Run test
forge script script/TestLocal.s.sol --rpc-url http://localhost:8545 --broadcast
```

### Manual Testing

**1. Mint an Agent:**
```bash
cast send $AGENT_REGISTRY \
  "mintAgent(string,string,string)" \
  "MyAgent" "Description" "Trading" \
  --value 0.001ether \
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY
```

**2. Check Agent Info:**
```bash
cast call $AGENT_REGISTRY \
  "getAgentInfoByTokenId(uint256)" 1 \
  --rpc-url http://localhost:8545
```

**3. Get TBA Address:**
```bash
cast call $AGENT_REGISTRY \
  "computeTBAAddress(uint256)" 1 \
  --rpc-url http://localhost:8545
```

## 📚 Full Documentation

- **Local Deployment Guide**: [LOCAL_DEPLOYMENT.md](./LOCAL_DEPLOYMENT.md)
- **V2.0 Implementation**: [V2_IMPLEMENTATION.md](./V2_IMPLEMENTATION.md)
- **Main README**: [README.md](./README.md)

## 🔧 Troubleshooting

**Problem**: `ERC6551Registry not found`
- **Solution**: Use a fork: `anvil --fork-url <RPC_URL>`

**Problem**: `insufficient funds`
- **Solution**: Anvil accounts have 10,000 ETH. If needed, restart with `anvil --balance 100000`

**Problem**: Contracts fail to deploy
- **Solution**: 
  1. Make sure Anvil is running
  2. Check RPC URL: `http://localhost:8545`
  3. Verify dependencies: `forge install`

## 💡 Pro Tips

1. **Save addresses**: The deployment script saves addresses to `deployments/local-<timestamp>.md`

2. **Use environment variables**: Create `.env.local`:
   ```bash
   PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
   RPC_URL=http://localhost:8545
   AGENT_REGISTRY=<address>
   # ... etc
   ```

3. **Fork for realistic testing**: 
   ```bash
   anvil --fork-url https://base-sepolia.g.alchemy.com/v2/YOUR_KEY
   ```

4. **View contracts in explorer**: Use [Foundry Book's Anvil section](https://book.getfoundry.sh/anvil/) for debugging

## 🎯 Next Steps

1. ✅ Deploy locally
2. ✅ Test minting
3. ⏭️ Write unit tests
4. ⏭️ Test staking flow
5. ⏭️ Test reputation system
6. ⏭️ Deploy to testnet

