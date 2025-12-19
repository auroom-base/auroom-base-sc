#!/bin/bash

# DEX Deployment Script for Mantle Sepolia
# This script deploys WMNT, UniswapV2Factory, and UniswapV2Router02

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Load environment
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | xargs)
else
    echo -e "${RED}Error: .env file not found${NC}"
    exit 1
fi

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Uniswap V2 DEX Deployment${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# Get deployer address
DEPLOYER=$(cast wallet address $PRIVATE_KEY)
echo -e "Deployer: ${GREEN}$DEPLOYER${NC}"
echo -e "RPC: ${YELLOW}$MANTLE_TESTNET_RPC${NC}"
echo ""

# Check balance
BALANCE=$(cast balance $DEPLOYER --rpc-url $MANTLE_TESTNET_RPC)
BALANCE_ETH=$(cast to-unit $BALANCE ether)
echo -e "Balance: ${GREEN}$BALANCE_ETH MNT${NC}"
echo ""

if [ "$(echo "$BALANCE_ETH < 0.1" | bc)" -eq 1 ]; then
    echo -e "${YELLOW}Warning: Low balance. Get testnet MNT from faucet.${NC}"
    echo "https://faucet.sepolia.mantle.xyz/"
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Step 1: Deploy WMNT${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# Deploy WMNT
forge script script/DeployDEX.s.sol \
    --rpc-url $MANTLE_TESTNET_RPC \
    --broadcast \
    -vvv

# Extract WMNT address
WMNT_ADDRESS=$(jq -r '.WMNT' deployments/wmnt-mantle-sepolia.json)
echo ""
echo -e "${GREEN}WMNT deployed at: $WMNT_ADDRESS${NC}"
echo ""

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Step 2: Deploy UniswapV2Factory${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# Deploy Factory
echo "Deploying Factory with feeToSetter=$DEPLOYER..."
FACTORY_OUTPUT=$(forge create lib/uniswap-v2-core/contracts/UniswapV2Factory.sol:UniswapV2Factory \
    --rpc-url $MANTLE_TESTNET_RPC \
    --private-key $PRIVATE_KEY \
    --constructor-args $DEPLOYER \
    --legacy \
    2>&1)

echo "$FACTORY_OUTPUT"

# Extract Factory address
FACTORY_ADDRESS=$(echo "$FACTORY_OUTPUT" | grep "Deployed to:" | awk '{print $3}')

if [ -z "$FACTORY_ADDRESS" ]; then
    echo -e "${RED}Error: Failed to deploy Factory${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Factory deployed at: $FACTORY_ADDRESS${NC}"
echo ""

# Wait for transaction to be mined
echo "Waiting for transaction to be mined..."
sleep 10

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Step 3: Get INIT_CODE_HASH${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# Get INIT_CODE_HASH (this is a constant in Uniswap V2)
INIT_CODE_HASH="0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f"
echo -e "INIT_CODE_HASH: ${YELLOW}$INIT_CODE_HASH${NC}"
echo ""

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Step 4: Deploy UniswapV2Router02${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# Deploy Router
echo "Deploying Router with factory=$FACTORY_ADDRESS, WMNT=$WMNT_ADDRESS..."
ROUTER_OUTPUT=$(forge create lib/uniswap-v2-periphery/contracts/UniswapV2Router02.sol:UniswapV2Router02 \
    --rpc-url $MANTLE_TESTNET_RPC \
    --private-key $PRIVATE_KEY \
    --constructor-args $FACTORY_ADDRESS $WMNT_ADDRESS \
    --legacy \
    2>&1)

echo "$ROUTER_OUTPUT"

# Extract Router address
ROUTER_ADDRESS=$(echo "$ROUTER_OUTPUT" | grep "Deployed to:" | awk '{print $3}')

if [ -z "$ROUTER_ADDRESS" ]; then
    echo -e "${RED}Error: Failed to deploy Router${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Router deployed at: $ROUTER_ADDRESS${NC}"
echo ""

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Step 5: Save Addresses${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# Save addresses using the UpdateDEXAddresses script
export WMNT_ADDRESS=$WMNT_ADDRESS
export FACTORY_ADDRESS=$FACTORY_ADDRESS
export ROUTER_ADDRESS=$ROUTER_ADDRESS
export INIT_CODE_HASH=$INIT_CODE_HASH
export DEPLOYER_ADDRESS=$DEPLOYER

forge script script/UpdateDEXAddresses.s.sol

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Deployment Summary${NC}"
echo -e "${GREEN}======================================${NC}"
echo -e "WMNT:              ${YELLOW}$WMNT_ADDRESS${NC}"
echo -e "Factory:           ${YELLOW}$FACTORY_ADDRESS${NC}"
echo -e "Router:            ${YELLOW}$ROUTER_ADDRESS${NC}"
echo -e "INIT_CODE_HASH:    ${YELLOW}$INIT_CODE_HASH${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

echo -e "${GREEN}Addresses saved to: deployments/dex-mantle-sepolia.json${NC}"
echo ""

echo -e "${YELLOW}Next steps:${NC}"
echo "1. Verify contracts: ./scripts/verify-dex.sh"
echo "2. Test DEX: create pair and add liquidity"
echo "3. Update script/Deploy.s.sol with Router address"
echo "4. Deploy AuRoom Protocol"
echo ""

echo -e "${GREEN}Deployment completed successfully!${NC}"
