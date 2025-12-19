# Deployment Files Index

Complete index of all deployment-related files untuk AuRoom Protocol.

## 📑 Quick Navigation

| Category | File | Description |
|----------|------|-------------|
| **📖 Documentation** | [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) | Complete deployment guide |
| | [QUICK_DEPLOY.md](QUICK_DEPLOY.md) | Quick reference for deployment |
| | [DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md) | Summary of all deployment files |
| | [DEPLOYMENT_INDEX.md](DEPLOYMENT_INDEX.md) | This file - complete index |
| **🔧 Scripts** | [script/Deploy.s.sol](script/Deploy.s.sol) | Main deployment script |
| | [script/Verify.s.sol](script/Verify.s.sol) | Contract verification script |
| | [script/DeployConfig.sol](script/DeployConfig.sol) | Network configuration library |
| | [script/PostDeploymentSetup.s.sol](script/PostDeploymentSetup.s.sol) | Post-deployment setup helper |
| | [script/DeploymentInfo.s.sol](script/DeploymentInfo.s.sol) | Deployment info viewer |
| | [script/NetworkInfo.s.sol](script/NetworkInfo.s.sol) | Network & account checker |
| | [script/README.md](script/README.md) | Scripts documentation |
| **🛠️ Build Tools** | [Makefile](Makefile) | Make commands for deployment |
| | [scripts/deploy.sh](scripts/deploy.sh) | Bash deployment script |
| **⚙️ Configuration** | [.env.example](.env.example) | Environment variables template |
| | [foundry.toml](foundry.toml) | Foundry configuration |
| **📁 Output** | `deployments/*.json` | Deployment addresses (created after deploy) |
| | `broadcast/` | Foundry broadcast logs (created after deploy) |

## 📚 Documentation Files

### [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
**Complete deployment guide** dengan detailed instructions.

**Contents:**
- ✅ Prerequisites & Installation
- ✅ Deployment Order & Dependencies
- ✅ Post-Deployment Setup
- ✅ Deployment Commands
- ✅ Manual Verification
- ✅ Configuration Guide
- ✅ Troubleshooting (detailed)
- ✅ Advanced Usage
- ✅ Post-Deployment Checklist
- ✅ Security Notes

**Use for:** First-time deployment, detailed reference

---

### [QUICK_DEPLOY.md](QUICK_DEPLOY.md)
**Quick reference** untuk experienced users.

**Contents:**
- ⚡ Prerequisites (minimal)
- ⚡ Deploy Commands (3 options)
- ⚡ Post-Deployment (quick)
- ⚡ Quick Troubleshooting
- ⚡ Important Notes

**Use for:** Quick deployment, command reference

---

### [DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md)
**Complete summary** of all deployment files dan features.

**Contents:**
- 📋 Files Created (detailed)
- 📋 Features per file
- 📋 Usage examples
- 📋 Configuration guide
- 📋 Troubleshooting table
- 📋 Resources

**Use for:** Understanding the deployment system

---

### [script/README.md](script/README.md)
**Scripts documentation** - detailed guide untuk semua scripts.

**Contents:**
- 📋 Scripts Overview (table)
- 📋 Detailed script documentation
- 📋 Configuration guide
- 📋 Troubleshooting
- 📋 Tips & tricks

**Use for:** Understanding and using deployment scripts

## 🔧 Deployment Scripts

### Core Scripts

#### [script/Deploy.s.sol](script/Deploy.s.sol)
**Main deployment script**

**What it does:**
- ✅ Deploy 6 contracts in correct order
- ✅ Initialize contracts with proper parameters
- ✅ Register deployer in IdentityRegistry
- ✅ Mint initial tokens (IDRX, USDC, XAUT)
- ✅ Save addresses to JSON file
- ✅ Log gas usage per contract

**Usage:**
```bash
# Dry run
forge script script/Deploy.s.sol --rpc-url $RPC

# Deploy
forge script script/Deploy.s.sol --rpc-url $RPC --broadcast --verify -vvvv
```

---

#### [script/Verify.s.sol](script/Verify.s.sol)
**Contract verification**

**What it does:**
- ✅ Read deployment addresses from JSON
- ✅ Verify all 6 contracts on block explorer
- ✅ Include constructor arguments
- ✅ Support Mantle Explorer API

**Usage:**
```bash
export NETWORK=mantle-testnet
forge script script/Verify.s.sol --rpc-url $RPC --ffi
```

---

#### [script/DeployConfig.sol](script/DeployConfig.sol)
**Configuration library**

**What it provides:**
- ✅ Network constants (chain IDs)
- ✅ Initial token amounts
- ✅ Uniswap router addresses
- ✅ Helper functions (getUniswapRouter, getNetworkName, isTestnet)

**Usage:**
```solidity
import "./DeployConfig.sol";

address router = DeployConfig.getUniswapRouter(block.chainid);
string memory network = DeployConfig.getNetworkName(block.chainid);
```

---

#### [script/PostDeploymentSetup.s.sol](script/PostDeploymentSetup.s.sol)
**Post-deployment helper**

**What it does:**
- ✅ Register additional users
- ✅ Mint tokens to specific addresses
- ✅ Setup vault permissions
- ✅ Verify deployment integrity

**Usage:**
```bash
forge script script/PostDeploymentSetup.s.sol --rpc-url $RPC --broadcast -vvvv
```

---

#### [script/DeploymentInfo.s.sol](script/DeploymentInfo.s.sol)
**Deployment info viewer**

**What it shows:**
- ✅ Contract addresses
- ✅ Token info (name, symbol, decimals, supply)
- ✅ Vault statistics
- ✅ Router configuration
- ✅ Owner addresses

**Usage:**
```bash
export NETWORK=mantle-testnet
forge script script/DeploymentInfo.s.sol --rpc-url $RPC
```

---

#### [script/NetworkInfo.s.sol](script/NetworkInfo.s.sol)
**Pre-deployment checker**

**What it shows:**
- ✅ Network info (chain ID, block, gas)
- ✅ Deployer info (address, balance, nonce)
- ✅ Deployment cost estimates
- ✅ Pre-deployment validation checks

**Usage:**
```bash
forge script script/NetworkInfo.s.sol --rpc-url $RPC
```

## 🛠️ Build Tools

### [Makefile](Makefile)
**Make commands** untuk simplified deployment.

**Available Commands:**
```bash
# Build & Test
make install        # Install dependencies
make build          # Build contracts
make test           # Run tests
make clean          # Clean artifacts

# Deploy
make deploy-dry     # Dry run
make deploy         # Deploy with confirmation
make deploy-force   # Deploy without confirmation
make verify         # Verify contracts
make setup          # Post-deployment setup

# Info
make status         # Check deployment status
make balance        # Check deployer balance
make gas-price      # Check gas price

# Utils
make format         # Format code
make lint           # Lint code
make coverage       # Coverage report
make snapshot       # Gas snapshot
```

**Most Used:**
```bash
make deploy-dry     # Always test first
make deploy         # Production deployment
make status         # Check results
```

---

### [scripts/deploy.sh](scripts/deploy.sh)
**Bash deployment script** dengan interactive prompts.

**Features:**
- ✅ Environment validation
- ✅ Build before deploy
- ✅ Interactive confirmation
- ✅ Dry run support
- ✅ Optional verification
- ✅ Error handling

**Usage:**
```bash
./scripts/deploy.sh              # Deploy with confirmation
./scripts/deploy.sh --dry-run    # Simulation only
./scripts/deploy.sh --no-verify  # Skip verification
./scripts/deploy.sh --verbose    # Detailed output
./scripts/deploy.sh --help       # Show help
```

## ⚙️ Configuration Files

### [.env.example](.env.example)
**Environment variables template**

**Variables:**
```bash
# Required
PRIVATE_KEY=                    # Deployer private key
MANTLE_TESTNET_RPC=            # RPC URL

# Optional
UNISWAP_ROUTER=                # Router address
MANTLE_API_KEY=                # Explorer API key
NETWORK=mantle-testnet         # Default network
```

**Setup:**
```bash
cp .env.example .env
# Edit .env with your values
```

---

### [foundry.toml](foundry.toml)
**Foundry configuration**

**Settings:**
- ✅ Compiler settings (0.8.30, optimizer)
- ✅ Script configuration
- ✅ File system permissions for JSON output
- ✅ Test configuration
- ✅ Code formatting rules
- ✅ RPC endpoints
- ✅ Etherscan verification

## 📁 Output Files

### deployments/mantle-testnet.json
**Deployment addresses** (created after deployment)

**Format:**
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

**Usage:**
```bash
# View with jq
cat deployments/mantle-testnet.json | jq .

# Use in scripts
address=$(jq -r '.XAUT' deployments/mantle-testnet.json)
```

---

### broadcast/Deploy.s.sol/
**Foundry broadcast logs** (created after deployment)

**Contents:**
- Transaction receipts
- Deployment data
- Gas usage
- Contract addresses

**Usage:**
```bash
# View latest deployment
cat broadcast/Deploy.s.sol/<chain_id>/run-latest.json | jq .

# Check transaction hashes
jq '.transactions[].hash' broadcast/Deploy.s.sol/<chain_id>/run-latest.json
```

## 🎯 Workflow

### 1. Setup
```bash
cp .env.example .env      # Create .env
# Edit .env               # Add private key & RPC
make install              # Install deps
```

### 2. Pre-Deployment Check
```bash
forge script script/NetworkInfo.s.sol --rpc-url $MANTLE_TESTNET_RPC
# Check balance, gas price, network
```

### 3. Dry Run
```bash
make deploy-dry
# or
forge script script/Deploy.s.sol --rpc-url $MANTLE_TESTNET_RPC
```

### 4. Deploy
```bash
make deploy
# or
forge script script/Deploy.s.sol --rpc-url $MANTLE_TESTNET_RPC --broadcast --verify -vvvv
```

### 5. Verify Results
```bash
make status               # Check addresses
forge script script/DeploymentInfo.s.sol --rpc-url $MANTLE_TESTNET_RPC
```

### 6. Post-Setup (Optional)
```bash
make setup                # Additional configuration
```

## 📖 Which File to Use?

| I want to... | Use this file |
|-------------|---------------|
| **Learn deployment process** | [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) |
| **Quick deploy reference** | [QUICK_DEPLOY.md](QUICK_DEPLOY.md) |
| **Understand all files** | [DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md) |
| **Find specific file** | [DEPLOYMENT_INDEX.md](DEPLOYMENT_INDEX.md) (this file) |
| **Deploy contracts** | [script/Deploy.s.sol](script/Deploy.s.sol) or `make deploy` |
| **Verify contracts** | [script/Verify.s.sol](script/Verify.s.sol) or `make verify` |
| **Check network status** | [script/NetworkInfo.s.sol](script/NetworkInfo.s.sol) |
| **View deployment info** | [script/DeploymentInfo.s.sol](script/DeploymentInfo.s.sol) |
| **Additional setup** | [script/PostDeploymentSetup.s.sol](script/PostDeploymentSetup.s.sol) |
| **Configure network** | [script/DeployConfig.sol](script/DeployConfig.sol) |
| **Use make commands** | [Makefile](Makefile) |
| **Use bash script** | [scripts/deploy.sh](scripts/deploy.sh) |
| **Setup environment** | [.env.example](.env.example) |
| **Configure Foundry** | [foundry.toml](foundry.toml) |

## 🔍 Find What You Need

### "How do I deploy?"
1. Read [QUICK_DEPLOY.md](QUICK_DEPLOY.md) first
2. For details, check [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
3. Run deployment with [script/Deploy.s.sol](script/Deploy.s.sol) or `make deploy`

### "What are all these files?"
1. Start with [DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md)
2. Check this index for specific files
3. Read [script/README.md](script/README.md) for scripts details

### "Something went wrong"
1. Check troubleshooting in [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
2. Run [script/NetworkInfo.s.sol](script/NetworkInfo.s.sol) to check status
3. Check broadcast logs in `broadcast/` directory

### "How do I configure X?"
1. Environment: [.env.example](.env.example)
2. Foundry: [foundry.toml](foundry.toml)
3. Network/Router: [script/DeployConfig.sol](script/DeployConfig.sol)
4. Initial amounts: [script/Deploy.s.sol](script/Deploy.s.sol)

### "I want to understand scripts"
1. Read [script/README.md](script/README.md)
2. Check individual script files
3. See examples in [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

## 📞 Support

**Documentation:**
- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Complete guide
- [QUICK_DEPLOY.md](QUICK_DEPLOY.md) - Quick reference
- [script/README.md](script/README.md) - Scripts guide

**External Resources:**
- [Foundry Book](https://book.getfoundry.sh/)
- [Mantle Docs](https://docs.mantle.xyz/)
- [Mantle Explorer](https://explorer.testnet.mantle.xyz/)
- [Mantle Faucet](https://faucet.testnet.mantle.xyz/)

**Other Docs:**
- [TESTING_GUIDE.md](TESTING_GUIDE.md) - Testing documentation
- [TEST_RESULTS.md](TEST_RESULTS.md) - Test results
- [README.md](README.md) - Main project README

---

**Last Updated:** 2024
**Version:** 1.0
**Project:** AuRoom Protocol
**Network:** Mantle Testnet
