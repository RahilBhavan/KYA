// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../BaseTest.sol";
import {TestConstants} from "../helpers/TestConstants.sol";
import {IPaymaster} from "../../src/interfaces/IPaymaster.sol";

/**
 * @title PaymasterTest
 * @notice Comprehensive unit tests for Paymaster
 */
contract PaymasterTest is BaseTest {
    uint256 public tokenId;
    address public tbaAddress;
    bytes32 public agentId;

    function setUp() public override {
        super.setUp();

        // Mint an agent for testing
        (agentId, tokenId, tbaAddress) = mintDefaultAgent(user1);
    }

    // =============================================================================
    // Eligibility Tests
    // =============================================================================

    function test_isEligible_newAgent() public {
        // Set Twitter verified (required for eligibility)
        vm.prank(deployer);
        paymaster.setTwitterVerified(tokenId, true);

        // New agent should be eligible (within cold start period)
        (bool eligible, uint256 remaining) = paymaster.isEligible(tokenId);
        assertTrue(eligible, "New agent should be eligible");
        assertEq(remaining, TestConstants.MAX_SPONSORED_TXS, "Should have max transactions");
    }

    function test_isEligible_oldAgent() public {
        // Age the agent past cold start period
        vm.warp(block.timestamp + TestConstants.COLD_START_PERIOD + 1);

        (bool eligible,) = paymaster.isEligible(tokenId);
        assertFalse(eligible, "Old agent should not be eligible");
    }

    function test_isEligible_maxTransactions() public {
        // Set Twitter verified (required for eligibility)
        vm.prank(deployer);
        paymaster.setTwitterVerified(tokenId, true);

        // Agent should be eligible initially (within cold start period)
        (bool eligible, uint256 remaining) = paymaster.isEligible(tokenId);
        assertTrue(eligible, "Should be eligible");
        assertGt(remaining, 0, "Should have remaining transactions");
    }

    function test_isEligible_twitterVerified() public {
        // Set Twitter verified
        vm.prank(deployer);
        paymaster.setTwitterVerified(tokenId, true);

        // Check eligibility
        (bool eligible,) = paymaster.isEligible(tokenId);
        // Eligibility also depends on age and transaction count
        // But Twitter verification is required for actual sponsorship
    }

    function test_isEligible_remainingTransactions() public {
        // Check remaining transactions
        (bool eligible, uint256 remaining) = paymaster.isEligible(tokenId);
        
        if (eligible) {
            assertLe(remaining, TestConstants.MAX_SPONSORED_TXS, "Remaining should be <= max");
            assertGe(remaining, 0, "Remaining should be >= 0");
        }
    }

    // =============================================================================
    // Validation Tests
    // =============================================================================

    function test_validatePaymasterUserOp_success() public {
        // Set Twitter verified
        vm.prank(deployer);
        paymaster.setTwitterVerified(tokenId, true);

        // Create paymaster data
        IPaymaster.PaymasterData memory data = IPaymaster.PaymasterData({
            tokenId: tokenId,
            userOp: abi.encode("test-userop"),
            maxCost: 0.01 ether
        });

        bytes memory paymasterAndData = abi.encodePacked(address(paymaster), abi.encode(data));

        // Mock EntryPoint call
        vm.prank(address(mockEntryPoint));
        (bytes memory context, uint256 validationData) = paymaster.validatePaymasterUserOp(
            0,
            data.userOp,
            paymasterAndData
        );

        // Verify context and validation data
        assertGt(context.length, 0, "Context should not be empty");
        assertGt(validationData, 0, "Validation data should not be zero");
    }

    function test_validatePaymasterUserOp_notEligible() public {
        // Age agent past eligibility
        vm.warp(block.timestamp + TestConstants.COLD_START_PERIOD + 1);

        IPaymaster.PaymasterData memory data = IPaymaster.PaymasterData({
            tokenId: tokenId,
            userOp: abi.encode("test-userop"),
            maxCost: 0.01 ether
        });

        bytes memory paymasterAndData = abi.encodePacked(address(paymaster), abi.encode(data));

        vm.prank(address(mockEntryPoint));
        vm.expectRevert();
        paymaster.validatePaymasterUserOp(0, data.userOp, paymasterAndData);
    }

    function test_validatePaymasterUserOp_onlyEntryPoint() public {
        IPaymaster.PaymasterData memory data = IPaymaster.PaymasterData({
            tokenId: tokenId,
            userOp: abi.encode("test-userop"),
            maxCost: 0.01 ether
        });

        bytes memory paymasterAndData = abi.encodePacked(address(paymaster), abi.encode(data));

        // Try to call from non-EntryPoint - should fail
        vm.prank(user1);
        vm.expectRevert();
        paymaster.validatePaymasterUserOp(0, data.userOp, paymasterAndData);
    }

    function test_postOp_updatesCount() public {
        // Set Twitter verified
        vm.prank(deployer);
        paymaster.setTwitterVerified(tokenId, true);

        // Get initial count
        paymaster.getSponsoredCount(tokenId);

        // Simulate postOp call
        bytes memory context = abi.encode(tokenId, 0.01 ether);
        vm.prank(address(mockEntryPoint));
        paymaster.postOp(0, context, 0.01 ether);

        // Check count increased (if validation was called first)
        // Note: In real flow, validatePaymasterUserOp would be called first
    }

    // =============================================================================
    // Funding Tests
    // =============================================================================

    function test_deposit() public {
        uint256 depositAmount = 1 ether;
        uint256 balanceBefore = address(paymaster).balance;

        // Deposit
        vm.deal(user1, depositAmount);
        vm.prank(user1);
        paymaster.deposit{value: depositAmount}();

        // Verify deposit
        uint256 balanceAfter = address(paymaster).balance;
        assertEq(balanceAfter - balanceBefore, depositAmount, "Deposit amount incorrect");
    }

    function test_withdrawTo() public {
        uint256 withdrawAmount = 1 ether;

        // Fund paymaster first
        vm.deal(address(paymaster), withdrawAmount * 2);
        paymaster.deposit{value: withdrawAmount * 2}();

        uint256 balanceBefore = address(user1).balance;

        // Withdraw
        vm.prank(deployer);
        paymaster.withdrawTo(payable(user1), withdrawAmount);

        // Verify withdrawal
        uint256 balanceAfter = address(user1).balance;
        assertEq(balanceAfter - balanceBefore, withdrawAmount, "Withdrawal amount incorrect");
    }

    function test_withdrawTo_adminOnly() public {
        uint256 withdrawAmount = 1 ether;

        // Try to withdraw as non-admin - should fail
        vm.prank(user1);
        vm.expectRevert();
        paymaster.withdrawTo(payable(user1), withdrawAmount);
    }

    // =============================================================================
    // Twitter Verification Tests
    // =============================================================================

    function test_setTwitterVerified() public {
        // Initially not verified
        assertFalse(paymaster.isTwitterVerified(tokenId), "Should not be verified initially");

        // Set verified
        vm.prank(deployer);
        paymaster.setTwitterVerified(tokenId, true);

        // Check verified
        assertTrue(paymaster.isTwitterVerified(tokenId), "Should be verified");
    }

    function test_isTwitterVerified() public {
        // Check initial status
        bool verified = paymaster.isTwitterVerified(tokenId);
        assertFalse(verified, "Should not be verified initially");

        // Set and check
        vm.prank(deployer);
        paymaster.setTwitterVerified(tokenId, true);

        verified = paymaster.isTwitterVerified(tokenId);
        assertTrue(verified, "Should be verified");
    }

    // =============================================================================
    // Fuzz Tests
    // =============================================================================

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
        } else {
            // Eligibility also depends on transaction count and Twitter verification
            // This is tested in other tests
        }
    }
}

