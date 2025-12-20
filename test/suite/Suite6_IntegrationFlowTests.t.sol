// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Suite6_IntegrationFlowTests
 * @notice Integration tests for complete user journeys on AuRoom Protocol
 * @dev Tests full flows: onboarding, swap+stake, withdraw+swap back, and full cycle
 */

interface ISwapRouter {
    function swapIDRXtoXAUT(uint256 amountIn, uint256 amountOutMin, address to, uint256 deadline) external returns (uint256);
    function swapXAUTtoIDRX(uint256 amountIn, uint256 amountOutMin, address to, uint256 deadline) external returns (uint256);
    function getQuoteIDRXtoXAUT(uint256 amountIn) external view returns (uint256);
    function getQuoteXAUTtoIDRX(uint256 amountIn) external view returns (uint256);
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

contract Suite6_IntegrationFlowTests is Test {
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
    IERC20 xaut;
    
    // Test users
    address ani;
    address budi;
    
    // Test amounts
    uint256 constant INITIAL_IDRX = 10_000_000 * 10**6; // 10M IDRX (6 decimals)
    uint256 constant SWAP_AMOUNT = 5_000_000 * 10**6; // 5M IDRX
    
    function setUp() public {
        // Fork Mantle Sepolia
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
        
        // Log setup info
        console.log("=== Suite 6: Integration Flow Test Setup ===");
        console.log("Chain ID:", block.chainid);
        console.log("Block Number:", block.number);
        console.log("Ani (verified):", ani);
        console.log("Budi (unverified):", budi);
    }
    
    // Helper: Log balances
    function _logBalances(address user, string memory label) internal view {
        console.log("--- Balances for", label, "---");
        console.log("IDRX:", idrx.balanceOf(user));
        console.log("XAUT:", xaut.balanceOf(user));
        console.log("gXAUT:", vault.balanceOf(user));
    }
    
    // ============================================
    // TEST 1: NEW USER ONBOARDING FLOW
    // ============================================
    
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
        uint256 testAmount = 1000 * 10**6;
        uint256 quote = swapRouter.getQuoteIDRXtoXAUT(testAmount);
        
        vm.startPrank(budi);
        idrx.approve(SWAP_ROUTER, type(uint256).max);
        vm.expectRevert();
        swapRouter.swapIDRXtoXAUT(testAmount, quote * 95 / 100, budi, block.timestamp + 300);
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
        uint256 swapQuote = swapRouter.getQuoteIDRXtoXAUT(swapAmount);
        
        vm.prank(budi);
        uint256 xautReceived = swapRouter.swapIDRXtoXAUT(swapAmount, swapQuote * 95 / 100, budi, block.timestamp + 300);
        console.log("XAUT received:", xautReceived);
        
        // Step 6: Verify Budi has XAUT
        console.log("\nStep 6: Verify final balances");
        assertGt(xaut.balanceOf(budi), 0, "Budi should have XAUT");
        _logBalances(budi, "Budi");
        
        console.log("\n========================================");
        console.log("=== PASSED: New User Onboarding ===");
        console.log("========================================");
    }
    
    // ============================================
    // TEST 2: SWAP AND STAKE JOURNEY
    // ============================================
    
    function test_SwapAndStakeJourney() public {
        console.log("========================================");
        console.log("=== Test: Swap and Stake Journey ===");
        console.log("========================================");
        
        // Step 1: Initial balances
        console.log("\nStep 1: Initial balances");
        _logBalances(ani, "Ani");
        assertEq(idrx.balanceOf(ani), INITIAL_IDRX, "Should have initial IDRX");
        assertEq(xaut.balanceOf(ani), 0, "Should have no XAUT");
        assertEq(vault.balanceOf(ani), 0, "Should have no gXAUT");
        
        // Step 2: Approve IDRX to SwapRouter
        console.log("\nStep 2: Approve IDRX to SwapRouter");
        vm.prank(ani);
        idrx.approve(SWAP_ROUTER, type(uint256).max);
        console.log("IDRX approved");
        
        // Step 3: Swap IDRX -> XAUT
        console.log("\nStep 3: Swap IDRX -> XAUT");
        uint256 swapAmount = SWAP_AMOUNT;
        uint256 quote = swapRouter.getQuoteIDRXtoXAUT(swapAmount);
        console.log("Swapping:", swapAmount, "IDRX");
        console.log("Expected XAUT:", quote);
        
        vm.prank(ani);
        uint256 xautReceived = swapRouter.swapIDRXtoXAUT(swapAmount, quote * 95 / 100, ani, block.timestamp + 300);
        console.log("XAUT received:", xautReceived);
        
        // Step 4: Verify balances after swap
        console.log("\nStep 4: Verify balances after swap");
        assertEq(idrx.balanceOf(ani), INITIAL_IDRX - swapAmount, "IDRX should decrease");
        assertGt(xaut.balanceOf(ani), 0, "XAUT should increase");
        _logBalances(ani, "Ani after swap");
        
        // Step 5: Approve XAUT to GoldVault
        console.log("\nStep 5: Approve XAUT to GoldVault");
        vm.prank(ani);
        xaut.approve(GOLD_VAULT, type(uint256).max);
        console.log("XAUT approved");
        
        // Step 6: Deposit all XAUT to GoldVault
        console.log("\nStep 6: Deposit XAUT to GoldVault");
        uint256 xautBalance = xaut.balanceOf(ani);
        console.log("Depositing:", xautBalance, "XAUT");
        
        vm.prank(ani);
        uint256 sharesReceived = vault.deposit(xautBalance, ani);
        console.log("gXAUT shares received:", sharesReceived);
        
        // Step 7: Verify final balances
        console.log("\nStep 7: Verify final balances");
        assertEq(xaut.balanceOf(ani), 0, "XAUT should be 0");
        assertGt(vault.balanceOf(ani), 0, "gXAUT should be > 0");
        _logBalances(ani, "Ani final");
        
        console.log("\n========================================");
        console.log("=== PASSED: Swap and Stake Journey ===");
        console.log("========================================");
    }
    
    // ============================================
    // TEST 3: WITHDRAW AND SWAP BACK JOURNEY
    // ============================================
    
    function test_WithdrawAndSwapBackJourney() public {
        console.log("========================================");
        console.log("=== Test: Withdraw and Swap Back ===");
        console.log("========================================");
        
        // Prerequisites: Ani has gXAUT from swap and stake
        console.log("\nPrerequisites: Setup Ani with gXAUT");
        
        // Swap IDRX -> XAUT
        vm.startPrank(ani);
        idrx.approve(SWAP_ROUTER, type(uint256).max);
        uint256 quote = swapRouter.getQuoteIDRXtoXAUT(SWAP_AMOUNT);
        uint256 xautReceived = swapRouter.swapIDRXtoXAUT(SWAP_AMOUNT, quote * 95 / 100, ani, block.timestamp + 300);
        
        // Deposit XAUT -> gXAUT
        xaut.approve(GOLD_VAULT, type(uint256).max);
        vault.deposit(xautReceived, ani);
        vm.stopPrank();
        
        console.log("Ani has gXAUT:", vault.balanceOf(ani));
        
        // Step 1: Initial balances
        console.log("\nStep 1: Initial balances");
        _logBalances(ani, "Ani");
        uint256 gXAUTBalance = vault.balanceOf(ani);
        assertGt(gXAUTBalance, 0, "Should have gXAUT");
        
        // Step 2: Redeem all gXAUT -> XAUT
        console.log("\nStep 2: Redeem gXAUT -> XAUT");
        console.log("Redeeming:", gXAUTBalance, "gXAUT");
        
        vm.prank(ani);
        uint256 xautRedeemed = vault.redeem(gXAUTBalance, ani, ani);
        console.log("XAUT redeemed:", xautRedeemed);
        
        // Step 3: Verify balances after redeem
        console.log("\nStep 3: Verify balances after redeem");
        assertEq(vault.balanceOf(ani), 0, "gXAUT should be 0");
        assertGt(xaut.balanceOf(ani), 0, "XAUT should be > 0");
        _logBalances(ani, "Ani after redeem");
        
        // Step 4: Approve XAUT to SwapRouter
        console.log("\nStep 4: Approve XAUT to SwapRouter");
        vm.prank(ani);
        xaut.approve(SWAP_ROUTER, type(uint256).max);
        console.log("XAUT approved");
        
        // Step 5: Swap all XAUT -> IDRX
        console.log("\nStep 5: Swap XAUT -> IDRX");
        uint256 xautToSwap = xaut.balanceOf(ani);
        uint256 quoteBack = swapRouter.getQuoteXAUTtoIDRX(xautToSwap);
        console.log("Swapping:", xautToSwap, "XAUT");
        console.log("Expected IDRX:", quoteBack);
        
        vm.prank(ani);
        uint256 idrxReceived = swapRouter.swapXAUTtoIDRX(xautToSwap, quoteBack * 95 / 100, ani, block.timestamp + 300);
        console.log("IDRX received:", idrxReceived);
        
        // Step 6: Verify final balances
        console.log("\nStep 6: Verify final balances");
        assertEq(xaut.balanceOf(ani), 0, "XAUT should be 0");
        assertGt(idrx.balanceOf(ani), 0, "IDRX should be > 0");
        _logBalances(ani, "Ani final");
        
        console.log("\n========================================");
        console.log("=== PASSED: Withdraw and Swap Back ===");
        console.log("========================================");
    }
    
    // ============================================
    // TEST 4: FULL CYCLE - IDRX -> gXAUT -> IDRX
    // ============================================
    
    function test_FullCycle_IDRXtoGXAUTtoIDRX() public {
        console.log("========================================");
        console.log("=== Test: Full Cycle Round Trip ===");
        console.log("========================================");
        
        // Step 1: Record initial balance
        console.log("\nStep 1: Initial balance");
        uint256 initialIDRX = idrx.balanceOf(ani);
        console.log("Initial IDRX:", initialIDRX);
        
        // Step 2: Swap IDRX -> XAUT
        console.log("\nStep 2: Swap IDRX -> XAUT");
        uint256 swapAmount = SWAP_AMOUNT;
        
        vm.startPrank(ani);
        idrx.approve(SWAP_ROUTER, type(uint256).max);
        uint256 quote1 = swapRouter.getQuoteIDRXtoXAUT(swapAmount);
        uint256 xautReceived = swapRouter.swapIDRXtoXAUT(swapAmount, quote1 * 95 / 100, ani, block.timestamp + 300);
        vm.stopPrank();
        
        console.log("IDRX swapped:", swapAmount);
        console.log("XAUT received:", xautReceived);
        
        // Step 3: Stake XAUT -> gXAUT
        console.log("\nStep 3: Stake XAUT -> gXAUT");
        vm.startPrank(ani);
        xaut.approve(GOLD_VAULT, type(uint256).max);
        uint256 sharesReceived = vault.deposit(xautReceived, ani);
        vm.stopPrank();
        
        console.log("XAUT deposited:", xautReceived);
        console.log("gXAUT received:", sharesReceived);
        
        // Step 4: Redeem gXAUT -> XAUT
        console.log("\nStep 4: Redeem gXAUT -> XAUT");
        vm.prank(ani);
        uint256 xautRedeemed = vault.redeem(sharesReceived, ani, ani);
        
        console.log("gXAUT redeemed:", sharesReceived);
        console.log("XAUT received:", xautRedeemed);
        
        // Step 5: Swap XAUT -> IDRX
        console.log("\nStep 5: Swap XAUT -> IDRX");
        
        // Approve XAUT to SwapRouter
        vm.prank(ani);
        xaut.approve(SWAP_ROUTER, type(uint256).max);
        
        uint256 quote2 = swapRouter.getQuoteXAUTtoIDRX(xautRedeemed);
        
        vm.prank(ani);
        uint256 idrxReceived = swapRouter.swapXAUTtoIDRX(xautRedeemed, quote2 * 95 / 100, ani, block.timestamp + 300);
        
        console.log("XAUT swapped:", xautRedeemed);
        console.log("IDRX received:", idrxReceived);
        
        // Step 6: Calculate final balance and fees
        console.log("\nStep 6: Final balance and fees");
        uint256 finalIDRX = idrx.balanceOf(ani);
        console.log("Final IDRX:", finalIDRX);
        
        // Step 7: Verify and calculate fees
        console.log("\nStep 7: Fee calculation");
        assertLt(finalIDRX, initialIDRX, "Final IDRX should be less than initial (fees paid)");
        
        uint256 totalFees = initialIDRX - finalIDRX;
        uint256 feePercentage = (totalFees * 10000) / swapAmount; // basis points
        
        console.log("Total fees paid:", totalFees, "IDRX");
        console.log("Fee percentage (basis points):", feePercentage);
        console.log("Amount cycled:", swapAmount);
        console.log("Amount returned:", idrxReceived);
        console.log("Net loss:", totalFees);
        
        // Verify reasonable fee range (should be around 0.6% for two 0.3% swaps)
        assertGt(feePercentage, 0, "Should have paid some fees");
        assertLt(feePercentage, 200, "Fees should be less than 2%"); // Allow up to 2% for slippage + fees
        
        console.log("\n========================================");
        console.log("=== PASSED: Full Cycle Round Trip ===");
        console.log("========================================");
    }
}
