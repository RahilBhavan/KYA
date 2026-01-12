// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {InsuranceVault} from "../src/InsuranceVault.sol";
import {ReputationScore} from "../src/ReputationScore.sol";
import {Paymaster} from "../src/Paymaster.sol";

/**
 * @title SetupTimelock
 * @notice Deploys TimelockController and configures it for critical admin functions
 * @dev Run with: forge script script/SetupTimelock.s.sol --rpc-url $RPC_URL --broadcast
 * 
 * This script:
 * 1. Deploys TimelockController
 * 2. Sets multi-sig as proposer and executor
 * 3. Configures delay period (default: 24 hours)
 * 
 * After deployment, contracts need to be updated to use timelock for critical functions.
 */
contract SetupTimelock is Script {
    // =============================================================================
    // Constants
    // =============================================================================

    /// @notice Minimum delay for timelock (24 hours)
    uint256 public constant MIN_DELAY = 24 hours;

    /// @notice Maximum delay for timelock (7 days)
    uint256 public constant MAX_DELAY = 7 days;

    // =============================================================================
    // State Variables
    // =============================================================================

    /// @notice Multi-sig wallet address
    address public multisigAddress;

    /// @notice Timelock delay in seconds
    uint256 public timelockDelay;

    // =============================================================================
    // Setup
    // =============================================================================

    function setUp() public {
        multisigAddress = vm.envAddress("MULTISIG_ADDRESS");
        require(multisigAddress != address(0), "MULTISIG_ADDRESS not set");

        // Get delay from environment or use default
        timelockDelay = vm.envOr("TIMELOCK_DELAY", uint256(MIN_DELAY));
        require(timelockDelay >= MIN_DELAY, "Delay too short");
        require(timelockDelay <= MAX_DELAY, "Delay too long");
    }

    // =============================================================================
    // Main Execution
    // =============================================================================

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("========================================");
        console.log("TimelockController Deployment");
        console.log("========================================");
        console.log("Deployer:", deployer);
        console.log("Multi-sig:", multisigAddress);
        console.log("Delay:", timelockDelay, "seconds");
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Prepare proposers and executors arrays
        address[] memory proposers = new address[](1);
        proposers[0] = multisigAddress;

        address[] memory executors = new address[](1);
        executors[0] = multisigAddress;

        // Deploy TimelockController
        console.log("Deploying TimelockController...");
        TimelockController timelock = new TimelockController(
            timelockDelay,
            proposers,
            executors,
            address(0) // No admin (multi-sig controls everything)
        );

        console.log("  ✓ TimelockController deployed at:", address(timelock));
        console.log("");

        // Verify configuration
        console.log("Verifying configuration...");
        require(timelock.getMinDelay() == timelockDelay, "Delay mismatch");
        require(timelock.hasRole(timelock.PROPOSER_ROLE(), multisigAddress), "Proposer role not set");
        require(timelock.hasRole(timelock.EXECUTOR_ROLE(), multisigAddress), "Executor role not set");
        console.log("  ✓ Configuration verified");
        console.log("");

        vm.stopBroadcast();

        console.log("========================================");
        console.log("Next Steps");
        console.log("========================================");
        console.log("1. Save TimelockController address:", address(timelock));
        console.log("2. Update contracts to use timelock for critical functions");
        console.log("3. Test timelock operations on testnet");
        console.log("4. Transfer admin roles to timelock (via multi-sig)");
        console.log("");
        console.log("Timelock Address:", address(timelock));
    }
}
