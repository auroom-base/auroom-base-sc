# Deploy GoldVault & SwapRouter - AuRoom Protocol

## Overview
Deployment guide untuk 2 contracts terakhir di AuRoom Protocol:
1. **GoldVault** - ERC-4626 vault untuk stake XAUT
2. **SwapRouter** - Custom router untuk swap IDRX ↔ XAUT

## Prerequisites

### Deployed Contracts (sudah ada)
```json
{
  "MockIDRX": "0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05",
  "MockUSDC": "0x96ABff3a2668B811371d7d763f06B3832CEdf38d",
  "XAUT": "0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78",
  "IdentityRegistry": "0x620870d419F6aFca8AFed5B516619aa50900cadc",
  "WMNT": "0xa2ddbfc12ab0B69c04eDCf1044382B9A38f883c3",
  "UniswapV2Factory": "0x8950d0D71a23085C514350df2682c3f6F1D7aBFE",
  "UniswapV2Router02": "0xF01D09A6CF3938d59326126174bD1b32FB47d8F5",
  "IDRX_USDC_Pair": "0xD3FF8e1C2821745513Ef83f3551668A7ce791Fe2",
  "XAUT_USDC_Pair": "0xc2da5178F53f45f604A275a3934979944eB15602"
}
```

### Environment Setup
Pastikan `.env` file sudah configured:
```env
PRIVATE_KEY=your_private_key
MANTLE_SEPOLIA_RPC_URL=https://rpc.sepolia.mantle.xyz
```

---

## Step 1: Deploy GoldVault

### 1.1 Run Deployment
```bash
deploy-goldvault.bat
```

### 1.2 Constructor Parameters
```solidity
constructor(
    address _xaut,              // 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78
    address _identityRegistry,  // 0x620870d419F6aFca8AFed5B516619aa50900cadc
    address _uniswapRouter,     // 0xF01D09A6CF3938d59326126174bD1b32FB47d8F5
    address _usdc               // 0x96ABff3a2668B811371d7d763f06B3832CEdf38d
)
```

### 1.3 Expected Output
```
Deploying GoldVault...
GoldVault deployed at: 0x...

=== GOLDVAULT DEPLOYMENT ===
Chain ID: 5003 (Mantle Sepolia)
Contract: 0x...
Name: Gold XAUT Vault
Symbol: gXAUT
```

### 1.4 Copy Address
Copy deployed address dan update di:
- `script/SetupVaultRouter.s.sol` → `GOLD_VAULT`
- `script/VerifyVaultRouter.s.sol` → `GOLD_VAULT`

---

## Step 2: Deploy SwapRouter

### 2.1 Run Deployment
```bash
deploy-swaprouter.bat
```

### 2.2 Constructor Parameters
```solidity
constructor(
    address _router,  // 0xF01D09A6CF3938d59326126174bD1b32FB47d8F5
    address _idrx,    // 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05
    address _usdc,    // 0x96ABff3a2668B811371d7d763f06B3832CEdf38d
    address _xaut     // 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78
)
```

### 2.3 Expected Output
```
Deploying SwapRouter...
SwapRouter deployed at: 0x...

=== SWAPROUTER DEPLOYMENT ===
Chain ID: 5003 (Mantle Sepolia)
Contract: 0x...
```

### 2.4 Copy Address
Copy deployed address dan update di:
- `script/SetupVaultRouter.s.sol` → `SWAP_ROUTER`
- `script/VerifyVaultRouter.s.sol` → `SWAP_ROUTER`

---

## Step 3: Register Contracts

### 3.1 Update Addresses
Edit `script/SetupVaultRouter.s.sol`:
```solidity
address constant GOLD_VAULT = 0x...; // Paste GoldVault address
address constant SWAP_ROUTER = 0x...; // Paste SwapRouter address
```

### 3.2 Run Setup
```bash
setup-vault-router.bat
```

### 3.3 What This Does
- Registers GoldVault in IdentityRegistry (sebagai INSTITUTION)
- Registers SwapRouter in IdentityRegistry (sebagai INSTITUTION)
- Allows contracts to hold/transfer XAUT, IDRX, USDC

---

## Step 4: Verify Deployment

### 4.1 Update Addresses
Edit `script/VerifyVaultRouter.s.sol`:
```solidity
address constant GOLD_VAULT = 0x...; // Paste GoldVault address
address constant SWAP_ROUTER = 0x...; // Paste SwapRouter address
```

### 4.2 Run Verification
```bash
verify-vault-router.bat
```

### 4.3 Expected Output
```
=== Verifying GoldVault ===
Contract: 0x...
Name: Gold XAUT Vault
Symbol: gXAUT
Asset (XAUT): 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78
[OK] GoldVault verification passed!

=== Verifying SwapRouter ===
Contract: 0x...
[OK] SwapRouter verification passed!

=== Checking Identity Registration ===
GoldVault verified: true
SwapRouter verified: true
[OK] All contracts are registered!
```

---

## Step 5: Update Deployment JSON

Update `deployments/auroom-mantle-sepolia.json`:
```json
{
  "chainId": 5003,
  "network": "mantle-sepolia",
  "deployer": "0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1",
  "contracts": {
    "MockIDRX": "0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05",
    "MockUSDC": "0x96ABff3a2668B811371d7d763f06B3832CEdf38d",
    "XAUT": "0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78",
    "IdentityRegistry": "0x620870d419F6aFca8AFed5B516619aa50900cadc",
    "WMNT": "0xa2ddbfc12ab0B69c04eDCf1044382B9A38f883c3",
    "UniswapV2Factory": "0x8950d0D71a23085C514350df2682c3f6F1D7aBFE",
    "UniswapV2Router02": "0xF01D09A6CF3938d59326126174bD1b32FB47d8F5",
    "IDRX_USDC_Pair": "0xD3FF8e1C2821745513Ef83f3551668A7ce791Fe2",
    "XAUT_USDC_Pair": "0xc2da5178F53f45f604A275a3934979944eB15602",
    "GoldVault": "0x...",      // ADD THIS
    "SwapRouter": "0x..."      // ADD THIS
  }
}
```

---

## Testing

### Test GoldVault Deposit
```solidity
// 1. User needs to be verified in IdentityRegistry
// 2. User approves XAUT to GoldVault
// 3. User calls deposit(amount, receiver)
// 4. User receives gXAUT shares
```

### Test SwapRouter
```solidity
// 1. User approves IDRX to SwapRouter
// 2. User calls swapIDRXtoXAUT(amountIn, minOut, to, deadline)
// 3. User receives XAUT

// Or reverse:
// 1. User approves XAUT to SwapRouter
// 2. User calls swapXAUTtoIDRX(amountIn, minOut, to, deadline)
// 3. User receives IDRX
```

---

## Scripts Reference

### Deployment Scripts
- `script/DeployGoldVault.s.sol` - Deploy GoldVault
- `script/DeploySwapRouter.s.sol` - Deploy SwapRouter
- `script/DeployVaultRouter.s.sol` - Deploy both (combined)

### Setup Scripts
- `script/SetupVaultRouter.s.sol` - Register contracts in IdentityRegistry

### Verification Scripts
- `script/VerifyVaultRouter.s.sol` - Verify deployment & setup

### Batch Files
- `deploy-goldvault.bat` - Deploy GoldVault
- `deploy-swaprouter.bat` - Deploy SwapRouter
- `deploy-vault-router.bat` - Deploy both (combined)
- `setup-vault-router.bat` - Setup contracts
- `verify-vault-router.bat` - Verify deployment

---

## Troubleshooting

### Error: "Deployment failed"
- Check `.env` file exists and has correct RPC URL
- Check PRIVATE_KEY has enough MNT for gas
- Check all prerequisite contracts are deployed

### Error: "Contract not verified"
- Run `setup-vault-router.bat` to register contracts
- Check IdentityRegistry address is correct

### Error: "Asset mismatch"
- Verify constructor parameters in deployment script
- Check deployed contract addresses match expected

---

## Security Notes

1. **GoldVault** is compliance-aware:
   - Only verified users can deposit/withdraw
   - Checks IdentityRegistry before transfers

2. **SwapRouter** handles routing:
   - IDRX → USDC → XAUT (2-hop swap)
   - XAUT → USDC → IDRX (2-hop swap)
   - Uses UniswapV2 for swaps

3. **Always verify**:
   - Constructor parameters
   - Identity registration
   - Contract permissions

---

## Next Steps After Deployment

1. ✅ Deploy GoldVault
2. ✅ Deploy SwapRouter
3. ✅ Register in IdentityRegistry
4. ✅ Verify deployment
5. ✅ Update deployment JSON
6. 🔄 Test deposit flow
7. 🔄 Test swap flow
8. 🔄 Monitor gas costs
9. 🔄 Monitor slippage
10. 🔄 Setup frontend integration

---

## Support

If you encounter issues:
1. Check deployment logs in `broadcast/` folder
2. Verify all addresses in deployment JSON
3. Check Mantle Sepolia explorer for transaction status
4. Review contract events for errors
