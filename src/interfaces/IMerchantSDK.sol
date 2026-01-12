// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IInsuranceVault} from "./IInsuranceVault.sol";
import {IReputationScore} from "./IReputationScore.sol";

/**
 * @title IMerchantSDK
 * @notice Interface for Merchant SDK verification functions
 * @dev Provides on-chain verification for merchants integrating with KYA agents
 */
interface IMerchantSDK {
    /// @notice Get the InsuranceVault contract
    function insuranceVault() external view returns (IInsuranceVault);

    /// @notice Get the ReputationScore contract
    function reputationScore() external view returns (IReputationScore);
    /**
     * @notice Agent verification result
     * @param isVerified Whether the agent has insurance stake
     * @param stakeAmount The amount of USDC staked
     * @param reputationScore The agent's reputation score
     * @param tier The agent's reputation tier
     * @param isActive Whether the agent is active (not suspended/revoked)
     */
    struct VerificationResult {
        bool isVerified;
        uint256 stakeAmount;
        uint256 reputationScore;
        uint8 tier;
        bool isActive;
    }

    /**
     * @notice Malicious condition violation
     * @param conditionType The type of condition violated
     * @param description Human-readable description
     * @param evidence Proof of violation (transaction hash, etc.)
     */
    struct Violation {
        string conditionType;
        string description;
        bytes evidence;
    }

    /**
     * @notice Verify an agent before allowing interaction
     * @param tokenId The agent's token ID
     * @param tbaAddress The Token Bound Account address
     * @return result The verification result
     */
    function verifyAgent(uint256 tokenId, address tbaAddress)
        external
        view
        returns (VerificationResult memory result);

    /**
     * @notice Check if an agent meets minimum requirements
     * @param tokenId The agent's token ID
     * @param minStake Minimum required stake
     * @param minReputation Minimum required reputation score
     * @return meetsRequirements Whether the agent meets requirements
     */
    function meetsRequirements(
        uint256 tokenId,
        uint256 minStake,
        uint256 minReputation
    ) external view returns (bool meetsRequirements);

    /**
     * @notice Get agent's insurance coverage amount
     * @param tokenId The agent's token ID
     * @return coverage The amount of USDC coverage available
     */
    function getCoverage(uint256 tokenId) external view returns (uint256 coverage);

    /**
     * @notice Report a violation (triggers claim process)
     * @param tokenId The agent's token ID
     * @param violation The violation details
     * @return claimId The claim identifier
     */
    function reportViolation(uint256 tokenId, Violation calldata violation)
        external
        returns (bytes32 claimId);
}

