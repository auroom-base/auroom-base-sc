# Deployment Scripts - Summary

Rangkuman lengkap deployment scripts untuk AuRoom Protocol.

## 📁 Files Created

### 1. Core Deployment Scripts

#### [script/Deploy.s.sol](script/Deploy.s.sol)
**Main deployment script** - Deploy semua contracts dengan urutan yang benar.

**Features:**
- ✅ Auto deploy semua 6 contracts (MockIDRX, MockUSDC, IdentityRegistry, XAUT, GoldVault, SwapRouter)
- ✅ Deployment dengan urutan dependencies yang benar
- ✅ Gas estimation logging per contract
- ✅ Post-deployment setup otomatis:
  - Register deployer di IdentityRegistry
  - Mint initial tokens (1B IDRX, 10M USDC, 100 XAUT)
- ✅ Save addresses ke JSON file
- ✅ Detailed console logging

**Usage:**
```bash
# Dry run
forge script script/Deploy.s.sol --rpc-url $MANTLE_TESTNET_RPC

# Deploy
forge script script/Deploy.s.sol --rpc-url $MANTLE_TESTNET_RPC --broadcast --verify -vvvv
```

---

#### [script/DeployConfig.sol](script/DeployConfig.sol)
**Configuration library** - Network-specific configurations.

**Features:**
- ✅ Network constants (Chain IDs)
- ✅ Initial token amounts
- ✅ Uniswap Router addresses per network
- ✅ Helper functions (getUniswapRouter, getNetworkName, isTestnet)

**Supported Networks:**
- Mantle Testnet (Chain ID: 5003)
- Mantle Mainnet (Chain ID: 5000)
- Localhost (Chain ID: 31337)

---

#### [script/Verify.s.sol](script/Verify.s.sol)
**Contract verification script** - Verify contracts di block explorer.

**Features:**
- ✅ Read deployment addresses dari JSON
- ✅ Auto verify semua contracts
- ✅ Include constructor arguments
- ✅ Support untuk Mantle Explorer

**Usage:**
```bash
export NETWORK=mantle-testnet
forge script script/Verify.s.sol --rpc-url $MANTLE_TESTNET_RPC --ffi
```

---

#### [script/PostDeploymentSetup.s.sol](script/PostDeploymentSetup.s.sol)
**Post-deployment helper script** - Setup tambahan setelah deployment.

**Features:**
- ✅ Register additional users
- ✅ Mint tokens ke specific addresses
- ✅ Setup vault permissions
- ✅ Verify deployment integrity

**Usage:**
```bash
forge script script/PostDeploymentSetup.s.sol --rpc-url $MANTLE_TESTNET_RPC --broadcast -vvvv
```

---

#### [script/DeploymentInfo.s.sol](script/DeploymentInfo.s.sol)
**Deployment info viewer** - Display detailed contract information.

**Features:**
- ✅ Read deployment addresses
- ✅ Query contract states
- ✅ Display token info (name, symbol, decimals, supply)
- ✅ Display vault stats
- ✅ Display router configuration

**Usage:**
```bash
export NETWORK=mantle-testnet
forge script script/DeploymentInfo.s.sol --rpc-url $MANTLE_TESTNET_RPC
```

---

### 2. Shell Scripts

#### [scripts/deploy.sh](scripts/deploy.sh)
**Bash deployment script** - Automated deployment dengan safety checks.

**Features:**
- ✅ Environment validation
- ✅ Build before deploy
- ✅ Interactive confirmation
- ✅ Dry run support
- ✅ Optional verification
- ✅ Verbose logging

**Usage:**
```bash
./scripts/deploy.sh              # Deploy with confirmation
./scripts/deploy.sh --dry-run    # Simulation only
./scripts/deploy.sh --no-verify  # Skip verification
./scripts/deploy.sh --verbose    # Detailed output
```

---

### 3. Build Tools

#### [Makefile](Makefile)
**Make commands** - Simplified deployment commands.

**Available Commands:**
```bash
make help           # Show all commands
make install        # Install dependencies
make build          # Build contracts
make test           # Run tests
make test-gas       # Test with gas report
make clean          # Clean artifacts

# Deployment
make deploy-dry     # Dry run
make deploy         # Deploy with confirmation
make deploy-force   # Deploy without confirmation
make deploy-local   # Deploy to localhost
make verify         # Verify contracts
make setup          # Post-deployment setup

# Utilities
make status         # Check deployment status
make balance        # Check deployer balance
make gas-price      # Check gas price
make format         # Format code
make lint           # Lint code
make coverage       # Coverage report
make snapshot       # Gas snapshot
make anvil          # Start local node

# Advanced
make deploy-with-gas   # Deploy with custom gas
make deploy-resume     # Resume failed deployment
```

---

### 4. Configuration Files

#### [.env.example](.env.example)
**Environment template** - Template untuk .env file.

**Variables:**
```bash
PRIVATE_KEY=                    # Deployer private key
MANTLE_TESTNET_RPC=            # Mantle testnet RPC
MANTLE_MAINNET_RPC=            # Mantle mainnet RPC
UNISWAP_ROUTER=                # Uniswap router address
MANTLE_API_KEY=                # Explorer API key
NETWORK=mantle-testnet         # Default network
```

---

#### [foundry.toml](foundry.toml)
**Foundry configuration** - Enhanced Foundry settings.

**Features:**
- ✅ Compiler settings (0.8.30, optimizer)
- ✅ Script configuration
- ✅ File system permissions untuk JSON output
- ✅ Test configuration (gas reports, fuzz)
- ✅ Code formatting rules
- ✅ RPC endpoints
- ✅ Etherscan verification settings

---

### 5. Documentation

#### [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
**Complete deployment guide** - Full documentation untuk deployment.

**Sections:**
- Prerequisites & Installation
- Deployment Order & Dependencies
- Post-Deployment Setup
- Deployment Commands (with examples)
- Manual Verification
- Deployment Output (Console & JSON)
- Configuration Guide
- Troubleshooting
- Advanced Usage
- Post-Deployment Checklist
- Security Notes

---

#### [QUICK_DEPLOY.md](QUICK_DEPLOY.md)
**Quick reference** - Fast reference untuk common commands.

**Sections:**
- Prerequisites (minimal)
- Deploy Commands (3 options)
- Post-Deployment (quick steps)
- Quick Troubleshooting
- Important Notes

---

## 🚀 Quick Start

1. **Setup Environment**
   ```bash
   cp .env.example .env
   # Edit .env dengan private key dan RPC URL
   ```

2. **Install Dependencies**
   ```bash
   make install
   ```

3. **Deploy**
   ```bash
   make deploy-dry      # Test first
   make deploy          # Deploy
   ```

4. **Verify**
   ```bash
   make status          # Check addresses
   make verify          # Verify contracts
   ```

## 📊 Deployment Order

Script otomatis deploy dalam urutan:

```
1. MockIDRX
   └─> 2. MockUSDC
       └─> 3. IdentityRegistry
           └─> 4. XAUT (requires IdentityRegistry)
               └─> 5. GoldVault (requires XAUT, IdentityRegistry, Router, USDC)
                   └─> 6. SwapRouter (requires Router, IDRX, USDC, XAUT)
```

## 🔧 Configuration

### Update Uniswap Router

**Option 1:** Edit [script/Deploy.s.sol](script/Deploy.s.sol)
```solidity
address constant UNISWAP_ROUTER = 0xYourAddress;
```

**Option 2:** Set environment variable
```bash
export UNISWAP_ROUTER=0xYourAddress
```

### Update Initial Amounts

Edit [script/Deploy.s.sol](script/Deploy.s.sol):
```solidity
uint256 constant INITIAL_IDRX = 1_000_000_000 * 1e18;
uint256 constant INITIAL_USDC = 10_000_000 * 1e6;
uint256 constant INITIAL_XAUT = 100 * 1e6;
```

## 📝 Output Files

### deployments/mantle-testnet.json
Deployment addresses dalam format JSON:
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
Foundry deployment logs dan transaction data.

## 🛠️ Troubleshooting

| Error | Solution |
|-------|----------|
| "insufficient funds" | Get testnet tokens dari faucet |
| "UNISWAP_ROUTER not configured" | Update router address di Deploy.s.sol |
| "verification failed" | Run `make verify` manually |
| "nonce too low" | Check nonce: `cast nonce <address>` |
| "deployment file not found" | Run deployment first |

## ⚠️ Important Notes

1. **Always test dengan `--dry-run` terlebih dahulu**
2. **Backup private keys dengan aman**
3. **Save deployment addresses (deployments/mantle-testnet.json)**
4. **Verify contracts di explorer**
5. **Test functionality sebelum production use**

## 📚 Additional Resources

- Full Guide: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- Quick Ref: [QUICK_DEPLOY.md](QUICK_DEPLOY.md)
- Testing: [TESTING_GUIDE.md](TESTING_GUIDE.md)
- Test Results: [TEST_RESULTS.md](TEST_RESULTS.md)
- Mantle Testnet Explorer: https://explorer.testnet.mantle.xyz/
- Mantle Faucet: https://faucet.testnet.mantle.xyz/
- Foundry Docs: https://book.getfoundry.sh/

## 🎯 Features Summary

✅ **Automated Deployment** - One command deploy semua contracts
✅ **Proper Dependencies** - Deploy dalam urutan yang benar
✅ **Gas Estimation** - Track gas usage per contract
✅ **Auto Configuration** - Post-deployment setup otomatis
✅ **JSON Output** - Save addresses untuk frontend integration
✅ **Verification** - Auto/manual contract verification
✅ **Error Handling** - Proper error messages dan validation
✅ **Multiple Interfaces** - Forge script, Shell script, Makefile
✅ **Network Support** - Testnet, Mainnet, Localhost
✅ **Dry Run Mode** - Safe testing before broadcast
✅ **Resume Support** - Continue failed deployments
✅ **Detailed Logging** - Verbose output dengan colors

## 📞 Support

Jika menemui masalah atau ada pertanyaan:
1. Check documentation files
2. Review error messages dengan `-vvvv` flag
3. Check broadcast logs di `broadcast/` directory
4. Open issue di repository
5. Contact development team

---

**Created for AuRoom Protocol**
Deployment automation untuk Mantle Testnet
