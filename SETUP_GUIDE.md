# 🚀 Environment Setup Guide

This guide will help you set up your environment for building and deploying the Self-Repaying Loan facet.

## Step 1: Install Foundry

Foundry is the development framework we're using. Install it:

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Verify installation
forge --version
cast --version
anvil --version
```

## Step 2: Install Dependencies

```bash
# Install project dependencies
forge install

# This will install all the libraries (Aave, OpenZeppelin, etc.)
```

## Step 3: Set Up Environment Variables

### Option A: For Local Testing (Anvil)

Create/update your `.env` file:

```bash
# Local Anvil (for testing)
PRIVATE_KEY_ANVIL=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
RPC_URL_ANVIL=http://127.0.0.1:8545
SALT=0x0000000000000000000000000000000000000000000000000000000000000000

# Optional: For local testing
API_KEY_ETHERSCAN=YOUR_API_KEY
```

### Option B: For Testnet Deployment (Base Sepolia)

```bash
# Base Sepolia Testnet
PRIVATE_KEY=your_private_key_here_0x...
RPC_URL_BASE_SEPOLIA=https://sepolia.base.org
API_KEY_BASESCAN=your_basescan_api_key

# Or use Base Mainnet
RPC_URL_BASE=https://mainnet.base.org
```

### Option C: Complete Setup (All Networks)

```bash
# Local Anvil
PRIVATE_KEY_ANVIL=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
RPC_URL_ANVIL=http://127.0.0.1:8545
SALT=0x0000000000000000000000000000000000000000000000000000000000000000

# For real network deployment
PRIVATE_KEY=your_private_key_here_0x...

# RPC URLs
RPC_URL_ARBITRUM=https://arb1.arbitrum.io/rpc
RPC_URL_POLYGON=https://polygon-rpc.com
RPC_URL_AVALANCHE=https://api.avax.network/ext/bc/C/rpc
RPC_URL_BASE=https://mainnet.base.org
RPC_URL_BASE_SEPOLIA=https://sepolia.base.org
RPC_URL_BSC=https://bsc-dataseed.binance.org

# API Keys for verification
API_KEY_ETHERSCAN=your_etherscan_api_key
API_KEY_ARBISCAN=your_arbiscan_api_key
API_KEY_POLYGONSCAN=your_polygonscan_api_key
API_KEY_SNOWTRACE=your_snowtrace_api_key
API_KEY_BASESCAN=your_basescan_api_key
API_KEY_BSCSCAN=your_bscscan_api_key
```

## Step 4: Get Your Private Key

⚠️ **SECURITY WARNING**: Never commit your private key to git!

### For Testing (Use a test wallet):
1. Create a new wallet in MetaMask
2. Export the private key (Settings → Security & Privacy → Show Private Key)
3. Use this for testnet only!

### For Mainnet:
- Use a hardware wallet or secure key management
- Consider using environment variable injection from a secure vault

## Step 5: Get RPC URLs

### Free RPC Providers:

**Base Sepolia (Testnet):**
- https://sepolia.base.org (Official)
- https://base-sepolia.g.alchemy.com/v2/YOUR_KEY (Alchemy - need account)
- https://base-sepolia.infura.io/v3/YOUR_KEY (Infura - need account)

**Base Mainnet:**
- https://mainnet.base.org (Official)
- https://base-mainnet.g.alchemy.com/v2/YOUR_KEY (Alchemy)
- https://base-mainnet.infura.io/v3/YOUR_KEY (Infura)

### Get API Keys:

1. **Basescan (Base Explorer):**
   - Go to https://basescan.org/
   - Sign up for an account
   - Get your API key from account settings

2. **Alchemy/Infura (for better RPC):**
   - Sign up at https://www.alchemy.com/ or https://www.infura.io/
   - Create a new app
   - Get your API key

## Step 6: Load Environment Variables

```bash
# Load variables into current shell
source .env

# Verify they're loaded
echo $PRIVATE_KEY_ANVIL
echo $RPC_URL_ANVIL
```

## Step 7: Test Your Setup

### Build the contracts:
```bash
forge build
```

### Run tests (if you have tests):
```bash
forge test
```

### Start local Anvil node:
```bash
# Terminal 1
anvil

# Terminal 2 - Deploy to Anvil
source .env
forge script script/Deploy.s.sol \
  --rpc-url $RPC_URL_ANVIL \
  --private-key $PRIVATE_KEY_ANVIL \
  --broadcast
```

## Step 8: Deploy to Testnet

Once everything works locally:

```bash
# Deploy to Base Sepolia
source .env

forge script script/Deploy.s.sol \
  --rpc-url $RPC_URL_BASE_SEPOLIA \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --slow \
  --etherscan-api-key $API_KEY_BASESCAN
```

## Troubleshooting

### "Forge not found"
- Make sure Foundry is installed: `foundryup`
- Check PATH: `echo $PATH`
- Restart terminal after installation

### "Private key not found"
- Make sure `.env` file exists
- Check variable name matches script (PRIVATE_KEY_ANVIL vs PRIVATE_KEY)
- Run `source .env` before deploying

### "RPC URL error"
- Check your internet connection
- Verify RPC URL is correct
- Try a different RPC provider

### "Insufficient funds"
- Get testnet ETH from faucet:
  - Base Sepolia: https://www.coinbase.com/faucets/base-ethereum-goerli-faucet
  - Or use: https://faucet.quicknode.com/base/sepolia

## Next Steps

Once setup is complete:
1. ✅ Build contracts: `forge build`
2. ✅ Deploy Diamond: `forge script script/Deploy.s.sol ...`
3. ✅ Deploy SelfRepayingLoanFacet: `forge script script/DeploySelfRepayingLoanFacet.s.sol ...`
4. ✅ Initialize facet: Call `initialize()` function
5. ✅ Test the facet!

