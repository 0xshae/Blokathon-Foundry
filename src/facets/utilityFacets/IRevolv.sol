// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRevolv {
    // ---------------------------------------------------------------------
    // Token Functions (rvUSDC)
    // ---------------------------------------------------------------------
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    // ---------------------------------------------------------------------
    // Vault Functions
    // ---------------------------------------------------------------------
    function depositCollateral(uint256 amount) external;
    function borrow(uint256 amount) external;
    function repay(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function harvest(address user) external;

    // ---------------------------------------------------------------------
    // Admin Functions
    // ---------------------------------------------------------------------
    function adminMint(address to, uint256 amount) external;
}

