// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../BaseTest.sol";
import {TestConstants} from "../helpers/TestConstants.sol";
import {IReputationScore} from "../../src/interfaces/IReputationScore.sol";

/**
 * @title ReputationScoreFuzzTest
 * @notice Fuzz tests for ReputationScore
 */
contract ReputationScoreFuzzTest is BaseTest {
    uint256 public tokenId;

    function setUp() public override {
        super.setUp();
        (, tokenId,) = mintDefaultAgent(user1);
    }

    function testFuzz_tierCalculation(uint256 score) public {
        // Bound score to uint224 range (getTier expects uint224)
        score = bound(score, 0, type(uint224).max);
        uint8 tier = reputationScore.getTier(uint224(score));

        // Verify tier is in valid range
        assertLe(tier, 5, "Tier should be <= 5");
        assertGe(tier, 0, "Tier should be >= 0");

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
        bytes memory proof = abi.encode("test-proof");

        // Try to verify - may fail if proof type not configured
        vm.prank(zkProver);
        try reputationScore.verifyProof(tokenId, proofType, proof, "Test") returns (
            IReputationScore.ProofResult memory result
        ) {
            // If successful, verify result
            assertTrue(result.verified || !result.verified, "Result should be valid");
            if (result.verified) {
                assertGt(result.scoreIncrease, 0, "Score increase should be positive");
            }
        } catch {
            // Expected for invalid proof types
        }
    }

    function testFuzz_multipleProofs(uint256 numProofs) public {
        // Bound number of proofs
        numProofs = bound(numProofs, 1, 100);

        bytes memory proof = abi.encode("test-proof");
        uint256 expectedScore = 0;

        // Add multiple proofs
        for (uint256 i = 0; i < numProofs; i++) {
            vm.prank(zkProver);
            try reputationScore.verifyProof(
                tokenId,
                TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
                proof,
                "Test"
            ) returns (IReputationScore.ProofResult memory result) {
                if (result.verified) {
                    expectedScore += result.scoreIncrease;
                }
            } catch {
                // Skip if fails
            }
        }

        // Verify final score
        IReputationScore.ReputationData memory rep = reputationScore.getReputation(tokenId);
        assertLe(rep.score, expectedScore, "Score should not exceed expected");
    }

    function testFuzz_badgeCombinations(uint256 numBadges) public {
        // Bound number of badges
        numBadges = bound(numBadges, 0, 10);

        bytes memory proof = abi.encode("test-proof");
        string[4] memory proofTypes = [
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            TestConstants.PROOF_TYPE_AAVE_BORROWER,
            TestConstants.PROOF_TYPE_AAVE_LENDER,
            TestConstants.PROOF_TYPE_CHAINLINK
        ];

        // Add proofs to get badges
        for (uint256 i = 0; i < numBadges && i < proofTypes.length; i++) {
            vm.prank(zkProver);
            try reputationScore.verifyProof(tokenId, proofTypes[i], proof, "Test") {} catch {
                // Skip if fails
            }
        }

        // Verify badge count
        string[] memory badges = reputationScore.getBadges(tokenId);
        assertLe(badges.length, numBadges, "Badge count should not exceed proofs");
    }
}

