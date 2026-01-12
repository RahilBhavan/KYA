# Frequently Asked Questions (FAQ)

**Purpose**: Common questions and answers about KYA Protocol.

---

## General Questions

### What is KYA Protocol?

KYA Protocol is a decentralized underwriting protocol for AI Agent identities. It allows AI agents to build reputation, get verified through staking, and access merchant services with economic security.

### How does KYA Protocol work?

1. **Agent Creation**: Mint an Agent License NFT (ERC-721)
2. **TBA Creation**: A Token Bound Account (ERC-6551) is automatically created
3. **Staking**: Stake USDC to become verified
4. **Reputation**: Build reputation using ZK proofs
5. **Access**: Merchants accept verified agents

### What is a Token Bound Account (TBA)?

A TBA is a smart contract wallet controlled by your Agent License NFT. It allows your agent to:
- Hold assets (USDC, ETH, etc.)
- Execute transactions
- Interact with DeFi protocols
- Transfer with the NFT

### Why use KYA Protocol?

- **Reputation**: Build verifiable on-chain reputation
- **Trust**: Merchants trust verified agents
- **Transferability**: Agent identity is transferable (NFT)
- **Economic Security**: Staking provides merchant protection

---

## Agent Creation

### How do I create an agent?

1. Connect your wallet
2. Click "Create Agent"
3. Fill in details (name, description, category)
4. Pay minting fee (~$10)
5. Confirm transaction

### What is the minting fee?

Approximately $10 (0.001 ETH on Base). This covers:
- NFT minting
- TBA deployment
- Protocol fees

### Can I create multiple agents?

Yes! Each agent is a separate NFT with its own TBA and reputation.

### Can I change my agent's details?

Currently, agent metadata is immutable. Future versions may support updates.

---

## Staking & Verification

### What is the minimum stake?

**1000 USDC** (6 decimals = 1,000,000,000)

### Why do I need to stake?

Staking provides:
- **Verified Status**: Shows you're serious
- **Economic Security**: Merchants have recourse if you misbehave
- **Trust**: Higher trust from merchants

### Can I unstake immediately?

- **Not Verified**: Yes, you can unstake immediately
- **Verified**: You must wait 7 days (cooldown period)

### What happens if I unstake?

- You receive your USDC back
- You lose verified status (if below minimum)
- Merchants may stop accepting your agent

### Can I add more stake?

Yes! You can stake additional amounts at any time.

### What happens to my stake if I'm slashed?

Your staked USDC is slashed and paid to the merchant who submitted the claim.

---

## Reputation & Badges

### How do I build reputation?

Verify ZK proofs of your on-chain activity:
- Uniswap trading volume
- Aave borrowing/lending
- Chainlink oracle usage
- Other DeFi activity

### What are reputation tiers?

- **None** (0-99): New agent
- **Bronze** (100-499): Established
- **Silver** (500-1,999): Trusted
- **Gold** (2,000-9,999): Premium
- **Platinum** (10,000-49,999): Elite
- **Whale** (50,000+): Top tier

### How do I get badges?

Badges are automatically awarded when you verify specific proof types:
- **Uniswap Trader**: Verify Uniswap volume
- **Aave Borrower**: Verify Aave borrowing
- **Aave Lender**: Verify Aave lending
- **Chainlink User**: Verify Chainlink usage

### Can I lose reputation?

Reputation scores only increase. However:
- Slashing removes verified status
- Bad behavior may result in claims
- Claims can lead to slashing

---

## Claims & Slashing

### What is a claim?

A claim is a report of malicious behavior submitted by a merchant.

### How are claims resolved?

1. Merchant submits claim
2. 24-hour challenge period
3. Oracle (UMA/Kleros) resolves
4. If approved, agent is slashed
5. Merchant receives slashed amount (minus fee)

### Can I challenge a claim?

Yes! During the 24-hour challenge period, you can:
- Submit evidence
- Dispute the claim
- Escalate to arbitration (Kleros)

### What happens if I'm slashed?

- Your staked USDC is slashed
- You lose verified status
- Merchant receives compensation
- You can stake again to regain verified status

### How much can I be slashed?

Up to your total staked amount. The protocol caps slashing at your stake.

---

## Technical Questions

### What blockchain is KYA Protocol on?

**Base** (Layer 2 on Ethereum)
- Testnet: Base Sepolia
- Mainnet: Base

### What tokens do I need?

- **ETH**: For gas fees
- **USDC**: For staking (on Base)

### How much gas does it cost?

Typical operations:
- Mint agent: ~200k gas
- Stake: ~150k gas
- Unstake: ~120k gas
- Verify proof: ~100k gas

### Can I use a hardware wallet?

Yes! KYA Protocol works with any Web3 wallet, including hardware wallets.

### Is my private key stored?

No! KYA Protocol is non-custodial. You control your wallet and NFT.

---

## Integration Questions

### How do merchants integrate?

Merchants use the `MerchantSDK` to verify agents:

```typescript
const result = await merchantSDK.verifyAgent(tokenId, tbaAddress);

if (result.isVerified && result.tier >= 3) {
  // Accept agent
}
```

### What ZK coprocessors are supported?

- **Axiom**: Historical data proofs
- **Brevis**: On-chain data proofs

### What oracles are supported?

- **UMA**: Optimistic oracle
- **Kleros**: Arbitration court

### Can I use my own ZK coprocessor?

Yes! Grant `ZK_PROVER_ROLE` to your coprocessor address.

---

## Troubleshooting

### "Insufficient Balance"

**Problem**: Not enough USDC in TBA

**Solution**: 
1. Send USDC to your agent's TBA address
2. Verify balance
3. Try again

### "Stake Below Minimum"

**Problem**: Trying to stake less than 1000 USDC

**Solution**: Stake at least 1000 USDC

### "Cooldown Active"

**Problem**: Trying to unstake during cooldown

**Solution**: Wait 7 days after becoming verified

### "Proof Generation Failed"

**Problem**: ZK proof generation error

**Solution**:
- Check Axiom/Brevis service status
- Verify agent address
- Check proof query parameters
- Try again later

### "Transaction Failed"

**Problem**: Transaction reverted

**Solution**:
- Check gas price
- Ensure sufficient ETH for gas
- Verify network (Base Sepolia/Mainnet)
- Check contract state
- Review error message

### "Not Authorized"

**Problem**: Missing required role

**Solution**: 
- For proof verification: Grant `ZK_PROVER_ROLE`
- For claim resolution: Grant `ORACLE_ROLE`
- For admin functions: Grant `DEFAULT_ADMIN_ROLE`

---

## Security Questions

### Is KYA Protocol secure?

- **Audited**: Security audits conducted
- **Open Source**: Code is open for review
- **Battle-Tested**: Uses OpenZeppelin contracts
- **Non-Custodial**: You control your assets

### What if I lose my NFT?

If you lose access to your NFT:
- You lose control of your agent
- Your TBA and assets remain
- The new NFT owner gains control

**Prevention**: Use a hardware wallet, backup seed phrase

### Can my agent be hacked?

Your agent's TBA is a smart contract. Security depends on:
- Smart contract security (audited)
- Your wallet security (your responsibility)
- Protocol security (monitored)

### What if the protocol is hacked?

- Protocol can be paused (emergency)
- Admin can revoke roles
- Funds in vault are protected
- Incident response plan exists

---

## Economics

### How much does it cost to use KYA?

- **Minting**: ~$10 (one-time)
- **Staking**: 1000+ USDC (locked, returnable)
- **Gas**: Varies by operation
- **Fees**: Claim fees (1% of slashed amount)

### Do I earn yield on my stake?

Currently, no. Future versions may include:
- Yield from DeFi protocols
- Protocol revenue sharing

### What are the fees?

- **Minting Fee**: ~$10 (one-time)
- **Claim Fee**: 1% of slashed amount (paid by merchant)
- **Gas Fees**: Standard Base network fees

---

## Future Features

### What's coming next?

- **Yield Generation**: Earn on staked USDC
- **Governance**: Decentralized protocol governance
- **More Proof Types**: Additional reputation sources
- **Advanced Badges**: More badge types
- **Agent Marketplace**: Buy/sell agents

---

## Support

### Where can I get help?

- **Documentation**: `docs/`
- **Discord**: [To be added]
- **GitHub**: [Repository URL]
- **Email**: support@kya.protocol

### How do I report a bug?

1. Open GitHub issue
2. Provide details:
   - What happened
   - Expected behavior
   - Steps to reproduce
   - Error messages

### How do I report a security issue?

**DO NOT** open a public issue. Instead:
- Email: security@kya.protocol
- Follow responsible disclosure
- Wait for response before public disclosure

---

**Last Updated**: 2026-01-06

