# Uniswap V2 Deployment Guide - Mantle Sepolia

Panduan lengkap untuk deploy Uniswap V2 infrastructure ke Mantle Sepolia testnet.

## Prerequisites

### Already Deployed Contracts
```
MockIDRX: 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05
MockUSDC: 0x96ABff3a2668B811371d7d763f06B3832CEdf38d
IdentityRegistry: 0x620870d419F6aFca8AFed5B516619aa50900cadc
XAUT: 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78
```

### Network Info
- **Chain ID**: 5003
- **RPC URL**: https://rpc.sepolia.mantle.xyz
- **Explorer**: https://sepolia.mantlescan.xyz
- **Deployer**: 0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1

### Required Tools
- Foundry (forge, cast)
- .env file with PRIVATE_KEY

## Deployment Steps

### Step 1: Deploy Uniswap V2 Infrastructure

Deploy WMNT, Factory, dan Router:

```bash
# Using shell script (recommended)
chmod +x scripts/deploy-uniswap.sh
./scripts/deploy-uniswap.sh

# Or using forge directly
forge script script/DeployUniswapV2.s.sol:DeployUniswapV2 \
    --rpc-url https://rpc.sepolia.mantle.xyz \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $MANTLESCAN_API_KEY \
    -vvvv
```

**Expected Output:**
```
1. Deploying WMNT...
WMNT deployed at: 0x...

2. Deploying UniswapV2Factory...
Factory deployed at: 0x...
INIT_CODE_HASH: 0x...

3. Deploying UniswapV2Router02...
Router deployed at: 0x...

=== Deployment Summary ===
WMNT: 0x...
Factory: 0x...
Router: 0x...
INIT_CODE_HASH: 0x...
```

**IMPORTANT**: Save the INIT_CODE_HASH - diperlukan untuk pair address calculation!

### Step 2: Update .env File

Tambahkan deployed addresses ke .env:

```bash
# Add to .env
UNISWAP_FACTORY=0x...  # Factory address from step 1
UNISWAP_ROUTER=0x...   # Router address from step 1
WMNT=0x...             # WMNT address from step 1
```

### Step 3: Prepare Liquidity

Pastikan deployer address punya cukup tokens untuk initial liquidity:

**Required Balances:**
- IDRX: 1,000,000 (1M IDRX = 100000000 raw with 2 decimals)
- USDC: 335,000 (335K USDC = 335000000000 raw with 6 decimals)
- XAUT: 100 (100 XAUT = 100000000 raw with 6 decimals)

**Check Balances:**
```bash
# Check IDRX balance
cast call 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05 \
  "balanceOf(address)(uint256)" \
  0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1 \
  --rpc-url https://rpc.sepolia.mantle.xyz

# Check USDC balance
cast call 0x96ABff3a2668B811371d7d763f06B3832CEdf38d \
  "balanceOf(address)(uint256)" \
  0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1 \
  --rpc-url https://rpc.sepolia.mantle.xyz

# Check XAUT balance
cast call 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78 \
  "balanceOf(address)(uint256)" \
  0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1 \
  --rpc-url https://rpc.sepolia.mantle.xyz
```

**Mint Tokens if Needed:**
```bash
# Mint IDRX (if you have minter role)
cast send 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05 \
  "mint(address,uint256)" \
  0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1 \
  100000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url https://rpc.sepolia.mantle.xyz

# Similar for USDC and XAUT
```

### Step 4: Create Pairs and Add Liquidity

```bash
# Using shell script (recommended)
chmod +x scripts/setup-dex-pairs.sh
./scripts/setup-dex-pairs.sh

# Or using forge directly
forge script script/SetupDEXPairs.s.sol:SetupDEXPairs \
    --rpc-url https://rpc.sepolia.mantle.xyz \
    --private-key $PRIVATE_KEY \
    --broadcast \
    -vvvv
```

**This will:**
1. Create IDRX/USDC pair
2. Create XAUT/USDC pair
3. Add initial liquidity:
   - IDRX/USDC: 1M IDRX + 65K USDC (price: 1 IDRX ≈ 0.065 USDC)
   - XAUT/USDC: 100 XAUT + 270K USDC (price: 1 XAUT ≈ 2,700 USDC)

## Manual Deployment (Alternative)

Jika prefer manual deployment dengan cast:

### 1. Deploy WMNT
```bash
# Compile first to get bytecode
forge build

# Deploy WMNT (using WETH9 contract)
cast send --private-key $PRIVATE_KEY \
  --rpc-url https://rpc.sepolia.mantle.xyz \
  --create $(forge inspect lib/uniswap-v2-periphery/contracts/test/WETH9.sol:WETH9 bytecode)

# Save address as WMNT_ADDRESS
export WMNT_ADDRESS=0x...
```

### 2. Deploy Factory
```bash
# Get deployer address
DEPLOYER=$(cast wallet address --private-key $PRIVATE_KEY)

# Encode constructor args (feeToSetter = deployer)
CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(address)" $DEPLOYER)

# Get Factory bytecode
FACTORY_BYTECODE=$(forge inspect lib/uniswap-v2-core/contracts/UniswapV2Factory.sol:UniswapV2Factory bytecode)

# Deploy Factory
cast send --private-key $PRIVATE_KEY \
  --rpc-url https://rpc.sepolia.mantle.xyz \
  --create ${FACTORY_BYTECODE}${CONSTRUCTOR_ARGS}

export FACTORY_ADDRESS=0x...
```

### 3. Get INIT_CODE_HASH
```bash
# Calculate INIT_CODE_HASH from UniswapV2Pair bytecode
PAIR_BYTECODE=$(forge inspect lib/uniswap-v2-core/contracts/UniswapV2Pair.sol:UniswapV2Pair bytecode)
INIT_CODE_HASH=$(cast keccak $PAIR_BYTECODE)

echo "INIT_CODE_HASH: $INIT_CODE_HASH"
```

### 4. Deploy Router
```bash
# Encode constructor args (factory, WMNT)
ROUTER_CONSTRUCTOR=$(cast abi-encode "constructor(address,address)" $FACTORY_ADDRESS $WMNT_ADDRESS)

# Get Router bytecode
ROUTER_BYTECODE=$(forge inspect lib/uniswap-v2-periphery/contracts/UniswapV2Router02.sol:UniswapV2Router02 bytecode)

# Deploy Router
cast send --private-key $PRIVATE_KEY \
  --rpc-url https://rpc.sepolia.mantle.xyz \
  --create ${ROUTER_BYTECODE}${ROUTER_CONSTRUCTOR}

export ROUTER_ADDRESS=0x...
```

### 5. Create Pairs
```bash
# Create IDRX/USDC pair
cast send $FACTORY_ADDRESS \
  "createPair(address,address)" \
  0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05 \
  0x96ABff3a2668B811371d7d763f06B3832CEdf38d \
  --private-key $PRIVATE_KEY \
  --rpc-url https://rpc.sepolia.mantle.xyz

# Create XAUT/USDC pair
cast send $FACTORY_ADDRESS \
  "createPair(address,address)" \
  0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78 \
  0x96ABff3a2668B811371d7d763f06B3832CEdf38d \
  --private-key $PRIVATE_KEY \
  --rpc-url https://rpc.sepolia.mantle.xyz
```

### 6. Approve Tokens
```bash
# Approve IDRX
cast send 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05 \
  "approve(address,uint256)" \
  $ROUTER_ADDRESS \
  100000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url https://rpc.sepolia.mantle.xyz

# Approve USDC
cast send 0x96ABff3a2668B811371d7d763f06B3832CEdf38d \
  "approve(address,uint256)" \
  $ROUTER_ADDRESS \
  335000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url https://rpc.sepolia.mantle.xyz

# Approve XAUT
cast send 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78 \
  "approve(address,uint256)" \
  $ROUTER_ADDRESS \
  100000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url https://rpc.sepolia.mantle.xyz
```

### 7. Add Liquidity
```bash
# Add IDRX/USDC liquidity
DEADLINE=$(($(date +%s) + 300))  # 5 minutes from now

cast send $ROUTER_ADDRESS \
  "addLiquidity(address,address,uint256,uint256,uint256,uint256,address,uint256)" \
  0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05 \
  0x96ABff3a2668B811371d7d763f06B3832CEdf38d \
  100000000 \
  65000000000 \
  95000000 \
  61750000000 \
  $DEPLOYER \
  $DEADLINE \
  --private-key $PRIVATE_KEY \
  --rpc-url https://rpc.sepolia.mantle.xyz

# Add XAUT/USDC liquidity
cast send $ROUTER_ADDRESS \
  "addLiquidity(address,address,uint256,uint256,uint256,uint256,address,uint256)" \
  0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78 \
  0x96ABff3a2668B811371d7d763f06B3832CEdf38d \
  100000000 \
  270000000000 \
  95000000 \
  256500000000 \
  $DEPLOYER \
  $DEADLINE \
  --private-key $PRIVATE_KEY \
  --rpc-url https://rpc.sepolia.mantle.xyz
```

## Verification

### Verify Pair Creation
```bash
# Get IDRX/USDC pair address
cast call $FACTORY_ADDRESS \
  "getPair(address,address)(address)" \
  0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05 \
  0x96ABff3a2668B811371d7d763f06B3832CEdf38d \
  --rpc-url https://rpc.sepolia.mantle.xyz

# Get XAUT/USDC pair address
cast call $FACTORY_ADDRESS \
  "getPair(address,address)(address)" \
  0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78 \
  0x96ABff3a2668B811371d7d763f06B3832CEdf38d \
  --rpc-url https://rpc.sepolia.mantle.xyz
```

### Check Liquidity
```bash
# Check IDRX/USDC pair reserves
PAIR_IDRX_USDC=0x...  # from getPair call above

cast call $PAIR_IDRX_USDC \
  "getReserves()(uint112,uint112,uint32)" \
  --rpc-url https://rpc.sepolia.mantle.xyz
```

## Update Deployment JSON

Setelah semua berhasil, update [deployments/auroom-mantle-sepolia.json](deployments/auroom-mantle-sepolia.json):

```json
{
  "chainId": 5003,
  "network": "mantle-sepolia",
  "timestamp": 1734496379,
  "deployer": "0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1",
  "contracts": {
    "MockIDRX": "0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05",
    "MockUSDC": "0x96ABff3a2668B811371d7d763f06B3832CEdf38d",
    "IdentityRegistry": "0x620870d419F6aFca8AFed5B516619aa50900cadc",
    "XAUT": "0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78",
    "WMNT": "0x...",
    "UniswapV2Factory": "0x...",
    "UniswapV2Router02": "0x...",
    "PairIDRX_USDC": "0x...",
    "PairXAUT_USDC": "0x..."
  },
  "dex": {
    "INIT_CODE_HASH": "0x...",
    "pairs": {
      "IDRX/USDC": {
        "address": "0x...",
        "reserves": {
          "IDRX": "100000000",
          "USDC": "65000000000"
        },
        "price": "0.065"
      },
      "XAUT/USDC": {
        "address": "0x...",
        "reserves": {
          "XAUT": "100000000",
          "USDC": "270000000000"
        },
        "price": "2700"
      }
    }
  },
  "status": {
    "MockIDRX": "deployed",
    "MockUSDC": "deployed",
    "IdentityRegistry": "deployed",
    "XAUT": "deployed",
    "WMNT": "deployed",
    "UniswapV2Factory": "deployed",
    "UniswapV2Router02": "deployed",
    "GoldVault": "ready to deploy",
    "SwapRouter": "ready to deploy"
  }
}
```

## Next Steps

Setelah DEX deployed, Anda bisa:

1. **Deploy GoldVault** - sudah bisa deploy karena Router sudah tersedia
2. **Deploy SwapRouter** - untuk handle swaps dengan fee
3. **Test Trading** - coba swap IDRX/USDC dan XAUT/USDC
4. **Add More Liquidity** - jika diperlukan

## Troubleshooting

### Gas Issues
Jika gas price terlalu tinggi, tambahkan `--gas-price` atau `--priority-gas-price`:
```bash
--gas-price 1000000000  # 1 gwei
```

### Verification Failed
Jika contract verification gagal, verify manual:
```bash
forge verify-contract \
  --chain-id 5003 \
  --compiler-version v0.6.6+commit.6c089d02 \
  --constructor-args $CONSTRUCTOR_ARGS \
  $CONTRACT_ADDRESS \
  src/ContractName.sol:ContractName \
  --etherscan-api-key $MANTLESCAN_API_KEY
```

### Insufficient Balance
Pastikan deployer punya:
- Cukup MNT untuk gas fees
- Cukup tokens untuk liquidity

Get testnet MNT: https://faucet.sepolia.mantle.xyz

## References

- [Uniswap V2 Documentation](https://docs.uniswap.org/contracts/v2/overview)
- [Mantle Sepolia Faucet](https://faucet.sepolia.mantle.xyz)
- [Mantle Sepolia Explorer](https://sepolia.mantlescan.xyz)
