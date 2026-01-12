// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {AgentLicense} from "../src/AgentLicense.sol";
import {AgentRegistry} from "../src/AgentRegistry.sol";
import {ReputationScore} from "../src/ReputationScore.sol";
import {InsuranceVault} from "../src/InsuranceVault.sol";
import {Paymaster} from "../src/Paymaster.sol";
import {MerchantSDK} from "../src/MerchantSDK.sol";
import {ZKAdapter} from "../src/integrations/ZKAdapter.sol";
import {OracleAdapter} from "../src/integrations/OracleAdapter.sol";

/**
 * @title VerifyMultisigSetup
 * @notice Verifies multi-sig setup and admin role configuration
 * @dev Run with: forge script script/VerifyMultisigSetup.s.sol --rpc-url $RPC_URL
 */
contract VerifyMultisigSetup is Script {
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    function run() external view {
        address multisigAddress = vm.envAddress("MULTISIG_ADDRESS");
        address deployerAddress = vm.envAddress("DEPLOYER_ADDRESS");

        console.log("========================================");
        console.log("Multi-sig Setup Verification");
        console.log("========================================");
        console.log("Multi-sig:", multisigAddress);
        console.log("Deployer:", deployerAddress);
        console.log("");

        bool allVerified = true;

        // Verify AgentLicense
        address agentLicenseAddr = vm.envAddress("AGENT_LICENSE_ADDRESS");
        if (agentLicenseAddr != address(0)) {
            AgentLicense agentLicense = AgentLicense(agentLicenseAddr);
            bool multisigHasRole = agentLicense.hasRole(DEFAULT_ADMIN_ROLE, multisigAddress);
            bool deployerHasRole = agentLicense.hasRole(DEFAULT_ADMIN_ROLE, deployerAddress);
            
            console.log("AgentLicense:");
            console.log("  Multi-sig has admin:", multisigHasRole);
            console.log("  Deployer has admin:", deployerHasRole);
            
            if (!multisigHasRole || deployerHasRole) {
                console.log("  ❌ FAILED");
                allVerified = false;
            } else {
                console.log("  ✅ PASSED");
            }
            console.log("");
        }

        // Verify AgentRegistry
        address agentRegistryAddr = vm.envAddress("AGENT_REGISTRY_ADDRESS");
        if (agentRegistryAddr != address(0)) {
            AgentRegistry agentRegistry = AgentRegistry(agentRegistryAddr);
            bool multisigHasRole = agentRegistry.hasRole(DEFAULT_ADMIN_ROLE, multisigAddress);
            bool deployerHasRole = agentRegistry.hasRole(DEFAULT_ADMIN_ROLE, deployerAddress);
            
            console.log("AgentRegistry:");
            console.log("  Multi-sig has admin:", multisigHasRole);
            console.log("  Deployer has admin:", deployerHasRole);
            
            if (!multisigHasRole || deployerHasRole) {
                console.log("  ❌ FAILED");
                allVerified = false;
            } else {
                console.log("  ✅ PASSED");
            }
            console.log("");
        }

        // Verify ReputationScore
        address reputationScoreAddr = vm.envAddress("REPUTATION_SCORE_ADDRESS");
        if (reputationScoreAddr != address(0)) {
            ReputationScore reputationScore = ReputationScore(reputationScoreAddr);
            bool multisigHasRole = reputationScore.hasRole(DEFAULT_ADMIN_ROLE, multisigAddress);
            bool deployerHasRole = reputationScore.hasRole(DEFAULT_ADMIN_ROLE, deployerAddress);
            
            console.log("ReputationScore:");
            console.log("  Multi-sig has admin:", multisigHasRole);
            console.log("  Deployer has admin:", deployerHasRole);
            
            if (!multisigHasRole || deployerHasRole) {
                console.log("  ❌ FAILED");
                allVerified = false;
            } else {
                console.log("  ✅ PASSED");
            }
            console.log("");
        }

        // Verify InsuranceVault
        address insuranceVaultAddr = vm.envAddress("INSURANCE_VAULT_ADDRESS");
        if (insuranceVaultAddr != address(0)) {
            InsuranceVault insuranceVault = InsuranceVault(insuranceVaultAddr);
            bool multisigHasRole = insuranceVault.hasRole(DEFAULT_ADMIN_ROLE, multisigAddress);
            bool deployerHasRole = insuranceVault.hasRole(DEFAULT_ADMIN_ROLE, deployerAddress);
            
            console.log("InsuranceVault:");
            console.log("  Multi-sig has admin:", multisigHasRole);
            console.log("  Deployer has admin:", deployerHasRole);
            
            if (!multisigHasRole || deployerHasRole) {
                console.log("  ❌ FAILED");
                allVerified = false;
            } else {
                console.log("  ✅ PASSED");
            }
            console.log("");
        }

        // Verify Paymaster
        address paymasterAddr = vm.envAddress("PAYMASTER_ADDRESS");
        if (paymasterAddr != address(0)) {
            Paymaster paymaster = Paymaster(paymasterAddr);
            bool multisigHasRole = paymaster.hasRole(DEFAULT_ADMIN_ROLE, multisigAddress);
            bool deployerHasRole = paymaster.hasRole(DEFAULT_ADMIN_ROLE, deployerAddress);
            
            console.log("Paymaster:");
            console.log("  Multi-sig has admin:", multisigHasRole);
            console.log("  Deployer has admin:", deployerHasRole);
            
            if (!multisigHasRole || deployerHasRole) {
                console.log("  ❌ FAILED");
                allVerified = false;
            } else {
                console.log("  ✅ PASSED");
            }
            console.log("");
        }

        // Verify MerchantSDK
        address merchantSDKAddr = vm.envAddress("MERCHANT_SDK_ADDRESS");
        if (merchantSDKAddr != address(0)) {
            MerchantSDK merchantSDK = MerchantSDK(merchantSDKAddr);
            bool multisigHasRole = merchantSDK.hasRole(DEFAULT_ADMIN_ROLE, multisigAddress);
            bool deployerHasRole = merchantSDK.hasRole(DEFAULT_ADMIN_ROLE, deployerAddress);
            
            console.log("MerchantSDK:");
            console.log("  Multi-sig has admin:", multisigHasRole);
            console.log("  Deployer has admin:", deployerHasRole);
            
            if (!multisigHasRole || deployerHasRole) {
                console.log("  ❌ FAILED");
                allVerified = false;
            } else {
                console.log("  ✅ PASSED");
            }
            console.log("");
        }

        // Verify ZKAdapter
        address zkAdapterAddr = vm.envAddress("ZK_ADAPTER_ADDRESS");
        if (zkAdapterAddr != address(0)) {
            ZKAdapter zkAdapter = ZKAdapter(zkAdapterAddr);
            bool multisigHasRole = zkAdapter.hasRole(DEFAULT_ADMIN_ROLE, multisigAddress);
            bool deployerHasRole = zkAdapter.hasRole(DEFAULT_ADMIN_ROLE, deployerAddress);
            
            console.log("ZKAdapter:");
            console.log("  Multi-sig has admin:", multisigHasRole);
            console.log("  Deployer has admin:", deployerHasRole);
            
            if (!multisigHasRole || deployerHasRole) {
                console.log("  ❌ FAILED");
                allVerified = false;
            } else {
                console.log("  ✅ PASSED");
            }
            console.log("");
        }

        // Verify OracleAdapter
        address oracleAdapterAddr = vm.envAddress("ORACLE_ADAPTER_ADDRESS");
        if (oracleAdapterAddr != address(0)) {
            OracleAdapter oracleAdapter = OracleAdapter(oracleAdapterAddr);
            bool multisigHasRole = oracleAdapter.hasRole(DEFAULT_ADMIN_ROLE, multisigAddress);
            bool deployerHasRole = oracleAdapter.hasRole(DEFAULT_ADMIN_ROLE, deployerAddress);
            
            console.log("OracleAdapter:");
            console.log("  Multi-sig has admin:", multisigHasRole);
            console.log("  Deployer has admin:", deployerHasRole);
            
            if (!multisigHasRole || deployerHasRole) {
                console.log("  ❌ FAILED");
                allVerified = false;
            } else {
                console.log("  ✅ PASSED");
            }
            console.log("");
        }

        console.log("========================================");
        if (allVerified) {
            console.log("✅ All verifications passed!");
            console.log("Multi-sig setup is correct.");
        } else {
            console.log("❌ Some verifications failed!");
            console.log("Please review and fix issues.");
        }
        console.log("========================================");
    }
}
