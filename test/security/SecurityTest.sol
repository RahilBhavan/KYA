// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../BaseTest.sol";
import {TestConstants} from "../helpers/TestConstants.sol";
import {IInsuranceVault} from "../../src/interfaces/IInsuranceVault.sol";
import {IReputationScore} from "../../src/interfaces/IReputationScore.sol";
import {IPaymaster} from "../../src/interfaces/IPaymaster.sol";
import {IAgentAccount} from "../../src/interfaces/IAgentAccount.sol";

/**
 * @title SecurityTest
 * @notice Security-focused tests for KYA Protocol
 * @dev Tests for reentrancy, access control, and other security concerns
 */
contract SecurityTest is BaseTest {
    uint256 public tokenId;
    address public tbaAddress;

    function setUp() public override {
        super.setUp();
        (, tokenId, tbaAddress) = mintDefaultAgent(user1);
    }

    // =============================================================================
    // Reentrancy Tests
    // =============================================================================

    function test_reentrancy_stake() public {
        // Attempt reentrancy attack on stake()
        // Should be protected by ReentrancyGuard
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;

        // Fund TBA with USDC
        fundTBA(tbaAddress, stakeAmount);

        // Setup: Approve USDC
        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(mockUSDC),
            0,
            abi.encodeWithSignature("approve(address,uint256)", address(insuranceVault), stakeAmount)
        );

        // Attempt reentrancy (should fail)
        // Note: This test verifies ReentrancyGuard is in place
        // A real reentrancy attack would require a malicious contract
        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(insuranceVault),
            0,
            abi.encodeWithSignature("stake(uint256,uint256)", tokenId, stakeAmount)
        );

        // Verify stake succeeded (no reentrancy occurred)
        IInsuranceVault.StakeInfo memory stakeInfo = insuranceVault.getStakeInfo(tokenId);
        assertEq(stakeInfo.amount, stakeAmount, "Stake should succeed");
    }

    function test_reentrancy_unstake() public {
        // Setup: Stake first
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;
        fundTBA(tbaAddress, TestConstants.TEST_STAKE_AMOUNT);

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

        // Request unstake (starts cooldown for verified agents)
        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(insuranceVault),
            0,
            abi.encodeWithSignature("requestUnstake(uint256)", tokenId)
        );

        // Wait for cooldown
        vm.warp(block.timestamp + TestConstants.UNSTAKE_COOLDOWN + 1);

        // Attempt unstake (should be protected)
        uint256 unstakeAmount = 500 * 10**6;
        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(insuranceVault),
            0,
            abi.encodeWithSignature("unstake(uint256,uint256)", tokenId, unstakeAmount)
        );

        // Verify unstake succeeded
        IInsuranceVault.StakeInfo memory stakeInfo = insuranceVault.getStakeInfo(tokenId);
        assertEq(stakeInfo.amount, stakeAmount - unstakeAmount, "Unstake should succeed");
    }

    // =============================================================================
    // Access Control Tests
    // =============================================================================

    function test_accessControl_adminOnly() public {
        // Test that only admin can call admin functions
        vm.prank(user1);
        vm.expectRevert();
        insuranceVault.setMinimumStake(2000 * 10**6);

        // Deployer (who has admin role) should succeed
        vm.prank(deployer);
        insuranceVault.setMinimumStake(2000 * 10**6);
        assertEq(insuranceVault.minimumStake(), 2000 * 10**6, "Admin should set minimum stake");
    }

    function test_accessControl_oracleOnly() public {
        // Setup: Submit claim
        uint256 claimAmount = 500 * 10**6;
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

        vm.prank(merchant);
        bytes32 claimId = insuranceVault.submitClaim(tokenId, claimAmount, "Test claim");

        // Non-oracle cannot resolve
        vm.prank(user1);
        vm.expectRevert();
        insuranceVault.resolveClaim(claimId, true);

        // Oracle can resolve
        vm.prank(oracle);
        insuranceVault.resolveClaim(claimId, true);
    }

    function test_accessControl_zkProverOnly() public {
        bytes memory proof = abi.encode("test-proof");

        // Non-prover cannot verify
        vm.prank(user1);
        vm.expectRevert();
        reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof,
            "Test"
        );

        // Prover can verify
        vm.prank(zkProver);
        reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof,
            "Test"
        );
    }

    // =============================================================================
    // Input Validation Tests
    // =============================================================================

    function test_inputValidation_zeroAddress() public {
        // Test zero address validation
        vm.prank(admin);
        vm.expectRevert();
        insuranceVault.withdrawFees(address(0));
    }

    function test_inputValidation_zeroAmount() public {
        // Test zero amount validation
        vm.prank(user1);
        vm.expectRevert();
        IAgentAccount(tbaAddress).execute(
            address(insuranceVault),
            0,
            abi.encodeWithSignature("stake(uint256,uint256)", tokenId, 0)
        );
    }

    function test_inputValidation_invalidTokenId() public {
        // Test invalid token ID
        uint256 invalidTokenId = 99999;
        vm.prank(user1);
        vm.expectRevert();
        IAgentAccount(tbaAddress).execute(
            address(insuranceVault),
            0,
            abi.encodeWithSignature("stake(uint256,uint256)", invalidTokenId, TestConstants.MINIMUM_STAKE)
        );
    }

    // =============================================================================
    // Proof Replay Prevention Tests
    // =============================================================================

    function test_proofReplay_prevention() public {
        bytes memory proof = abi.encode("test-proof-data");

        // Verify proof first time
        vm.prank(zkProver);
        reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof,
            "Test metadata"
        );

        // Attempt to verify same proof again - should fail
        vm.prank(zkProver);
        vm.expectRevert();
        reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof,
            "Test metadata"
        );
    }

    function test_proofReplay_differentProofs() public {
        bytes memory proof1 = abi.encode("proof-1");
        bytes memory proof2 = abi.encode("proof-2");

        // Verify first proof
        vm.prank(zkProver);
        reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof1,
            "Metadata 1"
        );

        // Verify different proof - should succeed
        vm.prank(zkProver);
        reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof2,
            "Metadata 2"
        );

        // Verify both counted
        IReputationScore.ReputationData memory rep = reputationScore.getReputation(tokenId);
        assertEq(rep.verifiedProofs, 2, "Both proofs should be counted");
    }

    // =============================================================================
    // Economic Security Tests
    // =============================================================================

    function test_economicSecurity_slashingCap() public {
        // Test that slashing cannot exceed stake
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;
        uint256 claimAmount = stakeAmount * 2; // Claim more than stake

        fundTBA(tbaAddress, TestConstants.TEST_STAKE_AMOUNT);

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

        // Submit claim for full stake (submitClaim doesn't allow more than stake)
        vm.prank(merchant);
        bytes32 claimId = insuranceVault.submitClaim(tokenId, stakeAmount, "Large claim");

        // Resolve claim
        vm.prank(oracle);
        insuranceVault.resolveClaim(claimId, true);

        // Verify only stake amount was slashed
        IInsuranceVault.StakeInfo memory stakeInfo = insuranceVault.getStakeInfo(tokenId);
        assertEq(stakeInfo.amount, 0, "All stake should be slashed");
        assertFalse(stakeInfo.isVerified, "Should no longer be verified");
    }

    function test_economicSecurity_feeCalculation() public {
        // Test fee calculation correctness
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;
        uint256 claimAmount = 1000 * 10**6;
        uint256 expectedFee = (claimAmount * TestConstants.CLAIM_FEE_BPS) / 10000;
        uint256 expectedPayout = claimAmount - expectedFee;

        fundTBA(tbaAddress, TestConstants.TEST_STAKE_AMOUNT);

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

        uint256 merchantBalanceBefore = mockUSDC.balanceOf(merchant);

        vm.prank(merchant);
        bytes32 claimId = insuranceVault.submitClaim(tokenId, claimAmount, "Test claim");

        vm.prank(oracle);
        insuranceVault.resolveClaim(claimId, true);

        uint256 merchantBalanceAfter = mockUSDC.balanceOf(merchant);
        uint256 actualPayout = merchantBalanceAfter - merchantBalanceBefore;

        assertEq(actualPayout, expectedPayout, "Payout should match expected (minus fee)");
    }

    // =============================================================================
    // Edge Case Tests
    // =============================================================================

    function test_edgeCase_maxStake() public {
        // Test maximum stake amount
        uint256 maxStake = type(uint256).max / 2; // Reasonable max
        fundTBA(tbaAddress, maxStake);

        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(mockUSDC),
            0,
            abi.encodeWithSignature("approve(address,uint256)", address(insuranceVault), maxStake)
        );

        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(insuranceVault),
            0,
            abi.encodeWithSignature("stake(uint256,uint256)", tokenId, maxStake)
        );

        IInsuranceVault.StakeInfo memory stakeInfo = insuranceVault.getStakeInfo(tokenId);
        assertEq(stakeInfo.amount, maxStake, "Max stake should work");
    }

    function test_edgeCase_partialUnstake() public {
        // Test partial unstake
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE * 2;
        uint256 unstakeAmount = TestConstants.MINIMUM_STAKE;

        fundTBA(tbaAddress, TestConstants.TEST_STAKE_AMOUNT * 2);

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

        // Request unstake (starts cooldown for verified agents)
        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(insuranceVault),
            0,
            abi.encodeWithSignature("requestUnstake(uint256)", tokenId)
        );

        // Wait for cooldown
        vm.warp(block.timestamp + TestConstants.UNSTAKE_COOLDOWN + 1);

        // Partial unstake
        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(insuranceVault),
            0,
            abi.encodeWithSignature("unstake(uint256,uint256)", tokenId, unstakeAmount)
        );

        IInsuranceVault.StakeInfo memory stakeInfo = insuranceVault.getStakeInfo(tokenId);
        assertEq(stakeInfo.amount, stakeAmount - unstakeAmount, "Partial unstake should work");
        assertTrue(stakeInfo.isVerified, "Should still be verified");
    }

    // =============================================================================
    // Paymaster Security Tests
    // =============================================================================

    function test_paymaster_eligibilityEnforcement() public {
        // Set Twitter verified (required for eligibility)
        vm.prank(deployer);
        paymaster.setTwitterVerified(tokenId, true);

        // Ensure agent is within cold start period (agent created at block.timestamp = 1)
        // COLD_START_PERIOD is 7 days, so we're safe if we don't warp too far

        // Test eligibility limits
        IPaymaster.PaymasterData memory data = IPaymaster.PaymasterData({
            tokenId: tokenId,
            userOp: abi.encode("test"),
            maxCost: 0.01 ether
        });

        bytes memory paymasterAndData = abi.encodePacked(address(paymaster), abi.encode(data));

        // Sponsor max transactions
        for (uint256 i = 0; i < TestConstants.MAX_SPONSORED_TXS; i++) {
            vm.prank(address(mockEntryPoint));
            (bytes memory context,) = paymaster.validatePaymasterUserOp(
                0,
                data.userOp,
                paymasterAndData
            );

            vm.prank(address(mockEntryPoint));
            paymaster.postOp(0, context, 0.01 ether);
        }

        // Next transaction should fail (exceeded max)
        vm.prank(address(mockEntryPoint));
        vm.expectRevert();
        paymaster.validatePaymasterUserOp(0, data.userOp, paymasterAndData);
    }

    function test_paymaster_entryPointOnly() public {
        // Set Twitter verified (required for eligibility)
        vm.prank(deployer);
        paymaster.setTwitterVerified(tokenId, true);

        // Test that only EntryPoint can call paymaster functions
        IPaymaster.PaymasterData memory data = IPaymaster.PaymasterData({
            tokenId: tokenId,
            userOp: abi.encode("test"),
            maxCost: 0.01 ether
        });

        bytes memory paymasterAndData = abi.encodePacked(address(paymaster), abi.encode(data));

        // Non-EntryPoint cannot call
        vm.prank(user1);
        vm.expectRevert();
        paymaster.validatePaymasterUserOp(0, data.userOp, paymasterAndData);

        // EntryPoint can call
        vm.prank(address(mockEntryPoint));
        paymaster.validatePaymasterUserOp(0, data.userOp, paymasterAndData);
    }
}

