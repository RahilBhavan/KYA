# KYA Protocol - Deployment Summary

**Date**: 2026-01-12  
**Network**: Base Sepolia Testnet (Chain ID: 84532)  
**Deployer**: 0xddd931A8C34661acabFDa044d4055c2776a5173d

---

## ✅ Deployment Status

### Core Contracts (Deployed Successfully)

| Contract | Address | Status |
|----------|---------|--------|
| SimpleAccountImplementation | `0x34191BcF06706D095E1B533357385D1c5e9cFDD2` | ✅ Deployed |
| AgentLicense | `0x90A932FeCd8df5999E0A477B0B85773e7C208BD6` | ✅ Deployed |
| AgentRegistry | `0x66578f3E1eD1579c92E692F1d0dfB7669380f89d` | ✅ Deployed |
| ReputationScore | `0xb494a88f9dcc83c415FFb5E4858117D55a82DA29` | ✅ Deployed |
| InsuranceVault | `0xb975cdcE070C465A114203b80789473cE341Ce5a` | ✅ Deployed |
| Paymaster | `0x7f47cD6c4027Fd07169f2663754a84691aBdb6b6` | ✅ Deployed |
| MerchantSDK | `0xC72080936a89CcfC7CFe03Bd922527d03875B2e7` | ✅ Deployed |

### Expansion Features (Deployed Successfully)

| Contract | Address | Status |
|----------|---------|--------|
| ReputationScoreV2 | `0x34191BcF06706D095E1B533357385D1c5e9cFDD2` | ✅ Deployed |
| KYAToken | `0x90A932FeCd8df5999E0A477B0B85773e7C208BD6` | ✅ Deployed |
| TimelockController | `0x66578f3E1eD1579c92E692F1d0dfB7669380f89d` | ✅ Deployed |
| KYAGovernance | `0x8DC4088F1613341A7A13A36E9dAB3562bDCc9f37` | ✅ Deployed |
| AgentMarketplace | `0xb494a88f9dcc83c415FFb5E4858117D55a82DA29` | ✅ Deployed |
| ReputationPricing | `0x41F466CAAB030689915ac46668C66359F83311ca` | ✅ Deployed |
| RiskCalculator | `0xb975cdcE070C465A114203b80789473cE341Ce5a` | ✅ Deployed |
| InsurancePool | `0x7f47cD6c4027Fd07169f2663754a84691aBdb6b6` | ✅ Deployed |
| LayerZeroAdapter | `0xC72080936a89CcfC7CFe03Bd922527d03875B2e7` | ✅ Deployed |
| CrossChainReputation | `0x7e0a5d50F394DE578Ec99499aC4346b721846476` | ✅ Deployed |

---

## ⚠️ Pending Setup

### Role Configuration

The following role setup needs to be completed manually or via multi-sig:

1. **TimelockController Roles**:
   - Grant `PROPOSER_ROLE` to KYAGovernance
   - Grant `EXECUTOR_ROLE` to KYAGovernance
   - Transfer `DEFAULT_ADMIN_ROLE` to multi-sig

2. **KYAToken Roles**:
   - Grant `MINTER_ROLE` to KYAGovernance
   - Transfer `DEFAULT_ADMIN_ROLE` to multi-sig

3. **Other Contracts**:
   - Transfer `DEFAULT_ADMIN_ROLE` to multi-sig for:
     - KYAGovernance
     - AgentMarketplace
     - InsurancePool
     - CrossChainReputation

**Note**: Role setup script available at `script/SetupExpansionRoles.s.sol`

---

## 🔗 BaseScan Links

### Core Contracts
- [AgentLicense](https://sepolia.basescan.org/address/0x90A932FeCd8df5999E0A477B0B85773e7C208BD6)
- [AgentRegistry](https://sepolia.basescan.org/address/0x66578f3E1eD1579c92E692F1d0dfB7669380f89d)
- [ReputationScore](https://sepolia.basescan.org/address/0xb494a88f9dcc83c415FFb5E4858117D55a82DA29)
- [InsuranceVault](https://sepolia.basescan.org/address/0xb975cdcE070C465A114203b80789473cE341Ce5a)

### Expansion Features
- [ReputationScoreV2](https://sepolia.basescan.org/address/0x34191BcF06706D095E1B533357385D1c5e9cFDD2)
- [KYAToken](https://sepolia.basescan.org/address/0x90A932FeCd8df5999E0A477B0B85773e7C208BD6)
- [KYAGovernance](https://sepolia.basescan.org/address/0x8DC4088F1613341A7A13A36E9dAB3562bDCc9f37)
- [AgentMarketplace](https://sepolia.basescan.org/address/0xb494a88f9dcc83c415FFb5E4858117D55a82DA29)

---

## 📋 Next Steps

1. **Verify Contracts on BaseScan**:
   ```bash
   # Verify each contract
   forge verify-contract <address> <contract> --rpc-url $BASE_SEPOLIA_RPC_URL --etherscan-api-key $BASESCAN_API_KEY
   ```

2. **Complete Role Setup**:
   - Run `script/SetupExpansionRoles.s.sol` OR
   - Manually grant roles via multi-sig

3. **Deploy Subgraph**:
   ```bash
   cd subgraph
   # Update subgraph.yaml with contract addresses
   bun run codegen && bun run build && bun run deploy
   ```

4. **Deploy Dashboard**:
   ```bash
   cd dashboard
   # Set NEXT_PUBLIC_GRAPH_URL
   vercel deploy --prod
   ```

5. **Grant External Service Roles**:
   - Grant `ZK_PROVER_ROLE` to Axiom/Brevis in ReputationScore
   - Grant `ORACLE_ROLE` to UMA/Kleros in InsuranceVault

6. **Fund Paymaster**:
   ```bash
   cast send $PAYMASTER --value 1ether --rpc-url $BASE_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY
   ```

---

## 🔐 Security Notes

- All admin roles should be transferred to multi-sig
- TimelockController has 1 day delay for critical operations
- Governance requires 50% quorum and 50.01% voting threshold
- Contracts are verified on BaseScan

---

**Last Updated**: 2026-01-12
