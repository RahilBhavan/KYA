// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IAgentRegistry} from "./interfaces/IAgentRegistry.sol";
import {IAgentLicense} from "./interfaces/IAgentLicense.sol";
import {IERC6551Registry} from "./interfaces/IERC6551.sol";

/**
 * @title AgentRegistry
 * @notice Central coordinator for the KYA Protocol
 * @dev Factory contract that creates agents (NFT + TBA) atomically
 *
 * Key Responsibilities:
 * - Mint AgentLicense NFTs through controlled access
 * - Create Token Bound Accounts via ERC-6551 Registry
 * - Maintain agent metadata and mappings
 * - Collect and manage minting fees
 * - Provide pause mechanism for emergencies
 *
 * Architecture:
 * - Stateless coordinator (can be upgraded by deploying new version)
 * - Immutable NFT contract (permanent agent identities)
 * - Uses canonical ERC6551Registry (0x000000006551c19487814612e58FE06813775758)
 */
contract AgentRegistry is IAgentRegistry, AccessControl, Pausable, ReentrancyGuard {
    // =============================================================================
    // State Variables
    // =============================================================================

    /// @notice The AgentLicense NFT contract
    IAgentLicense public immutable agentLicense;

    /// @notice The SimpleAccountImplementation contract (TBA implementation)
    address public immutable accountImplementation;

    /// @notice The canonical ERC-6551 Registry
    IERC6551Registry public immutable erc6551Registry;

    /// @notice Current minting fee in wei
    uint256 private _mintingFee;

    /// @notice Counter for agent IDs
    uint256 private _agentCounter;

    /// @notice Mapping from agent ID to agent information
    mapping(bytes32 => AgentInfo) private _agents;

    /// @notice Mapping from token ID to agent ID
    mapping(uint256 => bytes32) private _tokenIdToAgentId;

    /// @notice Accumulated fees ready for withdrawal
    uint256 private _accumulatedFees;

    // =============================================================================
    // Constants
    // =============================================================================

    /// @notice Salt used for CREATE2 deployments (for deterministic TBA addresses)
    bytes32 private constant ACCOUNT_SALT = bytes32(0);

    // =============================================================================
    // Constructor
    // =============================================================================

    /**
     * @notice Initialize the Agent Registry
     * @param agentLicense_ The AgentLicense NFT contract address
     * @param accountImplementation_ The SimpleAccountImplementation address
     * @param erc6551Registry_ The canonical ERC-6551 Registry address
     * @param initialMintingFee The initial minting fee in wei
     */
    constructor(
        address agentLicense_,
        address accountImplementation_,
        address erc6551Registry_,
        uint256 initialMintingFee
    ) {
        require(agentLicense_ != address(0), "AgentRegistry: zero address");
        require(accountImplementation_ != address(0), "AgentRegistry: zero address");
        require(erc6551Registry_ != address(0), "AgentRegistry: zero address");

        agentLicense = IAgentLicense(agentLicense_);
        accountImplementation = accountImplementation_;
        erc6551Registry = IERC6551Registry(erc6551Registry_);
        _mintingFee = initialMintingFee;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Start agent counter at 1
        _agentCounter = 1;
    }

    // =============================================================================
    // External Functions - Agent Creation
    // =============================================================================

    /**
     * @notice Mint a new agent (creates NFT + TBA atomically)
     * @param name The agent's display name
     * @param description Brief description of the agent
     * @param category Agent category
     * @return agentId Unique identifier for the agent
     * @return tokenId The NFT token ID
     * @return tbaAddress The Token Bound Account address
     */
    function mintAgent(string calldata name, string calldata description, string calldata category)
        external
        payable
        override
        whenNotPaused
        nonReentrant
        returns (bytes32 agentId, uint256 tokenId, address tbaAddress)
    {
        // Validate minting fee
        require(msg.value >= _mintingFee, "AgentRegistry: insufficient fee");

        // Input validation
        require(bytes(name).length > 0, "AgentRegistry: name cannot be empty");
        require(bytes(category).length > 0, "AgentRegistry: category cannot be empty");

        // Generate unique agent ID
        agentId = keccak256(abi.encodePacked(msg.sender, _agentCounter, block.timestamp));
        _agentCounter++;

        // Mint the AgentLicense NFT
        tokenId = agentLicense.mint(
            msg.sender,
            IAgentLicense.AgentMetadata({
                name: name,
                description: description,
                category: category,
                createdAt: block.timestamp,
                status: 0 // Active
            })
        );

        // Create the Token Bound Account via ERC-6551 Registry
        tbaAddress = erc6551Registry.createAccount(
            accountImplementation,
            ACCOUNT_SALT,
            block.chainid,
            address(agentLicense),
            tokenId
        );

        // Store agent information
        _agents[agentId] = AgentInfo({
            tokenId: tokenId,
            tbaAddress: tbaAddress,
            owner: msg.sender,
            createdAt: block.timestamp
        });

        _tokenIdToAgentId[tokenId] = agentId;

        // Accumulate fees
        _accumulatedFees += msg.value;

        // Refund excess payment if any
        uint256 excess = msg.value - _mintingFee;
        if (excess > 0) {
            (bool success,) = msg.sender.call{value: excess}("");
            require(success, "AgentRegistry: refund failed");
        }

        emit AgentCreated(agentId, tokenId, tbaAddress, msg.sender, name);
    }

    // =============================================================================
    // External Functions - Views
    // =============================================================================

    /**
     * @notice Get agent information by agent ID
     * @param agentId The unique agent ID
     * @return info The agent's information
     */
    function getAgentInfo(bytes32 agentId) external view override returns (AgentInfo memory info) {
        info = _agents[agentId];
        require(info.tokenId != 0, "AgentRegistry: agent not found");
        return info;
    }

    /**
     * @notice Get agent information by token ID
     * @param tokenId The NFT token ID
     * @return info The agent's information
     */
    function getAgentInfoByTokenId(uint256 tokenId)
        external
        view
        override
        returns (AgentInfo memory info)
    {
        bytes32 agentId = _tokenIdToAgentId[tokenId];
        require(agentId != bytes32(0), "AgentRegistry: agent not found");
        return _agents[agentId];
    }

    /**
     * @notice Compute the TBA address for a token
     * @dev Uses the same logic as ERC6551Registry for address prediction
     * @param tokenId The NFT token ID
     * @return tbaAddress The deterministic TBA address
     */
    function computeTBAAddress(uint256 tokenId)
        external
        view
        override
        returns (address tbaAddress)
    {
        return erc6551Registry.account(
            accountImplementation, ACCOUNT_SALT, block.chainid, address(agentLicense), tokenId
        );
    }

    /**
     * @notice Get the current minting fee
     * @return The minting fee in wei
     */
    function getMintingFee() external view override returns (uint256) {
        return _mintingFee;
    }

    /**
     * @notice Get the total number of agents created
     * @return The total agent count
     */
    function totalAgents() external view override returns (uint256) {
        return _agentCounter - 1; // Subtract 1 because we start at 1
    }

    // =============================================================================
    // External Functions - Admin
    // =============================================================================

    /**
     * @notice Update the minting fee
     * @dev Can only be called by admin
     * @param newFee The new minting fee in wei
     */
    function setMintingFee(uint256 newFee) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 oldFee = _mintingFee;
        _mintingFee = newFee;
        emit MintingFeeUpdated(oldFee, newFee);
    }

    /**
     * @notice Withdraw collected fees
     * @dev Can only be called by admin
     * @param recipient The address to send fees to
     */
    function withdrawFees(address payable recipient)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        require(recipient != address(0), "AgentRegistry: zero address");
        uint256 amount = _accumulatedFees;
        require(amount > 0, "AgentRegistry: no fees to withdraw");

        _accumulatedFees = 0;

        (bool success,) = recipient.call{value: amount}("");
        require(success, "AgentRegistry: transfer failed");

        emit FeesWithdrawn(recipient, amount);
    }

    /**
     * @notice Pause the contract
     * @dev Can only be called by admin
     */
    function pause() external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause the contract
     * @dev Can only be called by admin
     */
    function unpause() external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}
