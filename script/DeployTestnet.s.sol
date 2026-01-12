// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {DeployExpansionFeatures} from "./DeployExpansionFeatures.s.sol";

/**
 * @title DeployTestnet
 * @notice Deploy all contracts to testnet (Base Sepolia)
 */
contract DeployTestnet is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address multisigAddress = vm.envAddress("MULTISIG_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        console.log("=== KYA Protocol Testnet Deployment ===");
        console.log("Network: Base Sepolia");
        console.log("");

        // Deploy core contracts first (if not already deployed)
        // Then deploy expansion features
        DeployExpansionFeatures deployer = new DeployExpansionFeatures();
        deployer.run();

        console.log("");
        console.log("[SUCCESS] All contracts deployed to testnet!");
        console.log("");
        console.log("Next steps:");
        console.log("1. Verify contracts on BaseScan");
        console.log("2. Deploy subgraph to The Graph testnet");
        console.log("3. Deploy dashboard to staging");
        console.log("4. Run integration tests");

        vm.stopBroadcast();
    }
}
