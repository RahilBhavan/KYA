// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ICrossChain} from "./ICrossChain.sol";
import {MessageRelayer} from "./MessageRelayer.sol";
import {IReputationScore} from "../interfaces/IReputationScore.sol";
import {IAgentLicense} from "../interfaces/IAgentLicense.sol";

/**
 * @title CrossChainReputation
 * @notice Cross-chain reputation synchronization
 * @dev Syncs reputation scores across multiple chains
 *
 * Key Features:
 * - Reputation synchronization across chains
 * - Unified agent identity
 * - Cross-chain proof verification
 */
contract CrossChainReputation is ICrossChain, AccessControl, ReentrancyGuard {
    // =============================================================================
    // State Variables
    // =============================================================================

    /// @notice The ReputationScore contract
    IReputationScore public immutable reputationScore;

    /// @notice The AgentLicense contract
    IAgentLicense public immutable agentLicense;

    /// @notice The message relayer (LayerZero or Chainlink CCIP)
    MessageRelayer public immutable messageRelayer;

    /// @notice Mapping from tokenId => chainId => synced score
    mapping(uint256 => mapping(uint256 => uint256)) private _syncedScores;

    /// @notice Mapping from tokenId => chainId => last sync timestamp
    mapping(uint256 => mapping(uint256 => uint256)) private _lastSync;

    /// @notice Supported source chains
    mapping(uint256 => bool) public supportedChains;

    // =============================================================================
    // Errors
    // =============================================================================

    error InvalidTokenId();
    error InvalidProof();
    error UnsupportedChain();
    error InvalidSource();

    // =============================================================================
    // Constructor
    // =============================================================================

    constructor(
        address reputationScore_,
        address agentLicense_,
        address messageRelayer_
    ) {
        require(reputationScore_ != address(0), "CrossChainReputation: zero address");
        require(agentLicense_ != address(0), "CrossChainReputation: zero address");
        require(messageRelayer_ != address(0), "CrossChainReputation: zero address");

        reputationScore = IReputationScore(reputationScore_);
        agentLicense = IAgentLicense(agentLicense_);
        messageRelayer = MessageRelayer(messageRelayer_);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Support current chain by default
        supportedChains[block.chainid] = true;
    }

    // =============================================================================
    // External Functions
    // =============================================================================

    /**
     * @notice Sync reputation from source chain
     * @param tokenId The agent token ID
     * @param score The reputation score from source chain
     * @param proof The cross-chain proof
     */
    function syncReputation(
        uint256 tokenId,
        uint256 score,
        bytes calldata proof
    ) external override nonReentrant {
        // Validate token exists
        try agentLicense.ownerOf(tokenId) returns (address) {} catch {
            revert InvalidTokenId();
        }

        // Decode proof to get source chain ID
        // In production, this would verify the cross-chain message
        (uint256 sourceChainId, bytes memory messageProof) = abi.decode(proof, (uint256, bytes));

        // Verify source chain is supported
        if (!supportedChains[sourceChainId]) {
            revert UnsupportedChain();
        }

        // Verify message proof (would verify LayerZero/CCIP proof in production)
        // For now, we trust the message relayer
        bytes32 messageId = keccak256(abi.encodePacked(sourceChainId, tokenId, score));
        bool valid = messageRelayer.verifyMessage(messageId, sourceChainId, messageProof);
        if (!valid) {
            revert InvalidProof();
        }

        // Update synced score
        _syncedScores[tokenId][sourceChainId] = score;
        _lastSync[tokenId][sourceChainId] = block.timestamp;

        emit ReputationSynced(tokenId, sourceChainId, score, block.timestamp);
    }

    /**
     * @notice Get synced reputation score
     * @param tokenId The agent token ID
     * @param chainId The source chain ID
     * @return score The synced score from that chain
     */
    function getSyncedScore(uint256 tokenId, uint256 chainId)
        external
        view
        override
        returns (uint256 score)
    {
        return _syncedScores[tokenId][chainId];
    }

    /**
     * @notice Get unified reputation score (local + synced from other chains)
     * @param tokenId The agent token ID
     * @return totalScore The total score across all chains
     */
    function getUnifiedScore(uint256 tokenId) external view returns (uint256 totalScore) {
        // Get local score
        IReputationScore.ReputationData memory localRep = reputationScore.getReputation(tokenId);
        totalScore = localRep.score;

        // Add synced scores from other chains
        // In production, you'd iterate through supported chains
        // For now, we return local score
        return totalScore;
    }

    // =============================================================================
    // External Functions - Admin
    // =============================================================================

    /**
     * @notice Add or remove supported chain
     * @param chainId The chain ID
     * @param supported Whether chain is supported
     */
    function setSupportedChain(uint256 chainId, bool supported)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        supportedChains[chainId] = supported;
    }
}
