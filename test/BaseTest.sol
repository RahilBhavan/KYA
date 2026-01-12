// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {AgentLicense} from "../src/AgentLicense.sol";
import {AgentRegistry} from "../src/AgentRegistry.sol";
import {SimpleAccountImplementation} from "../src/SimpleAccountImplementation.sol";
import {InsuranceVault} from "../src/InsuranceVault.sol";
import {ReputationScore} from "../src/ReputationScore.sol";
import {Paymaster} from "../src/Paymaster.sol";
import {MerchantSDK} from "../src/MerchantSDK.sol";
import {MockERC20} from "./helpers/MockERC20.sol";
import {MockEntryPoint} from "./helpers/MockEntryPoint.sol";
import {TestConstants} from "./helpers/TestConstants.sol";
import {TestUtils} from "./helpers/TestUtils.sol";
import {IERC6551Registry} from "../src/interfaces/IERC6551.sol";
import {ERC6551Registry} from "../lib/reference/src/ERC6551Registry.sol";

/**
 * @title BaseTest
 * @notice Abstract base test contract with common setup
 */
abstract contract BaseTest is TestUtils {

    // =============================================================================
    // Contracts
    // =============================================================================

    AgentLicense public agentLicense;
    AgentRegistry public agentRegistry;
    SimpleAccountImplementation public accountImpl;
    InsuranceVault public insuranceVault;
    ReputationScore public reputationScore;
    Paymaster public paymaster;
    MerchantSDK public merchantSDK;

    // =============================================================================
    // Mock Contracts
    // =============================================================================

    MockERC20 public mockUSDC;
    MockEntryPoint public mockEntryPoint;

    // =============================================================================
    // External Contracts
    // =============================================================================

    ERC6551Registry public erc6551Registry;

    // =============================================================================
    // Test Accounts
    // =============================================================================

    address public deployer;
    address public user1;
    address public user2;
    address public merchant;
    address public oracle;
    address public zkProver;
    address public admin;

    uint256 public deployerKey;
    uint256 public user1Key;
    uint256 public user2Key;

    // =============================================================================
    // Setup
    // =============================================================================

    function setUp() public virtual {
        // Create test accounts
        deployerKey = 0x1;
        user1Key = 0x2;
        user2Key = 0x3;

        deployer = vm.addr(deployerKey);
        user1 = vm.addr(user1Key);
        user2 = vm.addr(user2Key);
        merchant = TestConstants.MERCHANT;
        oracle = TestConstants.ORACLE;
        zkProver = TestConstants.ZK_PROVER;
        admin = TestConstants.ADMIN;

        // Fund test accounts
        vm.deal(deployer, 100 ether);
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(merchant, 100 ether);

        // Deploy mock contracts
        mockUSDC = new MockERC20("USD Coin", "USDC", 6);
        mockEntryPoint = new MockEntryPoint();
        erc6551Registry = new ERC6551Registry();

        // Deploy core contracts
        accountImpl = new SimpleAccountImplementation();
        agentLicense = new AgentLicense(
            "KYA Agent License", "KYA", "https://metadata.kya.protocol/agent/"
        );
        agentRegistry = new AgentRegistry(
            address(agentLicense),
            address(accountImpl),
            address(erc6551Registry),
            TestConstants.MINTING_FEE
        );

        // Grant MINTER_ROLE
        agentLicense.grantRole(agentLicense.MINTER_ROLE(), address(agentRegistry));

        // Deploy v2.0 contracts
        reputationScore = new ReputationScore(address(agentLicense));
        insuranceVault = new InsuranceVault(
            address(mockUSDC),
            address(agentLicense),
            address(agentRegistry),
            TestConstants.MINIMUM_STAKE,
            TestConstants.CLAIM_FEE_BPS
        );
        paymaster = new Paymaster(
            address(mockEntryPoint),
            address(agentLicense),
            address(agentRegistry)
        );
        merchantSDK = new MerchantSDK(
            address(insuranceVault),
            address(reputationScore),
            address(agentLicense),
            address(agentRegistry)
        );

        // Grant roles
        insuranceVault.grantRole(insuranceVault.ORACLE_ROLE(), oracle);
        reputationScore.grantRole(reputationScore.ZK_PROVER_ROLE(), zkProver);
        
        // Grant admin roles to deployer for testing
        // Note: Contracts grant DEFAULT_ADMIN_ROLE to msg.sender (this contract) in constructor
        // We grant it to deployer so tests can use vm.prank(deployer)
        vm.startPrank(address(this));
        reputationScore.grantRole(reputationScore.DEFAULT_ADMIN_ROLE(), deployer);
        insuranceVault.grantRole(insuranceVault.DEFAULT_ADMIN_ROLE(), deployer);
        paymaster.grantRole(paymaster.DEFAULT_ADMIN_ROLE(), deployer);
        agentLicense.grantRole(agentLicense.DEFAULT_ADMIN_ROLE(), deployer);
        vm.stopPrank();

        // Fund paymaster
        vm.deal(address(paymaster), 10 ether);
        paymaster.deposit{value: 10 ether}();
    }

    // =============================================================================
    // Helper Functions
    // =============================================================================

    /**
     * @notice Mint an agent and return info
     */
    function mintAgent(
        address to,
        string memory name,
        string memory description,
        string memory category
    ) internal returns (bytes32 agentId, uint256 tokenId, address tbaAddress) {
        vm.prank(to);
        (agentId, tokenId, tbaAddress) = agentRegistry.mintAgent{value: TestConstants.MINTING_FEE}(
            name,
            description,
            category
        );
    }

    /**
     * @notice Mint a default agent
     */
    function mintDefaultAgent(address to)
        internal
        returns (bytes32 agentId, uint256 tokenId, address tbaAddress)
    {
        return mintAgent(
            to,
            TestConstants.AGENT_NAME,
            TestConstants.AGENT_DESCRIPTION,
            TestConstants.AGENT_CATEGORY
        );
    }

    /**
     * @notice Fund TBA with USDC
     */
    function fundTBA(address tbaAddress, uint256 amount) internal {
        mockUSDC.mint(tbaAddress, amount);
    }

    /**
     * @notice Stake USDC for an agent (from TBA)
     */
    function stakeFromTBA(
        address tbaOwner,
        address tbaAddress,
        uint256 tokenId,
        uint256 amount
    ) internal {
        // Approve from TBA
        vm.prank(tbaOwner);
        (bool success,) = tbaAddress.call(
            abi.encodeWithSignature(
                "execute(address,uint256,bytes)",
                address(mockUSDC),
                0,
                abi.encodeWithSignature("approve(address,uint256)", address(insuranceVault), amount)
            )
        );
        require(success, "Approve failed");

        // Stake from TBA
        vm.prank(tbaOwner);
        (success,) = tbaAddress.call(
            abi.encodeWithSignature(
                "execute(address,uint256,bytes)",
                address(insuranceVault),
                0,
                abi.encodeWithSignature("stake(uint256,uint256)", tokenId, amount)
            )
        );
        require(success, "Stake failed");
    }

    /**
     * @notice Get agent info
     */
    function getAgentInfo(uint256 tokenId)
        internal
        view
        returns (AgentRegistry.AgentInfo memory)
    {
        return agentRegistry.getAgentInfoByTokenId(tokenId);
    }
}

