// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IInsurancePool
 * @notice Interface for Insurance Pool contracts
 */
interface IInsurancePool {
    /**
     * @notice Pool structure
     * @param poolId Pool ID
     * @param name Pool name
     * @param totalStaked Total amount staked in pool
     * @param totalCoverage Total coverage provided
     * @param premiumRate Premium rate (basis points)
     * @param riskLevel Risk level (0-100)
     * @param active Whether pool is active
     * @param createdAt Pool creation timestamp
     */
    struct Pool {
        uint256 poolId;
        string name;
        uint256 totalStaked;
        uint256 totalCoverage;
        uint256 premiumRate; // Basis points
        uint8 riskLevel; // 0-100
        bool active;
        uint256 createdAt;
    }

    /**
     * @notice Participant structure
     * @param tokenId Agent token ID
     * @param stakeAmount Amount staked
     * @param coverageAmount Coverage amount
     * @param joinedAt Join timestamp
     * @param premiumPaid Total premium paid
     */
    struct Participant {
        uint256 tokenId;
        uint256 stakeAmount;
        uint256 coverageAmount;
        uint256 joinedAt;
        uint256 premiumPaid;
    }

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
    ) external returns (uint256 poolId);

    /**
     * @notice Join an insurance pool
     * @param poolId The pool ID
     * @param tokenId The agent token ID
     * @param stakeAmount Amount to stake
     */
    function joinPool(uint256 poolId, uint256 tokenId, uint256 stakeAmount) external;

    /**
     * @notice Leave an insurance pool
     * @param poolId The pool ID
     * @param tokenId The agent token ID
     */
    function leavePool(uint256 poolId, uint256 tokenId) external;

    /**
     * @notice Get pool details
     * @param poolId The pool ID
     * @return pool The pool struct
     */
    function getPool(uint256 poolId) external view returns (Pool memory pool);

    /**
     * @notice Get participant details
     * @param poolId The pool ID
     * @param tokenId The agent token ID
     * @return participant The participant struct
     */
    function getParticipant(uint256 poolId, uint256 tokenId)
        external
        view
        returns (Participant memory participant);

    /**
     * @notice Emitted when a pool is created
     */
    event PoolCreated(
        uint256 indexed poolId,
        string name,
        uint256 premiumRate,
        uint8 riskLevel
    );

    /**
     * @notice Emitted when an agent joins a pool
     */
    event PoolJoined(
        uint256 indexed poolId,
        uint256 indexed tokenId,
        uint256 stakeAmount,
        uint256 premium
    );

    /**
     * @notice Emitted when an agent leaves a pool
     */
    event PoolLeft(uint256 indexed poolId, uint256 indexed tokenId, uint256 amountReturned);
}
