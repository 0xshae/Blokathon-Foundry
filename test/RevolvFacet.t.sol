// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {RevolvFacet} from "src/facets/utilityFacets/RevolvFacet.sol";
import {IRevolv} from "src/facets/utilityFacets/IRevolv.sol";
import {RevolvStorage} from "src/facets/utilityFacets/RevolvStorage.sol";
import {OwnershipStorage} from "src/facets/baseFacets/ownership/OwnershipStorage.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";
import {MockAavePool} from "test/mocks/MockAavePool.sol";

contract RevolvFacetTest is Test {
    RevolvFacet revolv;
    MockERC20 usdc;
    MockERC20 aUsdc;
    MockAavePool pool;

    address user = address(0xBEEF);

    // helpers
    uint256 constant USDC_DECIMALS = 6;

    function setUp() public {
        // Deploy mocks
        usdc = new MockERC20("Mock USDC", "mUSDC", uint8(USDC_DECIMALS));
        aUsdc = new MockERC20("Mock aUSDC", "maUSDC", uint8(USDC_DECIMALS));
        pool = new MockAavePool(address(usdc), address(aUsdc));

        // Deploy facet
        revolv = new RevolvFacet();

        // Set ownership to this test contract
        bytes32 ownerSlot = keccak256("ownership.storage");
        vm.store(address(revolv), ownerSlot, bytes32(uint256(uint160(address(this)))));

        // Configure to use mocks
        revolv.setConfig(address(usdc), address(pool), address(aUsdc));

        // Fund user and approve
        usdc.mint(user, 2_000 * 10 ** USDC_DECIMALS);
        vm.prank(user);
        usdc.approve(address(revolv), type(uint256).max);
    }

    function testDepositAndBorrow() public {
        vm.startPrank(user);
        revolv.depositCollateral(1_000 * 10 ** USDC_DECIMALS);
        revolv.borrow(400 * 10 ** USDC_DECIMALS); // 40% LTV
        vm.stopPrank();

        assertEq(_userCollateral(), 1_000 * 10 ** USDC_DECIMALS, "collateral");
        assertEq(_userDebt(), 400 * 10 ** USDC_DECIMALS, "debt");
        assertEq(revolv.balanceOf(user), 400 * 10 ** USDC_DECIMALS, "rv balance");
    }

    function testBorrowOverLTVReverts() public {
        vm.startPrank(user);
        revolv.depositCollateral(100 * 10 ** USDC_DECIMALS);
        vm.expectRevert("Revolv: exceeds 50% LTV");
        revolv.borrow(60 * 10 ** USDC_DECIMALS);
        vm.stopPrank();
    }

    function testHarvestReducesDebt() public {
        vm.startPrank(user);
        revolv.depositCollateral(1_000 * 10 ** USDC_DECIMALS);
        revolv.borrow(400 * 10 ** USDC_DECIMALS);
        vm.stopPrank();

        // Simulate yield: mint aUSDC to the facet and ensure pool has USDC to withdraw
        aUsdc.mint(address(revolv), 200 * 10 ** USDC_DECIMALS);
        usdc.mint(address(pool), 200 * 10 ** USDC_DECIMALS);

        revolv.harvest(user);

        assertEq(_userDebt(), 200 * 10 ** USDC_DECIMALS, "debt reduced by yield");
    }

    function testAdminMintRequiresOwner() public {
        vm.prank(user);
        vm.expectRevert("Revolv: not owner");
        revolv.adminMint(user, 1);
    }

    // ---------------------------------------------------------------------
    // Internal helpers
    // ---------------------------------------------------------------------
    function _userCollateral() internal view returns (uint256) {
        // RevolvStorage slot = keccak256("revolv.storage"); mapping offset = 5
        uint256 base = uint256(keccak256("revolv.storage"));
        bytes32 slot = keccak256(abi.encode(user, base + 5));
        return uint256(vm.load(address(revolv), slot));
    }

    function _userDebt() internal view returns (uint256) {
        uint256 base = uint256(keccak256("revolv.storage"));
        bytes32 slot = keccak256(abi.encode(user, base + 6));
        return uint256(vm.load(address(revolv), slot));
    }
}

