# Deployment Scripts

Foundry scripts untuk deploy dan manage AuRoom Protocol contracts.

## 📁 Scripts Overview

### Core Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| [Deploy.s.sol](Deploy.s.sol) | Main deployment script | `forge script script/Deploy.s.sol --rpc-url $RPC --broadcast` |
| [Verify.s.sol](Verify.s.sol) | Verify contracts on explorer | `forge script script/Verify.s.sol --rpc-url $RPC --ffi` |
| [DeployConfig.sol](DeployConfig.sol) | Network configurations | Library (imported by other scripts) |
| [PostDeploymentSetup.s.sol](PostDeploymentSetup.s.sol) | Additional setup tasks | `forge script script/PostDeploymentSetup.s.sol --rpc-url $RPC --broadcast` |
| [DeploymentInfo.s.sol](DeploymentInfo.s.sol) | View deployment info | `forge script script/DeploymentInfo.s.sol --rpc-url $RPC` |
| [NetworkInfo.s.sol](NetworkInfo.s.sol) | Check network & account info | `forge script script/NetworkInfo.s.sol --rpc-url $RPC` |

## 🚀 Quick Start

### 1. Pre-Deployment Check

Check network status dan balance sebelum deploy:

```bash
export NETWORK=mantle-testnet
forge script script/NetworkInfo.s.sol --rpc-url $MANTLE_TESTNET_RPC
```

### 2. Deployment (Dry Run)

Test deployment tanpa broadcast:

```bash
forge script script/Deploy.s.sol --rpc-url $MANTLE_TESTNET_RPC
```

### 3. Deployment (Production)

Deploy dengan broadcast:

```bash
forge script script/Deploy.s.sol \
  --rpc-url $MANTLE_TESTNET_RPC \
  --broadcast \
  --verify \
  -vvvv
```

### 4. Post-Deployment

View deployment info:

```bash
export NETWORK=mantle-testnet
forge script script/DeploymentInfo.s.sol --rpc-url $MANTLE_TESTNET_RPC
```

## 📋 Script Details

### Deploy.s.sol

**Main deployment script** yang deploy semua contracts dalam urutan yang benar.

**Deployment Order:**
1. MockIDRX
2. MockUSDC
3. IdentityRegistry
4. XAUT (with IdentityRegistry)
5. GoldVault (with XAUT, IdentityRegistry, Router, USDC)
6. SwapRouter (with Router, IDRX, USDC, XAUT)

**Post-Deployment Actions:**
- Register deployer di IdentityRegistry
- Mint 1B IDRX ke deployer
- Mint 10M USDC ke deployer
- Mint 100 XAUT ke deployer
- Save addresses ke `deployments/mantle-testnet.json`

**Output:**
- Console: Deployment details dengan gas usage
- JSON: Contract addresses di `deployments/`

---

### Verify.s.sol

**Contract verification script** untuk verify di block explorer.

**Features:**
- Read deployment addresses dari JSON
- Verify semua contracts dengan constructor args
- Support Mantle Explorer

**Requirements:**
- `NETWORK` environment variable
- `UNISWAP_ROUTER` environment variable
- Valid deployment JSON file

**Usage:**
```bash
export NETWORK=mantle-testnet
export UNISWAP_ROUTER=0xYourRouterAddress
forge script script/Verify.s.sol --rpc-url $MANTLE_TESTNET_RPC --ffi
```

---

### DeployConfig.sol

**Configuration library** dengan network-specific settings.

**Functions:**
- `getUniswapRouter(chainId)` - Get router address for network
- `getNetworkName(chainId)` - Get network name string
- `isTestnet(chainId)` - Check if network is testnet

**Supported Networks:**
- Mantle Testnet (5003)
- Mantle Mainnet (5000)
- Localhost (31337)

---

### PostDeploymentSetup.s.sol

**Helper script** untuk additional setup setelah deployment.

**Functions:**
```solidity
registerAdditionalUsers()  // Register more users
mintTokensToUsers()        // Mint tokens to specific addresses
setupVaultPermissions()    // Configure vault approvals
verifyDeployment()         // Verify contract integrity
```

**Usage:**
1. Edit functions dengan addresses dan amounts yang diinginkan
2. Uncomment functions yang ingin dijalankan
3. Run script:
```bash
forge script script/PostDeploymentSetup.s.sol \
  --rpc-url $MANTLE_TESTNET_RPC \
  --broadcast \
  -vvvv
```

---

### DeploymentInfo.s.sol

**Info viewer** untuk display contract details.

**Displays:**
- Contract addresses
- Token info (name, symbol, decimals)
- Total supplies
- Owner addresses
- Vault statistics
- Router configurations

**Usage:**
```bash
export NETWORK=mantle-testnet
forge script script/DeploymentInfo.s.sol --rpc-url $MANTLE_TESTNET_RPC
```

---

### NetworkInfo.s.sol

**Pre-deployment checker** untuk verify network dan account status.

**Displays:**
- Network info (chain ID, block number, base fee)
- Deployer info (address, balance, nonce)
- Gas price (current, estimated)
- Deployment cost estimates
- Pre-deployment checks

**Pre-Deployment Checks:**
- ✅ Deployer has balance
- ✅ Environment variables set
- ✅ Network is correct
- ✅ Deployments directory exists

**Usage:**
```bash
export DEPLOYER_ADDRESS=0xYourAddress  # Optional
forge script script/NetworkInfo.s.sol --rpc-url $MANTLE_TESTNET_RPC
```

## 🔧 Configuration

### Environment Variables

Required:
```bash
PRIVATE_KEY=your_private_key
MANTLE_TESTNET_RPC=https://rpc.testnet.mantle.xyz
```

Optional:
```bash
NETWORK=mantle-testnet
UNISWAP_ROUTER=0xYourRouterAddress
MANTLE_API_KEY=your_api_key
DEPLOYER_ADDRESS=0xYourAddress
```

### Script Configuration

Edit [Deploy.s.sol](Deploy.s.sol) untuk update:

**Uniswap Router:**
```solidity
address constant UNISWAP_ROUTER = 0xYourAddress;
```

**Initial Token Amounts:**
```solidity
uint256 constant INITIAL_IDRX = 1_000_000_000 * 1e18;
uint256 constant INITIAL_USDC = 10_000_000 * 1e6;
uint256 constant INITIAL_XAUT = 100 * 1e6;
```

## 📤 Output Files

### deployments/mantle-testnet.json
```json
{
  "chainId": 5003,
  "network": "mantle-testnet",
  "timestamp": 1234567890,
  "deployer": "0x...",
  "MockIDRX": "0x...",
  "MockUSDC": "0x...",
  "IdentityRegistry": "0x...",
  "XAUT": "0x...",
  "GoldVault": "0x...",
  "SwapRouter": "0x..."
}
```

### broadcast/Deploy.s.sol/
Foundry broadcast logs dan transaction receipts.

## 🐛 Troubleshooting

### Script fails with "insufficient funds"

**Solution:**
```bash
# Check balance
forge script script/NetworkInfo.s.sol --rpc-url $MANTLE_TESTNET_RPC

# Get testnet tokens
# Visit: https://faucet.testnet.mantle.xyz/
```

### Script fails with "UNISWAP_ROUTER not configured"

**Solution:**
```bash
# Set environment variable
export UNISWAP_ROUTER=0xYourRouterAddress

# Or edit Deploy.s.sol line 20
```

### Verification fails

**Solution:**
```bash
# Verify manually
forge script script/Verify.s.sol --rpc-url $MANTLE_TESTNET_RPC --ffi

# Or verify individual contract
forge verify-contract <ADDRESS> <CONTRACT> --chain-id 5003
```

### "deployment file not found"

**Solution:**
```bash
# Create deployments directory
mkdir -p deployments

# Run deployment first
forge script script/Deploy.s.sol --rpc-url $RPC --broadcast
```

## 💡 Tips

1. **Always dry run first:**
   ```bash
   forge script script/Deploy.s.sol --rpc-url $RPC
   ```

2. **Check network info before deploy:**
   ```bash
   forge script script/NetworkInfo.s.sol --rpc-url $RPC
   ```

3. **Save deployment logs:**
   ```bash
   forge script script/Deploy.s.sol --rpc-url $RPC --broadcast -vvvv > deployment.log
   ```

4. **Resume failed deployment:**
   ```bash
   forge script script/Deploy.s.sol --rpc-url $RPC --broadcast --resume
   ```

5. **Use verbose output for debugging:**
   ```bash
   forge script script/Deploy.s.sol --rpc-url $RPC -vvvv
   ```

## 📚 Additional Resources

- [Deployment Guide](../DEPLOYMENT_GUIDE.md) - Full deployment documentation
- [Quick Deploy](../QUICK_DEPLOY.md) - Quick reference guide
- [Foundry Book](https://book.getfoundry.sh/) - Foundry documentation
- [Mantle Docs](https://docs.mantle.xyz/) - Mantle network documentation

## ⚠️ Security Notes

1. **Never commit `.env` files**
2. **Backup private keys securely**
3. **Test on testnet first**
4. **Verify contracts after deployment**
5. **Double-check constructor parameters**
6. **Save deployment addresses safely**

---

For issues or questions, check the main [DEPLOYMENT_GUIDE.md](../DEPLOYMENT_GUIDE.md) or open an issue.
