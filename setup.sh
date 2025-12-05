#!/bin/bash

# Setup script for Blokathon Foundry project

echo "🚀 Setting up Blokathon Foundry environment..."
echo ""

# Check if Foundry is installed
if ! command -v forge &> /dev/null; then
    echo "❌ Foundry is not installed!"
    echo ""
    echo "Installing Foundry..."
    curl -L https://foundry.paradigm.xyz | bash
    foundryup
    echo ""
    echo "✅ Foundry installed! Please restart your terminal and run this script again."
    exit 0
else
    echo "✅ Foundry is installed"
    forge --version
fi

echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ .env file not found!"
    echo "Creating .env from template..."
    cp .envExample .env
    echo "✅ .env file created. Please edit it with your credentials!"
else
    echo "✅ .env file exists"
fi

echo ""

# Check if dependencies are installed
if [ ! -d "lib" ] || [ -z "$(ls -A lib)" ]; then
    echo "📦 Installing dependencies..."
    forge install
    echo "✅ Dependencies installed"
else
    echo "✅ Dependencies already installed"
fi

echo ""

# Try to build
echo "🔨 Testing compilation..."
if forge build 2>&1 | grep -q "Error"; then
    echo "❌ Compilation failed! Check the errors above."
    exit 1
else
    echo "✅ Compilation successful!"
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit .env file with your private key and API keys"
echo "2. Source the environment: source .env"
echo "3. Start Anvil: anvil (in a separate terminal)"
echo "4. Deploy: forge script script/Deploy.s.sol --rpc-url \$RPC_URL_ANVIL --private-key \$PRIVATE_KEY_ANVIL --broadcast"

