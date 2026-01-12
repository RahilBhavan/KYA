// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {ReputationScore} from "../src/ReputationScore.sol";
import {InsuranceVault} from "../src/InsuranceVault.sol";
import {Paymaster} from "../src/Paymaster.sol";
import {ZKAdapter} from "../src/integrations/ZKAdapter.sol";
import {OracleAdapter} from "../src/integrations/OracleAdapter.sol";

/**
 * @title PostDeploymentSetup
 * @notice Post-deployment configuration script
 * @dev Grants roles, funds paymaster, configures integrations
 * 
 * Usage:
 * Set contract addresses in environment variables
 * forge script script/PostDeploymentSetup.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast
 */
contract PostDeploymentSetup is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Get contract addresses
        address reputationScoreAddr = vm.envAddress("REPUTATION_SCORE");
        address insuranceVaultAddr = vm.envAddress("INSURANCE_VAULT");
        address paymasterAddr = vm.envAddress("PAYMASTER");
        address agentRegistryAddr = vm.envAddress("AGENT_REGISTRY");

        // Get integration addresses (optional)
        address axiomAddress = vm.envOr("AXIOM_ADDRESS", address(0));
        address brevisAddress = vm.envOr("BREVIS_ADDRESS", address(0));
        address umaAddress = vm.envOr("UMA_ADDRESS", address(0));
        address klerosAddress = vm.envOr("KLEROS_ADDRESS", address(0));

        console.log("===========================================");
        console.log("KYA Protocol - Post-Deployment Setup");
        console.log("===========================================");
        console.log("Deployer:", deployer);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        ReputationScore reputationScore = ReputationScore(reputationScoreAddr);
        InsuranceVault insuranceVault = InsuranceVault(insuranceVaultAddr);
        Paymaster paymaster = Paymaster(paymasterAddr);

        // Step 1: Deploy integration adapters
        console.log("[1/5] Deploying integration adapters...");
        ZKAdapter zkAdapter = new ZKAdapter(reputationScoreAddr, agentRegistryAddr);
        OracleAdapter oracleAdapter = new OracleAdapter(insuranceVaultAddr);
        console.log("  ZKAdapter:", address(zkAdapter));
        console.log("  OracleAdapter:", address(oracleAdapter));

        // Step 2: Grant ZK_PROVER_ROLE
        console.log("\n[2/5] Granting ZK_PROVER_ROLE...");
        bytes32 zkProverRole = reputationScore.ZK_PROVER_ROLE();
        
        if (axiomAddress != address(0)) {
            reputationScore.grantRole(zkProverRole, axiomAddress);
            console.log("  [OK] Granted to Axiom:", axiomAddress);
        } else {
            console.log("  [WARNING] AXIOM_ADDRESS not set - grant manually");
        }

        if (brevisAddress != address(0)) {
            reputationScore.grantRole(zkProverRole, brevisAddress);
            console.log("  [OK] Granted to Brevis:", brevisAddress);
        } else {
            console.log("  [WARNING] BREVIS_ADDRESS not set - grant manually");
        }

        // Step 3: Grant ORACLE_ROLE
        console.log("\n[3/5] Granting ORACLE_ROLE...");
        bytes32 oracleRole = insuranceVault.ORACLE_ROLE();
        
        if (umaAddress != address(0)) {
            insuranceVault.grantRole(oracleRole, umaAddress);
            console.log("  [OK] Granted to UMA:", umaAddress);
        } else {
            console.log("  [WARNING] UMA_ADDRESS not set - grant manually");
        }

        if (klerosAddress != address(0)) {
            insuranceVault.grantRole(oracleRole, klerosAddress);
            console.log("  [OK] Granted to Kleros:", klerosAddress);
        } else {
            console.log("  [WARNING] KLEROS_ADDRESS not set - grant manually");
        }

        // Step 4: Fund Paymaster
        console.log("\n[4/5] Funding Paymaster...");
        uint256 paymasterFunding = vm.envOr("PAYMASTER_FUNDING", uint256(1 ether));
        if (paymasterFunding > 0) {
            paymaster.deposit{value: paymasterFunding}();
            console.log("  [OK] Funded with:", paymasterFunding / 1e18, "ETH");
        } else {
            console.log("  [WARNING] PAYMASTER_FUNDING not set - fund manually");
        }

        // Step 5: Verify setup
        console.log("\n[5/5] Verifying setup...");
        uint256 paymasterDeposit = paymaster.getDeposited();
        console.log("  Paymaster deposit:", paymasterDeposit / 1e18, "ETH");
        console.log("  [OK] Setup complete");

        vm.stopBroadcast();

        console.log("\n===========================================");
        console.log("Post-Deployment Setup Complete!");
        console.log("===========================================");
        console.log("\nDeployed Contracts:");
        console.log("- ZKAdapter:", address(zkAdapter));
        console.log("- OracleAdapter:", address(oracleAdapter));
        console.log("\nNext Steps:");
        console.log("1. Verify contracts on BaseScan");
        console.log("2. Test end-to-end flows");
        console.log("3. Monitor contract activity");
        console.log("===========================================");
    }
}

