# Auditor Onboarding Guide

**Purpose**: Help external auditors quickly understand and audit the KYA Protocol

---

## Quick Start

### 1. Repository Access

```bash
git clone [repository-url]
cd KYA
```

### 2. Install Dependencies

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Install dependencies
forge install
```

### 3. Build Contracts

```bash
forge build
```

### 4. Run Tests

```bash
forge test
forge coverage
```

---

## Codebase Overview

### Core Contracts

1. **AgentLicense.sol** (ERC-721)
   - Agent identity NFTs
   - Metadata management
   - Status tracking

2. **AgentRegistry.sol**
   - Factory for agent creation
   - Atomic NFT + TBA deployment
   - Fee collection

3. **SimpleAccountImplementation.sol** (ERC-6551)
   - Token Bound Account implementation
   - Transaction execution
   - Asset management

4. **InsuranceVault.sol** ⚠️ **CRITICAL**
   - Staking mechanism
   - Slashing mechanism
   - Claim resolution
   - Fee management

5. **ReputationScore.sol** ⚠️ **CRITICAL**
   - Reputation scoring
   - ZK proof verification
   - Badge system
   - Tier management

6. **Paymaster.sol** ⚠️ **CRITICAL**
   - ERC-4337 gas sponsorship
   - Eligibility checks
   - Deposit management

7. **MerchantSDK.sol**
   - Merchant verification
   - Agent status checks
   - Violation reporting

### Integration Contracts

8. **ZKAdapter.sol**
   - ZK coprocessor bridge
   - Proof query management

9. **OracleAdapter.sol**
   - Oracle bridge
   - Claim management

---

## Critical Functions to Review

### InsuranceVault.sol

**High Priority**:
- `stake()` - Economic security
- `unstake()` - Cooldown logic
- `submitClaim()` - Claim creation
- `resolveClaim()` - Slashing logic
- `_slash()` - Core slashing function
- `withdrawFees()` - Fee withdrawal

**Focus Areas**:
- Reentrancy protection
- Access control
- Fee calculation
- Slashing edge cases
- Cooldown enforcement

### ReputationScore.sol

**High Priority**:
- `verifyProof()` - Proof verification
- `getTier()` - Tier calculation
- Badge awarding logic

**Focus Areas**:
- Proof replay prevention
- Score overflow protection
- Badge storage efficiency
- Access control

### Paymaster.sol

**High Priority**:
- `validatePaymasterUserOp()` - Eligibility
- `postOp()` - Gas payment
- `isEligible()` - Eligibility checks

**Focus Areas**:
- Eligibility enforcement
- Gas payment logic
- EntryPoint integration
- Deposit management

---

## Security Considerations

### 1. Economic Security

**Staking/Slashing**:
- Minimum stake enforcement
- Slashing amount validation
- Fee calculation correctness
- Partial slashing handling

**Test Cases**:
- Claim > stake amount
- Multiple claims
- Fee calculation edge cases

### 2. Access Control

**Roles**:
- `DEFAULT_ADMIN_ROLE`: Protocol admin
- `ZK_PROVER_ROLE`: ZK coprocessors
- `ORACLE_ROLE`: Oracles

**Test Cases**:
- Unauthorized access attempts
- Role escalation
- Multi-sig considerations

### 3. Reentrancy

**Protected Functions**:
- All external functions in InsuranceVault
- Paymaster.postOp()
- All token transfer functions

**Test Cases**:
- Reentrancy attack scenarios
- Cross-function reentrancy
- External call ordering

### 4. Input Validation

**Validations**:
- Zero address checks
- Amount > 0 checks
- Bounds checking
- Token existence

**Test Cases**:
- Zero address inputs
- Zero amounts
- Invalid token IDs
- Overflow/underflow

### 5. Proof Replay

**Protection**:
- `_verifiedProofs` mapping
- Hash-based tracking

**Test Cases**:
- Same proof twice
- Different proofs same type
- Proof hash collisions

---

## Test Suite

### Running Tests

```bash
# All tests
forge test -vvv

# Security tests
forge test --match-path test/security/

# Specific contract
forge test --match-contract InsuranceVaultTest

# With gas report
forge test --gas-report
```

### Test Coverage

```bash
forge coverage
```

**Target**: 90%+ coverage

---

## Known Issues

### Documented Limitations

1. **ZK Proof Verification**: Trusts coprocessor (future: on-chain)
2. **Oracle Trust**: Single oracle (future: multi-oracle)
3. **Admin Centralization**: Single admin (future: multi-sig)
4. **No Timelock**: Immediate parameter changes (future: timelock)

### Fixed Issues

1. ✅ Proof replay prevention (added)
2. ✅ Fee withdrawal logic (fixed)
3. ✅ Paymaster gas payment (fixed)
4. ✅ Redundant storage (optimized)

---

## Attack Vectors to Consider

### 1. Economic Attacks

- **Stake Manipulation**: Can agents manipulate stake amounts?
- **Fee Manipulation**: Can fees be manipulated?
- **Slashing Griefing**: Can malicious claims drain stakes?

### 2. Access Control Attacks

- **Role Escalation**: Can users gain unauthorized roles?
- **Admin Compromise**: What if admin key is compromised?
- **Oracle Manipulation**: Can oracles be manipulated?

### 3. Reentrancy Attacks

- **Cross-Function**: Reentrancy across functions
- **External Calls**: Reentrancy via external contracts
- **State Consistency**: State updates before external calls

### 4. Logic Errors

- **Edge Cases**: Zero amounts, max values, etc.
- **Race Conditions**: Concurrent operations
- **Integer Overflow**: Arithmetic operations

### 5. Integration Attacks

- **EntryPoint**: ERC-4337 integration issues
- **ZK Proofs**: Proof verification issues
- **Oracles**: Oracle resolution issues

---

## Documentation

### Key Documents

1. **SECURITY.md**: Security considerations and mitigations
2. **AUDIT_SCOPE.md**: Detailed audit scope
3. **INTEGRATIONS.md**: External service integrations
4. **DEPLOYMENT.md**: Deployment procedures

### Code Documentation

- Inline comments on all functions
- NatSpec documentation
- Security considerations in comments

---

## Tools & Resources

### Recommended Tools

1. **Slither**: Static analysis
2. **Mythril**: Symbolic execution
3. **Foundry**: Testing and fuzzing
4. **Echidna**: Property-based testing

### Running Security Analysis

```bash
# Run security analysis script
./script/security-analysis.sh

# Run security checklist
./script/security-checklist.sh
```

---

## Questions & Support

### Technical Questions

- **Code Questions**: Review inline comments and documentation
- **Design Questions**: See SECURITY.md and architecture docs
- **Integration Questions**: See INTEGRATIONS.md

### Contact

- **Primary Contact**: [To be provided]
- **Security Contact**: security@kya.protocol
- **Response Time**: 24-48 hours

---

## Audit Deliverables

### Expected Deliverables

1. **Security Report**
   - Executive summary
   - Detailed findings
   - Severity classification
   - Recommendations

2. **Code Review**
   - Line-by-line review
   - Logic analysis
   - Edge case identification

3. **Attack Scenarios**
   - Potential attacks
   - Exploit scenarios
   - Proof of concept (if applicable)

### Severity Guidelines

- **Critical**: Loss of funds, permanent DoS
- **High**: Significant fund loss, access control bypass
- **Medium**: Minor fund loss, logic errors
- **Low**: Code quality, optimizations

---

## Additional Resources

### External References

- **ERC-6551**: Token Bound Accounts standard
- **ERC-4337**: Account Abstraction standard
- **OpenZeppelin**: Security best practices
- **Axiom**: ZK coprocessor documentation
- **UMA**: Oracle documentation

### Internal Resources

- Test suite: `test/`
- Deployment scripts: `script/`
- Documentation: `docs/`

---

**Last Updated**: 2026-01-06  
**Status**: Ready for Audit

