# Quick Uniswap V2 Deployment - Mantle Sepolia

Panduan cepat untuk deploy Uniswap V2 ke Mantle Sepolia.

## Quick Start

### 1. Deploy Uniswap V2 (One Command)

```bash
# Make scripts executable
chmod +x scripts/deploy-uniswap.sh scripts/setup-dex-pairs.sh

# Deploy DEX infrastructure
./scripts/deploy-uniswap.sh
```

### 2. Update .env

Setelah deployment, catat addresses dan update .env:

```bash
# Add to your .env file
WMNT=0x...              # dari output deployment
UNISWAP_FACTORY=0x...   # dari output deployment
UNISWAP_ROUTER=0x...    # dari output deployment
```

### 3. Setup Pairs & Liquidity (One Command)

```bash
./scripts/setup-dex-pairs.sh
```

Done! DEX siap digunakan.

## Alternative: Forge Script Method

```bash
# 1. Deploy DEX
forge script script/DeployUniswapV2.s.sol:DeployUniswapV2 \
    --rpc-url https://rpc.sepolia.mantle.xyz \
    --private-key $PRIVATE_KEY \
    --broadcast \
    -vvvv

# 2. Update .env dengan addresses yang di-output

# 3. Setup pairs
forge script script/SetupDEXPairs.s.sol:SetupDEXPairs \
    --rpc-url https://rpc.sepolia.mantle.xyz \
    --private-key $PRIVATE_KEY \
    --broadcast \
    -vvvv
```

## Verify Deployment

```bash
RPC="https://rpc.sepolia.mantle.xyz"

# Check Factory
cast call $UNISWAP_FACTORY "allPairsLength()(uint256)" --rpc-url $RPC

# Check IDRX/USDC pair
cast call $UNISWAP_FACTORY \
  "getPair(address,address)(address)" \
  0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05 \
  0x96ABff3a2668B811371d7d763f06B3832CEdf38d \
  --rpc-url $RPC

# Check XAUT/USDC pair
cast call $UNISWAP_FACTORY \
  "getPair(address,address)(address)" \
  0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78 \
  0x96ABff3a2668B811371d7d763f06B3832CEdf38d \
  --rpc-url $RPC
```

## What Gets Deployed

### Uniswap V2 Infrastructure
1. **WMNT** - Wrapped MNT (standard WETH9)
2. **UniswapV2Factory** - Creates and manages pairs
3. **UniswapV2Router02** - Handles swaps and liquidity

### Trading Pairs
1. **IDRX/USDC** - 1M IDRX + 65K USDC
2. **XAUT/USDC** - 100 XAUT + 270K USDC

## Important Outputs

### INIT_CODE_HASH
Catat hash ini untuk pair address calculation:
```
INIT_CODE_HASH: 0x...
```

### Contract Addresses
```
WMNT: 0x...
Factory: 0x...
Router: 0x...
Pair IDRX/USDC: 0x...
Pair XAUT/USDC: 0x...
```

## Common Issues

### "Insufficient balance"
Mint tokens terlebih dahulu:
```bash
# Mint IDRX (contoh: 1M IDRX = 100000000 with 2 decimals)
cast send 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05 \
  "mint(address,uint256)" \
  YOUR_ADDRESS \
  100000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url https://rpc.sepolia.mantle.xyz
```

### "Factory not set in .env"
Jalankan Step 1 dulu, kemudian update .env sebelum Step 3.

### "Pair already exists"
Tidak masalah - script akan skip pair creation dan langsung add liquidity.

## Next Steps

Setelah DEX deployed:

1. **Test Swaps**
   ```bash
   # Swap IDRX to USDC via Router
   cast send $UNISWAP_ROUTER "swapExactTokensForTokens(...)" ...
   ```

2. **Deploy GoldVault** - Router sudah tersedia
3. **Deploy SwapRouter** - untuk handle fee logic
4. **Update Frontend** - gunakan deployed addresses

## Full Documentation

Lihat [UNISWAP_DEPLOYMENT.md](UNISWAP_DEPLOYMENT.md) untuk:
- Manual deployment dengan cast
- Detailed explanation
- Troubleshooting
- Verification commands
