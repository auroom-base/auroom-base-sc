#!/bin/bash

# Setup Initial Liquidity Pools for AuRoom Platform
# Creates pairs and adds initial liquidity for IDRX/USDC and USDC/XAUT

set -e

echo "=============================================="
echo "AuRoom - Liquidity Pool Setup"
echo "=============================================="
echo ""

# Load environment
source .env

# Load deployment addresses
DEPLOYMENT_FILE="deployments/auroom-mantle-testnet.json"

if [ ! -f "$DEPLOYMENT_FILE" ]; then
    echo "❌ Error: Deployment file not found!"
    echo "Please deploy contracts first using:"
    echo "  ./scripts/deploy-auroom.sh"
    exit 1
fi

# Extract addresses from JSON
IDRX=$(jq -r '.MockIDRX' $DEPLOYMENT_FILE)
USDC=$(jq -r '.MockUSDC' $DEPLOYMENT_FILE)
XAUT=$(jq -r '.XAUT' $DEPLOYMENT_FILE)
ROUTER=$(jq -r '.UniswapRouter' $DEPLOYMENT_FILE)
DEPLOYER=$(jq -r '.deployer' $DEPLOYMENT_FILE)

echo "Loaded Contract Addresses:"
echo "  IDRX:   $IDRX"
echo "  USDC:   $USDC"
echo "  XAUT:   $XAUT"
echo "  Router: $ROUTER"
echo ""

# Amounts for liquidity (6 decimals)
IDRX_AMOUNT="1000000000000"  # 1M IDRX
USDC_AMOUNT="1000000000000"  # 1M USDC
XAUT_AMOUNT="10000000000"    # 10K XAUT

echo "=============================================="
echo "Step 1: Minting Initial Tokens"
echo "=============================================="
echo ""

# Mint IDRX
echo "Minting IDRX..."
cast send $IDRX "publicMint(address,uint256)" $DEPLOYER $IDRX_AMOUNT \
    --rpc-url $MANTLE_TESTNET_RPC \
    --private-key $PRIVATE_KEY

# Mint USDC
echo "Minting USDC..."
cast send $USDC "publicMint(address,uint256)" $DEPLOYER $USDC_AMOUNT \
    --rpc-url $MANTLE_TESTNET_RPC \
    --private-key $PRIVATE_KEY

# Mint XAUT
echo "Minting XAUT..."
cast send $XAUT "mint(address,uint256)" $DEPLOYER $XAUT_AMOUNT \
    --rpc-url $MANTLE_TESTNET_RPC \
    --private-key $PRIVATE_KEY

echo "✅ Tokens minted successfully"
echo ""

echo "=============================================="
echo "Step 2: Approving Router"
echo "=============================================="
echo ""

# Approve IDRX
echo "Approving IDRX..."
cast send $IDRX "approve(address,uint256)" $ROUTER $IDRX_AMOUNT \
    --rpc-url $MANTLE_TESTNET_RPC \
    --private-key $PRIVATE_KEY

# Approve USDC
echo "Approving USDC..."
cast send $USDC "approve(address,uint256)" $ROUTER $USDC_AMOUNT \
    --rpc-url $MANTLE_TESTNET_RPC \
    --private-key $PRIVATE_KEY

# Approve XAUT
echo "Approving XAUT..."
cast send $XAUT "approve(address,uint256)" $ROUTER $XAUT_AMOUNT \
    --rpc-url $MANTLE_TESTNET_RPC \
    --private-key $PRIVATE_KEY

echo "✅ Router approved for all tokens"
echo ""

echo "=============================================="
echo "Step 3: Adding Liquidity - IDRX/USDC"
echo "=============================================="
echo ""

# Calculate deadline (current timestamp + 20 minutes)
DEADLINE=$(($(date +%s) + 1200))

# Add liquidity for IDRX/USDC
echo "Adding IDRX/USDC liquidity..."
cast send $ROUTER \
    "addLiquidity(address,address,uint256,uint256,uint256,uint256,address,uint256)" \
    $IDRX \
    $USDC \
    $IDRX_AMOUNT \
    $USDC_AMOUNT \
    0 \
    0 \
    $DEPLOYER \
    $DEADLINE \
    --rpc-url $MANTLE_TESTNET_RPC \
    --private-key $PRIVATE_KEY \
    --gas-limit 5000000

echo "✅ IDRX/USDC liquidity added"
echo ""

echo "=============================================="
echo "Step 4: Adding Liquidity - USDC/XAUT"
echo "=============================================="
echo ""

# Mint more USDC for second pair
echo "Minting additional USDC..."
cast send $USDC "publicMint(address,uint256)" $DEPLOYER $USDC_AMOUNT \
    --rpc-url $MANTLE_TESTNET_RPC \
    --private-key $PRIVATE_KEY

# Approve additional USDC
echo "Approving additional USDC..."
cast send $USDC "approve(address,uint256)" $ROUTER $USDC_AMOUNT \
    --rpc-url $MANTLE_TESTNET_RPC \
    --private-key $PRIVATE_KEY

# Add liquidity for USDC/XAUT
echo "Adding USDC/XAUT liquidity..."
cast send $ROUTER \
    "addLiquidity(address,address,uint256,uint256,uint256,uint256,address,uint256)" \
    $USDC \
    $XAUT \
    $USDC_AMOUNT \
    $XAUT_AMOUNT \
    0 \
    0 \
    $DEPLOYER \
    $DEADLINE \
    --rpc-url $MANTLE_TESTNET_RPC \
    --private-key $PRIVATE_KEY \
    --gas-limit 5000000

echo "✅ USDC/XAUT liquidity added"
echo ""

echo "=============================================="
echo "✅ Liquidity Setup Complete!"
echo "=============================================="
echo ""
echo "Liquidity Pools Created:"
echo "  1. IDRX/USDC - 1M IDRX : 1M USDC"
echo "  2. USDC/XAUT - 1M USDC : 10K XAUT"
echo ""
echo "Platform is now ready for swaps!"
echo ""
