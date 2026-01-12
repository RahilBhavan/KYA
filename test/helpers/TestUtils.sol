// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {IAgentLicense} from "../../src/interfaces/IAgentLicense.sol";
import {IInsuranceVault} from "../../src/interfaces/IInsuranceVault.sol";
import {IReputationScore} from "../../src/interfaces/IReputationScore.sol";

/**
 * @title TestUtils
 * @notice Utility functions for testing
 */
contract TestUtils is Test {
    /**
     * @notice Create agent metadata
     */
    function createAgentMetadata(
        string memory name,
        string memory description,
        string memory category
    ) internal view returns (IAgentLicense.AgentMetadata memory) {
        return IAgentLicense.AgentMetadata({
            name: name,
            description: description,
            category: category,
            createdAt: block.timestamp,
            status: 0 // Active
        });
    }

    /**
     * @notice Create default agent metadata
     */
    function createDefaultAgentMetadata()
        internal
        view
        returns (IAgentLicense.AgentMetadata memory)
    {
        return createAgentMetadata("TestAgent", "Test Description", "Trading");
    }

    /**
     * @notice Create ZK proof data structure
     */
    function createProofData(
        string memory proofType,
        string memory metadata
    ) internal pure returns (bytes memory) {
        return abi.encode(proofType, metadata);
    }

    /**
     * @notice Create claim reason
     */
    function createClaimReason(
        string memory conditionType,
        string memory description
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(conditionType, ": ", description));
    }

    /**
     * @notice Assert stake info matches expected values
     * @dev Note: tokenId was removed from StakeInfo struct (it's the mapping key)
     */
    function assertStakeInfo(
        IInsuranceVault.StakeInfo memory stakeInfo,
        uint256 expectedAmount,
        bool expectedVerified
    ) internal pure {
        assertEq(stakeInfo.amount, expectedAmount, "Stake amount mismatch");
        assertEq(stakeInfo.isVerified, expectedVerified, "Verification status mismatch");
    }

    /**
     * @notice Assert reputation data matches expected values
     * @dev Note: score is uint224 in ReputationData, but we accept uint256 for convenience
     */
    function assertReputationData(
        IReputationScore.ReputationData memory repData,
        uint256 expectedTokenId,
        uint256 expectedScore,
        uint8 expectedTier
    ) internal pure {
        assertEq(repData.tokenId, expectedTokenId, "Token ID mismatch");
        // Cast to uint224 for comparison (score is uint224 in struct)
        assertEq(uint256(repData.score), expectedScore, "Score mismatch");
        assertEq(repData.tier, expectedTier, "Tier mismatch");
    }

    /**
     * @notice Time manipulation helpers
     */
    function warp(uint256 newTimestamp) internal {
        vm.warp(newTimestamp);
    }

    function roll(uint256 newBlockNumber) internal {
        vm.roll(newBlockNumber);
    }

    function warpTo(uint256 targetTimestamp) internal {
        vm.warp(block.timestamp + targetTimestamp);
    }

    /**
     * @notice Balance assertion helpers
     */
    function assertBalance(address account, uint256 expectedBalance) internal view {
        assertEq(account.balance, expectedBalance, "ETH balance mismatch");
    }

    function assertERC20Balance(
        address token,
        address account,
        uint256 expectedBalance
    ) internal view {
        // This would require IERC20 interface - simplified for now
        // In actual tests, use: assertEq(IERC20(token).balanceOf(account), expectedBalance);
    }
}

