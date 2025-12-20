// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Suite5_GoldVaultTests
 * @notice Test suite for GoldVault (ERC-4626) contract on AuRoom Protocol
 * @dev Tests vault operations: deposit, withdraw, redeem, and compliance
 */

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

contract Suite5_GoldVaultTests is Test {
    // Constants - Contract Addresses
    address constant GOLD_VAULT = 0xd92cE2F13509840B1203D35218227559E64fbED0; // Redeployed with Router V2
    address constant XAUT = 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78;
    address constant IDENTITY_REGISTRY = 0x620870d419F6aFca8AFed5B516619aa50900cadc;
    address constant DEPLOYER = 0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1;
    
    // Network Configuration
    uint256 constant MANTLE_SEPOLIA_CHAIN_ID = 5003;
    
    // Contracts
    IGoldVault vault;
    IXAUT xaut;
    IIdentityRegistry identityRegistry;
    
    // Test users
    address verifiedUser;
    address verifiedUser2;
    address unverifiedUser;
    
    // Test amounts
    uint256 constant DEPOSIT_AMOUNT = 10 * 10**6; // 10 XAUT (6 decimals)
    uint256 constant LARGE_DEPOSIT = 100 * 10**6; // 100 XAUT
    
    function setUp() public {
        // Fork Mantle Sepolia
        vm.createSelectFork("https://rpc.sepolia.mantle.xyz");
        
        // Initialize contracts
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
        identityRegistry.registerIdentity(GOLD_VAULT); // Vault needs to be verified
        
        // Mint XAUT to verified user
        xaut.mint(verifiedUser, 1000 * 10**6); // 1000 XAUT
        vm.stopPrank();
        
        // Approve vault
        vm.prank(verifiedUser);
        xaut.approve(GOLD_VAULT, type(uint256).max);
        
        // Log setup info
        console.log("=== Suite 5: GoldVault Test Setup ===");
        console.log("Chain ID:", block.chainid);
        console.log("Block Number:", block.number);
        console.log("GoldVault:", GOLD_VAULT);
        console.log("Verified User:", verifiedUser);
        console.log("Verified User Status:", identityRegistry.isVerified(verifiedUser));
        console.log("Verified User2:", verifiedUser2);
        console.log("Unverified User:", unverifiedUser);
    }
    
    // ============================================
    // VAULT INFO TESTS
    // ============================================
    
    function test_Vault_Name() public {
        console.log("=== Test: Vault Name ===");
        
        string memory name = vault.name();
        
        assertEq(name, "Gold Vault Token", "Name should be Gold Vault Token");
        console.log("Name:", name);
        console.log("=== PASSED ===");
    }
    
    function test_Vault_Symbol() public {
        console.log("=== Test: Vault Symbol ===");
        
        string memory symbol = vault.symbol();
        
        assertEq(symbol, "gXAUT", "Symbol should be gXAUT");
        console.log("Symbol:", symbol);
        console.log("=== PASSED ===");
    }
    
    function test_Vault_Decimals() public {
        console.log("=== Test: Vault Decimals ===");
        
        uint8 decimals = vault.decimals();
        
        assertEq(decimals, 6, "Decimals should be 6");
        console.log("Decimals:", decimals);
        console.log("=== PASSED ===");
    }
    
    function test_Vault_Asset() public {
        console.log("=== Test: Vault Asset ===");
        
        address asset = vault.asset();
        
        assertEq(asset, XAUT, "Asset should be XAUT");
        console.log("Asset:", asset);
        console.log("Expected:", XAUT);
        console.log("=== PASSED ===");
    }
    
    function test_Vault_IdentityRegistry() public {
        console.log("=== Test: Vault IdentityRegistry ===");
        
        address registry = vault.identityRegistry();
        
        assertEq(registry, IDENTITY_REGISTRY, "IdentityRegistry should match");
        console.log("Registry:", registry);
        console.log("Expected:", IDENTITY_REGISTRY);
        console.log("=== PASSED ===");
    }
    
    // ============================================
    // DEPOSIT TESTS
    // ============================================
    
    function test_Deposit_Success() public {
        console.log("=== Test: Deposit Success ===");
        
        uint256 assets = DEPOSIT_AMOUNT;
        
        vm.prank(verifiedUser);
        uint256 shares = vault.deposit(assets, verifiedUser);
        
        assertGt(shares, 0, "Should receive shares");
        console.log("Assets Deposited:", assets);
        console.log("Shares Received:", shares);
        console.log("=== PASSED ===");
    }
    
    function test_Deposit_ReceivesShares() public {
        console.log("=== Test: Deposit Receives Shares ===");
        
        uint256 assets = DEPOSIT_AMOUNT;
        uint256 sharesBefore = vault.balanceOf(verifiedUser);
        
        console.log("Shares Before:", sharesBefore);
        
        vm.prank(verifiedUser);
        uint256 sharesReceived = vault.deposit(assets, verifiedUser);
        
        uint256 sharesAfter = vault.balanceOf(verifiedUser);
        
        console.log("Shares Received:", sharesReceived);
        console.log("Shares After:", sharesAfter);
        
        assertEq(sharesAfter, sharesBefore + sharesReceived, "Shares should increase by amount received");
        console.log("=== PASSED ===");
    }
    
    function test_Deposit_TotalAssetsIncreases() public {
        console.log("=== Test: Deposit Total Assets Increases ===");
        
        uint256 assets = DEPOSIT_AMOUNT;
        uint256 totalAssetsBefore = vault.totalAssets();
        
        console.log("Total Assets Before:", totalAssetsBefore);
        
        vm.prank(verifiedUser);
        vault.deposit(assets, verifiedUser);
        
        uint256 totalAssetsAfter = vault.totalAssets();
        
        console.log("Total Assets After:", totalAssetsAfter);
        
        assertEq(totalAssetsAfter, totalAssetsBefore + assets, "Total assets should increase by deposit amount");
        console.log("=== PASSED ===");
    }
    

    function test_Deposit_ZeroAmount_ReturnsZero() public {
        console.log("=== Test: Deposit Zero Amount Returns Zero ===");
        
        vm.prank(verifiedUser);
        uint256 shares = vault.deposit(0, verifiedUser);
        
        assertEq(shares, 0, "Zero deposit should return zero shares");
        console.log("Zero deposit returned zero shares (allowed)");
        console.log("=== PASSED ===");
    }
    
    // ============================================
    // WITHDRAW TESTS
    // ============================================
    
    function test_Withdraw_Success() public {
        console.log("=== Test: Withdraw Success ===");
        
        // First deposit
        vm.prank(verifiedUser);
        vault.deposit(LARGE_DEPOSIT, verifiedUser);
        
        uint256 withdrawAmount = DEPOSIT_AMOUNT;
        
        vm.prank(verifiedUser);
        uint256 sharesBurned = vault.withdraw(withdrawAmount, verifiedUser, verifiedUser);
        
        assertGt(sharesBurned, 0, "Should burn shares");
        console.log("Assets Withdrawn:", withdrawAmount);
        console.log("Shares Burned:", sharesBurned);
        console.log("=== PASSED ===");
    }
    
    function test_Withdraw_ReceivesAssets() public {
        console.log("=== Test: Withdraw Receives Assets ===");
        
        // First deposit
        vm.prank(verifiedUser);
        vault.deposit(LARGE_DEPOSIT, verifiedUser);
        
        uint256 withdrawAmount = DEPOSIT_AMOUNT;
        uint256 xautBefore = xaut.balanceOf(verifiedUser);
        
        console.log("XAUT Before:", xautBefore);
        
        vm.prank(verifiedUser);
        vault.withdraw(withdrawAmount, verifiedUser, verifiedUser);
        
        uint256 xautAfter = xaut.balanceOf(verifiedUser);
        
        console.log("XAUT After:", xautAfter);
        
        assertEq(xautAfter, xautBefore + withdrawAmount, "XAUT should increase by withdraw amount");
        console.log("=== PASSED ===");
    }
    
    function test_Withdraw_SharesBurned() public {
        console.log("=== Test: Withdraw Shares Burned ===");
        
        // First deposit
        vm.prank(verifiedUser);
        vault.deposit(LARGE_DEPOSIT, verifiedUser);
        
        uint256 withdrawAmount = DEPOSIT_AMOUNT;
        uint256 sharesBefore = vault.balanceOf(verifiedUser);
        
        console.log("Shares Before:", sharesBefore);
        
        vm.prank(verifiedUser);
        uint256 sharesBurned = vault.withdraw(withdrawAmount, verifiedUser, verifiedUser);
        
        uint256 sharesAfter = vault.balanceOf(verifiedUser);
        
        console.log("Shares Burned:", sharesBurned);
        console.log("Shares After:", sharesAfter);
        
        assertEq(sharesAfter, sharesBefore - sharesBurned, "Shares should decrease by burned amount");
        console.log("=== PASSED ===");
    }
    
    function test_Withdraw_TotalAssetsDecreases() public {
        console.log("=== Test: Withdraw Total Assets Decreases ===");
        
        // First deposit
        vm.prank(verifiedUser);
        vault.deposit(LARGE_DEPOSIT, verifiedUser);
        
        uint256 withdrawAmount = DEPOSIT_AMOUNT;
        uint256 totalAssetsBefore = vault.totalAssets();
        
        console.log("Total Assets Before:", totalAssetsBefore);
        
        vm.prank(verifiedUser);
        vault.withdraw(withdrawAmount, verifiedUser, verifiedUser);
        
        uint256 totalAssetsAfter = vault.totalAssets();
        
        console.log("Total Assets After:", totalAssetsAfter);
        
        assertEq(totalAssetsAfter, totalAssetsBefore - withdrawAmount, "Total assets should decrease");
        console.log("=== PASSED ===");
    }
    
    function test_Withdraw_MoreThanBalance_Reverts() public {
        console.log("=== Test: Withdraw More Than Balance Reverts ===");
        
        // Deposit small amount
        vm.prank(verifiedUser);
        vault.deposit(DEPOSIT_AMOUNT, verifiedUser);
        
        // Try to withdraw more
        uint256 tooMuch = DEPOSIT_AMOUNT * 2;
        
        console.log("Deposited:", DEPOSIT_AMOUNT);
        console.log("Trying to withdraw:", tooMuch);
        
        vm.prank(verifiedUser);
        vm.expectRevert();
        vault.withdraw(tooMuch, verifiedUser, verifiedUser);
        
        console.log("Withdraw correctly reverted");
        console.log("=== PASSED ===");
    }
    
    // ============================================
    // REDEEM TESTS
    // ============================================
    
    function test_Redeem_Success() public {
        console.log("=== Test: Redeem Success ===");
        
        // First deposit
        vm.prank(verifiedUser);
        uint256 shares = vault.deposit(LARGE_DEPOSIT, verifiedUser);
        
        uint256 redeemShares = shares / 2; // Redeem half
        
        vm.prank(verifiedUser);
        uint256 assetsReceived = vault.redeem(redeemShares, verifiedUser, verifiedUser);
        
        assertGt(assetsReceived, 0, "Should receive assets");
        console.log("Shares Redeemed:", redeemShares);
        console.log("Assets Received:", assetsReceived);
        console.log("=== PASSED ===");
    }
    
    function test_Redeem_ReceivesAssets() public {
        console.log("=== Test: Redeem Receives Assets ===");
        
        // First deposit
        vm.prank(verifiedUser);
        uint256 shares = vault.deposit(LARGE_DEPOSIT, verifiedUser);
        
        uint256 redeemShares = shares / 2;
        uint256 xautBefore = xaut.balanceOf(verifiedUser);
        
        console.log("XAUT Before:", xautBefore);
        
        vm.prank(verifiedUser);
        uint256 assetsReceived = vault.redeem(redeemShares, verifiedUser, verifiedUser);
        
        uint256 xautAfter = xaut.balanceOf(verifiedUser);
        
        console.log("Assets Received:", assetsReceived);
        console.log("XAUT After:", xautAfter);
        
        assertEq(xautAfter, xautBefore + assetsReceived, "XAUT should increase by assets received");
        console.log("=== PASSED ===");
    }
    
    function test_Redeem_SharesBurned() public {
        console.log("=== Test: Redeem Shares Burned ===");
        
        // First deposit
        vm.prank(verifiedUser);
        uint256 shares = vault.deposit(LARGE_DEPOSIT, verifiedUser);
        
        uint256 redeemShares = shares / 2;
        uint256 sharesBefore = vault.balanceOf(verifiedUser);
        
        console.log("Shares Before:", sharesBefore);
        console.log("Redeeming:", redeemShares);
        
        vm.prank(verifiedUser);
        vault.redeem(redeemShares, verifiedUser, verifiedUser);
        
        uint256 sharesAfter = vault.balanceOf(verifiedUser);
        
        console.log("Shares After:", sharesAfter);
        
        assertEq(sharesAfter, sharesBefore - redeemShares, "Shares should decrease by redeemed amount");
        console.log("=== PASSED ===");
    }
    
    // ============================================
    // SHARE CALCULATION TESTS
    // ============================================
    
    function test_ConvertToShares_Correct() public {
        console.log("=== Test: Convert To Shares Correct ===");
        
        uint256 assets = DEPOSIT_AMOUNT;
        uint256 expectedShares = vault.convertToShares(assets);
        
        console.log("Assets:", assets);
        console.log("Expected Shares:", expectedShares);
        
        assertGt(expectedShares, 0, "Should return shares");
        console.log("=== PASSED ===");
    }
    
    function test_ConvertToAssets_Correct() public {
        console.log("=== Test: Convert To Assets Correct ===");
        
        // First deposit to get shares
        vm.prank(verifiedUser);
        uint256 shares = vault.deposit(DEPOSIT_AMOUNT, verifiedUser);
        
        uint256 assets = vault.convertToAssets(shares);
        
        console.log("Shares:", shares);
        console.log("Assets:", assets);
        
        // Should be approximately equal (allowing for rounding)
        assertApproxEqAbs(assets, DEPOSIT_AMOUNT, 1, "Assets should match deposit amount");
        console.log("=== PASSED ===");
    }
    
    function test_PreviewDeposit_MatchesActual() public {
        console.log("=== Test: Preview Deposit Matches Actual ===");
        
        uint256 assets = DEPOSIT_AMOUNT;
        uint256 previewShares = vault.previewDeposit(assets);
        
        console.log("Preview Shares:", previewShares);
        
        vm.prank(verifiedUser);
        uint256 actualShares = vault.deposit(assets, verifiedUser);
        
        console.log("Actual Shares:", actualShares);
        
        assertEq(actualShares, previewShares, "Actual shares should match preview");
        console.log("=== PASSED ===");
    }
    
    function test_PreviewWithdraw_MatchesActual() public {
        console.log("=== Test: Preview Withdraw Matches Actual ===");
        
        // First deposit
        vm.prank(verifiedUser);
        vault.deposit(LARGE_DEPOSIT, verifiedUser);
        
        uint256 withdrawAmount = DEPOSIT_AMOUNT;
        uint256 previewShares = vault.previewWithdraw(withdrawAmount);
        
        console.log("Preview Shares:", previewShares);
        
        vm.prank(verifiedUser);
        uint256 actualShares = vault.withdraw(withdrawAmount, verifiedUser, verifiedUser);
        
        console.log("Actual Shares:", actualShares);
        
        assertEq(actualShares, previewShares, "Actual shares should match preview");
        console.log("=== PASSED ===");
    }
    
    function test_PreviewRedeem_MatchesActual() public {
        console.log("=== Test: Preview Redeem Matches Actual ===");
        
        // First deposit
        vm.prank(verifiedUser);
        uint256 shares = vault.deposit(LARGE_DEPOSIT, verifiedUser);
        
        uint256 redeemShares = shares / 2;
        uint256 previewAssets = vault.previewRedeem(redeemShares);
        
        console.log("Preview Assets:", previewAssets);
        
        vm.prank(verifiedUser);
        uint256 actualAssets = vault.redeem(redeemShares, verifiedUser, verifiedUser);
        
        console.log("Actual Assets:", actualAssets);
        
        assertEq(actualAssets, previewAssets, "Actual assets should match preview");
        console.log("=== PASSED ===");
    }
    
    // ============================================
    // gXAUT COMPLIANCE TESTS
    // ============================================
    
    function test_gXAUT_TransferToVerified_Success() public {
        console.log("=== Test: gXAUT Transfer To Verified Success ===");
        
        // First deposit to get gXAUT
        vm.prank(verifiedUser);
        uint256 shares = vault.deposit(DEPOSIT_AMOUNT, verifiedUser);
        
        console.log("Shares to transfer:", shares);
        console.log("From:", verifiedUser);
        console.log("To:", verifiedUser2);
        console.log("To Verified:", identityRegistry.isVerified(verifiedUser2));
        
        // Transfer to another verified user
        vm.prank(verifiedUser);
        bool success = vault.transfer(verifiedUser2, shares);
        
        assertTrue(success, "Transfer should succeed");
        assertEq(vault.balanceOf(verifiedUser2), shares, "Receiver should have shares");
        console.log("=== PASSED ===");
    }
    
    function test_gXAUT_TransferToUnverified_Reverts() public {
        console.log("=== Test: gXAUT Transfer To Unverified Reverts ===");
        
        // First deposit to get gXAUT
        vm.prank(verifiedUser);
        uint256 shares = vault.deposit(DEPOSIT_AMOUNT, verifiedUser);
        
        console.log("Unverified User:", unverifiedUser);
        console.log("Verified Status:", identityRegistry.isVerified(unverifiedUser));
        
        // Try to transfer to unverified user - should revert
        vm.prank(verifiedUser);
        vm.expectRevert();
        vault.transfer(unverifiedUser, shares);
        
        console.log("Transfer correctly reverted for unverified recipient");
        console.log("=== PASSED ===");
    }
}
