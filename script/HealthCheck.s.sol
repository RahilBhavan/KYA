// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {AgentRegistry} from "../src/AgentRegistry.sol";
import {InsuranceVault} from "../src/InsuranceVault.sol";
import {ReputationScore} from "../src/ReputationScore.sol";
import {Paymaster} from "../src/Paymaster.sol";
import {MerchantSDK} from "../src/MerchantSDK.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title HealthCheck
 * @notice Health check script for deployed contracts
 * @dev Monitors contract health and reports status
 * 
 * Usage:
 * forge script script/HealthCheck.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL
 */
contract HealthCheck is Script {
    function run() external view {
        // Get contract addresses
        address agentRegistryAddr = vm.envAddress("AGENT_REGISTRY");
        address insuranceVaultAddr = vm.envAddress("INSURANCE_VAULT");
        address reputationScoreAddr = vm.envAddress("REPUTATION_SCORE");
        address paymasterAddr = vm.envAddress("PAYMASTER");
        address merchantSDKAddr = vm.envAddress("MERCHANT_SDK");

        console.log("===========================================");
        console.log("KYA Protocol - Health Check");
        console.log("===========================================");
        console.log("Timestamp:", block.timestamp);
        console.log("Block:", block.number);
        console.log("");

        // Check contract deployments
        console.log("[1/6] Contract Deployment Status");
        _checkContract(agentRegistryAddr, "AgentRegistry");
        _checkContract(insuranceVaultAddr, "InsuranceVault");
        _checkContract(reputationScoreAddr, "ReputationScore");
        _checkContract(paymasterAddr, "Paymaster");
        _checkContract(merchantSDKAddr, "MerchantSDK");

        // Check contract state
        console.log("\n[2/6] Contract State");
        AgentRegistry agentRegistry = AgentRegistry(agentRegistryAddr);
        uint256 totalAgents = agentRegistry.totalAgents();
        console.log("  Total agents:", totalAgents);

        InsuranceVault insuranceVault = InsuranceVault(insuranceVaultAddr);
        uint256 minStake = insuranceVault.minimumStake();
        console.log("  Minimum stake:", minStake / 10**6, "USDC");
        bool isPaused = insuranceVault.paused();
        console.log("  Paused:", isPaused ? "Yes [WARNING]" : "No [OK]");

        Paymaster paymaster = Paymaster(paymasterAddr);
        uint256 paymasterDeposit = paymaster.getDeposited();
        console.log("  Paymaster deposit:", paymasterDeposit / 1e18, "ETH");

        // Check roles
        console.log("\n[3/6] Role Assignments");
        ReputationScore rep = ReputationScore(reputationScoreAddr);
        bytes32 zkProverRole = rep.ZK_PROVER_ROLE();
        // Note: Would need to check specific addresses
        console.log("  ZK_PROVER_ROLE: Check manually");

        bytes32 oracleRole = insuranceVault.ORACLE_ROLE();
        console.log("  ORACLE_ROLE: Check manually");

        // Check external contracts
        console.log("\n[4/6] External Contracts");
        address usdc = address(insuranceVault.usdc());
        uint256 usdcCodeSize;
        assembly {
            usdcCodeSize := extcodesize(usdc)
        }
        console.log("  USDC:", usdcCodeSize > 0 ? "OK [OK]" : "Missing [ERROR]");

        address entryPoint = paymaster.entryPoint();
        uint256 entryPointCodeSize;
        assembly {
            entryPointCodeSize := extcodesize(entryPoint)
        }
        console.log("  EntryPoint:", entryPointCodeSize > 0 ? "OK [OK]" : "Missing [ERROR]");

        // Check balances
        console.log("\n[5/6] Contract Balances");
        uint256 vaultBalance = IERC20(usdc).balanceOf(insuranceVaultAddr);
        console.log("  InsuranceVault USDC:", vaultBalance / 10**6, "USDC");
        
        uint256 paymasterEthBalance = paymasterAddr.balance;
        console.log("  Paymaster ETH:", paymasterEthBalance / 1e18, "ETH");

        // Check recent activity
        console.log("\n[6/6] Recent Activity");
        console.log("  Total agents:", totalAgents);
        console.log("  Vault balance:", vaultBalance / 10**6, "USDC");
        console.log("  Paymaster deposit:", paymasterDeposit / 1e18, "ETH");

        console.log("\n===========================================");
        console.log("Health Check Complete");
        console.log("===========================================");
    }

    function _checkContract(address contractAddr, string memory name) internal view {
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(contractAddr)
        }
        if (codeSize > 0) {
            console.log("  ", name, ": Deployed [OK]");
        } else {
            console.log("  ", name, ": Not deployed [ERROR]");
        }
    }
}

