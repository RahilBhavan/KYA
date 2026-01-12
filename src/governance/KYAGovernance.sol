// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {IKYAGovernance} from "./IKYAGovernance.sol";
import {KYAToken} from "./KYAToken.sol";

/**
 * @title KYAGovernance
 * @notice Governance system for KYA Protocol
 * @dev Implements proposal creation, voting, and execution with timelock
 *
 * Key Features:
 * - Proposal creation with minimum token balance
 * - On-chain voting with token weights
 * - Timelock for critical proposals
 * - Quorum and voting thresholds
 * - Emergency pause mechanism
 */
contract KYAGovernance is IKYAGovernance, AccessControl, ReentrancyGuard {
    // =============================================================================
    // Constants
    // =============================================================================

    /// @notice Minimum token balance to create proposal
    uint256 public constant MIN_PROPOSAL_BALANCE = 10_000 * 10**18; // 10,000 KYA

    /// @notice Voting period (blocks)
    uint256 public constant VOTING_PERIOD = 7 days / 12; // ~7 days at 12s block time

    /// @notice Quorum threshold (basis points, e.g., 5000 = 50%)
    uint256 public quorumThreshold; // Default: 5000 (50%)

    /// @notice Voting threshold (basis points, e.g., 5001 = 50.01% needed to pass)
    uint256 public votingThreshold; // Default: 5001 (50.01%)

    // =============================================================================
    // State Variables
    // =============================================================================

    /// @notice The KYA token contract
    KYAToken public immutable kyaToken;

    /// @notice The TimelockController contract
    TimelockController public immutable timelock;

    /// @notice Proposal counter
    uint256 private _proposalCounter;

    /// @notice Mapping from proposal ID to proposal
    mapping(uint256 => Proposal) private _proposals;

    /// @notice Mapping from proposal ID to voter address to whether they voted
    mapping(uint256 => mapping(address => bool)) private _hasVoted;

    /// @notice Mapping from proposal ID to whether it requires timelock
    mapping(uint256 => bool) private _requiresTimelock;

    // =============================================================================
    // Errors
    // =============================================================================

    error ProposalNotFound();
    error ProposalAlreadyExecuted();
    error ProposalAlreadyCanceled();
    error VotingNotStarted();
    error VotingEnded();
    error AlreadyVoted();
    error InsufficientBalance();
    error ProposalNotExecutable();
    error ExecutionFailed();

    // =============================================================================
    // Constructor
    // =============================================================================

    /**
     * @notice Initialize governance
     * @param kyaToken_ The KYA token contract address
     * @param timelock_ The TimelockController address
     * @param quorumThreshold_ Initial quorum threshold (basis points)
     * @param votingThreshold_ Initial voting threshold (basis points)
     */
    constructor(
        address kyaToken_,
        address timelock_,
        uint256 quorumThreshold_,
        uint256 votingThreshold_
    ) {
        require(kyaToken_ != address(0), "KYAGovernance: zero address");
        require(timelock_ != address(0), "KYAGovernance: zero address");
        require(quorumThreshold_ <= 10000, "KYAGovernance: invalid quorum");
        require(votingThreshold_ <= 10000, "KYAGovernance: invalid voting threshold");

        kyaToken = KYAToken(kyaToken_);
        timelock = TimelockController(payable(timelock_));
        quorumThreshold = quorumThreshold_;
        votingThreshold = votingThreshold_;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // =============================================================================
    // External Functions - Proposals
    // =============================================================================


    /**
     * @notice Create a proposal (overload without timelock flag, defaults to false)
     */
    function propose(
        address target,
        uint256 value,
        bytes calldata data,
        string calldata description
    ) external override returns (uint256 proposalId) {
        return _propose(target, value, data, description, false);
    }

    /**
     * @notice Internal function to create a proposal
     */
    function _propose(
        address target,
        uint256 value,
        bytes calldata data,
        string calldata description,
        bool requiresTimelock_
    ) internal returns (uint256 proposalId) {
        // Check proposer has minimum balance
        uint256 balance = kyaToken.balanceOf(msg.sender);
        if (balance < MIN_PROPOSAL_BALANCE) {
            revert InsufficientBalance();
        }

        proposalId = _proposalCounter++;
        
        _proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            target: target,
            value: value,
            data: data,
            description: description,
            votesFor: 0,
            votesAgainst: 0,
            startBlock: block.number,
            endBlock: block.number + VOTING_PERIOD,
            executed: false,
            canceled: false
        });

        _requiresTimelock[proposalId] = requiresTimelock_;

        emit ProposalCreated(proposalId, msg.sender, target, description);
        return proposalId;
    }

    /**
     * @notice Vote on a proposal
     * @param proposalId The proposal ID
     * @param support True for yes, false for no
     */
    function vote(uint256 proposalId, bool support) external override {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.id == 0) {
            revert ProposalNotFound();
        }
        if (proposal.executed) {
            revert ProposalAlreadyExecuted();
        }
        if (proposal.canceled) {
            revert ProposalAlreadyCanceled();
        }
        if (block.number < proposal.startBlock) {
            revert VotingNotStarted();
        }
        if (block.number > proposal.endBlock) {
            revert VotingEnded();
        }
        if (_hasVoted[proposalId][msg.sender]) {
            revert AlreadyVoted();
        }

        // Get voting power (token balance at proposal start block)
        uint256 votingPower = kyaToken.getPastVotes(msg.sender, proposal.startBlock);
        if (votingPower == 0) {
            revert InsufficientBalance();
        }

        _hasVoted[proposalId][msg.sender] = true;

        if (support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }

        emit VoteCast(proposalId, msg.sender, support, votingPower);
    }

    /**
     * @notice Execute a proposal
     * @param proposalId The proposal ID
     */
    function execute(uint256 proposalId) external override nonReentrant {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.id == 0) {
            revert ProposalNotFound();
        }
        if (proposal.executed) {
            revert ProposalAlreadyExecuted();
        }
        if (proposal.canceled) {
            revert ProposalAlreadyCanceled();
        }
        if (block.number <= proposal.endBlock) {
            revert VotingEnded(); // Voting still ongoing
        }

        // Check if proposal passed
        if (!canExecute(proposalId)) {
            revert ProposalNotExecutable();
        }

        proposal.executed = true;

        // Execute proposal
        if (_requiresTimelock[proposalId]) {
            // Schedule in timelock
            // Note: KYAGovernance must have PROPOSER_ROLE in timelock
            bytes32 salt = keccak256(abi.encodePacked(proposalId, block.timestamp));
            timelock.schedule(
                proposal.target,
                proposal.value,
                proposal.data,
                bytes32(0), // predecessor (none)
                salt,
                timelock.getMinDelay()
            );
            // Note: Actual execution happens after delay via timelock.execute
            // The proposal is marked as executed here, but the actual call happens later
        } else {
            // Execute directly
            (bool success,) = proposal.target.call{value: proposal.value}(proposal.data);
            if (!success) {
                revert ExecutionFailed();
            }
        }

        emit ProposalExecuted(proposalId);
    }

    /**
     * @notice Cancel a proposal
     * @param proposalId The proposal ID
     */
    function cancel(uint256 proposalId) external override {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.id == 0) {
            revert ProposalNotFound();
        }
        if (proposal.executed) {
            revert ProposalAlreadyExecuted();
        }
        if (proposal.canceled) {
            revert ProposalAlreadyCanceled();
        }

        // Only proposer or admin can cancel
        require(
            msg.sender == proposal.proposer || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "KYAGovernance: not authorized"
        );

        proposal.canceled = true;
        emit ProposalCanceled(proposalId);
    }

    // =============================================================================
    // External Functions - Views
    // =============================================================================

    /**
     * @notice Get proposal details
     * @param proposalId The proposal ID
     * @return proposal The proposal struct
     */
    function getProposal(uint256 proposalId)
        external
        view
        override
        returns (Proposal memory proposal)
    {
        proposal = _proposals[proposalId];
        if (proposal.id == 0) {
            revert ProposalNotFound();
        }
        return proposal;
    }

    /**
     * @notice Check if a proposal can be executed
     * @param proposalId The proposal ID
     * @return canExecute Whether the proposal can be executed
     */
    function canExecute(uint256 proposalId) public view override returns (bool canExecute) {
        Proposal memory proposal = _proposals[proposalId];
        if (proposal.id == 0 || proposal.executed || proposal.canceled) {
            return false;
        }
        if (block.number <= proposal.endBlock) {
            return false; // Voting still ongoing
        }

        // Check quorum
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 totalSupply = kyaToken.getPastTotalSupply(proposal.startBlock);
        uint256 quorum = (totalSupply * quorumThreshold) / 10000;
        if (totalVotes < quorum) {
            return false; // Quorum not met
        }

        // Check voting threshold
        uint256 threshold = (totalVotes * votingThreshold) / 10000;
        if (proposal.votesFor < threshold) {
            return false; // Not enough votes for
        }

        return true;
    }

    /**
     * @notice Check if an address has voted on a proposal
     * @param proposalId The proposal ID
     * @param voter The voter address
     * @return Whether the address has voted
     */
    function hasVoted(uint256 proposalId, address voter) external view returns (bool) {
        return _hasVoted[proposalId][voter];
    }

    // =============================================================================
    // External Functions - Admin
    // =============================================================================

    /**
     * @notice Set quorum threshold
     * @param newQuorumThreshold New quorum threshold (basis points)
     */
    function setQuorumThreshold(uint256 newQuorumThreshold)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(newQuorumThreshold <= 10000, "KYAGovernance: invalid quorum");
        quorumThreshold = newQuorumThreshold;
    }

    /**
     * @notice Set voting threshold
     * @param newVotingThreshold New voting threshold (basis points)
     */
    function setVotingThreshold(uint256 newVotingThreshold)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(newVotingThreshold <= 10000, "KYAGovernance: invalid voting threshold");
        votingThreshold = newVotingThreshold;
    }
}
