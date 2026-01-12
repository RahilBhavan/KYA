# Advanced Features Setup Guide

**Purpose**: Enable ZK proof verification and oracle-based claim resolution  
**Status**: Optional - Protocol works without these, but advanced features require them

---

## Overview

The KYA Protocol has two categories of advanced features that require external service integration:

1. **ZK Proof Verification** (Axiom/Brevis)
   - Private reputation verification
   - Badge awarding based on on-chain activity
   - Proof-based reputation updates

2. **Oracle-Based Claim Resolution** (UMA/Kleros)
   - Dispute resolution for insurance claims
   - Challenge period and oracle arbitration
   - Automated claim resolution

---

## Feature 1: ZK Proof Verification

### What It Enables

- ✅ **Private Reputation Verification**: Verify agent activity without revealing transaction details
- ✅ **Badge System**: Award badges based on on-chain activity (Uniswap volume, Aave usage, etc.)
- ✅ **Proof-Based Updates**: Update reputation scores using ZK proofs
- ✅ **Privacy-Preserving**: Agents can prove activity without exposing all transactions

### What's Needed

#### 1. Choose ZK Coprocessor

**Option A: Axiom** (Recommended)
- **Website**: https://axiom.xyz
- **Documentation**: https://docs.axiom.xyz/
- **Status**: Well-established, good Base support

**Option B: Brevis**
- **Website**: https://brevis.network
- **Documentation**: https://docs.brevis.network/
- **Status**: Alternative option

#### 2. Get Service Address

**For Axiom**:

1. **Install Axiom CLI**:
   ```bash
   # Install Rust (if needed)
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   
   # Install Axiom CLI
   cargo +1.86 install --locked --git https://github.com/axiom-crypto/axiom-api-cli.git --tag v1.0.1 cargo-axiom
   ```

2. **Get API Key**:
   - Sign up at https://axiom.xyz
   - Navigate to Dashboard → API Keys
   - Generate new API key
   - Save securely

3. **Register CLI**:
   ```bash
   export AXIOM_API_KEY=your_api_key_here
   cargo axiom register --api-key $AXIOM_API_KEY
   ```

4. **Get Contract Address**:
   ```bash
   # Base Sepolia
   cargo axiom get-address --chain-id 84532
   
   # Base Mainnet
   cargo axiom get-address --chain-id 8453
   ```

5. **Add to `.env`**:
   ```bash
   AXIOM_ADDRESS=0x...  # Address from CLI output
   ```

**For Brevis**:

1. Check documentation: https://docs.brevis.network/
2. Find Base Sepolia contract address
3. Or contact Brevis team (Discord: brevis)
4. Add to `.env`: `BREVIS_ADDRESS=0x...`

#### 3. Grant ZK_PROVER_ROLE

After deployment, grant the role to the ZK coprocessor address:

```bash
# Get role hash
ZK_ROLE=$(cast keccak "ZK_PROVER_ROLE()")

# Grant to Axiom (if using Axiom)
cast send $REPUTATION_SCORE \
  "grantRole(bytes32,address)" \
  $ZK_ROLE \
  $AXIOM_ADDRESS \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# Grant to Brevis (if using Brevis)
cast send $REPUTATION_SCORE \
  "grantRole(bytes32,address)" \
  $ZK_ROLE \
  $BREVIS_ADDRESS \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

#### 4. Verify Setup

```bash
# Check if role is granted
cast call $REPUTATION_SCORE \
  "hasRole(bytes32,address)" \
  $ZK_ROLE \
  $AXIOM_ADDRESS \
  --rpc-url $BASE_SEPOLIA_RPC_URL

# Should return: 0x0000000000000000000000000000000000000000000000000000000000000001 (true)
```

### Usage

Once set up, ZK coprocessors can:

1. **Generate Proofs**: Query on-chain data and generate ZK proofs
2. **Verify Proofs**: Call `ReputationScore.verifyProof()` with proof data
3. **Update Reputation**: Reputation scores updated based on proof verification
4. **Award Badges**: Badges automatically awarded based on proof types

**Example Proof Types**:
- `UniswapVolume`: Trading volume on Uniswap
- `UniswapTrades`: Number of trades
- `AaveBorrower`: Aave borrowing history
- `AaveLender`: Aave lending history
- `ChainlinkUser`: Chainlink oracle usage

---

## Feature 2: Oracle-Based Claim Resolution

### What It Enables

- ✅ **Dispute Resolution**: Automated resolution of insurance claims
- ✅ **Challenge Period**: Allow agents to challenge claims
- ✅ **Oracle Arbitration**: Third-party resolution of disputes
- ✅ **Automated Slashing**: Slash staked funds based on oracle decision

### What's Needed

#### 1. Choose Oracle Service

**Option A: UMA (Universal Market Access)** (Recommended)
- **Website**: https://umaproject.org
- **Documentation**: https://docs.umaproject.org/
- **Status**: Well-established oracle protocol

**Option B: Kleros**
- **Website**: https://kleros.io
- **Documentation**: https://docs.kleros.io/
- **Status**: Decentralized arbitration

#### 2. Get Service Address

**For UMA**:

1. **Check Documentation**:
   - Visit: https://docs.umaproject.org/
   - Navigate to "Contract Addresses" or "Deployments"
   - Check if Optimistic Oracle is deployed on Base

2. **If Not Available on Base**:
   - Deploy UMA contracts yourself (see UMA deployment guide)
   - Or use UMA's cross-chain capabilities
   - Or use alternative oracle service

3. **Add to `.env`**:
   ```bash
   UMA_ADDRESS=0x...  # Optimistic Oracle address
   ```

**For Kleros**:

1. **Check Documentation**:
   - Visit: https://docs.kleros.io/
   - Navigate to "Deployments" or "Arbitrator Addresses"
   - Check if Kleros arbitrator is deployed on Base

2. **If Not Available on Base**:
   - Deploy Kleros contracts yourself
   - Or use Kleros API (if available)
   - Or contact Kleros team

3. **Add to `.env`**:
   ```bash
   KLEROS_ADDRESS=0x...  # Arbitrator address
   ```

#### 3. Grant ORACLE_ROLE

After deployment, grant the role to the oracle address:

```bash
# Get role hash
ORACLE_ROLE=$(cast keccak "ORACLE_ROLE()")

# Grant to UMA (if using UMA)
cast send $INSURANCE_VAULT \
  "grantRole(bytes32,address)" \
  $ORACLE_ROLE \
  $UMA_ADDRESS \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# Grant to Kleros (if using Kleros)
cast send $INSURANCE_VAULT \
  "grantRole(bytes32,address)" \
  $ORACLE_ROLE \
  $KLEROS_ADDRESS \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

#### 4. Verify Setup

```bash
# Check if role is granted
cast call $INSURANCE_VAULT \
  "hasRole(bytes32,address)" \
  $ORACLE_ROLE \
  $UMA_ADDRESS \
  --rpc-url $BASE_SEPOLIA_RPC_URL

# Should return: 0x0000000000000000000000000000000000000000000000000000000000000001 (true)
```

### Usage

Once set up, oracles can:

1. **Resolve Claims**: Call `InsuranceVault.resolveClaim()` with claim ID and decision
2. **Challenge Claims**: Agents can challenge claims during challenge period
3. **Slash Funds**: Oracle decision triggers automatic slashing if claim is valid
4. **Refund Stakes**: Oracle decision triggers refund if claim is invalid

**Claim Resolution Flow**:
1. Merchant submits claim
2. Challenge period begins (agents can challenge)
3. Oracle resolves claim (if not challenged, or after challenge)
4. Funds slashed or refunded based on oracle decision

---

## Quick Setup Checklist

### For ZK Proof Verification

- [ ] Choose ZK coprocessor (Axiom or Brevis)
- [ ] Get service account/API key
- [ ] Get contract address for Base Sepolia
- [ ] Add address to `.env`: `AXIOM_ADDRESS=0x...` or `BREVIS_ADDRESS=0x...`
- [ ] Deploy contracts (if not already deployed)
- [ ] Grant `ZK_PROVER_ROLE` to service address
- [ ] Verify role is granted
- [ ] Test proof generation and verification

### For Oracle-Based Claim Resolution

- [ ] Choose oracle service (UMA or Kleros)
- [ ] Check if service is deployed on Base
- [ ] Get contract address (or deploy if needed)
- [ ] Add address to `.env`: `UMA_ADDRESS=0x...` or `KLEROS_ADDRESS=0x...`
- [ ] Deploy contracts (if not already deployed)
- [ ] Grant `ORACLE_ROLE` to service address
- [ ] Verify role is granted
- [ ] Test claim submission and resolution

---

## Post-Deployment Setup Script

You can use the automated setup script:

```bash
# Run post-deployment setup (grants roles if addresses are set)
forge script script/PostDeploymentSetup.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast
```

**What it does**:
- Grants `ZK_PROVER_ROLE` to Axiom/Brevis (if addresses set in `.env`)
- Grants `ORACLE_ROLE` to UMA/Kleros (if addresses set in `.env`)
- Funds Paymaster (if `PAYMASTER_FUNDING` set)

---

## Verification Commands

### Check ZK Proof Setup

```bash
# Verify Axiom address is set
echo "Axiom: ${AXIOM_ADDRESS:-NOT SET}"

# Check if role is granted
ZK_ROLE=$(cast keccak "ZK_PROVER_ROLE()")
cast call $REPUTATION_SCORE \
  "hasRole(bytes32,address)" \
  $ZK_ROLE \
  $AXIOM_ADDRESS \
  --rpc-url $BASE_SEPOLIA_RPC_URL
```

### Check Oracle Setup

```bash
# Verify UMA address is set
echo "UMA: ${UMA_ADDRESS:-NOT SET}"

# Check if role is granted
ORACLE_ROLE=$(cast keccak "ORACLE_ROLE()")
cast call $INSURANCE_VAULT \
  "hasRole(bytes32,address)" \
  $ORACLE_ROLE \
  $UMA_ADDRESS \
  --rpc-url $BASE_SEPOLIA_RPC_URL
```

---

## Troubleshooting

### Issue: "ZK_PROVER_ROLE not granted"
**Solution**: Grant role using commands above

### Issue: "ORACLE_ROLE not granted"
**Solution**: Grant role using commands above

### Issue: "Service not deployed on Base"
**Solution**: 
- Check service documentation for Base support
- Deploy service contracts yourself (if open source)
- Use alternative service
- Contact service team for Base deployment timeline

### Issue: "Proof verification fails"
**Solution**:
- Verify `ZK_PROVER_ROLE` is granted
- Check proof format matches expected format
- Verify ZK coprocessor is generating valid proofs

### Issue: "Claim resolution fails"
**Solution**:
- Verify `ORACLE_ROLE` is granted
- Check oracle contract is correct type
- Verify oracle is responding to resolution requests

---

## Cost Considerations

### ZK Proof Verification
- **Axiom**: May have API usage costs
- **Brevis**: May have API usage costs
- **Gas Costs**: Proof verification transactions require gas

### Oracle Resolution
- **UMA**: May have oracle fees
- **Kleros**: May have arbitration fees
- **Gas Costs**: Resolution transactions require gas

---

## Security Notes

1. **Role Management**: Only grant roles to trusted addresses
2. **Service Verification**: Verify service addresses are official
3. **Access Control**: Regularly audit who has roles
4. **Monitoring**: Monitor role grants and revocations

---

## Summary

**To enable advanced features, you need**:

1. **For ZK Proofs**:
   - ZK coprocessor address (Axiom or Brevis)
   - `ZK_PROVER_ROLE` granted to that address

2. **For Oracle Resolution**:
   - Oracle address (UMA or Kleros)
   - `ORACLE_ROLE` granted to that address

**The protocol works without these**, but:
- ❌ No ZK proof verification
- ❌ No badge system
- ❌ No oracle-based claim resolution
- ❌ Manual claim resolution only

**With these enabled**:
- ✅ Full ZK proof verification
- ✅ Badge system active
- ✅ Automated claim resolution
- ✅ Privacy-preserving reputation

---

**Last Updated**: 2026-01-06  
**Status**: Optional - Enable as needed
