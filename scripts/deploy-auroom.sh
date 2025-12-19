#!/bin/bash

# Productive Gold Platform (AuRoom) - Automated Deployment Script
# This script deploys all AuRoom contracts to Mantle Testnet

set -e  # Exit on error

echo "=============================================="
echo "AuRoom Platform - Automated Deployment"
echo "=============================================="
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found!"
    echo "Please copy .env.example to .env and configure it."
    exit 1
fi

# Load environment variables
source .env

# Validate required environment variables
if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ Error: PRIVATE_KEY not set in .env"
    exit 1
fi

if [ -z "$MANTLE_TESTNET_RPC" ]; then
    echo "❌ Error: MANTLE_TESTNET_RPC not set in .env"
    exit 1
fi

if [ -z "$UNISWAP_ROUTER" ] || [ "$UNISWAP_ROUTER" = "0x0000000000000000000000000000000000000000" ]; then
    echo "❌ Error: UNISWAP_ROUTER not set in .env"
    echo ""
    echo "Please deploy DEX first using:"
    echo "  ./scripts/deploy-dex.sh"
    echo ""
    echo "Then update UNISWAP_ROUTER in .env with the deployed router address"
    exit 1
fi

echo "✅ Environment validated"
echo "   Network: Mantle Testnet"
echo "   RPC: $MANTLE_TESTNET_RPC"
echo "   Uniswap Router: $UNISWAP_ROUTER"
echo ""

# Create deployments directory
mkdir -p deployments

echo "=============================================="
echo "Deploying AuRoom Contracts..."
echo "=============================================="
echo ""

# Deploy contracts
forge script script/DeployAuRoom.s.sol \
    --rpc-url $MANTLE_TESTNET_RPC \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify \
    -vvvv

DEPLOY_STATUS=$?

if [ $DEPLOY_STATUS -eq 0 ]; then
    echo ""
    echo "=============================================="
    echo "✅ Deployment Successful!"
    echo "=============================================="
    echo ""
    echo "Check deployments/auroom-mantle-testnet.json for contract addresses"
    echo ""
    echo "Next steps:"
    echo "1. Create Uniswap V2 pairs (IDRX/USDC, USDC/XAUT)"
    echo "2. Add initial liquidity"
    echo "3. Test the platform"
    echo ""
else
    echo ""
    echo "=============================================="
    echo "❌ Deployment Failed!"
    echo "=============================================="
    echo ""
    echo "Please check the error messages above"
    exit 1
fi
