// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {InsuranceVault} from "../src/InsuranceVault.sol";
import {ReputationScore} from "../src/ReputationScore.sol";

/**
 * @title Rollback
 * @notice Emergency rollback procedures
 * @dev Pauses contracts and revokes roles in emergency situations
 * 
 * WARNING: Use only in emergency situations
 * 
 * Usage:
 * forge script script/Rollback.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast
 */
contract Rollback is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("===========================================");
        console.log("KYA Protocol - Emergency Rollback");
        console.log("===========================================");
        console.log("WARNING: This will pause contracts!");
        console.log("Deployer:", deployer);
        console.log("");

        // Get contract addresses
        address insuranceVaultAddr = vm.envAddress("INSURANCE_VAULT");
        address reputationScoreAddr = vm.envAddress("REPUTATION_SCORE");

        vm.startBroadcast(deployerPrivateKey);

        // Option 1: Pause InsuranceVault
        console.log("[1/3] Pausing InsuranceVault...");
        InsuranceVault insuranceVault = InsuranceVault(insuranceVaultAddr);
        if (!insuranceVault.paused()) {
            insuranceVault.pause();
            console.log("  [OK] InsuranceVault paused");
        } else {
            console.log("  [INFO] InsuranceVault already paused");
        }

        // Option 2: Revoke roles (if compromised)
        console.log("\n[2/3] Role management...");
        console.log("  [INFO] To revoke roles, use:");
        console.log("    cast send $CONTRACT \"revokeRole(bytes32,address)\" $ROLE $ADDRESS");
        console.log("  [INFO] Manual intervention required");

        // Option 3: Emergency unpause (if safe)
        console.log("\n[3/3] Unpause (if safe)...");
        console.log("  [INFO] To unpause, use:");
        console.log("    cast send $INSURANCE_VAULT \"unpause()\"");
        console.log("  [INFO] Only if issue is resolved");

        vm.stopBroadcast();

        console.log("\n===========================================");
        console.log("Rollback Procedures");
        console.log("===========================================");
        console.log("\nEmergency Actions Taken:");
        console.log("- InsuranceVault: Paused");
        console.log("\nAdditional Actions (Manual):");
        console.log("1. Investigate issue");
        console.log("2. Revoke compromised roles (if needed)");
        console.log("3. Fix issue");
        console.log("4. Test fix");
        console.log("5. Unpause (if safe)");
        console.log("\nContact: security@kya.protocol");
        console.log("===========================================");
    }
}

