#!/bin/bash

# Register BorrowingProtocolV2 in KYC
# This is required for XAUT transfers to/from the protocol

source .env

echo "======================================"
echo "🪪  Registering BorrowingProtocolV2 in KYC"
echo "======================================"
echo "Identity Registry: $IDENTITY_REGISTRY"
echo "BorrowingProtocolV2: $BORROWING_PROTOCOL_V2"
echo "======================================"
echo ""

# Check if already registered
echo "Checking current KYC status..."
IS_VERIFIED=$(cast call $IDENTITY_REGISTRY "isVerified(address)" $BORROWING_PROTOCOL_V2 --rpc-url $LISK_TESTNET_RPC)

if [ "$IS_VERIFIED" == "0x0000000000000000000000000000000000000000000000000000000000000001" ]; then
    echo "✅ BorrowingProtocolV2 is already KYC verified!"
    exit 0
fi

echo "⏳ Registering BorrowingProtocolV2..."

# Register identity
cast send $IDENTITY_REGISTRY \
  "registerIdentity(address)" \
  $BORROWING_PROTOCOL_V2 \
  --rpc-url $LISK_TESTNET_RPC \
  --private-key $PRIVATE_KEY

echo ""
echo "✅ Registration complete!"
echo ""

# Verify registration
echo "Verifying registration..."
IS_VERIFIED=$(cast call $IDENTITY_REGISTRY "isVerified(address)" $BORROWING_PROTOCOL_V2 --rpc-url $LISK_TESTNET_RPC)

if [ "$IS_VERIFIED" == "0x0000000000000000000000000000000000000000000000000000000000000001" ]; then
    echo "✅ Confirmed: BorrowingProtocolV2 is now KYC verified!"
    echo ""
    echo "You can now use depositAndBorrow() function!"
else
    echo "❌ Error: Registration failed"
fi
