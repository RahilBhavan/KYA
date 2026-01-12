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
 * @title TransferAdminToMultisig
 * @notice Transfers all admin roles from deployer to multi-sig wallet
 * @dev Run with: forge script script/TransferAdminToMultisig.s.sol --rpc-url $RPC_URL --broadcast
 * 
 * SECURITY WARNING: This script transfers critical admin roles. Ensure:
 * 1. Multi-sig address is correct
 * 2. Multi-sig is properly configured
 * 3. All signers are onboarded
 * 4. Test on testnet first
 */
contract TransferAdminToMultisig is Script {
    // =============================================================================
    // State Variables
    // =============================================================================

    /// @notice Multi-sig wallet address (set via environment or constructor)
    address public multisigAddress;

    // =============================================================================
    // Setup
    // =============================================================================

    function setUp() public {
        // Get multi-sig address from environment
        multisigAddress = vm.envAddress("MULTISIG_ADDRESS");
        
        require(multisigAddress != address(0), "MULTISIG_ADDRESS not set");
        require(multisigAddress.code.length > 0, "MULTISIG_ADDRESS is not a contract");
    }

    // =============================================================================
    // Main Execution
    // =============================================================================

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("========================================");
        console.log("Admin Role Transfer to Multi-sig");
        console.log("========================================");
        console.log("Deployer:", deployer);
        console.log("Multi-sig:", multisigAddress);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Get contract addresses from environment
        address agentLicenseAddr = vm.envAddress("AGENT_LICENSE_ADDRESS");
        address agentRegistryAddr = vm.envAddress("AGENT_REGISTRY_ADDRESS");
        address reputationScoreAddr = vm.envAddress("REPUTATION_SCORE_ADDRESS");
        address insuranceVaultAddr = vm.envAddress("INSURANCE_VAULT_ADDRESS");
        address paymasterAddr = vm.envAddress("PAYMASTER_ADDRESS");
        address merchantSDKAddr = vm.envAddress("MERCHANT_SDK_ADDRESS");
        address zkAdapterAddr = vm.envAddress("ZK_ADAPTER_ADDRESS");
        address oracleAdapterAddr = vm.envAddress("ORACLE_ADAPTER_ADDRESS");

        bytes32 DEFAULT_ADMIN_ROLE = 0x00;

        // Transfer AgentLicense admin role
        if (agentLicenseAddr != address(0)) {
            console.log("Transferring AgentLicense admin role...");
            AgentLicense agentLicense = AgentLicense(agentLicenseAddr);
            agentLicense.grantRole(DEFAULT_ADMIN_ROLE, multisigAddress);
            agentLicense.revokeRole(DEFAULT_ADMIN_ROLE, deployer);
            console.log("  [OK] AgentLicense admin transferred");
        }

        // Transfer AgentRegistry admin role
        if (agentRegistryAddr != address(0)) {
            console.log("Transferring AgentRegistry admin role...");
            AgentRegistry agentRegistry = AgentRegistry(agentRegistryAddr);
            agentRegistry.grantRole(DEFAULT_ADMIN_ROLE, multisigAddress);
            agentRegistry.revokeRole(DEFAULT_ADMIN_ROLE, deployer);
            console.log("  [OK] AgentRegistry admin transferred");
        }

        // Transfer ReputationScore admin role
        if (reputationScoreAddr != address(0)) {
            console.log("Transferring ReputationScore admin role...");
            ReputationScore reputationScore = ReputationScore(reputationScoreAddr);
            reputationScore.grantRole(DEFAULT_ADMIN_ROLE, multisigAddress);
            reputationScore.revokeRole(DEFAULT_ADMIN_ROLE, deployer);
            console.log("  [OK] ReputationScore admin transferred");
        }

        // Transfer InsuranceVault admin role
        if (insuranceVaultAddr != address(0)) {
            console.log("Transferring InsuranceVault admin role...");
            InsuranceVault insuranceVault = InsuranceVault(insuranceVaultAddr);
            insuranceVault.grantRole(DEFAULT_ADMIN_ROLE, multisigAddress);
            insuranceVault.revokeRole(DEFAULT_ADMIN_ROLE, deployer);
            console.log("  [OK] InsuranceVault admin transferred");
        }

        // Transfer Paymaster admin role
        if (paymasterAddr != address(0)) {
            console.log("Transferring Paymaster admin role...");
            Paymaster paymaster = Paymaster(paymasterAddr);
            paymaster.grantRole(DEFAULT_ADMIN_ROLE, multisigAddress);
            paymaster.revokeRole(DEFAULT_ADMIN_ROLE, deployer);
            console.log("  [OK] Paymaster admin transferred");
        }

        // Transfer MerchantSDK admin role
        // Note: MerchantSDK uses AccessControl, but may not have admin functions
        // If MerchantSDK has admin functions, uncomment below:
        // if (merchantSDKAddr != address(0)) {
        //     console.log("Transferring MerchantSDK admin role...");
        //     MerchantSDK merchantSDK = MerchantSDK(merchantSDKAddr);
        //     merchantSDK.grantRole(DEFAULT_ADMIN_ROLE, multisigAddress);
        //     merchantSDK.revokeRole(DEFAULT_ADMIN_ROLE, deployer);
        //     console.log("  [OK] MerchantSDK admin transferred");
        // }

        // Transfer ZKAdapter admin role
        if (zkAdapterAddr != address(0)) {
            console.log("Transferring ZKAdapter admin role...");
            ZKAdapter zkAdapter = ZKAdapter(zkAdapterAddr);
            zkAdapter.grantRole(DEFAULT_ADMIN_ROLE, multisigAddress);
            zkAdapter.revokeRole(DEFAULT_ADMIN_ROLE, deployer);
            console.log("  [OK] ZKAdapter admin transferred");
        }

        // Transfer OracleAdapter admin role
        if (oracleAdapterAddr != address(0)) {
            console.log("Transferring OracleAdapter admin role...");
            OracleAdapter oracleAdapter = OracleAdapter(oracleAdapterAddr);
            oracleAdapter.grantRole(DEFAULT_ADMIN_ROLE, multisigAddress);
            oracleAdapter.revokeRole(DEFAULT_ADMIN_ROLE, deployer);
            console.log("  [OK] OracleAdapter admin transferred");
        }

        vm.stopBroadcast();

        console.log("");
        console.log("========================================");
        console.log("Verification");
        console.log("========================================");
        _verifyTransfers(
            agentLicenseAddr,
            agentRegistryAddr,
            reputationScoreAddr,
            insuranceVaultAddr,
            paymasterAddr,
            merchantSDKAddr,
            zkAdapterAddr,
            oracleAdapterAddr,
            deployer
        );
    }

    // =============================================================================
    // Verification
    // =============================================================================

    function _verifyTransfers(
        address agentLicenseAddr,
        address agentRegistryAddr,
        address reputationScoreAddr,
        address insuranceVaultAddr,
        address paymasterAddr,
        address merchantSDKAddr,
        address zkAdapterAddr,
        address oracleAdapterAddr,
        address deployer
    ) internal view {
        bytes32 DEFAULT_ADMIN_ROLE = 0x00;
        bool allVerified = true;

        if (agentLicenseAddr != address(0)) {
            AgentLicense agentLicense = AgentLicense(agentLicenseAddr);
            bool multisigHasRole = agentLicense.hasRole(DEFAULT_ADMIN_ROLE, multisigAddress);
            bool deployerHasRole = agentLicense.hasRole(DEFAULT_ADMIN_ROLE, deployer);
            
            if (multisigHasRole && !deployerHasRole) {
                console.log("  [OK] AgentLicense: Verified");
            } else {
                console.log("  [FAIL] AgentLicense: Verification failed");
                allVerified = false;
            }
        }

        if (agentRegistryAddr != address(0)) {
            AgentRegistry agentRegistry = AgentRegistry(agentRegistryAddr);
            bool multisigHasRole = agentRegistry.hasRole(DEFAULT_ADMIN_ROLE, multisigAddress);
            bool deployerHasRole = agentRegistry.hasRole(DEFAULT_ADMIN_ROLE, deployer);
            
            if (multisigHasRole && !deployerHasRole) {
                console.log("  [OK] AgentRegistry: Verified");
            } else {
                console.log("  [FAIL] AgentRegistry: Verification failed");
                allVerified = false;
            }
        }

        if (reputationScoreAddr != address(0)) {
            ReputationScore reputationScore = ReputationScore(reputationScoreAddr);
            bool multisigHasRole = reputationScore.hasRole(DEFAULT_ADMIN_ROLE, multisigAddress);
            bool deployerHasRole = reputationScore.hasRole(DEFAULT_ADMIN_ROLE, deployer);
            
            if (multisigHasRole && !deployerHasRole) {
                console.log("  [OK] ReputationScore: Verified");
            } else {
                console.log("  [FAIL] ReputationScore: Verification failed");
                allVerified = false;
            }
        }

        if (insuranceVaultAddr != address(0)) {
            InsuranceVault insuranceVault = InsuranceVault(insuranceVaultAddr);
            bool multisigHasRole = insuranceVault.hasRole(DEFAULT_ADMIN_ROLE, multisigAddress);
            bool deployerHasRole = insuranceVault.hasRole(DEFAULT_ADMIN_ROLE, deployer);
            
            if (multisigHasRole && !deployerHasRole) {
                console.log("  [OK] InsuranceVault: Verified");
            } else {
                console.log("  [FAIL] InsuranceVault: Verification failed");
                allVerified = false;
            }
        }

        if (paymasterAddr != address(0)) {
            Paymaster paymaster = Paymaster(paymasterAddr);
            bool multisigHasRole = paymaster.hasRole(DEFAULT_ADMIN_ROLE, multisigAddress);
            bool deployerHasRole = paymaster.hasRole(DEFAULT_ADMIN_ROLE, deployer);
            
            if (multisigHasRole && !deployerHasRole) {
                console.log("  [OK] Paymaster: Verified");
            } else {
                console.log("  [FAIL] Paymaster: Verification failed");
                allVerified = false;
            }
        }

        if (merchantSDKAddr != address(0)) {
            MerchantSDK merchantSDK = MerchantSDK(merchantSDKAddr);
            bool multisigHasRole = merchantSDK.hasRole(DEFAULT_ADMIN_ROLE, multisigAddress);
            bool deployerHasRole = merchantSDK.hasRole(DEFAULT_ADMIN_ROLE, deployer);
            
            if (multisigHasRole && !deployerHasRole) {
                console.log("  [OK] MerchantSDK: Verified");
            } else {
                console.log("  [FAIL] MerchantSDK: Verification failed");
                allVerified = false;
            }
        }

        if (zkAdapterAddr != address(0)) {
            ZKAdapter zkAdapter = ZKAdapter(zkAdapterAddr);
            bool multisigHasRole = zkAdapter.hasRole(DEFAULT_ADMIN_ROLE, multisigAddress);
            bool deployerHasRole = zkAdapter.hasRole(DEFAULT_ADMIN_ROLE, deployer);
            
            if (multisigHasRole && !deployerHasRole) {
                console.log("  [OK] ZKAdapter: Verified");
            } else {
                console.log("  [FAIL] ZKAdapter: Verification failed");
                allVerified = false;
            }
        }

        if (oracleAdapterAddr != address(0)) {
            OracleAdapter oracleAdapter = OracleAdapter(oracleAdapterAddr);
            bool multisigHasRole = oracleAdapter.hasRole(DEFAULT_ADMIN_ROLE, multisigAddress);
            bool deployerHasRole = oracleAdapter.hasRole(DEFAULT_ADMIN_ROLE, deployer);
            
            if (multisigHasRole && !deployerHasRole) {
                console.log("  [OK] OracleAdapter: Verified");
            } else {
                console.log("  [FAIL] OracleAdapter: Verification failed");
                allVerified = false;
            }
        }

        console.log("");
        if (allVerified) {
            console.log("[SUCCESS] All admin roles successfully transferred!");
        } else {
            console.log("[ERROR] Some transfers failed. Please review.");
        }
    }
}
