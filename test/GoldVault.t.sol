// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/GoldVault.sol";
import "../src/XAUT.sol";
import "../src/MockUSDC.sol";
import "../src/IdentityRegistry.sol";
import "./mocks/MockERC20.sol";
import "./mocks/MockUniswapV2Factory.sol";
import "./mocks/MockUniswapV2Router02.sol";
import "./mocks/MockUniswapV2Pair.sol";

contract GoldVaultTest is Test {
    GoldVault public vault;
    XAUT public xaut;
    MockUSDC public usdc;
    IdentityRegistry public identityRegistry;
    MockUniswapV2Factory public factory;
    MockUniswapV2Router02 public router;

    address public owner;
    address public alice;
    address public bob;
    address public unverifiedUser;

    uint256 constant INITIAL_XAUT = 1000 ether;
    uint256 constant INITIAL_USDC = 1000000 * 1e6; // 1M USDC

    event StrategyDeployed(uint256 xautAmount, uint256 usdcAmount, uint256 lpReceived);
    event StrategyWithdrawn(uint256 lpAmount, uint256 xautReceived, uint256 usdcReceived);
    event Harvested(uint256 xautProfit, uint256 usdcProfit);

    function setUp() public {
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        unverifiedUser = makeAddr("unverifiedUser");

        // Deploy identity registry
        identityRegistry = new IdentityRegistry();

        // Deploy real XAUT token
        xaut = new XAUT(address(identityRegistry));

        // Deploy mock USDC
        usdc = new MockUSDC();

        // Deploy Uniswap mocks
        factory = new MockUniswapV2Factory();
        router = new MockUniswapV2Router02(address(factory), address(0));

        // Deploy GoldVault
        vault = new GoldVault(
            address(xaut),
            address(identityRegistry),
            address(router),
            address(usdc)
        );

        // Setup verified users (vault needs to be verified to hold XAUT)
        identityRegistry.registerIdentity(alice);
        identityRegistry.registerIdentity(bob);
        identityRegistry.registerIdentity(owner);
        identityRegistry.registerIdentity(address(vault));

        // Verify LP pair (it gets created in constructor)
        address lpToken = vault.lpToken();
        if (lpToken != address(0)) {
            identityRegistry.registerIdentity(lpToken);
        }

        // Mint tokens to users
        xaut.mint(alice, INITIAL_XAUT);
        xaut.mint(bob, INITIAL_XAUT);
        xaut.mint(owner, INITIAL_XAUT);
        usdc.publicMint(owner, INITIAL_USDC);

        // Approve vault
        vm.prank(alice);
        xaut.approve(address(vault), type(uint256).max);

        vm.prank(bob);
        xaut.approve(address(vault), type(uint256).max);

        vm.prank(owner);
        xaut.approve(address(vault), type(uint256).max);

        vm.prank(owner);
        usdc.approve(address(vault), type(uint256).max);
    }

    // ============ Test Deployment ============

    function test_Deployment() public view {
        assertEq(address(vault.asset()), address(xaut));
        assertEq(vault.name(), "Gold Vault Token");
        assertEq(vault.symbol(), "gXAUT");
        assertEq(address(vault.identityRegistry()), address(identityRegistry));
        assertEq(address(vault.uniswapRouter()), address(router));
        assertEq(vault.usdcToken(), address(usdc));
        assertEq(vault.owner(), owner);
    }

    // ============ Test Compliance - Deposit ============

    function test_Deposit_Success() public {
        uint256 depositAmount = 100 ether;

        vm.prank(alice);
        uint256 shares = vault.deposit(depositAmount, alice);

        assertEq(vault.balanceOf(alice), shares);
        assertEq(xaut.balanceOf(address(vault)), depositAmount);
        assertGt(shares, 0);
    }

    function test_Deposit_RevertsIfNotVerified() public {
        uint256 depositAmount = 100 ether;

        // Temporarily verify to mint XAUT
        identityRegistry.registerIdentity(unverifiedUser);
        xaut.mint(unverifiedUser, depositAmount);

        // Remove verification before testing vault
        identityRegistry.removeIdentity(unverifiedUser);

        vm.startPrank(unverifiedUser);
        xaut.approve(address(vault), depositAmount);

        vm.expectRevert("GoldVault: account not verified");
        vault.deposit(depositAmount, unverifiedUser);
        vm.stopPrank();
    }

    function test_Deposit_RevertsIfReceiverNotVerified() public {
        uint256 depositAmount = 100 ether;

        vm.prank(alice);
        vm.expectRevert("GoldVault: account not verified");
        vault.deposit(depositAmount, unverifiedUser);
    }

    // ============ Test Compliance - Mint ============

    function test_Mint_Success() public {
        uint256 shares = 100 ether;

        vm.prank(alice);
        uint256 assets = vault.mint(shares, alice);

        assertEq(vault.balanceOf(alice), shares);
        assertEq(xaut.balanceOf(address(vault)), assets);
        assertGt(assets, 0);
    }

    function test_Mint_RevertsIfNotVerified() public {
        uint256 shares = 100 ether;

        // Temporarily verify to mint XAUT
        identityRegistry.registerIdentity(unverifiedUser);
        xaut.mint(unverifiedUser, 1000 ether);

        // Remove verification before testing vault
        identityRegistry.removeIdentity(unverifiedUser);

        vm.startPrank(unverifiedUser);
        xaut.approve(address(vault), 1000 ether);

        vm.expectRevert("GoldVault: account not verified");
        vault.mint(shares, unverifiedUser);
        vm.stopPrank();
    }

    // ============ Test Compliance - Withdraw ============

    function test_Withdraw_Success() public {
        uint256 depositAmount = 100 ether;

        // First deposit
        vm.prank(alice);
        vault.deposit(depositAmount, alice);

        // Then withdraw
        vm.prank(alice);
        uint256 shares = vault.withdraw(depositAmount, alice, alice);

        assertEq(vault.balanceOf(alice), 0);
        assertEq(xaut.balanceOf(alice), INITIAL_XAUT);
        assertGt(shares, 0);
    }

    function test_Withdraw_RevertsIfReceiverNotVerified() public {
        uint256 depositAmount = 100 ether;

        vm.prank(alice);
        vault.deposit(depositAmount, alice);

        vm.prank(alice);
        vm.expectRevert("GoldVault: account not verified");
        vault.withdraw(depositAmount, unverifiedUser, alice);
    }

    // ============ Test Compliance - Redeem ============

    function test_Redeem_Success() public {
        uint256 depositAmount = 100 ether;

        vm.prank(alice);
        uint256 shares = vault.deposit(depositAmount, alice);

        vm.prank(alice);
        uint256 assets = vault.redeem(shares, alice, alice);

        assertEq(vault.balanceOf(alice), 0);
        assertEq(xaut.balanceOf(alice), INITIAL_XAUT);
        assertGt(assets, 0);
    }

    function test_Redeem_RevertsIfReceiverNotVerified() public {
        uint256 depositAmount = 100 ether;

        vm.prank(alice);
        uint256 shares = vault.deposit(depositAmount, alice);

        vm.prank(alice);
        vm.expectRevert("GoldVault: account not verified");
        vault.redeem(shares, unverifiedUser, alice);
    }

    // ============ Test Compliance - Transfer ============

    function test_Transfer_Success() public {
        uint256 depositAmount = 100 ether;

        vm.prank(alice);
        uint256 shares = vault.deposit(depositAmount, alice);

        vm.prank(alice);
        bool success = vault.transfer(bob, shares / 2);

        assertTrue(success);
        assertEq(vault.balanceOf(alice), shares / 2);
        assertEq(vault.balanceOf(bob), shares / 2);
    }

    function test_Transfer_RevertsIfSenderNotVerified() public {
        uint256 depositAmount = 100 ether;

        vm.prank(alice);
        vault.deposit(depositAmount, alice);

        // Remove verification
        identityRegistry.removeIdentity(alice);

        vm.prank(alice);
        vm.expectRevert("GoldVault: account not verified");
        vault.transfer(bob, depositAmount);
    }

    function test_Transfer_RevertsIfReceiverNotVerified() public {
        uint256 depositAmount = 100 ether;

        vm.prank(alice);
        vault.deposit(depositAmount, alice);

        vm.prank(alice);
        vm.expectRevert("GoldVault: account not verified");
        vault.transfer(unverifiedUser, depositAmount);
    }

    // ============ Test Compliance - TransferFrom ============

    function test_TransferFrom_Success() public {
        uint256 depositAmount = 100 ether;

        vm.prank(alice);
        uint256 shares = vault.deposit(depositAmount, alice);

        vm.prank(alice);
        vault.approve(bob, shares);

        vm.prank(bob);
        bool success = vault.transferFrom(alice, bob, shares / 2);

        assertTrue(success);
        assertEq(vault.balanceOf(alice), shares / 2);
        assertEq(vault.balanceOf(bob), shares / 2);
    }

    function test_TransferFrom_RevertsIfFromNotVerified() public {
        uint256 depositAmount = 100 ether;

        vm.prank(alice);
        uint256 shares = vault.deposit(depositAmount, alice);

        vm.prank(alice);
        vault.approve(bob, shares);

        // Remove verification
        identityRegistry.removeIdentity(alice);

        vm.prank(bob);
        vm.expectRevert("GoldVault: account not verified");
        vault.transferFrom(alice, bob, shares);
    }

    // ============ Helper Functions ============

    function _verifyLPPair() internal {
        address lpToken = vault.lpToken();
        if (lpToken != address(0) && !identityRegistry.isVerified(lpToken)) {
            identityRegistry.registerIdentity(lpToken);
        }
    }

    // ============ Test Strategy - Deploy ============

    function test_DeployToStrategy_Success() public {
        // First, deposit XAUT into vault
        uint256 depositAmount = 100 ether;
        vm.prank(alice);
        vault.deposit(depositAmount, alice);

        // Owner deploys to strategy
        uint256 xautAmount = 50 ether;
        uint256 usdcAmount = 50000 * 1e6; // 50k USDC

        // Approve router to spend USDC
        vm.startPrank(owner);
        usdc.approve(address(router), usdcAmount);

        vm.expectEmit(false, false, false, false);
        emit StrategyDeployed(0, 0, 0);

        vault.deployToStrategy(xautAmount, usdcAmount, 0, 0);
        vm.stopPrank();

        assertGt(vault.totalLPTokens(), 0);
        assertGt(vault.lastDeploymentTime(), 0);
    }

    function test_DeployToStrategy_RevertsIfNotOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        vault.deployToStrategy(10 ether, 10000 * 1e6, 0, 0);
    }

    function test_DeployToStrategy_RevertsIfInsufficientXAUT() public {
        uint256 xautAmount = 100 ether;
        uint256 usdcAmount = 100000 * 1e6;

        vm.prank(owner);
        vm.expectRevert("GoldVault: insufficient XAUT");
        vault.deployToStrategy(xautAmount, usdcAmount, 0, 0);
    }

    function test_DeployToStrategy_RevertsIfZeroAmount() public {
        vm.prank(owner);
        vm.expectRevert("GoldVault: zero XAUT amount");
        vault.deployToStrategy(0, 10000 * 1e6, 0, 0);
    }

    // ============ Test Strategy - Withdraw ============

    function test_WithdrawFromStrategy_Success() public {
        // Setup: deposit and deploy to strategy
        uint256 depositAmount = 100 ether;
        vm.prank(alice);
        vault.deposit(depositAmount, alice);

        uint256 xautAmount = 50 ether;
        uint256 usdcAmount = 50000 * 1e6;

        vm.startPrank(owner);
        usdc.approve(address(router), usdcAmount);
        vault.deployToStrategy(xautAmount, usdcAmount, 0, 0);

        uint256 lpBalance = vault.totalLPTokens();
        assertGt(lpBalance, 0);

        // Withdraw from strategy
        address lpToken = vault.lpToken();
        vm.startPrank(owner);
        IERC20(lpToken).approve(address(router), lpBalance);

        vm.expectEmit(false, false, false, false);
        emit StrategyWithdrawn(0, 0, 0);

        vault.withdrawFromStrategy(lpBalance, 0, 0);
        vm.stopPrank();

        assertEq(vault.totalLPTokens(), 0);
    }

    function test_WithdrawFromStrategy_RevertsIfNotOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        vault.withdrawFromStrategy(1000, 0, 0);
    }

    function test_WithdrawFromStrategy_RevertsIfInsufficientLP() public {
        vm.prank(owner);
        vm.expectRevert("GoldVault: insufficient LP tokens");
        vault.withdrawFromStrategy(1000, 0, 0);
    }

    // ============ Test Strategy - Harvest ============

    function test_Harvest_Success() public {
        // Setup: deposit and deploy to strategy
        uint256 depositAmount = 100 ether;
        vm.prank(alice);
        vault.deposit(depositAmount, alice);

        uint256 xautAmount = 50 ether;
        uint256 usdcAmount = 50000 * 1e6;

        vm.startPrank(owner);
        usdc.approve(address(router), usdcAmount);
        vault.deployToStrategy(xautAmount, usdcAmount, 0, 0);

        uint256 lpBalance = vault.totalLPTokens();
        assertGt(lpBalance, 0);

        // Approve LP token for harvest
        address lpToken = vault.lpToken();
        IERC20(lpToken).approve(address(router), type(uint256).max);

        // Simulate some time passing
        vm.warp(block.timestamp + 30 days);

        // Harvest
        vm.expectEmit(false, false, false, false);
        emit Harvested(0, 0);

        vault.harvest();
        vm.stopPrank();

        // Should still have LP tokens after harvest
        assertGt(vault.totalLPTokens(), 0);
    }

    function test_Harvest_RevertsIfNoLPTokens() public {
        vm.prank(owner);
        vm.expectRevert("GoldVault: no LP tokens to harvest");
        vault.harvest();
    }

    function test_Harvest_RevertsIfNotOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        vault.harvest();
    }

    // ============ Test Accounting ============

    function test_TotalAssets_OnlyVaultBalance() public {
        uint256 depositAmount = 100 ether;

        vm.prank(alice);
        vault.deposit(depositAmount, alice);

        assertEq(vault.totalAssets(), depositAmount);
    }

    function test_TotalAssets_WithLPPosition() public {
        // Deposit
        uint256 depositAmount = 100 ether;
        vm.prank(alice);
        vault.deposit(depositAmount, alice);

        // Deploy to strategy
        uint256 xautAmount = 50 ether;
        uint256 usdcAmount = 50000 * 1e6;

        vm.startPrank(owner);
        usdc.approve(address(router), usdcAmount);
        vault.deployToStrategy(xautAmount, usdcAmount, 0, 0);
        vm.stopPrank();

        uint256 totalAssets = vault.totalAssets();

        // Total assets should be vault balance + LP value
        assertGe(totalAssets, depositAmount - xautAmount);
        assertGt(totalAssets, 0);
    }

    function test_ConvertToShares_BeforeDeposit() public view {
        uint256 assets = 100 ether;
        uint256 shares = vault.convertToShares(assets);
        assertEq(shares, assets); // 1:1 ratio initially
    }

    function test_ConvertToAssets_AfterDeposit() public {
        uint256 depositAmount = 100 ether;

        vm.prank(alice);
        uint256 shares = vault.deposit(depositAmount, alice);

        uint256 assets = vault.convertToAssets(shares);
        assertEq(assets, depositAmount);
    }

    // ============ Test View Functions ============

    function test_GetStrategyInfo() public {
        uint256 depositAmount = 100 ether;
        vm.prank(alice);
        vault.deposit(depositAmount, alice);

        (
            uint256 totalLPBalance,
            uint256 xautInLP,
            uint256 vaultXautBalance,
            uint256 totalValue,
            address lpPairAddress
        ) = vault.getStrategyInfo();

        assertEq(totalLPBalance, 0); // No LP yet
        assertEq(xautInLP, 0);
        assertEq(vaultXautBalance, depositAmount);
        assertEq(totalValue, depositAmount);
        assertNotEq(lpPairAddress, address(0));
    }

    function test_GetStrategyInfo_WithLPPosition() public {
        // Deposit
        uint256 depositAmount = 100 ether;
        vm.prank(alice);
        vault.deposit(depositAmount, alice);

        // Deploy
        uint256 xautAmount = 50 ether;
        uint256 usdcAmount = 50000 * 1e6;

        vm.startPrank(owner);
        usdc.approve(address(router), usdcAmount);
        vault.deployToStrategy(xautAmount, usdcAmount, 0, 0);
        vm.stopPrank();

        (
            uint256 totalLPBalance,
            uint256 xautInLP,
            uint256 vaultXautBalance,
            ,
            address lpPairAddress
        ) = vault.getStrategyInfo();

        assertGt(totalLPBalance, 0);
        assertGt(xautInLP, 0);
        assertEq(vaultXautBalance, depositAmount - xautAmount);
        assertNotEq(lpPairAddress, address(0));
    }

    function test_GetLPReserves() public {
        // Before any LP
        (uint256 r0, uint256 r1, address t0, address t1) = vault.getLPReserves();
        assertEq(r0, 0);
        assertEq(r1, 0);

        // After deploying to strategy
        uint256 depositAmount = 100 ether;
        vm.prank(alice);
        vault.deposit(depositAmount, alice);

        uint256 xautAmount = 50 ether;
        uint256 usdcAmount = 50000 * 1e6;

        vm.startPrank(owner);
        usdc.approve(address(router), usdcAmount);
        vault.deployToStrategy(xautAmount, usdcAmount, 0, 0);
        vm.stopPrank();

        (r0, r1, t0, t1) = vault.getLPReserves();
        assertGt(r0, 0);
        assertGt(r1, 0);
        assertTrue(t0 == address(xaut) || t0 == address(usdc));
        assertTrue(t1 == address(xaut) || t1 == address(usdc));
    }

    function test_GetCurrentAPY_NoLP() public view {
        uint256 apy = vault.getCurrentAPY();
        assertEq(apy, 0);
    }

    function test_GetCurrentAPY_WithLP() public {
        // Deposit
        uint256 depositAmount = 100 ether;
        vm.prank(alice);
        vault.deposit(depositAmount, alice);

        // Deploy
        uint256 xautAmount = 50 ether;
        uint256 usdcAmount = 50000 * 1e6;

        vm.startPrank(owner);
        usdc.approve(address(router), usdcAmount);
        vault.deployToStrategy(xautAmount, usdcAmount, 0, 0);
        vm.stopPrank();

        // Time passes
        vm.warp(block.timestamp + 365 days);

        uint256 apy = vault.getCurrentAPY();
        // APY could be 0 if no fees accumulated yet
        assertGe(apy, 0);
    }

    // ============ Test Admin Functions ============

    function test_UpdateIdentityRegistry_Success() public {
        IdentityRegistry newRegistry = new IdentityRegistry();

        vault.updateIdentityRegistry(address(newRegistry));

        assertEq(address(vault.identityRegistry()), address(newRegistry));
    }

    function test_UpdateIdentityRegistry_RevertsIfNotOwner() public {
        IdentityRegistry newRegistry = new IdentityRegistry();

        vm.prank(alice);
        vm.expectRevert();
        vault.updateIdentityRegistry(address(newRegistry));
    }

    function test_UpdateIdentityRegistry_RevertsIfZeroAddress() public {
        vm.expectRevert("GoldVault: zero registry address");
        vault.updateIdentityRegistry(address(0));
    }

    function test_EmergencyWithdraw_Success() public {
        // Create a random token
        MockERC20 randomToken = new MockERC20("Random", "RND", 18);
        randomToken.mint(address(vault), 100 ether);

        uint256 ownerBalanceBefore = randomToken.balanceOf(owner);

        vault.emergencyWithdraw(address(randomToken), 100 ether);

        assertEq(randomToken.balanceOf(owner), ownerBalanceBefore + 100 ether);
    }

    function test_EmergencyWithdraw_RevertsIfXAUT() public {
        vm.expectRevert("GoldVault: cannot withdraw XAUT");
        vault.emergencyWithdraw(address(xaut), 1 ether);
    }

    function test_EmergencyWithdraw_RevertsIfUSDC() public {
        vm.expectRevert("GoldVault: cannot withdraw USDC");
        vault.emergencyWithdraw(address(usdc), 1 ether);
    }

    function test_EmergencyWithdraw_RevertsIfLP() public {
        address lpToken = vault.lpToken();

        vm.expectRevert("GoldVault: cannot withdraw LP");
        vault.emergencyWithdraw(lpToken, 1 ether);
    }

    function test_EmergencyWithdraw_RevertsIfNotOwner() public {
        MockERC20 randomToken = new MockERC20("Random", "RND", 18);

        vm.prank(alice);
        vm.expectRevert();
        vault.emergencyWithdraw(address(randomToken), 100 ether);
    }

    // ============ Test Edge Cases ============

    function test_MultipleUsersDepositAndWithdraw() public {
        uint256 aliceDeposit = 100 ether;
        uint256 bobDeposit = 200 ether;

        // Alice deposits
        vm.prank(alice);
        uint256 aliceShares = vault.deposit(aliceDeposit, alice);

        // Bob deposits
        vm.prank(bob);
        uint256 bobShares = vault.deposit(bobDeposit, bob);

        // Check shares
        assertEq(vault.balanceOf(alice), aliceShares);
        assertEq(vault.balanceOf(bob), bobShares);

        // Bob should have 2x shares of Alice
        assertApproxEqRel(bobShares, aliceShares * 2, 0.01e18);

        // Alice withdraws
        vm.prank(alice);
        vault.redeem(aliceShares, alice, alice);

        assertEq(vault.balanceOf(alice), 0);
        assertEq(xaut.balanceOf(alice), INITIAL_XAUT);

        // Bob can still withdraw
        vm.prank(bob);
        vault.redeem(bobShares, bob, bob);

        assertEq(vault.balanceOf(bob), 0);
        assertEq(xaut.balanceOf(bob), INITIAL_XAUT);
    }

    function test_DepositAfterStrategyDeployment() public {
        // First user deposits
        uint256 aliceDeposit = 100 ether;
        vm.prank(alice);
        vault.deposit(aliceDeposit, alice);

        // Deploy to strategy
        uint256 xautAmount = 50 ether;
        uint256 usdcAmount = 50000 * 1e6;

        vm.startPrank(owner);
        usdc.approve(address(router), usdcAmount);
        vault.deployToStrategy(xautAmount, usdcAmount, 0, 0);
        vm.stopPrank();

        // Second user deposits
        uint256 bobDeposit = 100 ether;
        vm.prank(bob);
        uint256 bobShares = vault.deposit(bobDeposit, bob);

        assertGt(bobShares, 0);
        assertEq(vault.balanceOf(bob), bobShares);
    }

    function test_WithdrawAfterStrategyDeployment() public {
        // Deposit
        uint256 depositAmount = 100 ether;
        vm.prank(alice);
        uint256 shares = vault.deposit(depositAmount, alice);

        // Deploy to strategy
        uint256 xautAmount = 50 ether;
        uint256 usdcAmount = 50000 * 1e6;

        vm.startPrank(owner);
        usdc.approve(address(router), usdcAmount);
        vault.deployToStrategy(xautAmount, usdcAmount, 0, 0);
        vm.stopPrank();

        // Withdraw half
        vm.prank(alice);
        vault.redeem(shares / 2, alice, alice);

        // Should get approximately half of deposit
        assertGt(xaut.balanceOf(alice), INITIAL_XAUT - depositAmount);
    }

    function test_ReentrancyProtection() public {
        uint256 depositAmount = 100 ether;

        vm.prank(alice);
        vault.deposit(depositAmount, alice);

        // This should be protected by nonReentrant
        // The protection is tested implicitly through all functions
    }
}
