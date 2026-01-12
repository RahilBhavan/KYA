// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IAgentLicense} from "./IAgentLicense.sol";
import {IAgentRegistry} from "./IAgentRegistry.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IInsuranceVault
 * @notice Interface for the Insurance Vault contract
 * @dev Handles staking, slashing, and claims for agent verification
 */
interface IInsuranceVault {
    /// @notice Role identifier for oracles
    function ORACLE_ROLE() external view returns (bytes32);

    /// @notice Get the AgentLicense contract
    function agentLicense() external view returns (IAgentLicense);

    /// @notice Get the AgentRegistry contract
    function agentRegistry() external view returns (IAgentRegistry);

    /// @notice Get the USDC token contract
    function usdc() external view returns (IERC20);
    /**
     * @notice Staking information for an agent
     * @param amount The amount of USDC staked
     * @param stakedAt Timestamp when staking occurred
     * @param tbaAddress The Token Bound Account address (cached for gas optimization)
     * @param isVerified Whether the agent has achieved verified status
     */
    struct StakeInfo {
        uint256 amount;
        uint256 stakedAt;
        address tbaAddress;
        bool isVerified;
    }

    /**
     * @notice Claim information for a slashing request
     * @param claimId Unique identifier for the claim
     * @param tokenId The agent's token ID
     * @param merchant The address making the claim
     * @param amount The amount being claimed
     * @param reason The reason for the claim
     * @param submittedAt Timestamp when claim was submitted
     * @param status Claim status (0=Pending, 1=Approved, 2=Rejected, 3=Challenged)
     * @param challengeDeadline Deadline for challenging the claim
     */
    struct Claim {
        bytes32 claimId;
        uint256 tokenId;
        address merchant;
        uint256 amount;
        string reason;
        uint256 submittedAt;
        uint8 status; // 0=Pending, 1=Approved, 2=Rejected, 3=Challenged
        uint256 challengeDeadline;
    }

    /**
     * @notice Emitted when an agent stakes USDC
     * @param tokenId The agent's token ID
     * @param amount The amount staked
     * @param tbaAddress The Token Bound Account address
     */
    event Staked(uint256 indexed tokenId, uint256 amount, address indexed tbaAddress);

    /**
     * @notice Emitted when an agent unstakes USDC
     * @param tokenId The agent's token ID
     * @param amount The amount unstaked
     */
    event Unstaked(uint256 indexed tokenId, uint256 amount);

    /**
     * @notice Emitted when a claim is submitted
     * @param claimId The unique claim identifier
     * @param tokenId The agent's token ID
     * @param merchant The merchant making the claim
     * @param amount The amount being claimed
     */
    event ClaimSubmitted(
        bytes32 indexed claimId, uint256 indexed tokenId, address indexed merchant, uint256 amount
    );

    /**
     * @notice Emitted when a claim is resolved
     * @param claimId The unique claim identifier
     * @param status The final status (1=Approved, 2=Rejected)
     * @param amount The amount slashed (if approved)
     */
    event ClaimResolved(bytes32 indexed claimId, uint8 status, uint256 amount);

    /**
     * @notice Emitted when an agent is slashed
     * @param tokenId The agent's token ID
     * @param amount The amount slashed
     * @param recipient The address receiving the slashed funds
     */
    event Slashed(uint256 indexed tokenId, uint256 amount, address indexed recipient);

    /**
     * @notice Emitted when fees are withdrawn
     * @param recipient The address receiving the fees
     * @param amount The amount of fees withdrawn
     */
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    /**
     * @notice Stake USDC to achieve verified status
     * @param tokenId The agent's token ID
     * @param amount The amount of USDC to stake (must be >= minimumStake)
     */
    function stake(uint256 tokenId, uint256 amount) external;

    /**
     * @notice Request to unstake (starts cooldown period for verified agents)
     * @param tokenId The agent's token ID
     */
    function requestUnstake(uint256 tokenId) external;

    /**
     * @notice Unstake USDC (only if agent is not verified or after cooldown)
     * @param tokenId The agent's token ID
     * @param amount The amount to unstake
     */
    function unstake(uint256 tokenId, uint256 amount) external;

    /**
     * @notice Submit a claim for slashing
     * @param tokenId The agent's token ID
     * @param amount The amount to claim
     * @param reason The reason for the claim
     * @return claimId The unique claim identifier
     */
    function submitClaim(uint256 tokenId, uint256 amount, string calldata reason)
        external
        returns (bytes32 claimId);

    /**
     * @notice Resolve a claim (called by oracle or admin)
     * @param claimId The claim identifier
     * @param approved Whether the claim is approved
     */
    function resolveClaim(bytes32 claimId, bool approved) external;

    /**
     * @notice Challenge a claim (agent can challenge within challenge period)
     * @param claimId The claim identifier
     */
    function challengeClaim(bytes32 claimId) external;

    /**
     * @notice Get stake information for an agent
     * @param tokenId The agent's token ID
     * @return info The stake information
     */
    function getStakeInfo(uint256 tokenId) external view returns (StakeInfo memory info);

    /**
     * @notice Get claim information
     * @param claimId The claim identifier
     * @return claim The claim information
     */
    function getClaim(bytes32 claimId) external view returns (Claim memory claim);

    /**
     * @notice Check if an agent is verified (has minimum stake)
     * @param tokenId The agent's token ID
     * @return verified Whether the agent is verified
     */
    function isVerified(uint256 tokenId) external view returns (bool verified);

    /**
     * @notice Get the minimum stake required for verification
     * @return amount The minimum stake amount in USDC
     */
    function minimumStake() external view returns (uint256 amount);
}

