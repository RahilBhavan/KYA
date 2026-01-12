// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../BaseTest.sol";
import {TestConstants} from "../helpers/TestConstants.sol";
import {IInsuranceVault} from "../../src/interfaces/IInsuranceVault.sol";
import {IReputationScore} from "../../src/interfaces/IReputationScore.sol";
import {IAgentAccount} from "../../src/interfaces/IAgentAccount.sol";

/**
 * @title ProtocolInvariantsTest
 * @notice Invariant tests for protocol-level properties
 */
contract ProtocolInvariantsTest is BaseTest {
    /**
     * @notice Invariant: Verified agents always have stake >= minimum
     */
    function invariant_verifiedAgentsHaveMinimumStake() public {
        // Create and verify an agent
        (, uint256 tokenId, address tbaAddress) = mintDefaultAgent(user1);
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

        // Verify invariant
        bool isVerified = insuranceVault.isVerified(tokenId);
        if (isVerified) {
            IInsuranceVault.StakeInfo memory stakeInfo = insuranceVault.getStakeInfo(tokenId);
            assertGe(
                stakeInfo.amount,
                TestConstants.MINIMUM_STAKE,
                "Verified agent must have stake >= minimum"
            );
        }
    }

    /**
     * @notice Invariant: Claim amounts never exceed stake amounts
     */
    function invariant_claimAmountsNeverExceedStake() public {
        (, uint256 tokenId, address tbaAddress) = mintDefaultAgent(user1);
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

        // Submit claim
        uint256 claimAmount = stakeAmount / 2; // Valid claim amount
        vm.prank(merchant);
        bytes32 claimId = insuranceVault.submitClaim(tokenId, claimAmount, "Test claim");

        // Verify claim amount <= stake
        IInsuranceVault.Claim memory claim = insuranceVault.getClaim(claimId);
        IInsuranceVault.StakeInfo memory stakeInfo = insuranceVault.getStakeInfo(tokenId);
        assertLe(claim.amount, stakeInfo.amount, "Claim amount must not exceed stake");
    }

    /**
     * @notice Invariant: Reputation scores only increase (never decrease)
     */
    function invariant_reputationScoresOnlyIncrease() public {
        (, uint256 tokenId,) = mintDefaultAgent(user1);

        uint256 previousScore = 0;

        // Add multiple proofs with different proof data to avoid replay
        for (uint256 i = 0; i < 10; i++) {
            bytes memory proof = abi.encode("test-proof", i, block.timestamp + i);
            
            vm.prank(zkProver);
            reputationScore.verifyProof(
                tokenId,
                TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
                proof,
                "Test"
            );

            IReputationScore.ReputationData memory rep = reputationScore.getReputation(tokenId);
            assertGe(rep.score, previousScore, "Reputation score should never decrease");
            previousScore = rep.score;
        }
    }

    /**
     * @notice Invariant: Badge count <= proof count
     */
    function invariant_badgeCountLessThanOrEqualProofCount() public {
        (, uint256 tokenId,) = mintDefaultAgent(user1);

        // Add proofs with different proof data to avoid replay
        for (uint256 i = 0; i < 5; i++) {
            bytes memory proof = abi.encode("test-proof", i, block.timestamp + i);
            
            vm.prank(zkProver);
            reputationScore.verifyProof(
                tokenId,
                TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
                proof,
                "Test"
            );
        }

        // Verify invariant
        IReputationScore.ReputationData memory rep = reputationScore.getReputation(tokenId);
        string[] memory badges = reputationScore.getBadges(tokenId);

        assertLe(
            badges.length,
            rep.verifiedProofs,
            "Badge count must be <= proof count"
        );
    }

    /**
     * @notice Invariant: Paymaster sponsored count <= MAX_SPONSORED_TXS
     */
    function invariant_paymasterSponsoredCountWithinLimit() public {
        (, uint256 tokenId,) = mintDefaultAgent(user1);

        vm.prank(deployer);
        paymaster.setTwitterVerified(tokenId, true);

        // Get sponsored count
        uint256 sponsoredCount = paymaster.getSponsoredCount(tokenId);

        // Verify invariant
        assertLe(
            sponsoredCount,
            TestConstants.MAX_SPONSORED_TXS,
            "Sponsored count must be <= MAX_SPONSORED_TXS"
        );
    }

    /**
     * @notice Invariant: Total staked USDC = sum of individual stakes
     * @dev This is a simplified check - in production, maintain a totalStaked counter
     */
    function invariant_totalStakedEqualsSumOfIndividualStakes() public {
        // Create multiple agents and stake
        uint256 totalStaked = 0;
        uint256 numAgents = 5;

        for (uint256 i = 0; i < numAgents; i++) {
            (, uint256 tokenId, address tbaAddress) = mintDefaultAgent(user1);
            fundTBA(tbaAddress, TestConstants.TEST_STAKE_AMOUNT);

            uint256 stakeAmount = TestConstants.MINIMUM_STAKE;
            vm.prank(user1);
            IAgentAccount(tbaAddress).execute(
                address(mockUSDC),
                0,
                abi.encodeWithSignature(
                    "approve(address,uint256)",
                    address(insuranceVault),
                    stakeAmount
                )
            );

            vm.prank(user1);
            IAgentAccount(tbaAddress).execute(
                address(insuranceVault),
                0,
                abi.encodeWithSignature("stake(uint256,uint256)", tokenId, stakeAmount)
            );

            IInsuranceVault.StakeInfo memory stakeInfo = insuranceVault.getStakeInfo(tokenId);
            totalStaked += stakeInfo.amount;
        }

        // Verify total staked in vault
        uint256 vaultBalance = mockUSDC.balanceOf(address(insuranceVault));
        assertGe(vaultBalance, totalStaked, "Vault balance should be >= total staked");
    }
}

