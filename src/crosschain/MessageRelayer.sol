// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title MessageRelayer
 * @notice Abstract interface for cross-chain message relayers
 * @dev Implementations: LayerZeroAdapter, ChainlinkCCIPAdapter
 */
interface MessageRelayer {
    /**
     * @notice Send a message to another chain
     * @param targetChainId The target chain ID
     * @param targetAddress The target contract address
     * @param payload The message payload
     * @return messageId The message ID
     */
    function sendMessage(
        uint256 targetChainId,
        address targetAddress,
        bytes calldata payload
    ) external payable returns (bytes32 messageId);

    /**
     * @notice Receive a message from another chain
     * @param sourceChainId The source chain ID
     * @param sourceAddress The source contract address
     * @param payload The message payload
     */
    function receiveMessage(
        uint256 sourceChainId,
        address sourceAddress,
        bytes calldata payload
    ) external;

    /**
     * @notice Verify a cross-chain message
     * @param messageId The message ID
     * @param sourceChainId The source chain ID
     * @param payload The message payload
     * @return valid Whether the message is valid
     */
    function verifyMessage(
        bytes32 messageId,
        uint256 sourceChainId,
        bytes calldata payload
    ) external view returns (bool valid);
}
