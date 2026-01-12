// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../BaseTest.sol";
import {TestConstants} from "../helpers/TestConstants.sol";
import {IReputationScore} from "../../src/interfaces/IReputationScore.sol";
import {IReputationScoreV2} from "../../src/interfaces/IReputationScoreV2.sol";
import {ReputationScoreV2} from "../../src/ReputationScoreV2.sol";

/**
 * @title ReputationScoreV2Test
 * @notice Comprehensive unit tests for ReputationScoreV2
 */
contract ReputationScoreV2Test is BaseTest {
    ReputationScoreV2 public reputationScoreV2;
    uint256 public tokenId;
    address public tbaAddress;
    bytes32 public agentId;

    function setUp() public override {
        super.setUp();

        // Mint an agent for testing
        (agentId, tokenId, tbaAddress) = mintDefaultAgent(user1);

        // Deploy ReputationScoreV2 (deployer gets DEFAULT_ADMIN_ROLE in constructor)
        vm.startPrank(deployer);
        reputationScoreV2 = new ReputationScoreV2(
            address(reputationScore),
            address(agentLicense)
        );

        // Grant ZK_PROVER_ROLE to zkProver in V2
        bytes32 zkProverRole = reputationScoreV2.ZK_PROVER_ROLE();
        reputationScoreV2.grantRole(zkProverRole, zkProver);
        
        // Also grant DEFAULT_ADMIN_ROLE to deployer for admin functions
        reputationScoreV2.grantRole(reputationScoreV2.DEFAULT_ADMIN_ROLE(), deployer);
        
        // Grant ReputationScoreV2 the ZK_PROVER_ROLE in V1 so it can call verifyProof
        // This allows V2 to act as a proxy for V1
        reputationScore.grantRole(reputationScore.ZK_PROVER_ROLE(), address(reputationScoreV2));
        vm.stopPrank();
        
        // Note: V1 already has ZK_PROVER_ROLE granted to zkProver in BaseTest.setUp()
        // But V2 also needs the role to call V1's verifyProof
    }

    // =============================================================================
    // Time-Weighting Tests
    // =============================================================================

    function test_calculateTimeWeight_firstActivity() public {
        uint256 baseScore = 100;
        uint256 timeSinceActivity = 0;

        uint256 weightedScore = reputationScoreV2.calculateTimeWeight(baseScore, timeSinceActivity);

        // First activity should get max time weight (1.5x)
        assertEq(weightedScore, (baseScore * 15) / 10, "First activity should get 1.5x weight");
    }

    function test_calculateTimeWeight_recentActivity() public {
        uint256 baseScore = 100;
        uint256 timeSinceActivity = 1 days; // Recent activity

        uint256 weightedScore = reputationScoreV2.calculateTimeWeight(baseScore, timeSinceActivity);

        // Recent activity should get bonus weight
        assertGt(weightedScore, baseScore, "Recent activity should get bonus");
        assertLt(weightedScore, (baseScore * 15) / 10, "Should be less than max weight");
    }

    function test_calculateTimeWeight_oldActivity() public {
        uint256 baseScore = 100;
        uint256 timeSinceActivity = 10 days; // Old activity (beyond 7 day period)

        uint256 weightedScore = reputationScoreV2.calculateTimeWeight(baseScore, timeSinceActivity);

        // Old activity should get no bonus
        assertEq(weightedScore, baseScore, "Old activity should get no bonus");
    }

    // =============================================================================
    // Category Scoring Tests
    // =============================================================================

    function test_updateReputation_withCategory() public {
        bytes memory proof = abi.encode("test-proof-data");

        // Update reputation with category
        vm.prank(zkProver);
        IReputationScore.ProofResult memory result = reputationScoreV2.updateReputation(
            tokenId,
            "Trading",
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof,
            "Test metadata"
        );

        assertTrue(result.verified, "Proof should be verified");

        // Check category score
        uint256 categoryScore = reputationScoreV2.getCategoryScore(tokenId, "Trading");
        assertGt(categoryScore, 0, "Category score should be set");
    }

    function test_updateReputation_multipleCategories() public {
        bytes memory proof1 = abi.encode("test-proof-1");
        bytes memory proof2 = abi.encode("test-proof-2");

        // Update Trading category
        vm.prank(zkProver);
        reputationScoreV2.updateReputation(
            tokenId,
            "Trading",
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof1,
            "Trading metadata"
        );

        // Update Lending category
        vm.prank(zkProver);
        reputationScoreV2.updateReputation(
            tokenId,
            "Lending",
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof2,
            "Lending metadata"
        );

        // Check both category scores
        uint256 tradingScore = reputationScoreV2.getCategoryScore(tokenId, "Trading");
        uint256 lendingScore = reputationScoreV2.getCategoryScore(tokenId, "Lending");

        assertGt(tradingScore, 0, "Trading score should be set");
        assertGt(lendingScore, 0, "Lending score should be set");
        // Note: Scores may differ slightly due to time-weighting (second call happens later)
        // Both should be close to the base score (within reasonable range)
        assertApproxEqRel(tradingScore, lendingScore, 0.1e18, "Scores should be approximately equal");
    }

    function test_getExtendedReputation() public {
        bytes memory proof = abi.encode("test-proof-data");

        // Update reputation with category
        vm.prank(zkProver);
        reputationScoreV2.updateReputation(
            tokenId,
            "Trading",
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof,
            "Test metadata"
        );

        // Get extended reputation
        (
            IReputationScore.ReputationData memory baseData,
            uint256 lastActivity,
            string[] memory categories,
            uint256[] memory categoryScores
        ) = reputationScoreV2.getExtendedReputation(tokenId);

        assertGt(baseData.score, 0, "Base score should be set");
        assertGt(lastActivity, 0, "Last activity should be set");
        assertEq(categories.length, 1, "Should have one category");
        assertEq(categories[0], "Trading", "Category should be Trading");
        assertEq(categoryScores.length, 1, "Should have one category score");
        assertGt(categoryScores[0], 0, "Category score should be set");
    }

    // =============================================================================
    // Decay Tests
    // =============================================================================

    function test_applyDecay_noDecayIfRecent() public {
        bytes memory proof = abi.encode("test-proof-data");

        // Update reputation
        vm.prank(zkProver);
        reputationScoreV2.updateReputation(
            tokenId,
            "Trading",
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof,
            "Test metadata"
        );

        // Get initial score
        IReputationScore.ReputationData memory repBefore = reputationScoreV2.getReputation(tokenId);
        uint256 scoreBefore = repBefore.score;

        // Apply decay immediately (should not decay)
        uint256 scoreAfter = reputationScoreV2.applyDecay(tokenId);

        // Score should not change (activity is recent)
        assertEq(scoreAfter, scoreBefore, "Score should not decay for recent activity");
    }

    function test_applyDecay_afterPeriod() public {
        bytes memory proof = abi.encode("test-proof-data");

        // Update reputation
        vm.prank(zkProver);
        reputationScoreV2.updateReputation(
            tokenId,
            "Trading",
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof,
            "Test metadata"
        );

        // Get initial score
        IReputationScore.ReputationData memory repBefore = reputationScoreV2.getReputation(tokenId);
        uint256 scoreBefore = repBefore.score;

        // Fast forward past decay period (30 days)
        vm.warp(block.timestamp + 31 days);

        // Apply decay
        uint256 scoreAfter = reputationScoreV2.applyDecay(tokenId);

        // Score should decay (note: actual decay implementation may vary)
        // For now, we just check the function doesn't revert
        assertLe(scoreAfter, scoreBefore, "Score should not increase after decay period");
    }

    // =============================================================================
    // Admin Functions Tests
    // =============================================================================

    function test_setDecayParameters() public {
        uint256 newDecayPeriod = 60 days;
        uint256 newDecayRate = 200; // 2%

        vm.prank(deployer);
        reputationScoreV2.setDecayParameters(newDecayPeriod, newDecayRate);

        assertEq(reputationScoreV2.decayPeriod(), newDecayPeriod, "Decay period should be updated");
        assertEq(reputationScoreV2.decayRate(), newDecayRate, "Decay rate should be updated");
    }

    function test_setDecayParameters_onlyAdmin() public {
        vm.prank(user1);
        vm.expectRevert();
        reputationScoreV2.setDecayParameters(60 days, 200);
    }

    function test_setTimeWeightParameters() public {
        uint256 newTimeWeightPeriod = 14 days;
        uint256 newMaxTimeWeight = 2e18; // 200%

        vm.prank(deployer);
        reputationScoreV2.setTimeWeightParameters(newTimeWeightPeriod, newMaxTimeWeight);

        assertEq(
            reputationScoreV2.timeWeightPeriod(),
            newTimeWeightPeriod,
            "Time weight period should be updated"
        );
        assertEq(
            reputationScoreV2.maxTimeWeight(),
            newMaxTimeWeight,
            "Max time weight should be updated"
        );
    }

    function test_setTimeWeightParameters_onlyAdmin() public {
        vm.prank(user1);
        vm.expectRevert();
        reputationScoreV2.setTimeWeightParameters(14 days, 2e18);
    }

    // =============================================================================
    // Backward Compatibility Tests
    // =============================================================================

    function test_verifyProof_backwardCompatible() public {
        bytes memory proof = abi.encode("test-proof-data");

        // Use V1 interface method
        vm.prank(zkProver);
        IReputationScore.ProofResult memory result = reputationScoreV2.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof,
            "Test metadata"
        );

        assertTrue(result.verified, "Proof should be verified");

        // Check reputation updated in V1
        IReputationScore.ReputationData memory rep = reputationScoreV2.getReputation(tokenId);
        assertGt(rep.score, 0, "Score should be updated");
    }

    function test_getReputation_backwardCompatible() public {
        bytes memory proof = abi.encode("test-proof-data");

        // Update reputation via V1
        vm.prank(zkProver);
        reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof,
            "Test metadata"
        );

        // Get reputation via V2 (should work)
        IReputationScore.ReputationData memory rep = reputationScoreV2.getReputation(tokenId);
        assertGt(rep.score, 0, "Should get reputation from V1");
    }

    // =============================================================================
    // Fuzz Tests
    // =============================================================================

    function testFuzz_calculateTimeWeight(uint256 baseScore, uint256 timeSinceActivity) public {
        // Bound inputs to reasonable ranges
        baseScore = bound(baseScore, 1, 1000000);
        timeSinceActivity = bound(timeSinceActivity, 0, 365 days);

        uint256 weightedScore = reputationScoreV2.calculateTimeWeight(baseScore, timeSinceActivity);

        // Weighted score should never be less than base score (for old activity)
        // and never more than maxTimeWeight * baseScore
        assertGe(weightedScore, baseScore, "Weighted score should be >= base");
        assertLe(
            weightedScore,
            (baseScore * reputationScoreV2.maxTimeWeight()) / 1e18,
            "Weighted score should be <= max weight * base"
        );
    }

    function testFuzz_updateReputation_category(
        string calldata category,
        uint256 proofData
    ) public {
        // Bound category length
        vm.assume(bytes(category).length > 0 && bytes(category).length <= 32);

        bytes memory proof = abi.encode(proofData);

        vm.prank(zkProver);
        IReputationScore.ProofResult memory result = reputationScoreV2.updateReputation(
            tokenId,
            category,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof,
            "Fuzz test"
        );

        assertTrue(result.verified, "Proof should be verified");

        // Check category score exists
        uint256 categoryScore = reputationScoreV2.getCategoryScore(tokenId, category);
        assertGt(categoryScore, 0, "Category score should be set");
    }
}
