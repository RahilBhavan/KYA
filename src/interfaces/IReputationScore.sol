// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IReputationScore
 * @notice Interface for the Reputation Score contract
 * @dev Handles reputation scoring with ZK-proof verification
 */
interface IReputationScore {
    /// @notice Role identifier for ZK coprocessors
    function ZK_PROVER_ROLE() external view returns (bytes32);
    /**
     * @notice Reputation data for an agent
     * @param tokenId The agent's token ID
     * @param score The current reputation score
     * @param tier The reputation tier (0=None, 1=Bronze, 2=Silver, 3=Gold, 4=Platinum, 5=Whale)
     * @param lastUpdated Timestamp when reputation was last updated
     * @param verifiedProofs Number of verified ZK proofs
     */
    struct ReputationData {
        uint256 tokenId;
        uint224 score; // Packed with tier (max 2^224, sufficient for reputation scores)
        uint8 tier; // 0=None, 1=Bronze, 2=Silver, 3=Gold, 4=Platinum, 5=Whale (packed with score)
        uint32 verifiedProofs; // Packed with lastUpdated (max 2^32 proofs)
        uint32 lastUpdated; // Timestamp (fits in uint32 until year 2106)
    }

    /**
     * @notice Badge information
     * @param name The badge name
     * @param description The badge description
     * @param tier The tier required for this badge
     * @param proofType The type of proof required (e.g., "UniswapVolume")
     */
    struct Badge {
        string name;
        string description;
        uint8 tier;
        string proofType;
    }

    /**
     * @notice ZK Proof verification result
     * @param proofType The type of proof (e.g., "UniswapVolume", "AaveBorrower")
     * @param verified Whether the proof is verified
     * @param scoreIncrease The score increase from this proof
     * @param metadata Additional metadata (e.g., volume amount)
     */
    struct ProofResult {
        string proofType;
        bool verified;
        uint256 scoreIncrease;
        string metadata;
    }

    /**
     * @notice Emitted when reputation is updated
     * @param tokenId The agent's token ID
     * @param oldScore The previous score
     * @param newScore The new score
     * @param newTier The new tier
     */
    event ReputationUpdated(
        uint256 indexed tokenId, uint256 oldScore, uint256 newScore, uint8 newTier
    );

    /**
     * @notice Emitted when a ZK proof is verified
     * @param tokenId The agent's token ID
     * @param proofType The type of proof
     * @param scoreIncrease The score increase
     */
    event ProofVerified(
        uint256 indexed tokenId, string proofType, uint256 scoreIncrease
    );

    /**
     * @notice Emitted when a badge is awarded
     * @param tokenId The agent's token ID
     * @param badgeName The badge name
     */
    event BadgeAwarded(uint256 indexed tokenId, string badgeName);

    /**
     * @notice Verify a ZK proof and update reputation
     * @dev This function will be called by the ZK coprocessor (Axiom/Brevis)
     * @param tokenId The agent's token ID
     * @param proofType The type of proof (e.g., "UniswapVolume")
     * @param proof The ZK proof data
     * @param metadata Additional metadata for the proof
     * @return result The verification result
     */
    function verifyProof(
        uint256 tokenId,
        string calldata proofType,
        bytes calldata proof,
        string calldata metadata
    ) external returns (ProofResult memory result);

    /**
     * @notice Get reputation data for an agent
     * @param tokenId The agent's token ID
     * @return data The reputation data
     */
    function getReputation(uint256 tokenId) external view returns (ReputationData memory data);

    /**
     * @notice Get the tier for a given score
     * @param score The reputation score
     * @return tier The tier (0-5)
     */
    function getTier(uint224 score) external pure returns (uint8 tier);

    /**
     * @notice Get badges for an agent
     * @param tokenId The agent's token ID
     * @return badges Array of badge names
     */
    function getBadges(uint256 tokenId) external view returns (string[] memory badges);

    /**
     * @notice Check if an agent has a specific badge
     * @param tokenId The agent's token ID
     * @param badgeName The badge name
     * @return hasBadge Whether the agent has the badge
     */
    function hasBadge(uint256 tokenId, string calldata badgeName)
        external
        view
        returns (bool hasBadge);
}

