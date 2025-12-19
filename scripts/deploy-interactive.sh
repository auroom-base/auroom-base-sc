#!/bin/bash

# AuRoom Platform - Interactive Deployment
# This script uses interactive mode for safer key handling

set -e

echo "=============================================="
echo "AuRoom - Interactive Deployment"
echo "=============================================="
echo ""

# Load RPC URL from .env
if [ -f .env ]; then
    source .env
fi

if [ -z "$MANTLE_TESTNET_RPC" ]; then
    echo "❌ Error: MANTLE_TESTNET_RPC not set in .env"
    exit 1
fi

echo "Network: Mantle Sepolia Testnet"
echo "RPC: $MANTLE_TESTNET_RPC"
echo ""

# Create deployments directory
mkdir -p deployments

echo "=============================================="
echo "Step 1: Deploy DEX (Uniswap V2)"
echo "=============================================="
echo ""

read -p "Deploy DEX? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Deploying DEX with interactive mode..."
    echo ""

    # Deploy WMNT
    echo "Deploying WMNT..."
    forge script script/DeployDEX.s.sol \
        --rpc-url $MANTLE_TESTNET_RPC \
        --broadcast \
        --interactive 1

    echo ""
    echo "✅ DEX deployment initiated!"
    echo ""
    echo "IMPORTANT: Copy the Router address from the deployment output above"
    echo "           and update .env manually:"
    echo ""
    echo "UNISWAP_ROUTER=0x<router-address>"
    echo ""
    read -p "Press Enter once you've updated .env..."
fi

echo ""
echo "=============================================="
echo "Step 2: Deploy AuRoom Contracts"
echo "=============================================="
echo ""

# Reload .env to get updated UNISWAP_ROUTER
source .env

if [ -z "$UNISWAP_ROUTER" ] || [ "$UNISWAP_ROUTER" = "0x0000000000000000000000000000000000000000" ]; then
    echo "❌ Error: UNISWAP_ROUTER not set in .env"
    echo "Please update .env with the Router address from Step 1"
    exit 1
fi

echo "Using Uniswap Router: $UNISWAP_ROUTER"
echo ""

read -p "Deploy AuRoom contracts? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Deploying AuRoom with interactive mode..."
    echo ""

    forge script script/DeployAuRoom.s.sol \
        --rpc-url $MANTLE_TESTNET_RPC \
        --broadcast \
        --interactive 1

    echo ""
    echo "✅ AuRoom deployment complete!"
fi

echo ""
echo "=============================================="
echo "Step 3: Setup Liquidity"
echo "=============================================="
echo ""

read -p "Setup liquidity pools? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "⚠️  Note: Liquidity setup requires multiple transactions"
    echo "You'll need to sign each transaction"
    echo ""
    read -p "Continue? (y/n) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Load deployment addresses
        DEPLOYMENT_FILE="deployments/auroom-mantle-testnet.json"

        if [ ! -f "$DEPLOYMENT_FILE" ]; then
            echo "❌ Error: Deployment file not found!"
            echo "Please deploy contracts first"
            exit 1
        fi

        IDRX=$(jq -r '.MockIDRX' $DEPLOYMENT_FILE)
        USDC=$(jq -r '.MockUSDC' $DEPLOYMENT_FILE)
        XAUT=$(jq -r '.XAUT' $DEPLOYMENT_FILE)
        ROUTER=$(jq -r '.UniswapRouter' $DEPLOYMENT_FILE)

        echo "Setting up liquidity for:"
        echo "  IDRX: $IDRX"
        echo "  USDC: $USDC"
        echo "  XAUT: $XAUT"
        echo ""

        # Amounts
        IDRX_AMOUNT="1000000000000"
        USDC_AMOUNT="1000000000000"
        XAUT_AMOUNT="10000000000"

        echo "1. Minting IDRX..."
        cast send $IDRX \
            "publicMint(address,uint256)" \
            --rpc-url $MANTLE_TESTNET_RPC \
            --interactive 1 \
            $(cast wallet address --interactive 1) \
            $IDRX_AMOUNT

        echo "2. Minting USDC..."
        cast send $USDC \
            "publicMint(address,uint256)" \
            --rpc-url $MANTLE_TESTNET_RPC \
            --interactive 1 \
            $(cast wallet address --interactive 1) \
            $USDC_AMOUNT

        echo "3. Minting XAUT..."
        cast send $XAUT \
            "mint(address,uint256)" \
            --rpc-url $MANTLE_TESTNET_RPC \
            --interactive 1 \
            $(cast wallet address --interactive 1) \
            $XAUT_AMOUNT

        echo ""
        echo "✅ Tokens minted!"
        echo ""
        echo "Note: For adding liquidity, please use the Uniswap interface or run individual commands"
        echo "See DEPLOYMENT.md for manual liquidity setup instructions"
    fi
fi

echo ""
echo "=============================================="
echo "✅ Deployment Complete!"
echo "=============================================="
echo ""
echo "Next steps:"
echo "1. Verify contracts on explorer (optional)"
echo "2. Add liquidity to pools (if not done)"
echo "3. Test the platform"
echo ""
echo "See DEPLOYMENT.md for detailed instructions"
echo ""
