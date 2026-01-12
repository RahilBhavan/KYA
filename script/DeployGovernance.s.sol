// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {KYAToken} from "../src/governance/KYAToken.sol";
import {KYAGovernance} from "../src/governance/KYAGovernance.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

/**
 * @title DeployGovernance
 * @notice Deploy governance system (KYAToken, TimelockController, KYAGovernance)
 */
contract DeployGovernance is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address multisigAddress = vm.envAddress("MULTISIG_ADDRESS");
        uint256 timelockDelay = vm.envUint("TIMELOCK_DELAY"); // In seconds

        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying Governance System...");
        console.log("");

        // Step 1: Deploy KYA Token
        console.log("Step 1: Deploying KYAToken...");
        KYAToken kyaToken = new KYAToken("KYA Token", "KYA");
        console.log("  KYAToken deployed at:", address(kyaToken));
        console.log("");

        // Step 2: Deploy TimelockController
        console.log("Step 2: Deploying TimelockController...");
        address[] memory proposers = new address[](1);
        proposers[0] = address(0); // Will be set to governance contract
        address[] memory executors = new address[](1);
        executors[0] = multisigAddress; // Multi-sig as executor

        TimelockController timelock = new TimelockController(
            timelockDelay,
            proposers,
            executors,
            msg.sender // Admin (will be transferred to multi-sig)
        );
        console.log("  TimelockController deployed at:", address(timelock));
        console.log("  Min delay:", timelock.getMinDelay());
        console.log("");

        // Step 3: Deploy Governance
        console.log("Step 3: Deploying KYAGovernance...");
        KYAGovernance governance = new KYAGovernance(
            address(kyaToken),
            address(timelock),
            5000, // 50% quorum
            5001  // 50.01% voting threshold
        );
        console.log("  KYAGovernance deployed at:", address(governance));
        console.log("");

        // Step 4: Setup roles
        console.log("Step 4: Setting up roles...");

        // Grant governance PROPOSER_ROLE in timelock
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governance));
        console.log("  [OK] Governance granted PROPOSER_ROLE in timelock");

        // Grant governance EXECUTOR_ROLE in timelock
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(governance));
        console.log("  [OK] Governance granted EXECUTOR_ROLE in timelock");

        // Transfer timelock admin to multi-sig
        timelock.grantRole(timelock.DEFAULT_ADMIN_ROLE(), multisigAddress);
        timelock.revokeRole(timelock.DEFAULT_ADMIN_ROLE(), msg.sender);
        console.log("  [OK] Timelock admin transferred to multi-sig");

        // Grant governance MINTER_ROLE (for token distribution)
        kyaToken.grantRole(kyaToken.MINTER_ROLE(), address(governance));
        console.log("  [OK] Governance granted MINTER_ROLE");

        // Transfer token admin to multi-sig
        kyaToken.grantRole(kyaToken.DEFAULT_ADMIN_ROLE(), multisigAddress);
        kyaToken.revokeRole(kyaToken.DEFAULT_ADMIN_ROLE(), msg.sender);
        console.log("  [OK] Token admin transferred to multi-sig");

        // Transfer governance admin to multi-sig
        governance.grantRole(governance.DEFAULT_ADMIN_ROLE(), multisigAddress);
        governance.revokeRole(governance.DEFAULT_ADMIN_ROLE(), msg.sender);
        console.log("  [OK] Governance admin transferred to multi-sig");
        console.log("");

        // Step 5: Summary
        console.log("=== Deployment Summary ===");
        console.log("KYAToken:", address(kyaToken));
        console.log("TimelockController:", address(timelock));
        console.log("KYAGovernance:", address(governance));
        console.log("Multi-sig:", multisigAddress);
        console.log("");
        console.log("[SUCCESS] Governance system deployed and configured!");

        vm.stopBroadcast();
    }
}
