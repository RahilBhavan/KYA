// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../BaseTest.sol";
import {TestConstants} from "../helpers/TestConstants.sol";
import {IInsuranceVault} from "../../src/interfaces/IInsuranceVault.sol";
import {IAgentAccount} from "../../src/interfaces/IAgentAccount.sol";

/**
 * @title InsuranceVaultFuzzTest
 * @notice Fuzz tests for InsuranceVault with edge case coverage
 */
contract InsuranceVaultFuzzTest is BaseTest {
    uint256 public tokenId;
    address public tbaAddress;

    function setUp() public override {
        super.setUp();
        (, tokenId, tbaAddress) = mintDefaultAgent(user1);
    }

    function testFuzz_stake(uint256 amount) public {
        // Bound amount to reasonable range
        amount = bound(amount, TestConstants.MINIMUM_STAKE, 1000000 * 10**6);

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

        // Verify stake
        IInsuranceVault.StakeInfo memory stakeInfo = insuranceVault.getStakeInfo(tokenId);
        assertEq(stakeInfo.amount, amount, "Stake amount should match");
        assertTrue(stakeInfo.isVerified, "Should be verified");
    }

    function testFuzz_unstake(uint256 stakeAmount, uint256 unstakeAmount) public {
        // Bound amounts
        stakeAmount = bound(stakeAmount, TestConstants.MINIMUM_STAKE, 100000 * 10**6);
        unstakeAmount = bound(unstakeAmount, 1, stakeAmount);

        // Fund and stake
        fundTBA(tbaAddress, stakeAmount * 2);

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

        // Unstake (if not verified, no cooldown needed)
        // If verified, we need to request unstake and wait for cooldown
        bool isVerified = insuranceVault.isVerified(tokenId);
        
        if (isVerified && unstakeAmount < stakeAmount) {
            // Request unstake to start cooldown
            vm.prank(user1);
            IAgentAccount(tbaAddress).execute(
                address(insuranceVault),
                0,
                abi.encodeWithSignature("requestUnstake(uint256)", tokenId)
            );
            // Wait for cooldown
            vm.warp(block.timestamp + TestConstants.UNSTAKE_COOLDOWN + 1);
        }

        uint256 balanceBefore = mockUSDC.balanceOf(tbaAddress);

        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(insuranceVault),
            0,
            abi.encodeWithSignature("unstake(uint256,uint256)", tokenId, unstakeAmount)
        );

        // Verify unstake
        uint256 balanceAfter = mockUSDC.balanceOf(tbaAddress);
        assertEq(balanceAfter - balanceBefore, unstakeAmount, "USDC should be returned");

        IInsuranceVault.StakeInfo memory stakeInfo = insuranceVault.getStakeInfo(tokenId);
        assertEq(stakeInfo.amount, stakeAmount - unstakeAmount, "Stake should be reduced");
    }

    function testFuzz_claim(uint256 stakeAmount, uint256 claimAmount) public {
        // Bound amounts
        stakeAmount = bound(stakeAmount, TestConstants.MINIMUM_STAKE, 100000 * 10**6);
        claimAmount = bound(claimAmount, 1, stakeAmount);

        // Fund and stake
        fundTBA(tbaAddress, stakeAmount * 2);

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
        assertEq(claim.amount, claimAmount, "Claim amount should match");
        assertEq(claim.status, 0, "Claim should be pending");
    }

    function testFuzz_multipleStakes(uint256 stake1, uint256 stake2) public {
        // Bound amounts
        stake1 = bound(stake1, TestConstants.MINIMUM_STAKE, 100000 * 10**6);
        stake2 = bound(stake2, 1, 100000 * 10**6);

        // Fund TBA
        fundTBA(tbaAddress, (stake1 + stake2) * 2);

        // First stake
        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(mockUSDC),
            0,
            abi.encodeWithSignature("approve(address,uint256)", address(insuranceVault), stake1)
        );

        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(insuranceVault),
            0,
            abi.encodeWithSignature("stake(uint256,uint256)", tokenId, stake1)
        );

        // Second stake
        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(mockUSDC),
            0,
            abi.encodeWithSignature("approve(address,uint256)", address(insuranceVault), stake2)
        );

        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(insuranceVault),
            0,
            abi.encodeWithSignature("stake(uint256,uint256)", tokenId, stake2)
        );

        // Verify total stake
        IInsuranceVault.StakeInfo memory stakeInfo = insuranceVault.getStakeInfo(tokenId);
        assertEq(stakeInfo.amount, stake1 + stake2, "Total stake should match");
    }
}

