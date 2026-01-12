// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../BaseTest.sol";
import {TestConstants} from "../helpers/TestConstants.sol";
import {IPaymaster} from "../../src/interfaces/IPaymaster.sol";

/**
 * @title PaymasterIntegrationTest
 * @notice Integration tests for ERC-4337 Paymaster with EntryPoint
 */
contract PaymasterIntegrationTest is BaseTest {
    uint256 public tokenId;
    address public tbaAddress;

    function setUp() public override {
        super.setUp();

        // Mint agent
        (, tokenId, tbaAddress) = mintDefaultAgent(user1);

        // Set Twitter verified
        vm.prank(deployer);
        paymaster.setTwitterVerified(tokenId, true);
    }

    /**
     * @notice Test gas sponsorship flow
     */
    function test_paymaster_gasSponsorship() public {
        // Create paymaster data
        IPaymaster.PaymasterData memory data = IPaymaster.PaymasterData({
            tokenId: tokenId,
            userOp: abi.encode("test-userop"),
            maxCost: 0.01 ether
        });

        bytes memory paymasterAndData = abi.encodePacked(address(paymaster), abi.encode(data));

        // Validate user operation
        vm.prank(address(mockEntryPoint));
        (bytes memory context, uint256 validationData) = paymaster.validatePaymasterUserOp(
            0,
            data.userOp,
            paymasterAndData
        );

        // Verify validation
        assertGt(context.length, 0, "Context should not be empty");
        assertGt(validationData, 0, "Validation data should not be zero");

        // Simulate post-operation
        vm.prank(address(mockEntryPoint));
        paymaster.postOp(0, context, 0.01 ether);

        // Verify sponsored count increased
        uint256 sponsoredCount = paymaster.getSponsoredCount(tokenId);
        assertGt(sponsoredCount, 0, "Sponsored count should increase");
    }

    /**
     * @notice Test transaction limit enforcement
     */
    function test_paymaster_transactionLimit() public {
        IPaymaster.PaymasterData memory data = IPaymaster.PaymasterData({
            tokenId: tokenId,
            userOp: abi.encode("test-userop"),
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

        // Verify at limit
        (bool eligible, uint256 remaining) = paymaster.isEligible(tokenId);
        assertFalse(eligible, "Should not be eligible after max transactions");
        assertEq(remaining, 0, "Remaining should be zero");
    }

    /**
     * @notice Test eligibility window enforcement
     */
    function test_paymaster_eligibilityWindow() public {
        // Agent should be eligible initially
        (bool eligible,) = paymaster.isEligible(tokenId);
        assertTrue(eligible, "Should be eligible initially");

        // Age agent past cold start period
        vm.warp(block.timestamp + TestConstants.COLD_START_PERIOD + 1);

        // Should no longer be eligible
        (eligible,) = paymaster.isEligible(tokenId);
        assertFalse(eligible, "Should not be eligible after cold start period");
    }

    /**
     * @notice Test EntryPoint integration
     */
    function test_paymaster_entryPointIntegration() public {
        // Verify EntryPoint address
        address entryPoint = paymaster.entryPoint();
        assertEq(entryPoint, address(mockEntryPoint), "EntryPoint address incorrect");

        // Test EntryPoint can call validation
        IPaymaster.PaymasterData memory data = IPaymaster.PaymasterData({
            tokenId: tokenId,
            userOp: abi.encode("test-userop"),
            maxCost: 0.01 ether
        });

        bytes memory paymasterAndData = abi.encodePacked(address(paymaster), abi.encode(data));

        vm.prank(address(mockEntryPoint));
        (bytes memory context, uint256 validationData) = paymaster.validatePaymasterUserOp(
            0,
            data.userOp,
            paymasterAndData
        );

        // Verify EntryPoint interaction
        assertGt(context.length, 0, "Context should be set");
        assertGt(validationData, 0, "Validation data should be set");

        // Test non-EntryPoint cannot call
        vm.prank(user1);
        vm.expectRevert();
        paymaster.validatePaymasterUserOp(0, data.userOp, paymasterAndData);
    }
}

