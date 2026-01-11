# Base Sepolia Helper Scripts

Utility shell scripts for interacting with AuRoom Protocol on Base Sepolia.

## Prerequisites

- Foundry installed (`forge`, `cast`)
- `.env` file configured with proper values
- Bash shell (macOS/Linux)

## Quick Start

Make all scripts executable:
```bash
chmod +x script/base/helper/*.sh
```

## Available Scripts

### Token Minting

```bash
# Mint IDRX
./script/base/helper/mint-idrx.sh [amount] [recipient]
./script/base/helper/mint-idrx.sh 1000000000              # Mint 1B IDRX to deployer
./script/base/helper/mint-idrx.sh 500000000 0xAddress     # Mint 500M IDRX to address

# Mint USDC
./script/base/helper/mint-usdc.sh [amount] [recipient]
./script/base/helper/mint-usdc.sh 100000                  # Mint 100K USDC to deployer

# Mint XAUT (requires KYC)
./script/base/helper/mint-xaut.sh [amount] [recipient]
./script/base/helper/mint-xaut.sh 100                     # Mint 100 XAUT to deployer
```

### Balance Checking

```bash
# Check all balances
./script/base/helper/check-balances.sh [address]
./script/base/helper/check-balances.sh                    # Check deployer
./script/base/helper/check-balances.sh 0xAddress          # Check specific address
```

### KYC Management

```bash
# Register address in KYC
./script/base/helper/register-kyc.sh [address]
./script/base/helper/register-kyc.sh                      # Register deployer
./script/base/helper/register-kyc.sh 0xAddress            # Register specific address
```

### Token Approvals

```bash
# Approve tokens for spending
./script/base/helper/approve-tokens.sh [spender] [token]
./script/base/helper/approve-tokens.sh                    # Approve all for SwapRouter
./script/base/helper/approve-tokens.sh $SWAP_ROUTER IDRX  # Approve only IDRX
./script/base/helper/approve-tokens.sh $BORROWING_PROTOCOL_V2  # Approve all for Protocol
```

### Liquidity Monitoring

```bash
# Check liquidity pool reserves
./script/base/helper/check-liquidity.sh
```

### Borrowing Simulation

```bash
# Simulate deposit and borrow flow
./script/base/helper/simulate-borrow.sh [collateral_xaut] [borrow_idrx]
./script/base/helper/simulate-borrow.sh 10 40000000       # 10 XAUT, 40M IDRX
```

## Common Workflows

### Setup New Test User
```bash
# 1. Register in KYC
./script/base/helper/register-kyc.sh 0xNewUserAddress

# 2. Mint tokens
./script/base/helper/mint-idrx.sh 1000000000 0xNewUserAddress
./script/base/helper/mint-xaut.sh 100 0xNewUserAddress

# 3. Check balances
./script/base/helper/check-balances.sh 0xNewUserAddress
```

### Test Borrow Flow
```bash
# 1. Mint XAUT to yourself
./script/base/helper/mint-xaut.sh 100

# 2. Approve BorrowingProtocol
./script/base/helper/approve-tokens.sh $BORROWING_PROTOCOL_V2 XAUT

# 3. Simulate borrow
./script/base/helper/simulate-borrow.sh 10 40000000

# 4. Check position
./script/base/helper/check-balances.sh
```

## Environment Variables Required

```bash
PRIVATE_KEY=your_private_key
BASE_SEPOLIA_RPC=https://sepolia.base.org
MOCK_IDRX=0x...
MOCK_USDC=0x...
XAUT=0x...
IDENTITY_REGISTRY=0x...
SWAP_ROUTER=0x...
BORROWING_PROTOCOL_V2=0x...
PAIR_IDRX_USDC=0x...
PAIR_XAUT_USDC=0x...
```

## Troubleshooting

### Script not executable
```bash
chmod +x script/base/helper/*.sh
```

### Environment variables not loaded
```bash
cd /path/to/auroom-base-sc
source .env
```

### Transaction failed
- Check if address is KYC registered (for XAUT operations)
- Check if tokens are approved (for swap/borrow operations)
- Check if you have enough gas (ETH)

## Network Information

- **Network**: Base Sepolia Testnet
- **Chain ID**: 84532
- **RPC URL**: https://sepolia.base.org
- **Block Explorer**: https://sepolia.basescan.org
- **Faucet**: https://faucet.quicknode.com/base/sepolia
