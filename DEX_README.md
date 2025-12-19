# Uniswap V2 DEX - Quick Start

Quick guide untuk deploy Uniswap V2 DEX di Mantle Sepolia.

## 🚀 Quick Deployment

### Option 1: Automated Script (Recommended)

```bash
# 1. Setup environment
cp .env.example .env
# Edit .env dengan PRIVATE_KEY dan RPC URL

# 2. Run automated deployment
chmod +x scripts/deploy-dex.sh
./scripts/deploy-dex.sh

# 3. Verify contracts
chmod +x scripts/verify-dex.sh
./scripts/verify-dex.sh
```

### Option 2: Manual Deployment

See [DEX_DEPLOYMENT.md](DEX_DEPLOYMENT.md) for detailed instructions.

## 📋 What Gets Deployed

1. **WMNT** - Wrapped MNT (ERC20 wrapper for native MNT)
2. **UniswapV2Factory** - Creates trading pairs
3. **UniswapV2Router02** - Handles swaps and liquidity

## 📁 Output Files

After deployment:
- `deployments/wmnt-mantle-sepolia.json` - WMNT address
- `deployments/dex-mantle-sepolia.json` - All DEX addresses

## 🔑 Deployed Addresses

Check `deployments/dex-mantle-sepolia.json`:
```json
{
  "WMNT": "0x...",
  "UniswapV2Factory": "0x...",
  "UniswapV2Router02": "0x...",
  "INIT_CODE_HASH": "0x96e8ac4277..."
}
```

## ✅ Testing

### Create a Pair

```bash
# Example: Create XAUT/USDC pair
cast send <FACTORY_ADDRESS> \
  "createPair(address,address)" \
  <XAUT_ADDRESS> \
  <USDC_ADDRESS> \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY
```

### Add Liquidity

```bash
# 1. Approve tokens
cast send <TOKEN_A> "approve(address,uint256)" <ROUTER> 1000000000 --rpc-url $RPC --private-key $PK
cast send <TOKEN_B> "approve(address,uint256)" <ROUTER> 1000000000 --rpc-url $RPC --private-key $PK

# 2. Add liquidity
cast send <ROUTER_ADDRESS> \
  "addLiquidity(address,address,uint256,uint256,uint256,uint256,address,uint256)" \
  <TOKEN_A> <TOKEN_B> \
  100000000 100000000 \
  0 0 \
  $DEPLOYER_ADDRESS \
  $(date -d "+10 minutes" +%s) \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY
```

## 🔄 Using with AuRoom Protocol

After DEX deployment, update [script/Deploy.s.sol](script/Deploy.s.sol):

```solidity
// Replace mock router with real deployed router
address constant UNISWAP_ROUTER = 0x...; // Your deployed Router address
```

Then deploy AuRoom:
```bash
make deploy
```

## 📚 Documentation

- [DEX_DEPLOYMENT.md](DEX_DEPLOYMENT.md) - Detailed deployment guide
- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - AuRoom deployment guide

## ⚠️ Important Notes

- Factory and Router use **legacy Solidity versions** (0.5.16 and 0.6.6)
- Use `--legacy` flag when deploying manually
- INIT_CODE_HASH: `0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f`
- Test on Sepolia before mainnet!

## 🐛 Troubleshooting

**Error: "Failed to deploy"**
- Check balance: `cast balance $DEPLOYER --rpc-url $RPC`
- Get testnet MNT: https://faucet.sepolia.mantle.xyz/

**Error: "Verification failed"**
- Contracts may already be verified
- Check Mantle Explorer manually

**Error: "INIT_CODE_HASH mismatch"**
- Use default hash: `0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f`
- Or calculate from deployed Pair bytecode

## 📞 Support

See [DEX_DEPLOYMENT.md](DEX_DEPLOYMENT.md) for:
- Detailed deployment steps
- Verification instructions
- Testing procedures
- Troubleshooting guide

---

**Status:** Ready for deployment ✅
**Network:** Mantle Sepolia Testnet
**Tested:** ✅ WMNT, Factory, Router deployment
