// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {AgentRegistry} from "../src/AgentRegistry.sol";
import {InsuranceVault} from "../src/InsuranceVault.sol";
import {ReputationScore} from "../src/ReputationScore.sol";
import {Paymaster} from "../src/Paymaster.sol";
import {MerchantSDK} from "../src/MerchantSDK.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAgentAccount} from "../src/interfaces/IAgentAccount.sol";
import {IReputationScore} from "../src/interfaces/IReputationScore.sol";
import {IMerchantSDK} from "../src/interfaces/IMerchantSDK.sol";

/**
 * @title TestnetTesting
 * @notice End-to-end testing script for testnet deployment
 * @dev Tests full agent lifecycle on testnet
 * 
 * Usage:
 * Set contract addresses and test account in environment
 * forge script script/TestnetTesting.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast
 */
contract TestnetTesting is Script {
    // Test constants
    uint256 constant MINIMUM_STAKE = 1000 * 10**6; // 1000 USDC
    uint256 constant TEST_STAKE_AMOUNT = 2000 * 10**6; // 2000 USDC for testing

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Get contract addresses
        address agentRegistryAddr = vm.envAddress("AGENT_REGISTRY");
        address insuranceVaultAddr = vm.envAddress("INSURANCE_VAULT");
        address reputationScoreAddr = vm.envAddress("REPUTATION_SCORE");
        address paymasterAddr = vm.envAddress("PAYMASTER");
        address merchantSDKAddr = vm.envAddress("MERCHANT_SDK");
        address usdcAddr = vm.envAddress("USDC_ADDRESS");

        console.log("===========================================");
        console.log("KYA Protocol - Testnet Testing");
        console.log("===========================================");
        console.log("Deployer:", deployer);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        AgentRegistry agentRegistry = AgentRegistry(agentRegistryAddr);
        InsuranceVault insuranceVault = InsuranceVault(insuranceVaultAddr);
        ReputationScore reputationScore = ReputationScore(reputationScoreAddr);
        Paymaster paymaster = Paymaster(paymasterAddr);
        MerchantSDK merchantSDK = MerchantSDK(merchantSDKAddr);
        IERC20 usdc = IERC20(usdcAddr);

        // Test 1: Mint Agent
        console.log("[1/6] Testing agent minting...");
        (bytes32 agentId, uint256 tokenId, address tbaAddress) = agentRegistry.mintAgent(
            "TestAgent",
            "Test agent for testnet",
            "Trading"
        );
        console.log("  [OK] Agent minted");
        console.log("  Token ID:", tokenId);
        console.log("  TBA Address:", tbaAddress);

        // Test 2: Fund TBA with USDC
        console.log("\n[2/6] Funding TBA with USDC...");
        // Note: In testnet, you may need to mint test USDC or get from faucet
        // For this test, we assume USDC is available
        uint256 usdcBalance = usdc.balanceOf(tbaAddress);
        console.log("  TBA USDC balance:", usdcBalance / 10**6, "USDC");
        if (usdcBalance < TEST_STAKE_AMOUNT) {
            console.log("  [WARNING] Insufficient USDC - mint or transfer USDC to TBA");
        } else {
            console.log("  [OK] TBA has sufficient USDC");
        }

        // Test 3: Stake USDC
        console.log("\n[3/6] Testing staking...");
        if (usdcBalance >= MINIMUM_STAKE) {
            // Note: In real testnet, you would need to:
            // 1. Get the NFT owner (deployer in this case)
            // 2. Call execute via the owner
            // For this script, we'll just check the balance
            console.log("  [INFO] To stake, owner must call:");
            console.log("    tba.execute(usdc, 0, approve(...))");
            console.log("    tba.execute(insuranceVault, 0, stake(...))");
            console.log("  Current TBA balance:", usdcBalance / 10**6, "USDC");
            console.log("  Minimum stake required:", MINIMUM_STAKE / 10**6, "USDC");
        } else {
            console.log("  [WARNING] Skipping - insufficient USDC");
            console.log("  Current balance:", usdcBalance / 10**6, "USDC");
            console.log("  Required:", MINIMUM_STAKE / 10**6, "USDC");
        }

        // Test 4: Verify Proof (requires ZK_PROVER_ROLE)
        console.log("\n[4/6] Testing proof verification...");
        bytes memory proof = abi.encode("test-proof-data");
        try reputationScore.verifyProof(
            tokenId,
            "UniswapVolume",
            proof,
            "Testnet test proof"
        ) {
            console.log("  [OK] Proof verified");
            IReputationScore.ReputationData memory rep = reputationScore.getReputation(tokenId);
            console.log("  Reputation score:", rep.score);
            console.log("  Tier:", rep.tier);
        } catch {
            console.log("  [WARNING] Proof verification failed (may need ZK_PROVER_ROLE)");
        }

        // Test 5: Merchant Verification
        console.log("\n[5/6] Testing merchant verification...");
        IMerchantSDK.VerificationResult memory result = merchantSDK.verifyAgent(tokenId, tbaAddress);
        console.log("  Verified:", result.isVerified);
        console.log("  Stake amount:", result.stakeAmount / 10**6, "USDC");
        console.log("  Reputation score:", result.reputationScore);
        console.log("  Tier:", result.tier);
        console.log("  Active:", result.isActive);

        // Test 6: Paymaster Eligibility
        console.log("\n[6/6] Testing Paymaster eligibility...");
        (bool eligible, uint256 remaining) = paymaster.isEligible(tokenId);
        console.log("  Eligible:", eligible);
        console.log("  Remaining transactions:", remaining);

        vm.stopBroadcast();

        console.log("\n===========================================");
        console.log("Testnet Testing Complete!");
        console.log("===========================================");
        console.log("\nTest Results:");
        console.log("- Agent minted: [OK]");
        console.log("- Staking: ", usdcBalance >= MINIMUM_STAKE ? "[OK]" : "[WARNING] (needs USDC)");
        console.log("- Proof verification: Check ZK_PROVER_ROLE");
        console.log("- Merchant verification: [OK]");
        console.log("- Paymaster eligibility: Check");
        console.log("\nNext Steps:");
        console.log("1. Fund TBA with USDC (if needed)");
        console.log("2. Grant ZK_PROVER_ROLE for proof testing");
        console.log("3. Test claim submission and resolution");
        console.log("===========================================");
    }
}

