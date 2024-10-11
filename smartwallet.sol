// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ERC20 interface to interact with ERC20 tokens
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract MultiAssetWallet {
   // Mapping to track native cryptocurrency (Ether) deposits
    mapping(address => uint256) public nativeBalances;

    // Mapping to track ERC-20 token deposits per user and per token
    mapping(address => mapping(IERC20 => uint256)) public tokenBalances;

    // Event to log Ether deposits
    event NativeDeposit(address indexed user, uint256 amount);

    // Event to log ERC-20 token deposits
    event TokenDeposit(address indexed user, IERC20 token, uint256 amount);

    // Allow users to deposit native cryptocurrency (Ether)
    function depositNative() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");

        // Track the native cryptocurrency deposit
        nativeBalances[msg.sender] += msg.value;

        emit NativeDeposit(msg.sender, msg.value);
    }

    // Allow users to deposit ERC-20 tokens
    function depositToken(IERC20 token, uint256 amount) external {
        require(amount > 0, "Deposit amount must be greater than zero");

        // Transfer ERC-20 tokens from the user's wallet to this contract
        token.transferFrom(msg.sender, address(this), amount);

        // Track the ERC-20 token deposit
        tokenBalances[msg.sender][token] += amount;

        emit TokenDeposit(msg.sender, token, amount);
    }

    // Allow users to withdraw their native cryptocurrency (Ether)
    function withdrawNative(uint256 amount) external {
        require(nativeBalances[msg.sender] >= amount, "Insufficient balance");

        // Update the user's balance
        nativeBalances[msg.sender] -= amount;

        // Transfer Ether back to the user
        payable(msg.sender).transfer(amount);
    }

    // Allow users to withdraw their ERC-20 tokens
    function withdrawToken(IERC20 token, uint256 amount) external {
        require(tokenBalances[msg.sender][token] >= amount, "Insufficient token balance");

        // Update the user's token balance
        tokenBalances[msg.sender][token] -= amount;

        // Transfer the tokens back to the user
        token.transfer(msg.sender, amount);
    }

    // Function to check the contract's Ether balance
    function getContractNativeBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Function to check the contract's balance of a specific ERC-20 token
    function getContractTokenBalance(IERC20 token) external view returns (uint256) {
        return token.balanceOf(address(this));
    }
}