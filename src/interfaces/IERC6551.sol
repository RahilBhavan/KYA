// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IERC6551Account
 * @notice Interface for ERC-6551 Token Bound Accounts
 * @dev This interface defines the core functionality for accounts controlled by NFTs
 *
 * Key Concept: Each NFT can have a smart contract account that:
 * - Is controlled by the NFT owner
 * - Has a deterministic address (computed via CREATE2)
 * - Can own assets and execute transactions
 * - Transfers ownership when the NFT is transferred
 */
interface IERC6551Account {
    /**
     * @notice Emitted when a transaction is executed
     * @param target The address that was called
     * @param value The amount of ETH sent with the call
     * @param data The calldata sent
     */
    event TransactionExecuted(address indexed target, uint256 value, bytes data);

    /**
     * @notice Returns the NFT that owns this account
     * @return chainId The chain ID of the NFT contract
     * @return tokenContract The address of the NFT contract
     * @return tokenId The token ID of the NFT
     */
    function token()
        external
        view
        returns (uint256 chainId, address tokenContract, uint256 tokenId);

    /**
     * @notice Returns a nonce that changes when account state changes
     * @dev Used to invalidate signatures when account state changes
     * @return The current state nonce
     */
    function state() external view
 returns (uint256);

    /**
     * @notice Checks if a signer is authorized to use this account
     * @param signer The address to check
     * @return True if the signer is the NFT owner, false otherwise
     */
    function isValidSigner(address signer, bytes calldata context)
        external
        view
        returns (bytes4);
}

/**
 * @title IERC6551Executable
 * @notice Interface for executing transactions from a Token Bound Account
 * @dev Extends IERC6551Account with execution capabilities
 */
interface IERC6551Executable {
    /**
     * @notice Execute a transaction from the account
     * @dev Can only be called by the NFT owner
     * @param target The address to call
     * @param value The amount of ETH to send
     * @param data The calldata to send
     * @param operation The type of operation (0 = CALL, 1 = DELEGATECALL)
     * @return The return data from the call
     */
    function execute(address target, uint256 value, bytes calldata data, uint8 operation)
        external
        payable
        returns (bytes memory);
}

/**
 * @title IERC6551Registry
 * @notice Interface for the canonical ERC-6551 account registry
 * @dev The registry creates token bound accounts using CREATE2 for deterministic addresses
 *
 * Deployed Address: 0x000000006551c19487814612e58FE06813775758 (same on all chains)
 */
interface IERC6551Registry {
    /**
     * @notice Emitted when a new account is created
     * @param account The address of the created account
     * @param implementation The implementation address used
     * @param salt The salt used for CREATE2
     * @param chainId The chain ID
     * @param tokenContract The NFT contract address
     * @param tokenId The token ID
     */
    event ERC6551AccountCreated(
        address account,
        address indexed implementation,
        bytes32 salt,
        uint256 chainId,
        address indexed tokenContract,
        uint256 indexed tokenId
    );

    /**
     * @notice Creates a token bound account
     * @dev Uses CREATE2 to deploy a minimal proxy to the implementation
     * @param implementation The address of the account implementation
     * @param salt A salt for CREATE2 deployment (for address uniqueness)
     * @param chainId The chain ID of the NFT
     * @param tokenContract The address of the NFT contract
     * @param tokenId The token ID of the NFT
     * @return account The address of the created account
     */
    function createAccount(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external returns (address account);

    /**
     * @notice Computes the deterministic address of a token bound account
     * @dev The account address can be computed before deployment
     * @param implementation The address of the account implementation
     * @param salt A salt for CREATE2 deployment
     * @param chainId The chain ID of the NFT
     * @param tokenContract The address of the NFT contract
     * @param tokenId The token ID of the NFT
     * @return account The computed account address
     */
    function account(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external view returns (address account);
}
