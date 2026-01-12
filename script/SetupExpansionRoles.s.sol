// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {KYAToken} from "../src/governance/KYAToken.sol";
import {KYAGovernance} from "../src/governance/KYAGovernance.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {AgentMarketplace} from "../src/marketplace/AgentMarketplace.sol";
import {InsurancePool} from "../src/insurance/InsurancePool.sol";
import {CrossChainReputation} from "../src/crosschain/CrossChainReputation.sol";

/**
 * @title SetupExpansionRoles
 * @notice Setup roles for expansion features after deployment
 * @dev Run this after DeployExpansionFeatures to complete role setup
 */
contract SetupExpansionRoles is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address multisigAddress = vm.envAddress("MULTISIG_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        console.log("Setting up roles for expansion features...");
        console.log("");

        // Get contract addresses
        KYAToken kyaToken = KYAToken(vm.envAddress("KYA_TOKEN"));
        KYAGovernance governance = KYAGovernance(vm.envAddress("KYA_GOVERNANCE"));
        TimelockController timelock = TimelockController(payable(vm.envAddress("TIMELOCK_CONTROLLER")));
        AgentMarketplace marketplace = AgentMarketplace(vm.envAddress("AGENT_MARKETPLACE"));
        InsurancePool insurancePool = InsurancePool(vm.envAddress("INSURANCE_POOL"));
        CrossChainReputation crossChain = CrossChainReputation(vm.envAddress("CROSS_CHAIN_REPUTATION"));

        // Grant governance roles in timelock
        console.log("Granting governance roles in timelock...");
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governance));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(governance));
        console.log("  [OK] Governance granted PROPOSER_ROLE and EXECUTOR_ROLE");

        // Grant governance MINTER_ROLE
        console.log("Granting governance MINTER_ROLE...");
        kyaToken.grantRole(kyaToken.MINTER_ROLE(), address(governance));
        console.log("  [OK] Governance granted MINTER_ROLE");

        // Transfer admin roles to multi-sig
        console.log("Transferring admin roles to multi-sig...");
        
        kyaToken.grantRole(kyaToken.DEFAULT_ADMIN_ROLE(), multisigAddress);
        kyaToken.revokeRole(kyaToken.DEFAULT_ADMIN_ROLE(), msg.sender);
        console.log("  [OK] KYAToken admin transferred");

        governance.grantRole(governance.DEFAULT_ADMIN_ROLE(), multisigAddress);
        governance.revokeRole(governance.DEFAULT_ADMIN_ROLE(), msg.sender);
        console.log("  [OK] KYAGovernance admin transferred");

        marketplace.grantRole(marketplace.DEFAULT_ADMIN_ROLE(), multisigAddress);
        marketplace.revokeRole(marketplace.DEFAULT_ADMIN_ROLE(), msg.sender);
        console.log("  [OK] AgentMarketplace admin transferred");

        insurancePool.grantRole(insurancePool.DEFAULT_ADMIN_ROLE(), multisigAddress);
        insurancePool.revokeRole(insurancePool.DEFAULT_ADMIN_ROLE(), msg.sender);
        console.log("  [OK] InsurancePool admin transferred");

        crossChain.grantRole(crossChain.DEFAULT_ADMIN_ROLE(), multisigAddress);
        crossChain.revokeRole(crossChain.DEFAULT_ADMIN_ROLE(), msg.sender);
        console.log("  [OK] CrossChainReputation admin transferred");

        // Transfer timelock admin to multi-sig (last)
        timelock.grantRole(timelock.DEFAULT_ADMIN_ROLE(), multisigAddress);
        timelock.revokeRole(timelock.DEFAULT_ADMIN_ROLE(), msg.sender);
        console.log("  [OK] TimelockController admin transferred");

        console.log("");
        console.log("[SUCCESS] All roles configured!");

        vm.stopBroadcast();
    }
}
