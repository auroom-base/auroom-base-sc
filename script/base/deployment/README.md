# Base Sepolia Deployment Scripts

Deployment scripts for AuRoom Protocol contracts on Base Sepolia Testnet.

## Prerequisites

1. **Fund your wallet** with ETH on Base Sepolia:
   - Faucet: https://faucet.quicknode.com/base/sepolia
   - Or: https://www.alchemy.com/faucets/base-sepolia

2. **Set environment variables** in `.env`:
   ```bash
   PRIVATE_KEY=your_private_key_here
   BASE_SEPOLIA_RPC=https://sepolia.base.org
   ```

## Deployment Order

Deploy contracts in this exact order:

### Phase 1: Core Tokens

```bash
# 1. Deploy MockIDRX
forge script script/base/deployment/Deploy01_MockIDRX.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC \
  --broadcast \
  --verify

# 2. Deploy MockUSDC
forge script script/base/deployment/Deploy02_MockUSDC.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC \
  --broadcast \
  --verify

# 3. Deploy IdentityRegistry (KYC)
forge script script/base/deployment/Deploy03_IdentityRegistry.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC \
  --broadcast \
  --verify
```

### Phase 2: Gold Token

```bash
# 4. Deploy XAUT (requires IDENTITY_REGISTRY in .env)
forge script script/base/deployment/Deploy04_MockXAUT.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC \
  --broadcast \
  --verify
```

### Phase 3: DEX Infrastructure

```bash
# 5. Deploy Uniswap V2 Factory
forge script script/base/deployment/Deploy05_UniswapV2Factory.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC \
  --broadcast \
  --verify

# 6. Deploy Uniswap V2 Router
forge script script/base/deployment/Deploy06_UniswapV2Router.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC \
  --broadcast
```

### Phase 4: Liquidity Pools

```bash
# 7. Setup Liquidity (requires all tokens + DEX in .env)
forge script script/base/deployment/Deploy07_SetupLiquidity.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC \
  --broadcast
```

### Phase 5: AuRoom Protocol

```bash
# 8. Deploy SwapRouter
forge script script/base/deployment/Deploy08_SwapRouter.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC \
  --broadcast

# 9. Deploy BorrowingProtocolV2
forge script script/base/deployment/Deploy09_BorrowingProtocolV2.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC \
  --broadcast
```

## Environment Variables

After each deployment, add the contract address to `.env`:

```bash
# Tokens
MOCK_IDRX=<deployed_address>
MOCK_USDC=<deployed_address>
XAUT=<deployed_address>

# Infrastructure
IDENTITY_REGISTRY=<deployed_address>
UNISWAP_FACTORY=<deployed_address>
UNISWAP_ROUTER=<deployed_address>

# Pairs
PAIR_IDRX_USDC=<deployed_address>
PAIR_XAUT_USDC=<deployed_address>

# Protocol
SWAP_ROUTER=<deployed_address>
BORROWING_PROTOCOL_V2=<deployed_address>
```

## Verification

Verification may fail if done immediately after deployment. Use the post-deployment script:

```bash
# Wait 1-2 minutes after all deployments, then run:
./script/base/post-deployment/verify-all.sh
```

Or manually verify:

```bash
forge verify-contract <CONTRACT_ADDRESS> <CONTRACT_NAME> \
  --chain-id 84532 \
  --verifier blockscout \
  --verifier-url https://base-sepolia.blockscout.com/api
```

## Network Information

| Property | Value |
|----------|-------|
| Network | Base Sepolia Testnet |
| Chain ID | 84532 |
| RPC URL | https://sepolia.base.org |
| Block Explorer | https://sepolia.basescan.org |
| Blockscout | https://base-sepolia.blockscout.com |
| Native Token | ETH |

## Liquidity Ratios

| Pair | Ratio |
|------|-------|
| IDRX/USDC | 1 USDC = 16,500 IDRX |
| XAUT/USDC | 1 XAUT = 4,000 USDC |
| XAUT/IDRX | 1 XAUT = 66,000,000 IDRX |

## Protocol Parameters

| Parameter | Value |
|-----------|-------|
| MAX_LTV | 75% (7500 bps) |
| WARNING_LTV | 80% (8000 bps) |
| LIQUIDATION_LTV | 90% (9000 bps) |
| BORROW_FEE | 0.5% (50 bps) |

## Troubleshooting

### "IDENTITY_REGISTRY not set in .env"
Make sure you've deployed IdentityRegistry (Deploy03) first and added its address to `.env`.

### "Insufficient funds"
Get more ETH from the faucet: https://faucet.quicknode.com/base/sepolia

### "Verification failed"
Try manual verification using the commands above, or wait a few minutes and retry.

### "XAUT mint failed"
Ensure the deployer is registered in IdentityRegistry. Deploy03 auto-registers the deployer.
