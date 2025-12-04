# 🚀 Diamond Proxy Pattern - Quick Start Guide

## What is the Diamond Proxy Pattern? (Simple Explanation)

Think of the **Diamond** as a **smart contract router** and **facets** as **plug-in modules**.

### The Problem It Solves:
- Solidity contracts have a **24KB size limit** - you can't put everything in one contract
- Traditional proxies require redeploying everything to upgrade
- You want **modular, upgradeable** functionality

### The Solution:
- **Diamond** = The main contract that receives all calls
- **Facets** = Separate contracts with specific functionality (like plugins)
- When you call a function on the Diamond, it **delegates** to the right facet
- All facets **share the same storage** (like a shared database)

### Real-World Analogy:
Imagine a **smartphone** (Diamond) with **apps** (Facets):
- The phone receives all calls/requests
- Each app handles specific features
- All apps share the same storage (contacts, photos, etc.)
- You can add/remove/update apps without changing the phone

---

## How It Works (Technical)

### 1. **Function Selectors**
Every function has a unique 4-byte identifier called a "selector":
```solidity
bytes4 selector = bytes4(keccak256("lend(address,uint256)"));
// Example: 0x12345678
```

### 2. **The Diamond's Fallback**
When you call a function on the Diamond:
```solidity
// In Diamond.sol
fallback() external payable {
    // 1. Get the function selector from the call
    address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
    
    // 2. Delegatecall to that facet (runs code in facet's context, but uses Diamond's storage)
    delegatecall(facet, ...);
}
```

### 3. **Storage Pattern**
All facets use **namespaced storage** to avoid collisions:
```solidity
library AaveV3Storage {
    bytes32 constant STORAGE_POSITION = keccak256("aave.v3.storage");
    
    struct Layout {
        uint256 lastLendTimestamp;
    }
    
    function layout() internal pure returns (Layout storage l) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            l.slot := position
        }
    }
}
```

---

## 📁 Your Codebase Structure

```
src/
├── Diamond.sol                    # Main proxy contract (the router)
│
├── facets/
│   ├── Facet.sol                  # Base contract all facets inherit from
│   │
│   ├── baseFacets/                # Core Diamond functionality (don't modify)
│   │   ├── cut/                   # Adding/removing facets
│   │   ├── loupe/                 # Querying facets
│   │   └── ownership/             # Owner management
│   │
│   └── utilityFacets/             # YOUR FACETS GO HERE! 🎯
│       └── aaveV3/                # Example facet (study this!)
│           ├── AaveV3Storage.sol  # Storage layout
│           ├── IAaveV3.sol        # Interface
│           ├── AaveV3Base.sol     # Internal logic
│           └── AaveV3Facet.sol    # Public functions
│
└── interfaces/                    # Shared interfaces
```

---

## 🛠️ Building Your First Facet (Step-by-Step)

### Step 1: Create Your Facet Files

Create a new folder in `src/facets/utilityFacets/yourFacet/` with 4 files:

#### 1. **YourFacetStorage.sol** - Storage
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library YourFacetStorage {
    bytes32 constant STORAGE_POSITION = keccak256("your.facet.storage");
    
    struct Layout {
        mapping(address => uint256) balances;
        uint256 totalSupply;
        // Add your state variables here
    }
    
    function layout() internal pure returns (Layout storage l) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            l.slot := position
        }
    }
}
```

#### 2. **IYourFacet.sol** - Interface
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IYourFacet {
    function yourFunction() external returns (uint256);
    // Declare all public functions here
}
```

#### 3. **YourFacetBase.sol** - Internal Logic
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./YourFacetStorage.sol";
import "./IYourFacet.sol";

abstract contract YourFacetBase is IYourFacet {
    // Internal functions that do the actual work
    function _yourInternalLogic() internal view returns (uint256) {
        YourFacetStorage.Layout storage l = YourFacetStorage.layout();
        return l.totalSupply;
    }
}
```

#### 4. **YourFacet.sol** - Public Functions
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../Facet.sol";
import "./YourFacetBase.sol";
import "./IYourFacet.sol";

contract YourFacet is Facet, YourFacetBase {
    // Public functions that users call
    function yourFunction() external override returns (uint256) {
        return _yourInternalLogic();
    }
}
```

### Step 2: Deploy Your Facet

Update `script/DeployFacet.s.sol`:

```solidity
function run() public broadcaster {
    setUp();
    
    // Deploy your facet
    YourFacet yourFacet = new YourFacet();
    
    // Create facet cut
    IDiamondCut.FacetCut[] memory facetCuts = new IDiamondCut.FacetCut[](1);
    
    // Get function selectors
    bytes4[] memory functionSelectors = new bytes4[](1);
    functionSelectors[0] = YourFacet.yourFunction.selector;
    
    // Configure the cut
    facetCuts[0] = IDiamondCut.FacetCut({
        facetAddress: address(yourFacet),
        action: IDiamondCut.FacetCutAction.Add,
        functionSelectors: functionSelectors
    });
    
    // Add to diamond
    DiamondCutFacet(DIAMOND_ADDRESS).diamondCut(facetCuts, address(0), "");
}
```

### Step 3: Test It

```bash
# Build
forge build

# Test
forge test

# Deploy to local Anvil
anvil  # Terminal 1
forge script script/DeployFacet.s.sol --rpc-url http://127.0.0.1:8545 --broadcast  # Terminal 2
```

---

## 🎯 Key Concepts to Remember

### 1. **Storage Isolation**
Each facet uses a unique storage slot to avoid collisions:
```solidity
keccak256("your.unique.namespace.storage")
```

### 2. **Inheritance Chain**
```
YourFacet → Facet → YourFacetBase → IYourFacet
```
- `Facet`: Provides `onlyDiamondOwner` modifier and reentrancy protection
- `YourFacetBase`: Contains internal logic
- `IYourFacet`: Defines the interface

### 3. **Function Selectors**
Every public function needs to be registered:
```solidity
YourFacet.yourFunction.selector  // Gets the 4-byte selector
```

### 4. **Delegatecall Magic**
- Facet code runs in the Diamond's context
- Facet storage is accessed via the storage library
- All facets share the same address (the Diamond address)

---

## 📚 Study the Example: AaveV3Facet

Look at `src/facets/utilityFacets/aaveV3/` - it's a complete example:

1. **AaveV3Storage.sol**: Stores `lastLendTimestamp`
2. **IAaveV3.sol**: Interface with 3 functions
3. **AaveV3Base.sol**: Internal logic for lending/withdrawing
4. **AaveV3Facet.sol**: Public functions that call the base

**Key patterns to notice:**
- Uses `onlyDiamondOwner` modifier (from `Facet`)
- Uses `nonReentrant` modifier (from `Facet`)
- Accesses storage via `AaveV3Storage.layout()`
- Separates internal logic (`_lend`) from public interface (`lend`)

---

## 🚦 Where to Start

1. **Read the AaveV3Facet** - Understand the pattern
2. **Pick your DeFi feature** - Swap, lending, yield farming, etc.
3. **Create your 4 files** - Follow the structure above
4. **Test locally** - Use Anvil and Forge
5. **Deploy** - Use the deployment script

---

## 💡 Hackathon Tips

1. **Start Simple**: Build one feature first, then add more
2. **Reuse Storage**: You can access other facets' storage if needed
3. **Use OpenZeppelin**: SafeERC20, ReentrancyGuard, etc. are already available
4. **Test Thoroughly**: Write tests before deploying
5. **Focus on Wealth Management**: Lending, yield strategies, DCA, etc.

---

## 🔍 Common Questions

**Q: How do I call functions on the Diamond?**
```solidity
// The Diamond address IS your contract
IDiamond diamond = IDiamond(DIAMOND_ADDRESS);
diamond.yourFunction();  // Calls your facet!
```

**Q: Can facets call each other?**
Yes! Just call the function on the Diamond address (which is `address(this)` from a facet's perspective).

**Q: How do I upgrade a facet?**
Deploy a new version and use `DiamondCut` to replace the old one.

**Q: What if I need to store complex data?**
Use structs in your storage layout - they work just fine!

---

## 🎓 Resources

- **EIP-2535**: https://eips.ethereum.org/EIPS/eip-2535
- **Diamond Docs**: https://eip2535diamonds.substack.com/
- **Foundry Book**: https://book.getfoundry.sh/

---

Good luck at the hackathon! 🚀

