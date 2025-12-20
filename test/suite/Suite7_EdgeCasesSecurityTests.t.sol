// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Suite7_EdgeCasesSecurityTests
 * @notice Edge cases and security tests for AuRoom Protocol
 * @dev Tests error handling, access control, and security aspects
 */

interface ISwapRouter {
    function swapIDRXtoXAUT(uint256 amountIn, uint256 amountOutMin, address to, uint256 deadline) external returns (uint256);
    function swapXAUTtoIDRX(uint256 amountIn, uint256 amountOutMin, address to, uint256 deadline) external returns (uint256);
    function getQuoteIDRXtoXAUT(uint256 amountIn) external view returns (uint256);
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
    function isAdmin(address user) external view returns (bool);
}

interface IMockToken is IERC20 {
    function mint(address to, uint256 amount) external;
}

interface IXAUT is IERC20 {
    function mint(address to, uint256 amount) external;
}

contract Suite7_EdgeCasesSecurityTests is Test {
    // Constants - Contract Addresses
    address constant MOCK_IDRX = 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05;
    address constant XAUT = 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78;
    address constant IDENTITY_REGISTRY = 0x620870d419F6aFca8AFed5B516619aa50900cadc;
    address constant SWAP_ROUTER = 0xF948Dd812E7fA072367848ec3D198cc61488b1b9; // Redeployed with Router V2
    address constant GOLD_VAULT = 0xd92cE2F13509840B1203D35218227559E64fbED0; // Redeployed with Router V2
    address constant DEPLOYER = 0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1;
    
    // Network Configuration
    uint256 constant MANTLE_SEPOLIA_CHAIN_ID = 5003;
    
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
        // Fork Mantle Sepolia
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
        
        // Log setup info
        console.log("=== Suite 7: Edge Cases & Security Test Setup ===");
        console.log("Chain ID:", block.chainid);
        console.log("Block Number:", block.number);
    }
    
    // ============================================
    // ZERO AMOUNT EDGE CASES
    // ============================================
    
    function test_Swap_ZeroAmount_Reverts() public {
        console.log("=== Test: Swap Zero Amount Reverts ===");
        
        vm.prank(verifiedUser);
        vm.expectRevert();
        swapRouter.swapIDRXtoXAUT(0, 0, verifiedUser, block.timestamp + 300);
        
        console.log("Zero amount swap correctly reverted");
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
    
    function test_Withdraw_ZeroAmount_ReturnsZero() public {
        console.log("=== Test: Withdraw Zero Amount Returns Zero ===");
        
        // First deposit something
        vm.prank(verifiedUser);
        vault.deposit(10 * 10**6, verifiedUser);
        
        vm.prank(verifiedUser);
        uint256 shares = vault.withdraw(0, verifiedUser, verifiedUser);
        
        assertEq(shares, 0, "Zero withdraw should return zero shares");
        console.log("Zero withdraw returned zero shares (allowed)");
        console.log("=== PASSED ===");
    }
    
    // ============================================
    // INSUFFICIENT BALANCE EDGE CASES
    // ============================================
    
    function test_Swap_InsufficientBalance_Reverts() public {
        console.log("=== Test: Swap Insufficient Balance Reverts ===");
        
        uint256 balance = idrx.balanceOf(verifiedUser);
        uint256 tooMuch = balance + 1000 * 10**6;
        uint256 quote = swapRouter.getQuoteIDRXtoXAUT(tooMuch);
        
        console.log("User balance:", balance);
        console.log("Trying to swap:", tooMuch);
        
        vm.prank(verifiedUser);
        vm.expectRevert();
        swapRouter.swapIDRXtoXAUT(tooMuch, quote * 95 / 100, verifiedUser, block.timestamp + 300);
        
        console.log("Insufficient balance swap correctly reverted");
        console.log("=== PASSED ===");
    }
    
    function test_Withdraw_InsufficientShares_Reverts() public {
        console.log("=== Test: Withdraw Insufficient Shares Reverts ===");
        
        // Deposit small amount
        vm.prank(verifiedUser);
        vault.deposit(10 * 10**6, verifiedUser);
        
        uint256 tooMuch = 100 * 10**6; // Try to withdraw 10x more
        
        console.log("Deposited: 10 XAUT");
        console.log("Trying to withdraw:", tooMuch);
        
        vm.prank(verifiedUser);
        vm.expectRevert();
        vault.withdraw(tooMuch, verifiedUser, verifiedUser);
        
        console.log("Insufficient shares withdraw correctly reverted");
        console.log("=== PASSED ===");
    }
    
    function test_Transfer_InsufficientBalance_Reverts() public {
        console.log("=== Test: Transfer Insufficient Balance Reverts ===");
        
        uint256 balance = xaut.balanceOf(verifiedUser);
        uint256 tooMuch = balance + 1000 * 10**6;
        
        // Create another verified user
        address recipient = makeAddr("recipient");
        vm.prank(DEPLOYER);
        identityRegistry.registerIdentity(recipient);
        
        console.log("User balance:", balance);
        console.log("Trying to transfer:", tooMuch);
        
        vm.prank(verifiedUser);
        vm.expectRevert();
        xaut.transfer(recipient, tooMuch);
        
        console.log("Insufficient balance transfer correctly reverted");
        console.log("=== PASSED ===");
    }
    
    // ============================================
    // APPROVAL EDGE CASES
    // ============================================
    
    function test_Swap_WithoutApproval_Reverts() public {
        console.log("=== Test: Swap Without Approval Reverts ===");
        
        // Create new user without approval
        address newUser = makeAddr("newUser");
        vm.startPrank(DEPLOYER);
        identityRegistry.registerIdentity(newUser);
        idrx.mint(newUser, 10000 * 10**6);
        vm.stopPrank();
        
        // Try to swap without approval
        uint256 amount = 1000 * 10**6;
        uint256 quote = swapRouter.getQuoteIDRXtoXAUT(amount);
        
        console.log("User has IDRX but no approval");
        
        vm.prank(newUser);
        vm.expectRevert();
        swapRouter.swapIDRXtoXAUT(amount, quote * 95 / 100, newUser, block.timestamp + 300);
        
        console.log("Swap without approval correctly reverted");
        console.log("=== PASSED ===");
    }
    
    function test_Deposit_WithoutApproval_Reverts() public {
        console.log("=== Test: Deposit Without Approval Reverts ===");
        
        // Create new user without approval
        address newUser = makeAddr("newUser2");
        vm.startPrank(DEPLOYER);
        identityRegistry.registerIdentity(newUser);
        xaut.mint(newUser, 100 * 10**6);
        vm.stopPrank();
        
        console.log("User has XAUT but no approval");
        
        vm.prank(newUser);
        vm.expectRevert();
        vault.deposit(10 * 10**6, newUser);
        
        console.log("Deposit without approval correctly reverted");
        console.log("=== PASSED ===");
    }
    
    function test_TransferFrom_WithoutApproval_Reverts() public {
        console.log("=== Test: TransferFrom Without Approval Reverts ===");
        
        address recipient = makeAddr("recipient2");
        vm.prank(DEPLOYER);
        identityRegistry.registerIdentity(recipient);
        
        console.log("Attacker tries transferFrom without approval");
        
        vm.prank(attacker);
        vm.expectRevert();
        xaut.transferFrom(verifiedUser, recipient, 10 * 10**6);
        
        console.log("TransferFrom without approval correctly reverted");
        console.log("=== PASSED ===");
    }
    
    // ============================================
    // ACCESS CONTROL TESTS
    // ============================================
    
    function test_IdentityRegistry_NonAdmin_CannotRegister() public {
        console.log("=== Test: Non-Admin Cannot Register ===");
        
        address newUser = makeAddr("newUser3");
        
        console.log("Attacker is admin:", identityRegistry.isAdmin(attacker));
        
        vm.prank(attacker);
        vm.expectRevert();
        identityRegistry.registerIdentity(newUser);
        
        console.log("Non-admin registration correctly reverted");
        console.log("=== PASSED ===");
    }
    
    function test_IdentityRegistry_NonOwner_CannotAddAdmin() public {
        console.log("=== Test: Non-Owner Cannot Add Admin ===");
        
        console.log("Attacker tries to add themselves as admin");
        
        vm.prank(attacker);
        vm.expectRevert();
        identityRegistry.addAdmin(attacker);
        
        console.log("Non-owner addAdmin correctly reverted");
        console.log("=== PASSED ===");
    }
    
    function test_XAUT_NonOwner_CannotMint() public {
        console.log("=== Test: Non-Owner Cannot Mint XAUT ===");
        
        console.log("Attacker tries to mint XAUT");
        
        vm.prank(attacker);
        vm.expectRevert();
        xaut.mint(attacker, 1000000 * 10**6);
        
        console.log("Non-owner mint correctly reverted");
        console.log("=== PASSED ===");
    }
    
    // ============================================
    // DEADLINE & TIMING TESTS
    // ============================================
    
    function test_Swap_ExpiredDeadline_Reverts() public {
        console.log("=== Test: Expired Deadline Reverts ===");
        
        uint256 pastDeadline = block.timestamp - 1;
        uint256 amount = 1000 * 10**6;
        uint256 quote = swapRouter.getQuoteIDRXtoXAUT(amount);
        
        console.log("Current time:", block.timestamp);
        console.log("Deadline:", pastDeadline);
        
        vm.prank(verifiedUser);
        vm.expectRevert();
        swapRouter.swapIDRXtoXAUT(amount, quote * 95 / 100, verifiedUser, pastDeadline);
        
        console.log("Expired deadline correctly reverted");
        console.log("=== PASSED ===");
    }
    
    function test_Swap_ExactDeadline_Success() public {
        console.log("=== Test: Exact Deadline Success ===");
        
        uint256 exactDeadline = block.timestamp;
        uint256 amount = 1000 * 10**6;
        uint256 quote = swapRouter.getQuoteIDRXtoXAUT(amount);
        
        console.log("Current time:", block.timestamp);
        console.log("Deadline:", exactDeadline);
        
        vm.prank(verifiedUser);
        uint256 output = swapRouter.swapIDRXtoXAUT(amount, quote * 95 / 100, verifiedUser, exactDeadline);
        
        assertGt(output, 0, "Should succeed at exact deadline");
        console.log("Swap at exact deadline succeeded");
        console.log("=== PASSED ===");
    }
    
    // ============================================
    // IDENTITY REMOVAL EDGE CASE
    // ============================================
    
    function test_IdentityRemoved_CannotTransferXAUT() public {
        console.log("=== Test: Identity Removed Cannot Transfer XAUT ===");
        
        // Create and verify a user
        address tempUser = makeAddr("tempUser");
        vm.startPrank(DEPLOYER);
        identityRegistry.registerIdentity(tempUser);
        xaut.mint(tempUser, 100 * 10**6);
        vm.stopPrank();
        
        console.log("User verified:", identityRegistry.isVerified(tempUser));
        
        // Remove identity
        vm.prank(DEPLOYER);
        identityRegistry.removeIdentity(tempUser);
        
        console.log("User verified after removal:", identityRegistry.isVerified(tempUser));
        
        // Create recipient
        address recipient = makeAddr("recipient3");
        vm.prank(DEPLOYER);
        identityRegistry.registerIdentity(recipient);
        
        // Try to transfer - should revert
        vm.prank(tempUser);
        vm.expectRevert();
        xaut.transfer(recipient, 10 * 10**6);
        
        console.log("Transfer from removed identity correctly reverted");
        console.log("=== PASSED ===");
    }
    
    function test_IdentityRemoved_CannotWithdrawVault() public {
        console.log("=== Test: Identity Removed Cannot Withdraw from Vault ===");
        
        // Create and verify a user
        address tempUser = makeAddr("tempUser2");
        vm.startPrank(DEPLOYER);
        identityRegistry.registerIdentity(tempUser);
        xaut.mint(tempUser, 100 * 10**6);
        vm.stopPrank();
        
        // Deposit to vault
        vm.startPrank(tempUser);
        xaut.approve(GOLD_VAULT, type(uint256).max);
        uint256 shares = vault.deposit(50 * 10**6, tempUser);
        vm.stopPrank();
        
        console.log("Deposited 50 XAUT, received", shares, "shares");
        
        // Remove identity
        vm.prank(DEPLOYER);
        identityRegistry.removeIdentity(tempUser);
        
        console.log("User verified after removal:", identityRegistry.isVerified(tempUser));
        
        // Try to withdraw - should revert (vault requires verification)
        vm.prank(tempUser);
        vm.expectRevert();
        vault.withdraw(25 * 10**6, tempUser, tempUser);
        
        console.log("Withdrawal correctly reverted for removed identity");
        console.log("User cannot withdraw after identity removal (security feature)");
        console.log("=== PASSED ===");
    }
}
