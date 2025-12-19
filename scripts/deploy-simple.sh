#!/bin/bash

# AuRoom - Simple Manual Deployment Guide
# This script provides step-by-step commands to copy-paste

cat << 'EOF'
==============================================
 AuRoom Platform - Manual Deployment Guide
==============================================

This guide provides commands to deploy contracts one by one.
You'll be prompted for your private key securely for each deployment.

NETWORK: Mantle Sepolia Testnet
RPC: https://rpc.sepolia.mantle.xyz

==============================================
STEP 1: Deploy Mock Tokens
==============================================

1.1 Deploy MockIDRX:
--------------------
forge create src/MockIDRX.sol:MockIDRX \
  --rpc-url https://rpc.sepolia.mantle.xyz \
  --interactive

📝 Save the deployed address:
export IDRX=<deployed-address>

1.2 Deploy MockUSDC:
--------------------
forge create src/MockUSDC.sol:MockUSDC \
  --rpc-url https://rpc.sepolia.mantle.xyz \
  --interactive

📝 Save the deployed address:
export USDC=<deployed-address>

==============================================
STEP 2: Deploy IdentityRegistry
==============================================

forge create src/IdentityRegistry.sol:IdentityRegistry \
  --rpc-url https://rpc.sepolia.mantle.xyz \
  --interactive

📝 Save the deployed address:
export IDENTITY_REGISTRY=<deployed-address>

==============================================
STEP 3: Deploy XAUT
==============================================

forge create src/XAUT.sol:XAUT \
  --rpc-url https://rpc.sepolia.mantle.xyz \
  --constructor-args $IDENTITY_REGISTRY \
  --interactive

📝 Save the deployed address:
export XAUT=<deployed-address>

==============================================
STEP 4: Deploy Uniswap V2 (if not deployed)
==============================================

4.1 Deploy WMNT:
----------------
forge create src/WMNT.sol:WMNT \
  --rpc-url https://rpc.sepolia.mantle.xyz \
  --interactive

export WMNT=<deployed-address>

4.2 Deploy UniswapV2Factory:
---------------------------
forge create lib/uniswap-v2-core/contracts/UniswapV2Factory.sol:UniswapV2Factory \
  --rpc-url https://rpc.sepolia.mantle.xyz \
  --constructor-args <YOUR_ADDRESS> \
  --legacy \
  --interactive

export FACTORY=<deployed-address>

4.3 Deploy UniswapV2Router02:
----------------------------
forge create lib/uniswap-v2-periphery/contracts/UniswapV2Router02.sol:UniswapV2Router02 \
  --rpc-url https://rpc.sepolia.mantle.xyz \
  --constructor-args $FACTORY $WMNT \
  --legacy \
  --interactive

📝 Save the deployed address:
export UNISWAP_ROUTER=<deployed-address>

==============================================
STEP 5: Deploy GoldVault
==============================================

forge create src/GoldVault.sol:GoldVault \
  --rpc-url https://rpc.sepolia.mantle.xyz \
  --constructor-args $XAUT $IDENTITY_REGISTRY $UNISWAP_ROUTER $USDC \
  --interactive

📝 Save the deployed address:
export GOLD_VAULT=<deployed-address>

==============================================
STEP 6: Deploy SwapRouter
==============================================

forge create src/SwapRouter.sol:SwapRouter \
  --rpc-url https://rpc.sepolia.mantle.xyz \
  --constructor-args $UNISWAP_ROUTER $IDRX $USDC $XAUT \
  --interactive

📝 Save the deployed address:
export SWAP_ROUTER=<deployed-address>

==============================================
STEP 7: Save Addresses to File
==============================================

Create deployments/auroom-mantle-testnet.json manually:

{
  "chainId": 5003,
  "network": "mantle-sepolia",
  "MockIDRX": "$IDRX",
  "MockUSDC": "$USDC",
  "IdentityRegistry": "$IDENTITY_REGISTRY",
  "XAUT": "$XAUT",
  "GoldVault": "$GOLD_VAULT",
  "SwapRouter": "$SWAP_ROUTER",
  "UniswapRouter": "$UNISWAP_ROUTER"
}

Or use this command to create it automatically:

cat > deployments/auroom-mantle-testnet.json << JSON
{
  "chainId": 5003,
  "network": "mantle-sepolia",
  "MockIDRX": "$IDRX",
  "MockUSDC": "$USDC",
  "IdentityRegistry": "$IDENTITY_REGISTRY",
  "XAUT": "$XAUT",
  "GoldVault": "$GOLD_VAULT",
  "SwapRouter": "$SWAP_ROUTER",
  "UniswapRouter": "$UNISWAP_ROUTER"
}
JSON

==============================================
STEP 8: Initial Setup
==============================================

8.1 Register deployer in KYC:
-----------------------------
cast send $IDENTITY_REGISTRY \
  "registerIdentity(address)" \
  <YOUR_ADDRESS> \
  --rpc-url https://rpc.sepolia.mantle.xyz \
  --interactive

8.2 Register contracts in KYC:
------------------------------
cast send $IDENTITY_REGISTRY \
  "registerIdentity(address)" \
  $GOLD_VAULT \
  --rpc-url https://rpc.sepolia.mantle.xyz \
  --interactive

cast send $IDENTITY_REGISTRY \
  "registerIdentity(address)" \
  $SWAP_ROUTER \
  --rpc-url https://rpc.sepolia.mantle.xyz \
  --interactive

==============================================
STEP 9: Setup Liquidity (Optional)
==============================================

9.1 Mint tokens:
---------------
cast send $IDRX \
  "publicMint(address,uint256)" \
  <YOUR_ADDRESS> \
  1000000000000 \
  --rpc-url https://rpc.sepolia.mantle.xyz \
  --interactive

cast send $USDC \
  "publicMint(address,uint256)" \
  <YOUR_ADDRESS> \
  1000000000000 \
  --rpc-url https://rpc.sepolia.mantle.xyz \
  --interactive

cast send $XAUT \
  "mint(address,uint256)" \
  <YOUR_ADDRESS> \
  10000000000 \
  --rpc-url https://rpc.sepolia.mantle.xyz \
  --interactive

9.2 Approve router:
------------------
cast send $IDRX \
  "approve(address,uint256)" \
  $UNISWAP_ROUTER \
  1000000000000 \
  --rpc-url https://rpc.sepolia.mantle.xyz \
  --interactive

cast send $USDC \
  "approve(address,uint256)" \
  $UNISWAP_ROUTER \
  2000000000000 \
  --rpc-url https://rpc.sepolia.mantle.xyz \
  --interactive

cast send $XAUT \
  "approve(address,uint256)" \
  $UNISWAP_ROUTER \
  10000000000 \
  --rpc-url https://rpc.sepolia.mantle.xyz \
  --interactive

9.3 Add liquidity IDRX/USDC:
---------------------------
DEADLINE=$(expr $(date +%s) + 1200)

cast send $UNISWAP_ROUTER \
  "addLiquidity(address,address,uint256,uint256,uint256,uint256,address,uint256)" \
  $IDRX \
  $USDC \
  1000000000000 \
  1000000000000 \
  0 \
  0 \
  <YOUR_ADDRESS> \
  $DEADLINE \
  --rpc-url https://rpc.sepolia.mantle.xyz \
  --gas-limit 5000000 \
  --interactive

9.4 Add liquidity USDC/XAUT:
---------------------------
cast send $UNISWAP_ROUTER \
  "addLiquidity(address,address,uint256,uint256,uint256,uint256,address,uint256)" \
  $USDC \
  $XAUT \
  1000000000000 \
  10000000000 \
  0 \
  0 \
  <YOUR_ADDRESS> \
  $DEADLINE \
  --rpc-url https://rpc.sepolia.mantle.xyz \
  --gas-limit 5000000 \
  --interactive

==============================================
✅ DEPLOYMENT COMPLETE!
==============================================

Your contracts are now deployed to Mantle Sepolia Testnet!

View them on explorer:
https://sepolia.mantlescan.xyz/address/<CONTRACT_ADDRESS>

Test the platform:
See DEPLOYMENT.md for testing instructions

EOF
