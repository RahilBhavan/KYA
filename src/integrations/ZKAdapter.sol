// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IZKCoprocessor} from "./IZKCoprocessor.sol";
import {IReputationScore} from "../interfaces/IReputationScore.sol";
import {IAgentRegistry} from "../interfaces/IAgentRegistry.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title ZKAdapter
 * @notice Adapter contract for ZK coprocessor integration (Axiom/Brevis)
 * @dev Handles proof queries and verification for ReputationScore
 *
 * This contract acts as a bridge between ZK coprocessors and ReputationScore.
 * It can be extended to support multiple coprocessors (Axiom, Brevis, etc.)
 */
contract ZKAdapter is IZKCoprocessor, AccessControl {
    // =============================================================================
    // State Variables
    // =============================================================================

    /// @notice The ReputationScore contract
    IReputationScore public immutable reputationScore;

    /// @notice The AgentRegistry contract
    IAgentRegistry public immutable agentRegistry;

    /// @notice Mapping from query ID to query data
    mapping(bytes32 => ProofQuery) private _queries;

    /// @notice Mapping from query ID to proof result
    mapping(bytes32 => ProofResult) private _results;

    /// @notice Mapping from query ID to status (0=pending, 1=generated, 2=failed)
    mapping(bytes32 => uint8) private _statuses;

    /// @notice Counter for query IDs
    uint256 private _queryCounter;

    // =============================================================================
    // Errors
    // =============================================================================

    error InvalidQuery();
    error QueryNotFound();
    error InvalidStatus();

    // =============================================================================
    // Constructor
    // =============================================================================

    constructor(address reputationScore_, address agentRegistry_) {
        require(reputationScore_ != address(0), "ZKAdapter: zero address");
        require(agentRegistry_ != address(0), "ZKAdapter: zero address");

        reputationScore = IReputationScore(reputationScore_);
        agentRegistry = IAgentRegistry(agentRegistry_);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // =============================================================================
    // External Functions
    // =============================================================================

    /**
     * @notice Submit a proof query
     * @param query The proof query
     * @return queryId The query identifier
     */
    function submitQuery(ProofQuery memory query) external override returns (bytes32 queryId) {
        require(query.agentAddress != address(0), "ZKAdapter: invalid agent address");
        require(bytes(query.proofType).length > 0, "ZKAdapter: invalid proof type");

        queryId = keccak256(
            abi.encodePacked(
                _queryCounter++,
                query.agentAddress,
                query.proofType,
                block.timestamp,
                msg.sender
            )
        );

        query.queryId = queryId;
        _queries[queryId] = query;
        _statuses[queryId] = 0; // Pending

        emit ProofQuerySubmitted(queryId, query.agentAddress, query.proofType);

        return queryId;
    }

    /**
     * @notice Process proof result from coprocessor
     * @dev Called by coprocessor after proof generation
     * @param queryId The query identifier
     * @param proof The ZK proof data
     * @param metadata Additional metadata
     */
    function processProof(
        bytes32 queryId,
        bytes calldata proof,
        string calldata metadata
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ProofQuery memory query = _queries[queryId];
        if (query.agentAddress == address(0)) {
            revert QueryNotFound();
        }

        // Get agent token ID from TBA address
        // Note: This is a simplified lookup - in production, maintain a mapping
        // For now, we'll need to pass tokenId separately or maintain a registry

        // Store result
        _results[queryId] = ProofResult({
            queryId: queryId,
            verified: true,
            proof: proof,
            metadata: metadata
        });

        _statuses[queryId] = 1; // Generated

        emit ProofGenerated(queryId, true);
    }

    /**
     * @notice Process proof and update reputation
     * @dev Called by coprocessor with tokenId
     * @param queryId The query identifier
     * @param tokenId The agent's token ID
     * @param proof The ZK proof data
     * @param metadata Additional metadata
     */
    function processProofAndUpdate(
        bytes32 queryId,
        uint256 tokenId,
        bytes calldata proof,
        string calldata metadata
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ProofQuery memory query = _queries[queryId];
        if (query.agentAddress == address(0)) {
            revert QueryNotFound();
        }

        // Verify proof via ReputationScore
        // Note: This requires ZK_PROVER_ROLE on ReputationScore
        IReputationScore.ProofResult memory result = reputationScore.verifyProof(
            tokenId,
            query.proofType,
            proof,
            metadata
        );

        // Store result
        _results[queryId] = ProofResult({
            queryId: queryId,
            verified: result.verified,
            proof: proof,
            metadata: metadata
        });

        _statuses[queryId] = result.verified ? 1 : 2; // Generated or Failed

        emit ProofGenerated(queryId, result.verified);
    }

    /**
     * @notice Get proof status
     * @param queryId The query identifier
     * @return status The proof status (0=pending, 1=generated, 2=failed)
     * @return result The proof result (if available)
     */
    function getProofStatus(bytes32 queryId)
        external
        view
        override
        returns (uint8 status, ProofResult memory result)
    {
        status = _statuses[queryId];
        if (status == 0 && _queries[queryId].agentAddress == address(0)) {
            revert QueryNotFound();
        }

        if (status == 1) {
            result = _results[queryId];
        }
    }

    /**
     * @notice Get query data
     * @param queryId The query identifier
     * @return query The query data
     */
    function getQuery(bytes32 queryId) external view returns (ProofQuery memory query) {
        query = _queries[queryId];
        if (query.agentAddress == address(0)) {
            revert QueryNotFound();
        }
    }
}

