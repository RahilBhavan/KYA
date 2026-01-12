// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IReputationScore} from "../interfaces/IReputationScore.sol";
import {IInsuranceVault} from "../interfaces/IInsuranceVault.sol";

/**
 * @title ReputationPricing
 * @notice Helper contract for reputation-based pricing suggestions
 * @dev Provides price suggestions based on agent reputation and staking
 */
contract ReputationPricing {
    // =============================================================================
    // Constants
    // =============================================================================

    /// @notice Base price multiplier (in wei per reputation point)
    uint256 public constant BASE_PRICE_PER_SCORE = 1e15; // 0.001 ETH per score point

    /// @notice Tier multipliers (basis points, e.g., 20000 = 2x)
    uint256 public constant TIER_NONE_MULTIPLIER = 5000; // 0.5x
    uint256 public constant TIER_BRONZE_MULTIPLIER = 10000; // 1x
    uint256 public constant TIER_SILVER_MULTIPLIER = 15000; // 1.5x
    uint256 public constant TIER_GOLD_MULTIPLIER = 20000; // 2x
    uint256 public constant TIER_PLATINUM_MULTIPLIER = 30000; // 3x
    uint256 public constant TIER_WHALE_MULTIPLIER = 50000; // 5x

    /// @notice Stake multiplier (basis points per USDC staked)
    uint256 public constant STAKE_MULTIPLIER_BPS = 100; // 1% per USDC

    // =============================================================================
    // State Variables
    // =============================================================================

    /// @notice The ReputationScore contract
    IReputationScore public immutable reputationScore;

    /// @notice The InsuranceVault contract
    IInsuranceVault public immutable insuranceVault;

    // =============================================================================
    // Constructor
    // =============================================================================

    constructor(address reputationScore_, address insuranceVault_) {
        require(reputationScore_ != address(0), "ReputationPricing: zero address");
        require(insuranceVault_ != address(0), "ReputationPricing: zero address");

        reputationScore = IReputationScore(reputationScore_);
        insuranceVault = IInsuranceVault(insuranceVault_);
    }

    // =============================================================================
    // External Functions
    // =============================================================================

    /**
     * @notice Calculate suggested price based on reputation and staking
     * @param tokenId The agent token ID
     * @return suggestedPrice The suggested price in wei
     */
    function calculatePrice(uint256 tokenId) external view returns (uint256 suggestedPrice) {
        // Get reputation
        IReputationScore.ReputationData memory rep = reputationScore.getReputation(tokenId);
        
        // Base price from reputation score
        uint256 basePrice = rep.score * BASE_PRICE_PER_SCORE;
        
        // Apply tier multiplier
        uint256 tierMultiplier = getTierMultiplier(rep.tier);
        uint256 tierAdjustedPrice = (basePrice * tierMultiplier) / 10000;
        
        // Get stake amount
        IInsuranceVault.StakeInfo memory stake = insuranceVault.getStakeInfo(tokenId);
        
        // Add stake value (1:1 USDC to ETH, with multiplier)
        uint256 stakeValue = (stake.amount * STAKE_MULTIPLIER_BPS) / 10000;
        // Convert USDC (6 decimals) to wei (18 decimals)
        stakeValue = (stakeValue * 1e12); // Multiply by 10^12 to convert
        
        suggestedPrice = tierAdjustedPrice + stakeValue;
        
        return suggestedPrice;
    }

    /**
     * @notice Get tier multiplier
     * @param tier The reputation tier
     * @return multiplier The multiplier in basis points
     */
    function getTierMultiplier(uint8 tier) public pure returns (uint256 multiplier) {
        if (tier == 0) return TIER_NONE_MULTIPLIER;
        if (tier == 1) return TIER_BRONZE_MULTIPLIER;
        if (tier == 2) return TIER_SILVER_MULTIPLIER;
        if (tier == 3) return TIER_GOLD_MULTIPLIER;
        if (tier == 4) return TIER_PLATINUM_MULTIPLIER;
        if (tier == 5) return TIER_WHALE_MULTIPLIER;
        return TIER_NONE_MULTIPLIER;
    }
}
