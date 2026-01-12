// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../../BaseTest.sol";
import {KYAToken} from "../../../src/governance/KYAToken.sol";
import {KYAGovernance} from "../../../src/governance/KYAGovernance.sol";
import {IKYAGovernance} from "../../../src/governance/IKYAGovernance.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

/**
 * @title KYAGovernanceTest
 * @notice Comprehensive tests for KYA Governance system
 */
contract KYAGovernanceTest is BaseTest {
    KYAToken public kyaToken;
    KYAGovernance public governance;
    TimelockController public timelock;

    address public proposer;
    address public executor;

    function setUp() public override {
        super.setUp();

        proposer = address(0x100);
        executor = address(0x200);

        // Deploy TimelockController
        address[] memory proposers = new address[](1);
        proposers[0] = proposer;
        address[] memory executors = new address[](1);
        executors[0] = executor;

        vm.prank(deployer);
        timelock = new TimelockController(1 days, proposers, executors, deployer);

        // Deploy KYA Token
        vm.prank(deployer);
        kyaToken = new KYAToken("KYA Token", "KYA");

        // Deploy Governance
        vm.prank(deployer);
        governance = new KYAGovernance(
            address(kyaToken),
            address(timelock),
            5000, // 50% quorum
            5001  // 50.01% voting threshold
        );

        // Grant governance PROPOSER_ROLE in timelock
        vm.prank(deployer);
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governance));

        // Grant governance EXECUTOR_ROLE in timelock
        vm.prank(deployer);
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(governance));

        // Grant MINTER_ROLE to deployer
        vm.prank(deployer);
        kyaToken.grantRole(kyaToken.MINTER_ROLE(), deployer);

        // Mint tokens to test users
        vm.prank(deployer);
        kyaToken.mint(user1, 100_000 * 10**18); // 100k KYA
        vm.prank(deployer);
        kyaToken.mint(user2, 50_000 * 10**18); // 50k KYA
    }

    // =============================================================================
    // Proposal Creation Tests
    // =============================================================================

    function test_propose_success() public {
        address target = address(insuranceVault);
        bytes memory data = abi.encodeWithSignature("pause()");
        string memory description = "Pause insurance vault";

        vm.prank(user1);
        uint256 proposalId = governance.propose(target, 0, data, description);

        assertGt(proposalId, 0, "Proposal ID should be set");
        
        IKYAGovernance.Proposal memory proposal = governance.getProposal(proposalId);
        assertEq(proposal.proposer, user1, "Proposer should be user1");
        assertEq(proposal.target, target, "Target should match");
    }

    function test_propose_insufficientBalance() public {
        address target = address(insuranceVault);
        bytes memory data = abi.encodeWithSignature("pause()");
        string memory description = "Test proposal";

        // User with insufficient balance (user2 has 50k, needs 10k minimum, but might not have enough for proposal)
        // Actually user2 has 50k which is > 10k, so this test needs adjustment
        // Let's create a user with very low balance
        address lowBalanceUser = address(0x999);
        vm.prank(deployer);
        kyaToken.mint(lowBalanceUser, 1000 * 10**18); // Only 1k KYA

        vm.prank(lowBalanceUser);
        vm.expectRevert(); // InsufficientBalance
        governance.propose(target, 0, data, description);
    }

    // =============================================================================
    // Voting Tests
    // =============================================================================

    function test_vote_success() public {
        // Create proposal
        address target = address(insuranceVault);
        bytes memory data = abi.encodeWithSignature("pause()");
        string memory description = "Pause insurance vault";

        vm.prank(user1);
        uint256 proposalId = governance.propose(target, 0, data, description);

        // Vote for
        vm.prank(user1);
        governance.vote(proposalId, true);

        IKYAGovernance.Proposal memory proposal = governance.getProposal(proposalId);
        assertGt(proposal.votesFor, 0, "Votes for should be > 0");
        assertTrue(governance.hasVoted(proposalId, user1), "User1 should have voted");
    }

    function test_vote_against() public {
        address target = address(insuranceVault);
        bytes memory data = abi.encodeWithSignature("pause()");
        string memory description = "Pause insurance vault";

        vm.prank(user1);
        uint256 proposalId = governance.propose(target, 0, data, description);

        // Vote against
        vm.prank(user2);
        governance.vote(proposalId, false);

        IKYAGovernance.Proposal memory proposal = governance.getProposal(proposalId);
        assertGt(proposal.votesAgainst, 0, "Votes against should be > 0");
    }

    function test_vote_alreadyVoted() public {
        address target = address(insuranceVault);
        bytes memory data = abi.encodeWithSignature("pause()");
        string memory description = "Test";

        vm.prank(user1);
        uint256 proposalId = governance.propose(target, 0, data, description);

        vm.prank(user1);
        governance.vote(proposalId, true);

        // Try to vote again
        vm.prank(user1);
        vm.expectRevert(); // AlreadyVoted error
        governance.vote(proposalId, false);
    }

    // =============================================================================
    // Execution Tests
    // =============================================================================

    function test_execute_success() public {
        // Create a simple proposal (set a value in a mock contract)
        address target = address(insuranceVault);
        bytes memory data = abi.encodeWithSignature("pause()");
        string memory description = "Pause insurance vault";

        vm.prank(user1);
        uint256 proposalId = governance.propose(target, 0, data, description);

        // Vote for (need majority)
        vm.prank(user1);
        governance.vote(proposalId, true);

        // Fast forward past voting period
        vm.roll(block.number + governance.VOTING_PERIOD() + 1);

        // Execute
        vm.prank(user1);
        governance.execute(proposalId);

        IKYAGovernance.Proposal memory proposal = governance.getProposal(proposalId);
        assertTrue(proposal.executed, "Proposal should be executed");
    }

    function test_execute_quorumNotMet() public {
        address target = address(insuranceVault);
        bytes memory data = abi.encodeWithSignature("pause()");
        string memory description = "Test";

        vm.prank(user1);
        uint256 proposalId = governance.propose(target, 0, data, description);

        // Don't vote (no quorum)

        vm.roll(block.number + governance.VOTING_PERIOD() + 1);

        vm.prank(user1);
        vm.expectRevert(); // ProposalNotExecutable
        governance.execute(proposalId);
    }

    // =============================================================================
    // Admin Functions Tests
    // =============================================================================

    function test_setQuorumThreshold() public {
        vm.prank(deployer);
        governance.setQuorumThreshold(6000); // 60%

        assertEq(governance.quorumThreshold(), 6000, "Quorum should be updated");
    }

    function test_setVotingThreshold() public {
        vm.prank(deployer);
        governance.setVotingThreshold(6001); // 60.01%

        assertEq(governance.votingThreshold(), 6001, "Voting threshold should be updated");
    }

    function test_setQuorumThreshold_onlyAdmin() public {
        vm.prank(user1);
        vm.expectRevert();
        governance.setQuorumThreshold(6000);
    }
}
