# AuRoom Platform - Complete Deployment Guide

## Overview

This guide covers the complete deployment of the Productive Gold Platform (AuRoom) to Mantle Testnet, including:
1. DEX deployment (Uniswap V2)
2. AuRoom contracts deployment
3. Liquidity pool setup
4. Verification and testing

---

## Prerequisites

### 1. Environment Setup

```bash
# Install Foundry (if not installed)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Clone repository
git clone <repository-url>
cd AuRoom

# Install dependencies
forge install
```

### 2. Get Testnet Funds

Visit [Mantle Sepolia Faucet](https://faucet.sepolia.mantle.xyz/) and get testnet MNT tokens.

### 3. Configure Environment

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

Edit `.env`:
```env
# Your private key (without 0x prefix)
PRIVATE_KEY=your_private_key_here

# Network RPC
MANTLE_TESTNET_RPC=https://rpc.sepolia.mantle.xyz

# Will be filled after DEX deployment
UNISWAP_ROUTER=0x0000000000000000000000000000000000000000
```

---

## Deployment Steps

### Step 1: Deploy DEX (Uniswap V2)

Deploy the Uniswap V2 DEX infrastructure first:

```bash
./scripts/deploy-dex.sh
```

This will deploy:
- WMNT (Wrapped MNT)
- UniswapV2Factory
- UniswapV2Router02

**Output:** `deployments/dex-mantle-sepolia.json`

**Copy the Router address** and update `.env`:
```env
UNISWAP_ROUTER=0x<router-address-from-deployment>
```

---

### Step 2: Deploy AuRoom Contracts

Deploy all AuRoom platform contracts:

```bash
./scripts/deploy-auroom.sh
```

This will deploy:
1. **MockIDRX** - Rupiah stablecoin (ERC-20)
2. **MockUSDC** - USDC stablecoin (ERC-20)
3. **IdentityRegistry** - KYC/compliance registry
4. **XAUT** - Tokenized gold (ERC-3643 compliant)
5. **GoldVault** - Yield-bearing vault (ERC-4626)
6. **SwapRouter** - DEX routing for IDRX ↔ XAUT

**Output:** `deployments/auroom-mantle-testnet.json`

**Deployment Summary:**
```json
{
  "chainId": 5003,
  "deployer": "0x...",
  "MockIDRX": "0x...",
  "MockUSDC": "0x...",
  "IdentityRegistry": "0x...",
  "XAUT": "0x...",
  "GoldVault": "0x...",
  "SwapRouter": "0x...",
  "UniswapRouter": "0x..."
}
```

---

### Step 3: Setup Liquidity Pools

Create trading pairs and add initial liquidity:

```bash
./scripts/setup-liquidity.sh
```

This will:
1. Mint initial tokens (IDRX, USDC, XAUT)
2. Approve Uniswap Router
3. Create IDRX/USDC pair and add liquidity
4. Create USDC/XAUT pair and add liquidity

**Initial Liquidity:**
- IDRX/USDC: 1M IDRX : 1M USDC
- USDC/XAUT: 1M USDC : 10K XAUT

**Price Ratio:**
- 1 IDRX = 1 USDC
- 1 XAUT = 100 USDC
- Therefore: 1 XAUT = 100 IDRX

---

### Step 4: Verify Contracts (Optional)

Verify contracts on block explorer:

```bash
# Verify individual contract
forge verify-contract <ADDRESS> <CONTRACT_NAME> \
  --chain-id 5003 \
  --watch

# Example: Verify XAUT
forge verify-contract <XAUT_ADDRESS> src/XAUT.sol:XAUT \
  --chain-id 5003 \
  --constructor-args $(cast abi-encode "constructor(address)" <IDENTITY_REGISTRY_ADDRESS>) \
  --watch
```

---

## Contract Interactions

### Register Users in KYC

Only admins can register users:

```bash
# Get deployment addresses
IDENTITY_REGISTRY=$(jq -r '.IdentityRegistry' deployments/auroom-mantle-testnet.json)

# Register a user
cast send $IDENTITY_REGISTRY \
  "registerIdentity(address)" \
  <USER_ADDRESS> \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY
```

### Mint Tokens

```bash
# Load addresses
IDRX=$(jq -r '.MockIDRX' deployments/auroom-mantle-testnet.json)
XAUT=$(jq -r '.XAUT' deployments/auroom-mantle-testnet.json)

# Mint IDRX (public mint)
cast send $IDRX \
  "publicMint(address,uint256)" \
  <USER_ADDRESS> \
  1000000000 \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY

# Mint XAUT (owner only, user must be KYC verified)
cast send $XAUT \
  "mint(address,uint256)" \
  <USER_ADDRESS> \
  1000000 \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY
```

### Swap IDRX → XAUT

```bash
SWAP_ROUTER=$(jq -r '.SwapRouter' deployments/auroom-mantle-testnet.json)
AMOUNT_IN="10000000000"  # 10,000 IDRX

# 1. Get quote
cast call $SWAP_ROUTER \
  "getQuoteIDRXtoXAUT(uint256)" \
  $AMOUNT_IN \
  --rpc-url $MANTLE_TESTNET_RPC

# 2. Approve IDRX
cast send $IDRX \
  "approve(address,uint256)" \
  $SWAP_ROUTER \
  $AMOUNT_IN \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY

# 3. Execute swap
DEADLINE=$(($(date +%s) + 1200))
cast send $SWAP_ROUTER \
  "swapIDRXtoXAUT(uint256,uint256,address,uint256)" \
  $AMOUNT_IN \
  <MIN_AMOUNT_OUT> \
  <RECIPIENT_ADDRESS> \
  $DEADLINE \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY
```

### Deposit to GoldVault

```bash
GOLD_VAULT=$(jq -r '.GoldVault' deployments/auroom-mantle-testnet.json)
DEPOSIT_AMOUNT="1000000"  # 1 XAUT

# 1. Approve XAUT
cast send $XAUT \
  "approve(address,uint256)" \
  $GOLD_VAULT \
  $DEPOSIT_AMOUNT \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY

# 2. Deposit to vault
cast send $GOLD_VAULT \
  "deposit(uint256,address)" \
  $DEPOSIT_AMOUNT \
  <RECIPIENT_ADDRESS> \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY
```

---

## Testing Full Flow

### Complete User Journey

```bash
# 1. Register user in KYC
cast send $IDENTITY_REGISTRY "registerIdentity(address)" $USER_ADDRESS \
  --rpc-url $MANTLE_TESTNET_RPC --private-key $PRIVATE_KEY

# 2. Mint IDRX to user
cast send $IDRX "publicMint(address,uint256)" $USER_ADDRESS 100000000000 \
  --rpc-url $MANTLE_TESTNET_RPC --private-key $PRIVATE_KEY

# 3. User swaps IDRX → XAUT
# (Use swap commands from above)

# 4. User deposits XAUT to vault
# (Use deposit commands from above)

# 5. User withdraws from vault
cast send $GOLD_VAULT "withdraw(uint256,address,address)" \
  $WITHDRAW_AMOUNT $USER_ADDRESS $USER_ADDRESS \
  --rpc-url $MANTLE_TESTNET_RPC --private-key $PRIVATE_KEY

# 6. User swaps XAUT → IDRX
# (Use swap commands, reverse direction)
```

---

## Verification Checklist

### Contract Deployment
- [ ] MockIDRX deployed and verified
- [ ] MockUSDC deployed and verified
- [ ] IdentityRegistry deployed and verified
- [ ] XAUT deployed and verified
- [ ] GoldVault deployed and verified
- [ ] SwapRouter deployed and verified

### Liquidity Pools
- [ ] IDRX/USDC pair created
- [ ] USDC/XAUT pair created
- [ ] Initial liquidity added to IDRX/USDC
- [ ] Initial liquidity added to USDC/XAUT

### Functionality Tests
- [ ] KYC registration works
- [ ] Token minting works
- [ ] IDRX → XAUT swap works
- [ ] XAUT → IDRX swap works
- [ ] Vault deposit works
- [ ] Vault withdrawal works
- [ ] Compliance checks enforced

---

## Troubleshooting

### "UNISWAP_ROUTER not set"
**Solution:** Deploy DEX first using `./scripts/deploy-dex.sh`, then update `.env`

### "recipient not verified"
**Solution:** Register address in IdentityRegistry first

### "insufficient allowance"
**Solution:** Approve token spending before swap/deposit

### "insufficient liquidity"
**Solution:** Run `./scripts/setup-liquidity.sh` to add liquidity

### "deadline expired"
**Solution:** Increase deadline timestamp in swap calls

---

## Network Information

### Mantle Sepolia Testnet
- **Chain ID:** 5003
- **RPC URL:** https://rpc.sepolia.mantle.xyz
- **Explorer:** https://sepolia.mantlescan.xyz
- **Faucet:** https://faucet.sepolia.mantle.xyz

### Mantle Testnet (Legacy)
- **Chain ID:** 5001
- **RPC URL:** https://rpc.testnet.mantle.xyz
- **Explorer:** https://explorer.testnet.mantle.xyz

---

## File Structure

```
AuRoom/
├── script/
│   ├── DeployAuRoom.s.sol      # Main deployment script
│   └── DeployDEX.s.sol         # DEX deployment script
├── scripts/
│   ├── deploy-dex.sh           # Automated DEX deployment
│   ├── deploy-auroom.sh        # Automated AuRoom deployment
│   └── setup-liquidity.sh      # Liquidity pool setup
├── deployments/
│   ├── dex-mantle-sepolia.json      # DEX addresses
│   └── auroom-mantle-testnet.json   # AuRoom addresses
├── src/
│   ├── MockIDRX.sol
│   ├── MockUSDC.sol
│   ├── IdentityRegistry.sol
│   ├── XAUT.sol
│   ├── GoldVault.sol
│   └── SwapRouter.sol
└── test/
    └── Integration.t.sol       # Comprehensive tests
```

---

## Gas Estimates

| Operation | Estimated Gas | Approx Cost (10 gwei) |
|-----------|---------------|----------------------|
| Deploy MockIDRX | ~800,000 | 0.008 MNT |
| Deploy MockUSDC | ~800,000 | 0.008 MNT |
| Deploy IdentityRegistry | ~600,000 | 0.006 MNT |
| Deploy XAUT | ~1,500,000 | 0.015 MNT |
| Deploy GoldVault | ~3,500,000 | 0.035 MNT |
| Deploy SwapRouter | ~1,200,000 | 0.012 MNT |
| **Total Deployment** | **~8,400,000** | **~0.084 MNT** |
| Add Liquidity (per pair) | ~300,000 | 0.003 MNT |
| Swap Tokens | ~150,000 | 0.0015 MNT |
| Deposit to Vault | ~140,000 | 0.0014 MNT |

---

## Security Considerations

### Before Mainnet

1. **Audit all contracts** - Get professional security audit
2. **Test extensively** - Run all integration tests
3. **Update access controls** - Review admin roles
4. **Set proper parameters** - Configure fees, limits
5. **Test emergency procedures** - Verify pause/unpause works

### Production Deployment

1. Use hardware wallet or secure key management
2. Deploy from fresh account with minimal funds
3. Transfer ownership after verification
4. Implement timelock for critical functions
5. Set up monitoring and alerts

---

## Support & Resources

- **Documentation:** [README.md](README.md)
- **Testing Guide:** [TESTING_GUIDE.md](TESTING_GUIDE.md)
- **Test Results:** [TEST_RESULTS.md](TEST_RESULTS.md)
- **DEX Guide:** [DEX_DEPLOYMENT.md](DEX_DEPLOYMENT.md)

---

## Quick Reference Commands

```bash
# Full deployment (from scratch)
./scripts/deploy-dex.sh              # Step 1: Deploy DEX
# Update UNISWAP_ROUTER in .env      # Step 2: Update config
./scripts/deploy-auroom.sh           # Step 3: Deploy AuRoom
./scripts/setup-liquidity.sh         # Step 4: Add liquidity

# Run tests
forge test --match-contract IntegrationTest

# Check deployment
cat deployments/auroom-mantle-testnet.json

# Query contract
cast call <CONTRACT> "<FUNCTION>" --rpc-url $MANTLE_TESTNET_RPC

# Send transaction
cast send <CONTRACT> "<FUNCTION>" <ARGS> \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY
```

---

**Last Updated:** December 16, 2025
**Network:** Mantle Sepolia Testnet (Chain ID: 5003)
**Status:** Ready for Deployment ✅
