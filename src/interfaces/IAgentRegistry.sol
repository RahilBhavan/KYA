// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IAgentRegistry
 * @notice Interface for the Agent Registry contract
 * @dev Central coordinator that creates agents (NFT + TBA) atomically
 */
import {IAgentLicense} from "./IAgentLicense.sol";
import {IERC6551Registry} from "../interfaces/IERC6551.sol";

interface IAgentRegistry {
    /// @notice Get the AgentLicense contract
    function agentLicense() external view returns (IAgentLicense);

    /// @notice Get the ERC6551 Registry contract
    function erc6551Registry() external view returns (IERC6551Registry);
    /**
     * @notice Agent information structure
     * @param tokenId The NFT token ID
     * @param tbaAddress The Token Bound Account address
     * @param owner The current owner of the agent
     * @param createdAt Timestamp when agent was created
     */
    struct AgentInfo {
        uint256 tokenId;
        address tbaAddress;
        address owner;
        uint256 createdAt;
    }

    /**
     * @notice Emitted when a new agent is created
     * @param agentId The unique agent ID
     * @param tokenId The NFT token ID
     * @param tbaAddress The Token Bound Account address
     * @param owner The owner of the agent
     * @param name The agent's name
     */
    event AgentCreated(
        bytes32 indexed agentId,
        uint256 indexed tokenId,
        address indexed tbaAddress,
        address owner,
        string name
    );

    /**
     * @notice Emitted when minting fee is updated
     * @param oldFee The previous fee
     * @param newFee The new fee
     */
    event MintingFeeUpdated(uint256 oldFee, uint256 newFee);

    /**
     * @notice Emitted when fees are withdrawn
     * @param recipient The address that received the fees
     * @param amount The amount withdrawn
     */
    event FeesWithdrawn(address indexed recipient, uint256 amount);

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
        returns (bytes32 agentId, uint256 tokenId, address tbaAddress);

    /**
     * @notice Get agent information by agent ID
     * @param agentId The unique agent ID
     * @return info The agent's information
     */
    function getAgentInfo(bytes32 agentId) external view returns (AgentInfo memory info);

    /**
     * @notice Get agent information by token ID
     * @param tokenId The NFT token ID
     * @return info The agent's information
     */
    function getAgentInfoByTokenId(uint256 tokenId)
        external
        view
        returns (AgentInfo memory info);

    /**
     * @notice Compute the TBA address for a token
     * @param tokenId The NFT token ID
     * @return tbaAddress The deterministic TBA address
     */
    function computeTBAAddress(uint256 tokenId) external view returns (address tbaAddress);

    /**
     * @notice Get the current minting fee
     * @return The minting fee in wei
     */
    function getMintingFee() external view returns (uint256);

    /**
     * @notice Update the minting fee
     * @dev Can only be called by admin
     * @param newFee The new minting fee in wei
     */
    function setMintingFee(uint256 newFee) external;

    /**
     * @notice Withdraw collected fees
     * @dev Can only be called by admin
     * @param recipient The address to send fees to
     */
    function withdrawFees(address payable recipient) external;

    /**
     * @notice Pause the contract
     * @dev Can only be called by admin
     */
    function pause() external;

    /**
     * @notice Unpause the contract
     * @dev Can only be called by admin
     */
    function unpause() external;

    /**
     * @notice Get the total number of agents created
     * @return The total agent count
     */
    function totalAgents() external view returns (uint256);
}
