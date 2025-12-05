// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RevolvStorage
 * @notice Diamond storage for the Revolv self-repaying loan facet.
 * @dev Uses namespaced storage slot to avoid collisions across facets.
 */
library RevolvStorage {
    /// @dev Storage slot for Revolv state.
    bytes32 internal constant STORAGE_POSITION = keccak256("revolv.storage");

    struct Layout {
        // ---------------------------------------------------------------------
        // Token State (rvUSDC)
        // ---------------------------------------------------------------------
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        uint256 totalSupply;
        string name;
        string symbol;

        // ---------------------------------------------------------------------
        // Vault State
        // ---------------------------------------------------------------------
        mapping(address => uint256) userCollateralPrincipal; // USDC deposited
        mapping(address => uint256) userDebt; // rvUSDC owed
        uint256 totalCollateralPrincipal;

        // ---------------------------------------------------------------------
        // Config (Sepolia Addresses)
        // ---------------------------------------------------------------------
        address usdc; // USDC token address on Sepolia
        address aavePool; // Aave V3 pool address on Sepolia
        address aUsdc; // aEthUSDC (aUSDC) on Sepolia
        address treasury; // Treasury recipient for fees
    }

    /**
     * @notice Returns the storage layout for Revolv.
     */
    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_POSITION;
        assembly {
            l.slot := slot
        }
    }
}

