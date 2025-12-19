# AuRoom Protocol - Deployment Guide

Panduan lengkap untuk deploy AuRoom Protocol ke Mantle Testnet menggunakan Foundry.

## Prerequisites

1. **Install Foundry**
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Setup Environment Variables**
   ```bash
   cp .env.example .env
   ```

   Edit `.env` file dan isi:
   - `PRIVATE_KEY`: Private key wallet Anda (tanpa prefix 0x)
   - `MANTLE_TESTNET_RPC`: RPC URL Mantle Testnet (default: https://rpc.testnet.mantle.xyz)
   - `UNISWAP_ROUTER`: Address Uniswap V2 Router di Mantle Testnet
   - `MANTLE_API_KEY`: API key untuk verifikasi contract (optional)

3. **Get Testnet Tokens**
   - Dapatkan MNT testnet tokens dari [Mantle Faucet](https://faucet.testnet.mantle.xyz/)
   - Pastikan wallet Anda memiliki cukup MNT untuk gas fees

## Deployment Order

Script akan otomatis deploy contracts dalam urutan yang benar:

1. **MockIDRX** - Mock token Rupiah Indonesia
2. **MockUSDC** - Mock USDC stablecoin
3. **IdentityRegistry** - Registry untuk KYC/compliance
4. **XAUT** - Mock Tether Gold token (requires IdentityRegistry)
5. **GoldVault** - ERC4626 vault untuk XAUT (requires XAUT, IdentityRegistry, Uniswap Router, USDC)
6. **SwapRouter** - Router untuk swap IDRX <-> XAUT (requires Uniswap Router, IDRX, USDC, XAUT)

## Post-Deployment Setup

Script juga otomatis melakukan setup awal:

1. ✅ Register deployer di IdentityRegistry
2. ✅ Mint 1,000,000,000 IDRX ke deployer
3. ✅ Mint 10,000,000 USDC ke deployer
4. ✅ Mint 100 XAUT ke deployer

## Deployment Commands

### 1. Dry Run (Simulation)

Test deployment tanpa broadcast transaction:

```bash
forge script script/Deploy.s.sol --rpc-url $MANTLE_TESTNET_RPC
```

### 2. Deploy to Mantle Testnet

Deploy dengan broadcast transaction:

```bash
forge script script/Deploy.s.sol \
  --rpc-url $MANTLE_TESTNET_RPC \
  --broadcast \
  --verify \
  -vvvv
```

**Flags:**
- `--broadcast`: Broadcast transactions ke network
- `--verify`: Otomatis verify contracts di block explorer
- `-vvvv`: Verbose output untuk debugging

### 3. Deploy dengan Gas Estimation

```bash
forge script script/Deploy.s.sol \
  --rpc-url $MANTLE_TESTNET_RPC \
  --broadcast \
  --verify \
  --gas-estimate-multiplier 120 \
  -vvvv
```

### 4. Deploy dengan Custom Gas Price

```bash
forge script script/Deploy.s.sol \
  --rpc-url $MANTLE_TESTNET_RPC \
  --broadcast \
  --verify \
  --with-gas-price 1000000000 \
  -vvvv
```

## Verify Contracts (Manual)

Jika verifikasi otomatis gagal, Anda bisa verify manual:

```bash
# Set network di .env
export NETWORK=mantle-testnet

# Run verification script
forge script script/Verify.s.sol \
  --rpc-url $MANTLE_TESTNET_RPC \
  --ffi
```

**Note:** Flag `--ffi` diperlukan untuk menjalankan perintah eksternal.

## Deployment Output

### Console Output

Script akan menampilkan:
- ✅ Address setiap contract yang di-deploy
- ✅ Gas usage untuk setiap deployment
- ✅ Constructor parameters
- ✅ Post-deployment setup status
- ✅ Balance verification

### JSON Output

Deployment addresses disimpan di:
```
deployments/mantle-testnet.json
```

Format:
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

## Configuration

### Update Uniswap Router Address

Edit [script/Deploy.s.sol](script/Deploy.s.sol):

```solidity
// Line 20
address constant UNISWAP_ROUTER = 0xYourUniswapRouterAddress;
```

Atau set di environment variable:
```bash
export UNISWAP_ROUTER=0xYourUniswapRouterAddress
```

### Update Initial Token Amounts

Edit [script/Deploy.s.sol](script/Deploy.s.sol):

```solidity
// Lines 23-25
uint256 constant INITIAL_IDRX = 1_000_000_000 * 1e18; // 1 billion IDRX
uint256 constant INITIAL_USDC = 10_000_000 * 1e6;     // 10 million USDC
uint256 constant INITIAL_XAUT = 100 * 1e6;            // 100 XAUT
```

## Troubleshooting

### Error: "insufficient funds for gas"

**Solusi:**
- Pastikan wallet Anda memiliki cukup MNT testnet
- Dapatkan dari faucet: https://faucet.testnet.mantle.xyz/

### Error: "UNISWAP_ROUTER not configured"

**Solusi:**
- Update address Uniswap Router di `Deploy.s.sol`
- Atau set environment variable `UNISWAP_ROUTER`

### Error: "verification failed"

**Solusi:**
- Verify manual menggunakan script `Verify.s.sol`
- Atau verify via Mantle Explorer UI

### Error: "nonce too low"

**Solusi:**
```bash
# Reset nonce (hanya untuk development)
cast nonce <YOUR_ADDRESS> --rpc-url $MANTLE_TESTNET_RPC
```

### Error: "script failed"

**Solusi:**
- Jalankan dengan flag `-vvvv` untuk detailed output
- Check logs di `broadcast/` directory
- Verify RPC URL dan network connection

## Advanced Usage

### Deploy ke Network Lain

1. Update `foundry.toml` dengan network baru
2. Update `DeployConfig.sol` dengan chain ID dan router address
3. Set environment variables untuk network tersebut

### Resume Failed Deployment

Foundry menyimpan deployment state di `broadcast/` directory. Jika deployment gagal di tengah jalan:

```bash
# Check broadcast logs
cat broadcast/Deploy.s.sol/<chain_id>/run-latest.json

# Resume deployment
forge script script/Deploy.s.sol \
  --rpc-url $MANTLE_TESTNET_RPC \
  --broadcast \
  --resume
```

### Deployment dengan Ledger/Hardware Wallet

```bash
forge script script/Deploy.s.sol \
  --rpc-url $MANTLE_TESTNET_RPC \
  --broadcast \
  --ledger \
  --sender <YOUR_LEDGER_ADDRESS>
```

## Post-Deployment Checklist

- [ ] Verify semua contract addresses tersimpan di `deployments/mantle-testnet.json`
- [ ] Verify semua contracts di block explorer
- [ ] Verify deployer terdaftar di IdentityRegistry
- [ ] Verify token balances (IDRX, USDC, XAUT)
- [ ] Test basic functionality (mint, transfer, swap)
- [ ] Update frontend config dengan contract addresses
- [ ] Backup deployment JSON file

## Security Notes

⚠️ **PENTING:**
- Jangan commit `.env` file ke git
- Simpan private key dengan aman
- Gunakan hardware wallet untuk mainnet deployment
- Audit smart contracts sebelum mainnet deployment
- Test semua functionality di testnet terlebih dahulu

## Support

Jika menemui masalah:
1. Check TESTING_GUIDE.md untuk test coverage
2. Check TEST_RESULTS.md untuk known issues
3. Open issue di repository
4. Contact development team

## Resources

- [Mantle Testnet Explorer](https://explorer.testnet.mantle.xyz/)
- [Mantle Testnet Faucet](https://faucet.testnet.mantle.xyz/)
- [Foundry Book](https://book.getfoundry.sh/)
- [Mantle Documentation](https://docs.mantle.xyz/)
