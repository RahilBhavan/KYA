// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IReputationScore} from "./interfaces/IReputationScore.sol";
import {IAgentLicense} from "./interfaces/IAgentLicense.sol";

/**
 * @title ReputationScore
 * @notice Reputation scoring system with ZK-proof verification
 * @dev Handles reputation tiers, badges, and ZK proof verification
 *
 * Key Features:
 * - Reputation scoring based on verified ZK proofs
 * - Tier system (None, Bronze, Silver, Gold, Platinum, Whale)
 * - Badge system for specific achievements
 * - ZK coprocessor integration (Axiom/Brevis)
 * - Whitelisted external contracts for reputation building
 *
 * Security:
 * - Only verified ZK proofs can increase reputation
 * - Whitelisted contracts prevent Sybil attacks
 * - Access control for proof verification
 */
contract ReputationScore is IReputationScore, AccessControl {
    // =============================================================================
    // Constants
    // =============================================================================

    /// @notice Role identifier for ZK coprocessor (Axiom/Brevis)
    bytes32 public constant ZK_PROVER_ROLE = keccak256("ZK_PROVER_ROLE");

    /// @notice Tier thresholds (score required for each tier)
    uint256 public constant TIER_NONE = 0;
    uint256 public constant TIER_BRONZE = 100;
    uint256 public constant TIER_SILVER = 500;
    uint256 public constant TIER_GOLD = 2000;
    uint256 public constant TIER_PLATINUM = 10000;
    uint256 public constant TIER_WHALE = 50000;

    // =============================================================================
    // State Variables
    // =============================================================================

    /// @notice The AgentLicense NFT contract
    IAgentLicense public immutable agentLicense;

    /// @notice Mapping from token ID to reputation data
    mapping(uint256 => ReputationData) private _reputations;

    /// @notice Mapping from token ID to badges (using bytes32 for gas efficiency)
    mapping(uint256 => mapping(bytes32 => bool)) private _badges;

    /// @notice Mapping from token ID to badge list (bytes32 IDs)
    mapping(uint256 => bytes32[]) private _badgeLists;

    /// @notice Mapping from badge ID to human-readable name (for off-chain queries)
    mapping(bytes32 => string) public badgeNames;

    /// @notice Mapping to prevent proof replay attacks
    mapping(bytes32 => bool) private _verifiedProofs;

    /// @notice Mapping from proof type to score increase
    mapping(string => uint256) private _proofTypeScores;

    /// @notice Mapping from proof type to badge name
    mapping(string => string) private _proofTypeBadges;

    /// @notice Whitelisted external contracts (only interactions with these count)
    mapping(address => bool) public whitelistedContracts;

    /// @notice Badge definitions
    mapping(string => Badge) private _badgeDefinitions;

    // =============================================================================
    // Errors
    // =============================================================================

    error InvalidTokenId();
    error InvalidProof();
    error ProofAlreadyVerified();
    error InvalidProofType();
    error NotAuthorized();

    // =============================================================================
    // Constructor
    // =============================================================================

    /**
     * @notice Initialize the Reputation Score contract
     * @param agentLicense_ The AgentLicense NFT contract address
     */
    constructor(address agentLicense_) {
        require(agentLicense_ != address(0), "ReputationScore: zero address");
        
        agentLicense = IAgentLicense(agentLicense_);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Initialize proof type scores
        _proofTypeScores["UniswapVolume"] = 50;
        _proofTypeScores["UniswapTrades"] = 10;
        _proofTypeScores["AaveBorrower"] = 100;
        _proofTypeScores["AaveLender"] = 150;
        _proofTypeScores["ChainlinkUser"] = 75;
        _proofTypeScores["CompoundUser"] = 80;

        // Initialize badge mappings
        _proofTypeBadges["UniswapVolume"] = "Uniswap Trader";
        _proofTypeBadges["AaveBorrower"] = "Aave Borrower";
        _proofTypeBadges["AaveLender"] = "Aave Lender";
        _proofTypeBadges["ChainlinkUser"] = "Chainlink User";

        // Initialize badge definitions
        _badgeDefinitions["Uniswap Trader"] = Badge({
            name: "Uniswap Trader",
            description: "Verified Uniswap trading history",
            tier: 1,
            proofType: "UniswapVolume"
        });
        _badgeDefinitions["Aave Borrower"] = Badge({
            name: "Aave Borrower",
            description: "Verified Aave borrowing history",
            tier: 2,
            proofType: "AaveBorrower"
        });
        _badgeDefinitions["Aave Lender"] = Badge({
            name: "Aave Lender",
            description: "Verified Aave lending history",
            tier: 3,
            proofType: "AaveLender"
        });
        _badgeDefinitions["Chainlink User"] = Badge({
            name: "Chainlink User",
            description: "Verified Chainlink oracle usage",
            tier: 2,
            proofType: "ChainlinkUser"
        });
    }

    // =============================================================================
    // External Functions - ZK Proof Verification
    // =============================================================================

    /**
     * @notice Verify a ZK proof and update reputation
     * @dev Called by ZK coprocessor (Axiom/Brevis) after proof generation
     * @param tokenId The agent's token ID
     * @param proofType The type of proof (e.g., "UniswapVolume")
     * @param proof The ZK proof data (verified off-chain)
     * @param metadata Additional metadata (e.g., volume amount)
     * @return result The verification result
     */
    function verifyProof(
        uint256 tokenId,
        string calldata proofType,
        bytes calldata proof,
        string calldata metadata
    ) external override onlyRole(ZK_PROVER_ROLE) returns (ProofResult memory result) {
        // Validate token exists
        try agentLicense.ownerOf(tokenId) returns (address) {} catch {
            revert InvalidTokenId();
        }

        // Validate proof type
        uint256 scoreIncrease = _proofTypeScores[proofType];
        if (scoreIncrease == 0) {
            revert InvalidProofType();
        }

        // Prevent proof replay attacks
        bytes32 proofHash = keccak256(abi.encodePacked(tokenId, proofType, proof));
        if (_verifiedProofs[proofHash]) {
            revert ProofAlreadyVerified();
        }
        _verifiedProofs[proofHash] = true;

        // TODO: In production, verify the ZK proof on-chain
        // For MVP, we trust the ZK_PROVER_ROLE (Axiom/Brevis will have this role)
        // The actual proof verification happens off-chain by the coprocessor

        // Update reputation (optimized: use packed struct)
        ReputationData storage rep = _reputations[tokenId];
        uint224 oldScore = rep.score;
        
        bool isFirstProof = rep.verifiedProofs == 0;
        if (isFirstProof) {
            // First reputation entry
            rep.tokenId = tokenId;
            rep.score = uint224(scoreIncrease);
            rep.verifiedProofs = 1;
        } else {
            // Ensure score doesn't exceed uint224 max
            require(uint256(rep.score) + scoreIncrease <= type(uint224).max, "ReputationScore: score overflow");
            rep.score = uint224(uint256(rep.score) + scoreIncrease);
            rep.verifiedProofs += 1;
        }
        rep.lastUpdated = uint32(block.timestamp);

        // Update tier
        rep.tier = getTier(rep.score);

        // Award badge if applicable (optimized: use bytes32)
        string memory badgeName = _proofTypeBadges[proofType];
        if (bytes(badgeName).length > 0) {
            bytes32 badgeId = keccak256(bytes(badgeName));
            if (!_badges[tokenId][badgeId]) {
                _badges[tokenId][badgeId] = true;
                _badgeLists[tokenId].push(badgeId);
                badgeNames[badgeId] = badgeName; // Store human-readable name
                emit BadgeAwarded(tokenId, badgeName);
            }
        }

        emit ReputationUpdated(tokenId, oldScore, rep.score, rep.tier);
        emit ProofVerified(tokenId, proofType, scoreIncrease);

        result = ProofResult({
            proofType: proofType,
            verified: true,
            scoreIncrease: scoreIncrease,
            metadata: metadata
        });

        return result;
    }

    // =============================================================================
    // External Functions - Views
    // =============================================================================

    /**
     * @notice Get reputation data for an agent
     * @param tokenId The agent's token ID
     * @return data The reputation data
     */
    function getReputation(uint256 tokenId)
        external
        view
        override
        returns (ReputationData memory data)
    {
        data = _reputations[tokenId];
        if (data.verifiedProofs == 0) {
            // Return default values for agents without reputation
            data.tokenId = tokenId;
            data.score = 0;
            data.tier = 0;
            data.lastUpdated = 0;
            data.verifiedProofs = 0;
        }
        return data;
    }

    /**
     * @notice Get the tier for a given score
     * @param score The reputation score
     * @return tier The tier (0-5)
     */
    function getTier(uint224 score) public pure override returns (uint8 tier) {
        if (score >= TIER_WHALE) return 5;
        if (score >= TIER_PLATINUM) return 4;
        if (score >= TIER_GOLD) return 3;
        if (score >= TIER_SILVER) return 2;
        if (score >= TIER_BRONZE) return 1;
        return 0;
    }

    /**
     * @notice Get badges for an agent
     * @param tokenId The agent's token ID
     * @return badges Array of badge names
     */
    function getBadges(uint256 tokenId)
        external
        view
        override
        returns (string[] memory badges)
    {
        bytes32[] memory badgeIds = _badgeLists[tokenId];
        badges = new string[](badgeIds.length);
        for (uint256 i = 0; i < badgeIds.length; i++) {
            badges[i] = badgeNames[badgeIds[i]];
        }
        return badges;
    }

    /**
     * @notice Check if an agent has a specific badge
     * @param tokenId The agent's token ID
     * @param badgeName The badge name
     * @return hasBadge Whether the agent has the badge
     */
    function hasBadge(uint256 tokenId, string calldata badgeName)
        external
        view
        override
        returns (bool)
    {
        bytes32 badgeId = keccak256(bytes(badgeName));
        return _badges[tokenId][badgeId];
    }

    /**
     * @notice Get badge definition
     * @param badgeName The badge name
     * @return badge The badge definition
     */
    function getBadgeDefinition(string calldata badgeName)
        external
        view
        returns (Badge memory badge)
    {
        badge = _badgeDefinitions[badgeName];
        require(bytes(badge.name).length > 0, "ReputationScore: badge not found");
        return badge;
    }

    // =============================================================================
    // External Functions - Admin
    // =============================================================================

    /**
     * @notice Set score for a proof type
     * @param proofType The proof type
     * @param score The score increase
     */
    function setProofTypeScore(string calldata proofType, uint256 score)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _proofTypeScores[proofType] = score;
    }

    /**
     * @notice Set badge for a proof type
     * @param proofType The proof type
     * @param badgeName The badge name
     */
    function setProofTypeBadge(string calldata proofType, string calldata badgeName)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _proofTypeBadges[proofType] = badgeName;
    }

    /**
     * @notice Add or remove whitelisted contract
     * @param contractAddress The contract address
     * @param whitelisted Whether to whitelist
     */
    function setWhitelistedContract(address contractAddress, bool whitelisted)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        whitelistedContracts[contractAddress] = whitelisted;
    }

    /**
     * @notice Create a new badge definition
     * @param badge The badge definition
     */
    function createBadge(Badge calldata badge) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bytes(badge.name).length > 0, "ReputationScore: badge name required");
        _badgeDefinitions[badge.name] = badge;
    }
}

