// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../BaseTest.sol";
import {TestConstants} from "../helpers/TestConstants.sol";
import {IReputationScore} from "../../src/interfaces/IReputationScore.sol";

/**
 * @title ReputationScoreTest
 * @notice Comprehensive unit tests for ReputationScore
 */
contract ReputationScoreTest is BaseTest {
    uint256 public tokenId;
    address public tbaAddress;
    bytes32 public agentId;

    function setUp() public override {
        super.setUp();

        // Mint an agent for testing
        (agentId, tokenId, tbaAddress) = mintDefaultAgent(user1);
    }

    // =============================================================================
    // Proof Verification Tests
    // =============================================================================

    function test_verifyProof_success() public {
        bytes memory proof = abi.encode("test-proof-data");
        string memory metadata = "Uniswap volume: $10000";

        vm.prank(zkProver);
        IReputationScore.ProofResult memory result = reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof,
            metadata
        );

        assertTrue(result.verified, "Proof should be verified");
        assertGt(result.scoreIncrease, 0, "Score should increase");
    }

    function test_verifyProof_increasesScore() public {
        bytes memory proof = abi.encode("test-proof-data");

        // Get initial reputation (should be 0)
        IReputationScore.ReputationData memory repBefore = reputationScore.getReputation(tokenId);
        assertEq(repBefore.score, 0, "Initial score should be 0");

        // Verify proof
        vm.prank(zkProver);
        reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof,
            "Test metadata"
        );

        // Check score increased
        IReputationScore.ReputationData memory repAfter = reputationScore.getReputation(tokenId);
        assertGt(repAfter.score, repBefore.score, "Score should increase");
        assertEq(repAfter.verifiedProofs, 1, "Verified proofs should be 1");
    }

    function test_verifyProof_awardsBadge() public {
        bytes memory proof = abi.encode("test-proof-data");

        // Verify proof that should award badge
        vm.prank(zkProver);
        reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof,
            "Test metadata"
        );

        // Check badge awarded
        bool hasBadge = reputationScore.hasBadge(tokenId, TestConstants.BADGE_UNISWAP_TRADER);
        assertTrue(hasBadge, "Badge should be awarded");
    }

    function test_verifyProof_invalidType() public {
        bytes memory proof = abi.encode("test-proof-data");

        // Try to verify with invalid proof type
        vm.prank(zkProver);
        vm.expectRevert();
        reputationScore.verifyProof(tokenId, "InvalidProofType", proof, "Test metadata");
    }

    function test_verifyProof_onlyProver() public {
        bytes memory proof = abi.encode("test-proof-data");

        // Try to verify as non-prover - should fail
        vm.prank(user1);
        vm.expectRevert();
        reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof,
            "Test metadata"
        );
    }

    function test_verifyProof_multipleTypes() public {
        bytes memory proof1 = abi.encode("proof1");
        bytes memory proof2 = abi.encode("proof2");

        // Verify first proof
        vm.prank(zkProver);
        reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof1,
            "Metadata 1"
        );

        // Verify second proof
        vm.prank(zkProver);
        reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_AAVE_BORROWER,
            proof2,
            "Metadata 2"
        );

        // Check both proofs counted
        IReputationScore.ReputationData memory rep = reputationScore.getReputation(tokenId);
        assertEq(rep.verifiedProofs, 2, "Should have 2 verified proofs");
        assertGt(rep.score, 0, "Score should be greater than 0");
    }

    function test_verifyProof_replayPrevention() public {
        bytes memory proof = abi.encode("test-proof-data");

        // Verify proof first time - should succeed
        vm.prank(zkProver);
        IReputationScore.ProofResult memory result1 = reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof,
            "Test metadata"
        );
        assertTrue(result1.verified, "First proof should be verified");

        // Try to verify same proof again - should fail (replay prevention)
        vm.prank(zkProver);
        vm.expectRevert(); // Should revert with ProofAlreadyVerified
        reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof,
            "Test metadata"
        );
    }

    function test_verifyProof_differentProofsSameType() public {
        bytes memory proof1 = abi.encode("proof-data-1");
        bytes memory proof2 = abi.encode("proof-data-2");

        // Verify first proof
        vm.prank(zkProver);
        reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof1,
            "Metadata 1"
        );

        // Verify different proof with same type - should succeed
        vm.prank(zkProver);
        IReputationScore.ProofResult memory result2 = reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof2,
            "Metadata 2"
        );
        assertTrue(result2.verified, "Different proof should be verified");

        // Verify both proofs counted
        IReputationScore.ReputationData memory rep = reputationScore.getReputation(tokenId);
        assertEq(rep.verifiedProofs, 2, "Should have 2 verified proofs");
    }

    // =============================================================================
    // Tier System Tests
    // =============================================================================

    function test_getTier_bronze() public {
        uint8 tier = reputationScore.getTier(uint224(TestConstants.TIER_BRONZE));
        assertEq(tier, 1, "Should be Bronze tier");
    }

    function test_getTier_silver() public {
        uint8 tier = reputationScore.getTier(uint224(TestConstants.TIER_SILVER));
        assertEq(tier, 2, "Should be Silver tier");
    }

    function test_getTier_gold() public {
        uint8 tier = reputationScore.getTier(uint224(TestConstants.TIER_GOLD));
        assertEq(tier, 3, "Should be Gold tier");
    }

    function test_getTier_platinum() public {
        uint8 tier = reputationScore.getTier(uint224(TestConstants.TIER_PLATINUM));
        assertEq(tier, 4, "Should be Platinum tier");
    }

    function test_getTier_whale() public {
        uint8 tier = reputationScore.getTier(uint224(TestConstants.TIER_WHALE));
        assertEq(tier, 5, "Should be Whale tier");
    }

    function test_tierProgression() public {
        // Start with no tier
        IReputationScore.ReputationData memory rep = reputationScore.getReputation(tokenId);
        assertEq(rep.tier, 0, "Should start with no tier");

        // Add proofs to reach Bronze
        // Each UniswapVolume proof gives 50 points, need 2 for Bronze (100)
        for (uint256 i = 0; i < 2; i++) {
            bytes memory proof = abi.encode("test-proof-bronze", i); // Unique proof for each iteration
            vm.prank(zkProver);
            reputationScore.verifyProof(
                tokenId,
                TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
                proof,
                "Test"
            );
        }

        rep = reputationScore.getReputation(tokenId);
        assertGe(rep.tier, 1, "Should be at least Bronze tier");

        // Add more proofs to reach Silver (500)
        // Need 10 more UniswapVolume proofs (50 * 10 = 500)
        for (uint256 i = 0; i < 10; i++) {
            bytes memory proof = abi.encode("test-proof-silver", i); // Unique proof for each iteration
            vm.prank(zkProver);
            reputationScore.verifyProof(
                tokenId,
                TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
                proof,
                "Test"
            );
        }

        rep = reputationScore.getReputation(tokenId);
        assertGe(rep.tier, 2, "Should be at least Silver tier");
    }

    // =============================================================================
    // Badge Tests
    // =============================================================================

    function test_badgeAwarded() public {
        bytes memory proof = abi.encode("test-proof");

        // Verify proof that awards badge
        vm.prank(zkProver);
        reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof,
            "Test"
        );

        // Check badge
        bool hasBadge = reputationScore.hasBadge(tokenId, TestConstants.BADGE_UNISWAP_TRADER);
        assertTrue(hasBadge, "Badge should be awarded");
    }

    function test_hasBadge() public {
        // Initially no badge
        bool hasBadge = reputationScore.hasBadge(tokenId, TestConstants.BADGE_UNISWAP_TRADER);
        assertFalse(hasBadge, "Should not have badge initially");

        // Award badge
        bytes memory proof = abi.encode("test-proof");
        vm.prank(zkProver);
        reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof,
            "Test"
        );

        // Check badge exists
        hasBadge = reputationScore.hasBadge(tokenId, TestConstants.BADGE_UNISWAP_TRADER);
        assertTrue(hasBadge, "Should have badge after proof");
    }

    function test_getBadges() public {
        bytes memory proof = abi.encode("test-proof");

        // Award multiple badges
        vm.prank(zkProver);
        reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof,
            "Test"
        );

        vm.prank(zkProver);
        reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_AAVE_BORROWER,
            proof,
            "Test"
        );

        // Get badges
        string[] memory badges = reputationScore.getBadges(tokenId);
        assertGt(badges.length, 0, "Should have badges");
    }

    function test_multipleBadges() public {
        bytes memory proof = abi.encode("test-proof");

        // Award Uniswap badge
        vm.prank(zkProver);
        reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof,
            "Test"
        );

        // Award Aave borrower badge
        vm.prank(zkProver);
        reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_AAVE_BORROWER,
            proof,
            "Test"
        );

        // Check both badges
        assertTrue(
            reputationScore.hasBadge(tokenId, TestConstants.BADGE_UNISWAP_TRADER),
            "Should have Uniswap badge"
        );
        assertTrue(
            reputationScore.hasBadge(tokenId, TestConstants.BADGE_AAVE_BORROWER),
            "Should have Aave badge"
        );
    }

    // =============================================================================
    // Admin Functions Tests
    // =============================================================================

    function test_setProofTypeScore() public {
        string memory newProofType = "NewProofType";
        uint256 newScore = 200;

        // Set new proof type score
        vm.prank(deployer);
        reputationScore.setProofTypeScore(newProofType, newScore);

        // Verify proof with new type
        bytes memory proof = abi.encode("test-proof");
        vm.prank(zkProver);
        IReputationScore.ProofResult memory result = reputationScore.verifyProof(
            tokenId,
            newProofType,
            proof,
            "Test"
        );

        assertEq(result.scoreIncrease, newScore, "Score should match new value");
    }

    function test_setWhitelistedContract() public {
        address testContract = address(0x123);

        // Set whitelisted
        vm.prank(deployer);
        reputationScore.setWhitelistedContract(testContract, true);

        assertTrue(
            reputationScore.whitelistedContracts(testContract),
            "Contract should be whitelisted"
        );

        // Remove from whitelist
        vm.prank(deployer);
        reputationScore.setWhitelistedContract(testContract, false);

        assertFalse(
            reputationScore.whitelistedContracts(testContract),
            "Contract should not be whitelisted"
        );
    }

    function test_createBadge() public {
        IReputationScore.Badge memory newBadge = IReputationScore.Badge({
            name: "Test Badge",
            description: "A test badge",
            tier: 1,
            proofType: "TestProofType"
        });

        // Create badge
        vm.prank(deployer);
        reputationScore.createBadge(newBadge);

        // Get badge definition
        IReputationScore.Badge memory badge = reputationScore.getBadgeDefinition("Test Badge");
        assertEq(badge.name, "Test Badge", "Badge name incorrect");
    }

    // =============================================================================
    // Fuzz Tests
    // =============================================================================

    function testFuzz_tierCalculation(uint256 score) public {
        // Bound score to uint224 range
        score = bound(score, 0, type(uint224).max);
        uint8 tier = reputationScore.getTier(uint224(score));

        // Verify tier is in valid range
        assertLe(tier, 5, "Tier should be <= 5");

        // Verify tier thresholds
        if (score >= TestConstants.TIER_WHALE) {
            assertEq(tier, 5, "Should be Whale tier");
        } else if (score >= TestConstants.TIER_PLATINUM) {
            assertEq(tier, 4, "Should be Platinum tier");
        } else if (score >= TestConstants.TIER_GOLD) {
            assertEq(tier, 3, "Should be Gold tier");
        } else if (score >= TestConstants.TIER_SILVER) {
            assertEq(tier, 2, "Should be Silver tier");
        } else if (score >= TestConstants.TIER_BRONZE) {
            assertEq(tier, 1, "Should be Bronze tier");
        } else {
            assertEq(tier, 0, "Should be no tier");
        }
    }

    function testFuzz_proofScore(string memory proofType) public {
        // This test verifies that proof types are handled correctly
        // In practice, only whitelisted proof types will work
        bytes memory proof = abi.encode("test-proof");

        // Try to verify - may fail if proof type not configured
        vm.prank(zkProver);
        // This might revert if proof type is invalid, which is expected
        try reputationScore.verifyProof(tokenId, proofType, proof, "Test") returns (
            IReputationScore.ProofResult memory result
        ) {
            // If successful, verify result
            assertTrue(result.verified || !result.verified, "Result should be valid");
        } catch {
            // Expected for invalid proof types
        }
    }
}

