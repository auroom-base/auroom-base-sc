# Address Update Summary - December 20, 2024

## Overview
Updated all test suite documentation and test files to reflect the correct contract addresses after the Router V2 deployment and dependent contract redeployment.

## Problem
After the Router V2 deployment on December 20, 2024, several contracts were redeployed:
- **UniswapV2Router02** was upgraded from stub to full implementation
- **SwapRouter** was redeployed to use the new Router V2
- **GoldVault** was redeployed to use the new Router V2

The test suite prompts document (`AUROOM_TEST_SUITE_PROMPTS.md`) still contained the old addresses.

## Correct Addresses (from COMPLETE_DEPLOYMENT_ROUTER_V2_2024-12-20.md)

### Core Infrastructure (Unchanged)
| Contract | Address | Status |
|----------|---------|--------|
| **Factory** | `0x8950d0D71a23085C514350df2682c3f6F1D7aBFE` | ✅ Unchanged |
| **WMNT** | `0xa2ddbfc12ab0B69c04eDCf1044382B9A38f883c3` | ✅ Unchanged |
| **IDRX** | `0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05` | ✅ Unchanged |
| **USDC** | `0x96ABff3a2668B811371d7d763f06B3832CEdf38d` | ✅ Unchanged |
| **XAUT** | `0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78` | ✅ Unchanged |
| **IdentityRegistry** | `0x620870d419F6aFca8AFed5B516619aa50900cadc` | ✅ Unchanged |
| **IDRX/USDC Pair** | `0xD3FF8e1C2821745513Ef83f3551668A7ce791Fe2` | ✅ Unchanged |
| **XAUT/USDC Pair** | `0xc2da5178F53f45f604A275a3934979944eB15602` | ✅ Unchanged |

### Updated Contracts
| Contract | Old Address | New Address | Status |
|----------|-------------|-------------|--------|
| **UniswapV2Router02** | `0xF01D09A6CF3938d59326126174bD1b32FB47d8F5` | `0x54166b2C5e09f16c3c1D705FfB4eb29a069000A9` | ✅ **Updated** |
| **SwapRouter** | `0x2737e491775055F7218b40A11DE10dA855968277` | `0xF948Dd812E7fA072367848ec3D198cc61488b1b9` | ✅ **Updated** |
| **GoldVault** | `0xa039F4E162F8A8C5d01C57b78daDa8dcc976657a` | `0xd92cE2F13509840B1203D35218227559E64fbED0` | ✅ **Updated** |

## Files Updated

### 1. AUROOM_TEST_SUITE_PROMPTS.md
Updated all occurrences of contract addresses in:
- Main contract reference section (lines 54-75)
- Test Suite 3: DEX Tests (lines 410-419, 517-524)
- Test Suite 4: SwapRouter Tests (lines 599-605, 738-744)
- Test Suite 5: GoldVault Tests (lines 847-851, 985-989)
- Test Suite 6: Integration Flow Tests (lines 1098-1105, 1221-1227)
- Test Suite 7: Edge Cases & Security Tests (lines 1357-1363, 1465-1471)

**Changes:**
- `UNISWAP_ROUTER`: `0xF01D09A6CF3938d59326126174bD1b32FB47d8F5` → `0x54166b2C5e09f16c3c1D705FfB4eb29a069000A9`
- `SWAP_ROUTER`: `0x2737e491775055F7218b40A11DE10dA855968277` → `0xF948Dd812E7fA072367848ec3D198cc61488b1b9`
- `GOLD_VAULT`: `0xa039F4E162F8A8C5d01C57b78daDa8dcc976657a` → `0xd92cE2F13509840B1203D35218227559E64fbED0`

### 2. test/suite/Suite1_TokenTests.t.sol
Updated contract addresses (lines 44-45):
- `SWAP_ROUTER`: `0x2737e491775055F7218b40A11DE10dA855968277` → `0xF948Dd812E7fA072367848ec3D198cc61488b1b9`
- `GOLD_VAULT`: `0xa039F4E162F8A8C5d01C57b78daDa8dcc976657a` → `0xd92cE2F13509840B1203D35218227559E64fbED0`

### 3. test/suite/Suite3_DEXTests.t.sol
✅ Already had correct `UNISWAP_ROUTER` address (`0x54166b2C5e09f16c3c1D705FfB4eb29a069000A9`)

### 4. test/suite/Suite2_IdentityRegistryTests.t.sol
✅ No address changes needed (only uses IDENTITY_REGISTRY and DEPLOYER)

## Status: ✅ COMPLETE

All test suite documentation and test files now have the correct addresses matching the December 20, 2024 deployment.

## Next Steps

When generating test suites 4-7, use the updated addresses from `AUROOM_TEST_SUITE_PROMPTS.md`:
- Suite 4 (SwapRouter Tests): Use `SWAP_ROUTER = 0xF948Dd812E7fA072367848ec3D198cc61488b1b9`
- Suite 5 (GoldVault Tests): Use `GOLD_VAULT = 0xd92cE2F13509840B1203D35218227559E64fbED0`
- Suite 6 (Integration Tests): Use both new addresses
- Suite 7 (Edge Cases): Use both new addresses

## Verification

To verify the addresses are correct, you can check:
```bash
# Check Router V2
cast call 0x54166b2C5e09f16c3c1D705FfB4eb29a069000A9 "factory()(address)" --rpc-url https://rpc.sepolia.mantle.xyz

# Check SwapRouter
cast call 0xF948Dd812E7fA072367848ec3D198cc61488b1b9 "uniswapRouter()(address)" --rpc-url https://rpc.sepolia.mantle.xyz

# Check GoldVault
cast call 0xd92cE2F13509840B1203D35218227559E64fbED0 "asset()(address)" --rpc-url https://rpc.sepolia.mantle.xyz
```

Expected results:
- Router V2 factory: `0x8950d0D71a23085C514350df2682c3f6F1D7aBFE`
- SwapRouter uniswapRouter: `0x54166b2C5e09f16c3c1D705FfB4eb29a069000A9`
- GoldVault asset: `0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78` (XAUT)
