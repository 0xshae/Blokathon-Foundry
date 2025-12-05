# 🔄 Revolv Protocol - Design Document

## Overview

Revolv Protocol is a self-repaying loan mechanism built on Blok Capital's Garden (Diamond Proxy), inspired by Alchemix. Users can deposit stablecoins, earn yield via Yearn Finance, and borrow against their collateral with 0% interest loans that automatically repay themselves.

## Architecture

### Core Components

1. **Collateral Facet** (Facet 1)
   - Handles USDC deposits
   - Integrates with Yearn Finance (yvUSDC)
   - Locks yvUSDC as collateral
   - Mints rvUSDC (Revolv USD Coin) - pegged 1:1
   - Allows borrowing up to 80% LTV

2. **Settlement Facet** (Facet 2)
   - Harvests yield from Yearn pools
   - Takes 10% cut for Treasury
   - Uses remaining yield to repay debt
   - Automatically settles loans over time

3. **Treasury Facet** (Future)
   - Receives 10% of harvested yield
   - For Blok Capital DAO

4. **rvUSDC Token**
   - ERC20 token
   - Pegged 1:1 to collateral value
   - Backed by real money (yvUSDC)
   - Liquid and usable anywhere

## User Flow

### 1. Deposit & Lock Collateral
```
User deposits $1000 USDC
  ↓
Facet deposits to Yearn Finance
  ↓
Receives yvUSDC (Yearn vault token)
  ↓
yvUSDC locked as collateral in Garden
```

### 2. Borrow rvUSDC
```
User can borrow up to 80% LTV
  ↓
$1000 collateral → borrow $800 rvUSDC
  ↓
rvUSDC minted and sent to user
  ↓
0% interest on the loan
```

### 3. Automatic Debt Settlement
```
Settlement Facet periodically:
  ↓
Calls Yearn harvest() to withdraw APY
  ↓
Takes 10% cut → sends to Treasury
  ↓
Uses remaining 90% to repay debt
  ↓
Debt decreases: $800 → $700 → $600... → $0
```

### 4. Post-Repayment Options

**Option A: Keep Earning**
```
Debt fully repaid
  ↓
Yield keeps accumulating
  ↓
Settlement Facet harvests yield
  ↓
Yield sent to user's custodial wallet in Garden
```

**Option B: Withdraw Collateral**
```
User calls withdraw function
  ↓
Facet unstakes from Yearn pool
  ↓
Receives USDC back
  ↓
Transfers to user's Garden
```

## Technical Details

### Yearn Finance Integration
- **Protocol**: Yearn Finance V3
- **Vault**: yvUSDC (USDC Yearn Vault)
- **Functions Needed**:
  - `deposit(uint256 amount)` - Deposit USDC, receive yvUSDC
  - `withdraw(uint256 shares)` - Withdraw USDC, burn yvUSDC
  - `harvest()` - Claim accumulated yield
  - `pricePerShare()` - Get current share price

### Key Features

1. **No Liquidation Risk**
   - Only stablecoins (USDC)
   - No price volatility
   - Safe 80% LTV

2. **0% Interest Loans**
   - User pays no interest
   - Yield repays the debt automatically
   - True self-repaying mechanism

3. **Treasury Revenue**
   - 10% of all harvested yield
   - Supports Blok Capital DAO
   - Sustainable protocol economics

4. **Flexible Withdrawal**
   - Can withdraw anytime after debt repaid
   - Or keep earning passive income
   - Full control to user

## Facet Structure

### Facet 1: RevolvCollateralFacet
**Functions:**
- `depositCollateral(uint256 amount)` - Deposit USDC, lock yvUSDC
- `borrow(uint256 amount)` - Borrow rvUSDC against collateral
- `withdrawCollateral()` - Unstake and withdraw after debt repaid
- `getCollateralBalance(address user)` - View user's collateral
- `getBorrowableAmount(address user)` - Calculate max borrow (80% LTV)

**Storage:**
- User → collateral amount (yvUSDC)
- User → borrowed amount (rvUSDC)
- User → debt remaining

### Facet 2: RevolvSettlementFacet
**Functions:**
- `harvestAndSettle(address user)` - Harvest yield, settle debt
- `harvestAll()` - Batch harvest for all users
- `getAccumulatedYield(address user)` - View pending yield
- `getDebtStatus(address user)` - View remaining debt

**Storage:**
- User → last harvest timestamp
- User → accumulated yield
- Protocol → total treasury balance

### Facet 3: RevolvTreasuryFacet (Future)
**Functions:**
- `deposit(uint256 amount)` - Receive treasury fees
- `withdraw(uint256 amount)` - DAO governance withdrawal
- `getBalance()` - View treasury balance

## Token: rvUSDC

### Properties
- **Name**: Revolv USD Coin
- **Symbol**: rvUSDC
- **Decimals**: 6 (same as USDC)
- **Peg**: 1:1 with USDC
- **Backing**: yvUSDC collateral locked in Garden

### Minting
- Minted when user borrows
- Amount = borrow amount
- Backed by locked yvUSDC

### Redemption
- When debt is repaid, rvUSDC can be burned
- Or kept as liquid asset
- Always redeemable 1:1 with USDC (via collateral)

## Implementation Plan

### Phase 1: Core Infrastructure
1. ✅ Set up new branch
2. ⏳ Research Yearn Finance V3 contracts
3. ⏳ Design storage structures
4. ⏳ Create interfaces

### Phase 2: Collateral Facet
1. ⏳ Implement Yearn integration
2. ⏳ Implement deposit/lock mechanism
3. ⏳ Implement borrow mechanism
4. ⏳ Implement rvUSDC minting

### Phase 3: Settlement Facet
1. ⏳ Implement yield harvesting
2. ⏳ Implement debt settlement logic
3. ⏳ Implement treasury fee collection
4. ⏳ Implement batch operations

### Phase 4: Testing & Deployment
1. ⏳ Write comprehensive tests
2. ⏳ Deploy to testnet
3. ⏳ Verify Yearn integration
4. ⏳ Deploy to mainnet

## Open Questions

1. **Yearn Vault Address**: Which Yearn vault to use? (yvUSDC address on Base)
2. **Harvest Frequency**: How often to harvest? (Daily? Weekly?)
3. **Treasury Address**: Where to send treasury fees initially?
4. **rvUSDC Transferability**: Can rvUSDC be transferred? Or locked to borrower?
5. **Partial Withdrawal**: Can users partially withdraw collateral?

## Next Steps

Waiting for specific implementation instructions...

