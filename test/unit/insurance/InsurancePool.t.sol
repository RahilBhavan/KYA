// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../../BaseTest.sol";
import {InsurancePool} from "../../../src/insurance/InsurancePool.sol";
import {RiskCalculator} from "../../../src/insurance/RiskCalculator.sol";
import {IInsurancePool} from "../../../src/insurance/IInsurancePool.sol";
import {TestConstants} from "../../helpers/TestConstants.sol";

/**
 * @title InsurancePoolTest
 * @notice Comprehensive tests for Insurance Pool
 */
contract InsurancePoolTest is BaseTest {
    InsurancePool public insurancePool;
    RiskCalculator public riskCalculator;
    uint256 public tokenId;
    address public tbaAddress;
    bytes32 public agentId;

    function setUp() public override {
        super.setUp();

        // Mint an agent
        (agentId, tokenId, tbaAddress) = mintDefaultAgent(user1);

        // Deploy RiskCalculator
        vm.prank(deployer);
        riskCalculator = new RiskCalculator(
            address(reputationScore),
            address(insuranceVault)
        );

        // Deploy InsurancePool
        vm.prank(deployer);
        insurancePool = new InsurancePool(
            address(mockUSDC),
            address(agentLicense),
            address(insuranceVault),
            address(riskCalculator)
        );

        // Fund user1 with USDC
        mockUSDC.mint(user1, 100_000 * 10**6); // 100k USDC
    }

    // =============================================================================
    // Pool Creation Tests
    // =============================================================================

    function test_createPool_success() public {
        vm.prank(deployer);
        uint256 poolId = insurancePool.createPool("Low Risk Pool", 100, 20); // 1% premium, 20 risk

        IInsurancePool.Pool memory pool = insurancePool.getPool(poolId);
        assertEq(pool.name, "Low Risk Pool", "Pool name should match");
        assertEq(pool.premiumRate, 100, "Premium rate should match");
        assertEq(pool.riskLevel, 20, "Risk level should match");
        assertTrue(pool.active, "Pool should be active");
    }

    function test_createPool_onlyAdmin() public {
        vm.prank(user1);
        vm.expectRevert();
        insurancePool.createPool("Test Pool", 100, 20);
    }

    // =============================================================================
    // Join Pool Tests
    // =============================================================================

    function test_joinPool_success() public {
        // Create pool
        vm.prank(deployer);
        uint256 poolId = insurancePool.createPool("Test Pool", 100, 20);

        // Calculate total needed (stake + premium)
        uint256 stakeAmount = 10_000 * 10**6; // 10k USDC
        uint256 premium = (stakeAmount * 100) / 10000; // 1% premium
        uint256 totalNeeded = stakeAmount + premium;

        // Approve USDC (need to cover stake + premium)
        vm.prank(user1);
        mockUSDC.approve(address(insurancePool), totalNeeded);

        // Join pool
        vm.prank(user1);
        insurancePool.joinPool(poolId, tokenId, stakeAmount);

        IInsurancePool.Pool memory pool = insurancePool.getPool(poolId);
        assertEq(pool.totalStaked, stakeAmount, "Total staked should match");

        IInsurancePool.Participant memory participant = insurancePool.getParticipant(poolId, tokenId);
        assertEq(participant.stakeAmount, stakeAmount, "Participant stake should match");
    }

    function test_joinPool_alreadyParticipant() public {
        vm.prank(deployer);
        uint256 poolId = insurancePool.createPool("Test Pool", 100, 20);

        // Calculate total needed for first join
        uint256 stakeAmount1 = 10_000 * 10**6;
        uint256 premium1 = (stakeAmount1 * 100) / 10000;
        uint256 totalNeeded1 = stakeAmount1 + premium1;

        vm.prank(user1);
        mockUSDC.approve(address(insurancePool), totalNeeded1);

        vm.prank(user1);
        insurancePool.joinPool(poolId, tokenId, stakeAmount1);

        // Try to join again (should fail)
        uint256 stakeAmount2 = 5_000 * 10**6;
        uint256 premium2 = (stakeAmount2 * 100) / 10000;
        uint256 totalNeeded2 = stakeAmount2 + premium2;

        vm.prank(user1);
        mockUSDC.approve(address(insurancePool), totalNeeded2);

        vm.prank(user1);
        vm.expectRevert();
        insurancePool.joinPool(poolId, tokenId, stakeAmount2);
    }

    // =============================================================================
    // Leave Pool Tests
    // =============================================================================

    function test_leavePool_success() public {
        vm.prank(deployer);
        uint256 poolId = insurancePool.createPool("Test Pool", 100, 20);

        // Calculate total needed (stake + premium)
        uint256 stakeAmount = 10_000 * 10**6;
        uint256 premium = (stakeAmount * 100) / 10000; // 1% premium
        uint256 totalNeeded = stakeAmount + premium;

        vm.prank(user1);
        mockUSDC.approve(address(insurancePool), totalNeeded);

        uint256 balanceBeforeJoin = mockUSDC.balanceOf(user1);
        vm.prank(user1);
        insurancePool.joinPool(poolId, tokenId, stakeAmount);
        uint256 balanceAfterJoin = mockUSDC.balanceOf(user1);

        // User should have paid stake + premium
        assertEq(balanceBeforeJoin - balanceAfterJoin, totalNeeded, "Should pay stake + premium");

        uint256 balanceBeforeLeave = mockUSDC.balanceOf(user1);
        vm.prank(user1);
        insurancePool.leavePool(poolId, tokenId);
        uint256 balanceAfterLeave = mockUSDC.balanceOf(user1);

        // User should get back only the stake (premium is not refunded)
        assertEq(balanceAfterLeave - balanceBeforeLeave, stakeAmount, "Should return stake amount");
    }

    // =============================================================================
    // Risk Calculator Tests
    // =============================================================================

    function test_calculateRisk() public {
        // Build reputation
        bytes memory proof = abi.encode("test-proof");
        vm.prank(zkProver);
        reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof,
            "Test"
        );

        uint8 risk = riskCalculator.calculateRisk(tokenId);
        assertGe(risk, 0, "Risk should be >= 0");
        assertLe(risk, 100, "Risk should be <= 100");
    }
}
