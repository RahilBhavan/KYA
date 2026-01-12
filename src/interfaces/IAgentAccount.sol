// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC6551Account, IERC6551Executable} from "./IERC6551.sol";

/**
 * @title IAgentAccount
 * @notice Extended interface for KYA Protocol Token Bound Accounts
 * @dev Extends ERC-6551 with protocol-specific functionality
 *
 * This interface adds:
 * - Batch execution capabilities
 * - Event logging for analytics
 * - Extension points for future phases (ZK proofs, insurance)
 */
interface IAgentAccount is IERC6551Account, IERC6551Executable {
    /**
     * @notice Emitted when the account receives ETH
     * @param sender The address that sent ETH
     * @param amount The amount of ETH received
     */
    event Received(address indexed sender, uint256 amount);

    /**
     * @notice Emitted when a transaction is executed
     * @param target The address that was called
     * @param value The amount of ETH sent
     * @param data The calldata
     * @param success Whether the call succeeded
     */
    event Executed(address indexed target, uint256 value, bytes data, bool success);

    /**
     * @notice Execute a simple transaction (operation = 0)
     * @dev Convenience function for CALL operations
     * @param target The address to call
     * @param value The amount of ETH to send
     * @param data The calldata to send
     * @return result The return data from the call
     */
    function execute(address target, uint256 value, bytes calldata data)
        external
        payable
        returns (bytes memory result);

    /**
     * @notice Execute multiple transactions in a single call
     * @dev All transactions must succeed or the entire batch reverts
     * @param targets Array of addresses to call
     * @param values Array of ETH amounts to send
     * @param datas Array of calldata to send
     * @return results Array of return data from each call
     */
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external payable returns (bytes[] memory results);

    /**
     * @notice Get the owner of this account
     * @dev Returns the current owner of the NFT that controls this account
     * @return owner The address of the NFT owner
     */
    function owner() external view returns (address owner);

    /**
     * @notice Check if the account supports a specific interface
     * @dev Implements ERC-165 for interface detection
     * @param interfaceId The interface identifier
     * @return True if the interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
