// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IOracle} from "./IOracle.sol";
import {IInsuranceVault} from "../interfaces/IInsuranceVault.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title OracleAdapter
 * @notice Adapter contract for oracle integration (UMA/Kleros)
 * @dev Handles claim submission and resolution for InsuranceVault
 *
 * This contract acts as a bridge between oracles and InsuranceVault.
 * It can be extended to support multiple oracles (UMA, Kleros, etc.)
 */
contract OracleAdapter is IOracle, AccessControl {
    // =============================================================================
    // State Variables
    // =============================================================================

    /// @notice The InsuranceVault contract
    IInsuranceVault public immutable insuranceVault;

    /// @notice Mapping from oracle request ID to claim data
    mapping(bytes32 => ClaimData) private _claims;

    /// @notice Mapping from oracle request ID to resolution result
    mapping(bytes32 => ResolutionResult) private _resolutions;

    /// @notice Mapping from oracle request ID to status (0=pending, 1=resolved, 2=failed)
    mapping(bytes32 => uint8) private _statuses;

    /// @notice Mapping from InsuranceVault claimId to oracle requestId
    mapping(bytes32 => bytes32) private _vaultToOracle;

    /// @notice Mapping from oracle requestId to InsuranceVault claimId
    mapping(bytes32 => bytes32) private _oracleToVault;

    /// @notice Counter for request IDs
    uint256 private _requestCounter;

    // =============================================================================
    // Errors
    // =============================================================================

    error InvalidClaim();
    error RequestNotFound();
    error InvalidStatus();

    // =============================================================================
    // Constructor
    // =============================================================================

    constructor(address insuranceVault_) {
        require(insuranceVault_ != address(0), "OracleAdapter: zero address");

        insuranceVault = IInsuranceVault(insuranceVault_);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // =============================================================================
    // External Functions
    // =============================================================================

    /**
     * @notice Submit claim to oracle
     * @param claimData The claim data
     * @return requestId The oracle request identifier
     */
    function submitClaim(ClaimData memory claimData)
        external
        override
        returns (bytes32 requestId)
    {
        require(claimData.merchant != address(0), "OracleAdapter: invalid merchant");
        require(claimData.amount > 0, "OracleAdapter: invalid amount");

        // Store original vault claimId before overwriting
        bytes32 vaultClaimId = claimData.claimId;

        requestId = keccak256(
            abi.encodePacked(
                _requestCounter++,
                vaultClaimId,
                claimData.tokenId,
                block.timestamp,
                msg.sender
            )
        );

        claimData.claimId = requestId;
        _claims[requestId] = claimData;
        _statuses[requestId] = 0; // Pending

        // Link to InsuranceVault claim (bidirectional mapping)
        _vaultToOracle[vaultClaimId] = requestId;
        _oracleToVault[requestId] = vaultClaimId;

        emit ClaimSubmittedToOracle(requestId, msg.sender);

        return requestId;
    }

    /**
     * @notice Process oracle resolution
     * @dev Called by oracle after off-chain validation
     * @param requestId The oracle request identifier
     * @param approved Whether the claim is approved
     * @param resolutionData Additional resolution data
     */
    function processResolution(
        bytes32 requestId,
        bool approved,
        bytes calldata resolutionData
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ClaimData memory claim = _claims[requestId];
        if (claim.merchant == address(0)) {
            revert RequestNotFound();
        }

        // Store resolution
        _resolutions[requestId] = ResolutionResult({
            claimId: requestId,
            approved: approved,
            resolutionData: resolutionData
        });

        _statuses[requestId] = 1; // Resolved

        // Resolve claim in InsuranceVault
        // Note: This requires ORACLE_ROLE on InsuranceVault
        // Get the original vault claimId from the mapping
        bytes32 vaultClaimId = _oracleToVault[requestId];
        require(vaultClaimId != bytes32(0), "OracleAdapter: vault claim not found");
        insuranceVault.resolveClaim(vaultClaimId, approved);

        emit ClaimResolvedByOracle(requestId, approved);
    }

    /**
     * @notice Get claim status
     * @param requestId The oracle request identifier
     * @return status The status (0=pending, 1=resolved, 2=failed)
     * @return result The resolution result (if available)
     */
    function getClaimStatus(bytes32 requestId)
        external
        view
        override
        returns (uint8 status, ResolutionResult memory result)
    {
        status = _statuses[requestId];
        if (status == 0 && _claims[requestId].merchant == address(0)) {
            revert RequestNotFound();
        }

        if (status == 1) {
            result = _resolutions[requestId];
        }
    }

    /**
     * @notice Get claim data
     * @param requestId The oracle request identifier
     * @return claim The claim data
     */
    function getClaim(bytes32 requestId) external view returns (ClaimData memory claim) {
        claim = _claims[requestId];
        if (claim.merchant == address(0)) {
            revert RequestNotFound();
        }
    }

    /**
     * @notice Get oracle request ID from InsuranceVault claim ID
     * @param vaultClaimId The InsuranceVault claim ID
     * @return requestId The oracle request ID
     */
    function getOracleRequestId(bytes32 vaultClaimId) external view returns (bytes32 requestId) {
        requestId = _vaultToOracle[vaultClaimId];
        if (requestId == bytes32(0)) {
            revert RequestNotFound();
        }
    }
}

