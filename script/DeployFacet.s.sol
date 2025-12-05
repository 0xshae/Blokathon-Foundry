//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BaseScript} from "script/Base.s.sol";
import {console} from "forge-std/console.sol";
import {DiamondCutFacet} from "src/facets/baseFacets/cut/DiamondCutFacet.sol";
import {IDiamondCut} from "src/facets/baseFacets/cut/IDiamondCut.sol";
import {AaveV3Facet} from "src/facets/utilityFacets/aaveV3/AaveV3Facet.sol";

contract DeployFacetScript is BaseScript {
    address internal constant DIAMOND_ADDRESS = 0xc4bf49cE8Da3f8b5166Da8E5f62660aEdaDE948D;

    function run() public broadcaster {
        setUp();
        // Deploy AaveV3Facet
        AaveV3Facet aaveV3Facet = new AaveV3Facet();

        // Add AaveV3Facet to diamond
        IDiamondCut.FacetCut[] memory facetCuts = new IDiamondCut.FacetCut[](1);

        // Add function selectors to AaveV3Facet
        bytes4[] memory functionSelectors = new bytes4[](3);
        functionSelectors[0] = AaveV3Facet.getReserveData.selector;
        functionSelectors[1] = AaveV3Facet.lend.selector;
        functionSelectors[2] = AaveV3Facet.withdraw.selector;

        // Add AaveV3Facet to diamond
        facetCuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(aaveV3Facet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        // Cut diamond
        DiamondCutFacet(DIAMOND_ADDRESS).diamondCut(facetCuts, address(0), "");
        console.log("AaveV3Facet deployed to: ", address(aaveV3Facet));
    }
}
