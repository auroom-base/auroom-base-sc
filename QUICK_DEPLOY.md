# Quick Deploy Guide - AuRoom Platform

## 🚀 Quick Start (3 Commands)

```bash
# 1. Deploy DEX (Uniswap V2)
./scripts/deploy-dex.sh

# 2. Update .env with Router address from step 1
# (Script will show you the address)

# 3. Deploy AuRoom + Setup Liquidity
./scripts/deploy-auroom.sh
./scripts/setup-liquidity.sh
```

That's it! Your platform is deployed and ready! 🎉

---

## Prerequisites Checklist

- ✅ Foundry installed (`forge --version`)
- ✅ `.env` configured with:
  - `PRIVATE_KEY` (your wallet private key)
  - `MANTLE_TESTNET_RPC` (https://rpc.sepolia.mantle.xyz)
- ✅ Testnet MNT in wallet (get from [faucet](https://faucet.sepolia.mantle.xyz/))

---

## Step-by-Step

### Step 1: Deploy DEX

```bash
./scripts/deploy-dex.sh
```

**Wait for completion**, then you'll see:

```
✅ Deployment Successful!

Deployed Addresses:
  WMNT:                0x...
  UniswapV2Factory:    0x...
  UniswapV2Router02:   0x...  ← COPY THIS ADDRESS

Addresses saved to: deployments/dex-mantle-sepolia.json
```

### Step 2: Update Environment

Open `.env` and update:

```env
UNISWAP_ROUTER=0x<paste-router-address-here>
```

Or use this command:

```bash
# Automatically extract and update
ROUTER=$(jq -r '.UniswapV2Router02' deployments/dex-mantle-sepolia.json)
sed -i "s/UNISWAP_ROUTER=.*/UNISWAP_ROUTER=$ROUTER/" .env
```

### Step 3: Deploy AuRoom

```bash
./scripts/deploy-auroom.sh
```

**Wait for completion**, you'll see:

```
✅ Deployment Successful!

Deployed Contracts:
  MockIDRX:          0x...
  MockUSDC:          0x...
  IdentityRegistry:  0x...
  XAUT:              0x...
  GoldVault:         0x...
  SwapRouter:        0x...

Addresses saved to: deployments/auroom-mantle-testnet.json
```

### Step 4: Setup Liquidity

```bash
./scripts/setup-liquidity.sh
```

**This will:**
- Mint initial tokens
- Create IDRX/USDC pair
- Create USDC/XAUT pair
- Add liquidity to both pairs

**Output:**

```
✅ Liquidity Setup Complete!

Liquidity Pools Created:
  1. IDRX/USDC - 1M IDRX : 1M USDC
  2. USDC/XAUT - 1M USDC : 10K XAUT

Platform is now ready for swaps!
```

---

## 🎯 Quick Test

### Test Swap IDRX → XAUT

```bash
# Load addresses
source .env
IDRX=$(jq -r '.MockIDRX' deployments/auroom-mantle-testnet.json)
XAUT=$(jq -r '.XAUT' deployments/auroom-mantle-testnet.json)
SWAP_ROUTER=$(jq -r '.SwapRouter' deployments/auroom-mantle-testnet.json)
IDENTITY=$(jq -r '.IdentityRegistry' deployments/auroom-mantle-testnet.json)

# 1. Register yourself in KYC
cast send $IDENTITY "registerIdentity(address)" $(cast wallet address --private-key $PRIVATE_KEY) \
  --rpc-url $MANTLE_TESTNET_RPC --private-key $PRIVATE_KEY

# 2. Mint IDRX
cast send $IDRX "publicMint(address,uint256)" $(cast wallet address --private-key $PRIVATE_KEY) 10000000000 \
  --rpc-url $MANTLE_TESTNET_RPC --private-key $PRIVATE_KEY

# 3. Check balance
cast call $IDRX "balanceOf(address)" $(cast wallet address --private-key $PRIVATE_KEY) \
  --rpc-url $MANTLE_TESTNET_RPC

# 4. Approve swap
cast send $IDRX "approve(address,uint256)" $SWAP_ROUTER 10000000000 \
  --rpc-url $MANTLE_TESTNET_RPC --private-key $PRIVATE_KEY

# 5. Execute swap
DEADLINE=$(($(date +%s) + 1200))
cast send $SWAP_ROUTER \
  "swapIDRXtoXAUT(uint256,uint256,address,uint256)" \
  10000000000 \
  1 \
  $(cast wallet address --private-key $PRIVATE_KEY) \
  $DEADLINE \
  --rpc-url $MANTLE_TESTNET_RPC --private-key $PRIVATE_KEY

# 6. Check XAUT balance
cast call $XAUT "balanceOf(address)" $(cast wallet address --private-key $PRIVATE_KEY) \
  --rpc-url $MANTLE_TESTNET_RPC
```

---

## 📊 Verify Deployment

```bash
# Check DEX deployment
cat deployments/dex-mantle-sepolia.json

# Check AuRoom deployment
cat deployments/auroom-mantle-testnet.json

# Test contract (example: check XAUT name)
XAUT=$(jq -r '.XAUT' deployments/auroom-mantle-testnet.json)
cast call $XAUT "name()" --rpc-url $MANTLE_TESTNET_RPC
```

---

## 🆘 Troubleshooting

### "UNISWAP_ROUTER not set"
**Fix:** Deploy DEX first, then update `.env`

### "Insufficient funds"
**Fix:** Get MNT from [faucet](https://faucet.sepolia.mantle.xyz/)

### "recipient not verified"
**Fix:** Register address in KYC:
```bash
IDENTITY=$(jq -r '.IdentityRegistry' deployments/auroom-mantle-testnet.json)
cast send $IDENTITY "registerIdentity(address)" <USER_ADDRESS> \
  --rpc-url $MANTLE_TESTNET_RPC --private-key $PRIVATE_KEY
```

### "Insufficient liquidity"
**Fix:** Run `./scripts/setup-liquidity.sh`

---

## 📁 Deployment Files

After successful deployment:

```
deployments/
├── dex-mantle-sepolia.json       # DEX contract addresses
└── auroom-mantle-testnet.json    # AuRoom contract addresses
```

---

## 🔗 Useful Links

- **Explorer:** https://sepolia.mantlescan.xyz
- **Faucet:** https://faucet.sepolia.mantle.xyz
- **RPC:** https://rpc.sepolia.mantle.xyz

---

## 📖 Full Documentation

For detailed information, see:
- [DEPLOYMENT.md](DEPLOYMENT.md) - Complete deployment guide
- [TESTING_GUIDE.md](TESTING_GUIDE.md) - Testing instructions
- [TEST_RESULTS.md](TEST_RESULTS.md) - Test coverage report

---

**Estimated Time:** 10-15 minutes
**Total Cost:** ~0.15 MNT (testnet)
**Difficulty:** Easy ⭐

---

**Ready to deploy? Run:**
```bash
./scripts/deploy-dex.sh
```
