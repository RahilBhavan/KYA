// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IInsurancePool} from "./IInsurancePool.sol";
import {RiskCalculator} from "./RiskCalculator.sol";
import {IAgentLicense} from "../interfaces/IAgentLicense.sol";
import {IInsuranceVault} from "../interfaces/IInsuranceVault.sol";

/**
 * @title InsurancePool
 * @notice Pool-based insurance system for agents
 * @dev Allows agents to join insurance pools with risk-based pricing
 *
 * Key Features:
 * - Multiple insurance pools with different risk levels
 * - Risk-based premium calculation
 * - Pool participant rewards
 * - Coverage distribution
 */
contract InsurancePool is IInsurancePool, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // =============================================================================
    // State Variables
    // =============================================================================

    /// @notice The USDC token contract
    IERC20 public immutable usdc;

    /// @notice The AgentLicense NFT contract
    IAgentLicense public immutable agentLicense;

    /// @notice The InsuranceVault contract
    IInsuranceVault public immutable insuranceVault;

    /// @notice The RiskCalculator contract
    RiskCalculator public immutable riskCalculator;

    /// @notice Pool counter
    uint256 private _poolCounter;

    /// @notice Mapping from pool ID to pool
    mapping(uint256 => Pool) private _pools;

    /// @notice Mapping from pool ID to token ID to participant
    mapping(uint256 => mapping(uint256 => Participant)) private _participants;

    /// @notice Mapping from pool ID to participant token IDs
    mapping(uint256 => uint256[]) private _poolParticipants;

    // =============================================================================
    // Errors
    // =============================================================================

    error PoolNotFound();
    error PoolNotActive();
    error AlreadyParticipant();
    error NotParticipant();
    error InsufficientStake();
    error InvalidRiskLevel();

    // =============================================================================
    // Constructor
    // =============================================================================

    constructor(
        address usdc_,
        address agentLicense_,
        address insuranceVault_,
        address riskCalculator_
    ) {
        require(usdc_ != address(0), "InsurancePool: zero address");
        require(agentLicense_ != address(0), "InsurancePool: zero address");
        require(insuranceVault_ != address(0), "InsurancePool: zero address");
        require(riskCalculator_ != address(0), "InsurancePool: zero address");

        usdc = IERC20(usdc_);
        agentLicense = IAgentLicense(agentLicense_);
        insuranceVault = IInsuranceVault(insuranceVault_);
        riskCalculator = RiskCalculator(riskCalculator_);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // =============================================================================
    // External Functions - Pool Management
    // =============================================================================

    /**
     * @notice Create a new insurance pool
     * @param name Pool name
     * @param premiumRate Premium rate (basis points)
     * @param riskLevel Risk level (0-100)
     * @return poolId The pool ID
     */
    function createPool(
        string calldata name,
        uint256 premiumRate,
        uint8 riskLevel
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256 poolId) {
        require(premiumRate <= 10000, "InsurancePool: invalid premium rate");
        require(riskLevel <= 100, "InsurancePool: invalid risk level");

        poolId = _poolCounter++;

        _pools[poolId] = Pool({
            poolId: poolId,
            name: name,
            totalStaked: 0,
            totalCoverage: 0,
            premiumRate: premiumRate,
            riskLevel: riskLevel,
            active: true,
            createdAt: block.timestamp
        });

        emit PoolCreated(poolId, name, premiumRate, riskLevel);
        return poolId;
    }

    /**
     * @notice Join an insurance pool
     * @param poolId The pool ID
     * @param tokenId The agent token ID
     * @param stakeAmount Amount to stake
     */
    function joinPool(uint256 poolId, uint256 tokenId, uint256 stakeAmount)
        external
        override
        nonReentrant
    {
        Pool storage pool = _pools[poolId];
        // Check if pool exists by checking createdAt
        if (pool.createdAt == 0) {
            revert PoolNotFound();
        }
        if (!pool.active) {
            revert PoolNotActive();
        }

        // Check not already participant
        if (_participants[poolId][tokenId].stakeAmount > 0) {
            revert AlreadyParticipant();
        }

        // Validate token exists
        require(agentLicense.ownerOf(tokenId) != address(0), "InsurancePool: invalid token");

        // Calculate premium
        uint256 premium = (stakeAmount * pool.premiumRate) / 10000;
        uint256 totalRequired = stakeAmount + premium;

        // Transfer USDC from caller
        usdc.safeTransferFrom(msg.sender, address(this), totalRequired);

        // Update pool
        pool.totalStaked += stakeAmount;
        pool.totalCoverage += stakeAmount; // Coverage equals stake

        // Create participant
        _participants[poolId][tokenId] = Participant({
            tokenId: tokenId,
            stakeAmount: stakeAmount,
            coverageAmount: stakeAmount,
            joinedAt: block.timestamp,
            premiumPaid: premium
        });

        _poolParticipants[poolId].push(tokenId);

        // Distribute premium to existing participants (proportional to stake)
        if (pool.totalStaked > stakeAmount) {
            distributePremium(poolId, premium);
        }

        emit PoolJoined(poolId, tokenId, stakeAmount, premium);
    }

    /**
     * @notice Leave an insurance pool
     * @param poolId The pool ID
     * @param tokenId The agent token ID
     */
    function leavePool(uint256 poolId, uint256 tokenId) external override nonReentrant {
        Pool storage pool = _pools[poolId];
        // Check if pool exists by checking createdAt
        if (pool.createdAt == 0) {
            revert PoolNotFound();
        }
        
        Participant storage participant = _participants[poolId][tokenId];
        if (participant.stakeAmount == 0) {
            revert NotParticipant();
        }

        // Validate owner
        require(agentLicense.ownerOf(tokenId) == msg.sender, "InsurancePool: not owner");

        uint256 amountToReturn = participant.stakeAmount;

        // Update pool
        pool.totalStaked -= participant.stakeAmount;
        pool.totalCoverage -= participant.coverageAmount;

        // Remove participant
        delete _participants[poolId][tokenId];
        removeParticipantFromList(poolId, tokenId);

        // Return stake
        usdc.safeTransfer(msg.sender, amountToReturn);

        emit PoolLeft(poolId, tokenId, amountToReturn);
    }

    // =============================================================================
    // External Functions - Views
    // =============================================================================

    /**
     * @notice Get pool details
     * @param poolId The pool ID
     * @return pool The pool struct
     */
    function getPool(uint256 poolId) external view override returns (Pool memory pool) {
        pool = _pools[poolId];
        // Check if pool exists by checking createdAt (0 means not created)
        if (pool.createdAt == 0) {
            revert PoolNotFound();
        }
        return pool;
    }

    /**
     * @notice Get participant details
     * @param poolId The pool ID
     * @param tokenId The agent token ID
     * @return participant The participant struct
     */
    function getParticipant(uint256 poolId, uint256 tokenId)
        external
        view
        override
        returns (Participant memory participant)
    {
        participant = _participants[poolId][tokenId];
        if (participant.stakeAmount == 0) {
            revert NotParticipant();
        }
        return participant;
    }

    /**
     * @notice Get pool participant count
     * @param poolId The pool ID
     * @return count The number of participants
     */
    function getParticipantCount(uint256 poolId) external view returns (uint256 count) {
        return _poolParticipants[poolId].length;
    }

    // =============================================================================
    // Internal Functions
    // =============================================================================

    /**
     * @notice Distribute premium to pool participants
     * @param poolId The pool ID
     * @param premiumAmount The premium amount to distribute
     */
    function distributePremium(uint256 poolId, uint256 premiumAmount) internal {
        Pool memory pool = _pools[poolId];
        if (pool.totalStaked == 0) {
            return;
        }

        uint256[] memory participantIds = _poolParticipants[poolId];
        for (uint256 i = 0; i < participantIds.length; i++) {
            Participant storage participant = _participants[poolId][participantIds[i]];
            if (participant.stakeAmount > 0) {
                // Proportional distribution
                uint256 share = (premiumAmount * participant.stakeAmount) / pool.totalStaked;
                // Transfer to participant (would need to track participant address)
                // For now, we'll accumulate in the pool
            }
        }
    }

    /**
     * @notice Remove participant from list
     * @param poolId The pool ID
     * @param tokenId The token ID to remove
     */
    function removeParticipantFromList(uint256 poolId, uint256 tokenId) internal {
        uint256[] storage participants = _poolParticipants[poolId];
        for (uint256 i = 0; i < participants.length; i++) {
            if (participants[i] == tokenId) {
                participants[i] = participants[participants.length - 1];
                participants.pop();
                break;
            }
        }
    }
}
