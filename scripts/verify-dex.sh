#!/bin/bash

# DEX Verification Script for Mantle Sepolia

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Load environment
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | xargs)
fi

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Verifying DEX Contracts${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# Check if deployment file exists
if [ ! -f "deployments/dex-mantle-sepolia.json" ]; then
    echo -e "${RED}Error: deployments/dex-mantle-sepolia.json not found${NC}"
    echo "Please deploy DEX first using: ./scripts/deploy-dex.sh"
    exit 1
fi

# Read addresses from deployment file
WMNT_ADDRESS=$(jq -r '.WMNT' deployments/dex-mantle-sepolia.json)
FACTORY_ADDRESS=$(jq -r '.UniswapV2Factory' deployments/dex-mantle-sepolia.json)
ROUTER_ADDRESS=$(jq -r '.UniswapV2Router02' deployments/dex-mantle-sepolia.json)
DEPLOYER=$(jq -r '.deployer' deployments/dex-mantle-sepolia.json)

echo "WMNT:     $WMNT_ADDRESS"
echo "Factory:  $FACTORY_ADDRESS"
echo "Router:   $ROUTER_ADDRESS"
echo "Deployer: $DEPLOYER"
echo ""

# Verify WMNT
echo -e "${YELLOW}Verifying WMNT...${NC}"
forge verify-contract $WMNT_ADDRESS \
    src/WMNT.sol:WMNT \
    --chain-id 5003 \
    --watch \
    || echo -e "${RED}WMNT verification failed (may already be verified)${NC}"

echo ""

# Verify Factory
echo -e "${YELLOW}Verifying UniswapV2Factory...${NC}"
FACTORY_CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(address)" $DEPLOYER)

forge verify-contract $FACTORY_ADDRESS \
    lib/uniswap-v2-core/contracts/UniswapV2Factory.sol:UniswapV2Factory \
    --chain-id 5003 \
    --constructor-args $FACTORY_CONSTRUCTOR_ARGS \
    --watch \
    || echo -e "${RED}Factory verification failed (may already be verified)${NC}"

echo ""

# Verify Router
echo -e "${YELLOW}Verifying UniswapV2Router02...${NC}"
ROUTER_CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(address,address)" $FACTORY_ADDRESS $WMNT_ADDRESS)

forge verify-contract $ROUTER_ADDRESS \
    lib/uniswap-v2-periphery/contracts/UniswapV2Router02.sol:UniswapV2Router02 \
    --chain-id 5003 \
    --constructor-args $ROUTER_CONSTRUCTOR_ARGS \
    --watch \
    || echo -e "${RED}Router verification failed (may already be verified)${NC}"

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Verification Complete${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

echo "View contracts on Mantle Sepolia Explorer:"
echo "WMNT:    https://sepolia.mantlescan.xyz/address/$WMNT_ADDRESS"
echo "Factory: https://sepolia.mantlescan.xyz/address/$FACTORY_ADDRESS"
echo "Router:  https://sepolia.mantlescan.xyz/address/$ROUTER_ADDRESS"
echo ""
