// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IOracle
 * @notice Interface for oracle integration (UMA/Kleros)
 * @dev This interface defines the standard for oracle dispute resolution
 */
interface IOracle {
    /**
     * @notice Claim data structure
     * @param claimId The claim identifier
     * @param tokenId The agent's token ID
     * @param merchant The merchant making the claim
     * @param amount The claim amount
     * @param reason The claim reason
     * @param evidence Additional evidence
     */
    struct ClaimData {
        bytes32 claimId;
        uint256 tokenId;
        address merchant;
        uint256 amount;
        string reason;
        bytes evidence;
    }

    /**
     * @notice Resolution result
     * @param claimId The claim identifier
     * @param approved Whether the claim is approved
     * @param resolutionData Additional resolution data
     */
    struct ResolutionResult {
        bytes32 claimId;
        bool approved;
        bytes resolutionData;
    }

    /**
     * @notice Emitted when a claim is submitted to oracle
     * @param claimId The claim identifier
     * @param oracleAddress The oracle address
     */
    event ClaimSubmittedToOracle(bytes32 indexed claimId, address indexed oracleAddress);

    /**
     * @notice Emitted when oracle resolves a claim
     * @param claimId The claim identifier
     * @param approved Whether approved
     */
    event ClaimResolvedByOracle(bytes32 indexed claimId, bool approved);

    /**
     * @notice Submit claim to oracle
     * @param claimData The claim data
     * @return requestId The oracle request identifier
     */
    function submitClaim(ClaimData memory claimData) external returns (bytes32 requestId);

    /**
     * @notice Get claim status
     * @param requestId The oracle request identifier
     * @return status The status (0=pending, 1=resolved, 2=failed)
     * @return result The resolution result (if available)
     */
    function getClaimStatus(bytes32 requestId)
        external
        view
        returns (uint8 status, ResolutionResult memory result);
}

