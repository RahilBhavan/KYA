// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IAgentMarketplace
 * @notice Interface for Agent NFT Marketplace
 */
interface IAgentMarketplace {
    /**
     * @notice Listing structure
     * @param tokenId The agent token ID
     * @param seller The seller address
     * @param price The listing price (in wei)
     * @param paymentToken Payment token address (address(0) for ETH)
     * @param reputationScore The agent's reputation score at listing time
     * @param tier The agent's tier at listing time
     * @param listedAt Timestamp when listed
     * @param active Whether listing is active
     */
    struct Listing {
        uint256 tokenId;
        address seller;
        uint256 price;
        address paymentToken;
        uint256 reputationScore;
        uint8 tier;
        uint256 listedAt;
        bool active;
    }

    /**
     * @notice List an agent for sale
     * @param tokenId The agent token ID
     * @param price The listing price
     * @param paymentToken Payment token address (address(0) for ETH)
     */
    function listAgent(uint256 tokenId, uint256 price, address paymentToken) external;

    /**
     * @notice Buy an agent (ETH payment)
     * @param tokenId The agent token ID
     */
    function buyAgent(uint256 tokenId) external payable;

    /**
     * @notice Buy an agent (ERC-20 payment)
     * @param tokenId The agent token ID
     */
    function buyAgentWithToken(uint256 tokenId) external;

    /**
     * @notice Cancel a listing
     * @param tokenId The agent token ID
     */
    function cancelListing(uint256 tokenId) external;

    /**
     * @notice Update listing price
     * @param tokenId The agent token ID
     * @param newPrice The new price
     */
    function updatePrice(uint256 tokenId, uint256 newPrice) external;

    /**
     * @notice Get listing details
     * @param tokenId The agent token ID
     * @return listing The listing struct
     */
    function getListing(uint256 tokenId) external view returns (Listing memory listing);

    /**
     * @notice Get suggested price based on reputation
     * @param tokenId The agent token ID
     * @return suggestedPrice The suggested price
     */
    function getSuggestedPrice(uint256 tokenId) external view returns (uint256 suggestedPrice);

    /**
     * @notice Emitted when an agent is listed
     */
    event AgentListed(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price,
        address paymentToken,
        uint256 reputationScore,
        uint8 tier
    );

    /**
     * @notice Emitted when an agent is sold
     */
    event AgentSold(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 price,
        address paymentToken
    );

    /**
     * @notice Emitted when a listing is canceled
     */
    event ListingCanceled(uint256 indexed tokenId, address indexed seller);

    /**
     * @notice Emitted when listing price is updated
     */
    event PriceUpdated(uint256 indexed tokenId, uint256 oldPrice, uint256 newPrice);
}
