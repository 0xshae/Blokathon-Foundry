// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BaseScript} from "script/Base.s.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRevolv} from "src/facets/utilityFacets/IRevolv.sol";

// Minimal Uniswap V3 Position Manager interface
interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);

    function mint(MintParams calldata params)
        external
        payable
        returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
}

contract CreatePoolScript is BaseScript {
    // Uniswap V3 Position Manager (Sepolia)
    address internal constant POSITION_MANAGER = 0x1238536071E1c677A632429e3655c799b22cDA52;
    // USDC on Sepolia
    address internal constant USDC = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8;

    // Amounts for seeding liquidity
    uint256 internal constant AMOUNT_USDC = 1_000 * 1e6; // USDC has 6 decimals
    uint256 internal constant AMOUNT_RVUSDC = 1_000 * 1e18; // rvUSDC has 18 decimals

    function run() public broadcaster {
        setUp();

        address diamond = vm.envAddress("DIAMOND_ADDR");
        require(diamond != address(0), "CreatePool: DIAMOND_ADDR not set");

        IRevolv revolv = IRevolv(diamond);
        IERC20 usdc = IERC20(USDC);
        INonfungiblePositionManager manager = INonfungiblePositionManager(POSITION_MANAGER);

        // Mint initial rvUSDC to deployer for liquidity seeding
        revolv.adminMint(msg.sender, AMOUNT_RVUSDC);

        // Determine token order
        address token0 = USDC;
        address token1 = diamond; // rvUSDC lives at diamond address
        uint256 amount0Desired = AMOUNT_USDC;
        uint256 amount1Desired = AMOUNT_RVUSDC;

        if (token0 > token1) {
            (token0, token1) = (token1, token0);
            (amount0Desired, amount1Desired) = (amount1Desired, amount0Desired);
        }

        // Compute sqrtPriceX96 for 1:1 price adjusting for decimals
        uint160 sqrtPriceX96 = _getSqrtPriceX96(token0, token1);

        // Approvals
        require(usdc.approve(POSITION_MANAGER, AMOUNT_USDC), "CreatePool: USDC approve failed");
        revolv.approve(POSITION_MANAGER, AMOUNT_RVUSDC);

        // Create & initialize pool if needed
        address pool = manager.createAndInitializePoolIfNecessary(token0, token1, 3000, sqrtPriceX96);
        console.log("Pool address: ", pool);

        // Mint full-range position
        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: 3000,
            tickLower: -887220,
            tickUpper: 887220,
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            amount0Min: 0,
            amount1Min: 0,
            recipient: msg.sender,
            deadline: block.timestamp
        });

        (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) = manager.mint(params);
        console.log("Minted position tokenId:", tokenId);
        console.log("Liquidity:", liquidity);
        console.log("Amounts used - amount0:", amount0, " amount1:", amount1);
    }

    /// @dev Computes sqrtPriceX96 for 1:1 price, adjusting for decimals and token ordering.
    function _getSqrtPriceX96(address token0, address token1) internal pure returns (uint160) {
        // rvUSDC: 18 decimals, USDC: 6 decimals
        bool usdcIsToken0 = (token0 == USDC);

        // Price is token1 / token0
        // If token0 == USDC (6 dec) and token1 == rvUSDC (18 dec):
        // price = 1e12; sqrtPrice = 1e6; sqrtPriceX96 = 1e6 * 2^96
        // If reversed: price = 1e-12; sqrtPrice = 1e-6; sqrtPriceX96 = 1e-6 * 2^96
        if (usdcIsToken0) {
            // price = 1e12
            // sqrtPriceX96 = 1e6 * 2^96
            return uint160(uint256(1e6) * (2 ** 96));
        } else {
            // price = 1e-12
            // sqrtPriceX96 = 1e-6 * 2^96 = 2^96 / 1e6
            return uint160(uint256(2 ** 96) / 1_000_000);
        }
    }
}

