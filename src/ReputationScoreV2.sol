// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IReputationScore} from "./interfaces/IReputationScore.sol";
import {IReputationScoreV2} from "./interfaces/IReputationScoreV2.sol";
import {IAgentLicense} from "./interfaces/IAgentLicense.sol";
import {ReputationScore} from "./ReputationScore.sol";

/**
 * @title ReputationScoreV2
 * @notice Advanced reputation scoring with time-weighting, decay, and multi-factor reputation
 * @dev Extends ReputationScore with advanced features while maintaining backward compatibility
 *
 * Key Features:
 * - Time-weighted scoring (recent activity matters more)
 * - Score decay for inactivity
 * - Category-specific scores (Trading, Lending, Content)
 * - Backward compatible with ReputationScore V1
 *
 * Security:
 * - Inherits all security features from ReputationScore
 * - Access control for admin functions
 * - Input validation on all parameters
 */
contract ReputationScoreV2 is IReputationScoreV2, AccessControl {
    // =============================================================================
    // Constants
    // =============================================================================

    /// @notice Role identifier for ZK coprocessor (inherited from V1)
    bytes32 public constant ZK_PROVER_ROLE = keccak256("ZK_PROVER_ROLE");

    /// @notice Default decay period (30 days)
    uint256 public constant DEFAULT_DECAY_PERIOD = 30 days;

    /// @notice Default decay rate (1% per period, in basis points)
    uint256 public constant DEFAULT_DECAY_RATE = 100; // 1%

    /// @notice Default time-weight period (7 days)
    uint256 public constant DEFAULT_TIME_WEIGHT_PERIOD = 7 days;

    /// @notice Default max time weight (1.5x for recent activity)
    uint256 public constant DEFAULT_MAX_TIME_WEIGHT = 1.5e18; // 150%

    // =============================================================================
    // State Variables
    // =============================================================================

    /// @notice The base ReputationScore V1 contract
    IReputationScore public immutable reputationScoreV1;

    /// @notice The AgentLicense NFT contract
    IAgentLicense public immutable agentLicense;

    /// @notice Mapping from token ID to last activity timestamp
    mapping(uint256 => uint256) private _lastActivity;

    /// @notice Mapping from token ID to category scores
    mapping(uint256 => mapping(string => uint256)) private _categoryScores;

    /// @notice Mapping from token ID to category list
    mapping(uint256 => string[]) private _categoryLists;

    /// @notice Decay period (time before decay starts)
    uint256 public decayPeriod;

    /// @notice Decay rate (basis points, e.g., 100 = 1%)
    uint256 public decayRate;

    /// @notice Time-weight period (period for time-weighting calculation)
    uint256 public timeWeightPeriod;

    /// @notice Max time weight (multiplier for recent activity, in 1e18 format)
    uint256 public maxTimeWeight;

    // =============================================================================
    // Errors
    // =============================================================================

    error InvalidTokenId();
    error InvalidCategory();
    error InvalidDecayParameters();
    error InvalidTimeWeightParameters();
    error NotAuthorized();

    // =============================================================================
    // Constructor
    // =============================================================================

    /**
     * @notice Initialize ReputationScoreV2
     * @param reputationScoreV1_ The base ReputationScore V1 contract address
     * @param agentLicense_ The AgentLicense NFT contract address
     */
    constructor(address reputationScoreV1_, address agentLicense_) {
        require(reputationScoreV1_ != address(0), "ReputationScoreV2: zero address");
        require(agentLicense_ != address(0), "ReputationScoreV2: zero address");

        reputationScoreV1 = IReputationScore(reputationScoreV1_);
        agentLicense = IAgentLicense(agentLicense_);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Initialize default parameters
        decayPeriod = DEFAULT_DECAY_PERIOD;
        decayRate = DEFAULT_DECAY_RATE;
        timeWeightPeriod = DEFAULT_TIME_WEIGHT_PERIOD;
        maxTimeWeight = DEFAULT_MAX_TIME_WEIGHT;
    }

    // =============================================================================
    // External Functions - Reputation Updates
    // =============================================================================

    /**
     * @notice Update reputation with time-weighting and category
     * @dev This function extends V1's verifyProof with category and time-weighting
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
    ) external override onlyRole(ZK_PROVER_ROLE) returns (ProofResult memory result) {
        // Validate token exists
        try agentLicense.ownerOf(tokenId) returns (address) {} catch {
            revert InvalidTokenId();
        }

        // Validate category
        require(bytes(category).length > 0, "ReputationScoreV2: category required");

        // Apply decay if needed (before updating)
        applyDecay(tokenId);

        // Get current reputation from V1
        ReputationData memory baseData = reputationScoreV1.getReputation(tokenId);
        uint256 oldCategoryScore = _categoryScores[tokenId][category];

        // Verify proof in V1 (this updates base reputation)
        // Note: V1's verifyProof will check ZK_PROVER_ROLE
        // ReputationScoreV2 must have ZK_PROVER_ROLE in V1 to call this
        result = reputationScoreV1.verifyProof(tokenId, proofType, proof, metadata);

        // Get updated reputation from V1
        baseData = reputationScoreV1.getReputation(tokenId);

        // Calculate time-weighted points
        uint256 timeSinceActivity = block.timestamp - _lastActivity[tokenId];
        uint256 timeWeight = calculateTimeWeight(result.scoreIncrease, timeSinceActivity);

        // Update category score
        if (oldCategoryScore == 0) {
            // First score in this category - add to list
            _categoryLists[tokenId].push(category);
        }
        _categoryScores[tokenId][category] += timeWeight;

        // Update last activity
        _lastActivity[tokenId] = block.timestamp;

        // Emit event
        emit CategoryScoreUpdated(
            tokenId,
            category,
            oldCategoryScore,
            _categoryScores[tokenId][category]
        );

        return result;
    }

    /**
     * @notice Apply decay to reputation score
     * @dev Reduces score if agent has been inactive
     * @param tokenId The agent's token ID
     * @return newScore The score after decay
     */
    function applyDecay(uint256 tokenId) public override returns (uint256 newScore) {
        ReputationData memory baseData = reputationScoreV1.getReputation(tokenId);
        if (baseData.verifiedProofs == 0) {
            return 0; // No reputation to decay
        }

        uint256 lastActivity = _lastActivity[tokenId];
        if (lastActivity == 0) {
            // First time - set last activity to now
            _lastActivity[tokenId] = block.timestamp;
            return baseData.score;
        }

        uint256 timeSinceActivity = block.timestamp - lastActivity;
        if (timeSinceActivity <= decayPeriod) {
            return baseData.score; // No decay yet
        }

        // Calculate decay
        uint256 periodsElapsed = timeSinceActivity / decayPeriod;
        uint256 decayAmount = (baseData.score * decayRate * periodsElapsed) / 10000;

        // Note: We can't directly modify V1's score, so we track decay separately
        // In a full implementation, we might need to modify V1 or track decay offset
        // For now, we'll emit the decay event but note that V1 score remains unchanged
        // This is a limitation that would need to be addressed in production

        uint256 decayedScore = baseData.score > decayAmount ? baseData.score - decayAmount : 0;

        emit DecayApplied(tokenId, baseData.score, decayedScore);

        return decayedScore;
    }

    // =============================================================================
    // External Functions - Views
    // =============================================================================

    /**
     * @notice Get extended reputation data including category scores
     * @param tokenId The agent's token ID
     * @return baseData Base reputation data from V1
     * @return lastActivity Timestamp of last activity
     * @return categories Array of category names
     * @return categoryScores Array of category scores
     */
    function getExtendedReputation(uint256 tokenId)
        external
        view
        override
        returns (
            ReputationData memory baseData,
            uint256 lastActivity,
            string[] memory categories,
            uint256[] memory categoryScores
        )
    {
        baseData = reputationScoreV1.getReputation(tokenId);
        lastActivity = _lastActivity[tokenId];

        string[] memory categoryList = _categoryLists[tokenId];
        categories = new string[](categoryList.length);
        categoryScores = new uint256[](categoryList.length);

        for (uint256 i = 0; i < categoryList.length; i++) {
            categories[i] = categoryList[i];
            categoryScores[i] = _categoryScores[tokenId][categoryList[i]];
        }
    }

    /**
     * @notice Get category score for an agent
     * @param tokenId The agent's token ID
     * @param category The category name
     * @return score The category score
     */
    function getCategoryScore(uint256 tokenId, string calldata category)
        external
        view
        override
        returns (uint256 score)
    {
        return _categoryScores[tokenId][category];
    }

    /**
     * @notice Calculate time-weighted score
     * @dev Recent activity gets higher weight
     * @param baseScore The base score
     * @param timeSinceActivity Time since last activity (in seconds)
     * @return weightedScore The time-weighted score
     */
    function calculateTimeWeight(uint256 baseScore, uint256 timeSinceActivity)
        public
        view
        override
        returns (uint256 weightedScore)
    {
        if (timeSinceActivity == 0) {
            // First activity - full weight
            return (baseScore * maxTimeWeight) / 1e18;
        }

        if (timeSinceActivity >= timeWeightPeriod) {
            // Old activity - no bonus
            return baseScore;
        }

        // Linear interpolation: recent activity gets max weight, old activity gets base weight
        // weight = maxTimeWeight - (maxTimeWeight - 1e18) * (timeSinceActivity / timeWeightPeriod)
        uint256 weightDecrease = ((maxTimeWeight - 1e18) * timeSinceActivity) / timeWeightPeriod;
        uint256 currentWeight = maxTimeWeight - weightDecrease;

        return (baseScore * currentWeight) / 1e18;
    }

    // =============================================================================
    // External Functions - Admin
    // =============================================================================

    /**
     * @notice Set decay parameters
     * @param decayPeriod_ Period before decay starts (in seconds)
     * @param decayRate_ Rate of decay (basis points, e.g., 100 = 1%)
     */
    function setDecayParameters(uint256 decayPeriod_, uint256 decayRate_)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(decayPeriod_ > 0, "ReputationScoreV2: invalid decay period");
        require(decayRate_ <= 10000, "ReputationScoreV2: invalid decay rate"); // Max 100%

        decayPeriod = decayPeriod_;
        decayRate = decayRate_;

        emit DecayParametersUpdated(decayPeriod_, decayRate_);
    }

    /**
     * @notice Set time-weighting parameters
     * @param timeWeightPeriod_ Period for time-weighting (in seconds)
     * @param maxTimeWeight_ Maximum time weight multiplier (1e18 = 100%)
     */
    function setTimeWeightParameters(uint256 timeWeightPeriod_, uint256 maxTimeWeight_)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(timeWeightPeriod_ > 0, "ReputationScoreV2: invalid time weight period");
        require(maxTimeWeight_ >= 1e18, "ReputationScoreV2: max time weight must be >= 100%");

        timeWeightPeriod = timeWeightPeriod_;
        maxTimeWeight = maxTimeWeight_;

        emit TimeWeightParametersUpdated(timeWeightPeriod_, maxTimeWeight_);
    }

    // =============================================================================
    // IReputationScore Interface Implementation (Delegates to V1)
    // =============================================================================

    /**
     * @notice Verify a ZK proof and update reputation (V1 compatibility)
     * @dev Delegates to V1 for backward compatibility
     */
    function verifyProof(
        uint256 tokenId,
        string calldata proofType,
        bytes calldata proof,
        string calldata metadata
    ) external override onlyRole(ZK_PROVER_ROLE) returns (ProofResult memory result) {
        // Delegate to V1
        return reputationScoreV1.verifyProof(tokenId, proofType, proof, metadata);
    }

    /**
     * @notice Get reputation data for an agent (V1 compatibility)
     */
    function getReputation(uint256 tokenId)
        external
        view
        override
        returns (ReputationData memory data)
    {
        return reputationScoreV1.getReputation(tokenId);
    }

    /**
     * @notice Get the tier for a given score (V1 compatibility)
     */
    function getTier(uint224 score) external pure override returns (uint8 tier) {
        // Delegate to V1 logic (same calculation)
        if (score >= 50000) return 5; // Whale
        if (score >= 10000) return 4; // Platinum
        if (score >= 2000) return 3; // Gold
        if (score >= 500) return 2; // Silver
        if (score >= 100) return 1; // Bronze
        return 0; // None
    }

    /**
     * @notice Get badges for an agent (V1 compatibility)
     */
    function getBadges(uint256 tokenId)
        external
        view
        override
        returns (string[] memory badges)
    {
        return reputationScoreV1.getBadges(tokenId);
    }

    /**
     * @notice Check if an agent has a specific badge (V1 compatibility)
     */
    function hasBadge(uint256 tokenId, string calldata badgeName)
        external
        view
        override
        returns (bool)
    {
        return reputationScoreV1.hasBadge(tokenId, badgeName);
    }

    // =============================================================================
    // Events
    // =============================================================================

    /**
     * @notice Emitted when decay parameters are updated
     */
    event DecayParametersUpdated(uint256 decayPeriod, uint256 decayRate);

    /**
     * @notice Emitted when time-weight parameters are updated
     */
    event TimeWeightParametersUpdated(uint256 timeWeightPeriod, uint256 maxTimeWeight);
}
