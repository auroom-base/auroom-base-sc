#!/bin/bash

# AuRoom Protocol - Deployment Script
# Automated deployment to Mantle Testnet

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | xargs)
else
    echo -e "${RED}Error: .env file not found${NC}"
    echo "Please create .env file from .env.example"
    exit 1
fi

# Check required variables
if [ -z "$PRIVATE_KEY" ]; then
    echo -e "${RED}Error: PRIVATE_KEY not set in .env${NC}"
    exit 1
fi

if [ -z "$MANTLE_TESTNET_RPC" ]; then
    echo -e "${RED}Error: MANTLE_TESTNET_RPC not set in .env${NC}"
    exit 1
fi

# Parse arguments
DRY_RUN=false
VERIFY=true
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --no-verify)
            VERIFY=false
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            echo "Usage: ./scripts/deploy.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run      Run deployment simulation without broadcasting"
            echo "  --no-verify    Skip contract verification"
            echo "  --verbose      Enable verbose output"
            echo "  --help         Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Run './scripts/deploy.sh --help' for usage"
            exit 1
            ;;
    esac
done

# Header
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}AuRoom Protocol Deployment${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Build contracts first
echo -e "${YELLOW}Building contracts...${NC}"
forge build

if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi

echo -e "${GREEN}Build successful!${NC}"
echo ""

# Prepare forge script command
FORGE_CMD="forge script script/Deploy.s.sol --rpc-url $MANTLE_TESTNET_RPC"

if [ "$DRY_RUN" = false ]; then
    FORGE_CMD="$FORGE_CMD --broadcast"

    # Confirmation for mainnet deployment
    echo -e "${YELLOW}WARNING: This will deploy to Mantle Testnet!${NC}"
    echo -e "${YELLOW}This will cost real gas fees.${NC}"
    echo ""
    read -p "Continue with deployment? (yes/no): " -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo -e "${RED}Deployment cancelled${NC}"
        exit 0
    fi
fi

if [ "$VERIFY" = true ] && [ "$DRY_RUN" = false ]; then
    FORGE_CMD="$FORGE_CMD --verify"
fi

if [ "$VERBOSE" = true ]; then
    FORGE_CMD="$FORGE_CMD -vvvv"
else
    FORGE_CMD="$FORGE_CMD -vv"
fi

# Run deployment
echo -e "${GREEN}Starting deployment...${NC}"
echo ""

eval $FORGE_CMD

if [ $? -ne 0 ]; then
    echo ""
    echo -e "${RED}Deployment failed!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"

if [ "$DRY_RUN" = false ]; then
    echo ""
    echo -e "${GREEN}Deployment addresses saved to:${NC}"
    echo "  deployments/mantle-testnet.json"
    echo ""
    echo -e "${GREEN}Next steps:${NC}"
    echo "  1. Verify deployment: make status"
    echo "  2. Check contract info: forge script script/DeploymentInfo.s.sol --rpc-url \$MANTLE_TESTNET_RPC"
    echo "  3. Run post-deployment setup: make setup"
fi

echo ""
