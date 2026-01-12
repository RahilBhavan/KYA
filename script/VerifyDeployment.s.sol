// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {AgentLicense} from "../src/AgentLicense.sol";
import {IAgentLicense} from "../src/interfaces/IAgentLicense.sol";
import {IAgentRegistry} from "../src/interfaces/IAgentRegistry.sol";
import {IInsuranceVault} from "../src/interfaces/IInsuranceVault.sol";
import {IReputationScore} from "../src/interfaces/IReputationScore.sol";
import {IPaymaster} from "../src/interfaces/IPaymaster.sol";
import {IMerchantSDK} from "../src/interfaces/IMerchantSDK.sol";

/**
 * @title VerifyDeployment
 * @notice Verifies all contracts are deployed correctly and interactions work
 * 
 * Usage:
 * Set contract addresses in environment or pass as arguments
 * forge script script/VerifyDeployment.s.sol --rpc-url $RPC_URL
 */
contract VerifyDeployment is Script {
    function run() external {
        // Get contract addresses from environment
        address agentLicense = vm.envAddress("AGENT_LICENSE");
        address agentRegistry = vm.envAddress("AGENT_REGISTRY");
        address insuranceVault = vm.envAddress("INSURANCE_VAULT");
        address reputationScore = vm.envAddress("REPUTATION_SCORE");
        address paymaster = vm.envAddress("PAYMASTER");
        address merchantSDK = vm.envAddress("MERCHANT_SDK");

        console.log("===========================================");
        console.log("KYA Protocol Deployment Verification");
        console.log("===========================================");

        // Verify contracts exist
        console.log("\n[1/6] Verifying contract deployments...");
        _verifyContract(agentLicense, "AgentLicense");
        _verifyContract(agentRegistry, "AgentRegistry");
        _verifyContract(insuranceVault, "InsuranceVault");
        _verifyContract(reputationScore, "ReputationScore");
        _verifyContract(paymaster, "Paymaster");
        _verifyContract(merchantSDK, "MerchantSDK");

        // Verify role assignments
        console.log("\n[2/6] Verifying role assignments...");
        _verifyRoles(agentLicense, agentRegistry, reputationScore, insuranceVault);

        // Verify contract interactions
        console.log("\n[3/6] Verifying contract interactions...");
        _verifyInteractions(
            agentLicense, agentRegistry, insuranceVault, reputationScore, merchantSDK
        );

        // Verify configuration
        console.log("\n[4/6] Verifying configuration...");
        _verifyConfiguration(insuranceVault, reputationScore, paymaster);

        // Verify external contracts
        console.log("\n[5/6] Verifying external contracts...");
        _verifyExternalContracts(agentRegistry, insuranceVault, paymaster);

        // Test basic functionality
        console.log("\n[6/6] Testing basic functionality...");
        _testBasicFunctionality(agentRegistry, insuranceVault, reputationScore);

        console.log("\n===========================================");
        console.log("Verification Complete!");
        console.log("All checks passed.");
        console.log("===========================================");
    }

    function _verifyContract(address contractAddress, string memory name) internal view {
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(contractAddress)
        }
        require(codeSize > 0, string(abi.encodePacked(name, " not deployed")));
        console.log("  ", name, "verified at:", contractAddress);
    }

    function _verifyRoles(
        address agentLicense,
        address agentRegistry,
        address reputationScore,
        address insuranceVault
    ) internal view {
        // Check MINTER_ROLE
        AgentLicense license = AgentLicense(agentLicense);
        bytes32 MINTER_ROLE = license.MINTER_ROLE();
        require(
            license.hasRole(MINTER_ROLE, agentRegistry),
            "AgentRegistry should have MINTER_ROLE"
        );
        console.log("  MINTER_ROLE: OK");

        // Check ZK_PROVER_ROLE (should be granted manually)
        IReputationScore rep = IReputationScore(reputationScore);
        bytes32 ZK_PROVER_ROLE = rep.ZK_PROVER_ROLE();
        console.log("  ZK_PROVER_ROLE: Check manually (grant to Axiom/Brevis)");

        // Check ORACLE_ROLE (should be granted manually)
        IInsuranceVault vault = IInsuranceVault(insuranceVault);
        bytes32 ORACLE_ROLE = vault.ORACLE_ROLE();
        console.log("  ORACLE_ROLE: Check manually (grant to UMA/Kleros)");
    }

    function _verifyInteractions(
        address agentLicense,
        address agentRegistry,
        address insuranceVault,
        address reputationScore,
        address merchantSDK
    ) internal view {
        // Verify AgentRegistry references AgentLicense
        IAgentRegistry registry = IAgentRegistry(agentRegistry);
        require(
            address(registry.agentLicense()) == agentLicense,
            "AgentRegistry should reference AgentLicense"
        );
        console.log("  AgentRegistry -> AgentLicense: OK");

        // Verify InsuranceVault references
        IInsuranceVault vault = IInsuranceVault(insuranceVault);
        require(
            address(vault.agentLicense()) == agentLicense,
            "InsuranceVault should reference AgentLicense"
        );
        require(
            address(vault.agentRegistry()) == agentRegistry,
            "InsuranceVault should reference AgentRegistry"
        );
        console.log("  InsuranceVault references: OK");

        // Verify MerchantSDK references
        IMerchantSDK sdk = IMerchantSDK(merchantSDK);
        require(
            address(sdk.insuranceVault()) == insuranceVault,
            "MerchantSDK should reference InsuranceVault"
        );
        require(
            address(sdk.reputationScore()) == reputationScore,
            "MerchantSDK should reference ReputationScore"
        );
        console.log("  MerchantSDK references: OK");
    }

    function _verifyConfiguration(
        address insuranceVault,
        address reputationScore,
        address paymaster
    ) internal view {
        IInsuranceVault vault = IInsuranceVault(insuranceVault);
        uint256 minStake = vault.minimumStake();
        require(minStake > 0, "Minimum stake should be set");
        console.log("  Minimum stake:", minStake / 10**6, "USDC");

        IPaymaster pm = IPaymaster(paymaster);
        address entryPoint = pm.entryPoint();
        require(entryPoint != address(0), "EntryPoint should be set");
        console.log("  EntryPoint:", entryPoint);
    }

    function _verifyExternalContracts(
        address agentRegistry,
        address insuranceVault,
        address paymaster
    ) internal view {
        IAgentRegistry registry = IAgentRegistry(agentRegistry);
        address erc6551Registry = address(registry.erc6551Registry());
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(erc6551Registry)
        }
        require(codeSize > 0, "ERC6551Registry should exist");
        console.log("  ERC6551Registry: OK");

        IInsuranceVault vault = IInsuranceVault(insuranceVault);
        address usdc = address(vault.usdc());
        codeSize = 0;
        assembly {
            codeSize := extcodesize(usdc)
        }
        require(codeSize > 0, "USDC should exist");
        console.log("  USDC: OK");
    }

    function _testBasicFunctionality(
        address agentRegistry,
        address insuranceVault,
        address reputationScore
    ) internal view {
        // Test view functions
        IAgentRegistry registry = IAgentRegistry(agentRegistry);
        uint256 totalAgents = registry.totalAgents();
        console.log("  Total agents:", totalAgents);

        IInsuranceVault vault = IInsuranceVault(insuranceVault);
        uint256 minStake = vault.minimumStake();
        console.log("  Minimum stake:", minStake / 10**6, "USDC");

        IReputationScore rep = IReputationScore(reputationScore);
        uint8 tier = rep.getTier(100);
        require(tier >= 0 && tier <= 5, "Tier should be valid");
        console.log("  Tier calculation: OK");
    }
}

