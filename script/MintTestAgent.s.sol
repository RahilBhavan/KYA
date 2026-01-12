// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {AgentRegistry} from "../src/AgentRegistry.sol";
import {IAgentRegistry} from "../src/interfaces/IAgentRegistry.sol";

/**
 * @title MintTestAgent
 * @notice Script to mint a test agent after deployment
 * @dev Run with: forge script script/MintTestAgent.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast
 */
contract MintTestAgent is Script {
    function run() external {
        // Get deployer private key and registry address from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address registryAddress = vm.envAddress("AGENT_REGISTRY_ADDRESS");

        AgentRegistry registry = AgentRegistry(registryAddress);

        // Get minting fee
        uint256 mintingFee = registry.getMintingFee();

        console.log("===========================================");
        console.log("Minting Test Agent");
        console.log("===========================================");
        console.log("Registry:", registryAddress);
        console.log("Minting Fee:", mintingFee);
        console.log("===========================================");

        vm.startBroadcast(deployerPrivateKey);

        // Mint a test agent
        (bytes32 agentId, uint256 tokenId, address tbaAddress) = registry.mintAgent{
            value: mintingFee
        }("TradingBot Alpha", "High-frequency arbitrage bot for DEX trading", "DeFi");

        console.log("\n===========================================");
        console.log("Agent Created Successfully!");
        console.log("===========================================");
        console.log("Agent ID:", vm.toString(agentId));
        console.log("Token ID:", tokenId);
        console.log("TBA Address:", tbaAddress);
        console.log("===========================================");

        // Verify the agent info
        IAgentRegistry.AgentInfo memory info = registry.getAgentInfo(agentId);
        console.log("\nAgent Info:");
        console.log("- Owner:", info.owner);
        console.log("- Created At:", info.createdAt);
        console.log("- TBA Address:", info.tbaAddress);

        vm.stopBroadcast();

        console.log("\n===========================================");
        console.log("Next Steps:");
        console.log("1. View NFT on OpenSea testnet");
        console.log("2. Fund TBA with ETH/tokens");
        console.log("3. Execute transactions via TBA");
        console.log("===========================================");
    }
}
