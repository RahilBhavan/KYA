// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {DeployExpansionFeatures} from "./DeployExpansionFeatures.s.sol";

/**
 * @title DeployMainnet
 * @notice Deploy all contracts to mainnet (Base)
 * @dev Requires multi-sig approval and security audit
 */
contract DeployMainnet is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address multisigAddress = vm.envAddress("MULTISIG_ADDRESS");

        // Safety check - require explicit confirmation
        require(
            keccak256(bytes(vm.envString("CONFIRM_MAINNET_DEPLOYMENT"))) ==
            keccak256(bytes("YES_I_CONFIRM_MAINNET_DEPLOYMENT")),
            "DeployMainnet: Must set CONFIRM_MAINNET_DEPLOYMENT=YES_I_CONFIRM_MAINNET_DEPLOYMENT"
        );

        vm.startBroadcast(deployerPrivateKey);

        console.log("=== KYA Protocol Mainnet Deployment ===");
        console.log("Network: Base Mainnet");
        console.log("WARNING: This will deploy to MAINNET!");
        console.log("");

        // Deploy expansion features
        DeployExpansionFeatures deployer = new DeployExpansionFeatures();
        deployer.run();

        console.log("");
        console.log("[SUCCESS] All contracts deployed to mainnet!");
        console.log("");
        console.log("Post-deployment checklist:");
        console.log("1. Verify all contracts on BaseScan");
        console.log("2. Transfer admin roles to multi-sig");
        console.log("3. Deploy subgraph to The Graph mainnet");
        console.log("4. Deploy dashboard to production");
        console.log("5. Set up monitoring and alerting");
        console.log("6. Announce to community");

        vm.stopBroadcast();
    }
}
