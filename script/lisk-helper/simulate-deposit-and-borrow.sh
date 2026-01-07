#!/bin/bash

# Simulate Deposit and Borrow Operation
# Usage: ./simulate-deposit-and-borrow.sh [collateral_xaut] [borrow_idrx]

source .env

# Default values
COLLATERAL_XAUT=${1:-1}        # Default: 1 XAUT
BORROW_IDRX=${2:-1000000}      # Default: 1M IDRX

# Convert to wei (6 decimals)
COLLATERAL_WEI=$((COLLATERAL_XAUT * 1000000))
BORROW_WEI=$((BORROW_IDRX * 1000000))

echo "======================================"
echo "🏦  Simulating Deposit & Borrow"
echo "======================================"
echo "Collateral: $COLLATERAL_XAUT XAUT"
echo "Borrow: $BORROW_IDRX IDRX"
echo "======================================"
echo ""

# 1. Check user KYC status
echo "📋 Step 1: Checking User KYC Status"
USER_KYC=$(cast call $IDENTITY_REGISTRY "isVerified(address)" $DEPLOYER --rpc-url $LISK_TESTNET_RPC)
if [ "$USER_KYC" == "0x0000000000000000000000000000000000000000000000000000000000000001" ]; then
    echo "   ✅ User is KYC verified"
else
    echo "   ❌ User is NOT KYC verified"
    echo "   Fix: ./script/lisk-helper/register-kyc.sh"
    exit 1
fi
echo ""

# 2. Check BorrowingProtocol KYC status
echo "📋 Step 2: Checking BorrowingProtocolV2 KYC Status"
PROTOCOL_KYC=$(cast call $IDENTITY_REGISTRY "isVerified(address)" $BORROWING_PROTOCOL_V2 --rpc-url $LISK_TESTNET_RPC)
if [ "$PROTOCOL_KYC" == "0x0000000000000000000000000000000000000000000000000000000000000001" ]; then
    echo "   ✅ BorrowingProtocolV2 is KYC verified"
else
    echo "   ❌ BorrowingProtocolV2 is NOT KYC verified"
    echo "   Fix: ./script/lisk-helper/register-borrowing-protocol-kyc.sh"
    exit 1
fi
echo ""

# 3. Check XAUT balance
echo "📋 Step 3: Checking XAUT Balance"
XAUT_BALANCE=$(cast call $XAUT "balanceOf(address)" $DEPLOYER --rpc-url $LISK_TESTNET_RPC)
XAUT_DEC=$((16#${XAUT_BALANCE:2}))
XAUT_FORMATTED=$((XAUT_DEC / 1000000))
echo "   Current balance: $XAUT_FORMATTED XAUT"

if [ $XAUT_DEC -lt $COLLATERAL_WEI ]; then
    echo "   ❌ Insufficient XAUT balance"
    echo "   Fix: ./script/lisk-helper/mint-xaut.sh $COLLATERAL_XAUT"
    exit 1
else
    echo "   ✅ Sufficient XAUT balance"
fi
echo ""

# 4. Check XAUT approval
echo "📋 Step 4: Checking XAUT Approval"
XAUT_ALLOWANCE=$(cast call $XAUT "allowance(address,address)" $DEPLOYER $BORROWING_PROTOCOL_V2 --rpc-url $LISK_TESTNET_RPC)
XAUT_ALLOWANCE_DEC=$((16#${XAUT_ALLOWANCE:2}))

if [ $XAUT_ALLOWANCE_DEC -lt $COLLATERAL_WEI ]; then
    echo "   ❌ Insufficient XAUT allowance"
    echo "   Current: $((XAUT_ALLOWANCE_DEC / 1000000)) XAUT"
    echo "   Fix: cast send $XAUT \"approve(address,uint256)\" $BORROWING_PROTOCOL_V2 115792089237316195423570985008687907853269984665640564039457584007913129639935 --rpc-url \$LISK_TESTNET_RPC --private-key \$PRIVATE_KEY"
    exit 1
else
    echo "   ✅ XAUT approved for BorrowingProtocolV2"
fi
echo ""

# 5. Check treasury IDRX balance
echo "📋 Step 5: Checking Treasury IDRX Balance"
TREASURY=$(cast call $BORROWING_PROTOCOL_V2 "treasury()" --rpc-url $LISK_TESTNET_RPC)
TREASURY_ADDR="0x${TREASURY:26:40}"

TREASURY_IDRX=$(cast call $MOCK_IDRX "balanceOf(address)" $TREASURY_ADDR --rpc-url $LISK_TESTNET_RPC)
TREASURY_IDRX_DEC=$((16#${TREASURY_IDRX:2}))
TREASURY_IDRX_FORMATTED=$((TREASURY_IDRX_DEC / 1000000))

echo "   Treasury address: $TREASURY_ADDR"
echo "   Treasury IDRX balance: $TREASURY_IDRX_FORMATTED IDRX"

# Calculate amount needed (borrow amount - fee)
FEE_BPS=50  # 0.5%
FEE=$((BORROW_WEI * FEE_BPS / 10000))
AMOUNT_TO_RECEIVE=$((BORROW_WEI - FEE))

if [ $TREASURY_IDRX_DEC -lt $AMOUNT_TO_RECEIVE ]; then
    echo "   ❌ Insufficient IDRX in treasury"
    echo "   Need: $((AMOUNT_TO_RECEIVE / 1000000)) IDRX"
    echo "   Fix: ./script/lisk-helper/mint-idrx.sh $((AMOUNT_TO_RECEIVE / 1000000)) $TREASURY_ADDR"
    exit 1
else
    echo "   ✅ Sufficient IDRX in treasury"
fi
echo ""

# 6. Check treasury approval to protocol
echo "📋 Step 6: Checking Treasury IDRX Approval"
TREASURY_ALLOWANCE=$(cast call $MOCK_IDRX "allowance(address,address)" $TREASURY_ADDR $BORROWING_PROTOCOL_V2 --rpc-url $LISK_TESTNET_RPC)
TREASURY_ALLOWANCE_DEC=$((16#${TREASURY_ALLOWANCE:2}))

if [ $TREASURY_ALLOWANCE_DEC -lt $AMOUNT_TO_RECEIVE ]; then
    echo "   ❌ Treasury has not approved BorrowingProtocolV2"
    echo "   Fix: cast send $MOCK_IDRX \"approve(address,uint256)\" $BORROWING_PROTOCOL_V2 115792089237316195423570985008687907853269984665640564039457584007913129639935 --rpc-url \$LISK_TESTNET_RPC --private-key \$PRIVATE_KEY"
    exit 1
else
    echo "   ✅ Treasury approved BorrowingProtocolV2"
fi
echo ""

# 7. Get preview
echo "📋 Step 7: Getting Preview"
PREVIEW=$(cast call $BORROWING_PROTOCOL_V2 "previewDepositAndBorrow(address,uint256,uint256)" $DEPLOYER $COLLATERAL_WEI $BORROW_WEI --rpc-url $LISK_TESTNET_RPC)

# Parse preview (4 return values: amountReceived, fee, newLTV, allowed)
AMOUNT_RECEIVED_HEX=${PREVIEW:2:64}
FEE_HEX=${PREVIEW:66:64}
NEW_LTV_HEX=${PREVIEW:130:64}
ALLOWED_HEX=${PREVIEW:194:64}

AMOUNT_RECEIVED_DEC=$((16#$AMOUNT_RECEIVED_HEX))
FEE_DEC=$((16#$FEE_HEX))
NEW_LTV_DEC=$((16#$NEW_LTV_HEX))
ALLOWED_DEC=$((16#$ALLOWED_HEX))

echo "   Amount to receive: $((AMOUNT_RECEIVED_DEC / 1000000)) IDRX"
echo "   Fee: $((FEE_DEC / 1000000)) IDRX (0.5%)"
echo "   New LTV: $((NEW_LTV_DEC / 100))% (max: 75%)"

if [ $ALLOWED_DEC -eq 1 ]; then
    echo "   ✅ Operation is allowed"
else
    echo "   ❌ Operation NOT allowed (LTV too high)"
    exit 1
fi
echo ""

# 8. Summary
echo "======================================"
echo "📊 Summary"
echo "======================================"
echo "Operation: depositAndBorrow()"
echo "Collateral: $COLLATERAL_XAUT XAUT"
echo "Borrow: $BORROW_IDRX IDRX"
echo "You will receive: $((AMOUNT_RECEIVED_DEC / 1000000)) IDRX"
echo "Fee: $((FEE_DEC / 1000000)) IDRX"
echo "New LTV: $((NEW_LTV_DEC / 100))%"
echo ""
echo "✅ All checks passed! Ready to execute."
echo ""
echo "To execute, run:"
echo "cast send $BORROWING_PROTOCOL_V2 \\"
echo "  \"depositAndBorrow(uint256,uint256)\" \\"
echo "  $COLLATERAL_WEI \\"
echo "  $BORROW_WEI \\"
echo "  --rpc-url \$LISK_TESTNET_RPC \\"
echo "  --private-key \$PRIVATE_KEY"
echo "======================================"
