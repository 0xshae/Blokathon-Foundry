// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAaveAToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

/// @title MockAavePool
/// @notice Minimal mock for Aave V3 Pool interactions (supply/withdraw)
contract MockAavePool {
    address public immutable usdc;
    IAaveAToken public immutable aToken;

    constructor(address _usdc, address _aToken) {
        usdc = _usdc;
        aToken = IAaveAToken(_aToken);
    }

    function supply(address asset, uint256 amount, address onBehalfOf, uint16) external {
        require(asset == usdc, "asset");
        require(IERC20(usdc).transferFrom(msg.sender, address(this), amount), "transferFrom");
        aToken.mint(onBehalfOf, amount);
    }

    function withdraw(address asset, uint256 amount, address to) external returns (uint256) {
        require(asset == usdc, "asset");
        // burn caller's aTokens
        aToken.burn(msg.sender, amount);
        require(IERC20(usdc).transfer(to, amount), "transfer");
        return amount;
    }
}

