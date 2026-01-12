// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {ReputationScoreV2} from "../src/ReputationScoreV2.sol";
import {KYAToken} from "../src/governance/KYAToken.sol";
import {KYAGovernance} from "../src/governance/KYAGovernance.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {AgentMarketplace} from "../src/marketplace/AgentMarketplace.sol";
import {ReputationPricing} from "../src/marketplace/ReputationPricing.sol";
import {InsurancePool} from "../src/insurance/InsurancePool.sol";
import {RiskCalculator} from "../src/insurance/RiskCalculator.sol";
import {CrossChainReputation} from "../src/crosschain/CrossChainReputation.sol";
import {LayerZeroAdapter} from "../src/crosschain/LayerZeroAdapter.sol";

/**
 * @title DeployExpansionFeatures
 * @notice Deploy all expansion features
 */
contract DeployExpansionFeatures is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address multisigAddress = vm.envAddress("MULTISIG_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying Expansion Features...");
        console.log("");

        // Get existing contract addresses
        address agentLicense = vm.envAddress("AGENT_LICENSE_ADDRESS");
        address agentRegistry = vm.envAddress("AGENT_REGISTRY_ADDRESS");
        address reputationScore = vm.envAddress("REPUTATION_SCORE_ADDRESS");
        address insuranceVault = vm.envAddress("INSURANCE_VAULT_ADDRESS");
        address usdc = vm.envAddress("USDC_ADDRESS");

        // Phase 1: ReputationScoreV2
        console.log("Phase 1: Deploying ReputationScoreV2...");
        ReputationScoreV2 repV2 = new ReputationScoreV2(reputationScore, agentLicense);
        console.log("  ReputationScoreV2:", address(repV2));
        console.log("");

        // Phase 2: Governance
        console.log("Phase 2: Deploying Governance...");
        KYAToken kyaToken = new KYAToken("KYA Token", "KYA");
        console.log("  KYAToken:", address(kyaToken));

        // Create proposers array with governance (will be set after deployment)
        address[] memory proposers = new address[](1);
        proposers[0] = address(0); // Placeholder, will be updated
        
        // Create executors array with multi-sig
        address[] memory executors = new address[](1);
        executors[0] = multisigAddress;
        
        TimelockController timelock = new TimelockController(
            1 days,
            proposers,
            executors,
            msg.sender // Admin (will transfer to multi-sig later)
        );
        console.log("  TimelockController:", address(timelock));

        KYAGovernance governance = new KYAGovernance(
            address(kyaToken),
            address(timelock),
            5000, // 50% quorum
            5001  // 50.01% threshold
        );
        console.log("  KYAGovernance:", address(governance));
        console.log("");

        // Phase 2: Marketplace
        console.log("Phase 2: Deploying Marketplace...");
        AgentMarketplace marketplace = new AgentMarketplace(
            agentLicense,
            reputationScore,
            insuranceVault,
            multisigAddress // Fee recipient
        );
        console.log("  AgentMarketplace:", address(marketplace));
        console.log("  ReputationPricing:", address(marketplace.reputationPricing()));
        console.log("");

        // Phase 2: Insurance Pools
        console.log("Phase 2: Deploying Insurance Pools...");
        RiskCalculator riskCalculator = new RiskCalculator(
            reputationScore,
            insuranceVault
        );
        console.log("  RiskCalculator:", address(riskCalculator));

        InsurancePool insurancePool = new InsurancePool(
            usdc,
            agentLicense,
            insuranceVault,
            address(riskCalculator)
        );
        console.log("  InsurancePool:", address(insurancePool));
        console.log("");

        // Phase 3: Cross-Chain
        console.log("Phase 3: Deploying Cross-Chain...");
        address lzEndpoint = vm.envAddress("LAYERZERO_ENDPOINT"); // Or use Chainlink CCIP
        LayerZeroAdapter messageRelayer = new LayerZeroAdapter(lzEndpoint);
        console.log("  LayerZeroAdapter:", address(messageRelayer));

        CrossChainReputation crossChain = new CrossChainReputation(
            reputationScore,
            agentLicense,
            address(messageRelayer)
        );
        console.log("  CrossChainReputation:", address(crossChain));
        console.log("");

        // Setup roles and permissions
        console.log("Setting up roles and permissions...");
        
        // Grant governance MINTER_ROLE (for token distribution)
        kyaToken.grantRole(kyaToken.MINTER_ROLE(), address(governance));
        console.log("  [OK] Governance granted MINTER_ROLE");
        
        // Transfer admin roles to multi-sig
        kyaToken.grantRole(kyaToken.DEFAULT_ADMIN_ROLE(), multisigAddress);
        kyaToken.revokeRole(kyaToken.DEFAULT_ADMIN_ROLE(), msg.sender);
        
        governance.grantRole(governance.DEFAULT_ADMIN_ROLE(), multisigAddress);
        governance.revokeRole(governance.DEFAULT_ADMIN_ROLE(), msg.sender);
        
        marketplace.grantRole(marketplace.DEFAULT_ADMIN_ROLE(), multisigAddress);
        marketplace.revokeRole(marketplace.DEFAULT_ADMIN_ROLE(), msg.sender);
        
        insurancePool.grantRole(insurancePool.DEFAULT_ADMIN_ROLE(), multisigAddress);
        insurancePool.revokeRole(insurancePool.DEFAULT_ADMIN_ROLE(), msg.sender);
        
        crossChain.grantRole(crossChain.DEFAULT_ADMIN_ROLE(), multisigAddress);
        crossChain.revokeRole(crossChain.DEFAULT_ADMIN_ROLE(), msg.sender);
        
        // Transfer timelock admin to multi-sig (last, as it controls governance)
        timelock.grantRole(timelock.DEFAULT_ADMIN_ROLE(), multisigAddress);
        timelock.revokeRole(timelock.DEFAULT_ADMIN_ROLE(), msg.sender);
        
        console.log("  [OK] All admin roles transferred to multi-sig");
        console.log("");

        // Summary
        console.log("=== Deployment Summary ===");
        console.log("ReputationScoreV2:", address(repV2));
        console.log("KYAToken:", address(kyaToken));
        console.log("TimelockController:", address(timelock));
        console.log("KYAGovernance:", address(governance));
        console.log("AgentMarketplace:", address(marketplace));
        console.log("RiskCalculator:", address(riskCalculator));
        console.log("InsurancePool:", address(insurancePool));
        console.log("LayerZeroAdapter:", address(messageRelayer));
        console.log("CrossChainReputation:", address(crossChain));
        console.log("");
        console.log("[SUCCESS] All expansion features deployed!");

        vm.stopBroadcast();
    }
}
