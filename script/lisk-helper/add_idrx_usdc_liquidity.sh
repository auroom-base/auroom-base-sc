#!/bin/bash

# Add IDRX/USDC Liquidity Script
# This script adds liquidity to the IDRX/USDC pair

# Load environment variables
source .env

echo "=============================================="
echo "Adding IDRX/USDC Liquidity"
echo "=============================================="
echo "IDRX: $MOCK_IDRX"
echo "USDC: $MOCK_USDC"
echo "Router: $UNISWAP_ROUTER"
echo ""

# Amounts
IDRX_AMOUNT="1000000000000000"  # 1B IDRX (with 6 decimals)
USDC_AMOUNT="60606000000"        # 60,606 USDC (with 6 decimals)

echo "Step 1: Minting IDRX..."
cast send $MOCK_IDRX \
  "publicMint(address,uint256)" \
  $DEPLOYER \
  $IDRX_AMOUNT \
  --rpc-url $LISK_TESTNET_RPC \
  --private-key $PRIVATE_KEY \
  --legacy

echo ""
echo "Step 2: Minting USDC..."
cast send $MOCK_USDC \
  "publicMint(address,uint256)" \
  $DEPLOYER \
  $USDC_AMOUNT \
  --rpc-url $LISK_TESTNET_RPC \
  --private-key $PRIVATE_KEY \
  --legacy

echo ""
echo "Step 3: Approving IDRX..."
cast send $MOCK_IDRX \
  "approve(address,uint256)" \
  $UNISWAP_ROUTER \
  115792089237316195423570985008687907853269984665640564039457584007913129639935 \
  --rpc-url $LISK_TESTNET_RPC \
  --private-key $PRIVATE_KEY \
  --legacy

echo ""
echo "Step 4: Approving USDC..."
cast send $MOCK_USDC \
  "approve(address,uint256)" \
  $UNISWAP_ROUTER \
  115792089237316195423570985008687907853269984665640564039457584007913129639935 \
  --rpc-url $LISK_TESTNET_RPC \
  --private-key $PRIVATE_KEY \
  --legacy

echo ""
echo "Step 5: Adding liquidity..."
cast send $UNISWAP_ROUTER \
  "addLiquidity(address,address,uint256,uint256,uint256,uint256,address,uint256)" \
  $MOCK_IDRX \
  $MOCK_USDC \
  $IDRX_AMOUNT \
  $USDC_AMOUNT \
  0 \
  0 \
  $DEPLOYER \
  $(($(date +%s) + 300)) \
  --rpc-url $LISK_TESTNET_RPC \
  --private-key $PRIVATE_KEY \
  --legacy

echo ""
echo "=============================================="
echo "LIQUIDITY ADDED SUCCESSFULLY!"
echo "=============================================="
echo "Ratio: 1 USDC = 16,500 IDRX"
echo "IDRX: 1,000,000,000"
echo "USDC: 60,606"
echo "=============================================="
