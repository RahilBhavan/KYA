// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IPaymaster} from "./interfaces/IPaymaster.sol";
import {IAgentLicense} from "./interfaces/IAgentLicense.sol";
import {IAgentRegistry} from "./interfaces/IAgentRegistry.sol";

/**
 * @title Paymaster
 * @notice ERC-4337 Paymaster for cold start gas sponsorship
 * @dev Sponsors gas fees for new agents (first 7 days, first 50 transactions)
 *
 * Key Features:
 * - Gas sponsorship for agents < 7 days old
 * - Limited to first 50 transactions per agent
 * - Twitter-linked verification requirement
 * - ERC-4337 EntryPoint integration
 *
 * Note: This is a simplified implementation. Full ERC-4337 integration requires
 * the EntryPoint contract from the account-abstraction standard.
 */
contract Paymaster is IPaymaster, AccessControl, ReentrancyGuard {
    // =============================================================================
    // Constants
    // =============================================================================

    /// @notice Cold start period (7 days)
    uint256 public constant COLD_START_PERIOD = 7 days;

    /// @notice Maximum sponsored transactions per agent
    uint256 public constant MAX_SPONSORED_TXS = 50;

    // =============================================================================
    // State Variables
    // =============================================================================

    /// @notice The ERC-4337 EntryPoint address
    address private immutable _entryPoint;

    /// @notice The AgentLicense NFT contract
    IAgentLicense public immutable agentLicense;

    /// @notice The AgentRegistry contract
    IAgentRegistry public immutable agentRegistry;

    /// @notice Mapping from token ID to sponsored transaction count
    mapping(uint256 => uint256) private _sponsoredCounts;

    /// @notice Mapping from token ID to Twitter verification status
    mapping(uint256 => bool) private _twitterVerified;

    /// @notice Total deposited funds
    uint256 private _deposited;

    // =============================================================================
    // Errors
    // =============================================================================

    error InvalidTokenId();
    error NotEligible();
    error InsufficientFunds();
    error InvalidEntryPoint();
    error NotAuthorized();

    // =============================================================================
    // Constructor
    // =============================================================================

    /**
     * @notice Initialize the Paymaster
     * @param entryPoint_ The ERC-4337 EntryPoint address
     * @param agentLicense_ The AgentLicense NFT contract address
     * @param agentRegistry_ The AgentRegistry contract address
     */
    constructor(
        address entryPoint_,
        address agentLicense_,
        address agentRegistry_
    ) {
        require(entryPoint_ != address(0), "Paymaster: zero address");
        require(agentLicense_ != address(0), "Paymaster: zero address");
        require(agentRegistry_ != address(0), "Paymaster: zero address");

        _entryPoint = entryPoint_;
        agentLicense = IAgentLicense(agentLicense_);
        agentRegistry = IAgentRegistry(agentRegistry_);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // =============================================================================
    // External Functions - ERC-4337 Interface
    // =============================================================================

    /**
     * @notice Validate paymaster data and deposit
     * @dev ERC-4337 EntryPoint will call this
     * @param paymasterAndData The paymaster data (encoded PaymasterData)
     * @return context Context to pass to postOp
     * @return validationData Validation data (deadline and signature)
     */
    function validatePaymasterUserOp(
        uint8 /* mode */,
        bytes calldata /* userOp */,
        bytes calldata paymasterAndData
    ) external override returns (bytes memory context, uint256 validationData) {
        // Only EntryPoint can call this
        if (msg.sender != _entryPoint) {
            revert InvalidEntryPoint();
        }

        // Decode paymaster data
        PaymasterData memory data = abi.decode(paymasterAndData[20:], (PaymasterData));

        // Combined eligibility check (optimized)
        uint256 remaining = _checkEligibility(data.tokenId);
        if (remaining == 0) {
            revert NotEligible();
        }

        // Increment sponsored count
        _sponsoredCounts[data.tokenId] += 1;

        // Return context (tokenId for postOp)
        context = abi.encode(data.tokenId, data.maxCost);

        // Validation data: valid until block.timestamp + 1 hour
        validationData = (block.timestamp + 1 hours) << 160;

        return (context, validationData);
    }

    /**
     * @notice Post-operation hook
     * @dev Called after user operation execution
     * @param context The context from validatePaymasterUserOp
     * @param actualGasCost The actual gas cost
     */
    function postOp(uint8 /* mode */, bytes calldata context, uint256 actualGasCost)
        external
        override
        nonReentrant
    {
        // Only EntryPoint can call this
        if (msg.sender != _entryPoint) {
            revert InvalidEntryPoint();
        }

        // Decode context
        (uint256 tokenId, uint256 maxCost) = abi.decode(context, (uint256, uint256));

        // Ensure we don't pay more than maxCost
        uint256 cost = actualGasCost > maxCost ? maxCost : actualGasCost;

        // Pay EntryPoint for gas (ERC-4337 standard)
        // In ERC-4337, EntryPoint withdraws from paymaster's deposit balance
        // We need to ensure sufficient balance is available
        require(_deposited >= cost, "Paymaster: insufficient deposit");

        // Update deposited amount (EntryPoint will withdraw from this)
        _deposited -= cost;

        // In production ERC-4337, EntryPoint automatically withdraws from deposit
        // For this implementation, we track the deposit reduction
        // The actual ETH transfer is handled by EntryPoint's internal accounting

        // Emit event
        emit GasSponsored(tokenId, cost, keccak256(context));
    }

    // =============================================================================
    // External Functions - Funding
    // =============================================================================

    /**
     * @notice Deposit funds to the paymaster
     * @dev Allows protocol to fund the paymaster
     */
    function deposit() external payable override {
        _deposited += msg.value;

        // Also deposit to EntryPoint if needed
        // In full ERC-4337, you'd call entryPoint.depositTo{value: msg.value}(address(this))
    }

    /**
     * @notice Withdraw funds from the paymaster
     * @param withdrawAddress The address to withdraw to
     * @param amount The amount to withdraw
     */
    function withdrawTo(address payable withdrawAddress, uint256 amount)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        require(withdrawAddress != address(0), "Paymaster: zero address");
        require(amount <= address(this).balance, "Paymaster: insufficient balance");

        _deposited -= amount;
        (bool success,) = withdrawAddress.call{value: amount}("");
        require(success, "Paymaster: transfer failed");
    }

    // =============================================================================
    // External Functions - Views
    // =============================================================================

    /**
     * @notice Get the entry point address
     * @return The ERC-4337 EntryPoint address
     */
    function entryPoint() external view override returns (address) {
        return _entryPoint;
    }

    /**
     * @notice Check if an agent is eligible for gas sponsorship
     * @param tokenId The agent's token ID
     * @return eligible Whether the agent is eligible
     * @return remainingTransactions Number of remaining sponsored transactions
     */
    function isEligible(uint256 tokenId)
        public
        view
        override
        returns (bool eligible, uint256 remainingTransactions)
    {
        uint256 remaining = _checkEligibility(tokenId);
        return (remaining > 0, remaining);
    }

    /**
     * @notice Internal eligibility check (optimized)
     * @param tokenId The agent's token ID
     * @return remaining Number of remaining sponsored transactions (0 if not eligible)
     */
    function _checkEligibility(uint256 tokenId) internal view returns (uint256 remaining) {
        // Check if token exists
        try agentLicense.ownerOf(tokenId) returns (address) {} catch {
            return 0;
        }

        // Get agent metadata
        IAgentLicense.AgentMetadata memory metadata = agentLicense.getAgentMetadata(tokenId);

        // Check if agent is within cold start period
        if (block.timestamp > metadata.createdAt + COLD_START_PERIOD) {
            return 0;
        }

        // Check Twitter verification
        if (!_twitterVerified[tokenId]) {
            return 0;
        }

        // Check sponsored count
        uint256 sponsored = _sponsoredCounts[tokenId];
        if (sponsored >= MAX_SPONSORED_TXS) {
            return 0;
        }

        return MAX_SPONSORED_TXS - sponsored;
    }

    /**
     * @notice Get sponsored transaction count for an agent
     * @param tokenId The agent's token ID
     * @return count The number of sponsored transactions
     */
    function getSponsoredCount(uint256 tokenId) external view returns (uint256 count) {
        return _sponsoredCounts[tokenId];
    }

    /**
     * @notice Get total deposited funds
     * @return amount The total deposited amount
     */
    function getDeposited() external view returns (uint256 amount) {
        return _deposited;
    }

    // =============================================================================
    // External Functions - Admin
    // =============================================================================

    /**
     * @notice Set Twitter verification status for an agent
     * @param tokenId The agent's token ID
     * @param verified Whether the agent is Twitter verified
     */
    function setTwitterVerified(uint256 tokenId, bool verified)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _twitterVerified[tokenId] = verified;
    }

    /**
     * @notice Check Twitter verification status
     * @param tokenId The agent's token ID
     * @return verified Whether the agent is Twitter verified
     */
    function isTwitterVerified(uint256 tokenId) external view returns (bool verified) {
        return _twitterVerified[tokenId];
    }
}

