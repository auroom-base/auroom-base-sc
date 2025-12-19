#!/bin/bash

# Uniswap V2 Deployment Script for Mantle Sepolia
# This script deploys WMNT, UniswapV2Factory, and UniswapV2Router02

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Network configuration
NETWORK="mantle-sepolia"
RPC_URL="https://rpc.sepolia.mantle.xyz"
CHAIN_ID=5003
EXPLORER="https://sepolia.mantlescan.xyz"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Uniswap V2 Deployment to Mantle Sepolia${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    echo "Please create .env file with PRIVATE_KEY"
    exit 1
fi

# Load environment variables
source .env

if [ -z "$PRIVATE_KEY" ]; then
    echo -e "${RED}Error: PRIVATE_KEY not set in .env${NC}"
    exit 1
fi

# Get deployer address
DEPLOYER=$(cast wallet address --private-key $PRIVATE_KEY)
echo -e "${GREEN}Deployer:${NC} $DEPLOYER"

# Check balance
BALANCE=$(cast balance $DEPLOYER --rpc-url $RPC_URL)
echo -e "${GREEN}Balance:${NC} $BALANCE wei"

if [ "$BALANCE" = "0" ]; then
    echo -e "${RED}Error: Deployer has no MNT. Please fund the account.${NC}"
    echo "Get testnet MNT from: https://faucet.sepolia.mantle.xyz"
    exit 1
fi

echo ""
echo -e "${YELLOW}Step 1: Deploying Uniswap V2 Infrastructure${NC}"
echo "This will deploy:"
echo "  1. WMNT (Wrapped MNT)"
echo "  2. UniswapV2Factory"
echo "  3. UniswapV2Router02"
echo ""

read -p "Continue? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled"
    exit 1
fi

# Deploy using Foundry script
echo ""
echo -e "${BLUE}Deploying contracts...${NC}"

forge script script/DeployUniswapV2.s.sol:DeployUniswapV2 \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $MANTLESCAN_API_KEY \
    -vvvv

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Note down the deployed contract addresses"
echo "2. Update .env with UNISWAP_FACTORY and UNISWAP_ROUTER addresses"
echo "3. Run ./scripts/setup-dex-pairs.sh to create pairs and add liquidity"
echo ""
echo -e "${YELLOW}View on Explorer:${NC} $EXPLORER"
