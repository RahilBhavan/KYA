// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../BaseTest.sol";
import {TestConstants} from "../helpers/TestConstants.sol";
import {TestUtils} from "../helpers/TestUtils.sol";
import {IInsuranceVault} from "../../src/interfaces/IInsuranceVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAgentAccount} from "../../src/interfaces/IAgentAccount.sol";

/**
 * @title InsuranceVaultTest
 * @notice Comprehensive unit tests for InsuranceVault
 */
contract InsuranceVaultTest is BaseTest {
    // TestUtils is now inherited through BaseTest

    uint256 public tokenId;
    address public tbaAddress;
    bytes32 public agentId;

    function setUp() public override {
        super.setUp();

        // Mint an agent for testing
        (agentId, tokenId, tbaAddress) = mintDefaultAgent(user1);

        // Fund TBA with USDC
        fundTBA(tbaAddress, TestConstants.TEST_STAKE_AMOUNT * 2);
    }

    // =============================================================================
    // Staking Tests
    // =============================================================================

    function test_stake_success() public {
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;

        // Approve USDC from TBA
        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(mockUSDC),
            0,
            abi.encodeWithSignature("approve(address,uint256)", address(insuranceVault), stakeAmount)
        );

        // Stake from TBA
        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(insuranceVault),
            0,
            abi.encodeWithSignature("stake(uint256,uint256)", tokenId, stakeAmount)
        );

        // Verify stake info
        IInsuranceVault.StakeInfo memory stakeInfo = insuranceVault.getStakeInfo(tokenId);
        assertEq(stakeInfo.amount, stakeAmount, "Stake amount incorrect");
        assertTrue(stakeInfo.isVerified, "Agent should be verified");
        // Note: tokenId removed from StakeInfo struct (it's the mapping key)
        // Verify stake exists by checking amount > 0
        assertGt(stakeInfo.amount, 0, "Stake should exist");
    }

    function test_stake_insufficientAmount() public {
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE - 1;

        // Approve USDC from TBA
        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(mockUSDC),
            0,
            abi.encodeWithSignature("approve(address,uint256)", address(insuranceVault), stakeAmount)
        );

        // Attempt to stake - should fail
        vm.prank(user1);
        vm.expectRevert();
        IAgentAccount(tbaAddress).execute(
            address(insuranceVault),
            0,
            abi.encodeWithSignature("stake(uint256,uint256)", tokenId, stakeAmount)
        );
    }

    function test_stake_verifiedStatus() public {
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;

        // Approve and stake
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

        // Check verification status
        assertTrue(insuranceVault.isVerified(tokenId), "Agent should be verified");
    }

    function test_stake_multipleTimes() public {
        uint256 firstStake = TestConstants.MINIMUM_STAKE;
        uint256 secondStake = TestConstants.MINIMUM_STAKE; // Must be at least minimum stake

        // First stake
        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(mockUSDC),
            0,
            abi.encodeWithSignature("approve(address,uint256)", address(insuranceVault), firstStake)
        );

        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(insuranceVault),
            0,
            abi.encodeWithSignature("stake(uint256,uint256)", tokenId, firstStake)
        );

        // Second stake (must be at least minimum stake)
        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(mockUSDC),
            0,
            abi.encodeWithSignature("approve(address,uint256)", address(insuranceVault), secondStake)
        );

        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(insuranceVault),
            0,
            abi.encodeWithSignature("stake(uint256,uint256)", tokenId, secondStake)
        );

        // Verify total stake
        IInsuranceVault.StakeInfo memory stakeInfo = insuranceVault.getStakeInfo(tokenId);
        assertEq(stakeInfo.amount, firstStake + secondStake, "Total stake incorrect");
    }

    function test_stake_invalidTokenId() public {
        uint256 invalidTokenId = 99999;
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;

        vm.prank(user1);
        vm.expectRevert();
        IAgentAccount(tbaAddress).execute(
            address(insuranceVault),
            0,
            abi.encodeWithSignature("stake(uint256,uint256)", invalidTokenId, stakeAmount)
        );
    }

    // =============================================================================
    // Unstaking Tests
    // =============================================================================

    function test_unstake_success() public {
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;
        uint256 unstakeAmount = 500 * 10**6;

        // Stake first (makes agent verified)
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

        // Request unstake (starts cooldown)
        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(insuranceVault),
            0,
            abi.encodeWithSignature("requestUnstake(uint256)", tokenId)
        );

        // Wait for cooldown period
        vm.warp(block.timestamp + TestConstants.UNSTAKE_COOLDOWN + 1);

        // Now unstake should succeed
        uint256 balanceBefore = mockUSDC.balanceOf(tbaAddress);

        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(insuranceVault),
            0,
            abi.encodeWithSignature("unstake(uint256,uint256)", tokenId, unstakeAmount)
        );

        // Verify unstake
        uint256 balanceAfter = mockUSDC.balanceOf(tbaAddress);
        assertEq(balanceAfter - balanceBefore, unstakeAmount, "USDC not returned");

        IInsuranceVault.StakeInfo memory stakeInfo = insuranceVault.getStakeInfo(tokenId);
        assertEq(stakeInfo.amount, stakeAmount - unstakeAmount, "Stake amount incorrect");
    }

    function test_unstake_cooldown() public {
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;

        // Stake to become verified
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

        // Try to unstake immediately - should fail (cooldown)
        vm.prank(user1);
        vm.expectRevert();
        IAgentAccount(tbaAddress).execute(
            address(insuranceVault),
            0,
            abi.encodeWithSignature("unstake(uint256,uint256)", tokenId, 100 * 10**6)
        );
    }

    function test_unstake_afterCooldown() public {
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;
        uint256 unstakeAmount = 100 * 10**6;

        // Stake to become verified
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

        // Request unstake (starts cooldown)
        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(insuranceVault),
            0,
            abi.encodeWithSignature("requestUnstake(uint256)", tokenId)
        );

        // Wait for cooldown
        vm.warp(block.timestamp + TestConstants.UNSTAKE_COOLDOWN + 1);

        // Now unstake should succeed
        uint256 balanceBefore = mockUSDC.balanceOf(tbaAddress);

        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(insuranceVault),
            0,
            abi.encodeWithSignature("unstake(uint256,uint256)", tokenId, unstakeAmount)
        );

        uint256 balanceAfter = mockUSDC.balanceOf(tbaAddress);
        assertEq(balanceAfter - balanceBefore, unstakeAmount, "USDC not returned");
    }

    function test_unstake_removesVerification() public {
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;
        uint256 unstakeAmount = TestConstants.MINIMUM_STAKE; // Unstake all

        // Stake to become verified
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

        assertTrue(insuranceVault.isVerified(tokenId), "Should be verified");

        // Request unstake (starts cooldown)
        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(insuranceVault),
            0,
            abi.encodeWithSignature("requestUnstake(uint256)", tokenId)
        );

        // Wait for cooldown
        vm.warp(block.timestamp + TestConstants.UNSTAKE_COOLDOWN + 1);

        // Now unstake should succeed
        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(insuranceVault),
            0,
            abi.encodeWithSignature("unstake(uint256,uint256)", tokenId, unstakeAmount)
        );

        // Should no longer be verified
        assertFalse(insuranceVault.isVerified(tokenId), "Should not be verified");
    }

    // =============================================================================
    // Claims Tests
    // =============================================================================

    function test_submitClaim_success() public {
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;
        uint256 claimAmount = 500 * 10**6;

        // Stake first
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
        vm.prank(merchant);
        bytes32 claimId = insuranceVault.submitClaim(
            tokenId,
            claimAmount,
            "Malicious behavior detected"
        );

        // Verify claim
        IInsuranceVault.Claim memory claim = insuranceVault.getClaim(claimId);
        assertEq(claim.tokenId, tokenId, "Token ID incorrect");
        assertEq(claim.merchant, merchant, "Merchant incorrect");
        assertEq(claim.amount, claimAmount, "Amount incorrect");
        assertEq(claim.status, 0, "Status should be pending");
    }

    function test_submitClaim_invalidAmount() public {
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;
        uint256 claimAmount = stakeAmount + 1; // More than staked

        // Stake first
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

        // Submit claim with invalid amount
        vm.prank(merchant);
        vm.expectRevert();
        insuranceVault.submitClaim(tokenId, claimAmount, "Test claim");
    }

    function test_submitClaim_unverifiedAgent() public {
        // Try to submit claim without staking
        vm.prank(merchant);
        vm.expectRevert();
        insuranceVault.submitClaim(tokenId, 100 * 10**6, "Test claim");
    }

    function test_resolveClaim_approved() public {
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;
        uint256 claimAmount = 500 * 10**6;

        // Stake
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
        vm.prank(merchant);
        bytes32 claimId = insuranceVault.submitClaim(tokenId, claimAmount, "Test claim");

        // Resolve claim as approved
        vm.prank(oracle);
        insuranceVault.resolveClaim(claimId, true);

        // Verify claim resolved
        IInsuranceVault.Claim memory claim = insuranceVault.getClaim(claimId);
        assertEq(claim.status, 1, "Claim should be approved");

        // Verify stake reduced
        IInsuranceVault.StakeInfo memory stakeInfo = insuranceVault.getStakeInfo(tokenId);
        assertEq(stakeInfo.amount, stakeAmount - claimAmount, "Stake should be reduced");
    }

    function test_resolveClaim_rejected() public {
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;
        uint256 claimAmount = 500 * 10**6;

        // Stake
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
        vm.prank(merchant);
        bytes32 claimId = insuranceVault.submitClaim(tokenId, claimAmount, "Test claim");

        // Resolve claim as rejected
        vm.prank(oracle);
        insuranceVault.resolveClaim(claimId, false);

        // Verify claim rejected
        IInsuranceVault.Claim memory claim = insuranceVault.getClaim(claimId);
        assertEq(claim.status, 2, "Claim should be rejected");

        // Verify stake unchanged
        IInsuranceVault.StakeInfo memory stakeInfo = insuranceVault.getStakeInfo(tokenId);
        assertEq(stakeInfo.amount, stakeAmount, "Stake should be unchanged");
    }

    function test_challengeClaim_success() public {
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;
        uint256 claimAmount = 500 * 10**6;

        // Stake
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
        vm.prank(merchant);
        bytes32 claimId = insuranceVault.submitClaim(tokenId, claimAmount, "Test claim");

        // Challenge claim
        vm.prank(user1);
        insuranceVault.challengeClaim(claimId);

        // Verify claim challenged
        IInsuranceVault.Claim memory claim = insuranceVault.getClaim(claimId);
        assertEq(claim.status, 3, "Claim should be challenged");
    }

    function test_challengeClaim_expired() public {
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;
        uint256 claimAmount = 500 * 10**6;

        // Stake
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
        vm.prank(merchant);
        bytes32 claimId = insuranceVault.submitClaim(tokenId, claimAmount, "Test claim");

        // Wait for challenge period to expire
        vm.warp(block.timestamp + TestConstants.CHALLENGE_PERIOD + 1);

        // Try to challenge - should fail
        vm.prank(user1);
        vm.expectRevert();
        insuranceVault.challengeClaim(claimId);
    }

    function test_claimFee_calculation() public {
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;
        uint256 claimAmount = 1000 * 10**6; // 1000 USDC
        uint256 expectedFee = (claimAmount * TestConstants.CLAIM_FEE_BPS) / 10000;
        uint256 expectedPayout = claimAmount - expectedFee;

        // Stake
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

        // Submit and resolve claim
        vm.prank(merchant);
        bytes32 claimId = insuranceVault.submitClaim(tokenId, claimAmount, "Test claim");

        uint256 merchantBalanceBefore = mockUSDC.balanceOf(merchant);

        vm.prank(oracle);
        insuranceVault.resolveClaim(claimId, true);

        // Verify payout (merchant receives claimAmount - fee)
        uint256 merchantBalanceAfter = mockUSDC.balanceOf(merchant);
        assertEq(
            merchantBalanceAfter - merchantBalanceBefore,
            expectedPayout,
            "Payout incorrect"
        );
    }

    // =============================================================================
    // Access Control Tests
    // =============================================================================

    function test_onlyOracleCanResolve() public {
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;

        // Stake
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
        vm.prank(merchant);
        bytes32 claimId = insuranceVault.submitClaim(tokenId, 100 * 10**6, "Test claim");

        // Try to resolve as non-oracle - should fail
        vm.prank(user1);
        vm.expectRevert();
        insuranceVault.resolveClaim(claimId, true);
    }

    function test_adminCanUpdateSettings() public {
        // Update minimum stake
        vm.prank(deployer);
        insuranceVault.setMinimumStake(2000 * 10**6);

        assertEq(insuranceVault.minimumStake(), 2000 * 10**6, "Minimum stake not updated");

        // Update claim fee
        vm.prank(deployer);
        insuranceVault.setClaimFee(200); // 2%

        assertEq(insuranceVault.claimFeeBps(), 200, "Claim fee not updated");
    }

    // =============================================================================
    // Edge Cases
    // =============================================================================

    function test_slash_exceedsStake() public {
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;
        uint256 claimAmount = stakeAmount; // Claim full stake (submitClaim doesn't allow more)

        // Stake
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

        // Submit claim for full stake
        vm.prank(merchant);
        bytes32 claimId = insuranceVault.submitClaim(tokenId, claimAmount, "Test claim");

        // Resolve - should slash all available
        vm.prank(oracle);
        insuranceVault.resolveClaim(claimId, true);

        // Verify all stake slashed
        IInsuranceVault.StakeInfo memory stakeInfo = insuranceVault.getStakeInfo(tokenId);
        assertEq(stakeInfo.amount, 0, "All stake should be slashed");
    }

    function test_multipleClaims_sameAgent() public {
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE * 2; // Enough for multiple claims

        // Stake
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

        // Submit multiple claims
        vm.prank(merchant);
        bytes32 claimId1 = insuranceVault.submitClaim(tokenId, 500 * 10**6, "Claim 1");

        vm.prank(merchant);
        bytes32 claimId2 = insuranceVault.submitClaim(tokenId, 500 * 10**6, "Claim 2");

        // Both should be pending
        assertEq(insuranceVault.getClaim(claimId1).status, 0, "Claim 1 should be pending");
        assertEq(insuranceVault.getClaim(claimId2).status, 0, "Claim 2 should be pending");
    }

    // =============================================================================
    // Fuzz Tests
    // =============================================================================

    function testFuzz_stake(uint256 amount) public {
        // Bound amount to reasonable range
        amount = bound(amount, TestConstants.MINIMUM_STAKE, 100000 * 10**6);

        // Fund TBA
        fundTBA(tbaAddress, amount * 2);

        // Approve and stake
        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(mockUSDC),
            0,
            abi.encodeWithSignature("approve(address,uint256)", address(insuranceVault), amount)
        );

        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(insuranceVault),
            0,
            abi.encodeWithSignature("stake(uint256,uint256)", tokenId, amount)
        );

        // Verify
        IInsuranceVault.StakeInfo memory stakeInfo = insuranceVault.getStakeInfo(tokenId);
        assertEq(stakeInfo.amount, amount, "Stake amount incorrect");
        assertTrue(stakeInfo.isVerified, "Should be verified");
    }

    function testFuzz_unstake(uint256 unstakeAmount) public {
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE * 2;
        unstakeAmount = bound(unstakeAmount, 1, stakeAmount);

        // Stake first
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

        // Unstake (not verified if unstaking all, so no cooldown needed)
        if (unstakeAmount < stakeAmount) {
            uint256 balanceBefore = mockUSDC.balanceOf(tbaAddress);

            vm.prank(user1);
            IAgentAccount(tbaAddress).execute(
                address(insuranceVault),
                0,
                abi.encodeWithSignature("unstake(uint256,uint256)", tokenId, unstakeAmount)
            );

            uint256 balanceAfter = mockUSDC.balanceOf(tbaAddress);
            assertEq(balanceAfter - balanceBefore, unstakeAmount, "USDC not returned");
        }
    }

    function testFuzz_claim(uint256 claimAmount) public {
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE * 2;
        claimAmount = bound(claimAmount, 1, stakeAmount);

        // Stake
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
        vm.prank(merchant);
        bytes32 claimId = insuranceVault.submitClaim(tokenId, claimAmount, "Fuzz test claim");

        // Verify claim
        IInsuranceVault.Claim memory claim = insuranceVault.getClaim(claimId);
        assertEq(claim.amount, claimAmount, "Claim amount incorrect");
    }
}

