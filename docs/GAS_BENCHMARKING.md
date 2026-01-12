# Gas Benchmarking Guide

**Purpose**: Document gas usage for key operations and track optimization improvements.

---

## Key Operations

### InsuranceVault Operations

| Operation | Expected Gas | Notes |
|-----------|--------------|-------|
| `stake()` | ~150k | First stake includes TBA address caching |
| `unstake()` | ~120k | Includes cooldown check |
| `submitClaim()` | ~100k | Claim creation |
| `resolveClaim()` | ~80k | Includes slashing logic |
| `withdrawFees()` | ~60k | Fee withdrawal |

### ReputationScore Operations

| Operation | Expected Gas | Notes |
|-----------|--------------|-------|
| `verifyProof()` | ~100k | Includes proof replay check, badge awarding |
| `getReputation()` | ~5k | View function |
| `getTier()` | ~2k | Pure function |
| `getBadges()` | ~10k | View function (depends on badge count) |
| `hasBadge()` | ~5k | View function |

### Paymaster Operations

| Operation | Expected Gas | Notes |
|-----------|--------------|-------|
| `validatePaymasterUserOp()` | ~50k | Eligibility checks |
| `postOp()` | ~30k | Gas payment tracking |

---

## Generating Gas Reports

### Basic Gas Report

```bash
# Generate gas report for all tests
forge test --gas-report > gas_report.txt

# View report
cat gas_report.txt
```

### Specific Operation Reports

```bash
# Staking operations
forge test --gas-report --match-test test_stake

# Proof verification
forge test --gas-report --match-test test_verifyProof

# Claim operations
forge test --gas-report --match-test test_submitClaim
```

### Detailed Analysis

```bash
# Run with maximum verbosity to see gas per operation
forge test --gas-report -vvv > detailed_gas_report.txt
```

---

## Optimization Targets

### Achieved Optimizations

1. **Struct Packing**
   - `ReputationData`: 5 slots → 3 slots (40% reduction)
   - `StakeInfo`: Removed redundant `tokenId` field

2. **Storage Optimization**
   - Badge storage: `string` → `bytes32` (gas efficient)
   - TBA address caching (avoids repeated lookups)

3. **Code Optimization**
   - Removed duplicate `execute()` functions
   - Consolidated logic into internal functions

### Expected Gas Savings

- **Staking**: ~10-15% reduction from TBA caching
- **Proof Verification**: ~5-10% reduction from struct packing
- **Badge Operations**: ~20-30% reduction from bytes32 storage

---

## Benchmarking Process

### 1. Baseline Measurement

```bash
# Run baseline tests
forge test --gas-report --match-test test_stake > baseline_stake.txt
forge test --gas-report --match-test test_verifyProof > baseline_proof.txt
```

### 2. Post-Optimization Measurement

```bash
# Run after optimizations
forge test --gas-report --match-test test_stake > optimized_stake.txt
forge test --gas-report --match-test test_verifyProof > optimized_proof.txt
```

### 3. Compare Results

```bash
# Compare gas usage
diff baseline_stake.txt optimized_stake.txt
```

---

## Gas Report Analysis

### Understanding Gas Report Output

```
| Function Name          | min    | avg    | median | max    | # calls |
|------------------------|--------|--------|--------|--------|---------|
| InsuranceVault.stake   | 145234 | 150123 | 150000 | 155000 | 10      |
```

- **min**: Minimum gas used
- **avg**: Average gas used
- **median**: Median gas used
- **max**: Maximum gas used
- **# calls**: Number of times function was called

### Key Metrics to Track

1. **Average Gas Usage**: Primary metric for optimization
2. **Maximum Gas Usage**: Important for worst-case scenarios
3. **Gas Variance**: High variance may indicate optimization opportunities

---

## Optimization Opportunities

### High Gas Operations

1. **Storage Writes**: Most expensive operations
   - Minimize storage writes
   - Use events for non-critical data
   - Pack structs efficiently

2. **External Calls**: Can be expensive
   - Batch operations when possible
   - Cache results when appropriate

3. **Loops**: Can accumulate gas costs
   - Bound loop iterations
   - Consider gas limits

### Low-Hanging Fruit

1. **View Functions**: Already optimized (no gas cost for view)
2. **Pure Functions**: No gas cost
3. **Events**: Cheap alternative to storage

---

## Continuous Monitoring

### Pre-Deployment

- [ ] Generate gas report
- [ ] Compare with targets
- [ ] Document any deviations
- [ ] Optimize if needed

### Post-Deployment

- [ ] Monitor actual gas usage on-chain
- [ ] Compare with testnet benchmarks
- [ ] Track gas price trends
- [ ] Optimize based on real usage

---

## Gas Optimization Checklist

- [ ] Struct packing optimized
- [ ] Storage writes minimized
- [ ] External calls batched
- [ ] Loops bounded
- [ ] View functions used where appropriate
- [ ] Events used instead of storage when possible
- [ ] Gas benchmarks documented
- [ ] Optimization targets met

---

## Next Steps

1. Run gas benchmarks
2. Compare with targets
3. Identify optimization opportunities
4. Implement optimizations
5. Re-benchmark
6. Document improvements

---

**Last Updated**: 2026-01-06

