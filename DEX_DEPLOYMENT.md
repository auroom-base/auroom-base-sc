# Uniswap V2 DEX Deployment Guide for Mantle Sepolia

Complete guide untuk deploy Uniswap V2 DEX (Factory + Router) di Mantle Sepolia Testnet.

## 📋 Overview

Kita akan deploy 3 contracts:
1. **WMNT** (Wrapped MNT) - ERC20 wrapper untuk native MNT token
2. **UniswapV2Factory** - Factory contract untuk create pairs
3. **UniswapV2Router02** - Router contract untuk swaps dan liquidity

## 🔧 Prerequisites

```bash
# 1. Install dependencies (already done)
forge install

# 2. Setup environment
cp .env.example .env
# Edit .env dengan PRIVATE_KEY dan MANTLE_TESTNET_RPC

# 3. Ensure you have MNT testnet tokens
# Get from: https://faucet.sepolia.mantle.xyz/
```

## 🚀 Deployment Steps

### Step 1: Deploy WMNT

```bash
# Run deployment script
forge script script/DeployDEX.s.sol \
  --rpc-url $MANTLE_TESTNET_RPC \
  --broadcast \
  -vvvv
```

**Output:**
- WMNT address will be saved to `deployments/wmnt-mantle-sepolia.json`
- Note the WMNT address for next steps

**Example Output:**
```
WMNT deployed at: 0x1234...5678
Name: Wrapped MNT
Symbol: WMNT
Decimals: 18
```

### Step 2: Deploy UniswapV2Factory

The Factory contract is compiled with Solidity 0.5.16, so we need to use `forge create` with `--legacy` flag.

```bash
# Deploy Factory
forge create lib/uniswap-v2-core/contracts/UniswapV2Factory.sol:UniswapV2Factory \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY \
  --constructor-args $DEPLOYER_ADDRESS \
  --legacy \
  -vvvv
```

**Parameters:**
- `constructor-args`: Your deployer address (fee to setter)

**Example Output:**
```
Deployer: 0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1
Deployed to: 0xAbCd...1234
Transaction hash: 0x...
```

**Save the Factory address!**

### Step 3: Get INIT_CODE_HASH

After Factory is deployed, we need to get the INIT_CODE_HASH for pair creation:

```bash
# Get pair bytecode hash
cast call <FACTORY_ADDRESS> "INIT_CODE_PAIR_HASH()(bytes32)" \
  --rpc-url $MANTLE_TESTNET_RPC
```

Or calculate it manually:
```bash
# This returns the keccak256 of UniswapV2Pair bytecode
# Should be: 0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f
```

**Important:** This hash is used in UniswapV2Library for pair address calculation.

### Step 4: Deploy UniswapV2Router02

The Router contract is compiled with Solidity 0.6.6, also needs `--legacy` flag.

```bash
# Get WMNT address from previous deployment
WMNT_ADDRESS=$(jq -r '.WMNT' deployments/wmnt-mantle-sepolia.json)

# Deploy Router
forge create lib/uniswap-v2-periphery/contracts/UniswapV2Router02.sol:UniswapV2Router02 \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY \
  --constructor-args <FACTORY_ADDRESS> $WMNT_ADDRESS \
  --legacy \
  -vvvv
```

**Parameters:**
- `constructor-args`: Factory address (from Step 2), WMNT address (from Step 1)

**Example Output:**
```
Deployer: 0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1
Deployed to: 0x9876...5432
Transaction hash: 0x...
```

### Step 5: Save All Addresses

Create a JSON file with all deployed addresses:

```bash
# Create deployments/dex-mantle-sepolia.json
cat > deployments/dex-mantle-sepolia.json << EOF
{
  "chainId": 5003,
  "network": "mantle-sepolia",
  "timestamp": $(date +%s),
  "deployer": "$DEPLOYER_ADDRESS",
  "WMNT": "$WMNT_ADDRESS",
  "UniswapV2Factory": "<FACTORY_ADDRESS>",
  "UniswapV2Router02": "<ROUTER_ADDRESS>",
  "INIT_CODE_HASH": "<INIT_CODE_HASH>"
}
EOF
```

## ✅ Verification

### Verify WMNT

```bash
forge verify-contract <WMNT_ADDRESS> \
  src/WMNT.sol:WMNT \
  --chain-id 5003 \
  --watch
```

### Verify Factory

```bash
forge verify-contract <FACTORY_ADDRESS> \
  lib/uniswap-v2-core/contracts/UniswapV2Factory.sol:UniswapV2Factory \
  --chain-id 5003 \
  --constructor-args $(cast abi-encode "constructor(address)" $DEPLOYER_ADDRESS) \
  --watch
```

### Verify Router

```bash
forge verify-contract <ROUTER_ADDRESS> \
  lib/uniswap-v2-periphery/contracts/UniswapV2Router02.sol:UniswapV2Router02 \
  --chain-id 5003 \
  --constructor-args $(cast abi-encode "constructor(address,address)" <FACTORY_ADDRESS> $WMNT_ADDRESS) \
  --watch
```

## 🧪 Testing

### Test 1: Create a Pair

```bash
# Create XAUT/USDC pair using Factory
cast send <FACTORY_ADDRESS> \
  "createPair(address,address)" \
  <XAUT_ADDRESS> \
  <USDC_ADDRESS> \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY

# Get pair address
cast call <FACTORY_ADDRESS> \
  "getPair(address,address)(address)" \
  <XAUT_ADDRESS> \
  <USDC_ADDRESS> \
  --rpc-url $MANTLE_TESTNET_RPC
```

### Test 2: Add Liquidity

```bash
# First, approve router to spend tokens
cast send <XAUT_ADDRESS> \
  "approve(address,uint256)" \
  <ROUTER_ADDRESS> \
  1000000000000000000000 \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY

cast send <USDC_ADDRESS> \
  "approve(address,uint256)" \
  <ROUTER_ADDRESS> \
  1000000000000000000000 \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY

# Add liquidity
cast send <ROUTER_ADDRESS> \
  "addLiquidity(address,address,uint256,uint256,uint256,uint256,address,uint256)" \
  <XAUT_ADDRESS> \
  <USDC_ADDRESS> \
  100000000 \
  100000000 \
  0 \
  0 \
  $DEPLOYER_ADDRESS \
  $(date -d "+10 minutes" +%s) \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY
```

### Test 3: Swap Tokens

```bash
# Swap 1 XAUT for USDC
cast send <ROUTER_ADDRESS> \
  "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)" \
  1000000 \
  0 \
  [<XAUT_ADDRESS>,<USDC_ADDRESS>] \
  $DEPLOYER_ADDRESS \
  $(date -d "+10 minutes" +%s) \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY
```

## 📝 Deployed Addresses

After deployment, save these addresses for AuRoom protocol:

```json
{
  "WMNT": "0x...",
  "UniswapV2Factory": "0x...",
  "UniswapV2Router02": "0x...",
  "INIT_CODE_HASH": "0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f"
}
```

## 🔄 Update AuRoom Deployment

After DEX is deployed, update the main deployment script:

```solidity
// In script/Deploy.s.sol
address constant UNISWAP_ROUTER = 0x...; // Use deployed Router address
```

Or remove mock Uniswap deployment section and use the real addresses.

## ⚠️ Important Notes

1. **Solidity Versions:**
   - WMNT: 0.8.30
   - Factory: 0.5.16 (use --legacy flag)
   - Router: 0.6.6 (use --legacy flag)

2. **INIT_CODE_HASH:**
   - Must match the hash of UniswapV2Pair bytecode
   - Default: `0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f`
   - Verify this matches your deployment

3. **Gas Costs:**
   - WMNT: ~500k gas
   - Factory: ~2.5M gas
   - Router: ~3.5M gas
   - Total: ~6.5M gas

4. **Constructor Args:**
   - Factory: `feeToSetter` (your address)
   - Router: `factory` and `WMNT` addresses

## 🐛 Troubleshooting

### Error: "Compiler version mismatch"
**Solution:** Use `--legacy` flag for Factory and Router deployment

### Error: "Failed to verify contract"
**Solution:** Make sure to include correct constructor args in verification

### Error: "INIT_CODE_HASH mismatch"
**Solution:** Calculate the correct hash from deployed Pair bytecode

### Error: "UniswapV2: INSUFFICIENT_LIQUIDITY"
**Solution:** Add liquidity to the pair first before swapping

## 📚 Resources

- [Uniswap V2 Core](https://github.com/Uniswap/v2-core)
- [Uniswap V2 Periphery](https://github.com/Uniswap/v2-periphery)
- [Uniswap V2 Docs](https://docs.uniswap.org/contracts/v2/overview)
- [Mantle Sepolia Explorer](https://sepolia.mantlescan.xyz/)
- [Mantle Sepolia Faucet](https://faucet.sepolia.mantle.xyz/)

## 🎯 Summary

Deployment checklist:
- [ ] Deploy WMNT
- [ ] Deploy UniswapV2Factory
- [ ] Get INIT_CODE_HASH
- [ ] Deploy UniswapV2Router02
- [ ] Save all addresses to JSON
- [ ] Verify all contracts
- [ ] Test create pair
- [ ] Test add liquidity
- [ ] Test swap
- [ ] Update AuRoom deployment script

---

**Ready to deploy AuRoom Protocol after DEX is live!** 🚀
