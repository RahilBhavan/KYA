# KYA Protocol - User Guide

**Purpose**: Guide for users (agent operators) to get started with KYA Protocol.

---

## What is KYA Protocol?

KYA Protocol is a decentralized underwriting protocol for AI Agent identities. It allows AI agents to:

- **Build Reputation**: Prove your on-chain history privately using ZK proofs
- **Get Verified**: Stake USDC to become a verified agent
- **Access Services**: Merchants can trust verified agents with economic recourse
- **Transfer Identity**: Your agent identity is an NFT that you can transfer or sell

---

## Getting Started

### Prerequisites

- **Web3 Wallet**: MetaMask, Coinbase Wallet, or similar
- **Base Network**: Add Base Sepolia (testnet) or Base (mainnet) to your wallet
- **USDC**: For staking (testnet: get from faucet, mainnet: purchase)

### Step 1: Connect Your Wallet

1. Open the KYA Protocol dApp (or use the SDK)
2. Click "Connect Wallet"
3. Select your wallet
4. Approve connection
5. Switch to Base network

### Step 2: Create Your Agent

1. Click "Create Agent"
2. Fill in agent details:
   - **Name**: Your agent's name
   - **Description**: What your agent does
   - **Category**: Trading, Lending, etc.
3. Pay minting fee (~$10)
4. Confirm transaction

**What Happens**:
- An ERC-721 NFT is minted (your Agent License)
- A Token Bound Account (TBA) is created (your agent's wallet)
- Your agent is now registered

### Step 3: Fund Your Agent

1. Get your agent's TBA address
2. Send USDC to the TBA address
3. Verify balance

**Note**: Your agent's TBA is a smart contract wallet that you control via the NFT.

### Step 4: Stake to Get Verified

1. Navigate to "Staking"
2. Enter stake amount (minimum: 1000 USDC)
3. Approve USDC spending
4. Confirm stake transaction

**What Happens**:
- USDC is staked in InsuranceVault
- Your agent becomes "Verified"
- Merchants can now trust your agent

**Benefits of Verification**:
- Merchants accept your agent
- Access to premium services
- Higher trust score

### Step 5: Build Reputation

1. Navigate to "Reputation"
2. Click "Prove History"
3. Select proof type (e.g., "Uniswap Volume")
4. Generate ZK proof (via Axiom/Brevis)
5. Submit proof

**What Happens**:
- ZK proof verifies your on-chain history
- Your reputation score increases
- You may earn badges
- Your tier may upgrade

**Reputation Tiers**:
- **None** (0-99): New agent
- **Bronze** (100-499): Established agent
- **Silver** (500-1,999): Trusted agent
- **Gold** (2,000-9,999): Premium agent
- **Platinum** (10,000-49,999): Elite agent
- **Whale** (50,000+): Top tier agent

---

## Using Your Agent

### Making Transactions

Your agent's TBA can:
- Execute transactions
- Interact with DeFi protocols
- Sign messages
- Manage assets

**How to Use**:
- Transactions are executed via the TBA
- You sign with your wallet (NFT owner)
- TBA executes on your behalf

### Transferring Your Agent

Your agent identity is an NFT, so you can:
- **Transfer**: Send NFT to another address
- **Sell**: List on NFT marketplaces
- **Gift**: Transfer to another user

**What Transfers**:
- NFT ownership
- TBA control
- Reputation score
- Badges
- Staked amount (stays in vault)

---

## Staking & Unstaking

### Staking

**Minimum Stake**: 1000 USDC

**Process**:
1. Approve USDC spending
2. Stake amount
3. Become verified

**Benefits**:
- Verified status
- Merchant trust
- Economic security

### Unstaking

**Cooldown Period**: 7 days (for verified agents)

**Process**:
1. Request unstake
2. Wait for cooldown (if verified)
3. Unstake amount
4. Receive USDC

**Note**: Unstaking removes verified status if below minimum.

---

## Reputation & Badges

### Building Reputation

**Ways to Increase Score**:
- Verify ZK proofs (Uniswap volume, Aave activity, etc.)
- Maintain verified status
- Avoid claims/slashing

**Proof Types**:
- Uniswap Volume
- Uniswap Trades
- Aave Borrower
- Aave Lender
- Chainlink User

### Badges

**Available Badges**:
- **Uniswap Trader**: Verified Uniswap activity
- **Aave Borrower**: Borrowed from Aave
- **Aave Lender**: Lent to Aave
- **Chainlink User**: Used Chainlink oracles

**How to Earn**:
- Verify relevant ZK proofs
- Meet badge requirements
- Badges are automatically awarded

---

## Troubleshooting

### Common Issues

#### "Insufficient Balance"
**Solution**: Fund your agent's TBA with USDC

#### "Stake Below Minimum"
**Solution**: Stake at least 1000 USDC

#### "Cooldown Active"
**Solution**: Wait 7 days after becoming verified

#### "Proof Generation Failed"
**Solution**: 
- Check Axiom/Brevis service status
- Verify agent address
- Try again later

#### "Transaction Failed"
**Solution**:
- Check gas price
- Ensure sufficient ETH for gas
- Verify network (Base Sepolia/Mainnet)

---

## Best Practices

1. **Start Small**: Test on testnet first
2. **Build Reputation**: Verify proofs to increase score
3. **Maintain Stake**: Keep verified status
4. **Monitor Activity**: Watch for claims
5. **Stay Updated**: Follow protocol updates

---

## Support

### Resources

- **Documentation**: `docs/`
- **FAQ**: See below
- **Discord**: [To be added]
- **GitHub**: [Repository URL]

### Getting Help

- Check FAQ
- Review documentation
- Ask in Discord
- Open GitHub issue

---

## FAQ

### Q: What is a Token Bound Account (TBA)?

**A**: A TBA is a smart contract wallet controlled by your NFT. It allows your agent to hold assets and execute transactions.

### Q: Can I unstake immediately?

**A**: If you're verified, you must wait 7 days. If not verified, you can unstake immediately.

### Q: What happens if I get slashed?

**A**: Your staked USDC is slashed and paid to the merchant. You lose verified status.

### Q: Can I transfer my agent?

**A**: Yes! Your agent is an NFT. Transfer the NFT to transfer everything (reputation, TBA, etc.).

### Q: How do I increase my reputation?

**A**: Verify ZK proofs of your on-chain activity (Uniswap, Aave, etc.).

### Q: What are badges?

**A**: Badges show your agent's achievements and capabilities. They're earned by verifying specific proof types.

---

**Last Updated**: 2026-01-06

