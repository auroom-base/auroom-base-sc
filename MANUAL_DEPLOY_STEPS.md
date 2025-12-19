# Manual Deployment Steps - Uniswap V2

Deploy Uniswap V2 step-by-step menggunakan forge script individual commands.

## Prerequisites

```bash
# Set environment variables
source .env

# Or export manually
export PRIVATE_KEY=your_private_key
export RPC_URL=https://rpc.sepolia.mantle.xyz
```

## Step 1: Deploy WMNT

```bash
# Deploy menggunakan forge script (recommended)
forge script script/DeployUniswapV2.s.sol:DeployUniswapV2 \
    --rpc-url https://rpc.sepolia.mantle.xyz \
    --private-key $PRIVATE_KEY \
    --broadcast \
    -vvvv

# Catat WMNT address, Factory address, Router address, dan INIT_CODE_HASH dari output
```

**ATAU Deploy individual contracts dengan cast:**

### 1a. Deploy WMNT (WETH9) with cast

```bash
# Compile WETH9 to get bytecode
forge inspect lib/uniswap-v2-periphery/contracts/test/WETH9.sol:WETH9 bytecode --force

# Deploy
cast send --private-key $PRIVATE_KEY \
  --rpc-url https://rpc.sepolia.mantle.xyz \
  --create $(forge inspect lib/uniswap-v2-periphery/contracts/test/WETH9.sol:WETH9 bytecode --force)

# Save the deployed address
export WMNT=0x...  # dari output "Deployed to:"
echo "WMNT deployed at: $WMNT"
```

### 1b. Deploy UniswapV2Factory with cast

```bash
# Get deployer address
DEPLOYER=$(cast wallet address --private-key $PRIVATE_KEY)
echo "Deployer: $DEPLOYER"

# Get Factory bytecode
FACTORY_BYTECODE=$(forge inspect lib/uniswap-v2-core/contracts/UniswapV2Factory.sol:UniswapV2Factory bytecode --force)

# Encode constructor args (address feeToSetter)
FACTORY_CONSTRUCTOR=$(cast abi-encode "constructor(address)" $DEPLOYER)

# Deploy Factory
cast send --private-key $PRIVATE_KEY \
  --rpc-url https://rpc.sepolia.mantle.xyz \
  --create ${FACTORY_BYTECODE}${FACTORY_CONSTRUCTOR:2}

# Save address
export UNISWAP_FACTORY=0x...  # dari output "Deployed to:"
echo "Factory deployed at: $UNISWAP_FACTORY"
```

### 1c. Get INIT_CODE_HASH

```bash
# Get UniswapV2Pair bytecode
PAIR_BYTECODE=$(forge inspect lib/uniswap-v2-core/contracts/UniswapV2Pair.sol:UniswapV2Pair bytecode --force)

# Calculate keccak256 hash
INIT_CODE_HASH=$(cast keccak $PAIR_BYTECODE)

echo "INIT_CODE_HASH: $INIT_CODE_HASH"
# IMPORTANT: Save this hash!
```

### 1d. Deploy UniswapV2Router02 with cast

```bash
# Get Router bytecode
ROUTER_BYTECODE=$(forge inspect lib/uniswap-v2-periphery/contracts/UniswapV2Router02.sol:UniswapV2Router02 bytecode --force)

# Encode constructor args (address factory, address WETH)
ROUTER_CONSTRUCTOR=$(cast abi-encode "constructor(address,address)" $UNISWAP_FACTORY $WMNT)

# Deploy Router
cast send --private-key $PRIVATE_KEY \
  --rpc-url https://rpc.sepolia.mantle.xyz \
  --create ${ROUTER_BYTECODE}${ROUTER_CONSTRUCTOR:2}

# Save address
export UNISWAP_ROUTER=0x...  # dari output "Deployed to:"
echo "Router deployed at: $UNISWAP_ROUTER"
```

## Step 2: Update .env File

```bash
# Add to your .env file
echo "" >> .env
echo "# Uniswap V2 - Deployed $(date)" >> .env
echo "WMNT=$WMNT" >> .env
echo "UNISWAP_FACTORY=$UNISWAP_FACTORY" >> .env
echo "UNISWAP_ROUTER=$UNISWAP_ROUTER" >> .env
```

## Step 3: Verify Deployment

```bash
# Reload .env
source .env

# Check Factory
echo "Factory address: $UNISWAP_FACTORY"
cast call $UNISWAP_FACTORY "allPairsLength()(uint256)" --rpc-url $RPC_URL

# Check Router
echo "Router address: $UNISWAP_ROUTER"
cast call $UNISWAP_ROUTER "factory()(address)" --rpc-url $RPC_URL
cast call $UNISWAP_ROUTER "WETH()(address)" --rpc-url $RPC_URL
```

## Step 4: Create Pairs

```bash
# Token addresses
IDRX=0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05
USDC=0x96ABff3a2668B811371d7d763f06B3832CEdf38d
XAUT=0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78

# Create IDRX/USDC pair
echo "Creating IDRX/USDC pair..."
cast send $UNISWAP_FACTORY \
  "createPair(address,address)" \
  $IDRX \
  $USDC \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL

# Get pair address
PAIR_IDRX_USDC=$(cast call $UNISWAP_FACTORY \
  "getPair(address,address)(address)" \
  $IDRX \
  $USDC \
  --rpc-url $RPC_URL)
echo "IDRX/USDC pair: $PAIR_IDRX_USDC"

# Create XAUT/USDC pair
echo "Creating XAUT/USDC pair..."
cast send $UNISWAP_FACTORY \
  "createPair(address,address)" \
  $XAUT \
  $USDC \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL

# Get pair address
PAIR_XAUT_USDC=$(cast call $UNISWAP_FACTORY \
  "getPair(address,address)(address)" \
  $XAUT \
  $USDC \
  --rpc-url $RPC_URL)
echo "XAUT/USDC pair: $PAIR_XAUT_USDC"
```

## Step 5: Check Token Balances

```bash
# Get deployer address
DEPLOYER=$(cast wallet address --private-key $PRIVATE_KEY)

# Check balances
echo "Checking token balances for: $DEPLOYER"

IDRX_BAL=$(cast call $IDRX "balanceOf(address)(uint256)" $DEPLOYER --rpc-url $RPC_URL)
echo "IDRX Balance: $IDRX_BAL (need: 100000000 = 1M IDRX)"

USDC_BAL=$(cast call $USDC "balanceOf(address)(uint256)" $DEPLOYER --rpc-url $RPC_URL)
echo "USDC Balance: $USDC_BAL (need: 335000000000 = 335K USDC)"

XAUT_BAL=$(cast call $XAUT "balanceOf(address)(uint256)" $DEPLOYER --rpc-url $RPC_URL)
echo "XAUT Balance: $XAUT_BAL (need: 100000000 = 100 XAUT)"
```

## Step 6: Approve Tokens

```bash
# Approve IDRX
echo "Approving IDRX..."
cast send $IDRX \
  "approve(address,uint256)" \
  $UNISWAP_ROUTER \
  100000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL

# Approve USDC (total untuk both pairs)
echo "Approving USDC..."
cast send $USDC \
  "approve(address,uint256)" \
  $UNISWAP_ROUTER \
  335000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL

# Approve XAUT
echo "Approving XAUT..."
cast send $XAUT \
  "approve(address,uint256)" \
  $UNISWAP_ROUTER \
  100000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL
```

## Step 7: Add Liquidity

### 7a. Add IDRX/USDC Liquidity

```bash
# Calculate deadline (5 minutes from now)
DEADLINE=$(($(date +%s) + 300))

echo "Adding IDRX/USDC liquidity..."
echo "IDRX: 100000000 (1M)"
echo "USDC: 65000000000 (65K)"
echo "Deadline: $DEADLINE"

# Add liquidity
cast send $UNISWAP_ROUTER \
  "addLiquidity(address,address,uint256,uint256,uint256,uint256,address,uint256)" \
  $IDRX \
  $USDC \
  100000000 \
  65000000000 \
  95000000 \
  61750000000 \
  $DEPLOYER \
  $DEADLINE \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL \
  --gas-limit 500000

# Check reserves
echo "Checking IDRX/USDC reserves..."
cast call $PAIR_IDRX_USDC "getReserves()(uint112,uint112,uint32)" --rpc-url $RPC_URL
```

### 7b. Add XAUT/USDC Liquidity

```bash
# Calculate new deadline
DEADLINE=$(($(date +%s) + 300))

echo "Adding XAUT/USDC liquidity..."
echo "XAUT: 100000000 (100)"
echo "USDC: 270000000000 (270K)"
echo "Deadline: $DEADLINE"

# Add liquidity
cast send $UNISWAP_ROUTER \
  "addLiquidity(address,address,uint256,uint256,uint256,uint256,address,uint256)" \
  $XAUT \
  $USDC \
  100000000 \
  270000000000 \
  95000000 \
  256500000000 \
  $DEPLOYER \
  $DEADLINE \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL \
  --gas-limit 500000

# Check reserves
echo "Checking XAUT/USDC reserves..."
cast call $PAIR_XAUT_USDC "getReserves()(uint112,uint112,uint32)" --rpc-url $RPC_URL
```

## Step 8: Final Verification

```bash
echo "=== Deployment Complete ==="
echo ""
echo "WMNT: $WMNT"
echo "Factory: $UNISWAP_FACTORY"
echo "Router: $UNISWAP_ROUTER"
echo "INIT_CODE_HASH: $INIT_CODE_HASH"
echo ""
echo "Pair IDRX/USDC: $PAIR_IDRX_USDC"
echo "Pair XAUT/USDC: $PAIR_XAUT_USDC"
echo ""

# Check total pairs
TOTAL_PAIRS=$(cast call $UNISWAP_FACTORY "allPairsLength()(uint256)" --rpc-url $RPC_URL)
echo "Total pairs in factory: $TOTAL_PAIRS"

# View on explorer
echo ""
echo "View on Mantle Sepolia Explorer:"
echo "WMNT: https://sepolia.mantlescan.xyz/address/$WMNT"
echo "Factory: https://sepolia.mantlescan.xyz/address/$UNISWAP_FACTORY"
echo "Router: https://sepolia.mantlescan.xyz/address/$UNISWAP_ROUTER"
```

## Troubleshooting

### If token mint is needed:

```bash
# Mint IDRX (if you have minter role)
cast send $IDRX \
  "mint(address,uint256)" \
  $DEPLOYER \
  100000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL

# Mint USDC
cast send $USDC \
  "mint(address,uint256)" \
  $DEPLOYER \
  335000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL

# Mint XAUT
cast send $XAUT \
  "mint(address,uint256)" \
  $DEPLOYER \
  100000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL
```

### If deployment fails:

1. Check gas price: `cast gas-price --rpc-url $RPC_URL`
2. Check balance: `cast balance $DEPLOYER --rpc-url $RPC_URL`
3. Add `--gas-price` flag: `--gas-price 1000000000`
4. Increase gas limit: `--gas-limit 5000000`

### Contract Verification (Optional):

```bash
# Verify WMNT
forge verify-contract \
  --chain-id 5003 \
  --compiler-version v0.6.6+commit.6c089d02 \
  $WMNT \
  lib/uniswap-v2-periphery/contracts/test/WETH9.sol:WETH9 \
  --etherscan-api-key $MANTLESCAN_API_KEY

# Verify Factory
FACTORY_ARGS=$(cast abi-encode "constructor(address)" $DEPLOYER)
forge verify-contract \
  --chain-id 5003 \
  --compiler-version v0.6.6+commit.6c089d02 \
  --constructor-args $FACTORY_ARGS \
  $UNISWAP_FACTORY \
  lib/uniswap-v2-core/contracts/UniswapV2Factory.sol:UniswapV2Factory \
  --etherscan-api-key $MANTLESCAN_API_KEY

# Verify Router
ROUTER_ARGS=$(cast abi-encode "constructor(address,address)" $UNISWAP_FACTORY $WMNT)
forge verify-contract \
  --chain-id 5003 \
  --compiler-version v0.6.6+commit.6c089d02 \
  --constructor-args $ROUTER_ARGS \
  $UNISWAP_ROUTER \
  lib/uniswap-v2-periphery/contracts/UniswapV2Router02.sol:UniswapV2Router02 \
  --etherscan-api-key $MANTLESCAN_API_KEY
```
