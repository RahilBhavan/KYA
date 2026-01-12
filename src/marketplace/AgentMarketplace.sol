// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IAgentMarketplace} from "./IAgentMarketplace.sol";
import {ReputationPricing} from "./ReputationPricing.sol";
import {IAgentLicense} from "../interfaces/IAgentLicense.sol";
import {IReputationScore} from "../interfaces/IReputationScore.sol";

/**
 * @title AgentMarketplace
 * @notice Marketplace for buying and selling agent NFTs
 * @dev Implements listing, buying, and reputation-based pricing
 *
 * Key Features:
 * - List agents for sale (ETH or ERC-20)
 * - Buy agents with ETH or ERC-20
 * - Reputation-based price suggestions
 * - Platform fees
 * - Royalty system
 */
contract AgentMarketplace is IAgentMarketplace, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // =============================================================================
    // Constants
    // =============================================================================

    /// @notice Platform fee (basis points, e.g., 250 = 2.5%)
    uint256 public constant PLATFORM_FEE_BPS = 250; // 2.5%

    /// @notice Royalty fee (basis points, e.g., 500 = 5%)
    uint256 public constant ROYALTY_FEE_BPS = 500; // 5%

    // =============================================================================
    // State Variables
    // =============================================================================

    /// @notice The AgentLicense NFT contract
    IAgentLicense public immutable agentLicense;

    /// @notice The ReputationScore contract
    IReputationScore public immutable reputationScore;

    /// @notice The ReputationPricing helper
    ReputationPricing public immutable reputationPricing;

    /// @notice Platform fee recipient
    address public feeRecipient;

    /// @notice Mapping from token ID to listing
    mapping(uint256 => Listing) private _listings;

    /// @notice Supported payment tokens
    mapping(address => bool) public supportedPaymentTokens;

    // =============================================================================
    // Errors
    // =============================================================================

    error NotListed();
    error AlreadyListed();
    error NotOwner();
    error InsufficientPayment();
    error InvalidPaymentToken();
    error TransferFailed();

    // =============================================================================
    // Constructor
    // =============================================================================

    constructor(
        address agentLicense_,
        address reputationScore_,
        address insuranceVault_,
        address feeRecipient_
    ) {
        require(agentLicense_ != address(0), "AgentMarketplace: zero address");
        require(reputationScore_ != address(0), "AgentMarketplace: zero address");
        require(insuranceVault_ != address(0), "AgentMarketplace: zero address");
        require(feeRecipient_ != address(0), "AgentMarketplace: zero address");

        agentLicense = IAgentLicense(agentLicense_);
        reputationScore = IReputationScore(reputationScore_);
        feeRecipient = feeRecipient_;

        // Deploy ReputationPricing helper
        reputationPricing = new ReputationPricing(reputationScore_, insuranceVault_);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // ETH is always supported
        supportedPaymentTokens[address(0)] = true;
    }

    // =============================================================================
    // External Functions - Listings
    // =============================================================================

    /**
     * @notice List an agent for sale
     * @param tokenId The agent token ID
     * @param price The listing price
     * @param paymentToken Payment token address (address(0) for ETH)
     */
    function listAgent(uint256 tokenId, uint256 price, address paymentToken)
        external
        override
    {
        // Validate owner
        require(agentLicense.ownerOf(tokenId) == msg.sender, "AgentMarketplace: not owner");
        
        // Check not already listed
        if (_listings[tokenId].active) {
            revert AlreadyListed();
        }

        // Validate payment token
        if (paymentToken != address(0) && !supportedPaymentTokens[paymentToken]) {
            revert InvalidPaymentToken();
        }

        // Get reputation data
        IReputationScore.ReputationData memory rep = reputationScore.getReputation(tokenId);

        // Create listing
        _listings[tokenId] = Listing({
            tokenId: tokenId,
            seller: msg.sender,
            price: price,
            paymentToken: paymentToken,
            reputationScore: rep.score,
            tier: rep.tier,
            listedAt: block.timestamp,
            active: true
        });

        emit AgentListed(tokenId, msg.sender, price, paymentToken, rep.score, rep.tier);
    }

    /**
     * @notice Buy an agent with ETH
     * @param tokenId The agent token ID
     */
    function buyAgent(uint256 tokenId) external payable override nonReentrant {
        Listing memory listing = _listings[tokenId];
        if (!listing.active) {
            revert NotListed();
        }
        if (listing.paymentToken != address(0)) {
            revert InvalidPaymentToken(); // Use buyAgentWithToken for ERC-20
        }
        if (msg.value < listing.price) {
            revert InsufficientPayment();
        }

        // Mark listing as inactive
        _listings[tokenId].active = false;

        // Calculate fees
        uint256 platformFee = (listing.price * PLATFORM_FEE_BPS) / 10000;
        uint256 royaltyFee = (listing.price * ROYALTY_FEE_BPS) / 10000;
        uint256 sellerAmount = listing.price - platformFee - royaltyFee;

        // Transfer NFT
        agentLicense.transferFrom(listing.seller, msg.sender, tokenId);

        // Transfer payments
        payable(listing.seller).transfer(sellerAmount);
        payable(feeRecipient).transfer(platformFee);
        // Royalty goes to original creator (would need to track this)
        // For now, send to fee recipient
        payable(feeRecipient).transfer(royaltyFee);

        // Refund excess
        if (msg.value > listing.price) {
            payable(msg.sender).transfer(msg.value - listing.price);
        }

        emit AgentSold(tokenId, listing.seller, msg.sender, listing.price, address(0));
    }

    /**
     * @notice Buy an agent with ERC-20 token
     * @param tokenId The agent token ID
     */
    function buyAgentWithToken(uint256 tokenId) external override nonReentrant {
        Listing memory listing = _listings[tokenId];
        if (!listing.active) {
            revert NotListed();
        }
        if (listing.paymentToken == address(0)) {
            revert InvalidPaymentToken(); // Use buyAgent for ETH
        }

        IERC20 paymentToken = IERC20(listing.paymentToken);

        // Calculate fees
        uint256 platformFee = (listing.price * PLATFORM_FEE_BPS) / 10000;
        uint256 royaltyFee = (listing.price * ROYALTY_FEE_BPS) / 10000;
        uint256 sellerAmount = listing.price - platformFee - royaltyFee;

        // Transfer tokens
        paymentToken.safeTransferFrom(msg.sender, listing.seller, sellerAmount);
        paymentToken.safeTransferFrom(msg.sender, feeRecipient, platformFee);
        paymentToken.safeTransferFrom(msg.sender, feeRecipient, royaltyFee);

        // Mark listing as inactive
        _listings[tokenId].active = false;

        // Transfer NFT
        agentLicense.transferFrom(listing.seller, msg.sender, tokenId);

        emit AgentSold(tokenId, listing.seller, msg.sender, listing.price, listing.paymentToken);
    }

    /**
     * @notice Cancel a listing
     * @param tokenId The agent token ID
     */
    function cancelListing(uint256 tokenId) external override {
        Listing memory listing = _listings[tokenId];
        if (!listing.active) {
            revert NotListed();
        }
        if (listing.seller != msg.sender && !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert NotOwner();
        }

        _listings[tokenId].active = false;
        emit ListingCanceled(tokenId, listing.seller);
    }

    /**
     * @notice Update listing price
     * @param tokenId The agent token ID
     * @param newPrice The new price
     */
    function updatePrice(uint256 tokenId, uint256 newPrice) external override {
        Listing storage listing = _listings[tokenId];
        if (!listing.active) {
            revert NotListed();
        }
        if (listing.seller != msg.sender) {
            revert NotOwner();
        }

        uint256 oldPrice = listing.price;
        listing.price = newPrice;

        emit PriceUpdated(tokenId, oldPrice, newPrice);
    }

    // =============================================================================
    // External Functions - Views
    // =============================================================================

    /**
     * @notice Get listing details
     * @param tokenId The agent token ID
     * @return listing The listing struct
     */
    function getListing(uint256 tokenId)
        external
        view
        override
        returns (Listing memory listing)
    {
        listing = _listings[tokenId];
        if (!listing.active) {
            revert NotListed();
        }
        return listing;
    }

    /**
     * @notice Get suggested price based on reputation
     * @param tokenId The agent token ID
     * @return suggestedPrice The suggested price
     */
    function getSuggestedPrice(uint256 tokenId)
        external
        view
        override
        returns (uint256 suggestedPrice)
    {
        return reputationPricing.calculatePrice(tokenId);
    }

    // =============================================================================
    // External Functions - Admin
    // =============================================================================

    /**
     * @notice Set fee recipient
     * @param newFeeRecipient New fee recipient address
     */
    function setFeeRecipient(address newFeeRecipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newFeeRecipient != address(0), "AgentMarketplace: zero address");
        feeRecipient = newFeeRecipient;
    }

    /**
     * @notice Add or remove supported payment token
     * @param token Token address
     * @param supported Whether token is supported
     */
    function setSupportedPaymentToken(address token, bool supported)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(token != address(0), "AgentMarketplace: zero address");
        supportedPaymentTokens[token] = supported;
    }
}
