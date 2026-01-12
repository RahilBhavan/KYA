// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../BaseTest.sol";
import {TestConstants} from "../helpers/TestConstants.sol";
import {IInsuranceVault} from "../../src/interfaces/IInsuranceVault.sol";
import {IReputationScore} from "../../src/interfaces/IReputationScore.sol";
import {IMerchantSDK} from "../../src/interfaces/IMerchantSDK.sol";
import {IAgentAccount} from "../../src/interfaces/IAgentAccount.sol";

/**
 * @title FullFlowTest
 * @notice End-to-end integration tests for complete agent lifecycle
 */
contract FullFlowTest is BaseTest {
    function test_fullAgentLifecycle() public {
        // Step 1: Mint agent
        (, uint256 tokenId, address tbaAddress) = mintDefaultAgent(user1);
        assertGt(tokenId, 0, "Token ID should be valid");

        // Step 2: Fund TBA with USDC
        uint256 usdcAmount = TestConstants.TEST_STAKE_AMOUNT * 2;
        fundTBA(tbaAddress, usdcAmount);
        assertEq(
            mockUSDC.balanceOf(tbaAddress),
            usdcAmount,
            "TBA should be funded with USDC"
        );

        // Step 3: Stake USDC
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;
        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(mockUSDC),
            0,
            abi.encodeWithSignature("approve(address,uint256)", address(insuranceVault), stakeAmount)
        );

        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(insuranceVault),
            0,
            abi.encodeWithSignature("stake(uint256,uint256)", tokenId, stakeAmount)
        );

        // Step 4: Verify agent
        assertTrue(insuranceVault.isVerified(tokenId), "Agent should be verified");

        // Step 5: Submit ZK proof
        bytes memory proof = abi.encode("zk-proof-data");
        vm.prank(zkProver);
        IReputationScore.ProofResult memory proofResult = reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof,
            "Uniswap volume: $10000"
        );

        assertTrue(proofResult.verified, "Proof should be verified");
        assertGt(proofResult.scoreIncrease, 0, "Score should increase");

        // Step 6: Increase reputation
        IReputationScore.ReputationData memory rep = reputationScore.getReputation(tokenId);
        assertGt(rep.score, 0, "Reputation score should be greater than 0");
        assertEq(rep.verifiedProofs, 1, "Should have 1 verified proof");

        // Step 7: Merchant verification
        IMerchantSDK.VerificationResult memory verification = merchantSDK.verifyAgent(
            tokenId,
            tbaAddress
        );
        assertTrue(verification.isVerified, "Agent should be verified by merchant");
        assertGt(verification.reputationScore, 0, "Should have reputation");
        assertTrue(verification.isActive, "Agent should be active");

        // Step 8: Violation report
        IMerchantSDK.Violation memory violation = IMerchantSDK.Violation({
            conditionType: "RateLimit",
            description: "Exceeded 10 tx/minute limit",
            evidence: abi.encode("tx-hash-123")
        });

        vm.prank(merchant);
        bytes32 claimId = merchantSDK.reportViolation(tokenId, violation);
        assertNotEq(claimId, bytes32(0), "Claim ID should be valid");

        // Step 9: Claim resolution
        IInsuranceVault.Claim memory claim = insuranceVault.getClaim(claimId);
        assertEq(claim.status, 0, "Claim should be pending");

        // Step 10: Slashing (resolve claim as approved)
        // Note: The claim's merchant is the MerchantSDK contract (msg.sender), not the original merchant
        uint256 merchantSDKBalanceBefore = mockUSDC.balanceOf(address(merchantSDK));
        uint256 stakeBefore = insuranceVault.getStakeInfo(tokenId).amount;

        vm.prank(oracle);
        insuranceVault.resolveClaim(claimId, true);

        // Verify slashing occurred - payout goes to MerchantSDK contract
        uint256 merchantSDKBalanceAfter = mockUSDC.balanceOf(address(merchantSDK));
        assertGt(merchantSDKBalanceAfter, merchantSDKBalanceBefore, "MerchantSDK should receive payout");

        IInsuranceVault.StakeInfo memory stakeAfter = insuranceVault.getStakeInfo(tokenId);
        assertLt(stakeAfter.amount, stakeBefore, "Stake should be reduced");
    }

    function test_agentTransfer() public {
        // Mint and setup agent
        (, uint256 tokenId, address tbaAddress) = mintDefaultAgent(user1);

        // Fund and stake
        fundTBA(tbaAddress, TestConstants.TEST_STAKE_AMOUNT);
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;

        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(mockUSDC),
            0,
            abi.encodeWithSignature("approve(address,uint256)", address(insuranceVault), stakeAmount)
        );

        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(insuranceVault),
            0,
            abi.encodeWithSignature("stake(uint256,uint256)", tokenId, stakeAmount)
        );

        // Verify agent is verified
        assertTrue(insuranceVault.isVerified(tokenId), "Agent should be verified");

        // Transfer NFT to new owner
        vm.prank(user1);
        agentLicense.transferFrom(user1, user2, tokenId);

        // Verify new owner controls TBA
        address newOwner = agentLicense.ownerOf(tokenId);
        assertEq(newOwner, user2, "New owner should be user2");

        // Verify stake and verification status preserved
        assertTrue(insuranceVault.isVerified(tokenId), "Agent should still be verified");
        IInsuranceVault.StakeInfo memory stakeInfo = insuranceVault.getStakeInfo(tokenId);
        assertEq(stakeInfo.amount, stakeAmount, "Stake should be preserved");
    }

    function test_multipleAgents() public {
        // Create multiple agents
        (, uint256 tokenId1, address tba1) = mintDefaultAgent(user1);
        (, uint256 tokenId2, address tba2) = mintDefaultAgent(user2);

        // Fund and stake both
        fundTBA(tba1, TestConstants.TEST_STAKE_AMOUNT);
        fundTBA(tba2, TestConstants.TEST_STAKE_AMOUNT);

        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;

        // Stake agent 1
        vm.prank(user1);
        IAgentAccount(tba1).execute(
            address(mockUSDC),
            0,
            abi.encodeWithSignature("approve(address,uint256)", address(insuranceVault), stakeAmount)
        );

        vm.prank(user1);
        IAgentAccount(tba1).execute(
            address(insuranceVault),
            0,
            abi.encodeWithSignature("stake(uint256,uint256)", tokenId1, stakeAmount)
        );

        // Stake agent 2
        vm.prank(user2);
        IAgentAccount(tba2).execute(
            address(mockUSDC),
            0,
            abi.encodeWithSignature("approve(address,uint256)", address(insuranceVault), stakeAmount)
        );

        vm.prank(user2);
        IAgentAccount(tba2).execute(
            address(insuranceVault),
            0,
            abi.encodeWithSignature("stake(uint256,uint256)", tokenId2, stakeAmount)
        );

        // Verify both agents
        assertTrue(insuranceVault.isVerified(tokenId1), "Agent 1 should be verified");
        assertTrue(insuranceVault.isVerified(tokenId2), "Agent 2 should be verified");

        // Add reputation to agent 1
        bytes memory proof = abi.encode("proof");
        vm.prank(zkProver);
        reputationScore.verifyProof(
            tokenId1,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof,
            "Test"
        );

        // Verify agent 1 has reputation, agent 2 doesn't
        IReputationScore.ReputationData memory rep1 = reputationScore.getReputation(tokenId1);
        IReputationScore.ReputationData memory rep2 = reputationScore.getReputation(tokenId2);

        assertGt(rep1.score, 0, "Agent 1 should have reputation");
        assertEq(rep2.score, 0, "Agent 2 should not have reputation");
    }

    function test_reputationAccumulation() public {
        // Mint agent
        (, uint256 tokenId, address tbaAddress) = mintDefaultAgent(user1);

        // Add multiple proofs
        bytes memory proof = abi.encode("proof");
        uint256 expectedScore = 0;

        // Add UniswapVolume proof (50 points)
        vm.prank(zkProver);
        reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof,
            "Test"
        );
        expectedScore += 50;

        // Add AaveBorrower proof (100 points)
        vm.prank(zkProver);
        reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_AAVE_BORROWER,
            proof,
            "Test"
        );
        expectedScore += 100;

        // Add AaveLender proof (150 points)
        vm.prank(zkProver);
        reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_AAVE_LENDER,
            proof,
            "Test"
        );
        expectedScore += 150;

        // Verify total score
        IReputationScore.ReputationData memory rep = reputationScore.getReputation(tokenId);
        assertEq(rep.score, expectedScore, "Total score should match");
        assertEq(rep.verifiedProofs, 3, "Should have 3 verified proofs");

        // Verify tier progression
        assertGe(rep.tier, 1, "Should be at least Bronze tier");
    }
}

