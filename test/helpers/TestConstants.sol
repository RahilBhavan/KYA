// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title TestConstants
 * @notice Constants for testing
 */
library TestConstants {
    // =============================================================================
    // Staking Constants
    // =============================================================================

    uint256 public constant MINIMUM_STAKE = 1000 * 10**6; // 1000 USDC (6 decimals)
    uint256 public constant CLAIM_FEE_BPS = 100; // 1%
    uint256 public constant UNSTAKE_COOLDOWN = 7 days;
    uint256 public constant CHALLENGE_PERIOD = 24 hours;

    // =============================================================================
    // Reputation Constants
    // =============================================================================

    uint256 public constant TIER_BRONZE = 100;
    uint256 public constant TIER_SILVER = 500;
    uint256 public constant TIER_GOLD = 2000;
    uint256 public constant TIER_PLATINUM = 10000;
    uint256 public constant TIER_WHALE = 50000;

    // =============================================================================
    // Paymaster Constants
    // =============================================================================

    uint256 public constant COLD_START_PERIOD = 7 days;
    uint256 public constant MAX_SPONSORED_TXS = 50;

    // =============================================================================
    // Test Addresses
    // =============================================================================

    address public constant DEPLOYER = address(0x1);
    address public constant USER1 = address(0x2);
    address public constant USER2 = address(0x3);
    address public constant MERCHANT = address(0x4);
    address public constant ORACLE = address(0x5);
    address public constant ZK_PROVER = address(0x6);
    address public constant ADMIN = address(0x7);

    // =============================================================================
    // Test Data
    // =============================================================================

    string public constant AGENT_NAME = "TestAgent";
    string public constant AGENT_DESCRIPTION = "A test agent for testing";
    string public constant AGENT_CATEGORY = "Trading";

    string public constant PROOF_TYPE_UNISWAP_VOLUME = "UniswapVolume";
    string public constant PROOF_TYPE_UNISWAP_TRADES = "UniswapTrades";
    string public constant PROOF_TYPE_AAVE_BORROWER = "AaveBorrower";
    string public constant PROOF_TYPE_AAVE_LENDER = "AaveLender";
    string public constant PROOF_TYPE_CHAINLINK = "ChainlinkUser";

    string public constant BADGE_UNISWAP_TRADER = "Uniswap Trader";
    string public constant BADGE_AAVE_BORROWER = "Aave Borrower";
    string public constant BADGE_AAVE_LENDER = "Aave Lender";
    string public constant BADGE_CHAINLINK_USER = "Chainlink User";

    // =============================================================================
    // Test Amounts
    // =============================================================================

    uint256 public constant MINTING_FEE = 0.001 ether;
    uint256 public constant TEST_STAKE_AMOUNT = 2000 * 10**6; // 2000 USDC
    uint256 public constant TEST_CLAIM_AMOUNT = 500 * 10**6; // 500 USDC
}

