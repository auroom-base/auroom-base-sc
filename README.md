# 🏆 AuRoom Protocol - Smart Contracts

<div align="center">

![AuRoom Banner](https://img.shields.io/badge/AuRoom-Protocol-gold?style=for-the-badge&logo=ethereum&logoColor=white)

**From Rupiah to Yield-Bearing Gold**

[![Solidity](https://img.shields.io/badge/Solidity-0.8.30-363636?style=flat-square&logo=solidity)](https://docs.soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Foundry-1.5.0-orange?style=flat-square)](https://getfoundry.sh/)
[![Lisk](https://img.shields.io/badge/Lisk-Sepolia-blue?style=flat-square)](https://www.lisk.com/)
[![Tests](https://img.shields.io/badge/Tests-106%2F106%20Passing-brightgreen?style=flat-square)](./test)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](./LICENSE)

[Live Demo](https://auroom-testnet.vercel.app) • [Frontend Repo](https://github.com/AuRoom-Lisk/auroom-lisk-fe) • [Backend Repo](https://github.com/AuRoom-Lisk/auroom-lisk-be) • [Documentation](#-documentation)

</div>

---

## 📖 Overview

**AuRoom** is a Real World Asset (RWA) protocol that enables Indonesian users to access instant cash loans in IDRX (Indonesian Rupiah stablecoin) using tokenized gold (XAUT) as collateral, with integrated fiat redemption to convert IDRX back to Indonesian Rupiah (IDR).

### The Problem

| Traditional Gold Investment | Regular DEX |
|----------------------------|-------------|
| ❌ High minimum investment | ❌ Swap only, no yield |
| ❌ Storage fees | ❌ Assets sit idle |
| ❌ Illiquid (limited hours) | ❌ Manual management |
| ❌ No yield generation | ❌ Just tokens, no system |

### The AuRoom Solution

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   REGULAR DEX:                                                  │
│   IDRX ──→ XAUT ──→ 💤 Idle (0% yield)                         │
│                                                                 │
│   AUROOM:                                                       │
│   IDRX ──→ XAUT ──→ GoldVault ──→ gXAUT ──→ 📈 Earning Yield   │
│                                                                 │
│   "Not just a swap. A complete gold investment system."         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## ✨ Key Features

- 🔄 **Seamless Swap**: IDRX → USDC → XAUT in one transaction
- 💰 **Cash Loan**: Borrow IDRX (Indonesian Rupiah) using XAUT (gold) as collateral
- 🏦 **Fiat Redemption**: Convert IDRX to IDR (Indonesian fiat) via integrated IDRX.org API
- 🪪 **KYC Compliance**: On-chain identity verification (ERC-3643 inspired)
- ⚡ **Low Fees**: Built on Lisk L2 for minimal gas costs (0.5% borrow fee)
- 🔒 **Security**: Slippage protection, LTV limits, access control

---

## 🏗️ Architecture

```
                    ┌─────────────────┐
                    │   User (KYC'd)  │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
       ┌──────────┐   ┌──────────┐   ┌──────────┐
       │   Swap   │   │  Borrow  │   │  Redeem  │
       │IDRX→XAUT │   │XAUT→IDRX │   │IDRX→IDR  │
       └────┬─────┘   └────┬─────┘   └────┬─────┘
            │              │              │
            ▼              ▼              ▼
     ┌────────────┐ ┌──────────────┐ ┌─────────┐
     │ SwapRouter │ │ Borrowing    │ │ IDRX    │
     │            │ │ ProtocolV2   │ │ Burn +  │
     └─────┬──────┘ └──────────────┘ │ API     │
           │                          └─────────┘
           ▼
    ┌─────────────┐
    │ Uniswap V2  │
    │   Router    │
    └──────┬──────┘
           │
     ┌─────┴─────┐
     ▼           ▼
┌─────────┐ ┌─────────┐
│IDRX/USDC│ │XAUT/USDC│
│  Pair   │ │  Pair   │
└─────────┘ └─────────┘
```

### How Cash Loan Works

```
User deposits XAUT collateral
        │
        ▼
   ┌──────────────────┐
   │BorrowingProtocol │ ──→ Transfers IDRX from treasury
   └──────────────────┘
        │
        ▼
   User receives IDRX (minus 0.5% fee)
        │
        ▼
   User can redeem IDRX to Indonesian Rupiah
        │
        ▼
   To repay: User returns IDRX + withdraws XAUT collateral
```

---

## 📜 Smart Contracts

### Deployed Addresses (Lisk Sepolia)

| Contract | Address | Description |
|----------|---------|-------------|
| **MockIDRX** | `0xe0f7ea8fb1a7e9e9f8838d0e24b7a0f750c68d40` | Indonesian Rupiah Stablecoin (Mock) |
| **MockUSDC** | `0xA8F2b8180caFC670f4a24114FDB9c50361038857` | USD Coin (Mock) |
| **XAUT** | `0xDb198BEaccC55934062Be9AAEdce332c40A1f1Ed` | Tokenized Gold (Mock) |
| **IdentityRegistry** | `0x799fe52FA871EB8e4420fEc9d1b81c6297e712a5` | KYC Verification |
| **UniswapV2Factory** | `0x96abff3a2668b811371d7d763f06b3832cedf38d` | DEX Factory |
| **UniswapV2Router** | `0x6036306f417d720228ab939650e8acbe948d2d2b` | DEX Router |
| **IDRX/USDC Pair** | `0xB0ea91604C8B98205cbDd5c3F7d8DB006404515F` | Liquidity Pool |
| **XAUT/USDC Pair** | `0xBdfD81D4e79c0cC949BB52941BCd30Ed8b3B4112` | Liquidity Pool |
| **SwapRouter** | `0x8cDE80170b877a51a17323628BA6221F6F023505` | IDRX↔XAUT Router |
| **BorrowingProtocolV2** | `0x8c49cF7B7CCE0fBffADFe44F764fe6c5F2df82F9` | Cash Loan Protocol |

### Contract Overview

```
src/
├── BorrowingProtocolV2.sol # Cash loan protocol (XAUT collateral → IDRX loan)
├── SwapRouter.sol          # Routes swaps: IDRX ↔ USDC ↔ XAUT
├── IdentityRegistry.sol    # On-chain KYC management
├── XAUT.sol                # Tokenized gold with transfer restrictions
├── MockIDRX.sol            # Mock Indonesian Rupiah stablecoin (with burn)
├── MockUSDC.sol            # Mock USDC for testing
└── interfaces/
    └── IIdentityRegistry.sol
```

### Key Contract Features

#### BorrowingProtocolV2 (Cash Loan)
- **Instant IDRX loans** using XAUT collateral
- **Flexible LTV ratios** (up to 75% safe limit)
- **0.5% borrow fee** on each loan
- **Automatic LTV monitoring** for user safety
- **Repay and withdraw anytime** - no lock-up period
- **Only verified users** can borrow (KYC required)
- **Treasury-backed** lending from pre-funded IDRX pool

**Key Functions**:
- `depositAndBorrow(collateral, borrowAmount)` - One-click collateral deposit + borrow
- `repayAndWithdraw(repayAmount, withdrawAmount)` - One-click repay + withdraw collateral
- `getLTV(user)` - Check current loan-to-value ratio
- `getMaxBorrow(collateralAmount)` - Calculate maximum borrowable amount

**Safety Parameters**:
- MAX_LTV: 75% (safe borrowing limit)
- WARNING_LTV: 80% (warning zone)
- LIQUIDATION_LTV: 90% (liquidation threshold)

---

#### MockIDRX (Enhanced ERC20)
- Standard ERC20 stablecoin representing Indonesian Rupiah
- **Burn functions** for fiat redemption flow:
  - `burn(amount)` - Standard burn
  - `burnFrom(account, amount)` - Burn with allowance
  - `burnWithAccountNumber(amount, accountNumber)` - **Critical for redeem flow**
- Emits `BurnWithAccountNumber` event for backend integration
- Compatible with IDRX.org API for fiat conversion

---

#### SwapRouter
- Single transaction: IDRX → USDC → XAUT (or reverse)
- Slippage protection with `amountOutMin`
- Deadline protection to prevent stale transactions
- Emits detailed swap events

#### IdentityRegistry
- Admin-controlled KYC verification
- Batch registration support
- Multi-admin capability
- Required for XAUT transfers and vault operations

---

### Run Specific Tests

```bash
# All tests
forge test

# Verbose output
forge test -vvv

# Specific contract
forge test --match-contract GoldVaultTest

# Specific test
forge test --match-test testDeposit

# Gas report
forge test --gas-report
```

---

## 🚀 Getting Started

### Prerequisites

- [Foundry](https://getfoundry.sh/) (v1.5.0 or later)
- Git

### Installation

```bash
# Clone the repository
git clone https://github.com/YohanesVito/auroom-sc.git
cd auroom-sc

# Install dependencies
forge install

# Build contracts
forge build

# Run tests
forge test
```

### Environment Setup

Create a `.env` file:

```env
# Private key for deployment
PRIVATE_KEY=your_private_key_here

# RPC URLs
LISK_TESTNET_RPC=https://rpc.sepolia-api.lisk.com
LISK_MAINNET_RPC=https://rpc.api.lisk.com

# Deployer address
DEPLOYER=your_deployer_address

# Contract addresses (will be filled after deployment)
MOCK_IDRX=
MOCK_USDC=
XAUT=
IDENTITY_REGISTRY=
UNISWAP_V2_FACTORY=
UNISWAP_V2_ROUTER=
BORROWING_PROTOCOL_V2=
SWAP_ROUTER=

# Treasury
TREASURY=your_treasury_address
```

### Deployment

```bash
# Deploy to Lisk Sepolia
forge script script/lisk/Deploy.s.sol \
  --rpc-url $LISK_TESTNET_RPC \
  --broadcast \
  --legacy

# Verify contracts on Blockscout
forge verify-contract <CONTRACT_ADDRESS> <CONTRACT_NAME> \
  --chain-id 4202 \
  --verifier blockscout \
  --verifier-url https://sepolia-blockscout.lisk.com/api
```

### Post-Deployment Setup

**Critical**: After deploying BorrowingProtocolV2, register it in IdentityRegistry:

```bash
# Register BorrowingProtocolV2 to enable XAUT transfers
cast send $IDENTITY_REGISTRY \
  "registerIdentity(address)" \
  $BORROWING_PROTOCOL_V2 \
  --rpc-url $LISK_TESTNET_RPC \
  --private-key $PRIVATE_KEY

# Mint IDRX to Treasury
cast send $MOCK_IDRX \
  "publicMint(address,uint256)" \
  $TREASURY \
  100000000000000 \
  --rpc-url $LISK_TESTNET_RPC \
  --private-key $PRIVATE_KEY

# Approve BorrowingProtocol to spend treasury IDRX
cast send $MOCK_IDRX \
  "approve(address,uint256)" \
  $BORROWING_PROTOCOL_V2 \
  $(cast max-uint256) \
  --rpc-url $LISK_TESTNET_RPC \
  --private-key $PRIVATE_KEY
```

---

## 📁 Project Structure

```
auroom-sc/
├── src/                    # Smart contract source files
│   ├── GoldVault.sol
│   ├── SwapRouter.sol
│   ├── IdentityRegistry.sol
│   ├── XAUT.sol
│   ├── MockIDRX.sol
│   ├── MockUSDC.sol
│   └── interfaces/
├── test/                   # Test files
│   ├── GoldVault.t.sol
│   ├── SwapRouter.t.sol
│   ├── IdentityRegistry.t.sol
│   ├── Integration.t.sol
│   └── ...
├── script/                 # Deployment scripts
│   └── Deploy.s.sol
├── lib/                    # Dependencies (git submodules)
│   ├── openzeppelin-contracts/
│   ├── uniswap-v2-core/
│   └── uniswap-v2-periphery/
├── deployments/            # Deployment records
├── foundry.toml            # Foundry configuration
└── README.md
```

---

## ⚙️ Configuration

### foundry.toml

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
solc = "0.8.30"
optimizer = true
optimizer_runs = 200

[profile.uniswap]
solc = "0.6.6"
optimizer_runs = 999999
```

### Dependencies

| Library | Version | Purpose |
|---------|---------|---------|
| OpenZeppelin | 5.x | ERC20, ERC4626, Access Control |
| Uniswap V2 Core | - | AMM pairs |
| Uniswap V2 Periphery | - | Router |

---

## 🔐 Security Considerations

### Implemented Security Features

- ✅ **Slippage Protection**: All swaps have `amountOutMin` parameter
- ✅ **Deadline Protection**: Transactions expire after specified time
- ✅ **Access Control**: Only verified users can interact with XAUT
- ✅ **Reentrancy Guards**: Protected vault operations
- ✅ **Input Validation**: All user inputs are validated

### Audit Status

⏳ **Pending**: Professional audit planned for mainnet launch

Current status:
- ✅ Internal testing complete (106/106 tests)
- ✅ Testnet deployment verified
- ⏳ External audit in progress

---

## 🗺️ Roadmap

- [x] Core contracts development
- [x] Comprehensive test suite
- [x] Lisk Sepolia deployment
- [x] BorrowingProtocolV2 (Cash Loan) implementation
- [x] IDRX burn functions for redeem flow
- [x] Frontend integration
- [ ] Backend API for IDRX redemption (in progress)
- [ ] Frontend redeem modal integration
- [ ] Security audit
- [ ] Mainnet deployment
- [ ] Multi-chain expansion

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Lisk Network** - L2 Infrastructure
- **IDRX.org** - Indonesian Rupiah Stablecoin & API Integration
- **Tether Gold (XAUT)** - Tokenized gold concept
- **OpenZeppelin** - Secure contract libraries
- **Uniswap** - AMM protocol

---

## 📬 Contact

**Apple Bites** - [@YohanesVito](https://github.com/YohanesVito)

Project Links:
- Smart Contracts: [https://github.com/AuRoom-Lisk/auroom-lisk-sc](https://github.com/AuRoom-Lisk/auroom-lisk-sc)
- Frontend: [https://github.com/AuRoom-Lisk/auroom-lisk-fe](https://github.com/AuRoom-Lisk/auroom-lisk-fe)
- Backend: [https://github.com/AuRoom-Lisk/auroom-lisk-be](https://github.com/AuRoom-Lisk/auroom-lisk-be)

---

<div align="center">

**Built with ❤️ for Lisk Builders Challenge: Round Three**

[⬆ Back to Top](#-auroom-protocol---smart-contracts)

</div>
