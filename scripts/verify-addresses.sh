#!/bin/bash

# Verify addresses in IdentityRegistry for XAUT transfers
set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Verifying Addresses in IdentityRegistry${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Load .env
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    exit 1
fi

source .env

if [ -z "$PRIVATE_KEY" ]; then
    echo -e "${RED}Error: PRIVATE_KEY not set in .env${NC}"
    exit 1
fi

# Addresses
IDENTITY_REGISTRY=0x620870d419F6aFca8AFed5B516619aa50900cadc
DEPLOYER=0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1
PAIR_XAUT_USDC=0xc2da5178F53f45f604A275a3934979944eB15602
RPC=https://rpc.sepolia.mantle.xyz

echo -e "${GREEN}IdentityRegistry:${NC} $IDENTITY_REGISTRY"
echo ""

# Verify deployer
echo -e "${YELLOW}1. Verifying deployer address...${NC}"
echo "   Address: $DEPLOYER"
cast send $IDENTITY_REGISTRY \
  "addVerifiedUser(address)" \
  $DEPLOYER \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC

echo ""

# Verify XAUT/USDC pair
echo -e "${YELLOW}2. Verifying XAUT/USDC pair contract...${NC}"
echo "   Address: $PAIR_XAUT_USDC"
cast send $IDENTITY_REGISTRY \
  "addVerifiedUser(address)" \
  $PAIR_XAUT_USDC \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Verification Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Verified addresses:"
echo "  - Deployer: $DEPLOYER"
echo "  - XAUT/USDC Pair: $PAIR_XAUT_USDC"
echo ""
echo -e "${YELLOW}Next step:${NC} Run setup-dex-pairs script again to add XAUT liquidity"
