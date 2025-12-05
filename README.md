# 🔄 Revolv Protocol

**Self-Repaying Loans Powered by Aave V3 Yield**

Revolv Protocol is a revolutionary DeFi lending system built on Blok Capital's Garden (Diamond Proxy) that enables users to borrow against their collateral with **zero interest** - the loan repays itself automatically using yield generated from Aave V3.

---

## 🌟 What is Revolv Protocol?

Revolv Protocol introduces **rvUSDC** (Revolv USD Coin), a synthetic stablecoin backed 1:1 by USDC collateral locked in Aave V3. Users can:

- **Deposit USDC** as collateral → automatically earns yield on Aave V3
- **Borrow rvUSDC** up to 50% LTV with **0% interest**
- **Watch your loan repay itself** as Aave yield automatically reduces your debt
- **Withdraw collateral** once debt is fully repaid

### The Magic ✨

Traditional loans require you to pay interest. Revolv loans **pay themselves** using the yield from your collateral. It's like having a loan that gets smaller every day without you doing anything!

---

## 🎯 Key Features

- ✅ **Zero Interest Loans** - Borrow rvUSDC with 0% interest rate
- ✅ **Self-Repaying** - Aave yield automatically reduces your debt over time
- ✅ **50% LTV** - Conservative loan-to-value ratio for safety
- ✅ **Fully Backed** - Every rvUSDC is backed 1:1 by USDC collateral
- ✅ **Liquid Token** - rvUSDC can be used anywhere (DEXs, DeFi protocols, etc.)
- ✅ **Diamond Proxy** - Built on EIP-2535 for modularity and upgradeability
- ✅ **No Liquidation Risk** - Stablecoin-only (USDC) means no price volatility

---

## 🏗️ How It Works

### 1. **Deposit Collateral**
```
User deposits 10,000 USDC
  ↓
Protocol supplies to Aave V3
  ↓
Receives aUSDC (Aave interest-bearing token)
  ↓
Collateral locked in Garden
```

### 2. **Borrow rvUSDC**
```
User borrows 5,000 rvUSDC (50% of collateral)
  ↓
rvUSDC minted and sent to user
  ↓
Debt tracked: 5,000 rvUSDC
```

### 3. **Automatic Debt Repayment**
```
Aave generates yield on 10,000 USDC
  ↓
Periodically, harvest() is called
  ↓
Yield withdrawn from Aave
  ↓
Debt automatically reduced: 5,000 → 4,500 → 4,000... → 0
```

### 4. **Withdraw or Keep Earning**
```
Once debt = 0:
  ↓
Option A: Withdraw all collateral
Option B: Keep earning yield (debt already paid!)
```

---

## 📋 Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Node.js (for dependencies)
- Git
- Basic understanding of Solidity and DeFi

---

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/0xshae/Blokathon-Foundry.git
cd Blokathon-Foundry
```

### 2. Install Dependencies

```bash
forge install
```

### 3. Set Up Environment

```bash
# Copy example env file
cp .envExample .env

# Edit .env with your credentials
nano .env
```

**Required variables:**
```bash
# For testnet deployment
PRIVATE_KEY=0x...your_private_key
RPC_URL_BASE_SEPOLIA=https://sepolia.base.org

# For local testing
PRIVATE_KEY_ANVIL=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
RPC_URL_ANVIL=http://127.0.0.1:8545
```

### 4. Build Contracts

```bash
forge build
```

### 5. Run Tests

```bash
forge test
```

---

## 🧪 Testing

Revolv Protocol includes comprehensive tests covering:

- ✅ Token operations (mint, transfer, approve)
- ✅ Collateral deposits
- ✅ Borrowing with LTV checks
- ✅ Debt repayment
- ✅ Yield harvesting and automatic debt reduction
- ✅ Access control (owner-only functions)

**Run all tests:**
```bash
forge test
```

**Run with verbosity:**
```bash
forge test -vvv
```

**Run specific test:**
```bash
forge test --match-test testDepositAndBorrow
```

---

## 🌐 Deployment

### Step 1: Deploy Diamond

First, deploy the base Diamond contract:

```bash
source .env

forge script script/Deploy.s.sol \
  --rpc-url $RPC_URL_BASE_SEPOLIA \
  --private-key $PRIVATE_KEY \
  --broadcast
```

**Save the Diamond address** from the output!

### Step 2: Deploy Revolv Facet

Update `script/DeployRevolvFacet.s.sol` with your Diamond address, then:

```bash
forge script script/DeployRevolvFacet.s.sol \
  --rpc-url $RPC_URL_BASE_SEPOLIA \
  --private-key $PRIVATE_KEY \
  --broadcast
```

This adds the RevolvFacet to your Diamond with all 14 functions:
- 8 ERC20 token functions (name, symbol, decimals, totalSupply, balanceOf, transfer, approve, transferFrom)
- 5 vault functions (depositCollateral, borrow, repay, withdraw, harvest)
- 1 admin function (adminMint)

### Step 3: Create Uniswap V3 Pool (Optional)

To enable trading of rvUSDC, create a Uniswap V3 pool:

```bash
export DIAMOND_ADDR=0xYourDiamondAddress

forge script script/CreatePool.s.sol \
  --rpc-url $RPC_URL_BASE_SEPOLIA \
  --private-key $PRIVATE_KEY \
  --broadcast
```

This will:
1. Mint 1,000 rvUSDC to seed liquidity
2. Create a Uniswap V3 pool (rvUSDC/USDC)
3. Add initial liquidity (1,000 rvUSDC + 1,000 USDC)

---

## 💻 Usage Examples

### Interact with Revolv Protocol

Once deployed, you can interact with the Diamond address directly:

```solidity
// The Diamond address IS the rvUSDC token
IRevolv revolv = IRevolv(diamondAddress);

// Deposit collateral
revolv.depositCollateral(10_000 * 1e6); // 10,000 USDC

// Borrow rvUSDC (up to 50% LTV)
revolv.borrow(5_000 * 1e6); // 5,000 rvUSDC

// Check your balance
uint256 balance = revolv.balanceOf(msg.sender);

// Transfer rvUSDC
revolv.transfer(recipient, 1_000 * 1e6);

// Harvest yield (reduces debt automatically)
revolv.harvest(msg.sender);

// Withdraw collateral (only when debt = 0)
revolv.withdraw(10_000 * 1e6);
```

### Using Cast (Command Line)

```bash
# Check rvUSDC balance
cast call $DIAMOND_ADDR "balanceOf(address)" $USER_ADDRESS --rpc-url $RPC_URL

# Check total supply
cast call $DIAMOND_ADDR "totalSupply()" --rpc-url $RPC_URL

# Deposit collateral
cast send $DIAMOND_ADDR "depositCollateral(uint256)" 1000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL

# Borrow rvUSDC
cast send $DIAMOND_ADDR "borrow(uint256)" 500000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL
```

---

## 📁 Project Structure

```
Blokathon-Foundry/
├── src/
│   ├── Diamond.sol                    # Main Diamond proxy contract
│   ├── facets/
│   │   ├── Facet.sol                  # Base facet (reentrancy, ownership)
│   │   ├── baseFacets/                # Core Diamond facets
│   │   │   ├── cut/                   # DiamondCut functionality
│   │   │   ├── loupe/                 # DiamondLoupe introspection
│   │   │   └── ownership/             # Ownership management
│   │   └── utilityFacets/
│   │       ├── RevolvFacet.sol        # 🎯 Main Revolv implementation
│   │       ├── IRevolv.sol            # Revolv interface
│   │       └── RevolvStorage.sol      # Storage layout (token + vault)
│   └── interfaces/
├── script/
│   ├── Deploy.s.sol                   # Deploy Diamond
│   ├── DeployRevolvFacet.s.sol        # Deploy Revolv facet
│   ├── CreatePool.s.sol               # Create Uniswap V3 pool
│   └── Base.s.sol                     # Base script utilities
├── test/
│   ├── RevolvFacet.t.sol              # Comprehensive test suite
│   └── mocks/
│       ├── MockERC20.sol              # Mock USDC token
│       └── MockAavePool.sol            # Mock Aave pool
├── .envExample                        # Environment template
└── README.md                          # This file
```

---

## 🔧 Architecture

### Diamond Proxy Pattern (EIP-2535)

Revolv Protocol is built on the Diamond Proxy standard, which enables:

- **Modularity**: Add/remove/upgrade facets without redeploying
- **Unlimited Size**: Bypass 24KB contract size limit
- **Shared Storage**: All facets share the same storage space
- **Upgradeability**: Upgrade individual facets independently

### Storage Pattern

Revolv uses a **namespaced storage library** pattern:

```solidity
library RevolvStorage {
    bytes32 constant STORAGE_POSITION = keccak256("revolv.storage");
    
    struct Layout {
        // Token state (rvUSDC)
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        uint256 totalSupply;
        
        // Vault state
        mapping(address => uint256) userCollateralPrincipal;
        mapping(address => uint256) userDebt;
        uint256 totalCollateralPrincipal;
        
        // Config
        address usdc;
        address aavePool;
        address aUsdc;
    }
}
```

### Token Implementation

rvUSDC is **not** a standard ERC20 contract. Instead, it's implemented directly on Diamond storage:

- ✅ All ERC20 functions work (transfer, approve, balanceOf, etc.)
- ✅ Stored in Diamond's shared storage
- ✅ Can be upgraded via DiamondCut
- ✅ No separate token contract deployment needed

---

## 🔐 Security Features

- **Reentrancy Protection**: All state-changing functions use `nonReentrant` modifier
- **Access Control**: Admin functions restricted to Diamond owner
- **Conservative LTV**: 50% maximum loan-to-value ratio
- **Stablecoin Only**: USDC-only reduces liquidation risk
- **Storage Isolation**: Namespaced storage prevents collisions
- **Safe Math**: Solidity 0.8.20 built-in overflow protection

---

## 📊 Current Deployment

**Base Sepolia Testnet:**
- Diamond: `0xc4bf49cE8Da3f8b5166Da8E5f62660aEdaDE948D`
- RevolvFacet: `0x4d733dae9218a1bD983778c1F4bBe3E0307D9Ed0`

**Aave V3 Sepolia Addresses:**
- USDC: `0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8`
- Aave Pool: `0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951`
- aUSDC: `0x16dA4541aD1807f4443d92D26044C1147406EB80`

---

## 🛠️ Development

### Build

```bash
forge build
```

### Format Code

```bash
forge fmt
```

### Gas Snapshots

```bash
forge snapshot
```

### Clean Build Artifacts

```bash
forge clean
```

---

## 📚 Learn More

### Diamond Proxy Pattern
- [EIP-2535 Specification](https://eips.ethereum.org/EIPS/eip-2535)
- [Diamond Standard Documentation](https://eip2535diamonds.substack.com/)

### Aave V3
- [Aave V3 Documentation](https://docs.aave.com/)
- [Aave V3 GitHub](https://github.com/aave/aave-v3-core)

### Foundry
- [Foundry Book](https://book.getfoundry.sh/)
- [Foundry GitHub](https://github.com/foundry-rs/foundry)

---

## 🤝 Contributing

This project was built for the **Blok-a-Thon** hackathon by Blok Capital. Contributions and improvements are welcome!

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 🙏 Acknowledgments

- **Blok Capital** for the hackathon and Diamond Proxy infrastructure
- **Aave** for the yield generation protocol
- **Nick Mudge** for the Diamond Standard (EIP-2535)
- **OpenZeppelin** for security libraries

---

## 🚨 Disclaimer

This software is provided "as is" without warranty. Use at your own risk. Always audit smart contracts before deploying to mainnet.

---

## 📧 Contact

- **GitHub**: [@0xshae](https://github.com/0xshae)
- **Project**: Built for Blok-a-Thon Hackathon

---

**Built with ❤️ for the Blok-a-Thon Hackathon**

*Revolv Protocol - Where loans repay themselves* 🔄
