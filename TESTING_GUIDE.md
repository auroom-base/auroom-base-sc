# Testing Guide - Productive Gold Platform

## Quick Start

### Run All Tests
```bash
forge test
```

### Run Integration Tests Only
```bash
forge test --match-contract IntegrationTest
```

### Run With Gas Report
```bash
forge test --match-contract IntegrationTest --gas-report
```

---

## Test Structure

### File Organization
```
test/
├── Integration.t.sol          # Comprehensive integration tests (57 tests)
├── MockIDRX.t.sol            # MockIDRX unit tests
├── MockUSDC.t.sol            # MockUSDC unit tests
├── IdentityRegistry.t.sol    # IdentityRegistry unit tests
├── XAUT.t.sol                # XAUT unit tests
└── GoldVault.t.sol           # GoldVault unit tests
```

---

## Test Categories

### 1. Individual Contract Tests

#### MockIDRX & MockUSDC
```bash
forge test --match-test "test_MockIDRX_"
forge test --match-test "test_MockUSDC_"
```
**Coverage:**
- Deployment
- Minting (public & owner)
- Transfers
- Decimals (6)
- Balance updates

#### IdentityRegistry
```bash
forge test --match-test "test_IdentityRegistry_"
```
**Coverage:**
- Admin management
- User registration (single & batch)
- Identity removal
- Verification checks
- Access control

#### XAUT (Compliant Gold Token)
```bash
forge test --match-test "test_XAUT_"
```
**Coverage:**
- Compliance checks
- Verified transfers
- Unverified rejections
- Pause/unpause
- Registry updates

#### GoldVault (ERC-4626)
```bash
forge test --match-test "test_GoldVault_"
```
**Coverage:**
- Deposits (verified only)
- Withdrawals
- Share calculations
- Compliance on gXAUT
- Total assets tracking

#### SwapRouter
```bash
forge test --match-test "test_SwapRouter_"
```
**Coverage:**
- Price quotes
- IDRX → XAUT swaps
- XAUT → IDRX swaps
- Slippage protection
- Deadline checks

---

### 2. Integration Flow Tests

#### User Onboarding
```bash
forge test --match-test "test_Integration_NewUserOnboarding"
```
**Flow:** KYC → Receive IDRX → Swap to XAUT → Deposit to Vault

#### IDRX → XAUT → Vault
```bash
forge test --match-test "test_Integration_IDRXToXAUTToVault"
```
**Flow:** Swap IDRX for XAUT → Deposit into vault for yield

#### Vault → XAUT → IDRX
```bash
forge test --match-test "test_Integration_VaultToXAUTToIDRX"
```
**Flow:** Withdraw from vault → Swap XAUT back to IDRX

#### Compliance Restrictions
```bash
forge test --match-test "test_Integration_ComplianceRestrictions"
```
**Tests:** Unverified users blocked from receiving/depositing

#### Multi-User Vault
```bash
forge test --match-test "test_Integration_MultiUserVault"
```
**Tests:** Multiple users depositing/withdrawing independently

#### Emergency Scenarios
```bash
forge test --match-test "test_Integration_PauseUnpause"
forge test --match-test "test_Integration_KYCRevocation"
```
**Tests:** Pause controls, KYC revocation effects

#### Full Round-Trip
```bash
forge test --match-test "test_Integration_FullRoundTrip"
```
**Flow:** Complete user journey from IDRX → XAUT → Vault → XAUT → IDRX

#### Batch Operations
```bash
forge test --match-test "test_Integration_BatchKYCAndDeposits"
```
**Tests:** Batch KYC registration and deposits

---

## Running Specific Tests

### By Pattern
```bash
# All XAUT tests
forge test --match-test "XAUT"

# All integration tests
forge test --match-test "Integration"

# Specific test
forge test --match-test "test_Integration_NewUserOnboarding"
```

### With Verbosity

#### Level 1 (-v): Show test names
```bash
forge test --match-contract IntegrationTest -v
```

#### Level 2 (-vv): Show test names + logs
```bash
forge test --match-contract IntegrationTest -vv
```

#### Level 3 (-vvv): Show traces for failing tests
```bash
forge test --match-contract IntegrationTest -vvv
```

#### Level 4 (-vvvv): Show all traces
```bash
forge test --match-contract IntegrationTest -vvvv
```

---

## Debugging Tests

### Run Single Test with Full Traces
```bash
forge test --match-test "test_XAUT_TransferVerifiedToVerified" -vvvv
```

### Check Gas Usage
```bash
forge test --match-test "test_Integration_FullRoundTrip" --gas-report
```

### Run Tests in Watch Mode
```bash
forge test --watch --match-contract IntegrationTest
```

---

## Test Accounts

The integration tests use predefined accounts:

```solidity
owner:           address(this)   // Contract deployer
admin:           address(0xAD)   // KYC admin
user1:           address(0x1)    // Verified user 1
user2:           address(0x2)    // Verified user 2
unverifiedUser:  address(0x99)   // Not KYC verified
```

### Initial Balances (setUp)
```
IDRX:
  - owner:         1,000,000 IDRX
  - user1:         1,000,000 IDRX
  - uniswapRouter: 10,000,000 IDRX

USDC:
  - owner:         1,000,000 USDC
  - user1:         1,000,000 USDC
  - uniswapRouter: 10,000,000 USDC

XAUT:
  - owner:         1,000,000 XAUT
  - user1:         1,000,000 XAUT
  - user2:         1,000,000 XAUT
  - uniswapRouter: 10,000,000 XAUT
```

---

## Mock Contracts

### MockUniswapV2Router
Simplified price oracle for testing:
- 1 IDRX = 1 USDC
- 1 XAUT = 100 USDC
- **Therefore:** 1 XAUT = 100 IDRX

### MockUniswapV2Factory
Creates LP token pairs for testing

### MockLPToken
Simplified LP token with mock reserves

---

## Common Test Patterns

### Testing Compliance
```solidity
vm.prank(admin);
identityRegistry.registerIdentity(newUser);
assertTrue(identityRegistry.isVerified(newUser));
```

### Testing Swaps
```solidity
vm.startPrank(user1);
idrx.approve(address(swapRouter), amountIn);
uint256 amountOut = swapRouter.swapIDRXtoXAUT(
    amountIn,
    minAmountOut,
    user1,
    block.timestamp + 300
);
vm.stopPrank();
```

### Testing Vault Operations
```solidity
vm.startPrank(user1);
xaut.approve(address(goldVault), depositAmount);
uint256 shares = goldVault.deposit(depositAmount, user1);
vm.stopPrank();
```

### Testing Reverts
```solidity
vm.expectRevert("XAUT: recipient not verified");
xaut.transfer(unverifiedUser, amount);
```

---

## Coverage Report

### Generate Coverage
```bash
forge coverage
```

### Coverage with LCOV Report
```bash
forge coverage --report lcov
```

### Coverage for Specific Contract
```bash
forge coverage --match-contract XAUT
```

---

## CI/CD Integration

### GitHub Actions Example
```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: foundry-rs/foundry-toolchain@v1
      - run: forge test --match-contract IntegrationTest
```

---

## Expected Test Results

### Summary
```
Test Suite      | Passed | Failed | Skipped
================+=======+========+=========
IntegrationTest | 57    | 0      | 0
```

### Performance Benchmarks
- Individual tests: < 200,000 gas
- Simple integrations: ~150,000 gas
- Complex flows: ~300,000 gas
- Full round-trip: ~455,000 gas

---

## Troubleshooting

### Test Fails: "recipient not verified"
**Cause:** User not registered in IdentityRegistry
**Fix:** Add `identityRegistry.registerIdentity(user)` in setUp or test

### Test Fails: "insufficient balance"
**Cause:** Not enough tokens minted in setUp
**Fix:** Increase INITIAL_MINT or add extra mint in test

### Test Fails: "deadline expired"
**Cause:** Deadline in past
**Fix:** Use `block.timestamp + 300` for deadline

### Test Fails: "insufficient output amount"
**Cause:** Slippage too strict
**Fix:** Increase slippage tolerance (e.g., `quote * 95 / 100`)

---

## Best Practices

### 1. Always Use setUp
Initialize contracts and users in `setUp()` to ensure clean state

### 2. Use vm.prank for Access Control
```solidity
vm.prank(admin);  // Next call will be from admin
identityRegistry.registerIdentity(user);
```

### 3. Use vm.startPrank for Multiple Calls
```solidity
vm.startPrank(user1);
token.approve(spender, amount);
token.transfer(recipient, amount);
vm.stopPrank();
```

### 4. Test Events with expectEmit
```solidity
vm.expectEmit(true, true, false, true);
emit Transfer(from, to, amount);
token.transfer(to, amount);
```

### 5. Test Reverts with expectRevert
```solidity
vm.expectRevert("Error message");
contract.functionThatShouldRevert();
```

---

## Additional Resources

- [Foundry Book](https://book.getfoundry.sh/)
- [Forge Testing Guide](https://book.getfoundry.sh/forge/tests)
- [Cheatcodes Reference](https://book.getfoundry.sh/cheatcodes/)
- [Test Results](./TEST_RESULTS.md)

---

**Last Updated:** December 16, 2025
**Test Framework:** Foundry (Forge)
**Solidity Version:** 0.8.30
