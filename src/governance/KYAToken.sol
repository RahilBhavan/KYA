// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title KYAToken
 * @notice Governance token for KYA Protocol
 * @dev ERC-20 token with voting capabilities (ERC20Votes) and permit functionality
 *
 * Key Features:
 * - ERC-20 token for governance
 * - Voting power (ERC20Votes)
 * - Gasless approvals (ERC20Permit)
 * - Minting controlled by MINTER_ROLE
 * - Snapshot support for off-chain voting
 */
contract KYAToken is ERC20, AccessControl, ERC20Permit, ERC20Votes {
    /// @notice Role identifier for addresses authorized to mint tokens
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice Maximum supply (1 billion tokens)
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10**18;

    /// @notice Total minted tokens
    uint256 private _totalMinted;

    /**
     * @notice Initialize KYA Token
     * @param name Token name
     * @param symbol Token symbol
     */
    constructor(string memory name, string memory symbol)
        ERC20(name, symbol)
        ERC20Permit(name)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Mint tokens (only MINTER_ROLE)
     * @param to Address to mint to
     * @param amount Amount to mint
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        require(_totalMinted + amount <= MAX_SUPPLY, "KYAToken: exceeds max supply");
        
        _totalMinted += amount;
        _mint(to, amount);
    }

    /**
     * @notice Batch mint tokens
     * @param recipients Array of recipient addresses
     * @param amounts Array of amounts to mint
     */
    function batchMint(address[] calldata recipients, uint256[] calldata amounts)
        external
        onlyRole(MINTER_ROLE)
    {
        require(recipients.length == amounts.length, "KYAToken: array length mismatch");
        
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        
        require(_totalMinted + totalAmount <= MAX_SUPPLY, "KYAToken: exceeds max supply");
        
        _totalMinted += totalAmount;
        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], amounts[i]);
        }
    }

    // =============================================================================
    // ERC20Votes Overrides
    // =============================================================================

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Votes)
    {
        super._update(from, to, value);
    }

    // Override nonces to resolve diamond inheritance (ERC20Permit->Nonces and ERC20Votes->Votes->Nonces)
    function nonces(address owner)
        public
        view
        virtual
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        // Both paths use the same Nonces storage, so we can use either
        return Nonces.nonces(owner);
    }
}
