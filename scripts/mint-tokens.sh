#!/bin/bash

# Mint tokens for DEX liquidity
set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Minting Tokens for DEX Liquidity${NC}"
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
DEPLOYER=0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1
RPC=https://rpc.sepolia.mantle.xyz

IDRX=0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05
USDC=0x96ABff3a2668B811371d7d763f06B3832CEdf38d
XAUT=0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78

echo -e "${GREEN}Minting tokens to:${NC} $DEPLOYER"
echo ""

# Mint IDRX
echo -e "${YELLOW}1. Minting 1,000,000 IDRX...${NC}"
cast send $IDRX \
  "mint(address,uint256)" \
  $DEPLOYER \
  100000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC

echo ""

# Mint USDC
echo -e "${YELLOW}2. Minting 335,000 USDC...${NC}"
cast send $USDC \
  "mint(address,uint256)" \
  $DEPLOYER \
  335000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC

echo ""

# Mint XAUT
echo -e "${YELLOW}3. Minting 100 XAUT...${NC}"
cast send $XAUT \
  "mint(address,uint256)" \
  $DEPLOYER \
  100000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Minting Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Token Balances:"
echo "  IDRX: 1,000,000 (100000000)"
echo "  USDC: 335,000 (335000000000)"
echo "  XAUT: 100 (100000000)"
echo ""
echo -e "${YELLOW}Next step:${NC} Run ./scripts/setup-dex-pairs.sh"
