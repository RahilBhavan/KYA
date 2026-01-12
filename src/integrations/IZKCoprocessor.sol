// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IZKCoprocessor
 * @notice Interface for ZK coprocessor integration (Axiom/Brevis)
 * @dev This interface defines the standard for ZK proof generation and verification
 */
interface IZKCoprocessor {
    /**
     * @notice Proof query structure
     * @param queryId Unique identifier for the query
     * @param agentAddress The agent's TBA address
     * @param proofType The type of proof (e.g., "UniswapVolume")
     * @param queryData Additional query parameters
     * @param blockRange Block range to query
     */
    struct ProofQuery {
        bytes32 queryId;
        address agentAddress;
        string proofType;
        bytes queryData;
        uint256 startBlock;
        uint256 endBlock;
    }

    /**
     * @notice Proof result structure
     * @param queryId The query identifier
     * @param verified Whether the proof is verified
     * @param proof The ZK proof data
     * @param metadata Additional metadata
     */
    struct ProofResult {
        bytes32 queryId;
        bool verified;
        bytes proof;
        string metadata;
    }

    /**
     * @notice Emitted when a proof query is submitted
     * @param queryId The query identifier
     * @param agentAddress The agent's address
     * @param proofType The proof type
     */
    event ProofQuerySubmitted(
        bytes32 indexed queryId, address indexed agentAddress, string proofType
    );

    /**
     * @notice Emitted when a proof is generated
     * @param queryId The query identifier
     * @param verified Whether verification succeeded
     */
    event ProofGenerated(bytes32 indexed queryId, bool verified);

    /**
     * @notice Submit a proof query
     * @param query The proof query
     * @return queryId The query identifier
     */
    function submitQuery(ProofQuery memory query) external returns (bytes32 queryId);

    /**
     * @notice Get proof status
     * @param queryId The query identifier
     * @return status The proof status (0=pending, 1=generated, 2=failed)
     * @return result The proof result (if available)
     */
    function getProofStatus(bytes32 queryId)
        external
        view
        returns (uint8 status, ProofResult memory result);
}

