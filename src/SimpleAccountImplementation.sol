// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IAgentAccount} from "./interfaces/IAgentAccount.sol";
import {IERC6551Account, IERC6551Executable} from "./interfaces/IERC6551.sol";

/**
 * @title SimpleAccountImplementation
 * @notice ERC-6551 Token Bound Account implementation for KYA Protocol
 * @dev This contract is deployed once and used as implementation for all agent accounts
 *
 * Key Features:
 * - Controlled by the owner of the linked NFT
 * - Can hold ETH, ERC-20, ERC-721, and ERC-1155 tokens
 * - Executes arbitrary transactions on behalf of the agent
 * - Deterministic address via CREATE2
 * - Minimal proxy pattern for gas efficiency
 *
 * Security:
 * - Only NFT owner can execute transactions
 * - State counter invalidates signatures on transfers
 * - No delegatecall in MVP (reduces attack surface)
 */
contract SimpleAccountImplementation is IAgentAccount {
    // =============================================================================
    // State Variables
    // =============================================================================

    /// @notice Counter that increments when account state changes
    /// @dev Used to invalidate signatures on NFT transfers
    uint256 private _state;

    // =============================================================================
    // Errors
    // =============================================================================

    error NotAuthorized();
    error InvalidOperation();
    error ExecutionFailed();
    error InvalidInput();

    // =============================================================================
    // Receive ETH
    // =============================================================================

    /**
     * @notice Allows the account to receive ETH
     */
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // =============================================================================
    // ERC-6551 Core Functions
    // =============================================================================

    /**
     * @notice Returns the NFT that owns this account
     * @return chainId The chain ID of the NFT contract
     * @return tokenContract The address of the NFT contract
     * @return tokenId The token ID of the NFT
     */
    function token()
        public
        view
        override
        returns (uint256 chainId, address tokenContract, uint256 tokenId)
    {
        // ERC-6551 spec: The account's token info is stored at a specific offset
        // in the account's bytecode by the registry during deployment
        bytes memory footer = new bytes(0x60);

        assembly {
            // The last 96 bytes of deployed bytecode contain:
            // - chainId (32 bytes)
            // - tokenContract (32 bytes, address padded)
            // - tokenId (32 bytes)
            extcodecopy(address(), add(footer, 0x20), 0x4d, 0x60)
        }

        return abi.decode(footer, (uint256, address, uint256));
    }

    /**
     * @notice Returns the current state of the account
     * @dev State counter increments on transfers to invalidate old signatures
     * @return The current state nonce
     */
    function state() external view override returns (uint256) {
        return _state;
    }

    /**
     * @notice Checks if a signer is authorized to use this account
     * @param signer The address to check
     * @param context Additional context (unused in this implementation)
     * @return magicValue ERC-6551 magic value if signer is valid
     */
    function isValidSigner(address signer, bytes calldata context)
        external
        view
        override
        returns (bytes4 magicValue)
    {
        context; // Silence unused parameter warning

        if (signer == owner()) {
            return IERC6551Account.isValidSigner.selector;
        }

        return bytes4(0);
    }

    // =============================================================================
    // Execution Functions
    // =============================================================================

    /**
     * @notice Execute a transaction from the account
     * @param target The address to call
     * @param value The amount of ETH to send
     * @param data The calldata to send
     * @param operation The type of operation (0 = CALL, others not supported in MVP)
     * @return result The return data from the call
     */
    function execute(address target, uint256 value, bytes calldata data, uint8 operation)
        external
        payable
        override
        returns (bytes memory result)
    {
        // Only NFT owner can execute
        if (msg.sender != owner()) {
            revert NotAuthorized();
        }

        // Only CALL operations supported in MVP (no delegatecall)
        if (operation != 0) {
            revert InvalidOperation();
        }

        // Increment state counter
        ++_state;

        // Execute the call using internal function
        return _executeCall(target, value, data);
    }

    /**
     * @notice Execute a simple transaction (operation = CALL)
     * @dev Convenience function that defaults to CALL operation
     * @param target The address to call
     * @param value The amount of ETH to send
     * @param data The calldata to send
     * @return result The return data from the call
     */
    function execute(address target, uint256 value, bytes calldata data)
        external
        payable
        override
        returns (bytes memory result)
    {
        // Only NFT owner can execute
        if (msg.sender != owner()) {
            revert NotAuthorized();
        }

        // Only CALL operations supported in MVP (no delegatecall)
        // operation = 0 (CALL)

        // Increment state counter
        ++_state;

        // Execute the call using internal function
        return _executeCall(target, value, data);
    }

    /**
     * @notice Internal function to execute a call
     * @param target The address to call
     * @param value The amount of ETH to send
     * @param data The calldata to send
     * @return result The return data from the call
     */
    function _executeCall(address target, uint256 value, bytes calldata data)
        internal
        returns (bytes memory result)
    {
        // Execute the call
        bool success;
        (success, result) = target.call{value: value}(data);

        if (!success) {
            // If the call failed, revert with the error message
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        emit Executed(target, value, data, success);

        return result;
    }

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
    ) external payable override returns (bytes[] memory results) {
        // Only NFT owner can execute
        if (msg.sender != owner()) {
            revert NotAuthorized();
        }

        // Validate input lengths
        if (targets.length != values.length || targets.length != datas.length) {
            revert InvalidInput();
        }

        // Increment state counter once for batch
        ++_state;

        // Execute all calls
        results = new bytes[](targets.length);
        for (uint256 i = 0; i < targets.length; i++) {
            bool success;
            (success, results[i]) = targets[i].call{value: values[i]}(datas[i]);

            if (!success) {
                // If any call fails, revert the entire batch
                assembly {
                    revert(add(results, 32), mload(results))
                }
            }

            emit Executed(targets[i], values[i], datas[i], success);
        }

        return results;
    }

    // =============================================================================
    // View Functions
    // =============================================================================

    /**
     * @notice Get the owner of this account
     * @dev Returns the current owner of the NFT that controls this account
     * @return owner The address of the NFT owner
     */
    function owner() public view override returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = token();

        // Verify we're on the correct chain
        if (chainId != block.chainid) {
            return address(0);
        }

        // Return the owner of the NFT
        return IERC721(tokenContract).ownerOf(tokenId);
    }

    /**
     * @notice Check if the account supports a specific interface
     * @dev Implements ERC-165 for interface detection
     * @param interfaceId The interface identifier
     * @return True if the interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IAgentAccount).interfaceId
            || interfaceId == type(IERC6551Account).interfaceId
            || interfaceId == type(IERC6551Executable).interfaceId;
    }

    // =============================================================================
    // Token Reception (ERC-721 & ERC-1155)
    // =============================================================================

    /**
     * @notice Handle the receipt of an ERC-721 token
     * @dev Required to receive ERC-721 tokens via safeTransferFrom
     */
    function onERC721Received(address, address, uint256, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return this.onERC721Received.selector;
    }

    /**
     * @notice Handle the receipt of a single ERC-1155 token
     * @dev Required to receive ERC-1155 tokens via safeTransferFrom
     */
    function onERC1155Received(address, address, uint256, uint256, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return this.onERC1155Received.selector;
    }

    /**
     * @notice Handle the receipt of multiple ERC-1155 tokens
     * @dev Required to receive ERC-1155 tokens via safeBatchTransferFrom
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
