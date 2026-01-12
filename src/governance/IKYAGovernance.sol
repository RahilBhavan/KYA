// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IKYAGovernance
 * @notice Interface for KYA Protocol governance
 */
interface IKYAGovernance {
    /**
     * @notice Proposal structure
     * @param id Proposal ID
     * @param proposer Address that created the proposal
     * @param target Target contract address
     * @param value ETH value to send
     * @param data Calldata for the proposal
     * @param description Proposal description
     * @param votesFor Votes in favor
     * @param votesAgainst Votes against
     * @param startBlock Block when voting starts
     * @param endBlock Block when voting ends
     * @param executed Whether proposal has been executed
     * @param canceled Whether proposal has been canceled
     */
    struct Proposal {
        uint256 id;
        address proposer;
        address target;
        uint256 value;
        bytes data;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 startBlock;
        uint256 endBlock;
        bool executed;
        bool canceled;
    }

    /**
     * @notice Create a new proposal
     * @param target Target contract address
     * @param value ETH value to send
     * @param data Calldata for the proposal
     * @param description Proposal description
     * @return proposalId The proposal ID
     */
    function propose(
        address target,
        uint256 value,
        bytes calldata data,
        string calldata description
    ) external returns (uint256 proposalId);

    /**
     * @notice Vote on a proposal
     * @param proposalId The proposal ID
     * @param support True for yes, false for no
     */
    function vote(uint256 proposalId, bool support) external;

    /**
     * @notice Execute a proposal
     * @param proposalId The proposal ID
     */
    function execute(uint256 proposalId) external;

    /**
     * @notice Cancel a proposal (only proposer or admin)
     * @param proposalId The proposal ID
     */
    function cancel(uint256 proposalId) external;

    /**
     * @notice Get proposal details
     * @param proposalId The proposal ID
     * @return proposal The proposal struct
     */
    function getProposal(uint256 proposalId) external view returns (Proposal memory proposal);

    /**
     * @notice Check if a proposal can be executed
     * @param proposalId The proposal ID
     * @return canExecute Whether the proposal can be executed
     */
    function canExecute(uint256 proposalId) external view returns (bool canExecute);

    /**
     * @notice Emitted when a proposal is created
     */
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        address target,
        string description
    );

    /**
     * @notice Emitted when a vote is cast
     */
    event VoteCast(
        uint256 indexed proposalId,
        address indexed voter,
        bool support,
        uint256 weight
    );

    /**
     * @notice Emitted when a proposal is executed
     */
    event ProposalExecuted(uint256 indexed proposalId);

    /**
     * @notice Emitted when a proposal is canceled
     */
    event ProposalCanceled(uint256 indexed proposalId);

    /**
     * @notice Check if an address has voted on a proposal
     * @param proposalId The proposal ID
     * @param voter The voter address
     * @return Whether the address has voted
     */
    function hasVoted(uint256 proposalId, address voter) external view returns (bool);
}
