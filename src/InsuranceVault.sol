// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IInsuranceVault} from "./interfaces/IInsuranceVault.sol";
import {IAgentLicense} from "./interfaces/IAgentLicense.sol";
import {IAgentRegistry} from "./interfaces/IAgentRegistry.sol";

/**
 * @title InsuranceVault
 * @notice Insurance vault for agent staking and slashing mechanism
 * @dev Implements the economic security layer for the KYA Protocol
 *
 * Key Features:
 * - Agents stake USDC to achieve "Verified" status
 * - Merchants can submit claims for malicious behavior
 * - Optimistic oracle integration for dispute resolution
 * - Slashing mechanism with challenge period
 * - Minimum stake requirement (e.g., 1000 USDC)
 *
 * Security:
 * - Reentrancy protection on all external functions
 * - Access control for oracle/admin operations
 * - Pausable for emergencies
 * - SafeERC20 for token transfers
 */
contract InsuranceVault is
    IInsuranceVault,
    AccessControl,
    ReentrancyGuard,
    Pausable
{
    using SafeERC20 for IERC20;

    // =============================================================================
    // Constants
    // =============================================================================

    /// @notice Role identifier for addresses authorized to resolve claims (oracle/admin)
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    /// @notice Default challenge period (24 hours)
    uint256 public constant CHALLENGE_PERIOD = 24 hours;

    /// @notice Default unstaking cooldown (7 days)
    uint256 public constant UNSTAKE_COOLDOWN = 7 days;

    // =============================================================================
    // State Variables
    // =============================================================================

    /// @notice The USDC token contract
    IERC20 public immutable usdc;

    /// @notice The AgentLicense NFT contract
    IAgentLicense public immutable agentLicense;

    /// @notice The AgentRegistry contract
    IAgentRegistry public immutable agentRegistry;

    /// @notice Minimum stake required for verification (e.g., 1000 USDC)
    uint256 public minimumStake;

    /// @notice Claim fee percentage (basis points, e.g., 100 = 1%)
    uint256 public claimFeeBps;

    /// @notice Mapping from token ID to stake information
    mapping(uint256 => StakeInfo) private _stakes;

    /// @notice Mapping from claim ID to claim information
    mapping(bytes32 => Claim) private _claims;

    /// @notice Mapping from token ID to claim IDs
    mapping(uint256 => bytes32[]) private _agentClaims;

    /// @notice Mapping from token ID to unstake request timestamp
    mapping(uint256 => uint256) private _unstakeRequests;

    /// @notice Counter for claim IDs
    uint256 private _claimCounter;

    /// @notice Total amount staked across all agents (for fee calculation)
    uint256 private _totalStaked;

    // =============================================================================
    // Errors
    // =============================================================================

    error InsufficientStake();
    error InvalidTokenId();
    error InvalidAmount();
    error ClaimNotFound();
    error ClaimAlreadyResolved();
    error NotEligibleForUnstake();
    error UnstakeCooldownNotMet();
    error InsufficientBalance();
    error InvalidClaim();
    error ChallengePeriodExpired();
    error NotAuthorized();

    // =============================================================================
    // Constructor
    // =============================================================================

    /**
     * @notice Initialize the Insurance Vault
     * @param usdc_ The USDC token contract address
     * @param agentLicense_ The AgentLicense NFT contract address
     * @param agentRegistry_ The AgentRegistry contract address
     * @param minimumStake_ The minimum stake required for verification (in USDC, 6 decimals)
     * @param claimFeeBps_ The claim fee in basis points (e.g., 100 = 1%)
     */
    constructor(
        address usdc_,
        address agentLicense_,
        address agentRegistry_,
        uint256 minimumStake_,
        uint256 claimFeeBps_
    ) {
        require(usdc_ != address(0), "InsuranceVault: zero address");
        require(agentLicense_ != address(0), "InsuranceVault: zero address");
        require(agentRegistry_ != address(0), "InsuranceVault: zero address");
        require(minimumStake_ > 0, "InsuranceVault: invalid minimum stake");
        require(claimFeeBps_ <= 1000, "InsuranceVault: claim fee too high"); // Max 10%

        usdc = IERC20(usdc_);
        agentLicense = IAgentLicense(agentLicense_);
        agentRegistry = IAgentRegistry(agentRegistry_);
        minimumStake = minimumStake_;
        claimFeeBps = claimFeeBps_;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // =============================================================================
    // External Functions - Staking
    // =============================================================================

    /**
     * @notice Stake USDC to achieve verified status
     * @param tokenId The agent's token ID
     * @param amount The amount of USDC to stake (must be >= minimumStake)
     */
    function stake(uint256 tokenId, uint256 amount)
        external
        override
        nonReentrant
        whenNotPaused
    {
        // Validate token exists
        try agentLicense.ownerOf(tokenId) returns (address) {} catch {
            revert InvalidTokenId();
        }

        // Validate amount
        if (amount < minimumStake) {
            revert InsufficientStake();
        }

        // Get or cache TBA address (optimization: only fetch on first stake)
        StakeInfo storage stakeInfo = _stakes[tokenId];
        address tbaAddress = stakeInfo.tbaAddress;
        
        if (tbaAddress == address(0)) {
            // First stake - get and cache TBA address
            IAgentRegistry.AgentInfo memory info = agentRegistry.getAgentInfoByTokenId(tokenId);
            tbaAddress = info.tbaAddress;
            stakeInfo.tbaAddress = tbaAddress;
        }

        // Transfer USDC from TBA to vault
        usdc.safeTransferFrom(tbaAddress, address(this), amount);

        // Update stake information (optimized: only set stakedAt on first stake)
        bool isFirstStake = stakeInfo.amount == 0;
        stakeInfo.amount += amount;
        if (isFirstStake) {
            stakeInfo.stakedAt = block.timestamp;
        }
        stakeInfo.isVerified = stakeInfo.amount >= minimumStake;

        // Update total staked counter
        _totalStaked += amount;

        emit Staked(tokenId, amount, tbaAddress);
    }

    /**
     * @notice Request to unstake (starts cooldown period for verified agents)
     * @param tokenId The agent's token ID
     */
    function requestUnstake(uint256 tokenId) external {
        StakeInfo storage stakeInfo = _stakes[tokenId];
        
        // Check if stake exists
        if (stakeInfo.amount == 0) {
            revert InvalidTokenId();
        }

        // Only verified agents need to request unstake (cooldown)
        if (stakeInfo.isVerified) {
            // Set cooldown timestamp if not already set
            if (_unstakeRequests[tokenId] == 0) {
                _unstakeRequests[tokenId] = block.timestamp;
            }
        }
    }

    /**
     * @notice Unstake USDC (only if agent is not verified or after cooldown)
     * @param tokenId The agent's token ID
     * @param amount The amount to unstake
     */
    function unstake(uint256 tokenId, uint256 amount)
        external
        override
        nonReentrant
        whenNotPaused
    {
        StakeInfo storage stakeInfo = _stakes[tokenId];
        
        // Check if stake exists (amount > 0 means stake exists)
        if (stakeInfo.amount == 0) {
            revert InvalidTokenId();
        }

        if (amount == 0 || amount > stakeInfo.amount) {
            revert InvalidAmount();
        }

        // Check if agent is verified
        bool wasVerified = stakeInfo.isVerified;
        
        // If verified, require cooldown period
        if (wasVerified) {
            if (_unstakeRequests[tokenId] == 0) {
                revert UnstakeCooldownNotMet();
            }

            if (block.timestamp < _unstakeRequests[tokenId] + UNSTAKE_COOLDOWN) {
                revert UnstakeCooldownNotMet();
            }
        }

        // Use cached TBA address (optimization: no external call needed)
        address tbaAddress = stakeInfo.tbaAddress;
        require(tbaAddress != address(0), "InsuranceVault: invalid TBA");

        // Update stake information
        stakeInfo.amount -= amount;
        stakeInfo.isVerified = stakeInfo.amount >= minimumStake;

        // Update total staked counter
        _totalStaked -= amount;

        // Clear unstake request if fully unstaked
        if (stakeInfo.amount == 0) {
            _unstakeRequests[tokenId] = 0;
        }

        // Transfer USDC back to TBA
        usdc.safeTransfer(tbaAddress, amount);

        emit Unstaked(tokenId, amount);
    }

    // =============================================================================
    // External Functions - Claims
    // =============================================================================

    /**
     * @notice Submit a claim for slashing
     * @param tokenId The agent's token ID
     * @param amount The amount to claim
     * @param reason The reason for the claim
     * @return claimId The unique claim identifier
     */
    function submitClaim(uint256 tokenId, uint256 amount, string calldata reason)
        external
        override
        nonReentrant
        whenNotPaused
        returns (bytes32 claimId)
    {
        StakeInfo memory stakeInfo = _stakes[tokenId];
        
        if (stakeInfo.amount == 0 || !stakeInfo.isVerified) {
            revert InvalidClaim();
        }

        if (amount == 0 || amount > stakeInfo.amount) {
            revert InvalidAmount();
        }

        // Generate claim ID
        claimId = keccak256(
            abi.encodePacked(
                tokenId,
                msg.sender,
                amount,
                reason,
                block.timestamp,
                _claimCounter++
            )
        );

        // Create claim
        _claims[claimId] = Claim({
            claimId: claimId,
            tokenId: tokenId,
            merchant: msg.sender,
            amount: amount,
            reason: reason,
            submittedAt: block.timestamp,
            status: 0, // Pending
            challengeDeadline: block.timestamp + CHALLENGE_PERIOD
        });

        _agentClaims[tokenId].push(claimId);

        emit ClaimSubmitted(claimId, tokenId, msg.sender, amount);

        return claimId;
    }

    /**
     * @notice Resolve a claim (called by oracle or admin)
     * @param claimId The claim identifier
     * @param approved Whether the claim is approved
     */
    function resolveClaim(bytes32 claimId, bool approved)
        external
        override
        onlyRole(ORACLE_ROLE)
        nonReentrant
    {
        Claim storage claim = _claims[claimId];
        
        if (claim.claimId == bytes32(0)) {
            revert ClaimNotFound();
        }

        if (claim.status != 0 && claim.status != 3) {
            // Not pending or challenged
            revert ClaimAlreadyResolved();
        }

        uint8 newStatus = approved ? 1 : 2; // 1=Approved, 2=Rejected
        claim.status = newStatus;

        if (approved) {
            // Slash the agent's stake
            _slash(claim.tokenId, claim.amount, claim.merchant);
        }

        emit ClaimResolved(claimId, newStatus, approved ? claim.amount : 0);
    }

    /**
     * @notice Challenge a claim (agent can challenge within challenge period)
     * @param claimId The claim identifier
     */
    function challengeClaim(bytes32 claimId) external override {
        Claim storage claim = _claims[claimId];
        
        if (claim.claimId == bytes32(0)) {
            revert ClaimNotFound();
        }

        if (claim.status != 0) {
            revert ClaimAlreadyResolved();
        }

        if (block.timestamp > claim.challengeDeadline) {
            revert ChallengePeriodExpired();
        }

        // Verify caller owns the agent
        IAgentRegistry.AgentInfo memory info = agentRegistry.getAgentInfoByTokenId(claim.tokenId);
        if (msg.sender != info.owner) {
            revert NotAuthorized();
        }

        // Set status to challenged (escalates to human arbitration)
        claim.status = 3; // Challenged

        emit ClaimResolved(claimId, 3, 0);
    }

    // =============================================================================
    // Internal Functions
    // =============================================================================

    /**
     * @notice Slash an agent's stake
     * @param tokenId The agent's token ID
     * @param amount The amount to slash
     * @param recipient The address receiving the slashed funds
     */
    function _slash(uint256 tokenId, uint256 amount, address recipient) internal {
        StakeInfo storage stakeInfo = _stakes[tokenId];
        
        if (amount > stakeInfo.amount) {
            amount = stakeInfo.amount; // Slash all available
        }

        // Calculate claim fee
        uint256 fee = (amount * claimFeeBps) / 10000;
        uint256 payout = amount - fee;

        // Update stake
        stakeInfo.amount -= amount;
        stakeInfo.isVerified = stakeInfo.amount >= minimumStake;

        // Update total staked counter
        _totalStaked -= amount;

        // Transfer to merchant (minus fee)
        usdc.safeTransfer(recipient, payout);

        // Fee stays in vault (can be withdrawn by admin)

        emit Slashed(tokenId, amount, recipient);
    }

    // =============================================================================
    // External Functions - Views
    // =============================================================================

    /**
     * @notice Get stake information for an agent
     * @param tokenId The agent's token ID
     * @return info The stake information
     */
    function getStakeInfo(uint256 tokenId)
        external
        view
        override
        returns (StakeInfo memory info)
    {
        return _stakes[tokenId];
    }

    /**
     * @notice Get claim information
     * @param claimId The claim identifier
     * @return claim The claim information
     */
    function getClaim(bytes32 claimId)
        external
        view
        override
        returns (Claim memory claim)
    {
        claim = _claims[claimId];
        if (claim.claimId == bytes32(0)) {
            revert ClaimNotFound();
        }
        return claim;
    }

    /**
     * @notice Check if an agent is verified (has minimum stake)
     * @param tokenId The agent's token ID
     * @return verified Whether the agent is verified
     */
    function isVerified(uint256 tokenId)
        external
        view
        override
        returns (bool verified)
    {
        return _stakes[tokenId].isVerified;
    }

    /**
     * @notice Get all claims for an agent
     * @param tokenId The agent's token ID
     * @return claimIds Array of claim IDs
     */
    function getAgentClaims(uint256 tokenId)
        external
        view
        returns (bytes32[] memory claimIds)
    {
        return _agentClaims[tokenId];
    }

    // =============================================================================
    // External Functions - Admin
    // =============================================================================

    /**
     * @notice Update minimum stake requirement
     * @param newMinimumStake The new minimum stake amount
     */
    function setMinimumStake(uint256 newMinimumStake)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(newMinimumStake > 0, "InsuranceVault: invalid minimum stake");
        minimumStake = newMinimumStake;
    }

    /**
     * @notice Update claim fee
     * @param newClaimFeeBps The new claim fee in basis points
     */
    function setClaimFee(uint256 newClaimFeeBps)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(newClaimFeeBps <= 1000, "InsuranceVault: claim fee too high");
        claimFeeBps = newClaimFeeBps;
    }

    /**
     * @notice Withdraw accumulated fees (not staked amounts)
     * @param recipient The address to send fees to
     */
    function withdrawFees(address recipient)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        require(recipient != address(0), "InsuranceVault: zero address");
        
        uint256 balance = usdc.balanceOf(address(this));
        uint256 fees = balance - _totalStaked;  // Fees = total balance - staked amounts
        
        require(fees > 0, "InsuranceVault: no fees to withdraw");
        
        usdc.safeTransfer(recipient, fees);
        
        emit FeesWithdrawn(recipient, fees);
    }

    /**
     * @notice Pause the contract
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}

