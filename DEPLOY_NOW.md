# Deploy Mock Uniswap V2 - QUICK START

## 🚀 Windows (CMD/PowerShell)

```cmd
REM Step 1: Deploy DEX
deploy-dex-simple.bat

REM Step 2: Update .env file with addresses from output
REM Add: WMNT=0x... UNISWAP_FACTORY=0x... UNISWAP_ROUTER=0x...

REM Step 3: Setup pairs
setup-dex-pairs.bat
```

## 🚀 Linux/Mac/WSL

```bash
# Step 1: Deploy DEX
forge script script/DeployMockUniswapV2.s.sol:DeployMockUniswapV2 \
    --rpc-url https://rpc.sepolia.mantle.xyz \
    --private-key $PRIVATE_KEY \
    --broadcast \
    -vvvv

# Step 2: Update .env
# Copy addresses from output above and add to .env:
# WMNT=0x...
# UNISWAP_FACTORY=0x...
# UNISWAP_ROUTER=0x...

# Step 3: Setup pairs
forge script script/SetupDEXPairs.s.sol:SetupDEXPairs \
    --rpc-url https://rpc.sepolia.mantle.xyz \
    --private-key $PRIVATE_KEY \
    --broadcast \
    -vvvv
```

---

## What Gets Deployed

### Phase 1 - DEX Infrastructure (deploy-dex-simple.bat)
- ✅ WMNT (Wrapped MNT)
- ✅ MockUniswapV2Factory
- ✅ MockUniswapV2Router02

### Phase 2 - Trading Pairs (setup-dex-pairs.bat)
- ✅ IDRX/USDC pair
- ✅ XAUT/USDC pair
- ✅ Initial liquidity

---

## Prerequisites

### .env file must have:
```
PRIVATE_KEY=your_private_key_here
```

### Network:
- RPC: https://rpc.sepolia.mantle.xyz
- Chain ID: 5003
- Explorer: https://sepolia.mantlescan.xyz

### Tokens needed for liquidity:
```
IDRX: 1,000,000 (100000000 with 2 decimals)
USDC: 335,000 (335000000000 with 6 decimals)
XAUT: 100 (100000000 with 6 decimals)
```

---

## Check Balances

```bash
# Get your address
cast wallet address --private-key $PRIVATE_KEY

# Check MNT balance
cast balance YOUR_ADDRESS --rpc-url https://rpc.sepolia.mantle.xyz

# Check IDRX
cast call 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05 "balanceOf(address)(uint256)" YOUR_ADDRESS --rpc-url https://rpc.sepolia.mantle.xyz

# Check USDC
cast call 0x96ABff3a2668B811371d7d763f06B3832CEdf38d "balanceOf(address)(uint256)" YOUR_ADDRESS --rpc-url https://rpc.sepolia.mantle.xyz

# Check XAUT
cast call 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78 "balanceOf(address)(uint256)" YOUR_ADDRESS --rpc-url https://rpc.sepolia.mantle.xyz
```

---

## Troubleshooting

### "Insufficient balance"
Mint tokens if you have minter role:
```bash
# Mint IDRX (1M = 100000000 with 2 decimals)
cast send 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05 \
  "mint(address,uint256)" \
  YOUR_ADDRESS \
  100000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url https://rpc.sepolia.mantle.xyz
```

### Build fails
```bash
# Clean and rebuild
forge clean
forge build
```

### "Factory not set"
Run Step 1 first, then update .env before Step 3.

---

## Token Addresses (Mantle Sepolia)

```
IDRX: 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05
USDC: 0x96ABff3a2668B811371d7d763f06B3832CEdf38d
XAUT: 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78
IdentityRegistry: 0x620870d419F6aFca8AFed5B516619aa50900cadc
```

---

## Next Steps After Deployment

1. Update [deployments/auroom-mantle-sepolia.json](deployments/auroom-mantle-sepolia.json)
2. Deploy GoldVault (Router now available)
3. Deploy SwapRouter
4. Test swaps via Router

---

## Full Documentation

- [MANUAL_DEPLOY_STEPS.md](MANUAL_DEPLOY_STEPS.md) - Manual step-by-step with cast
- [DEPLOY_DEX_NOW.md](DEPLOY_DEX_NOW.md) - Detailed guide
- [UNISWAP_DEPLOYMENT.md](UNISWAP_DEPLOYMENT.md) - Complete documentation
