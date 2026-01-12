// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IPaymaster
 * @notice Interface for ERC-4337 Paymaster contract
 * @dev Handles gas sponsorship for new agents (cold start)
 */
interface IPaymaster {
    /**
     * @notice Paymaster operation data
     * @param tokenId The agent's token ID
     * @param userOp The user operation being sponsored
     * @param maxCost The maximum cost the paymaster will cover
     */
    struct PaymasterData {
        uint256 tokenId;
        bytes userOp;
        uint256 maxCost;
    }

    /**
     * @notice Emitted when gas is sponsored
     * @param tokenId The agent's token ID
     * @param amount The amount of gas sponsored
     * @param userOpHash The hash of the user operation
     */
    event GasSponsored(
        uint256 indexed tokenId, uint256 amount, bytes32 indexed userOpHash
    );

    /**
     * @notice Validate paymaster data and deposit
     * @dev ERC-4337 EntryPoint will call this
     * @param mode The validation mode
     * @param userOp The user operation
     * @param paymasterAndData The paymaster data (encoded PaymasterData)
     * @return context Context to pass to postOp
     * @return validationData Validation data (deadline and signature)
     */
    function validatePaymasterUserOp(
        uint8 mode,
        bytes calldata userOp,
        bytes calldata paymasterAndData
    ) external returns (bytes memory context, uint256 validationData);

    /**
     * @notice Post-operation hook
     * @dev Called after user operation execution
     * @param mode The operation mode
     * @param context The context from validatePaymasterUserOp
     * @param actualGasCost The actual gas cost
     */
    function postOp(uint8 mode, bytes calldata context, uint256 actualGasCost) external;

    /**
     * @notice Deposit funds to the paymaster
     * @dev Allows protocol to fund the paymaster
     */
    function deposit() external payable;

    /**
     * @notice Withdraw funds from the paymaster
     * @param withdrawAddress The address to withdraw to
     * @param amount The amount to withdraw
     */
    function withdrawTo(address payable withdrawAddress, uint256 amount) external;

    /**
     * @notice Get the entry point address
     * @return entryPoint The ERC-4337 EntryPoint address
     */
    function entryPoint() external view returns (address entryPoint);

    /**
     * @notice Check if an agent is eligible for gas sponsorship
     * @param tokenId The agent's token ID
     * @return eligible Whether the agent is eligible
     * @return remainingTransactions Number of remaining sponsored transactions
     */
    function isEligible(uint256 tokenId)
        external
        view
        returns (bool eligible, uint256 remainingTransactions);
}

