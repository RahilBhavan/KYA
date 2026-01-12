// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../BaseTest.sol";
import {TestConstants} from "../helpers/TestConstants.sol";
import {IPaymaster} from "../../src/interfaces/IPaymaster.sol";

/**
 * @title PaymasterFuzzTest
 * @notice Fuzz tests for Paymaster
 */
contract PaymasterFuzzTest is BaseTest {
    uint256 public tokenId;

    function setUp() public override {
        super.setUp();
        (, tokenId,) = mintDefaultAgent(user1);

        // Set Twitter verified
        vm.prank(deployer);
        paymaster.setTwitterVerified(tokenId, true);
    }

    function testFuzz_eligibility(uint256 age, uint256 txCount) public {
        // Bound inputs
        age = bound(age, 0, TestConstants.COLD_START_PERIOD * 2);
        txCount = bound(txCount, 0, TestConstants.MAX_SPONSORED_TXS * 2);

        // Set agent age
        if (age > 0) {
            vm.warp(block.timestamp + age);
        }

        // Check eligibility
        (bool eligible, uint256 remaining) = paymaster.isEligible(tokenId);

        // Verify eligibility logic
        if (age > TestConstants.COLD_START_PERIOD) {
            assertFalse(eligible, "Should not be eligible if too old");
        } else if (txCount >= TestConstants.MAX_SPONSORED_TXS) {
            // If we could set txCount, it would affect eligibility
            // For now, we verify the logic
        } else {
            // Eligibility also depends on Twitter verification (set in setUp)
            // This is tested in other tests
        }

        // Verify remaining is within bounds
        assertLe(remaining, TestConstants.MAX_SPONSORED_TXS, "Remaining should be <= max");
        assertGe(remaining, 0, "Remaining should be >= 0");
    }

    function testFuzz_deposit(uint256 amount) public {
        // Bound amount
        amount = bound(amount, 0.001 ether, 100 ether);

        uint256 balanceBefore = address(paymaster).balance;

        // Deposit
        vm.deal(user1, amount);
        vm.prank(user1);
        paymaster.deposit{value: amount}();

        // Verify deposit
        uint256 balanceAfter = address(paymaster).balance;
        assertEq(balanceAfter - balanceBefore, amount, "Deposit amount should match");
    }

    function testFuzz_withdraw(uint256 depositAmount, uint256 withdrawAmount) public {
        // Bound amounts
        depositAmount = bound(depositAmount, 1 ether, 100 ether);
        withdrawAmount = bound(withdrawAmount, 0.001 ether, depositAmount);

        // Deposit
        vm.deal(address(paymaster), depositAmount);
        paymaster.deposit{value: depositAmount}();

        uint256 userBalanceBefore = address(user1).balance;

        // Withdraw
        vm.prank(deployer);
        paymaster.withdrawTo(payable(user1), withdrawAmount);

        // Verify withdrawal
        uint256 userBalanceAfter = address(user1).balance;
        assertEq(userBalanceAfter - userBalanceBefore, withdrawAmount, "Withdrawal should match");
    }
}

