# Multi-sig Administration Setup Guide

**Purpose**: Guide for setting up multi-signature wallet administration for KYA Protocol contracts.

---

## Overview

Multi-sig administration is critical for production security. This guide walks through:
1. Choosing a multi-sig solution
2. Setting up the multi-sig wallet
3. Transferring admin roles
4. Configuring timelock (optional)
5. Operational procedures

---

## Step 1: Choose Multi-sig Solution

### Recommended: Gnosis Safe

**Why Gnosis Safe?**
- Most widely used and audited
- Excellent Base network support
- User-friendly web interface
- Mobile app available
- Hardware wallet integration
- Battle-tested in production

**Setup**:
1. Visit https://safe.global
2. Connect wallet
3. Create new Safe
4. Add signers
5. Set threshold (recommended: 3-of-5 or 4-of-7)

### Alternative: OpenZeppelin Defender

**Why Defender?**
- Enterprise-grade security
- Integrated monitoring
- Automation features
- Multi-sig + timelock support

**Setup**:
1. Visit https://defender.openzeppelin.com
2. Create account
3. Set up multi-sig wallet
4. Configure signers

---

## Step 2: Create Multi-sig Wallet

### On Base Sepolia (Testnet)

1. **Go to Safe App**: https://app.safe.global
2. **Create Safe**:
   - Network: Base Sepolia
   - Name: "KYA Protocol Admin (Testnet)"
   - Add signers (minimum 3, recommended 5)
   - Set threshold: 3-of-5
3. **Fund with testnet ETH**: Get from Base Sepolia faucet
4. **Test operations**: Create test transaction, confirm with multiple signers

### On Base Mainnet

1. **Create Safe**:
   - Network: Base Mainnet
   - Name: "KYA Protocol Admin"
   - Add signers (recommended: 5-7)
   - Set threshold: 4-of-7 (more secure)
2. **Fund with ETH**: For gas fees
3. **Verify configuration**: Test with small transaction

### Signer Selection

**Recommended Signers**:
- 2-3 Team members
- 1-2 Advisors/Partners
- 1-2 Community representatives (optional)

**Requirements**:
- Hardware wallets (Ledger/Trezor) recommended
- Secure key storage
- Availability for signing
- Clear communication channels

---

## Step 3: Transfer Admin Roles

### Prerequisites

1. Multi-sig wallet created and funded
2. All contracts deployed
3. Contract addresses saved
4. Testnet testing complete

### Environment Setup

Create `.env` file with:

```bash
# Multi-sig address
MULTISIG_ADDRESS=0x...

# Contract addresses
AGENT_LICENSE_ADDRESS=0x...
AGENT_REGISTRY_ADDRESS=0x...
REPUTATION_SCORE_ADDRESS=0x...
INSURANCE_VAULT_ADDRESS=0x...
PAYMASTER_ADDRESS=0x...
MERCHANT_SDK_ADDRESS=0x...
ZK_ADAPTER_ADDRESS=0x...
ORACLE_ADAPTER_ADDRESS=0x...

# Deployer private key (for transfer)
PRIVATE_KEY=0x...

# RPC URL
RPC_URL=https://...
```

### Execute Transfer

**On Testnet First**:

```bash
# 1. Verify multi-sig is ready
forge script script/TransferAdminToMultisig.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  -vvv

# 2. Execute transfer
forge script script/TransferAdminToMultisig.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast

# 3. Verify transfer
# Check console output for verification results
```

**On Mainnet** (after testnet verification):

```bash
forge script script/TransferAdminToMultisig.s.sol \
  --rpc-url $BASE_RPC_URL \
  --broadcast \
  --verify
```

### Verification Checklist

After transfer, verify:

- [ ] Multi-sig has `DEFAULT_ADMIN_ROLE` on all contracts
- [ ] Deployer no longer has `DEFAULT_ADMIN_ROLE`
- [ ] Multi-sig can execute admin functions (test on testnet)
- [ ] Deployer cannot execute admin functions

### Manual Verification

```solidity
// Check if multi-sig has admin role
bytes32 DEFAULT_ADMIN_ROLE = 0x00;
bool hasRole = contract.hasRole(DEFAULT_ADMIN_ROLE, multisigAddress);

// Check if deployer no longer has role
bool deployerHasRole = contract.hasRole(DEFAULT_ADMIN_ROLE, deployerAddress);
```

---

## Step 4: Timelock Setup (Optional but Recommended)

### Why Timelock?

Timelock adds a delay to critical admin operations, providing:
- Protection against compromised multi-sig
- Time for community review
- Additional security layer

### Deploy TimelockController

```bash
# Set delay (default: 24 hours)
export TIMELOCK_DELAY=86400  # 24 hours in seconds

# Deploy timelock
forge script script/SetupTimelock.s.sol \
  --rpc-url $RPC_URL \
  --broadcast
```

### Configure Contracts for Timelock

After deployment, contracts need to be updated to use timelock for critical functions. This requires contract modifications:

```solidity
contract InsuranceVault {
    TimelockController public timelock;
    
    function updateSettings(...) external {
        require(msg.sender == address(timelock), "Only timelock");
        // ... update logic
    }
}
```

**Note**: This requires contract upgrades or new deployments. Consider for v2.0.

---

## Step 5: Operational Procedures

### Admin Operations via Multi-sig

1. **Create Proposal**
   - Document the change
   - Get team approval
   - Prepare transaction data

2. **Submit to Multi-sig**
   - Go to Safe app
   - Create new transaction
   - Enter contract address and calldata
   - Submit for approval

3. **Gather Signatures**
   - Notify signers
   - Wait for threshold signatures
   - Execute transaction

4. **Verify Execution**
   - Check transaction on block explorer
   - Verify state changes
   - Update documentation

### Critical Functions Requiring Multi-sig

**ReputationScore**:
- `createBadge()`
- `setProofTypeScore()`
- `setWhitelistedContract()`

**InsuranceVault**:
- `updateSettings()`
- `withdrawFees()`
- `pause()` / `unpause()`

**Paymaster**:
- `setTwitterVerified()`
- `withdrawTo()`

**MerchantSDK**:
- `verifyAgent()`
- `suspendAgent()`

**AgentRegistry**:
- `setMintingFee()`
- `setBaseURI()`
- `pause()` / `unpause()`

### Emergency Procedures

**If Multi-sig is Compromised**:
1. Immediately pause all contracts
2. Assess damage
3. Execute recovery plan
4. Deploy new contracts if necessary

**If Signer is Unavailable**:
1. Use backup signers
2. If threshold cannot be met, wait for signer availability
3. For emergencies, consider temporary threshold reduction (risky)

---

## Security Best Practices

1. **Hardware Wallets**: Use hardware wallets for all signers
2. **Key Management**: Secure key storage, no cloud storage
3. **Signer Diversity**: Mix team, advisors, community
4. **Threshold**: 3-of-5 minimum, 4-of-7 recommended
5. **Regular Testing**: Test multi-sig operations monthly
6. **Documentation**: Keep all procedures documented
7. **Backup Plans**: Have recovery procedures ready

---

## Troubleshooting

### Transaction Fails

**Issue**: Multi-sig transaction reverts
**Solution**: 
- Check contract state
- Verify calldata is correct
- Check gas limits
- Review contract requirements

### Cannot Reach Threshold

**Issue**: Not enough signers available
**Solution**:
- Wait for signer availability
- Use backup signers
- Consider temporary threshold reduction (only for emergencies)

### Wrong Address

**Issue**: Transferred to wrong multi-sig address
**Solution**:
- If on testnet: Redeploy and retry
- If on mainnet: Contact security team immediately

---

## Next Steps

After multi-sig setup:

1. ✅ Test all admin functions via multi-sig
2. ✅ Document operational procedures
3. ✅ Set up monitoring for admin operations
4. ✅ Create incident response plan
5. ✅ Train team on multi-sig operations

---

## Resources

- [Gnosis Safe Documentation](https://docs.safe.global/)
- [OpenZeppelin Defender](https://docs.openzeppelin.com/defender/)
- [Base Network](https://docs.base.org/)
- [KYA Protocol Security Docs](./SECURITY.md)

---

**Last Updated**: 2026-01-12
