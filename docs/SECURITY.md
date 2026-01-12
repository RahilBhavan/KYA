# KYA Protocol - Security Documentation

**Version**: 2.0  
**Last Updated**: 2026-01-06  
**Status**: Pre-Audit

---

## Overview

This document outlines the security considerations, attack vectors, and mitigations for the KYA Protocol v2.0. It serves as both an internal security review guide and preparation for external security audits.

---

## Security Model

### Trust Assumptions

1. **ZK Coprocessors (Axiom/Brevis)**: Trusted to generate valid ZK proofs
2. **Oracles (UMA/Kleros)**: Trusted to resolve claims fairly
3. **ERC-4337 EntryPoint**: Trusted standard implementation
4. **OpenZeppelin Contracts**: Trusted audited libraries

### Attack Surfaces

1. **Smart Contracts**: Direct contract interactions
2. **External Integrations**: ZK coprocessors, oracles, EntryPoint
3. **Economic Attacks**: Staking, slashing, fee manipulation
4. **Access Control**: Role-based permissions
5. **Reentrancy**: Cross-contract calls

---

## Security Features

### 1. Access Control

**Implementation**: OpenZeppelin `AccessControl`

**Roles**:
- `DEFAULT_ADMIN_ROLE`: Protocol administration
- `ZK_PROVER_ROLE`: ZK coprocessor addresses (Axiom/Brevis)
- `ORACLE_ROLE`: Oracle addresses (UMA/Kleros)

**Protections**:
- Role-based function access
- Multi-sig recommended for admin (production)
- Timelock recommended for critical functions (production)

### 2. Reentrancy Protection

**Implementation**: OpenZeppelin `ReentrancyGuard`

**Protected Functions**:
- `InsuranceVault.stake()`
- `InsuranceVault.unstake()`
- `InsuranceVault.submitClaim()`
- `InsuranceVault.resolveClaim()`
- `InsuranceVault.withdrawFees()`
- `Paymaster.postOp()`

**Pattern**: Checks-Effects-Interactions (CEI) pattern used throughout

### 3. Input Validation

**Validations**:
- Zero address checks
- Amount > 0 checks
- Token existence checks
- Bounds checking (e.g., claimFeeBps <= 1000)
- Proof replay prevention

### 4. Safe Token Transfers

**Implementation**: OpenZeppelin `SafeERC20`

**Usage**: All ERC-20 transfers use `safeTransfer` and `safeTransferFrom`

### 5. Pausability

**Implementation**: OpenZeppelin `Pausable`

**Usage**: `InsuranceVault` can be paused in emergencies

---

## Attack Vectors & Mitigations

### 1. Reentrancy Attacks

**Vector**: Attacker calls external contract that calls back into protocol

**Mitigation**:
- `ReentrancyGuard` on all external functions
- CEI pattern (Checks-Effects-Interactions)
- No external calls before state updates

**Status**: ✅ Protected

### 2. Access Control Bypass

**Vector**: Unauthorized access to admin functions

**Mitigation**:
- Role-based access control
- Zero-address checks
- Role verification on all protected functions

**Status**: ✅ Protected

**Recommendation**: Use multi-sig and timelock in production

### 3. Integer Overflow/Underflow

**Vector**: Arithmetic operations exceed type limits

**Mitigation**:
- Solidity 0.8.28 (built-in overflow protection)
- Explicit bounds checking where needed
- Safe math operations

**Status**: ✅ Protected (Solidity 0.8+)

### 4. Proof Replay Attacks

**Vector**: Same ZK proof verified multiple times

**Mitigation**:
- `_verifiedProofs` mapping tracks proof hashes
- Proof hash = `keccak256(tokenId, proofType, proof)`
- Revert if proof already verified

**Status**: ✅ Protected

### 5. Oracle Manipulation

**Vector**: Malicious oracle resolves claims incorrectly

**Mitigation**:
- 24-hour challenge period
- Escalation to human arbitration (Kleros)
- Only trusted addresses granted `ORACLE_ROLE`
- Challenge mechanism for agents

**Status**: ✅ Protected (with trust assumption)

**Recommendation**: Use multiple oracles or oracle aggregation

### 6. ZK Proof Manipulation

**Vector**: Invalid or manipulated ZK proofs

**Mitigation**:
- Only `ZK_PROVER_ROLE` can verify proofs
- Proof replay prevention
- Trust Axiom/Brevis (future: on-chain verification)

**Status**: ⚠️ Partially Protected (trusts coprocessor)

**Future**: Implement on-chain ZK proof verification

### 7. Fee Manipulation

**Vector**: Admin sets excessive fees

**Mitigation**:
- Maximum fee caps (e.g., claimFeeBps <= 1000 = 10%)
- Timelock recommended for fee changes
- Governance mechanism (future)

**Status**: ✅ Protected (with caps)

**Recommendation**: Add timelock for fee changes

### 8. Slashing Edge Cases

**Vector**: Partial slashing, claim > stake, etc.

**Mitigation**:
- `_slash()` caps amount to available stake
- Fee calculation before slashing
- Safe token transfers

**Status**: ✅ Protected

### 9. Unstake Cooldown Bypass

**Vector**: Agent unstakes immediately after verification

**Mitigation**:
- 7-day cooldown for verified agents
- Cooldown tracked per agent
- Cannot unstake during cooldown

**Status**: ✅ Protected

### 10. Paymaster Gas Griefing

**Vector**: Agent exhausts sponsored gas limit

**Mitigation**:
- Hard limit: 50 transactions per agent
- Time limit: 7 days from creation
- Twitter verification required
- Max cost per transaction

**Status**: ✅ Protected

### 11. Badge Storage DoS

**Vector**: Excessive badge storage costs gas

**Mitigation**:
- Badges stored as `bytes32` (not strings)
- Badge count limited by proof count
- Gas-efficient storage

**Status**: ✅ Protected (optimized)

### 12. Struct Packing Edge Cases

**Vector**: Integer overflow in packed structs

**Mitigation**:
- `uint224` for score (max 2^224, sufficient)
- `uint32` for verifiedProofs (max 4B, sufficient)
- Validation on updates

**Status**: ✅ Protected (with validation)

---

## Security Checklist

### Code Review Checklist

- [ ] All external functions use `ReentrancyGuard`
- [ ] All state changes before external calls (CEI)
- [ ] All inputs validated (zero address, amounts, etc.)
- [ ] Access control on all admin functions
- [ ] Safe token transfers (SafeERC20)
- [ ] Bounds checking on all arithmetic
- [ ] Proof replay prevention
- [ ] Challenge periods enforced
- [ ] Fee caps enforced
- [ ] Cooldown periods enforced

### Deployment Checklist

- [ ] Multi-sig for admin role
- [ ] Timelock for critical functions
- [ ] Oracle addresses verified
- [ ] ZK coprocessor addresses verified
- [ ] EntryPoint address verified
- [ ] Initial parameters set correctly
- [ ] Pause functionality tested
- [ ] Emergency procedures documented

### Operational Checklist

- [ ] Monitor for suspicious activity
- [ ] Regular security reviews
- [ ] Oracle monitoring
- [ ] ZK proof verification monitoring
- [ ] Gas usage monitoring
- [ ] Incident response plan

---

## Known Limitations

### 1. ZK Proof Verification

**Current**: Trusts ZK coprocessor (Axiom/Brevis)  
**Future**: On-chain ZK proof verification

### 2. Oracle Trust

**Current**: Trusts single oracle (UMA or Kleros)  
**Future**: Multi-oracle aggregation

### 3. Admin Centralization

**Current**: Single admin address  
**Future**: Multi-sig + governance

### 4. No Timelock

**Current**: Admin can change parameters immediately  
**Future**: Timelock for critical functions

### 5. No Rate Limiting

**Current**: No rate limiting on functions  
**Future**: Rate limiting for high-frequency operations

---

## Security Best Practices

### For Developers

1. **Always use SafeERC20** for token transfers
2. **Follow CEI pattern** (Checks-Effects-Interactions)
3. **Validate all inputs** before processing
4. **Use ReentrancyGuard** on external functions
5. **Check access control** before state changes
6. **Test edge cases** (zero, max, overflow)
7. **Review external calls** for reentrancy risks

### For Operators

1. **Use multi-sig** for admin operations
2. **Implement timelock** for parameter changes
3. **Monitor contracts** for suspicious activity
4. **Verify oracle addresses** before granting roles
5. **Test pause functionality** regularly
6. **Keep emergency procedures** documented
7. **Regular security reviews**

---

## Security Testing

### Unit Tests

All security-critical functions have unit tests:
- Reentrancy protection
- Access control
- Input validation
- Edge cases

### Fuzz Tests

Fuzz tests cover:
- Random stake amounts
- Random claim amounts
- Random proof types
- Random eligibility parameters

### Invariant Tests

Invariant tests verify:
- Verified agents always have minimum stake
- Claim amounts never exceed stake
- Reputation scores only increase
- Badge count <= proof count

---

## Audit Preparation

### For Auditors

1. **Codebase**: All contracts in `src/`
2. **Tests**: Comprehensive test suite in `test/`
3. **Documentation**: This document + inline comments
4. **Deployment Scripts**: `script/`
5. **Known Issues**: Documented in this file

### Audit Scope

**In Scope**:
- All smart contracts in `src/`
- Integration contracts
- Access control mechanisms
- Economic security (staking/slashing)
- External integrations

**Out of Scope**:
- JavaScript SDK (separate audit)
- Frontend applications
- External services (Axiom, UMA, etc.)

### Audit Deliverables Expected

1. **Security Report**: Findings categorized by severity
2. **Code Review**: Line-by-line security review
3. **Attack Scenarios**: Potential attack vectors
4. **Recommendations**: Security improvements
5. **Fix Verification**: Confirmation of fixes

---

## Incident Response

### Emergency Procedures

1. **Pause Protocol**: Use `pause()` function
2. **Revoke Roles**: Revoke compromised roles
3. **Contact Team**: Alert development team
4. **Investigate**: Determine scope of issue
5. **Fix**: Implement fix and test
6. **Unpause**: After fix verified

### Contact

- **Security Email**: security@kya.protocol
- **Emergency**: [To be defined]
- **Bug Bounty**: [To be defined]

---

## Security History

### v2.0 (Current)

- ✅ Proof replay prevention added
- ✅ Fee withdrawal logic fixed
- ✅ Paymaster gas payment fixed
- ✅ Struct packing optimizations
- ✅ Badge storage optimizations

### v1.0 (MVP)

- ✅ Basic access control
- ✅ Reentrancy protection
- ✅ Safe token transfers

---

## Future Security Enhancements

1. **On-Chain ZK Verification**: Verify proofs on-chain
2. **Multi-Oracle**: Aggregate multiple oracles
3. **Timelock**: Add timelock for admin functions
4. **Governance**: Decentralized governance
5. **Rate Limiting**: Prevent DoS attacks
6. **Circuit Breakers**: Automatic pause triggers
7. **Formal Verification**: Mathematical proof of correctness

---

**Last Updated**: 2026-01-06  
**Next Review**: After external audit

