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

/**
 * @title DeployBaseSepolia
 * @notice Deployment script for KYA Protocol on Base Sepolia testnet
 * @dev Includes testnet-specific configuration and verification
 * 
 * Usage:
 * forge script script/DeployBaseSepolia.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast --verify
 */
contract DeployBaseSepolia is Script {
    // =============================================================================
    // Constants - Base Sepolia Testnet
    // =============================================================================

    address constant ERC6551_REGISTRY = 0x000000006551c19487814612e58FE06813775758;
    address constant USDC_BASE_SEPOLIA = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
    address constant ENTRY_POINT_BASE_SEPOLIA = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;

    uint256 constant INITIAL_MINTING_FEE = 0.001 ether;
    uint256 constant MINIMUM_STAKE = 1000 * 10**6; // 1000 USDC (6 decimals)
    uint256 constant CLAIM_FEE_BPS = 100; // 1%

    string constant NFT_NAME = "KYA Agent License";
    string constant NFT_SYMBOL = "KYA";
    string constant BASE_URI = "https://metadata.kya.protocol/agent/";

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("===========================================");
        console.log("KYA Protocol - Base Sepolia Deployment");
        console.log("===========================================");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("Network: Base Sepolia Testnet");
        console.log("===========================================");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy core contracts
        console.log("\n[1/8] Deploying SimpleAccountImplementation...");
        SimpleAccountImplementation accountImpl = new SimpleAccountImplementation();
        console.log("SimpleAccountImplementation:", address(accountImpl));

        console.log("\n[2/8] Deploying AgentLicense...");
        AgentLicense agentLicense = new AgentLicense(NFT_NAME, NFT_SYMBOL, BASE_URI);
        console.log("AgentLicense:", address(agentLicense));

        console.log("\n[3/8] Deploying AgentRegistry...");
        AgentRegistry agentRegistry = new AgentRegistry(
            address(agentLicense),
            address(accountImpl),
            ERC6551_REGISTRY,
            INITIAL_MINTING_FEE
        );
        console.log("AgentRegistry:", address(agentRegistry));

        console.log("\n[4/8] Granting MINTER_ROLE...");
        agentLicense.grantRole(agentLicense.MINTER_ROLE(), address(agentRegistry));
        console.log("MINTER_ROLE granted");

        console.log("\n[5/8] Deploying ReputationScore...");
        ReputationScore reputationScore = new ReputationScore(address(agentLicense));
        console.log("ReputationScore:", address(reputationScore));

        console.log("\n[6/8] Deploying InsuranceVault...");
        InsuranceVault insuranceVault = new InsuranceVault(
            USDC_BASE_SEPOLIA,
            address(agentLicense),
            address(agentRegistry),
            MINIMUM_STAKE,
            CLAIM_FEE_BPS
        );
        console.log("InsuranceVault:", address(insuranceVault));

        console.log("\n[7/8] Deploying Paymaster...");
        Paymaster paymaster = new Paymaster(
            ENTRY_POINT_BASE_SEPOLIA,
            address(agentLicense),
            address(agentRegistry)
        );
        console.log("Paymaster:", address(paymaster));

        console.log("\n[8/8] Deploying MerchantSDK...");
        MerchantSDK merchantSDK = new MerchantSDK(
            address(insuranceVault),
            address(reputationScore),
            address(agentLicense),
            address(agentRegistry)
        );
        console.log("MerchantSDK:", address(merchantSDK));

        vm.stopBroadcast();

        // Deployment summary
        console.log("\n===========================================");
        console.log("Deployment Complete!");
        console.log("===========================================");
        console.log("Contract Addresses:");
        console.log("- SimpleAccountImplementation:", address(accountImpl));
        console.log("- AgentLicense:", address(agentLicense));
        console.log("- AgentRegistry:", address(agentRegistry));
        console.log("- ReputationScore:", address(reputationScore));
        console.log("- InsuranceVault:", address(insuranceVault));
        console.log("- Paymaster:", address(paymaster));
        console.log("- MerchantSDK:", address(merchantSDK));
        console.log("\nExternal Contracts:");
        console.log("- ERC6551Registry:", ERC6551_REGISTRY);
        console.log("- USDC:", USDC_BASE_SEPOLIA);
        console.log("- EntryPoint:", ENTRY_POINT_BASE_SEPOLIA);
        console.log("===========================================");
        console.log("\nNext Steps:");
        console.log("1. Verify contracts: forge verify-contract ...");
        console.log("2. Grant ZK_PROVER_ROLE to Axiom/Brevis");
        console.log("3. Grant ORACLE_ROLE to UMA/Kleros");
        console.log("4. Fund Paymaster");
        console.log("5. Run verification script");
        console.log("===========================================");

        // Save deployment info
        _saveDeploymentInfo(
            address(accountImpl),
            address(agentLicense),
            address(agentRegistry),
            address(reputationScore),
            address(insuranceVault),
            address(paymaster),
            address(merchantSDK)
        );
    }

    function _saveDeploymentInfo(
        address accountImpl,
        address agentLicense,
        address agentRegistry,
        address reputationScore,
        address insuranceVault,
        address paymaster,
        address merchantSDK
    ) internal {
        string memory info = string(
            abi.encodePacked(
                "# KYA Protocol - Base Sepolia Deployment\n\n",
                "Deployment Date: ",
                vm.toString(block.timestamp),
                "\nChain ID: ",
                vm.toString(block.chainid),
                "\n\n## Contracts\n\n",
                "- SimpleAccountImplementation: `",
                vm.toString(accountImpl),
                "`\n",
                "- AgentLicense: `",
                vm.toString(agentLicense),
                "`\n",
                "- AgentRegistry: `",
                vm.toString(agentRegistry),
                "`\n",
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
                "`\n"
            )
        );

        string memory filename = string(
            abi.encodePacked("deployments/base-sepolia-", vm.toString(block.timestamp), ".md")
        );

        vm.writeFile(filename, info);
        console.log("\nDeployment info saved to:", filename);
    }
}

