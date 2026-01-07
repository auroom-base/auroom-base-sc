#!/bin/bash

# Setup Treasury for BorrowingProtocolV2
# This script will:
# 1. Mint IDRX to treasury
# 2. Approve BorrowingProtocolV2 to spend IDRX from treasury

source .env

TREASURY=$DEPLOYER  # Treasury is the deployer address
MINT_AMOUNT=${1:-10000000000}  # Default: 10 billion IDRX

echo "======================================"
echo "🏦  Setting Up Treasury"
echo "======================================"
echo "Treasury: $TREASURY"
echo "BorrowingProtocolV2: $BORROWING_PROTOCOL_V2"
echo "======================================"
echo ""

# Step 1: Check current IDRX balance
echo "📊 Step 1: Checking Treasury IDRX Balance"
BALANCE=$(cast call $MOCK_IDRX "balanceOf(address)" $TREASURY --rpc-url $LISK_TESTNET_RPC)
BALANCE_DEC=$((16#${BALANCE:2}))
BALANCE_FORMATTED=$((BALANCE_DEC / 1000000))
echo "   Current balance: $BALANCE_FORMATTED IDRX"
echo ""

# Step 2: Mint IDRX to treasury if needed
if [ $BALANCE_DEC -lt $((MINT_AMOUNT * 1000000)) ]; then
    echo "💰 Step 2: Minting IDRX to Treasury"
    echo "   Amount: $MINT_AMOUNT IDRX"
    
    cast send $MOCK_IDRX \
      "publicMint(address,uint256)" \
      $TREASURY \
      $((MINT_AMOUNT * 1000000)) \
      --rpc-url $LISK_TESTNET_RPC \
      --private-key $PRIVATE_KEY
    
    echo "   ✅ Minted!"
    echo ""
else
    echo "💰 Step 2: Treasury has sufficient IDRX"
    echo "   Skipping mint"
    echo ""
fi

# Step 3: Check current approval
echo "✅ Step 3: Checking IDRX Approval"
ALLOWANCE=$(cast call $MOCK_IDRX "allowance(address,address)" $TREASURY $BORROWING_PROTOCOL_V2 --rpc-url $LISK_TESTNET_RPC)
ALLOWANCE_DEC=$((16#${ALLOWANCE:2}))

if [ $ALLOWANCE_DEC -eq 0 ]; then
    echo "   Current allowance: 0 IDRX"
    echo "   ⚠️  Need to approve!"
    echo ""
    
    # Step 4: Approve BorrowingProtocolV2
    echo "🔓 Step 4: Approving BorrowingProtocolV2"
    echo "   Approving unlimited IDRX..."
    
    cast send $MOCK_IDRX \
      "approve(address,uint256)" \
      $BORROWING_PROTOCOL_V2 \
      115792089237316195423570985008687907853269984665640564039457584007913129639935 \
      --rpc-url $LISK_TESTNET_RPC \
      --private-key $PRIVATE_KEY
    
    echo "   ✅ Approved!"
    echo ""
else
    echo "   ✅ Already approved (allowance > 0)"
    echo ""
fi

# Step 5: Verify setup
echo "======================================"
echo "✅ Verification"
echo "======================================"

# Check balance
NEW_BALANCE=$(cast call $MOCK_IDRX "balanceOf(address)" $TREASURY --rpc-url $LISK_TESTNET_RPC)
NEW_BALANCE_DEC=$((16#${NEW_BALANCE:2}))
NEW_BALANCE_FORMATTED=$((NEW_BALANCE_DEC / 1000000))

# Check allowance
NEW_ALLOWANCE=$(cast call $MOCK_IDRX "allowance(address,address)" $TREASURY $BORROWING_PROTOCOL_V2 --rpc-url $LISK_TESTNET_RPC)
NEW_ALLOWANCE_DEC=$((16#${NEW_ALLOWANCE:2}))

echo "Treasury IDRX Balance: $NEW_BALANCE_FORMATTED IDRX"

if [ $NEW_ALLOWANCE_DEC -gt 0 ]; then
    echo "BorrowingProtocolV2 Allowance: ✅ Unlimited"
    echo ""
    echo "✅ Treasury setup complete!"
    echo "Users can now use depositAndBorrow() function!"
else
    echo "BorrowingProtocolV2 Allowance: ❌ Not approved"
    echo ""
    echo "❌ Setup failed!"
fi

echo "======================================"
