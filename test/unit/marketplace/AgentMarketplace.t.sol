// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../../BaseTest.sol";
import {AgentMarketplace} from "../../../src/marketplace/AgentMarketplace.sol";
import {ReputationPricing} from "../../../src/marketplace/ReputationPricing.sol";
import {IAgentMarketplace} from "../../../src/marketplace/IAgentMarketplace.sol";
import {TestConstants} from "../../helpers/TestConstants.sol";

/**
 * @title AgentMarketplaceTest
 * @notice Comprehensive tests for Agent Marketplace
 */
contract AgentMarketplaceTest is BaseTest {
    AgentMarketplace public marketplace;
    ReputationPricing public reputationPricing;
    uint256 public tokenId;
    address public tbaAddress;
    bytes32 public agentId;

    function setUp() public override {
        super.setUp();

        // Mint an agent
        (agentId, tokenId, tbaAddress) = mintDefaultAgent(user1);

        // Deploy marketplace
        vm.prank(deployer);
        marketplace = new AgentMarketplace(
            address(agentLicense),
            address(reputationScore),
            address(insuranceVault),
            deployer // fee recipient
        );

        // Get reputation pricing (deployed by marketplace)
        reputationPricing = marketplace.reputationPricing();
    }

    // =============================================================================
    // Listing Tests
    // =============================================================================

    function test_listAgent_success() public {
        uint256 price = 1 ether;

        vm.prank(user1);
        marketplace.listAgent(tokenId, price, address(0)); // ETH payment

        IAgentMarketplace.Listing memory listing = marketplace.getListing(tokenId);
        assertTrue(listing.active, "Listing should be active");
        assertEq(listing.seller, user1, "Seller should be user1");
        assertEq(listing.price, price, "Price should match");
    }

    function test_listAgent_notOwner() public {
        vm.prank(user2);
        vm.expectRevert();
        marketplace.listAgent(tokenId, 1 ether, address(0));
    }

    function test_listAgent_alreadyListed() public {
        vm.prank(user1);
        marketplace.listAgent(tokenId, 1 ether, address(0));

        vm.prank(user1);
        vm.expectRevert();
        marketplace.listAgent(tokenId, 2 ether, address(0));
    }

    // =============================================================================
    // Buying Tests
    // =============================================================================

    function test_buyAgent_success() public {
        uint256 price = 1 ether;

        // Approve marketplace to transfer NFT
        vm.prank(user1);
        agentLicense.approve(address(marketplace), tokenId);

        // List agent
        vm.prank(user1);
        marketplace.listAgent(tokenId, price, address(0));

        // Buy agent
        vm.deal(user2, 2 ether);
        vm.prank(user2);
        marketplace.buyAgent{value: price}(tokenId);

        // Check NFT transferred
        assertEq(agentLicense.ownerOf(tokenId), user2, "NFT should be transferred to buyer");
        
        // Check listing inactive
        vm.expectRevert();
        marketplace.getListing(tokenId); // Should revert (not listed)
    }

    function test_buyAgent_insufficientPayment() public {
        uint256 price = 1 ether;

        vm.prank(user1);
        marketplace.listAgent(tokenId, price, address(0));

        vm.deal(user2, 0.5 ether);
        vm.prank(user2);
        vm.expectRevert();
        marketplace.buyAgent{value: 0.5 ether}(tokenId);
    }

    // =============================================================================
    // Price Suggestion Tests
    // =============================================================================

    function test_getSuggestedPrice() public {
        // Build some reputation
        bytes memory proof = abi.encode("test-proof");
        vm.prank(zkProver);
        reputationScore.verifyProof(
            tokenId,
            TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            proof,
            "Test"
        );

        uint256 suggestedPrice = marketplace.getSuggestedPrice(tokenId);
        assertGt(suggestedPrice, 0, "Suggested price should be > 0");
    }

    // =============================================================================
    // Cancel Listing Tests
    // =============================================================================

    function test_cancelListing_success() public {
        vm.prank(user1);
        marketplace.listAgent(tokenId, 1 ether, address(0));

        vm.prank(user1);
        marketplace.cancelListing(tokenId);

        vm.expectRevert();
        marketplace.getListing(tokenId); // Should revert (not listed)
    }

    function test_cancelListing_notOwner() public {
        vm.prank(user1);
        marketplace.listAgent(tokenId, 1 ether, address(0));

        vm.prank(user2);
        vm.expectRevert();
        marketplace.cancelListing(tokenId);
    }

    // =============================================================================
    // Update Price Tests
    // =============================================================================

    function test_updatePrice_success() public {
        uint256 initialPrice = 1 ether;
        uint256 newPrice = 2 ether;

        vm.prank(user1);
        marketplace.listAgent(tokenId, initialPrice, address(0));

        vm.prank(user1);
        marketplace.updatePrice(tokenId, newPrice);

        IAgentMarketplace.Listing memory listing = marketplace.getListing(tokenId);
        assertEq(listing.price, newPrice, "Price should be updated");
    }
}
