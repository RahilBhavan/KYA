// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {ZKAdapter} from "../src/integrations/ZKAdapter.sol";
import {OracleAdapter} from "../src/integrations/OracleAdapter.sol";
import {ReputationScore} from "../src/ReputationScore.sol";
import {InsuranceVault} from "../src/InsuranceVault.sol";

/**
 * @title SetupIntegrations
 * @notice Script to set up external integrations after deployment
 * @dev Grants roles and configures adapters for Axiom/Brevis and UMA/Kleros
 */
contract SetupIntegrations is Script {
    function run() external {
        // Get deployed contract addresses from environment or deployment
        address reputationScoreAddress = vm.envAddress("REPUTATION_SCORE_ADDRESS");
        address insuranceVaultAddress = vm.envAddress("INSURANCE_VAULT_ADDRESS");
        address agentRegistryAddress = vm.envAddress("AGENT_REGISTRY_ADDRESS");

        // Get oracle addresses from environment
        address axiomAddress = vm.envOr("AXIOM_ADDRESS", address(0));
        address brevisAddress = vm.envOr("BREVIS_ADDRESS", address(0));
        address umaAddress = vm.envOr("UMA_ADDRESS", address(0));
        address klerosAddress = vm.envOr("KLEROS_ADDRESS", address(0));

        // Deploy adapters
        vm.startBroadcast();

        // Deploy ZK Adapter
        ZKAdapter zkAdapter = new ZKAdapter(reputationScoreAddress, agentRegistryAddress);
        console.log("ZKAdapter deployed at:", address(zkAdapter));

        // Deploy Oracle Adapter
        OracleAdapter oracleAdapter = new OracleAdapter(insuranceVaultAddress);
        console.log("OracleAdapter deployed at:", address(oracleAdapter));

        // Grant ZK_PROVER_ROLE to Axiom/Brevis
        ReputationScore reputationScore = ReputationScore(reputationScoreAddress);
        bytes32 zkProverRole = reputationScore.ZK_PROVER_ROLE();

        if (axiomAddress != address(0)) {
            reputationScore.grantRole(zkProverRole, axiomAddress);
            console.log("Granted ZK_PROVER_ROLE to Axiom:", axiomAddress);
        }

        if (brevisAddress != address(0)) {
            reputationScore.grantRole(zkProverRole, brevisAddress);
            console.log("Granted ZK_PROVER_ROLE to Brevis:", brevisAddress);
        }

        // Grant ORACLE_ROLE to UMA/Kleros
        InsuranceVault insuranceVault = InsuranceVault(insuranceVaultAddress);
        bytes32 oracleRole = insuranceVault.ORACLE_ROLE();

        if (umaAddress != address(0)) {
            insuranceVault.grantRole(oracleRole, umaAddress);
            console.log("Granted ORACLE_ROLE to UMA:", umaAddress);
        }

        if (klerosAddress != address(0)) {
            insuranceVault.grantRole(oracleRole, klerosAddress);
            console.log("Granted ORACLE_ROLE to Kleros:", klerosAddress);
        }

        vm.stopBroadcast();

        console.log("\n=== Integration Setup Complete ===");
        console.log("ZKAdapter:", address(zkAdapter));
        console.log("OracleAdapter:", address(oracleAdapter));
    }
}

