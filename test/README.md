# KYA Protocol Test Suite

## Overview

This directory contains comprehensive tests for the KYA Protocol v2.0 contracts, including unit tests, integration tests, fuzz tests, and invariant tests.

## Test Structure

```
test/
├── BaseTest.sol                    # Base test contract with common setup
├── helpers/
│   ├── MockERC20.sol              # Mock USDC token
│   ├── MockEntryPoint.sol         # Mock ERC-4337 EntryPoint
│   ├── TestConstants.sol          # Test constants
│   └── TestUtils.sol               # Test utility functions
├── unit/
│   ├── InsuranceVault.t.sol       # InsuranceVault unit tests
│   ├── ReputationScore.t.sol      # ReputationScore unit tests
│   ├── Paymaster.t.sol            # Paymaster unit tests
│   └── MerchantSDK.t.sol           # MerchantSDK unit tests
├── integration/
│   ├── FullFlow.t.sol             # End-to-end flow tests
│   ├── ZKProofIntegration.t.sol   # Axiom/Brevis integration
│   ├── OracleIntegration.t.sol    # UMA/Kleros integration
│   └── PaymasterIntegration.t.sol  # ERC-4337 integration
├── fuzz/
│   ├── InsuranceVaultFuzz.t.sol   # InsuranceVault fuzz tests
│   ├── ReputationScoreFuzz.t.sol  # ReputationScore fuzz tests
│   └── PaymasterFuzz.t.sol        # Paymaster fuzz tests
└── invariant/
    └── ProtocolInvariants.t.sol   # Protocol-level invariants
```

## Running Tests

### Run All Tests

```bash
forge test
```

### Run Specific Test File

```bash
forge test --match-path test/unit/InsuranceVault.t.sol
```

### Run with Verbosity

```bash
forge test -vvv  # Very verbose
```

### Run Fuzz Tests

```bash
forge test --fuzz-runs 1000
```

### Run Invariant Tests

```bash
forge test --match-path test/invariant/
```

### Run with Gas Reporting

```bash
forge test --gas-report
```

## Coverage

### Generate Coverage Report

```bash
forge coverage
```

### Generate Coverage with Script

```bash
./script/coverage.sh
```

This will:
- Run all tests with coverage
- Generate LCOV report
- Generate HTML report (if genhtml installed)
- Check if coverage meets 90% threshold

### View Coverage Report

If HTML report is generated:
```bash
open coverage-report/index.html
```

## Coverage Requirements

- **Target**: 90%+ coverage across all v2.0 contracts
- **Contracts**: InsuranceVault, ReputationScore, Paymaster, MerchantSDK
- **Exclusions**: Test files, mocks, and scripts are excluded

## Test Categories

### Unit Tests

Test individual contract functions in isolation:
- Staking/unstaking flows
- Claim submission and resolution
- Proof verification
- Eligibility checks
- Access control

### Integration Tests

Test interactions between contracts:
- Full agent lifecycle
- ZK proof integration (Axiom/Brevis)
- Oracle integration (UMA/Kleros)
- ERC-4337 Paymaster integration

### Fuzz Tests

Test with random inputs to find edge cases:
- Random stake amounts
- Random claim amounts
- Random proof types
- Random eligibility parameters

### Invariant Tests

Test protocol-level invariants:
- Verified agents always have minimum stake
- Claim amounts never exceed stake
- Reputation scores only increase
- Badge count <= proof count

## Integration Test Setup

### Axiom/Brevis

For real ZK proof integration:
1. Set up Axiom/Brevis test environment
2. Configure API keys in environment
3. Update test files with real API endpoints

### UMA/Kleros

For real oracle integration:
1. Set up UMA/Kleros test environment
2. Configure oracle addresses
3. Update test files with real oracle contracts

### ERC-4337 EntryPoint

For real EntryPoint integration:
1. Deploy or use existing EntryPoint
2. Update Paymaster with EntryPoint address
3. Test with real user operations

## Writing New Tests

### Test Template

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../BaseTest.sol";

contract MyTest is BaseTest {
    function setUp() public override {
        super.setUp();
        // Additional setup
    }

    function test_myFunction() public {
        // Test implementation
    }
}
```

### Best Practices

1. Use `BaseTest` for common setup
2. Use `TestConstants` for test values
3. Use `TestUtils` for helper functions
4. Test both success and failure cases
5. Test edge cases and boundary conditions
6. Use descriptive test names
7. Add comments for complex test logic

## Troubleshooting

### Tests Failing

1. Check contract addresses are correct
2. Verify roles are granted properly
3. Ensure sufficient balances for operations
4. Check time-dependent tests (use `vm.warp`)

### Coverage Issues

1. Ensure all functions are called in tests
2. Test both branches of conditionals
3. Test error cases (reverts)
4. Test edge cases

### Integration Test Issues

1. Verify external services are accessible
2. Check API keys and credentials
3. Ensure test environment is configured
4. Use mocks if real integration unavailable

## Continuous Integration

Tests are automatically run in CI/CD:
- On every pull request
- Coverage must meet 90% threshold
- All tests must pass

See `.github/workflows/test.yml` for CI configuration.

