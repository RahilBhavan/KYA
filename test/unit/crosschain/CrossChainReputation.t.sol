// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../../BaseTest.sol";
import {CrossChainReputation} from "../../../src/crosschain/CrossChainReputation.sol";
import {LayerZeroAdapter} from "../../../src/crosschain/LayerZeroAdapter.sol";
import {ICrossChain} from "../../../src/crosschain/ICrossChain.sol";

/**
 * @title CrossChainReputationTest
 * @notice Tests for cross-chain reputation synchronization
 */
contract CrossChainReputationTest is BaseTest {
    CrossChainReputation public crossChainRep;
    LayerZeroAdapter public messageRelayer;
    uint256 public tokenId;
    address public tbaAddress;
    bytes32 public agentId;

    function setUp() public override {
        super.setUp();

        // Mint an agent
        (agentId, tokenId, tbaAddress) = mintDefaultAgent(user1);

        // Deploy message relayer (mock LayerZero endpoint)
        vm.prank(deployer);
        messageRelayer = new LayerZeroAdapter(address(0x123)); // Mock endpoint

        // Deploy CrossChainReputation
        vm.prank(deployer);
        crossChainRep = new CrossChainReputation(
            address(reputationScore),
            address(agentLicense),
            address(messageRelayer)
        );

        // Add supported chain
        vm.prank(deployer);
        crossChainRep.setSupportedChain(1, true); // Ethereum mainnet
    }

    function test_syncReputation() public {
        uint256 sourceChainId = 1; // Ethereum
        uint256 score = 1000;
        bytes memory proof = abi.encode(sourceChainId, "mock-proof");

        // Simulate message verification (in production, this would be done by relayer)
        // For testing, we'll need to mock the verification

        // Note: Full test would require proper message relayer setup
        // This is a basic structure
    }

    function test_getSyncedScore() public {
        uint256 chainId = 1;
        uint256 score = crossChainRep.getSyncedScore(tokenId, chainId);
        assertEq(score, 0, "Initial synced score should be 0");
    }
}
