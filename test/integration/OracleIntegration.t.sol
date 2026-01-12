// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../BaseTest.sol";
import {TestConstants} from "../helpers/TestConstants.sol";
import {IInsuranceVault} from "../../src/interfaces/IInsuranceVault.sol";
import {IAgentAccount} from "../../src/interfaces/IAgentAccount.sol";

/**
 * @title OracleIntegrationTest
 * @notice Integration tests for oracle dispute resolution with UMA/Kleros
 * 
 * Note: For real integration, configure UMA/Kleros test environment.
 * This test includes both real integration patterns and mock alternatives.
 */
contract OracleIntegrationTest is BaseTest {
    uint256 public tokenId;
    address public tbaAddress;
    bytes32 public claimId;

    function setUp() public override {
        super.setUp();

        // Mint and setup agent
        (, tokenId, tbaAddress) = mintDefaultAgent(user1);

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
    }

    /**
     * @notice Test UMA claim submission
     */
    function test_uma_claimSubmission() public {
        uint256 claimAmount = 500 * 10**6;

        // Submit claim
        vm.prank(merchant);
        claimId = insuranceVault.submitClaim(
            tokenId,
            claimAmount,
            "UMA: Malicious behavior detected"
        );

        // Verify claim submitted
        IInsuranceVault.Claim memory claim = insuranceVault.getClaim(claimId);
        assertEq(claim.status, 0, "Claim should be pending");
        assertEq(claim.tokenId, tokenId, "Token ID incorrect");
        assertEq(claim.merchant, merchant, "Merchant incorrect");

        // In real integration:
        // 1. Claim would be submitted to UMA
        // 2. UMA would validate off-chain
        // 3. UMA would call resolveClaim() with result
    }

    /**
     * @notice Test UMA claim resolution
     */
    function test_uma_claimResolution() public {
        uint256 claimAmount = 500 * 10**6;
        uint256 stakeBefore = insuranceVault.getStakeInfo(tokenId).amount;

        // Submit claim
        vm.prank(merchant);
        claimId = insuranceVault.submitClaim(tokenId, claimAmount, "UMA claim");

        // Simulate UMA oracle resolution (approved)
        vm.prank(oracle); // Oracle role represents UMA in this test
        insuranceVault.resolveClaim(claimId, true);

        // Verify claim resolved and slashing occurred
        IInsuranceVault.Claim memory claim = insuranceVault.getClaim(claimId);
        assertEq(claim.status, 1, "Claim should be approved");

        IInsuranceVault.StakeInfo memory stakeAfter = insuranceVault.getStakeInfo(tokenId);
        assertLt(stakeAfter.amount, stakeBefore, "Stake should be reduced");
    }

    /**
     * @notice Test UMA challenge flow
     */
    function test_uma_challengeFlow() public {
        uint256 claimAmount = 500 * 10**6;

        // Submit claim
        vm.prank(merchant);
        claimId = insuranceVault.submitClaim(tokenId, claimAmount, "UMA claim");

        // Agent challenges claim
        vm.prank(user1);
        insuranceVault.challengeClaim(claimId);

        // Verify claim challenged
        IInsuranceVault.Claim memory claim = insuranceVault.getClaim(claimId);
        assertEq(claim.status, 3, "Claim should be challenged");

        // In real integration:
        // 1. Challenge would escalate to UMA dispute resolution
        // 2. UMA would conduct human arbitration
        // 3. Final resolution would be called via resolveClaim()
    }

    /**
     * @notice Test Kleros arbitration flow
     */
    function test_kleros_arbitration() public {
        uint256 claimAmount = 500 * 10**6;

        // Submit claim
        vm.prank(merchant);
        claimId = insuranceVault.submitClaim(tokenId, claimAmount, "Kleros claim");

        // Challenge (triggers Kleros arbitration)
        vm.prank(user1);
        insuranceVault.challengeClaim(claimId);

        // Simulate Kleros arbitration result
        // In real integration, Kleros would call resolveClaim() after arbitration
        vm.prank(oracle); // Oracle role represents Kleros in this test
        insuranceVault.resolveClaim(claimId, false); // Rejected after arbitration

        // Verify claim rejected
        IInsuranceVault.Claim memory claim = insuranceVault.getClaim(claimId);
        assertEq(claim.status, 2, "Claim should be rejected");
    }

    /**
     * @notice Test slashing after oracle resolution
     */
    function test_oracle_slashing() public {
        uint256 claimAmount = 500 * 10**6;
        uint256 merchantBalanceBefore = mockUSDC.balanceOf(merchant);
        uint256 stakeBefore = insuranceVault.getStakeInfo(tokenId).amount;

        // Submit claim
        vm.prank(merchant);
        claimId = insuranceVault.submitClaim(tokenId, claimAmount, "Oracle claim");

        // Oracle resolves (approved)
        vm.prank(oracle);
        insuranceVault.resolveClaim(claimId, true);

        // Verify slashing
        uint256 merchantBalanceAfter = mockUSDC.balanceOf(merchant);
        assertGt(merchantBalanceAfter, merchantBalanceBefore, "Merchant should receive payout");

        IInsuranceVault.StakeInfo memory stakeAfter = insuranceVault.getStakeInfo(tokenId);
        assertLt(stakeAfter.amount, stakeBefore, "Stake should be reduced");

        // Calculate expected payout (claimAmount - fee)
        uint256 expectedFee = (claimAmount * TestConstants.CLAIM_FEE_BPS) / 10000;
        uint256 expectedPayout = claimAmount - expectedFee;
        assertEq(
            merchantBalanceAfter - merchantBalanceBefore,
            expectedPayout,
            "Payout should match expected"
        );
    }

    /**
     * @notice Mock oracle resolution for testing
     */
    function test_mockOracleResolution() public {
        uint256 claimAmount = 500 * 10**6;

        // Submit claim
        vm.prank(merchant);
        claimId = insuranceVault.submitClaim(tokenId, claimAmount, "Mock claim");

        // Mock oracle decision (simulate off-chain validation)
        bool oracleDecision = true; // Mock decision

        // Resolve claim
        vm.prank(oracle);
        insuranceVault.resolveClaim(claimId, oracleDecision);

        // Verify resolution
        IInsuranceVault.Claim memory claim = insuranceVault.getClaim(claimId);
        if (oracleDecision) {
            assertEq(claim.status, 1, "Claim should be approved");
        } else {
            assertEq(claim.status, 2, "Claim should be rejected");
        }
    }
}

