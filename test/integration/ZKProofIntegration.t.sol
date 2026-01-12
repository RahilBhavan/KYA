// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../BaseTest.sol";
import {TestConstants} from "../helpers/TestConstants.sol";
import {IReputationScore} from "../../src/interfaces/IReputationScore.sol";

/**
 * @title ZKProofIntegrationTest
 * @notice Integration tests for ZK proof verification with Axiom/Brevis
 * 
 * Note: For real integration, configure Axiom/Brevis test environment.
 * This test includes both real integration patterns and mock alternatives.
 */
contract ZKProofIntegrationTest is BaseTest {
    uint256 public tokenId;
    address public tbaAddress;

    function setUp() public override {
        super.setUp();
        (, tokenId, tbaAddress) = mintDefaultAgent(user1);
    }

    /**
     * @notice Test Axiom proof generation and verification
     * @dev In production, this would call Axiom API to generate proof
     */
    function test_axiom_proofGeneration() public {
        // Simulate Axiom proof generation
        // In real integration:
        // 1. Call Axiom API with query (e.g., "Uniswap volume > $10000")
        // 2. Axiom generates ZK proof
        // 3. Proof is returned

        bytes memory axiomProof = abi.encode(
            "axiom-proof",
            block.chainid,
            tbaAddress,
            "UniswapVolume",
            "10000"
        );

        // Verify proof via ReputationScore (called by Axiom coprocessor)
        vm.prank(zkProver);
        IReputationScore.ProofResult memory result = reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            axiomProof,
            "Axiom: Uniswap volume $10000"
        );

        assertTrue(result.verified, "Axiom proof should be verified");
        assertGt(result.scoreIncrease, 0, "Score should increase");
    }

    /**
     * @notice Test Axiom proof verification on-chain
     */
    function test_axiom_proofVerification() public {
        // Generate proof (simulated)
        bytes memory axiomProof = abi.encode("axiom-proof-data");

        // Verify on-chain
        vm.prank(zkProver);
        IReputationScore.ProofResult memory result = reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            axiomProof,
            "Axiom verified proof"
        );

        // Verify result
        assertTrue(result.verified, "Proof should be verified");
        assertEq(result.proofType, TestConstants.PROOF_TYPE_UNISWAP_VOLUME, "Proof type incorrect");

        // Verify reputation updated
        IReputationScore.ReputationData memory rep = reputationScore.getReputation(tokenId);
        assertGt(rep.score, 0, "Reputation should increase");
    }

    /**
     * @notice Test reputation update after Axiom proof
     */
    function test_axiom_reputationUpdate() public {
        uint256 initialScore = reputationScore.getReputation(tokenId).score;

        // Generate and verify proof
        bytes memory axiomProof = abi.encode("axiom-proof");
        vm.prank(zkProver);
        reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            axiomProof,
            "Axiom proof"
        );

        // Verify reputation updated
        IReputationScore.ReputationData memory rep = reputationScore.getReputation(tokenId);
        assertGt(rep.score, initialScore, "Reputation should increase");
        assertEq(rep.verifiedProofs, 1, "Should have 1 verified proof");
    }

    /**
     * @notice Test multiple Axiom proofs
     */
    function test_axiom_multipleProofs() public {
        // Verify multiple proof types
        bytes memory proof1 = abi.encode("axiom-proof-1");
        bytes memory proof2 = abi.encode("axiom-proof-2");
        bytes memory proof3 = abi.encode("axiom-proof-3");

        // Uniswap volume
        vm.prank(zkProver);
        reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof1,
            "Axiom: Uniswap"
        );

        // Aave borrower
        vm.prank(zkProver);
        reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_AAVE_BORROWER,
            proof2,
            "Axiom: Aave"
        );

        // Chainlink user
        vm.prank(zkProver);
        reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_CHAINLINK,
            proof3,
            "Axiom: Chainlink"
        );

        // Verify all proofs counted
        IReputationScore.ReputationData memory rep = reputationScore.getReputation(tokenId);
        assertEq(rep.verifiedProofs, 3, "Should have 3 verified proofs");
        assertGt(rep.score, 0, "Score should be greater than 0");
    }

    /**
     * @notice Test Brevis proof generation and verification
     */
    function test_brevis_proofGeneration() public {
        // Simulate Brevis proof generation
        bytes memory brevisProof = abi.encode(
            "brevis-proof",
            block.chainid,
            tbaAddress,
            "UniswapTrades",
            "100"
        );

        // Verify proof
        vm.prank(zkProver);
        IReputationScore.ProofResult memory result = reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_TRADES,
            brevisProof,
            "Brevis: 100 Uniswap trades"
        );

        assertTrue(result.verified, "Brevis proof should be verified");
    }

    /**
     * @notice Test Brevis proof verification on-chain
     */
    function test_brevis_proofVerification() public {
        bytes memory brevisProof = abi.encode("brevis-proof-data");

        vm.prank(zkProver);
        IReputationScore.ProofResult memory result = reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_TRADES,
            brevisProof,
            "Brevis verified proof"
        );

        assertTrue(result.verified, "Proof should be verified");
    }

    /**
     * @notice Mock ZK proof for testing when real integration unavailable
     */
    function test_mockZKProof() public {
        // Mock proof that matches real proof format
        bytes memory mockProof = abi.encode(
            "mock-proof",
            block.chainid,
            tbaAddress,
            "UniswapVolume",
            "10000",
            keccak256("proof-data")
        );

        // Verify mock proof
        vm.prank(zkProver);
        IReputationScore.ProofResult memory result = reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            mockProof,
            "Mock proof metadata"
        );

        assertTrue(result.verified, "Mock proof should be verified");
    }
}

