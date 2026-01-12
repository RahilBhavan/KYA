// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../BaseTest.sol";
import {ZKAdapter} from "../../src/integrations/ZKAdapter.sol";
import {OracleAdapter} from "../../src/integrations/OracleAdapter.sol";
import {IZKCoprocessor} from "../../src/integrations/IZKCoprocessor.sol";
import {IOracle} from "../../src/integrations/IOracle.sol";
import {TestConstants} from "../helpers/TestConstants.sol";
import {IReputationScore} from "../../src/interfaces/IReputationScore.sol";
import {IInsuranceVault} from "../../src/interfaces/IInsuranceVault.sol";
import {IAgentAccount} from "../../src/interfaces/IAgentAccount.sol";

/**
 * @title AdapterIntegrationTest
 * @notice Integration tests for ZKAdapter and OracleAdapter
 */
contract AdapterIntegrationTest is BaseTest {
    ZKAdapter public zkAdapter;
    OracleAdapter public oracleAdapter;
    uint256 public tokenId;
    address public tbaAddress;

    function setUp() public override {
        super.setUp();

        // Deploy adapters
        zkAdapter = new ZKAdapter(address(reputationScore), address(agentRegistry));
        oracleAdapter = new OracleAdapter(address(insuranceVault));

        // Grant admin roles to deployer for adapters
        vm.startPrank(address(this));
        zkAdapter.grantRole(zkAdapter.DEFAULT_ADMIN_ROLE(), deployer);
        oracleAdapter.grantRole(oracleAdapter.DEFAULT_ADMIN_ROLE(), deployer);
        vm.stopPrank();

        // Mint agent
        (, tokenId, tbaAddress) = mintDefaultAgent(user1);

        // Setup agent with stake
        fundTBA(tbaAddress, TestConstants.TEST_STAKE_AMOUNT);
        uint256 stakeAmount = TestConstants.MINIMUM_STAKE;

        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(mockUSDC),
            0,
            abi.encodeWithSignature("approve(address,uint256)", address(insuranceVault), stakeAmount)
        );

        vm.prank(user1);
        IAgentAccount(tbaAddress).execute(
            address(insuranceVault),
            0,
            abi.encodeWithSignature("stake(uint256,uint256)", tokenId, stakeAmount)
        );
    }

    // =============================================================================
    // ZKAdapter Tests
    // =============================================================================

    function test_zkAdapter_submitQuery() public {
        // Ensure we have valid block numbers (avoid underflow)
        uint256 startBlock = block.number > 1000 ? block.number - 1000 : 0;
        uint256 endBlock = block.number;

        IZKCoprocessor.ProofQuery memory query = IZKCoprocessor.ProofQuery({
            queryId: bytes32(0), // Will be set by adapter
            agentAddress: tbaAddress,
            proofType: TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            queryData: abi.encode("minVolume", 10000),
            startBlock: startBlock,
            endBlock: endBlock
        });

        bytes32 queryId = zkAdapter.submitQuery(query);

        assertNotEq(queryId, bytes32(0), "Query ID should be set");
        
        (uint8 status,) = zkAdapter.getProofStatus(queryId);
        assertEq(status, 0, "Status should be pending");
    }

    function test_zkAdapter_processProofAndUpdate() public {
        // Ensure we have valid block numbers (avoid underflow)
        uint256 startBlock = block.number > 1000 ? block.number - 1000 : 0;
        uint256 endBlock = block.number;

        // Submit query
        IZKCoprocessor.ProofQuery memory query = IZKCoprocessor.ProofQuery({
            queryId: bytes32(0),
            agentAddress: tbaAddress,
            proofType: TestConstants.PROOF_TYPE_UNISWAP_VOLUME,
            queryData: abi.encode("minVolume", 10000),
            startBlock: startBlock,
            endBlock: endBlock
        });

        bytes32 queryId = zkAdapter.submitQuery(query);

        // Grant ZK_PROVER_ROLE to adapter (for testing)
        vm.prank(deployer);
        reputationScore.grantRole(reputationScore.ZK_PROVER_ROLE(), address(zkAdapter));

        // Process proof (adapter needs admin role to call processProofAndUpdate)
        bytes memory proof = abi.encode("test-proof-data");
        vm.prank(deployer);
        zkAdapter.processProofAndUpdate(queryId, tokenId, proof, "Test metadata");

        // Verify status
        (uint8 status, ZKAdapter.ProofResult memory result) = zkAdapter.getProofStatus(queryId);
        assertEq(status, 1, "Status should be generated");
        assertTrue(result.verified, "Proof should be verified");

        // Verify reputation updated
        IReputationScore.ReputationData memory rep = reputationScore.getReputation(tokenId);
        assertGt(rep.score, 0, "Reputation should increase");
    }

    // =============================================================================
    // OracleAdapter Tests
    // =============================================================================

    function test_oracleAdapter_submitClaim() public {
        uint256 claimAmount = 500 * 10**6;

        // Submit claim to InsuranceVault
        vm.prank(merchant);
        bytes32 vaultClaimId = insuranceVault.submitClaim(
            tokenId,
            claimAmount,
            "Test claim"
        );

        // Submit to oracle adapter
        IOracle.ClaimData memory claimData = IOracle.ClaimData({
            claimId: vaultClaimId,
            tokenId: tokenId,
            merchant: merchant,
            amount: claimAmount,
            reason: "Test claim",
            evidence: abi.encode("evidence")
        });

        bytes32 requestId = oracleAdapter.submitClaim(claimData);

        assertNotEq(requestId, bytes32(0), "Request ID should be set");

        // Verify status
        (uint8 status, OracleAdapter.ResolutionResult memory result) = oracleAdapter.getClaimStatus(requestId);
        assertEq(status, 0, "Status should be pending");
    }

    function test_oracleAdapter_processResolution() public {
        uint256 claimAmount = 500 * 10**6;
        uint256 stakeBefore = insuranceVault.getStakeInfo(tokenId).amount;

        // Submit claim
        vm.prank(merchant);
        bytes32 vaultClaimId = insuranceVault.submitClaim(
            tokenId,
            claimAmount,
            "Test claim"
        );

        // Submit to oracle
        IOracle.ClaimData memory claimData = IOracle.ClaimData({
            claimId: vaultClaimId,
            tokenId: tokenId,
            merchant: merchant,
            amount: claimAmount,
            reason: "Test claim",
            evidence: abi.encode("evidence")
        });

        bytes32 requestId = oracleAdapter.submitClaim(claimData);

        // Grant ORACLE_ROLE to adapter (for testing)
        vm.prank(deployer);
        insuranceVault.grantRole(insuranceVault.ORACLE_ROLE(), address(oracleAdapter));

        // Process resolution (approved) - adapter needs admin role
        vm.prank(deployer);
        oracleAdapter.processResolution(requestId, true, abi.encode("resolution"));

        // Verify status
        (uint8 status, OracleAdapter.ResolutionResult memory result) = oracleAdapter.getClaimStatus(requestId);
        assertEq(status, 1, "Status should be resolved");
        assertTrue(result.approved, "Claim should be approved");

        // Verify slashing occurred
        IInsuranceVault.StakeInfo memory stakeAfter = insuranceVault.getStakeInfo(tokenId);
        assertLt(stakeAfter.amount, stakeBefore, "Stake should be reduced");
    }

    function test_oracleAdapter_getOracleRequestId() public {
        uint256 claimAmount = 500 * 10**6;

        // Submit claim
        vm.prank(merchant);
        bytes32 vaultClaimId = insuranceVault.submitClaim(
            tokenId,
            claimAmount,
            "Test claim"
        );

        // Submit to oracle
        IOracle.ClaimData memory claimData = IOracle.ClaimData({
            claimId: vaultClaimId,
            tokenId: tokenId,
            merchant: merchant,
            amount: claimAmount,
            reason: "Test claim",
            evidence: abi.encode("evidence")
        });

        bytes32 requestId = oracleAdapter.submitClaim(claimData);

        // Get oracle request ID from vault claim ID
        bytes32 retrievedRequestId = oracleAdapter.getOracleRequestId(vaultClaimId);
        assertEq(retrievedRequestId, requestId, "Request IDs should match");
    }
}

