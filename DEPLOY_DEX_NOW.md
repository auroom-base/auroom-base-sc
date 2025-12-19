# Deploy Uniswap V2 - Quick Start

**3 commands untuk deploy complete DEX infrastructure.**

## Method 1: Windows Batch Files (EASIEST for Windows)

### Step 1: Deploy DEX Infrastructure

```cmd
deploy-dex-simple.bat
```

Ini akan deploy:
- WMNT (Wrapped MNT)
- UniswapV2Factory
- UniswapV2Router02

**Output yang penting:**
```
WMNT: 0x...
Factory: 0x...
Router: 0x...
INIT_CODE_HASH: 0x...  ← SAVE THIS!
```

## Step 2: Update .env

```bash
# Add to .env file
WMNT=0x...              # dari output step 1
UNISWAP_FACTORY=0x...   # dari output step 1
UNISWAP_ROUTER=0x...    # dari output step 1
```

### Step 3: Setup Pairs & Liquidity

```cmd
setup-dex-pairs.bat
```

---

## Method 2: Makefile (Linux/Mac or Windows with make)

### Step 1: Deploy DEX Infrastructure

```bash
make deploy-uniswap
```

### Step 2: Update .env

```bash
# Add to .env file
WMNT=0x...              # dari output step 1
UNISWAP_FACTORY=0x...   # dari output step 1
UNISWAP_ROUTER=0x...    # dari output step 1
```

### Step 3: Setup Pairs & Liquidity

```bash
make setup-dex-pairs
```

Ini akan:
- Create IDRX/USDC pair
- Create XAUT/USDC pair
- Add initial liquidity

## Verify

```bash
make check-dex
make check-pairs
```

---

## Prerequisites

### Required in .env:
```
PRIVATE_KEY=your_key
MANTLESCAN_API_KEY=your_key
```

### Required balances:
```
MNT: untuk gas fees
IDRX: 1,000,000 (100000000 raw)
USDC: 335,000 (335000000000 raw)
XAUT: 100 (100000000 raw)
```

Check balances:
```bash
# MNT balance
make balance

# Token balances
cast call 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05 "balanceOf(address)(uint256)" YOUR_ADDRESS --rpc-url https://rpc.sepolia.mantle.xyz  # IDRX
cast call 0x96ABff3a2668B811371d7d763f06B3832CEdf38d "balanceOf(address)(uint256)" YOUR_ADDRESS --rpc-url https://rpc.sepolia.mantle.xyz  # USDC
cast call 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78 "balanceOf(address)(uint256)" YOUR_ADDRESS --rpc-url https://rpc.sepolia.mantle.xyz  # XAUT
```

---

---

## Method 3: Direct Forge Commands (Most Reliable)

```bash
# Step 1: Deploy DEX
forge script script/DeployUniswapV2.s.sol:DeployUniswapV2 \
    --rpc-url https://rpc.sepolia.mantle.xyz \
    --private-key $PRIVATE_KEY \
    --broadcast -vvvv

# Step 2: Update .env

# Step 3: Setup pairs
forge script script/SetupDEXPairs.s.sol:SetupDEXPairs \
    --rpc-url https://rpc.sepolia.mantle.xyz \
    --private-key $PRIVATE_KEY \
    --broadcast -vvvv
```

---

## What You Get

After completion:

### Deployed Contracts
- WMNT at 0x...
- UniswapV2Factory at 0x...
- UniswapV2Router02 at 0x...

### Trading Pairs
- IDRX/USDC with 1M IDRX + 65K USDC
- XAUT/USDC with 100 XAUT + 270K USDC

### Ready for
- GoldVault deployment (needs Router)
- SwapRouter deployment
- Trading/swapping operations

---

## Troubleshooting

**"Insufficient balance"**
```bash
# Mint tokens if you have minter role
cast send TOKEN_ADDRESS "mint(address,uint256)" YOUR_ADDRESS AMOUNT --private-key $PRIVATE_KEY --rpc-url https://rpc.sepolia.mantle.xyz
```

**"Factory not set"**
- Run Step 1 first
- Update .env before Step 3

**"Pair already exists"**
- Not an error, will add liquidity to existing pair

---

## Method 4: Manual Step-by-Step (For Debugging)

See [MANUAL_DEPLOY_STEPS.md](MANUAL_DEPLOY_STEPS.md) for individual cast commands to deploy each contract separately.

---

## Full Documentation

- **[MANUAL_DEPLOY_STEPS.md](MANUAL_DEPLOY_STEPS.md)** - Manual deployment with cast commands
- [QUICK_UNISWAP_DEPLOY.md](QUICK_UNISWAP_DEPLOY.md) - Quick reference
- [UNISWAP_DEPLOYMENT.md](UNISWAP_DEPLOYMENT.md) - Complete guide
- [DEX_DEPLOYMENT_SUMMARY.md](DEX_DEPLOYMENT_SUMMARY.md) - Summary

---

## Network

```
Mantle Sepolia
Chain ID: 5003
RPC: https://rpc.sepolia.mantle.xyz
Explorer: https://sepolia.mantlescan.xyz
```

**Token Addresses:**
```
IDRX: 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05
USDC: 0x96ABff3a2668B811371d7d763f06B3832CEdf38d
XAUT: 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78
```
