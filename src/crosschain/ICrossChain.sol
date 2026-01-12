// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title ICrossChain
 * @notice Interface for cross-chain reputation synchronization
 */
interface ICrossChain {
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
    ) external;

    /**
     * @notice Get synced reputation score
     * @param tokenId The agent token ID
     * @param chainId The source chain ID
     * @return score The synced score from that chain
     */
    function getSyncedScore(uint256 tokenId, uint256 chainId)
        external
        view
        returns (uint256 score);

    /**
     * @notice Emitted when reputation is synced
     */
    event ReputationSynced(
        uint256 indexed tokenId,
        uint256 sourceChainId,
        uint256 score,
        uint256 timestamp
    );
}
