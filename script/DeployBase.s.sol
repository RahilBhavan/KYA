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
 * @title DeployBase
 * @notice Deployment script for KYA Protocol on Base network
 * @dev Run with: forge script script/DeployBase.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast --verify
 */
contract DeployBase is Script {
    // =============================================================================
    // Constants
    // =============================================================================

    /// @notice Canonical ERC-6551 Registry (same address on all chains)
    address constant ERC6551_REGISTRY = 0x000000006551c19487814612e58FE06813775758;

    /// @notice Default minting fee (0.001 ETH)
    uint256 constant INITIAL_MINTING_FEE = 0.001 ether;

    /// @notice USDC address on Base (to be set via env or use testnet address)
    /// Base Mainnet: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
    /// Base Sepolia: 0x036CbD53842c5426634e7929541eC2318f3dCF7e

    /// @notice ERC-4337 EntryPoint address (to be set via env)
    /// Base Mainnet: 0x0000000071727De22E5E9d8BAf0edAc6f37da032
    /// Base Sepolia: 0x0000000071727De22E5E9d8BAf0edAc6f37da032

    /// @notice Minimum stake for verification (1000 USDC, 6 decimals)
    uint256 constant MINIMUM_STAKE = 1000 * 10**6;

    /// @notice Claim fee in basis points (100 = 1%)
    uint256 constant CLAIM_FEE_BPS = 100;

    /// @notice NFT collection name
    string constant NFT_NAME = "KYA Agent License";

    /// @notice NFT collection symbol
    string constant NFT_SYMBOL = "KYA";

    /// @notice Base URI for metadata (to be updated with actual IPFS/server)
    string constant BASE_URI = "https://metadata.kya.protocol/agent/";

    // =============================================================================
    // Deployment
    // =============================================================================

    function run() external {
        // Get deployer private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Get fee receiver from environment (defaults to deployer if not set)
        address feeReceiver = vm.envOr("FEE_RECEIVER", deployer);

        console.log("===========================================");
        console.log("KYA Protocol Deployment");
        console.log("===========================================");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("Fee Receiver:", feeReceiver);
        console.log("===========================================");

        // Verify ERC6551Registry exists
        uint256 registryCodeSize;
        assembly {
            registryCodeSize := extcodesize(ERC6551_REGISTRY)
        }
        require(
            registryCodeSize > 0, "ERC6551Registry not deployed on this network"
        );
        console.log("ERC6551Registry verified at:", ERC6551_REGISTRY);

        vm.startBroadcast(deployerPrivateKey);

        // =============================================================================
        // Step 1: Deploy SimpleAccountImplementation
        // =============================================================================

        console.log("\n[1/3] Deploying SimpleAccountImplementation...");
        SimpleAccountImplementation accountImpl = new SimpleAccountImplementation();
        console.log("SimpleAccountImplementation deployed at:", address(accountImpl));

        // =============================================================================
        // Step 2: Deploy AgentLicense NFT
        // =============================================================================

        console.log("\n[2/3] Deploying AgentLicense NFT...");
        AgentLicense agentLicense = new AgentLicense(NFT_NAME, NFT_SYMBOL, BASE_URI);
        console.log("AgentLicense deployed at:", address(agentLicense));

        // =============================================================================
        // Step 3: Deploy AgentRegistry
        // =============================================================================

        console.log("\n[3/3] Deploying AgentRegistry...");
        AgentRegistry agentRegistry = new AgentRegistry(
            address(agentLicense), address(accountImpl), ERC6551_REGISTRY, INITIAL_MINTING_FEE
        );
        console.log("AgentRegistry deployed at:", address(agentRegistry));

        // =============================================================================
        // Step 4: Grant MINTER_ROLE to AgentRegistry
        // =============================================================================

        console.log("\n[4/8] Granting MINTER_ROLE to AgentRegistry...");
        bytes32 MINTER_ROLE = agentLicense.MINTER_ROLE();
        agentLicense.grantRole(MINTER_ROLE, address(agentRegistry));
        console.log("MINTER_ROLE granted successfully");

        // =============================================================================
        // Step 5: Deploy ReputationScore
        // =============================================================================

        console.log("\n[5/8] Deploying ReputationScore...");
        ReputationScore reputationScore = new ReputationScore(address(agentLicense));
        console.log("ReputationScore deployed at:", address(reputationScore));

        // =============================================================================
        // Step 6: Deploy InsuranceVault
        // =============================================================================

        console.log("\n[6/8] Deploying InsuranceVault...");
        address usdcAddress = vm.envOr("USDC_ADDRESS", address(0));
        require(usdcAddress != address(0), "USDC_ADDRESS not set in environment");
        
        InsuranceVault insuranceVault = new InsuranceVault(
            usdcAddress,
            address(agentLicense),
            address(agentRegistry),
            MINIMUM_STAKE,
            CLAIM_FEE_BPS
        );
        console.log("InsuranceVault deployed at:", address(insuranceVault));

        // =============================================================================
        // Step 7: Deploy Paymaster
        // =============================================================================

        console.log("\n[7/8] Deploying Paymaster...");
        address entryPoint = vm.envOr("ENTRY_POINT_ADDRESS", address(0));
        require(entryPoint != address(0), "ENTRY_POINT_ADDRESS not set in environment");
        
        Paymaster paymaster = new Paymaster(
            entryPoint,
            address(agentLicense),
            address(agentRegistry)
        );
        console.log("Paymaster deployed at:", address(paymaster));

        // =============================================================================
        // Step 8: Deploy MerchantSDK
        // =============================================================================

        console.log("\n[8/8] Deploying MerchantSDK...");
        MerchantSDK merchantSDK = new MerchantSDK(
            address(insuranceVault),
            address(reputationScore),
            address(agentLicense),
            address(agentRegistry)
        );
        console.log("MerchantSDK deployed at:", address(merchantSDK));

        vm.stopBroadcast();

        // =============================================================================
        // Deployment Summary
        // =============================================================================

        console.log("\n===========================================");
        console.log("Deployment Complete!");
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
        console.log("\nExternal Contracts:");
        console.log("- ERC6551Registry:", ERC6551_REGISTRY);
        console.log("- USDC:", usdcAddress);
        console.log("- EntryPoint:", entryPoint);
        console.log("===========================================");
        console.log("\nNext Steps:");
        console.log("1. Grant ZK_PROVER_ROLE to Axiom/Brevis on ReputationScore");
        console.log("2. Grant ORACLE_ROLE to UMA/Kleros on InsuranceVault");
        console.log("3. Deposit funds to Paymaster for gas sponsorship");
        console.log("4. Configure whitelisted contracts in ReputationScore");
        console.log("5. Verify contracts on BaseScan");
        console.log("6. Run deployment verification script");
        console.log("7. Test minting and staking flow");
        console.log("===========================================");

        // Post-deployment setup
        _postDeploymentSetup(
            address(reputationScore),
            address(insuranceVault),
            address(paymaster),
            deployer
        );

        // Save deployment addresses to file
        _saveDeploymentInfo(
            address(accountImpl),
            address(agentLicense),
            address(agentRegistry),
            address(reputationScore),
            address(insuranceVault),
            address(paymaster),
            address(merchantSDK),
            usdcAddress,
            entryPoint
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
        address entryPoint
    ) internal {
        string memory deploymentInfo = string(
            abi.encodePacked(
                "# KYA Protocol Deployment (v2.0)\n\n",
                "Network: ",
                _getNetworkName(),
                "\n",
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
                "## External Contracts\n\n",
                "- ERC6551Registry: `",
                vm.toString(ERC6551_REGISTRY),
                "`\n",
                "- USDC: `",
                vm.toString(usdc),
                "`\n",
                "- EntryPoint: `",
                vm.toString(entryPoint),
                "`\n\n",
                "## Configuration\n\n",
                "- NFT Name: ",
                NFT_NAME,
                "\n",
                "- NFT Symbol: ",
                NFT_SYMBOL,
                "\n",
                "- Initial Minting Fee: ",
                vm.toString(INITIAL_MINTING_FEE),
                " wei\n",
                "- Minimum Stake: ",
                vm.toString(MINIMUM_STAKE),
                " (USDC, 6 decimals)\n",
                "- Claim Fee: ",
                vm.toString(CLAIM_FEE_BPS),
                " basis points (",
                vm.toString(CLAIM_FEE_BPS / 100),
                "%)\n",
                "- Base URI: ",
                BASE_URI,
                "\n\n",
                "## Setup Instructions\n\n",
                "1. Grant ZK_PROVER_ROLE to Axiom/Brevis:\n",
                "   ```\n",
                "   reputationScore.grantRole(ZK_PROVER_ROLE, <axiom_address>)\n",
                "   ```\n\n",
                "2. Grant ORACLE_ROLE to UMA/Kleros:\n",
                "   ```\n",
                "   insuranceVault.grantRole(ORACLE_ROLE, <uma_address>)\n",
                "   ```\n\n",
                "3. Deposit funds to Paymaster:\n",
                "   ```\n",
                "   paymaster.deposit{value: <amount>}()\n",
                "   ```\n"
            )
        );

        string memory filename = string(
            abi.encodePacked(
                "deployments/", _getNetworkName(), "-", vm.toString(block.timestamp), ".md"
            )
        );

        vm.writeFile(filename, deploymentInfo);
        console.log("\nDeployment info saved to:", filename);
    }

    function _getNetworkName() internal view returns (string memory) {
        uint256 chainId = block.chainid;
        if (chainId == 8453) return "base";
        if (chainId == 84532) return "base-sepolia";
        if (chainId == 1) return "ethereum";
        if (chainId == 11155111) return "sepolia";
        return vm.toString(chainId);
    }

    /**
     * @notice Post-deployment setup (role grants, funding, etc.)
     */
    function _postDeploymentSetup(
        address reputationScore_,
        address insuranceVault_,
        address paymaster_,
        address deployer_
    ) internal {
        // Note: Role grants and funding should be done manually or via separate script
        // This function is a placeholder for future automation

        // Example: Fund paymaster (if deployer has ETH)
        if (address(paymaster_).balance == 0 && deployer_.balance > 0.1 ether) {
            // Would fund paymaster here if needed
        }
    }
}
