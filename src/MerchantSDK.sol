// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IMerchantSDK} from "./interfaces/IMerchantSDK.sol";
import {IInsuranceVault} from "./interfaces/IInsuranceVault.sol";
import {IReputationScore} from "./interfaces/IReputationScore.sol";
import {IAgentLicense} from "./interfaces/IAgentLicense.sol";
import {IAgentRegistry} from "./interfaces/IAgentRegistry.sol";

/**
 * @title MerchantSDK
 * @notice On-chain verification functions for merchants
 * @dev Provides easy-to-use verification for merchants integrating with KYA agents
 *
 * Key Features:
 * - Single function to verify agent eligibility
 * - Check minimum requirements (stake, reputation)
 * - Get insurance coverage amount
 * - Report violations (triggers claim process)
 *
 * Usage:
 * ```solidity
 * MerchantSDK sdk = MerchantSDK(merchantSDKAddress);
 * VerificationResult memory result = sdk.verifyAgent(tokenId, tbaAddress);
 * require(result.isVerified && result.isActive, "Agent not eligible");
 * ```
 */
contract MerchantSDK is IMerchantSDK {
    // =============================================================================
    // State Variables
    // =============================================================================

    /// @notice The InsuranceVault contract
    IInsuranceVault public immutable insuranceVault;

    /// @notice The ReputationScore contract
    IReputationScore public immutable reputationScore;

    /// @notice The AgentLicense NFT contract
    IAgentLicense public immutable agentLicense;

    /// @notice The AgentRegistry contract
    IAgentRegistry public immutable agentRegistry;

    // =============================================================================
    // Constructor
    // =============================================================================

    /**
     * @notice Initialize the Merchant SDK
     * @param insuranceVault_ The InsuranceVault contract address
     * @param reputationScore_ The ReputationScore contract address
     * @param agentLicense_ The AgentLicense NFT contract address
     * @param agentRegistry_ The AgentRegistry contract address
     */
    constructor(
        address insuranceVault_,
        address reputationScore_,
        address agentLicense_,
        address agentRegistry_
    ) {
        require(insuranceVault_ != address(0), "MerchantSDK: zero address");
        require(reputationScore_ != address(0), "MerchantSDK: zero address");
        require(agentLicense_ != address(0), "MerchantSDK: zero address");
        require(agentRegistry_ != address(0), "MerchantSDK: zero address");

        insuranceVault = IInsuranceVault(insuranceVault_);
        reputationScore = IReputationScore(reputationScore_);
        agentLicense = IAgentLicense(agentLicense_);
        agentRegistry = IAgentRegistry(agentRegistry_);
    }

    // =============================================================================
    // External Functions - Verification
    // =============================================================================

    /**
     * @notice Verify an agent before allowing interaction
     * @param tokenId The agent's token ID
     * @param tbaAddress The Token Bound Account address
     * @return result The verification result
     */
    function verifyAgent(uint256 tokenId, address tbaAddress)
        external
        view
        override
        returns (VerificationResult memory result)
    {
        // Verify TBA address matches
        IAgentRegistry.AgentInfo memory info = agentRegistry.getAgentInfoByTokenId(tokenId);
        require(info.tbaAddress == tbaAddress, "MerchantSDK: invalid TBA address");

        // Get stake information
        IInsuranceVault.StakeInfo memory stakeInfo = insuranceVault.getStakeInfo(tokenId);
        bool isVerified = stakeInfo.isVerified;

        // Get reputation
        IReputationScore.ReputationData memory rep = reputationScore.getReputation(tokenId);

        // Get agent status
        IAgentLicense.AgentMetadata memory metadata = agentLicense.getAgentMetadata(tokenId);
        bool isActive = metadata.status == 0; // 0 = Active

        result = VerificationResult({
            isVerified: isVerified,
            stakeAmount: stakeInfo.amount,
            reputationScore: rep.score,
            tier: rep.tier,
            isActive: isActive
        });

        return result;
    }

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
    ) external view override returns (bool) {
        // Get stake information
        IInsuranceVault.StakeInfo memory stakeInfo = insuranceVault.getStakeInfo(tokenId);
        if (stakeInfo.amount < minStake) {
            return false;
        }

        // Get reputation
        IReputationScore.ReputationData memory rep = reputationScore.getReputation(tokenId);
        if (rep.score < minReputation) {
            return false;
        }

        // Check agent is active
        IAgentLicense.AgentMetadata memory metadata = agentLicense.getAgentMetadata(tokenId);
        if (metadata.status != 0) {
            return false;
        }

        return true;
    }

    /**
     * @notice Get agent's insurance coverage amount
     * @param tokenId The agent's token ID
     * @return coverage The amount of USDC coverage available
     */
    function getCoverage(uint256 tokenId) external view override returns (uint256 coverage) {
        IInsuranceVault.StakeInfo memory stakeInfo = insuranceVault.getStakeInfo(tokenId);
        return stakeInfo.amount;
    }

    /**
     * @notice Report a violation (triggers claim process)
     * @param tokenId The agent's token ID
     * @param violation The violation details
     * @return claimId The claim identifier
     */
    function reportViolation(uint256 tokenId, Violation calldata violation)
        external
        override
        returns (bytes32 claimId)
    {
        // Build reason string
        string memory reason = string(
            abi.encodePacked(
                violation.conditionType,
                ": ",
                violation.description
            )
        );

        // Get coverage amount (claim up to full coverage)
        uint256 coverage = this.getCoverage(tokenId);
        require(coverage > 0, "MerchantSDK: no coverage available");

        // Submit claim to insurance vault
        claimId = insuranceVault.submitClaim(tokenId, coverage, reason);

        return claimId;
    }
}

