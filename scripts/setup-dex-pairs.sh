#!/bin/bash

# DEX Pairs Setup Script for Mantle Sepolia
# This script creates trading pairs and adds initial liquidity

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

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}DEX Pairs Setup - Mantle Sepolia${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    exit 1
fi

# Load environment variables
source .env

# Validate required environment variables
if [ -z "$PRIVATE_KEY" ]; then
    echo -e "${RED}Error: PRIVATE_KEY not set in .env${NC}"
    exit 1
fi

if [ -z "$UNISWAP_FACTORY" ]; then
    echo -e "${RED}Error: UNISWAP_FACTORY not set in .env${NC}"
    echo "Please deploy Uniswap V2 first using ./scripts/deploy-uniswap.sh"
    exit 1
fi

if [ -z "$UNISWAP_ROUTER" ]; then
    echo -e "${RED}Error: UNISWAP_ROUTER not set in .env${NC}"
    echo "Please deploy Uniswap V2 first using ./scripts/deploy-uniswap.sh"
    exit 1
fi

# Token addresses
IDRX="0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05"
USDC="0x96ABff3a2668B811371d7d763f06B3832CEdf38d"
XAUT="0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78"

DEPLOYER=$(cast wallet address --private-key $PRIVATE_KEY)
echo -e "${GREEN}Deployer:${NC} $DEPLOYER"
echo -e "${GREEN}Factory:${NC} $UNISWAP_FACTORY"
echo -e "${GREEN}Router:${NC} $UNISWAP_ROUTER"
echo ""
echo -e "${YELLOW}Token Addresses:${NC}"
echo "  IDRX: $IDRX"
echo "  USDC: $USDC"
echo "  XAUT: $XAUT"
echo ""

# Check token balances
echo -e "${YELLOW}Checking token balances...${NC}"

IDRX_BALANCE=$(cast call $IDRX "balanceOf(address)(uint256)" $DEPLOYER --rpc-url $RPC_URL)
USDC_BALANCE=$(cast call $USDC "balanceOf(address)(uint256)" $DEPLOYER --rpc-url $RPC_URL)
XAUT_BALANCE=$(cast call $XAUT "balanceOf(address)(uint256)" $DEPLOYER --rpc-url $RPC_URL)

echo "  IDRX Balance: $IDRX_BALANCE (need: 100000000 = 1M IDRX)"
echo "  USDC Balance: $USDC_BALANCE (need: 335000000000 = 335K USDC)"
echo "  XAUT Balance: $XAUT_BALANCE (need: 100000000 = 100 XAUT)"
echo ""

# Warning about liquidity amounts
echo -e "${YELLOW}This will create the following pairs and add liquidity:${NC}"
echo ""
echo "  1. IDRX/USDC Pair"
echo "     - 1,000,000 IDRX (1M)"
echo "     - 65,000 USDC"
echo ""
echo "  2. XAUT/USDC Pair"
echo "     - 100 XAUT"
echo "     - 270,000 USDC"
echo ""
echo -e "${RED}WARNING: Make sure you have enough token balances!${NC}"
echo ""

read -p "Continue? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled"
    exit 1
fi

# Run the setup script
echo ""
echo -e "${BLUE}Creating pairs and adding liquidity...${NC}"

forge script script/SetupDEXPairs.s.sol:SetupDEXPairs \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    -vvvv

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}DEX Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Trading pairs are now ready to use!"
echo "You can now trade IDRX/USDC and XAUT/USDC on Uniswap V2"
