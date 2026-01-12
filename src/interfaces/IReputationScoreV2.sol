// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IReputationScore} from "./IReputationScore.sol";

/**
 * @title IReputationScoreV2
 * @notice Extended interface for advanced reputation scoring
 * @dev Adds time-weighting, decay, and multi-factor reputation
 */
interface IReputationScoreV2 is IReputationScore {
    /**
     * @notice Extended reputation data with category scores
     * @param baseData Base reputation data from V1
     * @param lastActivity Timestamp of last activity
     * @param categoryScores Mapping of category to score
     */
    struct ExtendedReputationData {
        ReputationData baseData;
        uint256 lastActivity;
        mapping(string => uint256) categoryScores;
    }

    /**
     * @notice Category score information
     * @param category The category name (e.g., "Trading", "Lending")
     * @param score The score for this category
     * @param lastUpdated Timestamp when category was last updated
     */
    struct CategoryScore {
        string category;
        uint256 score;
        uint256 lastUpdated;
    }

    /**
     * @notice Update reputation with time-weighting and category
     * @param tokenId The agent's token ID
     * @param category The category (e.g., "Trading", "Lending", "Content")
     * @param proofType The proof type
     * @param proof The ZK proof data
     * @param metadata Additional metadata
     * @return result The verification result
     */
    function updateReputation(
        uint256 tokenId,
        string calldata category,
        string calldata proofType,
        bytes calldata proof,
        string calldata metadata
    ) external returns (ProofResult memory result);

    /**
     * @notice Get extended reputation data including category scores
     * @param tokenId The agent's token ID
     * @return baseData Base reputation data
     * @return lastActivity Timestamp of last activity
     * @return categories Array of category names
     * @return categoryScores Array of category scores
     */
    function getExtendedReputation(uint256 tokenId)
        external
        view
        returns (
            ReputationData memory baseData,
            uint256 lastActivity,
            string[] memory categories,
            uint256[] memory categoryScores
        );

    /**
     * @notice Get category score for an agent
     * @param tokenId The agent's token ID
     * @param category The category name
     * @return score The category score
     */
    function getCategoryScore(uint256 tokenId, string calldata category)
        external
        view
        returns (uint256 score);

    /**
     * @notice Calculate time-weighted score
     * @param baseScore The base score
     * @param timeSinceActivity Time since last activity
     * @return weightedScore The time-weighted score
     */
    function calculateTimeWeight(uint256 baseScore, uint256 timeSinceActivity)
        external
        view
        returns (uint256 weightedScore);

    /**
     * @notice Apply decay to reputation score
     * @param tokenId The agent's token ID
     * @return newScore The score after decay
     */
    function applyDecay(uint256 tokenId) external returns (uint256 newScore);

    /**
     * @notice Set decay parameters
     * @param decayPeriod Period before decay starts (in seconds)
     * @param decayRate Rate of decay (basis points, e.g., 100 = 1%)
     */
    function setDecayParameters(uint256 decayPeriod, uint256 decayRate)
        external;

    /**
     * @notice Set time-weighting parameters
     * @param timeWeightPeriod Period for time-weighting (in seconds)
     * @param maxTimeWeight Maximum time weight multiplier (1e18 = 100%)
     */
    function setTimeWeightParameters(uint256 timeWeightPeriod, uint256 maxTimeWeight)
        external;

    /**
     * @notice Emitted when category score is updated
     * @param tokenId The agent's token ID
     * @param category The category name
     * @param oldScore The previous category score
     * @param newScore The new category score
     */
    event CategoryScoreUpdated(
        uint256 indexed tokenId,
        string category,
        uint256 oldScore,
        uint256 newScore
    );

    /**
     * @notice Emitted when decay is applied
     * @param tokenId The agent's token ID
     * @param oldScore The score before decay
     * @param newScore The score after decay
     */
    event DecayApplied(uint256 indexed tokenId, uint256 oldScore, uint256 newScore);
}
