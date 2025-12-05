//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BaseScript} from "script/Base.s.sol";
import {console} from "forge-std/console.sol";
import {DiamondCutFacet} from "src/facets/baseFacets/cut/DiamondCutFacet.sol";
import {IDiamondCut} from "src/facets/baseFacets/cut/IDiamondCut.sol";
import {RevolvFacet} from "src/facets/utilityFacets/RevolvFacet.sol";

contract DeployRevolvFacetScript is BaseScript {
    // Diamond address (replace if different)
    address internal constant diamondAddr = 0xc4bf49cE8Da3f8b5166Da8E5f62660aEdaDE948D;

    function run() public broadcaster {
        require(diamondAddr != address(0), "DeployRevolvFacet: Set diamondAddr first!");
        
        setUp();
        
        // Deploy RevolvFacet
        RevolvFacet revolvFacet = new RevolvFacet();
        console.log("RevolvFacet deployed to: ", address(revolvFacet));

        // Prepare DiamondCut: replace existing selectors, add adminMint separately
        IDiamondCut.FacetCut[] memory facetCuts = new IDiamondCut.FacetCut[](2);

        // Replace existing selectors (13)
        bytes4[] memory replaceSelectors = new bytes4[](13);
        replaceSelectors[0] = RevolvFacet.name.selector;
        replaceSelectors[1] = RevolvFacet.symbol.selector;
        replaceSelectors[2] = RevolvFacet.decimals.selector;
        replaceSelectors[3] = RevolvFacet.totalSupply.selector;
        replaceSelectors[4] = RevolvFacet.balanceOf.selector;
        replaceSelectors[5] = RevolvFacet.transfer.selector;
        replaceSelectors[6] = RevolvFacet.approve.selector;
        replaceSelectors[7] = RevolvFacet.transferFrom.selector;
        replaceSelectors[8] = RevolvFacet.depositCollateral.selector;
        replaceSelectors[9] = RevolvFacet.borrow.selector;
        replaceSelectors[10] = RevolvFacet.repay.selector;
        replaceSelectors[11] = RevolvFacet.withdraw.selector;
        replaceSelectors[12] = RevolvFacet.harvest.selector;

        facetCuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(revolvFacet),
            action: IDiamondCut.FacetCutAction.Replace,
            functionSelectors: replaceSelectors
        });

        // Add new selector (adminMint)
        bytes4[] memory addSelectors = new bytes4[](1);
        addSelectors[0] = RevolvFacet.adminMint.selector;

        facetCuts[1] = IDiamondCut.FacetCut({
            facetAddress: address(revolvFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: addSelectors
        });

        // Cut diamond
        DiamondCutFacet(diamondAddr).diamondCut(facetCuts, address(0), "");
        console.log("RevolvFacet added to Diamond at: ", diamondAddr);
    }
}

