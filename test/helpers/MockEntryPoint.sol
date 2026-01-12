// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title MockEntryPoint
 * @notice Simplified mock of ERC-4337 EntryPoint for testing
 */
contract MockEntryPoint {
    mapping(address => uint256) public balances;

    event Deposited(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);

    /**
     * @notice Deposit funds
     */
    function deposit() external payable {
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @notice Deposit funds to a specific account
     */
    function depositTo(address account) external payable {
        balances[account] += msg.value;
        emit Deposited(account, msg.value);
    }

    /**
     * @notice Get deposit balance
     */
    function getDeposit(address account) external view returns (uint256) {
        return balances[account];
    }

    /**
     * @notice Withdraw funds (for testing)
     */
    function withdrawTo(address payable account, uint256 amount) external {
        require(balances[msg.sender] >= amount, "MockEntryPoint: insufficient balance");
        balances[msg.sender] -= amount;
        (bool success,) = account.call{value: amount}("");
        require(success, "MockEntryPoint: transfer failed");
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @notice Receive ETH
     */
    receive() external payable {
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
}

