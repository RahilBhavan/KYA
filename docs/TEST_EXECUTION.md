# Test Execution Guide

**Purpose**: Comprehensive guide for running and verifying all tests in the KYA Protocol test suite.

---

## Quick Start

### Run All Tests

```bash
# Run all tests with verbose output
forge test -vvv

# Run with gas reporting
forge test --gas-report

# Run with coverage
forge coverage
```

### Automated Test Execution

```bash
# Run Phase 1 testing script (includes all test types)
./script/Phase1Testing.sh
```

---

## Test Suite Structure

### Test Categories

1. **Unit Tests** (`test/unit/`)
   - `InsuranceVault.t.sol` - Staking, slashing, claims
   - `ReputationScore.t.sol` - Proof verification, badges, tiers
   - `Paymaster.t.sol` - Gas sponsorship, eligibility
   - `MerchantSDK.t.sol` - Merchant verification

2. **Integration Tests** (`test/integration/`)
   - `FullFlow.t.sol` - End-to-end agent lifecycle
   - `ZKProofIntegration.t.sol` - ZK coprocessor integration
   - `OracleIntegration.t.sol` - Oracle integration
   - `PaymasterIntegration.t.sol` - ERC-4337 integration
   - `AdapterIntegration.t.sol` - Integration adapters

3. **Fuzz Tests** (`test/fuzz/`)
   - `InsuranceVaultFuzz.t.sol` - Random stake/claim amounts
   - `ReputationScoreFuzz.t.sol` - Random proof types/scores
   - `PaymasterFuzz.t.sol` - Random eligibility parameters

4. **Invariant Tests** (`test/invariant/`)
   - `ProtocolInvariants.t.sol` - Protocol-level invariants

5. **Security Tests** (`test/security/`)
   - `SecurityTest.sol` - Security-focused tests

---

## Running Specific Test Suites

### Unit Tests

```bash
# Run all unit tests
forge test --match-path test/unit/

# Run specific contract tests
forge test --match-path test/unit/InsuranceVault.t.sol
forge test --match-path test/unit/ReputationScore.t.sol
forge test --match-path test/unit/Paymaster.t.sol
```

### Integration Tests

```bash
# Run all integration tests
forge test --match-path test/integration/

# Run specific integration test
forge test --match-path test/integration/FullFlow.t.sol
```

### Fuzz Tests

```bash
# Run all fuzz tests
forge test --match-path test/fuzz/

# Run with more fuzz runs
forge test --match-path test/fuzz/ --fuzz-runs 1000
```

### Invariant Tests

```bash
# Run invariant tests
forge test --match-path test/invariant/
```

### Security Tests

```bash
# Run security tests
forge test --match-path test/security/
```

---

## Test Execution Output

### Verbose Levels

```bash
# Minimal output
forge test

# Verbose (shows test names)
forge test -v

# Very verbose (shows logs)
forge test -vv

# Very very verbose (shows traces)
forge test -vvv

# Very very very verbose (shows stack traces)
forge test -vvvv
```

### Understanding Output

- **✓** - Test passed
- **✗** - Test failed
- **⚠** - Test skipped or warning

---

## Gas Reporting

### Generate Gas Report

```bash
# Generate gas report for all tests
forge test --gas-report > gas_report.txt

# Generate gas report for specific tests
forge test --gas-report --match-test test_stake
```

### Key Operations to Monitor

- `stake()` - Staking operation
- `unstake()` - Unstaking operation
- `verifyProof()` - ZK proof verification
- `submitClaim()` - Claim submission
- `resolveClaim()` - Claim resolution
- `awardBadge()` - Badge awarding

### Expected Gas Costs

Based on optimizations:
- `stake()`: ~150k gas
- `unstake()`: ~120k gas
- `verifyProof()`: ~100k gas
- `submitClaim()`: ~100k gas
- `resolveClaim()`: ~80k gas

---

## Coverage Analysis

### Generate Coverage Report

```bash
# Generate coverage report
forge coverage

# Generate with script (includes HTML report)
./script/coverage.sh
```

### Coverage Targets

- **Overall**: 90%+ coverage
- **Critical Functions**: 100% coverage
  - `stake()`, `unstake()`, `_slash()`
  - `verifyProof()`, `getTier()`
  - `validatePaymasterUserOp()`, `postOp()`

### View Coverage Report

```bash
# If HTML report generated
open coverage-report/index.html

# View LCOV report
cat coverage.lcov
```

---

## Fixing Test Failures

### Common Issues

#### 1. Type Mismatches

**Issue**: `getTier()` expects `uint224` but test passes `uint256`

**Fix**: Cast to `uint224`:
```solidity
uint8 tier = reputationScore.getTier(uint224(score));
```

#### 2. Struct Changes

**Issue**: `StakeInfo` struct changed (removed `tokenId`)

**Fix**: Update assertions to not check `tokenId`:
```solidity
// OLD (incorrect)
assertEq(stakeInfo.tokenId, tokenId, "Token ID incorrect");

// NEW (correct)
assertGt(stakeInfo.amount, 0, "Stake should exist");
```

#### 3. Badge Storage Changes

**Issue**: Badges stored as `bytes32` internally

**Fix**: Tests should use string names (contract handles conversion):
```solidity
// This still works - contract converts internally
bool hasBadge = reputationScore.hasBadge(tokenId, "Uniswap Trader");
```

#### 4. Proof Replay Prevention

**Issue**: Same proof cannot be verified twice

**Fix**: Use different proof data for each verification:
```solidity
bytes memory proof1 = abi.encode("proof-1");
bytes memory proof2 = abi.encode("proof-2");
```

### Debugging Failed Tests

```bash
# Run specific test with maximum verbosity
forge test --match-test test_stake_success -vvvv

# Run with debugger
forge test --match-test test_stake_success --debug
```

---

## Test Execution Checklist

### Pre-Execution

- [ ] Contracts compile: `forge build`
- [ ] Dependencies installed: `forge install`
- [ ] Test environment configured

### Execution

- [ ] Run all tests: `forge test -vvv`
- [ ] Run unit tests: `forge test --match-path test/unit/`
- [ ] Run integration tests: `forge test --match-path test/integration/`
- [ ] Run fuzz tests: `forge test --match-path test/fuzz/`
- [ ] Run invariant tests: `forge test --match-path test/invariant/`
- [ ] Run security tests: `forge test --match-path test/security/`

### Post-Execution

- [ ] All tests passing
- [ ] Gas report generated
- [ ] Coverage report generated
- [ ] Coverage meets 90%+ target
- [ ] Test failures documented
- [ ] Fixes implemented

---

## Continuous Integration

### GitHub Actions

Tests are automatically run in CI/CD:
- On every pull request
- On every push to main
- Coverage must meet 90% threshold
- All tests must pass

### Local CI Simulation

```bash
# Simulate CI environment
forge test
forge coverage
./script/security-checklist.sh
```

---

## Test Data and Fixtures

### Test Constants

Located in `test/helpers/TestConstants.sol`:
- Staking amounts
- Tier thresholds
- Test addresses
- Proof types
- Badge names

### Test Utilities

Located in `test/helpers/TestUtils.sol`:
- `assertStakeInfo()` - Stake info assertions
- `assertReputationData()` - Reputation assertions
- `createAgentMetadata()` - Agent metadata creation
- `createProofData()` - Proof data creation

### Base Test Contract

Located in `test/BaseTest.sol`:
- Common setup
- Mock contracts
- Test accounts
- Helper functions

---

## Integration Test Setup

### ZK Coprocessor Integration

For real Axiom/Brevis integration:
1. Set up testnet accounts
2. Get API keys
3. Configure environment variables
4. Update test files with real API endpoints

### Oracle Integration

For real UMA/Kleros integration:
1. Set up testnet accounts
2. Get oracle addresses
3. Configure environment variables
4. Update test files with real oracle contracts

### ERC-4337 EntryPoint

For real EntryPoint integration:
1. Use existing EntryPoint on testnet
2. Configure Paymaster address
3. Test with real user operations

---

## Troubleshooting

### Tests Not Running

**Issue**: `forge` command not found

**Solution**: Install Foundry:
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Compilation Errors

**Issue**: Type mismatches or missing imports

**Solution**: 
- Check Solidity version (0.8.28)
- Verify imports are correct
- Check for type casting issues

### Test Timeouts

**Issue**: Tests taking too long

**Solution**:
- Reduce fuzz runs: `--fuzz-runs 100`
- Run specific test suites
- Check for infinite loops

### Coverage Issues

**Issue**: Coverage below 90%

**Solution**:
- Identify uncovered functions
- Add tests for missing coverage
- Test error cases and edge cases

---

## Best Practices

1. **Run tests frequently** during development
2. **Fix failures immediately** before they accumulate
3. **Maintain 90%+ coverage** for all contracts
4. **Test edge cases** and error conditions
5. **Use descriptive test names** that explain what's being tested
6. **Keep tests independent** - each test should be able to run alone
7. **Use fixtures and helpers** to reduce duplication
8. **Document complex test logic** with comments

---

## Next Steps

After all tests pass:

1. Review gas report for optimizations
2. Verify coverage meets targets
3. Document any test failures and fixes
4. Proceed to external integrations
5. Prepare for security audit

---

**Last Updated**: 2026-01-06

