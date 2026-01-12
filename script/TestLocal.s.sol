// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IAgentRegistry} from "../src/interfaces/IAgentRegistry.sol";
import {IInsuranceVault} from "../src/interfaces/IInsuranceVault.sol";
import {IReputationScore} from "../src/interfaces/IReputationScore.sol";
import {IMerchantSDK} from "../src/interfaces/IMerchantSDK.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAgentAccount} from "../src/interfaces/IAgentAccount.sol";

/**
 * @title TestLocal
 * @notice Test script for local deployment
 * @dev Tests the full flow: mint → stake → verify → check reputation
 * 
 * Usage:
 * 1. Deploy contracts: forge script script/DeployLocal.s.sol --rpc-url http://localhost:8545 --broadcast
 * 2. Set addresses in .env or export them
 * 3. Run: forge script script/TestLocal.s.sol --rpc-url http://localhost:8545 --broadcast
 */
contract TestLocal is Script {
    function run() external {
        // Get addresses from environment or deployment output
        address agentRegistry = vm.envOr("AGENT_REGISTRY", address(0));
        address insuranceVault = vm.envOr("INSURANCE_VAULT", address(0));
        address reputationScore = vm.envOr("REPUTATION_SCORE", address(0));
        address merchantSDK = vm.envOr("MERCHANT_SDK", address(0));
        address mockUSDC = vm.envOr("MOCK_USDC", address(0));
        
        require(agentRegistry != address(0), "AGENT_REGISTRY not set");
        require(insuranceVault != address(0), "INSURANCE_VAULT not set");
        require(mockUSDC != address(0), "MOCK_USDC not set");
        
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);
        
        console.log("===========================================");
        console.log("KYA Protocol Local Test");
        console.log("===========================================");
        console.log("Deployer:", deployer);
        console.log("AgentRegistry:", agentRegistry);
        console.log("InsuranceVault:", insuranceVault);
        console.log("===========================================");
        
        vm.startBroadcast(deployerKey);
        
        // =============================================================================
        // Step 1: Mint an Agent
        // =============================================================================
        
        console.log("\n[1/5] Minting agent...");
        IAgentRegistry registry = IAgentRegistry(agentRegistry);
        
        (bytes32 agentId, uint256 tokenId, address tbaAddress) = registry.mintAgent{
            value: 0.001 ether
        }("TestAgent", "A test agent for local testing", "Trading");
        
        console.log("Agent minted successfully!");
        console.log("  Agent ID:", vm.toString(agentId));
        console.log("  Token ID:", tokenId);
        console.log("  TBA Address:", tbaAddress);
        
        // =============================================================================
        // Step 2: Fund TBA with USDC
        // =============================================================================
        
        console.log("\n[2/5] Funding TBA with USDC...");
        IERC20 usdc = IERC20(mockUSDC);
        uint256 usdcAmount = 2000 * 10**6; // 2000 USDC
        
        // Transfer USDC to TBA
        usdc.transfer(tbaAddress, usdcAmount);
        console.log("Transferred", usdcAmount / 10**6, "USDC to TBA");
        console.log("TBA USDC balance:", usdc.balanceOf(tbaAddress) / 10**6, "USDC");
        
        // =============================================================================
        // Step 3: Approve and Stake USDC
        // =============================================================================
        
        console.log("\n[3/5] Staking USDC for verification...");
        IInsuranceVault vault = IInsuranceVault(insuranceVault);
        uint256 stakeAmount = 1000 * 10**6; // 1000 USDC (minimum)
        
        // Approve and stake from TBA
        // Get TBA account interface
        IAgentAccount tba = IAgentAccount(tbaAddress);
        
        // Build approve calldata
        bytes memory approveData = abi.encodeWithSignature(
            "approve(address,uint256)",
            insuranceVault,
            stakeAmount
        );
        
        // Execute approve from TBA
        tba.execute(mockUSDC, 0, approveData);
        console.log("Approved", stakeAmount / 10**6, "USDC from TBA");
        
        // Build stake calldata
        bytes memory stakeData = abi.encodeWithSignature(
            "stake(uint256,uint256)",
            tokenId,
            stakeAmount
        );
        
        // Execute stake from TBA (TBA calls InsuranceVault.stake())
        tba.execute(insuranceVault, 0, stakeData);
        console.log("Staked", stakeAmount / 10**6, "USDC");
        
        // Check verification status
        bool verified = vault.isVerified(tokenId);
        console.log("Agent verified:", verified);
        
        // =============================================================================
        // Step 4: Check Reputation (should be 0 initially)
        // =============================================================================
        
        if (reputationScore != address(0)) {
            console.log("\n[4/5] Checking reputation...");
            IReputationScore rep = IReputationScore(reputationScore);
            IReputationScore.ReputationData memory repData = rep.getReputation(tokenId);
            
            console.log("Reputation Score:", repData.score);
            console.log("Tier:", repData.tier);
            console.log("Verified Proofs:", repData.verifiedProofs);
        } else {
            console.log("\n[4/5] Skipping reputation check (REPUTATION_SCORE not set)");
        }
        
        // =============================================================================
        // Step 5: Verify via MerchantSDK
        // =============================================================================
        
        if (merchantSDK != address(0)) {
            console.log("\n[5/5] Verifying agent via MerchantSDK...");
            IMerchantSDK sdk = IMerchantSDK(merchantSDK);
            IMerchantSDK.VerificationResult memory result = sdk.verifyAgent(tokenId, tbaAddress);
            
            console.log("Verification Result:");
            console.log("  Verified:", result.isVerified);
            console.log("  Stake Amount:", result.stakeAmount / 10**6, "USDC");
            console.log("  Reputation Score:", result.reputationScore);
            console.log("  Tier:", result.tier);
            console.log("  Active:", result.isActive);
        } else {
            console.log("\n[5/5] Skipping MerchantSDK verification (MERCHANT_SDK not set)");
        }
        
        vm.stopBroadcast();
        
        console.log("\n===========================================");
        console.log("Test Complete!");
        console.log("===========================================");
        console.log("\nNext Steps:");
        console.log("1. Test reputation proof verification");
        console.log("2. Test claim submission and slashing");
        console.log("3. Test paymaster gas sponsorship");
        console.log("===========================================");
    }
}

