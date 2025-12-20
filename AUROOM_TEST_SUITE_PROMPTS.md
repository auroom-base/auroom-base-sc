# AuRoom Protocol - Smart Contract Test Suite Prompts
## Dokumentasi Lengkap untuk Generate Integration Tests

**Project:** AuRoom Protocol  
**Network:** Mantle Sepolia (Chain ID: 5003)  
**Framework:** Foundry (Forge)  
**Solidity:** ^0.8.20  
**Date:** December 19, 2024

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Deployed Contracts Reference](#deployed-contracts-reference)
3. [Test Suite 1: Token Tests](#test-suite-1-token-tests)
4. [Test Suite 2: IdentityRegistry Tests](#test-suite-2-identityregistry-tests)
5. [Test Suite 3: DEX Tests](#test-suite-3-dex-tests)
6. [Test Suite 4: SwapRouter Tests](#test-suite-4-swaprouter-tests)
7. [Test Suite 5: GoldVault Tests](#test-suite-5-goldvault-tests)
8. [Test Suite 6: Integration Flow Tests](#test-suite-6-integration-flow-tests)
9. [Test Suite 7: Edge Cases & Security Tests](#test-suite-7-edge-cases--security-tests)
10. [Run Commands](#run-commands)
11. [Expected Results](#expected-results)

---

## Overview

AuRoom Protocol adalah platform RWA (Real World Asset) untuk:
- Swap IDRX (Indonesian Rupiah stablecoin) ke XAUT (tokenized gold)
- Stake XAUT ke GoldVault untuk mendapatkan yield (gXAUT)
- Compliance-aware dengan IdentityRegistry (ERC-3643 simplified)

### Test Suites Summary

| Suite | Nama | File | Tests | Fokus |
|-------|------|------|-------|-------|
| 1 | Token Tests | `TokenTests.t.sol` | ~11 | MockIDRX, MockUSDC, XAUT compliance |
| 2 | IdentityRegistry Tests | `IdentityRegistryTests.t.sol` | ~10 | Registration, access control |
| 3 | DEX Tests | `DEXTests.t.sol` | ~9 | UniswapV2 pools, quotes, swaps |
| 4 | SwapRouter Tests | `SwapRouterTests.t.sol` | ~12 | Custom router functions |
| 5 | GoldVault Tests | `GoldVaultTests.t.sol` | ~16 | ERC-4626 vault operations |
| 6 | Integration Flow Tests | `IntegrationFlowTests.t.sol` | ~4 | Full user journeys |
| 7 | Edge Cases & Security | `EdgeCasesSecurityTests.t.sol` | ~12 | Edge cases, security |

**Total: ~74 tests**

---

## Deployed Contracts Reference

```solidity
// === TOKENS ===
address constant MOCK_IDRX = 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05;
address constant MOCK_USDC = 0x96ABff3a2668B811371d7d763f06B3832CEdf38d;
address constant XAUT = 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78;

// === INFRASTRUCTURE ===
address constant IDENTITY_REGISTRY = 0x620870d419F6aFca8AFed5B516619aa50900cadc;
address constant WMNT = 0xa2ddbfc12ab0B69c04eDCf1044382B9A38f883c3;

// === DEX (UniswapV2) ===
address constant UNISWAP_FACTORY = 0x8950d0D71a23085C514350df2682c3f6F1D7aBFE;
address constant UNISWAP_ROUTER = 0x54166b2C5e09f16c3c1D705FfB4eb29a069000A9; // Router V2 (Dec 20, 2024)
address constant IDRX_USDC_PAIR = 0xD3FF8e1C2821745513Ef83f3551668A7ce791Fe2;
address constant XAUT_USDC_PAIR = 0xc2da5178F53f45f604A275a3934979944eB15602;

// === CORE PROTOCOL ===
address constant GOLD_VAULT = 0xd92cE2F13509840B1203D35218227559E64fbED0; // Redeployed with Router V2
address constant SWAP_ROUTER = 0xF948Dd812E7fA072367848ec3D198cc61488b1b9; // Redeployed with Router V2

// === DEPLOYER/ADMIN ===
address constant DEPLOYER = 0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1;
```

### Network Configuration

```
Chain ID:    5003
Network:     Mantle Sepolia
RPC URL:     https://rpc.sepolia.mantle.xyz
Explorer:    https://sepolia.mantlescan.xyz
Native:      MNT
```

---

## Test Suite 1: Token Tests

### Prompt

```
Buatkan Foundry test suite untuk Token Tests pada AuRoom Protocol.

## Context
AuRoom Protocol adalah platform RWA untuk swap IDRX ke tokenized gold (XAUT) dengan yield-bearing vault di Mantle Sepolia.

## Deployed Contracts

```solidity
address constant MOCK_IDRX = 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05;
address constant MOCK_USDC = 0x96ABff3a2668B811371d7d763f06B3832CEdf38d;
address constant XAUT = 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78;
address constant IDENTITY_REGISTRY = 0x620870d419F6aFca8AFed5B516619aa50900cadc;
address constant DEPLOYER = 0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1;
```

## Network
- Chain ID: 5003 (Mantle Sepolia)
- RPC: https://rpc.sepolia.mantle.xyz
- Fork testing menggunakan actual deployed contracts

## Test File: test/suite1/TokenTests.t.sol

## Tests yang Dibutuhkan

### 1.1 MockIDRX Tests
```
test_IDRX_Name() - Should return "Mock IDRX"
test_IDRX_Symbol() - Should return "IDRX"
test_IDRX_Decimals() - Should return 6
test_IDRX_Transfer() - Should transfer tokens correctly between addresses
```

### 1.2 MockUSDC Tests
```
test_USDC_Name() - Should return correct name
test_USDC_Symbol() - Should return "USDC"
test_USDC_Decimals() - Should return 6
test_USDC_Transfer() - Should transfer tokens correctly
```

### 1.3 XAUT Tests (Compliant Token)
```
test_XAUT_Name() - Should return correct name
test_XAUT_Symbol() - Should return "XAUT"
test_XAUT_Decimals() - Should return 6
test_XAUT_IdentityRegistry() - Should have correct IdentityRegistry reference
test_XAUT_TransferBetweenVerified() - Should transfer between verified addresses
test_XAUT_TransferToUnverified_ShouldRevert() - Should REVERT transfer to unverified
test_XAUT_TransferFromUnverified_ShouldRevert() - Should REVERT transfer from unverified
```

## Template Structure

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IXAUT is IERC20 {
    function identityRegistry() external view returns (address);
}

interface IIdentityRegistry {
    function isVerified(address user) external view returns (bool);
    function registerIdentity(address user) external;
}

contract TokenTests is Test {
    // Contract addresses
    address constant MOCK_IDRX = 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05;
    address constant MOCK_USDC = 0x96ABff3a2668B811371d7d763f06B3832CEdf38d;
    address constant XAUT = 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78;
    address constant IDENTITY_REGISTRY = 0x620870d419F6aFca8AFed5B516619aa50900cadc;
    address constant DEPLOYER = 0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1;
    
    // Contracts
    IERC20 idrx;
    IERC20 usdc;
    IXAUT xaut;
    IIdentityRegistry identityRegistry;
    
    // Test users
    address verifiedUser;
    address unverifiedUser;
    
    function setUp() public {
        // Fork Mantle Sepolia
        // Initialize contracts
        // Setup test users
    }
    
    // === IDRX TESTS ===
    function test_IDRX_Name() public {
        console.log("=== Test: IDRX Name ===");
        // Implementation
        console.log("=== PASSED ===");
    }
    
    function test_IDRX_Symbol() public { }
    function test_IDRX_Decimals() public { }
    function test_IDRX_Transfer() public { }
    
    // === USDC TESTS ===
    function test_USDC_Name() public { }
    function test_USDC_Symbol() public { }
    function test_USDC_Decimals() public { }
    function test_USDC_Transfer() public { }
    
    // === XAUT TESTS ===
    function test_XAUT_Name() public { }
    function test_XAUT_Symbol() public { }
    function test_XAUT_Decimals() public { }
    function test_XAUT_IdentityRegistry() public { }
    function test_XAUT_TransferBetweenVerified() public { }
    function test_XAUT_TransferToUnverified_ShouldRevert() public { }
    function test_XAUT_TransferFromUnverified_ShouldRevert() public { }
}
```

## Requirements
1. Setiap test harus punya console.log untuk visibility
2. Setiap test harus punya assertion message yang jelas
3. Gunakan vm.prank() untuk impersonate users
4. Gunakan vm.expectRevert() untuk test yang expect revert
5. Setup harus menggunakan fork dari Mantle Sepolia

## Run Command
```bash
forge test --match-path test/suite1/TokenTests.t.sol -vvv --fork-url https://rpc.sepolia.mantle.xyz
```

Generate complete test file.
```

### Expected Tests: 11

---

## Test Suite 2: IdentityRegistry Tests

### Prompt

```
Buatkan Foundry test suite untuk IdentityRegistry Tests pada AuRoom Protocol.

## Context
IdentityRegistry adalah contract untuk menyimpan KYC status (verified/not verified) per wallet address. Ini adalah simplified version dari ERC-3643.

## Deployed Contracts

```solidity
address constant IDENTITY_REGISTRY = 0x620870d419F6aFca8AFed5B516619aa50900cadc;
address constant DEPLOYER = 0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1; // Owner & Admin
```

## Network
- Chain ID: 5003 (Mantle Sepolia)
- RPC: https://rpc.sepolia.mantle.xyz

## Test File: test/suite2/IdentityRegistryTests.t.sol

## Tests yang Dibutuhkan

### 2.1 Admin & Access Control
```
test_Owner_IsAdmin() - Owner should automatically be admin
test_IsAdmin_ReturnsCorrect() - isAdmin returns correct status
test_OnlyAdmin_CanRegister() - Non-admin cannot register (should revert)
test_OnlyOwner_CanAddAdmin() - Non-owner cannot add admin (should revert)
```

### 2.2 Registration Functions
```
test_RegisterIdentity_Success() - Admin can register new identity
test_RegisterIdentity_AlreadyRegistered() - Can register same address twice (idempotent or revert?)
test_RemoveIdentity_Success() - Admin can remove identity
test_BatchRegisterIdentity_Success() - Admin can batch register multiple addresses
test_IsVerified_ReturnsCorrect() - isVerified returns true for registered, false for unregistered
```

### 2.3 Events
```
test_RegisterIdentity_EmitsEvent() - Should emit IdentityRegistered event
test_RemoveIdentity_EmitsEvent() - Should emit IdentityRemoved event
```

## Interface

```solidity
interface IIdentityRegistry {
    event IdentityRegistered(address indexed user, uint256 timestamp);
    event IdentityRemoved(address indexed user, uint256 timestamp);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    
    function registerIdentity(address user) external;
    function removeIdentity(address user) external;
    function batchRegisterIdentity(address[] calldata users) external;
    function isVerified(address user) external view returns (bool);
    function isAdmin(address account) external view returns (bool);
    function addAdmin(address admin) external;
    function removeAdmin(address admin) external;
    function owner() external view returns (address);
}
```

## Template Structure

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";

interface IIdentityRegistry {
    event IdentityRegistered(address indexed user, uint256 timestamp);
    event IdentityRemoved(address indexed user, uint256 timestamp);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    
    function registerIdentity(address user) external;
    function removeIdentity(address user) external;
    function batchRegisterIdentity(address[] calldata users) external;
    function isVerified(address user) external view returns (bool);
    function isAdmin(address account) external view returns (bool);
    function addAdmin(address admin) external;
    function removeAdmin(address admin) external;
    function owner() external view returns (address);
}

contract IdentityRegistryTests is Test {
    address constant IDENTITY_REGISTRY = 0x620870d419F6aFca8AFed5B516619aa50900cadc;
    address constant DEPLOYER = 0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1;
    
    IIdentityRegistry registry;
    
    address newUser1;
    address newUser2;
    address newUser3;
    address nonAdmin;
    
    function setUp() public {
        // Fork Mantle Sepolia
        vm.createSelectFork("https://rpc.sepolia.mantle.xyz");
        
        // Initialize registry
        registry = IIdentityRegistry(IDENTITY_REGISTRY);
        
        // Create test addresses
        newUser1 = makeAddr("newUser1");
        newUser2 = makeAddr("newUser2");
        newUser3 = makeAddr("newUser3");
        nonAdmin = makeAddr("nonAdmin");
    }
    
    // === ADMIN TESTS ===
    function test_Owner_IsAdmin() public {
        console.log("=== Test: Owner Is Admin ===");
        address owner = registry.owner();
        bool isAdmin = registry.isAdmin(owner);
        assertTrue(isAdmin, "Owner should be admin");
        console.log("Owner:", owner);
        console.log("Is Admin:", isAdmin);
        console.log("=== PASSED ===");
    }
    
    function test_IsAdmin_ReturnsCorrect() public { }
    function test_OnlyAdmin_CanRegister() public { }
    function test_OnlyOwner_CanAddAdmin() public { }
    
    // === REGISTRATION TESTS ===
    function test_RegisterIdentity_Success() public { }
    function test_RemoveIdentity_Success() public { }
    function test_BatchRegisterIdentity_Success() public { }
    function test_IsVerified_ReturnsCorrect() public { }
    
    // === EVENT TESTS ===
    function test_RegisterIdentity_EmitsEvent() public { }
    function test_RemoveIdentity_EmitsEvent() public { }
}
```

## Requirements
1. Gunakan vm.prank(DEPLOYER) untuk operasi admin
2. Gunakan vm.expectRevert() untuk test unauthorized access
3. Gunakan vm.expectEmit() untuk test events
4. Test users harus fresh addresses (bukan yang sudah registered)

## Run Command
```bash
forge test --match-path test/suite2/IdentityRegistryTests.t.sol -vvv --fork-url https://rpc.sepolia.mantle.xyz
```

Generate complete test file.
```

### Expected Tests: 10

---

## Test Suite 3: DEX Tests

### Prompt

```
Buatkan Foundry test suite untuk DEX Tests (UniswapV2) pada AuRoom Protocol.

## Context
AuRoom menggunakan Uniswap V2 fork untuk liquidity pools. Ada 2 pairs: IDRX/USDC dan XAUT/USDC.

## Deployed Contracts

```solidity
address constant MOCK_IDRX = 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05;
address constant MOCK_USDC = 0x96ABff3a2668B811371d7d763f06B3832CEdf38d;
address constant XAUT = 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78;
address constant UNISWAP_FACTORY = 0x8950d0D71a23085C514350df2682c3f6F1D7aBFE;
address constant UNISWAP_ROUTER = 0x54166b2C5e09f16c3c1D705FfB4eb29a069000A9; // Router V2
address constant IDRX_USDC_PAIR = 0xD3FF8e1C2821745513Ef83f3551668A7ce791Fe2;
address constant XAUT_USDC_PAIR = 0xc2da5178F53f45f604A275a3934979944eB15602;
address constant DEPLOYER = 0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1;
```

## Network
- Chain ID: 5003 (Mantle Sepolia)
- RPC: https://rpc.sepolia.mantle.xyz

## Test File: test/suite3/DEXTests.t.sol

## Tests yang Dibutuhkan

### 3.1 Factory Tests
```
test_Factory_GetPair_IDRX_USDC() - Should return correct pair address
test_Factory_GetPair_XAUT_USDC() - Should return correct pair address
test_Factory_AllPairsLength() - Should return 2 (or more)
```

### 3.2 Pool Reserves Tests
```
test_IDRX_USDC_Reserves() - Should have non-zero reserves
test_XAUT_USDC_Reserves() - Should have non-zero reserves
test_Reserves_MatchExpected() - Reserves should roughly match initial liquidity
```

### 3.3 Quote Tests
```
test_GetAmountsOut_IDRX_to_USDC() - Should return valid quote
test_GetAmountsOut_USDC_to_XAUT() - Should return valid quote
test_GetAmountsOut_MultiHop_IDRX_USDC_XAUT() - Should return valid multi-hop quote
```

### 3.4 Swap Tests (via Router)
```
test_Swap_IDRX_to_USDC() - Should swap successfully
test_Swap_USDC_to_XAUT() - Should swap successfully (need verified user)
test_Swap_SlippageProtection() - Should revert if amountOut < minOut
```

## Interfaces

```solidity
interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairsLength() external view returns (uint);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IUniswapV2Router02 {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}
```

## Template Structure

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairsLength() external view returns (uint);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IUniswapV2Router02 {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract DEXTests is Test {
    // Constants
    address constant MOCK_IDRX = 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05;
    address constant MOCK_USDC = 0x96ABff3a2668B811371d7d763f06B3832CEdf38d;
    address constant XAUT = 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78;
    address constant UNISWAP_FACTORY = 0x8950d0D71a23085C514350df2682c3f6F1D7aBFE;
    address constant UNISWAP_ROUTER = 0x54166b2C5e09f16c3c1D705FfB4eb29a069000A9; // Router V2
    address constant IDRX_USDC_PAIR = 0xD3FF8e1C2821745513Ef83f3551668A7ce791Fe2;
    address constant XAUT_USDC_PAIR = 0xc2da5178F53f45f604A275a3934979944eB15602;
    address constant DEPLOYER = 0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1;
    
    // Contracts
    IUniswapV2Factory factory;
    IUniswapV2Router02 router;
    IUniswapV2Pair idrxUsdcPair;
    IUniswapV2Pair xautUsdcPair;
    IERC20 idrx;
    IERC20 usdc;
    IERC20 xaut;
    
    function setUp() public {
        vm.createSelectFork("https://rpc.sepolia.mantle.xyz");
        
        factory = IUniswapV2Factory(UNISWAP_FACTORY);
        router = IUniswapV2Router02(UNISWAP_ROUTER);
        idrxUsdcPair = IUniswapV2Pair(IDRX_USDC_PAIR);
        xautUsdcPair = IUniswapV2Pair(XAUT_USDC_PAIR);
        idrx = IERC20(MOCK_IDRX);
        usdc = IERC20(MOCK_USDC);
        xaut = IERC20(XAUT);
    }
    
    // === FACTORY TESTS ===
    function test_Factory_GetPair_IDRX_USDC() public {
        console.log("=== Test: Factory GetPair IDRX/USDC ===");
        address pair = factory.getPair(MOCK_IDRX, MOCK_USDC);
        assertEq(pair, IDRX_USDC_PAIR, "Pair address should match");
        console.log("Pair address:", pair);
        console.log("=== PASSED ===");
    }
    
    function test_Factory_GetPair_XAUT_USDC() public { }
    function test_Factory_AllPairsLength() public { }
    
    // === RESERVES TESTS ===
    function test_IDRX_USDC_Reserves() public { }
    function test_XAUT_USDC_Reserves() public { }
    
    // === QUOTE TESTS ===
    function test_GetAmountsOut_IDRX_to_USDC() public { }
    function test_GetAmountsOut_USDC_to_XAUT() public { }
    function test_GetAmountsOut_MultiHop() public { }
    
    // === SWAP TESTS ===
    function test_Swap_IDRX_to_USDC() public { }
    function test_Swap_SlippageProtection() public { }
}
```

## Run Command
```bash
forge test --match-path test/suite3/DEXTests.t.sol -vvv --fork-url https://rpc.sepolia.mantle.xyz
```

Generate complete test file.
```

### Expected Tests: 9

---

## Test Suite 4: SwapRouter Tests

### Prompt

```
Buatkan Foundry test suite untuk SwapRouter Tests pada AuRoom Protocol.

## Context
SwapRouter adalah custom router untuk swap IDRX ↔ XAUT dengan routing melalui USDC. Path: IDRX → USDC → XAUT.

## Deployed Contracts

```solidity
address constant SWAP_ROUTER = 0xF948Dd812E7fA072367848ec3D198cc61488b1b9; // Redeployed with Router V2
address constant MOCK_IDRX = 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05;
address constant MOCK_USDC = 0x96ABff3a2668B811371d7d763f06B3832CEdf38d;
address constant XAUT = 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78;
address constant IDENTITY_REGISTRY = 0x620870d419F6aFca8AFed5B516619aa50900cadc;
address constant DEPLOYER = 0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1;
```

## Network
- Chain ID: 5003 (Mantle Sepolia)
- RPC: https://rpc.sepolia.mantle.xyz

## Test File: test/suite4/SwapRouterTests.t.sol

## Tests yang Dibutuhkan

### 4.1 Configuration Tests
```
test_Router_IDRX_Address() - Should return correct IDRX address
test_Router_USDC_Address() - Should return correct USDC address
test_Router_XAUT_Address() - Should return correct XAUT address
test_Router_UniswapRouter_Address() - Should return correct Uniswap router
```

### 4.2 Quote Tests
```
test_GetQuoteIDRXtoXAUT_ReturnsValue() - Should return non-zero quote
test_GetQuoteXAUTtoIDRX_ReturnsValue() - Should return non-zero quote
test_Quote_MatchesActualSwap() - Quote should match actual swap output (within tolerance)
```

### 4.3 Swap IDRX → XAUT Tests
```
test_SwapIDRXtoXAUT_Success() - Verified user can swap
test_SwapIDRXtoXAUT_BalancesCorrect() - User balances update correctly
test_SwapIDRXtoXAUT_EmitsEvent() - Should emit Swap event
```

### 4.4 Swap XAUT → IDRX Tests
```
test_SwapXAUTtoIDRX_Success() - Verified user can swap
test_SwapXAUTtoIDRX_BalancesCorrect() - User balances update correctly
test_SwapXAUTtoIDRX_EmitsEvent() - Should emit Swap event
```

### 4.5 Slippage & Deadline Tests
```
test_Swap_SlippageProtection_Reverts() - Should revert if amountOut < amountOutMin
test_Swap_DeadlineExpired_Reverts() - Should revert if deadline passed
```

### 4.6 Compliance Tests
```
test_SwapIDRXtoXAUT_UnverifiedUser_Reverts() - Unverified cannot receive XAUT
```

## Interface

```solidity
interface ISwapRouter {
    event Swap(
        address indexed user,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 timestamp
    );
    
    function swapIDRXtoXAUT(
        uint256 amountIn,
        uint256 amountOutMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);
    
    function swapXAUTtoIDRX(
        uint256 amountIn,
        uint256 amountOutMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);
    
    function getQuoteIDRXtoXAUT(uint256 amountIn) external view returns (uint256 amountOut);
    function getQuoteXAUTtoIDRX(uint256 amountIn) external view returns (uint256 amountOut);
    
    function idrx() external view returns (address);
    function usdc() external view returns (address);
    function xaut() external view returns (address);
    function uniswapRouter() external view returns (address);
}

interface IIdentityRegistry {
    function isVerified(address user) external view returns (bool);
    function registerIdentity(address user) external;
}
```

## Template Structure

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISwapRouter {
    event Swap(
        address indexed user,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 timestamp
    );
    
    function swapIDRXtoXAUT(uint256 amountIn, uint256 amountOutMin, address to, uint256 deadline) external returns (uint256 amountOut);
    function swapXAUTtoIDRX(uint256 amountIn, uint256 amountOutMin, address to, uint256 deadline) external returns (uint256 amountOut);
    function getQuoteIDRXtoXAUT(uint256 amountIn) external view returns (uint256 amountOut);
    function getQuoteXAUTtoIDRX(uint256 amountIn) external view returns (uint256 amountOut);
    function idrx() external view returns (address);
    function usdc() external view returns (address);
    function xaut() external view returns (address);
    function uniswapRouter() external view returns (address);
}

interface IIdentityRegistry {
    function isVerified(address user) external view returns (bool);
    function registerIdentity(address user) external;
}

interface IMockToken is IERC20 {
    function mint(address to, uint256 amount) external;
}

contract SwapRouterTests is Test {
    // Constants
    address constant SWAP_ROUTER = 0xF948Dd812E7fA072367848ec3D198cc61488b1b9; // Redeployed with Router V2
    address constant MOCK_IDRX = 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05;
    address constant MOCK_USDC = 0x96ABff3a2668B811371d7d763f06B3832CEdf38d;
    address constant XAUT = 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78;
    address constant IDENTITY_REGISTRY = 0x620870d419F6aFca8AFed5B516619aa50900cadc;
    address constant DEPLOYER = 0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1;
    
    // Contracts
    ISwapRouter swapRouter;
    IIdentityRegistry identityRegistry;
    IMockToken idrx;
    IERC20 xaut;
    
    // Test users
    address verifiedUser;
    address unverifiedUser;
    
    uint256 constant SWAP_AMOUNT = 1000 * 10**6; // 1000 IDRX
    
    function setUp() public {
        vm.createSelectFork("https://rpc.sepolia.mantle.xyz");
        
        swapRouter = ISwapRouter(SWAP_ROUTER);
        identityRegistry = IIdentityRegistry(IDENTITY_REGISTRY);
        idrx = IMockToken(MOCK_IDRX);
        xaut = IERC20(XAUT);
        
        // Create test users
        verifiedUser = makeAddr("verifiedUser");
        unverifiedUser = makeAddr("unverifiedUser");
        
        // Setup verified user
        vm.prank(DEPLOYER);
        identityRegistry.registerIdentity(verifiedUser);
        
        // Mint IDRX to both users
        vm.prank(DEPLOYER);
        idrx.mint(verifiedUser, 10000 * 10**6);
        vm.prank(DEPLOYER);
        idrx.mint(unverifiedUser, 10000 * 10**6);
        
        // Approve for verified user
        vm.prank(verifiedUser);
        idrx.approve(SWAP_ROUTER, type(uint256).max);
    }
    
    // === CONFIGURATION TESTS ===
    function test_Router_IDRX_Address() public {
        console.log("=== Test: Router IDRX Address ===");
        assertEq(swapRouter.idrx(), MOCK_IDRX, "IDRX address should match");
        console.log("=== PASSED ===");
    }
    
    function test_Router_USDC_Address() public { }
    function test_Router_XAUT_Address() public { }
    function test_Router_UniswapRouter_Address() public { }
    
    // === QUOTE TESTS ===
    function test_GetQuoteIDRXtoXAUT_ReturnsValue() public { }
    function test_GetQuoteXAUTtoIDRX_ReturnsValue() public { }
    function test_Quote_MatchesActualSwap() public { }
    
    // === SWAP IDRX → XAUT ===
    function test_SwapIDRXtoXAUT_Success() public { }
    function test_SwapIDRXtoXAUT_BalancesCorrect() public { }
    
    // === SWAP XAUT → IDRX ===
    function test_SwapXAUTtoIDRX_Success() public { }
    function test_SwapXAUTtoIDRX_BalancesCorrect() public { }
    
    // === SLIPPAGE & DEADLINE ===
    function test_Swap_SlippageProtection_Reverts() public { }
    function test_Swap_DeadlineExpired_Reverts() public { }
    
    // === COMPLIANCE ===
    function test_SwapIDRXtoXAUT_UnverifiedUser_Reverts() public { }
}
```

## Important Notes
- Verified user perlu punya IDRX balance sebelum swap
- Verified user perlu approve IDRX ke SwapRouter sebelum swap
- Untuk test XAUT → IDRX, user perlu punya XAUT (bisa dari swap sebelumnya)

## Run Command
```bash
forge test --match-path test/suite4/SwapRouterTests.t.sol -vvv --fork-url https://rpc.sepolia.mantle.xyz
```

Generate complete test file.
```

### Expected Tests: 12

---

## Test Suite 5: GoldVault Tests

### Prompt

```
Buatkan Foundry test suite untuk GoldVault Tests pada AuRoom Protocol.

## Context
GoldVault adalah ERC-4626 compliant vault. User deposit XAUT dan menerima gXAUT (shares). Vault terintegrasi dengan IdentityRegistry untuk compliance.

## Deployed Contracts

```solidity
address constant GOLD_VAULT = 0xd92cE2F13509840B1203D35218227559E64fbED0; // Redeployed with Router V2
address constant XAUT = 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78;
address constant IDENTITY_REGISTRY = 0x620870d419F6aFca8AFed5B516619aa50900cadc;
address constant DEPLOYER = 0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1;
```

## Network
- Chain ID: 5003 (Mantle Sepolia)
- RPC: https://rpc.sepolia.mantle.xyz

## Test File: test/suite5/GoldVaultTests.t.sol

## Tests yang Dibutuhkan

### 5.1 Vault Info Tests
```
test_Vault_Name() - Should return "Gold Vault Token"
test_Vault_Symbol() - Should return "gXAUT"
test_Vault_Decimals() - Should return 6
test_Vault_Asset() - Should return XAUT address
```

### 5.2 Deposit Tests
```
test_Deposit_Success() - Verified user can deposit XAUT
test_Deposit_ReceivesShares() - User receives correct gXAUT shares
test_Deposit_TotalAssetsIncreases() - Vault totalAssets increases
test_Deposit_UnverifiedUser_Reverts() - Unverified user cannot deposit
test_Deposit_ZeroAmount() - Deposit 0 should revert or return 0
```

### 5.3 Withdraw Tests
```
test_Withdraw_Success() - Verified user can withdraw XAUT
test_Withdraw_ReceivesAssets() - User receives correct XAUT amount
test_Withdraw_SharesBurned() - gXAUT shares are burned
test_Withdraw_TotalAssetsDecreases() - Vault totalAssets decreases
test_Withdraw_MoreThanBalance_Reverts() - Cannot withdraw more than deposited
```

### 5.4 Redeem Tests
```
test_Redeem_Success() - Verified user can redeem gXAUT
test_Redeem_ReceivesAssets() - User receives correct XAUT
test_Redeem_SharesBurned() - Shares burned correctly
```

### 5.5 Share Calculation Tests
```
test_ConvertToShares_Correct() - convertToShares returns correct value
test_ConvertToAssets_Correct() - convertToAssets returns correct value
test_PreviewDeposit_MatchesActual() - previewDeposit matches actual deposit
test_PreviewWithdraw_MatchesActual() - previewWithdraw matches actual withdraw
test_PreviewRedeem_MatchesActual() - previewRedeem matches actual redeem
```

### 5.6 gXAUT Transfer Tests (Compliance)
```
test_gXAUT_TransferToVerified_Success() - Transfer to verified succeeds
test_gXAUT_TransferToUnverified_Reverts() - Transfer to unverified reverts
```

## Interface

```solidity
interface IGoldVault {
    // ERC-4626 functions
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
    
    function totalAssets() external view returns (uint256);
    function convertToShares(uint256 assets) external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
    function previewDeposit(uint256 assets) external view returns (uint256);
    function previewWithdraw(uint256 assets) external view returns (uint256);
    function previewRedeem(uint256 shares) external view returns (uint256);
    
    function asset() external view returns (address);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    
    // Custom
    function identityRegistry() external view returns (address);
}

interface IXAUT is IERC20 {
    function mint(address to, uint256 amount) external;
}

interface IIdentityRegistry {
    function isVerified(address user) external view returns (bool);
    function registerIdentity(address user) external;
}
```

## Template Structure

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGoldVault {
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
    function totalAssets() external view returns (uint256);
    function convertToShares(uint256 assets) external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
    function previewDeposit(uint256 assets) external view returns (uint256);
    function previewWithdraw(uint256 assets) external view returns (uint256);
    function previewRedeem(uint256 shares) external view returns (uint256);
    function asset() external view returns (address);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IXAUT is IERC20 {
    function mint(address to, uint256 amount) external;
}

interface IIdentityRegistry {
    function isVerified(address user) external view returns (bool);
    function registerIdentity(address user) external;
}

contract GoldVaultTests is Test {
    // Constants
    address constant GOLD_VAULT = 0xd92cE2F13509840B1203D35218227559E64fbED0; // Redeployed with Router V2
    address constant XAUT = 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78;
    address constant IDENTITY_REGISTRY = 0x620870d419F6aFca8AFed5B516619aa50900cadc;
    address constant DEPLOYER = 0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1;
    
    // Contracts
    IGoldVault vault;
    IXAUT xaut;
    IIdentityRegistry identityRegistry;
    
    // Test users
    address verifiedUser;
    address verifiedUser2;
    address unverifiedUser;
    
    uint256 constant DEPOSIT_AMOUNT = 10 * 10**6; // 10 XAUT
    
    function setUp() public {
        vm.createSelectFork("https://rpc.sepolia.mantle.xyz");
        
        vault = IGoldVault(GOLD_VAULT);
        xaut = IXAUT(XAUT);
        identityRegistry = IIdentityRegistry(IDENTITY_REGISTRY);
        
        // Create test users
        verifiedUser = makeAddr("verifiedUser");
        verifiedUser2 = makeAddr("verifiedUser2");
        unverifiedUser = makeAddr("unverifiedUser");
        
        // Register verified users
        vm.startPrank(DEPLOYER);
        identityRegistry.registerIdentity(verifiedUser);
        identityRegistry.registerIdentity(verifiedUser2);
        
        // Mint XAUT to verified user
        xaut.mint(verifiedUser, 100 * 10**6); // 100 XAUT
        vm.stopPrank();
        
        // Approve vault
        vm.prank(verifiedUser);
        xaut.approve(GOLD_VAULT, type(uint256).max);
    }
    
    // === VAULT INFO ===
    function test_Vault_Name() public {
        console.log("=== Test: Vault Name ===");
        string memory name = vault.name();
        assertEq(name, "Gold Vault Token", "Name should be Gold Vault Token");
        console.log("Name:", name);
        console.log("=== PASSED ===");
    }
    
    function test_Vault_Symbol() public { }
    function test_Vault_Decimals() public { }
    function test_Vault_Asset() public { }
    
    // === DEPOSIT ===
    function test_Deposit_Success() public { }
    function test_Deposit_ReceivesShares() public { }
    function test_Deposit_TotalAssetsIncreases() public { }
    function test_Deposit_UnverifiedUser_Reverts() public { }
    
    // === WITHDRAW ===
    function test_Withdraw_Success() public { }
    function test_Withdraw_ReceivesAssets() public { }
    function test_Withdraw_SharesBurned() public { }
    function test_Withdraw_MoreThanBalance_Reverts() public { }
    
    // === REDEEM ===
    function test_Redeem_Success() public { }
    function test_Redeem_ReceivesAssets() public { }
    
    // === SHARE CALCULATIONS ===
    function test_ConvertToShares_Correct() public { }
    function test_ConvertToAssets_Correct() public { }
    function test_PreviewDeposit_MatchesActual() public { }
    
    // === gXAUT COMPLIANCE ===
    function test_gXAUT_TransferToVerified_Success() public { }
    function test_gXAUT_TransferToUnverified_Reverts() public { }
}
```

## Important Notes
- User perlu XAUT balance sebelum deposit
- User perlu approve XAUT ke GoldVault sebelum deposit
- Initial share ratio biasanya 1:1 (1 XAUT = 1 gXAUT) jika vault kosong

## Run Command
```bash
forge test --match-path test/suite5/GoldVaultTests.t.sol -vvv --fork-url https://rpc.sepolia.mantle.xyz
```

Generate complete test file.
```

### Expected Tests: 16

---

## Test Suite 6: Integration Flow Tests

### Prompt

```
Buatkan Foundry test suite untuk Integration Flow Tests pada AuRoom Protocol.

## Context
Test ini menguji full user journey dari awal sampai akhir, mensimulasikan real user scenarios.

## Deployed Contracts

```solidity
address constant MOCK_IDRX = 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05;
address constant MOCK_USDC = 0x96ABff3a2668B811371d7d763f06B3832CEdf38d;
address constant XAUT = 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78;
address constant IDENTITY_REGISTRY = 0x620870d419F6aFca8AFed5B516619aa50900cadc;
address constant SWAP_ROUTER = 0xF948Dd812E7fA072367848ec3D198cc61488b1b9; // Redeployed with Router V2
address constant GOLD_VAULT = 0xd92cE2F13509840B1203D35218227559E64fbED0; // Redeployed with Router V2
address constant DEPLOYER = 0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1;
```

## Network
- Chain ID: 5003 (Mantle Sepolia)
- RPC: https://rpc.sepolia.mantle.xyz

## Test File: test/suite6/IntegrationFlowTests.t.sol

## Tests yang Dibutuhkan

### 6.1 New User Onboarding Flow
```
test_NewUserOnboarding()

Scenario: Budi adalah user baru yang mau beli emas digital

Steps:
1. Budi (unverified) punya IDRX
2. Budi coba swap IDRX → XAUT → REVERT (not verified)
3. Admin register Budi
4. Verify: isVerified(Budi) == true
5. Budi swap IDRX → XAUT → SUCCESS
6. Verify: Budi now has XAUT balance
```

### 6.2 Complete Swap & Stake Journey
```
test_SwapAndStakeJourney()

Scenario: Ani (verified) mau swap IDRX ke XAUT lalu stake untuk yield

Steps:
1. Ani starts with: 10,000,000 IDRX, 0 XAUT, 0 gXAUT
2. Ani approves IDRX to SwapRouter
3. Ani swaps 5,000,000 IDRX → XAUT
4. Verify: Ani IDRX decreased, Ani XAUT increased
5. Ani approves XAUT to GoldVault
6. Ani deposits all XAUT to GoldVault
7. Verify: Ani XAUT = 0, Ani gXAUT > 0
8. Log final balances
```

### 6.3 Withdraw & Swap Back Journey
```
test_WithdrawAndSwapBackJourney()

Scenario: Ani mau withdraw dan convert back ke IDRX

Prerequisites: Ani has gXAUT from previous deposit

Steps:
1. Ani starts with: gXAUT balance > 0
2. Ani redeems all gXAUT → XAUT
3. Verify: gXAUT = 0, XAUT > 0
4. Ani approves XAUT to SwapRouter
5. Ani swaps all XAUT → IDRX
6. Verify: XAUT = 0, IDRX > 0
7. Log final balances
```

### 6.4 Full Cycle Test
```
test_FullCycle_IDRXtoGXAUTtoIDRX()

Scenario: Complete round trip

Steps:
1. Start: User has 10,000,000 IDRX
2. Swap: IDRX → XAUT
3. Stake: XAUT → gXAUT
4. Redeem: gXAUT → XAUT
5. Swap: XAUT → IDRX
6. End: User has IDRX (less than start due to fees)
7. Verify: Final IDRX < Initial IDRX (fees taken)
8. Calculate and log total fees paid
```

## Interfaces

```solidity
interface ISwapRouter {
    function swapIDRXtoXAUT(uint256 amountIn, uint256 amountOutMin, address to, uint256 deadline) external returns (uint256);
    function swapXAUTtoIDRX(uint256 amountIn, uint256 amountOutMin, address to, uint256 deadline) external returns (uint256);
    function getQuoteIDRXtoXAUT(uint256 amountIn) external view returns (uint256);
}

interface IGoldVault {
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
    function balanceOf(address account) external view returns (uint256);
}

interface IIdentityRegistry {
    function isVerified(address user) external view returns (bool);
    function registerIdentity(address user) external;
}

interface IMockToken is IERC20 {
    function mint(address to, uint256 amount) external;
}
```

## Template Structure

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Interfaces here...

contract IntegrationFlowTests is Test {
    // Constants
    address constant MOCK_IDRX = 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05;
    address constant XAUT = 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78;
    address constant IDENTITY_REGISTRY = 0x620870d419F6aFca8AFed5B516619aa50900cadc;
    address constant SWAP_ROUTER = 0xF948Dd812E7fA072367848ec3D198cc61488b1b9; // Redeployed with Router V2
    address constant GOLD_VAULT = 0xd92cE2F13509840B1203D35218227559E64fbED0; // Redeployed with Router V2
    address constant DEPLOYER = 0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1;
    
    // Contracts
    ISwapRouter swapRouter;
    IGoldVault vault;
    IIdentityRegistry identityRegistry;
    IMockToken idrx;
    IERC20 xaut;
    
    // Test users
    address ani;
    address budi;
    
    uint256 constant INITIAL_IDRX = 10_000_000 * 10**6; // 10M IDRX
    
    function setUp() public {
        vm.createSelectFork("https://rpc.sepolia.mantle.xyz");
        
        // Initialize contracts
        swapRouter = ISwapRouter(SWAP_ROUTER);
        vault = IGoldVault(GOLD_VAULT);
        identityRegistry = IIdentityRegistry(IDENTITY_REGISTRY);
        idrx = IMockToken(MOCK_IDRX);
        xaut = IERC20(XAUT);
        
        // Create test users
        ani = makeAddr("ani");
        budi = makeAddr("budi");
        
        // Setup Ani as verified with IDRX
        vm.startPrank(DEPLOYER);
        identityRegistry.registerIdentity(ani);
        idrx.mint(ani, INITIAL_IDRX);
        vm.stopPrank();
        
        // Setup Budi as unverified with IDRX
        vm.prank(DEPLOYER);
        idrx.mint(budi, INITIAL_IDRX);
    }
    
    // Helper: Log balances
    function _logBalances(address user, string memory label) internal view {
        console.log("--- Balances for", label, "---");
        console.log("IDRX:", idrx.balanceOf(user));
        console.log("XAUT:", xaut.balanceOf(user));
        console.log("gXAUT:", vault.balanceOf(user));
    }
    
    function test_NewUserOnboarding() public {
        console.log("========================================");
        console.log("=== Test: New User Onboarding Flow ===");
        console.log("========================================");
        
        // Step 1: Budi is unverified
        console.log("\nStep 1: Verify Budi is unverified");
        assertFalse(identityRegistry.isVerified(budi), "Budi should be unverified");
        console.log("Budi verified:", identityRegistry.isVerified(budi));
        
        // Step 2: Budi tries to swap - should revert
        console.log("\nStep 2: Budi tries swap - expecting revert");
        vm.startPrank(budi);
        idrx.approve(SWAP_ROUTER, type(uint256).max);
        vm.expectRevert();
        swapRouter.swapIDRXtoXAUT(1000 * 10**6, 0, budi, block.timestamp + 300);
        vm.stopPrank();
        console.log("Swap reverted as expected");
        
        // Step 3: Admin registers Budi
        console.log("\nStep 3: Admin registers Budi");
        vm.prank(DEPLOYER);
        identityRegistry.registerIdentity(budi);
        
        // Step 4: Verify Budi is now verified
        console.log("\nStep 4: Verify Budi status");
        assertTrue(identityRegistry.isVerified(budi), "Budi should be verified");
        console.log("Budi verified:", identityRegistry.isVerified(budi));
        
        // Step 5: Budi swaps successfully
        console.log("\nStep 5: Budi swaps IDRX -> XAUT");
        uint256 swapAmount = 1000 * 10**6;
        vm.prank(budi);
        uint256 xautReceived = swapRouter.swapIDRXtoXAUT(swapAmount, 0, budi, block.timestamp + 300);
        console.log("XAUT received:", xautReceived);
        
        // Step 6: Verify Budi has XAUT
        console.log("\nStep 6: Verify final balances");
        assertGt(xaut.balanceOf(budi), 0, "Budi should have XAUT");
        _logBalances(budi, "Budi");
        
        console.log("\n========================================");
        console.log("=== PASSED: New User Onboarding ===");
        console.log("========================================");
    }
    
    function test_SwapAndStakeJourney() public { }
    function test_WithdrawAndSwapBackJourney() public { }
    function test_FullCycle_IDRXtoGXAUTtoIDRX() public { }
}
```

## Important Notes
- Setiap test harus independent (tidak depend on state dari test lain)
- Gunakan setUp() untuk prepare fresh state
- Log semua balances sebelum dan sesudah setiap step
- Calculate dan log fees/slippage di full cycle test

## Run Command
```bash
forge test --match-path test/suite6/IntegrationFlowTests.t.sol -vvv --fork-url https://rpc.sepolia.mantle.xyz
```

Generate complete test file.
```

### Expected Tests: 4

---

## Test Suite 7: Edge Cases & Security Tests

### Prompt

```
Buatkan Foundry test suite untuk Edge Cases & Security Tests pada AuRoom Protocol.

## Context
Test ini menguji error handling, edge cases, dan security aspects dari protocol.

## Deployed Contracts

```solidity
address constant MOCK_IDRX = 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05;
address constant XAUT = 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78;
address constant IDENTITY_REGISTRY = 0x620870d419F6aFca8AFed5B516619aa50900cadc;
address constant SWAP_ROUTER = 0xF948Dd812E7fA072367848ec3D198cc61488b1b9; // Redeployed with Router V2
address constant GOLD_VAULT = 0xd92cE2F13509840B1203D35218227559E64fbED0; // Redeployed with Router V2
address constant DEPLOYER = 0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1;
```

## Network
- Chain ID: 5003 (Mantle Sepolia)
- RPC: https://rpc.sepolia.mantle.xyz

## Test File: test/suite7/EdgeCasesSecurityTests.t.sol

## Tests yang Dibutuhkan

### 7.1 Zero Amount Edge Cases
```
test_Swap_ZeroAmount_Reverts() - Swap with 0 amount should revert
test_Deposit_ZeroAmount_Reverts() - Deposit 0 to vault should revert
test_Withdraw_ZeroAmount_Reverts() - Withdraw 0 should revert
```

### 7.2 Insufficient Balance Edge Cases
```
test_Swap_InsufficientBalance_Reverts() - Swap more than balance
test_Withdraw_InsufficientShares_Reverts() - Withdraw more than deposited
test_Transfer_InsufficientBalance_Reverts() - Transfer more than balance
```

### 7.3 Approval Edge Cases
```
test_Swap_WithoutApproval_Reverts() - Swap without approve should revert
test_Deposit_WithoutApproval_Reverts() - Deposit without approve should revert
test_TransferFrom_WithoutApproval_Reverts() - TransferFrom without approve
```

### 7.4 Access Control Tests
```
test_IdentityRegistry_NonAdmin_CannotRegister() - Non-admin cannot register
test_IdentityRegistry_NonOwner_CannotAddAdmin() - Non-owner cannot add admin
test_XAUT_NonOwner_CannotMint() - Non-owner cannot mint XAUT
test_XAUT_NonOwner_CannotPause() - Non-owner cannot pause (if applicable)
```

### 7.5 Deadline & Timing Tests
```
test_Swap_ExpiredDeadline_Reverts() - Swap with past deadline reverts
test_Swap_ExactDeadline_Success() - Swap at exact deadline succeeds
```

### 7.6 Reentrancy Protection (if applicable)
```
test_Vault_ReentrancyProtection() - Reentrancy attack should fail
test_SwapRouter_ReentrancyProtection() - Reentrancy attack should fail
```

### 7.7 Identity Removal Edge Case
```
test_IdentityRemoved_CannotTransferXAUT() - User dengan identity removed tidak bisa transfer XAUT
test_IdentityRemoved_CanStillWithdrawVault() - User masih bisa withdraw dari vault? (design decision)
```

## Interfaces

```solidity
interface ISwapRouter {
    function swapIDRXtoXAUT(uint256 amountIn, uint256 amountOutMin, address to, uint256 deadline) external returns (uint256);
    function swapXAUTtoIDRX(uint256 amountIn, uint256 amountOutMin, address to, uint256 deadline) external returns (uint256);
}

interface IGoldVault {
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
    function balanceOf(address account) external view returns (uint256);
}

interface IIdentityRegistry {
    function isVerified(address user) external view returns (bool);
    function registerIdentity(address user) external;
    function removeIdentity(address user) external;
    function addAdmin(address admin) external;
}

interface IMockToken is IERC20 {
    function mint(address to, uint256 amount) external;
}

interface IXAUT is IERC20 {
    function mint(address to, uint256 amount) external;
    function pause() external;
}
```

## Template Structure

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Interfaces here...

contract EdgeCasesSecurityTests is Test {
    // Constants
    address constant MOCK_IDRX = 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05;
    address constant XAUT = 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78;
    address constant IDENTITY_REGISTRY = 0x620870d419F6aFca8AFed5B516619aa50900cadc;
    address constant SWAP_ROUTER = 0xF948Dd812E7fA072367848ec3D198cc61488b1b9; // Redeployed with Router V2
    address constant GOLD_VAULT = 0xd92cE2F13509840B1203D35218227559E64fbED0; // Redeployed with Router V2
    address constant DEPLOYER = 0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1;
    
    // Contracts
    ISwapRouter swapRouter;
    IGoldVault vault;
    IIdentityRegistry identityRegistry;
    IMockToken idrx;
    IXAUT xaut;
    
    // Test users
    address verifiedUser;
    address unverifiedUser;
    address attacker;
    
    function setUp() public {
        vm.createSelectFork("https://rpc.sepolia.mantle.xyz");
        
        // Initialize contracts
        swapRouter = ISwapRouter(SWAP_ROUTER);
        vault = IGoldVault(GOLD_VAULT);
        identityRegistry = IIdentityRegistry(IDENTITY_REGISTRY);
        idrx = IMockToken(MOCK_IDRX);
        xaut = IXAUT(XAUT);
        
        // Create test users
        verifiedUser = makeAddr("verifiedUser");
        unverifiedUser = makeAddr("unverifiedUser");
        attacker = makeAddr("attacker");
        
        // Setup verified user
        vm.startPrank(DEPLOYER);
        identityRegistry.registerIdentity(verifiedUser);
        idrx.mint(verifiedUser, 10000 * 10**6);
        xaut.mint(verifiedUser, 100 * 10**6);
        vm.stopPrank();
        
        // Approvals for verified user
        vm.startPrank(verifiedUser);
        idrx.approve(SWAP_ROUTER, type(uint256).max);
        xaut.approve(GOLD_VAULT, type(uint256).max);
        xaut.approve(SWAP_ROUTER, type(uint256).max);
        vm.stopPrank();
    }
    
    // === ZERO AMOUNT ===
    function test_Swap_ZeroAmount_Reverts() public {
        console.log("=== Test: Swap Zero Amount ===");
        
        vm.prank(verifiedUser);
        vm.expectRevert();
        swapRouter.swapIDRXtoXAUT(0, 0, verifiedUser, block.timestamp + 300);
        
        console.log("=== PASSED: Correctly reverted ===");
    }
    
    function test_Deposit_ZeroAmount_Reverts() public { }
    function test_Withdraw_ZeroAmount_Reverts() public { }
    
    // === INSUFFICIENT BALANCE ===
    function test_Swap_InsufficientBalance_Reverts() public { }
    function test_Withdraw_InsufficientShares_Reverts() public { }
    
    // === APPROVAL ===
    function test_Swap_WithoutApproval_Reverts() public { }
    function test_Deposit_WithoutApproval_Reverts() public { }
    
    // === ACCESS CONTROL ===
    function test_IdentityRegistry_NonAdmin_CannotRegister() public { }
    function test_XAUT_NonOwner_CannotMint() public { }
    
    // === DEADLINE ===
    function test_Swap_ExpiredDeadline_Reverts() public {
        console.log("=== Test: Expired Deadline ===");
        
        uint256 pastDeadline = block.timestamp - 1;
        
        vm.prank(verifiedUser);
        vm.expectRevert();
        swapRouter.swapIDRXtoXAUT(1000 * 10**6, 0, verifiedUser, pastDeadline);
        
        console.log("=== PASSED ===");
    }
    
    // === IDENTITY REMOVAL ===
    function test_IdentityRemoved_CannotTransferXAUT() public { }
}
```

## Run Command
```bash
forge test --match-path test/suite7/EdgeCasesSecurityTests.t.sol -vvv --fork-url https://rpc.sepolia.mantle.xyz
```

Generate complete test file.
```

### Expected Tests: 12

---

## Run Commands

### Run Individual Suite

```bash
# Suite 1: Token Tests
forge test --match-path test/suite1/TokenTests.t.sol -vvv --fork-url https://rpc.sepolia.mantle.xyz

# Suite 2: IdentityRegistry Tests
forge test --match-path test/suite2/IdentityRegistryTests.t.sol -vvv --fork-url https://rpc.sepolia.mantle.xyz

# Suite 3: DEX Tests
forge test --match-path test/suite3/DEXTests.t.sol -vvv --fork-url https://rpc.sepolia.mantle.xyz

# Suite 4: SwapRouter Tests
forge test --match-path test/suite4/SwapRouterTests.t.sol -vvv --fork-url https://rpc.sepolia.mantle.xyz

# Suite 5: GoldVault Tests
forge test --match-path test/suite5/GoldVaultTests.t.sol -vvv --fork-url https://rpc.sepolia.mantle.xyz

# Suite 6: Integration Flow Tests
forge test --match-path test/suite6/IntegrationFlowTests.t.sol -vvv --fork-url https://rpc.sepolia.mantle.xyz

# Suite 7: Edge Cases & Security
forge test --match-path test/suite7/EdgeCasesSecurityTests.t.sol -vvv --fork-url https://rpc.sepolia.mantle.xyz
```

### Run All Suites

```bash
# Run all test suites
forge test --match-path "test/suite*" -vvv --fork-url https://rpc.sepolia.mantle.xyz

# Run with gas report
forge test --match-path "test/suite*" -vvv --fork-url https://rpc.sepolia.mantle.xyz --gas-report

# Run with summary only (less verbose)
forge test --match-path "test/suite*" -v --fork-url https://rpc.sepolia.mantle.xyz
```

### Run Specific Test

```bash
# Run specific test function
forge test --match-test test_SwapIDRXtoXAUT_Success -vvv --fork-url https://rpc.sepolia.mantle.xyz

# Run tests matching pattern
forge test --match-test "test_Swap" -vvv --fork-url https://rpc.sepolia.mantle.xyz
```

---

## Expected Results

### Summary Report Format

Setelah semua test selesai, output harus seperti:

```
╔══════════════════════════════════════════════════════════════╗
║          AUROOM PROTOCOL - INTEGRATION TEST SUMMARY          ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  Suite 1: Token Tests ..................... 11/11 passed ✅  ║
║  Suite 2: IdentityRegistry Tests .......... 10/10 passed ✅  ║
║  Suite 3: DEX Tests ....................... 9/9 passed ✅    ║
║  Suite 4: SwapRouter Tests ................ 12/12 passed ✅  ║
║  Suite 5: GoldVault Tests ................. 16/16 passed ✅  ║
║  Suite 6: Integration Flow Tests .......... 4/4 passed ✅    ║
║  Suite 7: Edge Cases & Security ........... 12/12 passed ✅  ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║  TOTAL: 74/74 passed ✅                                      ║
║  Status: ALL TESTS PASSED                                    ║
╚══════════════════════════════════════════════════════════════╝
```

### Test Categories Breakdown

| Category | Tests | Coverage |
|----------|-------|----------|
| Token Functionality | 11 | Basic ERC-20, Compliance |
| Access Control | 10 | Admin, Owner, Registration |
| DEX Operations | 9 | Factory, Reserves, Quotes |
| Swap Functions | 12 | IDRX↔XAUT, Slippage, Deadline |
| Vault Operations | 16 | Deposit, Withdraw, Shares |
| User Journeys | 4 | Full E2E Flows |
| Edge Cases | 12 | Error Handling, Security |
| **TOTAL** | **74** | **Comprehensive** |

---

## Directory Structure

```
test/
├── suite1/
│   └── TokenTests.t.sol
├── suite2/
│   └── IdentityRegistryTests.t.sol
├── suite3/
│   └── DEXTests.t.sol
├── suite4/
│   └── SwapRouterTests.t.sol
├── suite5/
│   └── GoldVaultTests.t.sol
├── suite6/
│   └── IntegrationFlowTests.t.sol
├── suite7/
│   └── EdgeCasesSecurityTests.t.sol
└── interfaces/
    ├── IIdentityRegistry.sol
    ├── ISwapRouter.sol
    ├── IGoldVault.sol
    └── IMockToken.sol
```

---

## Notes

### Important Considerations

1. **Fork Testing**: Semua test menggunakan fork dari Mantle Sepolia untuk test terhadap actual deployed contracts

2. **Fresh State**: Setiap test suite menggunakan `setUp()` untuk memastikan state fresh

3. **Console Logging**: Setiap test memiliki console.log untuk visibility dan debugging

4. **Independent Tests**: Setiap test function independent dan tidak depend pada test lain

5. **vm.prank Usage**: Gunakan `vm.prank()` untuk simulate different users

6. **vm.expectRevert**: Gunakan untuk test yang expect revert

### Common Issues

1. **RPC Rate Limiting**: Jika terkena rate limit, gunakan private RPC atau tambahkan delay

2. **Nonce Issues**: Fork state bisa stale, re-run jika ada nonce mismatch

3. **Gas Estimation**: Beberapa test mungkin butuh gas limit adjustment

---

**Document Version:** 1.0.0  
**Last Updated:** December 19, 2024  
**Author:** AuRoom Protocol Team
