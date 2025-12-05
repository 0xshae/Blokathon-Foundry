// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {RevolvStorage} from "src/facets/utilityFacets/RevolvStorage.sol";
import {IRevolv} from "src/facets/utilityFacets/IRevolv.sol";
import {Facet} from "src/facets/Facet.sol";
import {OwnershipStorage} from "src/facets/baseFacets/ownership/OwnershipStorage.sol";

// ---------------------------------------------------------------------
// Aave minimal interface
// ---------------------------------------------------------------------
interface IPool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

/**
 * @title RevolvFacet
 * @notice Self-repaying loan facet using Aave V3 yield on Sepolia.
 * @dev Implements rvUSDC token logic directly on diamond storage.
 */
contract RevolvFacet is Facet, IRevolv {
    // ---------------------------------------------------------------------
    // Constants (Sepolia)
    // ---------------------------------------------------------------------
    address private constant USDC_DEFAULT = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8;
    address private constant AAVE_POOL_DEFAULT = 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951;
    address private constant A_USDC_DEFAULT = 0x16dA4541aD1807f4443d92D26044C1147406EB80;

    // ---------------------------------------------------------------------
    // Token Functions (rvUSDC)
    // ---------------------------------------------------------------------
    function name() external view override returns (string memory) {
        return "Revolv USD Coin";
    }

    function symbol() external view override returns (string memory) {
        return "rvUSDC";
    }

    function decimals() external pure override returns (uint8) {
        return 6; // Match USDC decimals
    }

    function totalSupply() external view override returns (uint256) {
        return RevolvStorage.layout().totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return RevolvStorage.layout().balances[account];
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        RevolvStorage.layout().allowances[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        RevolvStorage.Layout storage l = RevolvStorage.layout();
        uint256 currentAllowance = l.allowances[from][msg.sender];
        require(currentAllowance >= amount, "Revolv: allowance exceeded");
        unchecked {
            l.allowances[from][msg.sender] = currentAllowance - amount;
        }
        _transfer(from, to, amount);
        return true;
    }

    // ---------------------------------------------------------------------
    // Vault Functions
    // ---------------------------------------------------------------------

    /// @notice Deposit USDC as collateral and supply to Aave.
    function depositCollateral(uint256 amount) external override nonReentrant {
        require(amount > 0, "Revolv: amount = 0");
        RevolvStorage.Layout storage l = RevolvStorage.layout();

        // Pull USDC from user
        address usdc = _usdc(l);
        address pool = _aavePool(l);
        require(IERC20(usdc).transferFrom(msg.sender, address(this), amount), "Revolv: transferFrom failed");

        // Approve and supply to Aave
        require(IERC20(usdc).approve(pool, amount), "Revolv: approve failed");
        IPool(pool).supply(usdc, amount, address(this), 0);

        // Accounting
        l.userCollateralPrincipal[msg.sender] += amount;
        l.totalCollateralPrincipal += amount;
    }

    /// @notice Borrow rvUSDC against collateral (50% LTV).
    function borrow(uint256 amount) external override nonReentrant {
        require(amount > 0, "Revolv: amount = 0");
        RevolvStorage.Layout storage l = RevolvStorage.layout();

        uint256 principal = l.userCollateralPrincipal[msg.sender];
        require(principal >= amount * 2, "Revolv: exceeds 50% LTV");

        l.userDebt[msg.sender] += amount;

        // Mint rvUSDC to borrower
        l.balances[msg.sender] += amount;
        l.totalSupply += amount;
    }

    /// @notice Repay rvUSDC debt with USDC.
    function repay(uint256 amount) external override nonReentrant {
        require(amount > 0, "Revolv: amount = 0");
        RevolvStorage.Layout storage l = RevolvStorage.layout();
        uint256 debt = l.userDebt[msg.sender];
        require(debt > 0, "Revolv: no debt");

        uint256 repayAmount = amount > debt ? debt : amount;

        // Pull USDC from user to back the debt repayment
        address usdc = _usdc(l);
        require(IERC20(usdc).transferFrom(msg.sender, address(this), repayAmount), "Revolv: transferFrom failed");

        l.userDebt[msg.sender] = debt - repayAmount;
    }

    /// @notice Withdraw collateral (requires zero debt).
    function withdraw(uint256 amount) external override nonReentrant {
        require(amount > 0, "Revolv: amount = 0");
        RevolvStorage.Layout storage l = RevolvStorage.layout();
        require(l.userDebt[msg.sender] == 0, "Revolv: debt outstanding");
        require(l.userCollateralPrincipal[msg.sender] >= amount, "Revolv: insufficient collateral");

        // Update accounting
        l.userCollateralPrincipal[msg.sender] -= amount;
        l.totalCollateralPrincipal -= amount;

        // Withdraw from Aave
        address usdc = _usdc(l);
        address pool = _aavePool(l);
        IPool(pool).withdraw(usdc, amount, address(this));

        // Transfer USDC back to user
        require(IERC20(usdc).transfer(msg.sender, amount), "Revolv: transfer failed");
    }

    /// @notice Harvest Aave yield and apply toward a user's debt.
    function harvest(address user) external override nonReentrant {
        RevolvStorage.Layout storage l = RevolvStorage.layout();

        address aUsdc = _aUsdc(l);
        address usdc = _usdc(l);
        address pool = _aavePool(l);

        uint256 aBalance = IERC20(aUsdc).balanceOf(address(this));
        if (aBalance <= l.totalCollateralPrincipal) {
            return; // No yield accrued
        }

        uint256 yieldAmount = aBalance - l.totalCollateralPrincipal;

        // Withdraw yield from Aave to this contract
        IPool(pool).withdraw(usdc, yieldAmount, address(this));

        uint256 debt = l.userDebt[user];
        if (debt == 0) {
            return;
        }

        uint256 repayAmount = yieldAmount < debt ? yieldAmount : debt;
        l.userDebt[user] = debt - repayAmount;
        // Note: USDC stays in contract as backing for the reduced debt.
    }

    // ---------------------------------------------------------------------
    // Internal Helpers
    // ---------------------------------------------------------------------
    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "Revolv: transfer to zero");
        RevolvStorage.Layout storage l = RevolvStorage.layout();
        uint256 fromBal = l.balances[from];
        require(fromBal >= amount, "Revolv: balance too low");
        unchecked {
            l.balances[from] = fromBal - amount;
            l.balances[to] += amount;
        }
    }

    /// @notice Admin-only mint to seed initial liquidity.
    function adminMint(address to, uint256 amount) external {
        require(OwnershipStorage.layout().owner == msg.sender, "Revolv: not owner");
        require(to != address(0), "Revolv: mint to zero");
        RevolvStorage.Layout storage l = RevolvStorage.layout();
        l.balances[to] += amount;
        l.totalSupply += amount;
    }

    /// @notice Owner-only config to override protocol addresses (useful for testing).
    function setConfig(address usdc, address aavePool, address aUsdc) external {
        require(OwnershipStorage.layout().owner == msg.sender, "Revolv: not owner");
        RevolvStorage.Layout storage l = RevolvStorage.layout();
        l.usdc = usdc;
        l.aavePool = aavePool;
        l.aUsdc = aUsdc;
    }

    // ---------------------------------------------------------------------
    // Internal getters with defaults
    // ---------------------------------------------------------------------
    function _usdc(RevolvStorage.Layout storage l) internal view returns (address) {
        return l.usdc == address(0) ? USDC_DEFAULT : l.usdc;
    }

    function _aavePool(RevolvStorage.Layout storage l) internal view returns (address) {
        return l.aavePool == address(0) ? AAVE_POOL_DEFAULT : l.aavePool;
    }

    function _aUsdc(RevolvStorage.Layout storage l) internal view returns (address) {
        return l.aUsdc == address(0) ? A_USDC_DEFAULT : l.aUsdc;
    }
}

