// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IAgentLicense} from "./interfaces/IAgentLicense.sol";

/**
 * @title AgentLicense
 * @notice ERC-721 NFT representing KYA Agent Licenses
 * @dev Each NFT represents an AI agent's identity and is linked to a Token Bound Account
 *
 * Key Features:
 * - Only addresses with MINTER_ROLE (AgentRegistry) can mint
 * - Stores agent metadata on-chain for composability
 * - Supports OpenSea metadata standards
 * - Immutable core data with admin-controlled status updates
 * - Gas-optimized for Base network
 */
contract AgentLicense is ERC721, AccessControl, IAgentLicense {
    using Strings for uint256;

    // =============================================================================
    // Constants
    // =============================================================================

    /// @notice Role identifier for addresses authorized to mint tokens
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // =============================================================================
    // State Variables
    // =============================================================================

    /// @notice Counter for token IDs
    uint256 private _tokenIdCounter;

    /// @notice Base URI for token metadata
    string private _baseTokenURI;

    /// @notice Mapping from token ID to agent metadata
    mapping(uint256 => AgentMetadata) private _agentMetadata;

    // =============================================================================
    // Constructor
    // =============================================================================

    /**
     * @notice Initializes the Agent License NFT contract
     * @param name The name of the NFT collection
     * @param symbol The symbol of the NFT collection
     * @param baseURI The base URI for token metadata
     */
    constructor(string memory name, string memory symbol, string memory baseURI)
        ERC721(name, symbol)
    {
        _baseTokenURI = baseURI;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Start token IDs at 1 (0 is reserved as null value)
        _tokenIdCounter = 1;
    }

    // =============================================================================
    // External Functions - Minting
    // =============================================================================

    /**
     * @notice Mint a new agent license
     * @dev Can only be called by addresses with MINTER_ROLE (typically AgentRegistry)
     * @param to The address to mint the token to
     * @param metadata The agent's metadata
     * @return tokenId The ID of the minted token
     */
    function mint(address to, AgentMetadata calldata metadata)
        external
        override
        onlyRole(MINTER_ROLE)
        returns (uint256 tokenId)
    {
        // Input validation
        require(to != address(0), "AgentLicense: mint to zero address");
        require(bytes(metadata.name).length > 0, "AgentLicense: name cannot be empty");
        require(bytes(metadata.name).length <= 64, "AgentLicense: name too long");
        require(bytes(metadata.category).length > 0, "AgentLicense: category cannot be empty");
        require(metadata.status == 0, "AgentLicense: initial status must be Active");

        // Get next token ID and increment counter
        tokenId = _tokenIdCounter++;

        // Store metadata
        _agentMetadata[tokenId] = AgentMetadata({
            name: metadata.name,
            description: metadata.description,
            category: metadata.category,
            createdAt: block.timestamp,
            status: 0 // Active by default
        });

        // Mint the NFT
        _safeMint(to, tokenId);

        emit AgentMinted(tokenId, to, metadata.name, metadata.category);
    }

    // =============================================================================
    // External Functions - Metadata
    // =============================================================================

    /**
     * @notice Get the metadata for an agent
     * @param tokenId The ID of the token
     * @return metadata The agent's metadata
     */
    function getAgentMetadata(uint256 tokenId)
        external
        view
        override
        returns (AgentMetadata memory metadata)
    {
        _requireOwned(tokenId);
        return _agentMetadata[tokenId];
    }

    /**
     * @notice Returns the token URI for a given token ID
     * @dev Overrides ERC721's tokenURI to support dynamic metadata
     * @param tokenId The ID of the token
     * @return The token URI (IPFS or HTTP endpoint)
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        string memory baseURI = _baseTokenURI;

        // If base URI is set, return base + tokenId
        if (bytes(baseURI).length > 0) {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }

        // Otherwise return empty string (can be set later)
        return "";
    }

    /**
     * @notice Set the base URI for token metadata
     * @dev Can only be called by admin
     * @param baseURI The new base URI
     */
    function setBaseURI(string calldata baseURI) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = baseURI;
    }

    // =============================================================================
    // External Functions - Status Management
    // =============================================================================

    /**
     * @notice Update an agent's status
     * @dev Can only be called by admin
     * @param tokenId The ID of the token
     * @param newStatus The new status (0=Active, 1=Suspended, 2=Revoked)
     */
    function updateAgentStatus(uint256 tokenId, uint8 newStatus)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _requireOwned(tokenId);
        require(newStatus <= 2, "AgentLicense: invalid status");

        uint8 oldStatus = _agentMetadata[tokenId].status;
        require(oldStatus != newStatus, "AgentLicense: status unchanged");

        _agentMetadata[tokenId].status = newStatus;

        emit AgentStatusChanged(tokenId, oldStatus, newStatus);
    }

    // =============================================================================
    // External Functions - Views
    // =============================================================================

    /**
     * @notice Returns the total number of agents minted
     * @return The total supply of agent licenses
     */
    function totalSupply() external view override returns (uint256) {
        return _tokenIdCounter - 1; // Subtract 1 because we start at 1
    }

    /**
     * @notice Check if contract supports an interface
     * @dev Overrides both ERC721 and AccessControl
     * @param interfaceId The interface identifier
     * @return True if interface is supported
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // =============================================================================
    // Internal Functions
    // =============================================================================

    /**
     * @notice Returns the base URI for computing tokenURI
     * @dev Override of ERC721's _baseURI
     * @return The base URI string
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}
