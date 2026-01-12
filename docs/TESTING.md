# Testing Documentation

## Overview

The KYA Protocol test suite provides comprehensive coverage of all v2.0 contracts through unit tests, integration tests, fuzz tests, and invariant tests.

## Test Structure

### Test Organization

```
test/
├── BaseTest.sol                    # Base test contract
├── helpers/                        # Test utilities
│   ├── MockERC20.sol
│   ├── MockEntryPoint.sol
│   ├── TestConstants.sol
│   └── TestUtils.sol
├── unit/                          # Unit tests
│   ├── InsuranceVault.t.sol
│   ├── ReputationScore.t.sol
│   ├── Paymaster.t.sol
│   └── MerchantSDK.t.sol
├── integration/                   # Integration tests
│   ├── FullFlow.t.sol
│   ├── ZKProofIntegration.t.sol
│   ├── OracleIntegration.t.sol
│   └── PaymasterIntegration.t.sol
├── fuzz/                         # Fuzz tests
│   ├── InsuranceVaultFuzz.t.sol
│   ├── ReputationScoreFuzz.t.sol
│   └── PaymasterFuzz.t.sol
└── invariant/                    # Invariant tests
    └── ProtocolInvariants.t.sol
```

## Running Tests

### Basic Commands

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run specific test file
forge test --match-path test/unit/InsuranceVault.t.sol

# Run specific test function
forge test --match-test test_stake_success

# Run fuzz tests
forge test --fuzz-runs 1000

# Run with gas reporting
forge test --gas-report
```

### Coverage

```bash
# Generate coverage report
forge coverage

# Generate with script (includes threshold check)
./script/coverage.sh

# View HTML report (if generated)
open coverage-report/index.html
```

## Test Categories

### Unit Tests

Test individual contract functions in isolation:

- **InsuranceVault**: Staking, unstaking, claims, slashing, access control
- **ReputationScore**: Proof verification, tier system, badges, admin functions
- **Paymaster**: Eligibility, validation, funding, Twitter verification
- **MerchantSDK**: Verification, requirements checking, violation reporting

### Integration Tests

Test interactions between contracts and external services:

- **FullFlow**: Complete agent lifecycle from minting to slashing
- **ZKProofIntegration**: Axiom/Brevis proof generation and verification
- **OracleIntegration**: UMA/Kleros dispute resolution
- **PaymasterIntegration**: ERC-4337 EntryPoint interaction

### Fuzz Tests

Test with random inputs to find edge cases:

- Random stake amounts, claim amounts, proof types
- Boundary conditions and overflow scenarios
- Invalid input handling

### Invariant Tests

Test protocol-level properties that must always hold:

- Verified agents always have minimum stake
- Claim amounts never exceed stake amounts
- Reputation scores only increase
- Badge count <= proof count
- Paymaster sponsored count <= MAX_SPONSORED_TXS

## Coverage Requirements

### Target Coverage

- **Overall**: 90%+ coverage across all v2.0 contracts
- **Critical Functions**: 100% coverage for security-critical functions
- **Public Functions**: 95%+ coverage for all public/external functions

### Coverage Exclusions

The following are excluded from coverage:
- Test files (`test/**/*`)
- Scripts (`script/**/*`)
- Mock contracts (`**/Mock*.sol`)
- Helper contracts (`**/Test*.sol`)

### Checking Coverage

```bash
# Generate coverage report
forge coverage

# Check coverage percentage
forge coverage --report summary

# Fail if below threshold
./script/coverage.sh
```

## Writing New Tests

### Test Template

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../BaseTest.sol";
import {TestConstants} from "../helpers/TestConstants.sol";

contract MyTest is BaseTest {
    function setUp() public override {
        super.setUp();
        // Additional setup
    }

    function test_myFunction() public {
        // Arrange
        // Act
        // Assert
    }
}
```

### Best Practices

1. **Use BaseTest**: Inherit from `BaseTest` for common setup
2. **Use Constants**: Use `TestConstants` for test values
3. **Use Helpers**: Use `TestUtils` for common operations
4. **Test Both Paths**: Test success and failure cases
5. **Test Edge Cases**: Test boundary conditions
6. **Descriptive Names**: Use clear, descriptive test names
7. **Comments**: Add comments for complex test logic
8. **Isolation**: Each test should be independent

### Example Test

```solidity
function test_stake_success() public {
    // Arrange
    uint256 stakeAmount = TestConstants.MINIMUM_STAKE;
    fundTBA(tbaAddress, stakeAmount * 2);

    // Act
    vm.prank(user1);
    IAgentAccount(tbaAddress).execute(
        address(mockUSDC),
        0,
        abi.encodeWithSignature("approve(address,uint256)", address(insuranceVault), stakeAmount)
    );

    vm.prank(user1);
    IAgentAccount(tbaAddress).execute(
        address(insuranceVault),
        0,
        abi.encodeWithSignature("stake(uint256,uint256)", tokenId, stakeAmount)
    );

    // Assert
    assertTrue(insuranceVault.isVerified(tokenId), "Agent should be verified");
}
```

## Integration Test Setup

### Axiom/Brevis

For real ZK proof integration:

1. Set up Axiom/Brevis test environment
2. Configure API keys in environment variables
3. Update test files with real API endpoints
4. Test proof generation and verification

### UMA/Kleros

For real oracle integration:

1. Set up UMA/Kleros test environment
2. Configure oracle addresses
3. Update test files with real oracle contracts
4. Test dispute resolution flow

### ERC-4337 EntryPoint

For real EntryPoint integration:

1. Deploy or use existing EntryPoint
2. Update Paymaster with EntryPoint address
3. Test with real user operations
4. Verify gas sponsorship

## Troubleshooting

### Common Issues

**Tests Failing**:
- Check contract addresses are correct
- Verify roles are granted properly
- Ensure sufficient balances
- Check time-dependent tests (use `vm.warp`)

**Coverage Issues**:
- Ensure all functions are called
- Test both branches of conditionals
- Test error cases (reverts)
- Test edge cases

**Integration Test Issues**:
- Verify external services are accessible
- Check API keys and credentials
- Ensure test environment is configured
- Use mocks if real integration unavailable

### Debugging Tips

```bash
# Run with maximum verbosity
forge test -vvvv

# Run specific test with verbosity
forge test --match-test test_stake_success -vvv

# Use debugger
forge test --debug <test_name>

# Check gas usage
forge test --gas-report
```

## Continuous Integration

Tests are automatically run in CI/CD:

- **On PR**: All tests run, coverage checked
- **On Push**: Tests run, coverage uploaded
- **On Tag**: Tests run, deployment triggered

See `.github/workflows/test.yml` for CI configuration.

## Coverage Reports

Coverage reports are generated in multiple formats:

- **LCOV**: `coverage.lcov` (for codecov)
- **HTML**: `coverage-report/` (if genhtml installed)
- **Summary**: Console output with percentages

## Next Steps

1. Run tests locally: `forge test`
2. Check coverage: `forge coverage`
3. Write new tests for uncovered code
4. Update tests when adding features
5. Review coverage reports regularly

