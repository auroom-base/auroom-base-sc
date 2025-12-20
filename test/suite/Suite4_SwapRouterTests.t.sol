// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Suite4_SwapRouterTests
 * @notice Test suite for SwapRouter contract on AuRoom Protocol
 * @dev Tests custom router for IDRX ↔ XAUT swaps via USDC routing
 */

interface ISwapRouter {
    event SwapExecuted(
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

interface IXAUT is IERC20 {
    function mint(address to, uint256 amount) external;
}

contract Suite4_SwapRouterTests is Test {
    // Constants - Contract Addresses
    address constant SWAP_ROUTER = 0xF948Dd812E7fA072367848ec3D198cc61488b1b9; // Redeployed with Router V2
    address constant MOCK_IDRX = 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05;
    address constant MOCK_USDC = 0x96ABff3a2668B811371d7d763f06B3832CEdf38d;
    address constant XAUT = 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78;
    address constant IDENTITY_REGISTRY = 0x620870d419F6aFca8AFed5B516619aa50900cadc;
    address constant UNISWAP_ROUTER = 0x54166b2C5e09f16c3c1D705FfB4eb29a069000A9; // Router V2
    address constant DEPLOYER = 0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1;
    
    // Network Configuration
    uint256 constant MANTLE_SEPOLIA_CHAIN_ID = 5003;
    
    // Contracts
    ISwapRouter swapRouter;
    IIdentityRegistry identityRegistry;
    IMockToken idrx;
    IXAUT xaut;
    
    // Test users
    address verifiedUser;
    address unverifiedUser;
    
    // Test amounts
    uint256 constant SWAP_AMOUNT = 1000 * 10**6; // 1000 IDRX (6 decimals)
    uint256 constant LARGE_SWAP_AMOUNT = 10000 * 10**6; // 10,000 IDRX
    
    function setUp() public {
        // Fork Mantle Sepolia
        vm.createSelectFork("https://rpc.sepolia.mantle.xyz");
        
        // Initialize contracts
        swapRouter = ISwapRouter(SWAP_ROUTER);
        identityRegistry = IIdentityRegistry(IDENTITY_REGISTRY);
        idrx = IMockToken(MOCK_IDRX);
        xaut = IXAUT(XAUT);
        
        // Create test users
        verifiedUser = makeAddr("verifiedUser");
        unverifiedUser = makeAddr("unverifiedUser");
        
        // Setup verified user
        vm.prank(DEPLOYER);
        identityRegistry.registerIdentity(verifiedUser);
        
        // Mint IDRX to both users
        vm.startPrank(DEPLOYER);
        idrx.mint(verifiedUser, 100000 * 10**6); // 100,000 IDRX
        idrx.mint(unverifiedUser, 100000 * 10**6);
        vm.stopPrank();
        
        // Approve SwapRouter for verified user
        vm.prank(verifiedUser);
        idrx.approve(SWAP_ROUTER, type(uint256).max);
        
        // Log setup info
        console.log("=== Suite 4: SwapRouter Test Setup ===");
        console.log("Chain ID:", block.chainid);
        console.log("Block Number:", block.number);
        console.log("SwapRouter:", SWAP_ROUTER);
        console.log("Verified User:", verifiedUser);
        console.log("Verified User Status:", identityRegistry.isVerified(verifiedUser));
        console.log("Unverified User:", unverifiedUser);
        console.log("Unverified User Status:", identityRegistry.isVerified(unverifiedUser));
    }
    
    // ============================================
    // CONFIGURATION TESTS
    // ============================================
    
    function test_Router_IDRX_Address() public {
        console.log("=== Test: SwapRouter IDRX Address ===");
        
        address idrxAddress = swapRouter.idrx();
        
        assertEq(idrxAddress, MOCK_IDRX, "IDRX address should match");
        console.log("IDRX Address:", idrxAddress);
        console.log("Expected:", MOCK_IDRX);
        console.log("=== PASSED ===");
    }
    
    function test_Router_USDC_Address() public {
        console.log("=== Test: SwapRouter USDC Address ===");
        
        address usdcAddress = swapRouter.usdc();
        
        assertEq(usdcAddress, MOCK_USDC, "USDC address should match");
        console.log("USDC Address:", usdcAddress);
        console.log("Expected:", MOCK_USDC);
        console.log("=== PASSED ===");
    }
    
    function test_Router_XAUT_Address() public {
        console.log("=== Test: SwapRouter XAUT Address ===");
        
        address xautAddress = swapRouter.xaut();
        
        assertEq(xautAddress, XAUT, "XAUT address should match");
        console.log("XAUT Address:", xautAddress);
        console.log("Expected:", XAUT);
        console.log("=== PASSED ===");
    }
    
    function test_Router_UniswapRouter_Address() public {
        console.log("=== Test: SwapRouter UniswapRouter Address ===");
        
        address uniswapRouterAddress = swapRouter.uniswapRouter();
        
        assertEq(uniswapRouterAddress, UNISWAP_ROUTER, "UniswapRouter address should match Router V2");
        console.log("UniswapRouter Address:", uniswapRouterAddress);
        console.log("Expected (Router V2):", UNISWAP_ROUTER);
        console.log("=== PASSED ===");
    }
    
    // ============================================
    // QUOTE TESTS
    // ============================================
    
    function test_GetQuoteIDRXtoXAUT_ReturnsValue() public {
        console.log("=== Test: GetQuote IDRX to XAUT ===");
        
        uint256 amountIn = SWAP_AMOUNT;
        uint256 quote = swapRouter.getQuoteIDRXtoXAUT(amountIn);
        
        assertGt(quote, 0, "Quote should be greater than 0");
        console.log("Input (IDRX):", amountIn);
        console.log("Quote (XAUT):", quote);
        console.log("=== PASSED ===");
    }
    
    function test_GetQuoteXAUTtoIDRX_ReturnsValue() public {
        console.log("=== Test: GetQuote XAUT to IDRX ===");
        
        uint256 amountIn = 1 * 10**6; // 1 XAUT
        uint256 quote = swapRouter.getQuoteXAUTtoIDRX(amountIn);
        
        assertGt(quote, 0, "Quote should be greater than 0");
        console.log("Input (XAUT):", amountIn);
        console.log("Quote (IDRX):", quote);
        console.log("=== PASSED ===");
    }
    
    function test_Quote_MatchesActualSwap() public {
        console.log("=== Test: Quote Matches Actual Swap ===");
        
        uint256 amountIn = SWAP_AMOUNT;
        uint256 quote = swapRouter.getQuoteIDRXtoXAUT(amountIn);
        
        console.log("Quote (XAUT):", quote);
        
        // Execute actual swap with quote as minimum (should match exactly)
        vm.prank(verifiedUser);
        uint256 actualOut = swapRouter.swapIDRXtoXAUT(amountIn, quote, verifiedUser, block.timestamp + 300);
        
        console.log("Actual Output (XAUT):", actualOut);
        
        // Quote should match actual output exactly (no slippage in same block)
        assertEq(actualOut, quote, "Actual output should match quote");
        console.log("Match: true");
        console.log("=== PASSED ===");
    }
    
    // ============================================
    // SWAP IDRX → XAUT TESTS
    // ============================================
    
    function test_SwapIDRXtoXAUT_Success() public {
        console.log("=== Test: Swap IDRX to XAUT Success ===");
        
        uint256 amountIn = SWAP_AMOUNT;
        uint256 quote = swapRouter.getQuoteIDRXtoXAUT(amountIn);
        uint256 minOut = quote * 95 / 100; // Accept 95% of quote (5% slippage tolerance)
        
        vm.prank(verifiedUser);
        uint256 amountOut = swapRouter.swapIDRXtoXAUT(amountIn, minOut, verifiedUser, block.timestamp + 300);
        
        assertGt(amountOut, 0, "Should receive XAUT");
        console.log("Input (IDRX):", amountIn);
        console.log("Output (XAUT):", amountOut);
        console.log("=== PASSED ===");
    }
    
    function test_SwapIDRXtoXAUT_BalancesCorrect() public {
        console.log("=== Test: Swap IDRX to XAUT - Balances Correct ===");
        
        uint256 amountIn = SWAP_AMOUNT;
        uint256 quote = swapRouter.getQuoteIDRXtoXAUT(amountIn);
        uint256 minOut = quote * 95 / 100;
        
        uint256 idrxBefore = idrx.balanceOf(verifiedUser);
        uint256 xautBefore = xaut.balanceOf(verifiedUser);
        
        console.log("IDRX Balance Before:", idrxBefore);
        console.log("XAUT Balance Before:", xautBefore);
        
        vm.prank(verifiedUser);
        uint256 amountOut = swapRouter.swapIDRXtoXAUT(amountIn, minOut, verifiedUser, block.timestamp + 300);
        
        uint256 idrxAfter = idrx.balanceOf(verifiedUser);
        uint256 xautAfter = xaut.balanceOf(verifiedUser);
        
        console.log("IDRX Balance After:", idrxAfter);
        console.log("XAUT Balance After:", xautAfter);
        
        assertEq(idrxAfter, idrxBefore - amountIn, "IDRX should decrease by amountIn");
        assertEq(xautAfter, xautBefore + amountOut, "XAUT should increase by amountOut");
        console.log("=== PASSED ===");
    }
    
    function test_SwapIDRXtoXAUT_EmitsEvent() public {
        console.log("=== Test: Swap IDRX to XAUT - Emits Event ===");
        
        uint256 amountIn = SWAP_AMOUNT;
        uint256 quote = swapRouter.getQuoteIDRXtoXAUT(amountIn);
        uint256 minOut = quote * 95 / 100;
        
        // Expect SwapExecuted event (we check indexed params, not exact amountOut)
        vm.expectEmit(true, true, true, false);
        emit ISwapRouter.SwapExecuted(verifiedUser, MOCK_IDRX, XAUT, amountIn, 0, block.timestamp);
        
        vm.prank(verifiedUser);
        swapRouter.swapIDRXtoXAUT(amountIn, minOut, verifiedUser, block.timestamp + 300);
        
        console.log("SwapExecuted event emitted correctly");
        console.log("=== PASSED ===");
    }
    
    // ============================================
    // SWAP XAUT → IDRX TESTS
    // ============================================
    
    function test_SwapXAUTtoIDRX_Success() public {
        console.log("=== Test: Swap XAUT to IDRX Success ===");
        
        // First, get some XAUT by swapping IDRX
        uint256 idrxQuote = swapRouter.getQuoteIDRXtoXAUT(LARGE_SWAP_AMOUNT);
        vm.prank(verifiedUser);
        uint256 xautAmount = swapRouter.swapIDRXtoXAUT(LARGE_SWAP_AMOUNT, idrxQuote * 95 / 100, verifiedUser, block.timestamp + 300);
        
        console.log("XAUT obtained:", xautAmount);
        
        // Approve XAUT for swap back
        vm.prank(verifiedUser);
        xaut.approve(SWAP_ROUTER, type(uint256).max);
        
        // Swap XAUT back to IDRX
        uint256 xautQuote = swapRouter.getQuoteXAUTtoIDRX(xautAmount);
        vm.prank(verifiedUser);
        uint256 idrxOut = swapRouter.swapXAUTtoIDRX(xautAmount, xautQuote * 95 / 100, verifiedUser, block.timestamp + 300);
        
        assertGt(idrxOut, 0, "Should receive IDRX");
        console.log("Input (XAUT):", xautAmount);
        console.log("Output (IDRX):", idrxOut);
        console.log("=== PASSED ===");
    }
    
    function test_SwapXAUTtoIDRX_BalancesCorrect() public {
        console.log("=== Test: Swap XAUT to IDRX - Balances Correct ===");
        
        // Get XAUT first
        uint256 idrxQuote = swapRouter.getQuoteIDRXtoXAUT(LARGE_SWAP_AMOUNT);
        vm.prank(verifiedUser);
        uint256 xautAmount = swapRouter.swapIDRXtoXAUT(LARGE_SWAP_AMOUNT, idrxQuote * 95 / 100, verifiedUser, block.timestamp + 300);
        
        // Approve XAUT
        vm.prank(verifiedUser);
        xaut.approve(SWAP_ROUTER, type(uint256).max);
        
        uint256 xautBefore = xaut.balanceOf(verifiedUser);
        uint256 idrxBefore = idrx.balanceOf(verifiedUser);
        
        console.log("XAUT Balance Before:", xautBefore);
        console.log("IDRX Balance Before:", idrxBefore);
        
        // Swap back
        uint256 xautQuote = swapRouter.getQuoteXAUTtoIDRX(xautAmount);
        vm.prank(verifiedUser);
        uint256 idrxOut = swapRouter.swapXAUTtoIDRX(xautAmount, xautQuote * 95 / 100, verifiedUser, block.timestamp + 300);
        
        uint256 xautAfter = xaut.balanceOf(verifiedUser);
        uint256 idrxAfter = idrx.balanceOf(verifiedUser);
        
        console.log("XAUT Balance After:", xautAfter);
        console.log("IDRX Balance After:", idrxAfter);
        
        assertEq(xautAfter, xautBefore - xautAmount, "XAUT should decrease by input amount");
        assertEq(idrxAfter, idrxBefore + idrxOut, "IDRX should increase by output amount");
        console.log("=== PASSED ===");
    }
    
    function test_SwapXAUTtoIDRX_EmitsEvent() public {
        console.log("=== Test: Swap XAUT to IDRX - Emits Event ===");
        
        // Get XAUT first
        uint256 idrxQuote = swapRouter.getQuoteIDRXtoXAUT(LARGE_SWAP_AMOUNT);
        vm.prank(verifiedUser);
        uint256 xautAmount = swapRouter.swapIDRXtoXAUT(LARGE_SWAP_AMOUNT, idrxQuote * 95 / 100, verifiedUser, block.timestamp + 300);
        
        // Approve XAUT
        vm.prank(verifiedUser);
        xaut.approve(SWAP_ROUTER, type(uint256).max);
        
        // Expect SwapExecuted event
        uint256 xautQuote = swapRouter.getQuoteXAUTtoIDRX(xautAmount);
        vm.expectEmit(true, true, true, false);
        emit ISwapRouter.SwapExecuted(verifiedUser, XAUT, MOCK_IDRX, xautAmount, 0, block.timestamp);
        
        vm.prank(verifiedUser);
        swapRouter.swapXAUTtoIDRX(xautAmount, xautQuote * 95 / 100, verifiedUser, block.timestamp + 300);
        
        console.log("SwapExecuted event emitted correctly");
        console.log("=== PASSED ===");
    }
    
    // ============================================
    // SLIPPAGE & DEADLINE TESTS
    // ============================================
    
    function test_Swap_SlippageProtection_Reverts() public {
        console.log("=== Test: Swap Slippage Protection ===");
        
        uint256 amountIn = SWAP_AMOUNT;
        uint256 quote = swapRouter.getQuoteIDRXtoXAUT(amountIn);
        uint256 unrealisticMinOut = quote * 2; // Require 2x the quote (impossible)
        
        console.log("Quote:", quote);
        console.log("Unrealistic Min Out:", unrealisticMinOut);
        
        vm.prank(verifiedUser);
        vm.expectRevert();
        swapRouter.swapIDRXtoXAUT(amountIn, unrealisticMinOut, verifiedUser, block.timestamp + 300);
        
        console.log("Swap correctly reverted due to slippage protection");
        console.log("=== PASSED ===");
    }
    
    function test_Swap_DeadlineExpired_Reverts() public {
        console.log("=== Test: Swap Deadline Expired ===");
        
        uint256 amountIn = SWAP_AMOUNT;
        uint256 pastDeadline = block.timestamp - 1;
        
        console.log("Current Time:", block.timestamp);
        console.log("Deadline:", pastDeadline);
        
        vm.prank(verifiedUser);
        vm.expectRevert();
        swapRouter.swapIDRXtoXAUT(amountIn, 0, verifiedUser, pastDeadline);
        
        console.log("Swap correctly reverted due to expired deadline");
        console.log("=== PASSED ===");
    }
    
    // ============================================
    // COMPLIANCE TESTS
    // ============================================
    
    function test_SwapIDRXtoXAUT_UnverifiedUser_Reverts() public {
        console.log("=== Test: Swap IDRX to XAUT - Unverified User Reverts ===");
        
        uint256 amountIn = SWAP_AMOUNT;
        uint256 quote = swapRouter.getQuoteIDRXtoXAUT(amountIn);
        uint256 minOut = quote * 95 / 100;
        
        console.log("Unverified User:", unverifiedUser);
        console.log("Verified Status:", identityRegistry.isVerified(unverifiedUser));
        
        // Approve for unverified user
        vm.prank(unverifiedUser);
        idrx.approve(SWAP_ROUTER, type(uint256).max);
        
        // Try to swap - should revert because recipient is not verified
        vm.prank(unverifiedUser);
        vm.expectRevert();
        swapRouter.swapIDRXtoXAUT(amountIn, minOut, unverifiedUser, block.timestamp + 300);
        
        console.log("Swap correctly reverted for unverified user");
        console.log("=== PASSED ===");
    }
}
