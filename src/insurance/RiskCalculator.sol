// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IReputationScore} from "../interfaces/IReputationScore.sol";
import {IInsuranceVault} from "../interfaces/IInsuranceVault.sol";

/**
 * @title RiskCalculator
 * @notice Calculates risk levels for insurance pools
 * @dev Provides risk assessment based on agent reputation and history
 */
contract RiskCalculator {
    // =============================================================================
    // State Variables
    // =============================================================================

    /// @notice The ReputationScore contract
    IReputationScore public immutable reputationScore;

    /// @notice The InsuranceVault contract
    IInsuranceVault public immutable insuranceVault;

    /// @notice Risk weights for different factors
    uint256 public constant REPUTATION_WEIGHT = 40; // 40% of risk calculation
    uint256 public constant STAKING_WEIGHT = 30; // 30% of risk calculation
    uint256 public constant CLAIM_HISTORY_WEIGHT = 30; // 30% of risk calculation

    // =============================================================================
    // Constructor
    // =============================================================================

    constructor(address reputationScore_, address insuranceVault_) {
        require(reputationScore_ != address(0), "RiskCalculator: zero address");
        require(insuranceVault_ != address(0), "RiskCalculator: zero address");

        reputationScore = IReputationScore(reputationScore_);
        insuranceVault = IInsuranceVault(insuranceVault_);
    }

    // =============================================================================
    // External Functions
    // =============================================================================

    /**
     * @notice Calculate risk level for an agent (0-100, lower is better)
     * @param tokenId The agent token ID
     * @return riskLevel The risk level (0-100)
     */
    function calculateRisk(uint256 tokenId) external view returns (uint8 riskLevel) {
        // Get reputation
        IReputationScore.ReputationData memory rep = reputationScore.getReputation(tokenId);
        
        // Get stake info
        IInsuranceVault.StakeInfo memory stake = insuranceVault.getStakeInfo(tokenId);
        
        // Calculate reputation risk (higher tier = lower risk)
        uint256 reputationRisk = calculateReputationRisk(rep.tier, rep.score);
        
        // Calculate staking risk (more staked = lower risk)
        uint256 stakingRisk = calculateStakingRisk(stake.amount, stake.isVerified);
        
        // Calculate claim history risk (would need to query claims)
        uint256 claimHistoryRisk = 50; // Default (would calculate from actual claims)
        
        // Weighted average
        uint256 totalRisk = (reputationRisk * REPUTATION_WEIGHT +
                            stakingRisk * STAKING_WEIGHT +
                            claimHistoryRisk * CLAIM_HISTORY_WEIGHT) / 100;
        
        // Clamp to 0-100
        if (totalRisk > 100) {
            totalRisk = 100;
        }
        
        return uint8(totalRisk);
    }

    /**
     * @notice Calculate reputation-based risk
     * @param tier The reputation tier
     * @param score The reputation score
     * @return risk The risk value (0-100)
     */
    function calculateReputationRisk(uint8 tier, uint224 score) public pure returns (uint256 risk) {
        // Higher tier = lower risk
        if (tier >= 5) return 10; // Whale - very low risk
        if (tier >= 4) return 20; // Platinum - low risk
        if (tier >= 3) return 35; // Gold - medium-low risk
        if (tier >= 2) return 50; // Silver - medium risk
        if (tier >= 1) return 70; // Bronze - medium-high risk
        return 90; // None - high risk
    }

    /**
     * @notice Calculate staking-based risk
     * @param stakeAmount The stake amount
     * @param isVerified Whether agent is verified
     * @return risk The risk value (0-100)
     */
    function calculateStakingRisk(uint256 stakeAmount, bool isVerified)
        public
        pure
        returns (uint256 risk)
    {
        if (!isVerified) {
            return 80; // High risk if not verified
        }
        
        // More staked = lower risk
        // Scale: 1000 USDC = 50 risk, 10000 USDC = 20 risk, 100000 USDC = 10 risk
        if (stakeAmount >= 100_000 * 10**6) return 10; // Very low risk
        if (stakeAmount >= 10_000 * 10**6) return 20; // Low risk
        if (stakeAmount >= 1_000 * 10**6) return 50; // Medium risk
        return 70; // Higher risk for minimum stake
    }
}
