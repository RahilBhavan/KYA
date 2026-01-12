// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title IAgentLicense
 * @notice Interface for the Agent License NFT contract
 * @dev Extends ERC-721 with protocol-specific functionality
 */
interface IAgentLicense is IERC721 {
    /// @notice Role identifier for addresses authorized to mint tokens
    function MINTER_ROLE() external view returns (bytes32);

    /**
     * @notice Agent metadata structure
     * @param name The agent's display name
     * @param description Brief description of the agent
     * @param category Agent category (e.g., "Trading", "DeFi", "NFT")
     * @param createdAt Timestamp when agent was created
     * @param status Current status (0=Active, 1=Suspended, 2=Revoked)
     */
    struct AgentMetadata {
        string name;
        string description;
        string category;
        uint256 createdAt;
        uint8 status; // 0=Active, 1=Suspended, 2=Revoked
    }

    /**
     * @notice Emitted when a new agent license is minted
     * @param tokenId The ID of the minted token
     * @param owner The address that received the token
     * @param name The agent's name
     * @param category The agent's category
     */
    event AgentMinted(
        uint256 indexed tokenId, address indexed owner, string name, string category
    );

    /**
     * @notice Emitted when an agent's status changes
     * @param tokenId The ID of the token
     * @param oldStatus The previous status
     * @param newStatus The new status
     */
    event AgentStatusChanged(uint256 indexed tokenId, uint8 oldStatus, uint8 newStatus);

    /**
     * @notice Mint a new agent license
     * @dev Can only be called by addresses with MINTER_ROLE (typically AgentRegistry)
     * @param to The address to mint the token to
     * @param metadata The agent's metadata
     * @return tokenId The ID of the minted token
     */
    function mint(address to, AgentMetadata calldata metadata)
        external
        returns (uint256 tokenId);

    /**
     * @notice Get the metadata for an agent
     * @param tokenId The ID of the token
     * @return metadata The agent's metadata
     */
    function getAgentMetadata(uint256 tokenId)
        external
        view
        returns (AgentMetadata memory metadata);

    /**
     * @notice Update an agent's status
     * @dev Can only be called by admin
     * @param tokenId The ID of the token
     * @param newStatus The new status (0=Active, 1=Suspended, 2=Revoked)
     */
    function updateAgentStatus(uint256 tokenId, uint8 newStatus) external;

    /**
     * @notice Set the base URI for token metadata
     * @dev Can only be called by admin
     * @param baseURI The new base URI
     */
    function setBaseURI(string calldata baseURI) external;

    /**
     * @notice Returns the total number of agents minted
     * @return The total supply of agent licenses
     */
    function totalSupply() external view returns (uint256);
}
