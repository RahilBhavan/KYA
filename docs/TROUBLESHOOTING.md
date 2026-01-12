# Troubleshooting Guide

**Purpose**: Comprehensive troubleshooting guide for common issues.

---

## Common Issues

### Contract Interaction Issues

#### Issue: "Transaction Reverted"

**Symptoms**:
- Transaction fails
- Gas used but no state change
- Error message in transaction

**Diagnosis**:
1. Check transaction on BaseScan
2. Review error message
3. Check contract state
4. Verify parameters

**Solutions**:

**"Insufficient Balance"**:
```bash
# Check TBA balance
cast balance $TBA_ADDRESS --rpc-url $RPC_URL

# Fund TBA if needed
cast send $TBA_ADDRESS --value 1ether --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

**"Stake Below Minimum"**:
- Ensure stake amount >= 1000 USDC
- Check USDC decimals (6 on Base)

**"Not Authorized"**:
- Verify caller has required role
- Check if function requires specific role
- Grant role if needed

**"Cooldown Active"**:
- Wait 7 days after becoming verified
- Check cooldown timestamp
- Use `getStakeInfo()` to check status

#### Issue: "Contract Not Found"

**Symptoms**:
- Cannot interact with contract
- Address shows no code
- Deployment failed

**Solutions**:
1. Verify contract address
2. Check network (Base Sepolia vs Base)
3. Verify contract was deployed
4. Check deployment transaction

```bash
# Verify contract exists
cast code $CONTRACT_ADDRESS --rpc-url $RPC_URL

# Check on BaseScan
# https://sepolia.basescan.org/address/$CONTRACT_ADDRESS
```

---

### Staking Issues

#### Issue: Cannot Stake

**Symptoms**:
- Transaction fails
- "Insufficient allowance" error
- "Stake below minimum" error

**Diagnosis**:
1. Check USDC balance in TBA
2. Check USDC allowance
3. Verify stake amount

**Solutions**:

**Step 1: Check Balance**
```bash
cast call $USDC_ADDRESS "balanceOf(address)" $TBA_ADDRESS --rpc-url $RPC_URL
```

**Step 2: Approve USDC**
```solidity
// Approve from TBA
IAgentAccount(tbaAddress).execute(
    usdcAddress,
    0,
    abi.encodeWithSignature("approve(address,uint256)", insuranceVaultAddress, stakeAmount)
);
```

**Step 3: Verify Amount**
- Minimum: 1000 USDC (1,000,000,000 with 6 decimals)
- Check amount format

#### Issue: Cannot Unstake

**Symptoms**:
- "Cooldown active" error
- Transaction fails
- Unstake button disabled

**Solutions**:

**If Verified**:
- Wait 7 days after becoming verified
- Check cooldown: `getStakeInfo().stakedAt + 7 days`

**If Not Verified**:
- Should be able to unstake immediately
- Check stake amount > 0
- Verify you're the NFT owner

---

### Reputation Issues

#### Issue: Proof Verification Fails

**Symptoms**:
- "Proof already verified" error
- "Invalid proof type" error
- "Not authorized" error

**Solutions**:

**"Proof Already Verified"**:
- Each proof can only be verified once
- Use different proof data
- Check `_verifiedProofs` mapping

**"Invalid Proof Type"**:
- Verify proof type is supported
- Check proof type spelling
- Supported types: "UniswapVolume", "AaveBorrower", etc.

**"Not Authorized"**:
- Only `ZK_PROVER_ROLE` can verify
- Grant role to Axiom/Brevis address
- Or use adapter contract

#### Issue: Reputation Not Updating

**Symptoms**:
- Score doesn't increase
- Tier doesn't change
- Badge not awarded

**Solutions**:
1. Verify proof was successful
2. Check `getReputation()` for updates
3. Verify score thresholds
4. Check badge requirements

```bash
# Check reputation
cast call $REPUTATION_SCORE "getReputation(uint256)" $TOKEN_ID --rpc-url $RPC_URL
```

---

### Paymaster Issues

#### Issue: Gas Not Sponsored

**Symptoms**:
- User operation fails
- Gas not paid
- "Not eligible" error

**Solutions**:

**Check Eligibility**:
- Agent created < 7 days ago?
- Twitter verified?
- Transaction count < 50?
- Paymaster has deposit?

**Check Paymaster**:
```bash
# Check deposit
cast call $PAYMASTER "getDeposited()" --rpc-url $RPC_URL

# Fund if needed
cast send $PAYMASTER "deposit()" --value 1ether --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

---

### Integration Issues

#### Issue: ZK Proof Generation Fails

**Symptoms**:
- Axiom/Brevis API errors
- Proof generation timeout
- Invalid proof data

**Solutions**:
1. Check API key validity
2. Verify network configuration
3. Check service status
4. Review query parameters
5. Try again with retry logic

#### Issue: Oracle Resolution Fails

**Symptoms**:
- UMA/Kleros API errors
- Claim not resolved
- Resolution timeout

**Solutions**:
1. Check API key validity
2. Verify oracle address
3. Check claim status
4. Review evidence
5. Wait for resolution (can take time)

---

## Debugging Tools

### Foundry Tools

```bash
# Trace transaction
cast run $TX_HASH --rpc-url $RPC_URL

# Decode transaction
cast tx $TX_HASH --rpc-url $RPC_URL

# Call contract
cast call $CONTRACT "functionName()" --rpc-url $RPC_URL
```

### BaseScan

- View transactions: https://sepolia.basescan.org/tx/$TX_HASH
- View contracts: https://sepolia.basescan.org/address/$ADDRESS
- View events: Filter by contract address

### Tenderly

- Simulate transactions
- Debug failed transactions
- View contract state

---

## Getting Help

### Before Asking for Help

1. **Check Documentation**
   - User Guide
   - Developer Guide
   - FAQ

2. **Search Issues**
   - GitHub issues
   - Discord messages
   - Documentation

3. **Gather Information**
   - Error messages
   - Transaction hashes
   - Contract addresses
   - Steps to reproduce

### How to Ask for Help

**Include**:
- What you're trying to do
- What happened (error messages)
- What you expected
- Steps to reproduce
- Relevant addresses/hashes
- Network (testnet/mainnet)

**Example**:
```
I'm trying to stake 1000 USDC for my agent (tokenId: 1).
The transaction fails with "Insufficient allowance".
I've approved USDC from the TBA address: 0x...
Transaction hash: 0x...
Network: Base Sepolia
```

---

## Prevention

### Best Practices

1. **Test on Testnet First**
   - Always test on Base Sepolia
   - Verify everything works
   - Then use mainnet

2. **Check Balances**
   - Ensure sufficient ETH for gas
   - Ensure sufficient USDC for staking
   - Monitor TBA balance

3. **Verify Parameters**
   - Check amounts (decimals)
   - Verify addresses
   - Confirm network

4. **Monitor Transactions**
   - Watch for confirmations
   - Check for errors
   - Verify state changes

5. **Keep Backups**
   - Backup wallet seed phrase
   - Save contract addresses
   - Document configurations

---

## Emergency Procedures

### If You're Hacked

1. **Immediately**:
   - Transfer NFT to new wallet (if possible)
   - Report to security@kya.protocol
   - Document everything

2. **Investigation**:
   - Review transactions
   - Identify attack vector
   - Assess damage

3. **Recovery**:
   - Secure new wallet
   - Transfer remaining assets
   - Update security

### If Protocol is Compromised

1. **Monitor**:
   - Watch for unusual activity
   - Check protocol status
   - Review alerts

2. **Response**:
   - Protocol may be paused
   - Follow official communications
   - Do not interact if unsafe

---

## Resources

- **Documentation**: `docs/`
- **BaseScan**: https://basescan.org
- **Tenderly**: https://tenderly.co
- **Support**: support@kya.protocol
- **Security**: security@kya.protocol

---

**Last Updated**: 2026-01-06

