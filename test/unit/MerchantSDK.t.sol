// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../BaseTest.sol";
import {TestConstants} from "../helpers/TestConstants.sol";
import {IMerchantSDK} from "../../src/interfaces/IMerchantSDK.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAgentAccount} from "../../src/interfaces/IAgentAccount.sol";
import {IInsuranceVault} from "../../src/interfaces/IInsuranceVault.sol";

/**
 * @title MerchantSDKTest
 * @notice Comprehensive unit tests for MerchantSDK
 */
contract MerchantSDKTest is BaseTest {
    uint256 public tokenId;
    address public tbaAddress;
    bytes32 public agentId;

    function setUp() public override {
        super.setUp();

        // Mint an agent for testing
        (agentId, tokenId, tbaAddress) = mintDefaultAgent(user1);
    }

    // =============================================================================
    // Verification Tests
    // =============================================================================

    function test_verifyAgent_verified() public {
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;

        // Fund TBA with USDC
        fundTBA(tbaAddress, stakeAmount);

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

        // Verify agent
        IMerchantSDK.VerificationResult memory result = merchantSDK.verifyAgent(
            tokenId,
            tbaAddress
        );

        assertTrue(result.isVerified, "Agent should be verified");
        assertEq(result.stakeAmount, stakeAmount, "Stake amount incorrect");
        assertTrue(result.isActive, "Agent should be active");
    }

    function test_verifyAgent_unverified() public {
        // Verify unverified agent
        IMerchantSDK.VerificationResult memory result = merchantSDK.verifyAgent(
            tokenId,
            tbaAddress
        );

        assertFalse(result.isVerified, "Agent should not be verified");
        assertEq(result.stakeAmount, 0, "Stake amount should be zero");
        assertTrue(result.isActive, "Agent should be active");
    }

    function test_verifyAgent_suspended() public {
        // Suspend agent
        vm.prank(deployer);
        agentLicense.updateAgentStatus(tokenId, 1); // Suspended

        // Verify suspended agent
        IMerchantSDK.VerificationResult memory result = merchantSDK.verifyAgent(
            tokenId,
            tbaAddress
        );

        assertFalse(result.isActive, "Agent should not be active");
    }

    function test_verifyAgent_invalidTBA() public {
        address invalidTBA = address(0x999);

        // Should revert with invalid TBA
        vm.expectRevert();
        merchantSDK.verifyAgent(tokenId, invalidTBA);
    }

    // =============================================================================
    // Requirements Tests
    // =============================================================================

    function test_meetsRequirements_success() public {
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;
        uint256 minStake = TestConstants.MINIMUM_STAKE;
        uint256 minReputation = 0; // No reputation requirement

        // Fund TBA with USDC
        fundTBA(tbaAddress, stakeAmount);

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

        // Check requirements
        bool meetsRequirements = merchantSDK.meetsRequirements(
            tokenId,
            minStake,
            minReputation
        );

        assertTrue(meetsRequirements, "Should meet requirements");
    }

    function test_meetsRequirements_lowStake() public {
        uint256 minStake = TestConstants.MINIMUM_STAKE;
        uint256 minReputation = 0;

        // Don't stake (or stake less than minimum)
        // Check requirements
        bool meetsRequirements = merchantSDK.meetsRequirements(
            tokenId,
            minStake,
            minReputation
        );

        assertFalse(meetsRequirements, "Should not meet requirements (low stake)");
    }

    function test_meetsRequirements_lowReputation() public {
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;
        uint256 minStake = TestConstants.MINIMUM_STAKE;
        uint256 minReputation = 1000; // High reputation requirement

        // Fund TBA with USDC
        fundTBA(tbaAddress, stakeAmount);

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

        // Check requirements (no reputation yet)
        bool meetsRequirements = merchantSDK.meetsRequirements(
            tokenId,
            minStake,
            minReputation
        );

        assertFalse(meetsRequirements, "Should not meet requirements (low reputation)");
    }

    function test_meetsRequirements_inactive() public {
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;

        // Fund TBA with USDC
        fundTBA(tbaAddress, stakeAmount);

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

        // Suspend agent
        vm.prank(deployer);
        agentLicense.updateAgentStatus(tokenId, 1); // Suspended

        // Check requirements
        bool meetsRequirements = merchantSDK.meetsRequirements(
            tokenId,
            TestConstants.MINIMUM_STAKE,
            0
        );

        assertFalse(meetsRequirements, "Should not meet requirements (inactive)");
    }

    // =============================================================================
    // Coverage Tests
    // =============================================================================

    function test_getCoverage() public {
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;

        // Fund TBA with USDC
        fundTBA(tbaAddress, stakeAmount);

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

        // Get coverage
        uint256 coverage = merchantSDK.getCoverage(tokenId);
        assertEq(coverage, stakeAmount, "Coverage should equal stake");
    }

    function test_getCoverage_zero() public {
        // Get coverage for unstaked agent
        uint256 coverage = merchantSDK.getCoverage(tokenId);
        assertEq(coverage, 0, "Coverage should be zero");
    }

    // =============================================================================
    // Violation Reporting Tests
    // =============================================================================

    function test_reportViolation_success() public {
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;

        // Fund TBA with USDC
        fundTBA(tbaAddress, stakeAmount);

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

        // Report violation
        IMerchantSDK.Violation memory violation = IMerchantSDK.Violation({
            conditionType: "RateLimit",
            description: "Exceeded transaction rate",
            evidence: abi.encode("tx-hash-123")
        });

        vm.prank(merchant);
        bytes32 claimId = merchantSDK.reportViolation(tokenId, violation);

        // Verify claim created
        assertNotEq(claimId, bytes32(0), "Claim ID should not be zero");
    }

    function test_reportViolation_noCoverage() public {
        // Try to report violation without coverage
        IMerchantSDK.Violation memory violation = IMerchantSDK.Violation({
            conditionType: "RateLimit",
            description: "Exceeded transaction rate",
            evidence: abi.encode("tx-hash-123")
        });

        vm.prank(merchant);
        vm.expectRevert();
        merchantSDK.reportViolation(tokenId, violation);
    }

    function test_reportViolation_createsClaim() public {
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;

        // Fund TBA with USDC
        fundTBA(tbaAddress, stakeAmount);

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

        // Report violation
        IMerchantSDK.Violation memory violation = IMerchantSDK.Violation({
            conditionType: "RateLimit",
            description: "Exceeded transaction rate",
            evidence: abi.encode("tx-hash-123")
        });

        vm.prank(merchant);
        bytes32 claimId = merchantSDK.reportViolation(tokenId, violation);

        // Verify claim exists in InsuranceVault
        // Note: The merchant in the claim is the MerchantSDK contract (msg.sender), not the original merchant
        IInsuranceVault.Claim memory claim = insuranceVault.getClaim(claimId);
        assertEq(claim.tokenId, tokenId, "Claim token ID incorrect");
        assertEq(claim.merchant, address(merchantSDK), "Claim merchant should be MerchantSDK contract");
    }
}

