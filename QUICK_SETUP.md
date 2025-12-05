# ⚡ Quick Setup Checklist

## ✅ Step 1: Install Foundry

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Verify
forge --version
```

## ✅ Step 2: Run Setup Script

```bash
# Run the automated setup
./setup.sh
```

Or manually:

```bash
# Install dependencies
forge install

# Build contracts
forge build
```

## ✅ Step 3: Configure Environment

Edit `.env` file with your credentials:

```bash
# For testnet deployment, you need:
PRIVATE_KEY=0x...your_private_key_here

# For verification (optional but recommended):
API_KEY_BASESCAN=your_api_key_here
```

**Where to get these:**

1. **Private Key**: 
   - Create a test wallet in MetaMask
   - Export private key (Settings → Security → Show Private Key)
   - ⚠️ **NEVER use mainnet private key! Use testnet only!**

2. **Basescan API Key**:
   - Go to https://basescan.org/
   - Sign up → Account → API Keys
   - Create new API key

3. **RPC URL** (already set, but you can use better ones):
   - Free: `https://sepolia.base.org` (already in .env)
   - Better: Get from Alchemy/Infura (faster, more reliable)

## ✅ Step 4: Test Locally

```bash
# Terminal 1: Start Anvil (local blockchain)
anvil

# Terminal 2: Deploy to Anvil
source .env
forge script script/Deploy.s.sol \
  --rpc-url $RPC_URL_ANVIL \
  --private-key $PRIVATE_KEY_ANVIL \
  --broadcast
```

## ✅ Step 5: Deploy to Base Sepolia (Testnet)

```bash
# Make sure you have testnet ETH
# Get it from: https://www.coinbase.com/faucets/base-ethereum-goerli-faucet

# Deploy
source .env
forge script script/Deploy.s.sol \
  --rpc-url $RPC_URL_BASE_SEPOLIA \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --slow \
  --etherscan-api-key $API_KEY_BASESCAN
```

## 🎯 What You Need

- [ ] Foundry installed (`forge --version` works)
- [ ] `.env` file configured with your private key
- [ ] Testnet ETH (for Base Sepolia deployment)
- [ ] Basescan API key (for contract verification)

## 🚨 Important Notes

1. **Never commit `.env` to git** - it contains your private key!
2. **Use testnet only** for development
3. **Keep your private key secure** - never share it
4. **Test locally first** before deploying to testnet

## 📝 Current Status

- ✅ Environment file created (`.env`)
- ✅ Setup script created (`setup.sh`)
- ✅ Self-Repaying Loan facet code complete
- ⏳ Need to: Install Foundry, configure .env, deploy!

## 🆘 Troubleshooting

**"Forge not found"**
```bash
foundryup  # Update Foundry
```

**"Private key error"**
- Check `.env` file exists
- Make sure variable name matches: `PRIVATE_KEY_ANVIL` or `PRIVATE_KEY`
- Run `source .env` before deploying

**"Insufficient funds"**
- Get testnet ETH from faucet
- Check you're using the right network

**"RPC error"**
- Check internet connection
- Try different RPC URL
- Wait a moment and retry

