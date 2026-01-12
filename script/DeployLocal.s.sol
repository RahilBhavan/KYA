// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {AgentLicense} from "../src/AgentLicense.sol";
import {AgentRegistry} from "../src/AgentRegistry.sol";
import {SimpleAccountImplementation} from "../src/SimpleAccountImplementation.sol";
import {InsuranceVault} from "../src/InsuranceVault.sol";
import {ReputationScore} from "../src/ReputationScore.sol";
import {Paymaster} from "../src/Paymaster.sol";
import {MerchantSDK} from "../src/MerchantSDK.sol";
import {MockERC20} from "../test/helpers/MockERC20.sol";
import {MockEntryPoint} from "../test/helpers/MockEntryPoint.sol";

/**
 * @title DeployLocal
 * @notice Local deployment script for KYA Protocol
 * @dev Deploys all contracts to a local Anvil node with mock dependencies
 * 
 * Usage:
 * 1. Start Anvil: anvil
 * 2. Run: forge script script/DeployLocal.s.sol --rpc-url http://localhost:8545 --broadcast
 */
contract DeployLocal is Script {
    // =============================================================================
    // Constants
    // =============================================================================

    /// @notice Canonical ERC-6551 Registry (deployed on most chains)
    /// For local, we'll deploy a mock if needed
    address constant ERC6551_REGISTRY = 0x000000006551c19487814612e58FE06813775758;

    /// @notice Default minting fee (0.001 ETH)
    uint256 constant INITIAL_MINTING_FEE = 0.001 ether;

    /// @notice Minimum stake for verification (1000 USDC, 6 decimals)
    uint256 constant MINIMUM_STAKE = 1000 * 10**6;

    /// @notice Claim fee in basis points (100 = 1%)
    uint256 constant CLAIM_FEE_BPS = 100;

    /// @notice NFT collection name
    string constant NFT_NAME = "KYA Agent License";

    /// @notice NFT collection symbol
    string constant NFT_SYMBOL = "KYA";

    /// @notice Base URI for metadata
    string constant BASE_URI = "https://metadata.kya.protocol/agent/";

    // =============================================================================
    // Deployment
    // =============================================================================

    function run() external {
        // Get deployer (use default Anvil account)
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("===========================================");
        console.log("KYA Protocol Local Deployment");
        console.log("===========================================");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("===========================================");

        vm.startBroadcast(deployerPrivateKey);

        // =============================================================================
        // Step 0: Deploy Mock Dependencies
        // =============================================================================

        console.log("\n[0/9] Deploying mock dependencies...");
        
        // Deploy Mock USDC
        MockERC20 mockUSDC = new MockERC20("USD Coin", "USDC", 6);
        console.log("MockUSDC deployed at:", address(mockUSDC));
        console.log("MockUSDC balance:", mockUSDC.balanceOf(deployer) / 10**6, "USDC");

        // Deploy Mock EntryPoint
        MockEntryPoint mockEntryPoint = new MockEntryPoint();
        console.log("MockEntryPoint deployed at:", address(mockEntryPoint));

        // Check if ERC6551Registry exists, if not we'll skip it for now
        // (In production, this is deployed at a canonical address)
        address erc6551Registry = ERC6551_REGISTRY;
        uint256 registryCodeSize;
        assembly {
            registryCodeSize := extcodesize(erc6551Registry)
        }
        
        if (registryCodeSize == 0) {
            console.log("WARNING: ERC6551Registry not found at canonical address");
            console.log("You may need to deploy it separately or use a fork");
            // For local testing, we'll continue anyway
        } else {
            console.log("ERC6551Registry found at:", erc6551Registry);
        }

        // =============================================================================
        // Step 1: Deploy SimpleAccountImplementation
        // =============================================================================

        console.log("\n[1/9] Deploying SimpleAccountImplementation...");
        SimpleAccountImplementation accountImpl = new SimpleAccountImplementation();
        console.log("SimpleAccountImplementation deployed at:", address(accountImpl));

        // =============================================================================
        // Step 2: Deploy AgentLicense NFT
        // =============================================================================

        console.log("\n[2/9] Deploying AgentLicense NFT...");
        AgentLicense agentLicense = new AgentLicense(NFT_NAME, NFT_SYMBOL, BASE_URI);
        console.log("AgentLicense deployed at:", address(agentLicense));

        // =============================================================================
        // Step 3: Deploy AgentRegistry
        // =============================================================================

        console.log("\n[3/9] Deploying AgentRegistry...");
        AgentRegistry agentRegistry = new AgentRegistry(
            address(agentLicense), address(accountImpl), erc6551Registry, INITIAL_MINTING_FEE
        );
        console.log("AgentRegistry deployed at:", address(agentRegistry));

        // =============================================================================
        // Step 4: Grant MINTER_ROLE to AgentRegistry
        // =============================================================================

        console.log("\n[4/9] Granting MINTER_ROLE to AgentRegistry...");
        bytes32 MINTER_ROLE = agentLicense.MINTER_ROLE();
        agentLicense.grantRole(MINTER_ROLE, address(agentRegistry));
        console.log("MINTER_ROLE granted successfully");

        // =============================================================================
        // Step 5: Deploy ReputationScore
        // =============================================================================

        console.log("\n[5/9] Deploying ReputationScore...");
        ReputationScore reputationScore = new ReputationScore(address(agentLicense));
        console.log("ReputationScore deployed at:", address(reputationScore));

        // =============================================================================
        // Step 6: Deploy InsuranceVault
        // =============================================================================

        console.log("\n[6/9] Deploying InsuranceVault...");
        InsuranceVault insuranceVault = new InsuranceVault(
            address(mockUSDC),
            address(agentLicense),
            address(agentRegistry),
            MINIMUM_STAKE,
            CLAIM_FEE_BPS
        );
        console.log("InsuranceVault deployed at:", address(insuranceVault));

        // =============================================================================
        // Step 7: Deploy Paymaster
        // =============================================================================

        console.log("\n[7/9] Deploying Paymaster...");
        Paymaster paymaster = new Paymaster(
            address(mockEntryPoint),
            address(agentLicense),
            address(agentRegistry)
        );
        console.log("Paymaster deployed at:", address(paymaster));

        // =============================================================================
        // Step 8: Deploy MerchantSDK
        // =============================================================================

        console.log("\n[8/9] Deploying MerchantSDK...");
        MerchantSDK merchantSDK = new MerchantSDK(
            address(insuranceVault),
            address(reputationScore),
            address(agentLicense),
            address(agentRegistry)
        );
        console.log("MerchantSDK deployed at:", address(merchantSDK));

        // =============================================================================
        // Step 9: Setup (Optional - grant roles, fund paymaster, etc.)
        // =============================================================================

        console.log("\n[9/9] Setup...");
        
        // Fund paymaster with some ETH
        uint256 paymasterFunds = 1 ether;
        payable(address(paymaster)).transfer(paymasterFunds);
        console.log("Paymaster funded with:", paymasterFunds / 1e18, "ETH");

        vm.stopBroadcast();

        // =============================================================================
        // Deployment Summary
        // =============================================================================

        console.log("\n===========================================");
        console.log("Local Deployment Complete!");
        console.log("===========================================");
        console.log("Core Contracts:");
        console.log("- SimpleAccountImplementation:", address(accountImpl));
        console.log("- AgentLicense:", address(agentLicense));
        console.log("- AgentRegistry:", address(agentRegistry));
        console.log("\nV2.0 Contracts:");
        console.log("- ReputationScore:", address(reputationScore));
        console.log("- InsuranceVault:", address(insuranceVault));
        console.log("- Paymaster:", address(paymaster));
        console.log("- MerchantSDK:", address(merchantSDK));
        console.log("\nMock Dependencies:");
        console.log("- MockUSDC:", address(mockUSDC));
        console.log("- MockEntryPoint:", address(mockEntryPoint));
        console.log("- ERC6551Registry:", erc6551Registry);
        console.log("===========================================");
        console.log("\nQuick Test Commands:");
        console.log("1. Mint an agent:");
        string memory cmd1 = string.concat("   cast send ", vm.toString(address(agentRegistry)), 
                   " mintAgent(string,string,string) \"TestAgent\" \"Test Description\" \"Trading\" --value 0.001ether --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY");
        console.log(cmd1);
        console.log("\n2. Check agent info:");
        string memory cmd2 = string.concat("   cast call ", vm.toString(address(agentRegistry)), 
                   " getAgentInfoByTokenId(uint256) 1 --rpc-url http://localhost:8545");
        console.log(cmd2);
        console.log("\n3. Approve USDC for staking:");
        string memory cmd3 = string.concat("   cast send ", vm.toString(address(mockUSDC)), 
                   " approve(address,uint256) ", vm.toString(address(insuranceVault)), 
                   " ", vm.toString(MINIMUM_STAKE), " --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY");
        console.log(cmd3);
        console.log("===========================================");

        // Save deployment addresses to file
        _saveDeploymentInfo(
            address(accountImpl),
            address(agentLicense),
            address(agentRegistry),
            address(reputationScore),
            address(insuranceVault),
            address(paymaster),
            address(merchantSDK),
            address(mockUSDC),
            address(mockEntryPoint),
            erc6551Registry
        );
    }

    // =============================================================================
    // Helper Functions
    // =============================================================================

    function _saveDeploymentInfo(
        address accountImpl,
        address agentLicense,
        address agentRegistry,
        address reputationScore,
        address insuranceVault,
        address paymaster,
        address merchantSDK,
        address usdc,
        address entryPoint,
        address erc6551Registry
    ) internal {
        string memory deploymentInfo = string(
            abi.encodePacked(
                "# KYA Protocol Local Deployment\n\n",
                "Network: local (Anvil)\n",
                "Chain ID: ",
                vm.toString(block.chainid),
                "\n",
                "Deployment Date: ",
                vm.toString(block.timestamp),
                "\n\n",
                "## Core Contracts\n\n",
                "- SimpleAccountImplementation: `",
                vm.toString(accountImpl),
                "`\n",
                "- AgentLicense: `",
                vm.toString(agentLicense),
                "`\n",
                "- AgentRegistry: `",
                vm.toString(agentRegistry),
                "`\n\n",
                "## V2.0 Contracts\n\n",
                "- ReputationScore: `",
                vm.toString(reputationScore),
                "`\n",
                "- InsuranceVault: `",
                vm.toString(insuranceVault),
                "`\n",
                "- Paymaster: `",
                vm.toString(paymaster),
                "`\n",
                "- MerchantSDK: `",
                vm.toString(merchantSDK),
                "`\n\n",
                "## Mock Dependencies\n\n",
                "- MockUSDC: `",
                vm.toString(usdc),
                "`\n",
                "- MockEntryPoint: `",
                vm.toString(entryPoint),
                "`\n",
                "- ERC6551Registry: `",
                vm.toString(erc6551Registry),
                "`\n\n",
                "## Environment Variables\n\n",
                "Add these to your .env file:\n\n",
                "```bash\n",
                "export AGENT_REGISTRY=", vm.toString(agentRegistry), "\n",
                "export AGENT_LICENSE=", vm.toString(agentLicense), "\n",
                "export INSURANCE_VAULT=", vm.toString(insuranceVault), "\n",
                "export REPUTATION_SCORE=", vm.toString(reputationScore), "\n",
                "export PAYMASTER=", vm.toString(paymaster), "\n",
                "export MERCHANT_SDK=", vm.toString(merchantSDK), "\n",
                "export MOCK_USDC=", vm.toString(usdc), "\n",
                "export MOCK_ENTRY_POINT=", vm.toString(entryPoint), "\n",
                "```\n"
            )
        );

        string memory filename = string(
            abi.encodePacked(
                "deployments/local-", vm.toString(block.timestamp), ".md"
            )
        );

        vm.writeFile(filename, deploymentInfo);
        console.log("\nDeployment info saved to:", filename);
    }
}

