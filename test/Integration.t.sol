// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/MockIDRX.sol";
import "../src/MockUSDC.sol";
import "../src/IdentityRegistry.sol";
import "../src/XAUT.sol";
import "../src/GoldVault.sol";
import "../src/SwapRouter.sol";

// Mock Uniswap V2 Router for testing
contract MockUniswapV2Router {
    address public factory;

    // Simple oracle price: 1 IDRX = 1 USDC, 1 XAUT = 100 USDC
    // So 1 XAUT = 100 IDRX (simplified for testing)

    constructor(address _factory) {
        factory = _factory;
    }

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        pure
        returns (uint256[] memory amounts)
    {
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;

        if (path.length == 3) {
            // IDRX -> USDC -> XAUT
            if (path[0] < path[2]) {
                // IDRX to XAUT (simplified: 100 IDRX = 1 XAUT)
                amounts[1] = amountIn; // IDRX to USDC (1:1)
                amounts[2] = amountIn / 100; // USDC to XAUT (100:1)
            } else {
                // XAUT to IDRX (simplified: 1 XAUT = 100 IDRX)
                amounts[1] = amountIn * 100; // XAUT to USDC (1:100)
                amounts[2] = amountIn * 100; // USDC to IDRX (1:1)
            }
        }

        return amounts;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        require(deadline >= block.timestamp, "Router: EXPIRED");

        amounts = this.getAmountsOut(amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "Router: INSUFFICIENT_OUTPUT_AMOUNT");

        // Transfer tokens
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        IERC20(path[path.length - 1]).transfer(to, amounts[amounts.length - 1]);

        return amounts;
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256, /* amountAMin */
        uint256, /* amountBMin */
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        require(deadline >= block.timestamp, "Router: EXPIRED");

        amountA = amountADesired;
        amountB = amountBDesired;
        liquidity = (amountA + amountB) / 2; // Simplified LP calculation

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        // Mint LP tokens (simplified - would normally come from pair contract)
        MockLPToken lpToken = MockLPToken(MockUniswapV2Factory(factory).getPair(tokenA, tokenB));
        lpToken.mint(to, liquidity);

        return (amountA, amountB, liquidity);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (uint256 amountA, uint256 amountB)
    {
        require(deadline >= block.timestamp, "Router: EXPIRED");

        MockLPToken lpToken = MockLPToken(MockUniswapV2Factory(factory).getPair(tokenA, tokenB));
        lpToken.transferFrom(msg.sender, address(this), liquidity);
        lpToken.burn(liquidity);

        // Simplified: return proportional amounts
        uint256 balanceA = IERC20(tokenA).balanceOf(address(this));
        uint256 balanceB = IERC20(tokenB).balanceOf(address(this));

        amountA = (balanceA * liquidity) / (liquidity + 1000000);
        amountB = (balanceB * liquidity) / (liquidity + 1000000);

        require(amountA >= amountAMin, "Router: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "Router: INSUFFICIENT_B_AMOUNT");

        IERC20(tokenA).transfer(to, amountA);
        IERC20(tokenB).transfer(to, amountB);

        return (amountA, amountB);
    }
}

contract MockLPToken is ERC20 {
    address public token0;
    address public token1;
    uint112 private reserve0;
    uint112 private reserve1;

    constructor(address _token0, address _token1) ERC20("LP Token", "LP") {
        token0 = _token0;
        token1 = _token1;
        reserve0 = 1000000 * 10**6;
        reserve1 = 1000000 * 10**6;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function getReserves() external view returns (uint112, uint112, uint32) {
        return (reserve0, reserve1, uint32(block.timestamp));
    }
}

contract MockUniswapV2Factory {
    mapping(address => mapping(address => address)) public pairs;

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        MockLPToken lpToken = new MockLPToken(token0, token1);
        pair = address(lpToken);
        pairs[token0][token1] = pair;
        pairs[token1][token0] = pair;
        return pair;
    }

    function getPair(address tokenA, address tokenB) external view returns (address) {
        return pairs[tokenA][tokenB];
    }
}

/**
 * @title Comprehensive Integration Test Suite
 * @dev Tests all contracts individually and their integration flows
 */
contract IntegrationTest is Test {
    // Contracts
    MockIDRX public idrx;
    MockUSDC public usdc;
    IdentityRegistry public identityRegistry;
    XAUT public xaut;
    GoldVault public goldVault;
    SwapRouter public swapRouter;
    MockUniswapV2Factory public uniswapFactory;
    MockUniswapV2Router public uniswapRouter;

    // Test accounts
    address public owner;
    address public admin;
    address public user1;
    address public user2;
    address public unverifiedUser;

    // Constants
    uint256 constant DECIMALS = 10**6;
    uint256 constant INITIAL_MINT = 1000000 * DECIMALS; // 1M tokens

    // Events to test
    event IdentityRegistered(address indexed user, uint256 timestamp);
    event IdentityRemoved(address indexed user, uint256 timestamp);
    event AdminAdded(address indexed admin);
    event SwapExecuted(
        address indexed user,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 timestamp
    );

    function setUp() public {
        owner = address(this);
        admin = address(0xAD);
        user1 = address(0x1);
        user2 = address(0x2);
        unverifiedUser = address(0x99);

        // Deploy mock tokens
        idrx = new MockIDRX();
        usdc = new MockUSDC();

        // Deploy Uniswap mocks
        uniswapFactory = new MockUniswapV2Factory();
        uniswapRouter = new MockUniswapV2Router(address(uniswapFactory));

        // Deploy IdentityRegistry
        identityRegistry = new IdentityRegistry();

        // Deploy XAUT
        xaut = new XAUT(address(identityRegistry));

        // Deploy GoldVault
        goldVault = new GoldVault(
            address(xaut),
            address(identityRegistry),
            address(uniswapRouter),
            address(usdc)
        );

        // Deploy SwapRouter
        swapRouter = new SwapRouter(
            address(uniswapRouter),
            address(idrx),
            address(usdc),
            address(xaut)
        );

        // Setup: Add admin and register users
        identityRegistry.addAdmin(admin);
        vm.prank(admin);
        identityRegistry.registerIdentity(owner);
        vm.prank(admin);
        identityRegistry.registerIdentity(user1);
        vm.prank(admin);
        identityRegistry.registerIdentity(user2);
        vm.prank(admin);
        identityRegistry.registerIdentity(address(goldVault));
        vm.prank(admin);
        identityRegistry.registerIdentity(address(swapRouter));
        vm.prank(admin);
        identityRegistry.registerIdentity(address(uniswapRouter));

        // Mint initial tokens for testing
        idrx.publicMint(owner, INITIAL_MINT);
        idrx.publicMint(user1, INITIAL_MINT);
        idrx.publicMint(address(uniswapRouter), INITIAL_MINT * 10);

        usdc.publicMint(owner, INITIAL_MINT);
        usdc.publicMint(user1, INITIAL_MINT);
        usdc.publicMint(address(uniswapRouter), INITIAL_MINT * 10);

        xaut.mint(owner, INITIAL_MINT);
        xaut.mint(user1, INITIAL_MINT);
        xaut.mint(user2, INITIAL_MINT);
        xaut.mint(address(uniswapRouter), INITIAL_MINT * 10);
    }

    /*//////////////////////////////////////////////////////////////
                    TEST SUITE 1: INDIVIDUAL CONTRACTS
    //////////////////////////////////////////////////////////////*/

    /*==============================================================
                        1.1 MockIDRX & MockUSDC Tests
    ==============================================================*/

    function test_MockIDRX_Deploy() public view {
        assertEq(idrx.name(), "Mock IDRX");
        assertEq(idrx.symbol(), "IDRX");
        assertTrue(address(idrx) != address(0));
    }

    function test_MockIDRX_PublicMint() public {
        uint256 amount = 1000 * DECIMALS;
        idrx.publicMint(user2, amount);
        assertEq(idrx.balanceOf(user2), amount);
    }

    function test_MockIDRX_Transfer() public {
        uint256 amount = 500 * DECIMALS;
        vm.prank(user1);
        idrx.transfer(user2, amount);
        assertEq(idrx.balanceOf(user2), amount);
    }

    function test_MockIDRX_Decimals() public view {
        assertEq(idrx.decimals(), 6);
    }

    function test_MockIDRX_BalanceUpdate() public {
        uint256 initialBalance = idrx.balanceOf(user1);
        uint256 amount = 100 * DECIMALS;
        idrx.publicMint(user1, amount);
        assertEq(idrx.balanceOf(user1), initialBalance + amount);
    }

    function test_MockUSDC_Deploy() public view {
        assertEq(usdc.name(), "Mock USDC");
        assertEq(usdc.symbol(), "USDC");
        assertTrue(address(usdc) != address(0));
    }

    function test_MockUSDC_PublicMint() public {
        uint256 amount = 1000 * DECIMALS;
        usdc.publicMint(user2, amount);
        assertEq(usdc.balanceOf(user2), amount);
    }

    function test_MockUSDC_Transfer() public {
        uint256 amount = 500 * DECIMALS;
        vm.prank(user1);
        usdc.transfer(user2, amount);
        assertEq(usdc.balanceOf(user2), amount);
    }

    function test_MockUSDC_Decimals() public view {
        assertEq(usdc.decimals(), 6);
    }

    function test_MockUSDC_BalanceUpdate() public {
        uint256 initialBalance = usdc.balanceOf(user1);
        uint256 amount = 100 * DECIMALS;
        usdc.publicMint(user1, amount);
        assertEq(usdc.balanceOf(user1), initialBalance + amount);
    }

    /*==============================================================
                    1.2 IdentityRegistry Tests
    ==============================================================*/

    function test_IdentityRegistry_Deploy() public view {
        assertTrue(address(identityRegistry) != address(0));
        assertEq(identityRegistry.owner(), owner);
    }

    function test_IdentityRegistry_OwnerIsAdmin() public view {
        assertTrue(identityRegistry.isAdmin(owner));
    }

    function test_IdentityRegistry_AddAdmin() public {
        address newAdmin = address(0xAA);

        vm.expectEmit(true, false, false, false);
        emit AdminAdded(newAdmin);

        identityRegistry.addAdmin(newAdmin);
        assertTrue(identityRegistry.isAdmin(newAdmin));
    }

    function test_IdentityRegistry_AddAdminOnlyOwner() public {
        address newAdmin = address(0xAA);

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user1));
        identityRegistry.addAdmin(newAdmin);
    }

    function test_IdentityRegistry_RegisterIdentity() public {
        address newUser = address(0x3);

        vm.expectEmit(true, false, false, true);
        emit IdentityRegistered(newUser, block.timestamp);

        vm.prank(admin);
        identityRegistry.registerIdentity(newUser);

        assertTrue(identityRegistry.isVerified(newUser));
    }

    function test_IdentityRegistry_RegisterIdentityOnlyAdmin() public {
        address newUser = address(0x3);

        vm.prank(unverifiedUser);
        vm.expectRevert(IdentityRegistry.NotAdmin.selector);
        identityRegistry.registerIdentity(newUser);
    }

    function test_IdentityRegistry_RemoveIdentity() public {
        vm.expectEmit(true, false, false, true);
        emit IdentityRemoved(user1, block.timestamp);

        vm.prank(admin);
        identityRegistry.removeIdentity(user1);

        assertFalse(identityRegistry.isVerified(user1));
    }

    function test_IdentityRegistry_BatchRegister() public {
        address[] memory users = new address[](3);
        users[0] = address(0x10);
        users[1] = address(0x11);
        users[2] = address(0x12);

        vm.prank(admin);
        identityRegistry.batchRegisterIdentity(users);

        assertTrue(identityRegistry.isVerified(users[0]));
        assertTrue(identityRegistry.isVerified(users[1]));
        assertTrue(identityRegistry.isVerified(users[2]));
    }

    function test_IdentityRegistry_IsVerified() public view {
        assertTrue(identityRegistry.isVerified(user1));
        assertTrue(identityRegistry.isVerified(user2));
        assertFalse(identityRegistry.isVerified(unverifiedUser));
    }

    function test_IdentityRegistry_EventsEmitted() public {
        address newUser = address(0x3);

        vm.expectEmit(true, false, false, true);
        emit IdentityRegistered(newUser, block.timestamp);

        vm.prank(admin);
        identityRegistry.registerIdentity(newUser);
    }

    /*==============================================================
                        1.3 XAUT Tests
    ==============================================================*/

    function test_XAUT_Deploy() public view {
        assertEq(xaut.name(), "Mock Tether Gold");
        assertEq(xaut.symbol(), "XAUT");
        assertEq(address(xaut.identityRegistry()), address(identityRegistry));
        assertTrue(address(xaut) != address(0));
    }

    function test_XAUT_MintToVerified() public {
        uint256 amount = 100 * DECIMALS;
        uint256 initialBalance = xaut.balanceOf(user1);

        xaut.mint(user1, amount);
        assertEq(xaut.balanceOf(user1), initialBalance + amount);
    }

    function test_XAUT_MintToUnverifiedReverts() public {
        uint256 amount = 100 * DECIMALS;

        vm.expectRevert("XAUT: recipient not verified");
        xaut.mint(unverifiedUser, amount);
    }

    function test_XAUT_TransferVerifiedToVerified() public {
        uint256 amount = 50 * DECIMALS;

        vm.prank(user1);
        xaut.transfer(user2, amount);

        assertEq(xaut.balanceOf(user2), INITIAL_MINT + amount);
    }

    function test_XAUT_TransferToUnverifiedReverts() public {
        uint256 amount = 50 * DECIMALS;

        vm.prank(user1);
        vm.expectRevert("XAUT: recipient not verified");
        xaut.transfer(unverifiedUser, amount);
    }

    function test_XAUT_TransferFromUnverifiedReverts() public {
        // First, let's give unverified user some XAUT
        // Register temporarily
        vm.prank(admin);
        identityRegistry.registerIdentity(unverifiedUser);
        xaut.mint(unverifiedUser, 100 * DECIMALS);

        // Remove verification
        vm.prank(admin);
        identityRegistry.removeIdentity(unverifiedUser);

        // Try to transfer - should fail
        vm.prank(unverifiedUser);
        vm.expectRevert("XAUT: sender not verified");
        xaut.transfer(user1, 10 * DECIMALS);
    }

    function test_XAUT_TransferFromCompliance() public {
        uint256 amount = 50 * DECIMALS;

        vm.prank(user1);
        xaut.approve(user2, amount);

        vm.prank(user2);
        xaut.transferFrom(user1, user2, amount);

        assertEq(xaut.balanceOf(user2), INITIAL_MINT + amount);
    }

    function test_XAUT_CanTransfer() public view {
        assertTrue(xaut.canTransfer(user1, user2, 100 * DECIMALS));
        assertFalse(xaut.canTransfer(user1, unverifiedUser, 100 * DECIMALS));
        assertFalse(xaut.canTransfer(unverifiedUser, user1, 100 * DECIMALS));
    }

    function test_XAUT_Pause() public {
        xaut.pause();

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        xaut.transfer(user2, 10 * DECIMALS);
    }

    function test_XAUT_Unpause() public {
        xaut.pause();
        xaut.unpause();

        vm.prank(user1);
        xaut.transfer(user2, 10 * DECIMALS);
        assertEq(xaut.balanceOf(user2), INITIAL_MINT + 10 * DECIMALS);
    }

    function test_XAUT_SetIdentityRegistry() public {
        IdentityRegistry newRegistry = new IdentityRegistry();
        xaut.setIdentityRegistry(address(newRegistry));
        assertEq(address(xaut.identityRegistry()), address(newRegistry));
    }

    /*==============================================================
                        1.4 GoldVault Tests
    ==============================================================*/

    function test_GoldVault_Deploy() public view {
        assertEq(goldVault.name(), "Gold Vault Token");
        assertEq(goldVault.symbol(), "gXAUT");
        assertEq(goldVault.asset(), address(xaut));
        assertTrue(address(goldVault) != address(0));
    }

    function test_GoldVault_DepositFromVerified() public {
        uint256 depositAmount = 100 * DECIMALS;

        vm.startPrank(user1);
        xaut.approve(address(goldVault), depositAmount);
        uint256 shares = goldVault.deposit(depositAmount, user1);
        vm.stopPrank();

        assertGt(shares, 0);
        assertEq(goldVault.balanceOf(user1), shares);
    }

    function test_GoldVault_DepositFromUnverifiedReverts() public {
        // Register temporarily to get XAUT
        vm.prank(admin);
        identityRegistry.registerIdentity(unverifiedUser);
        xaut.mint(unverifiedUser, 100 * DECIMALS);

        // Remove verification
        vm.prank(admin);
        identityRegistry.removeIdentity(unverifiedUser);

        vm.startPrank(unverifiedUser);
        xaut.approve(address(goldVault), 100 * DECIMALS);
        vm.expectRevert("GoldVault: account not verified");
        goldVault.deposit(100 * DECIMALS, unverifiedUser);
        vm.stopPrank();
    }

    function test_GoldVault_DepositReturnCorrectShares() public {
        uint256 depositAmount = 100 * DECIMALS;

        vm.startPrank(user1);
        xaut.approve(address(goldVault), depositAmount);
        uint256 shares = goldVault.deposit(depositAmount, user1);
        vm.stopPrank();

        // First deposit should be 1:1
        assertEq(shares, depositAmount);
    }

    function test_GoldVault_Withdraw() public {
        uint256 depositAmount = 100 * DECIMALS;

        // First deposit
        vm.startPrank(user1);
        xaut.approve(address(goldVault), depositAmount);
        goldVault.deposit(depositAmount, user1);

        // Then withdraw
        uint256 withdrawAmount = 50 * DECIMALS;
        uint256 sharesBurned = goldVault.withdraw(withdrawAmount, user1, user1);
        vm.stopPrank();

        assertGt(sharesBurned, 0);
        assertEq(xaut.balanceOf(user1), INITIAL_MINT - depositAmount + withdrawAmount);
    }

    function test_GoldVault_Redeem() public {
        uint256 depositAmount = 100 * DECIMALS;

        // First deposit
        vm.startPrank(user1);
        xaut.approve(address(goldVault), depositAmount);
        uint256 shares = goldVault.deposit(depositAmount, user1);

        // Then redeem
        uint256 redeemShares = shares / 2;
        uint256 assets = goldVault.redeem(redeemShares, user1, user1);
        vm.stopPrank();

        assertGt(assets, 0);
    }

    function test_GoldVault_TotalAssets() public {
        uint256 depositAmount = 100 * DECIMALS;

        uint256 assetsBefore = goldVault.totalAssets();

        vm.startPrank(user1);
        xaut.approve(address(goldVault), depositAmount);
        goldVault.deposit(depositAmount, user1);
        vm.stopPrank();

        assertEq(goldVault.totalAssets(), assetsBefore + depositAmount);
    }

    function test_GoldVault_gXAUTTransferCompliance() public {
        uint256 depositAmount = 100 * DECIMALS;

        // User1 deposits
        vm.startPrank(user1);
        xaut.approve(address(goldVault), depositAmount);
        uint256 shares = goldVault.deposit(depositAmount, user1);

        // User1 transfers gXAUT to user2 (both verified)
        goldVault.transfer(user2, shares / 2);
        vm.stopPrank();

        assertEq(goldVault.balanceOf(user2), shares / 2);
    }

    function test_GoldVault_ShareAssetRatio() public {
        uint256 depositAmount = 100 * DECIMALS;

        vm.startPrank(user1);
        xaut.approve(address(goldVault), depositAmount);
        uint256 shares = goldVault.deposit(depositAmount, user1);
        vm.stopPrank();

        // First deposit should be 1:1 ratio
        assertEq(shares, depositAmount);
        assertEq(goldVault.convertToAssets(shares), depositAmount);
        assertEq(goldVault.convertToShares(depositAmount), shares);
    }

    /*==============================================================
                        1.5 SwapRouter Tests
    ==============================================================*/

    function test_SwapRouter_Deploy() public view {
        assertEq(address(swapRouter.uniswapRouter()), address(uniswapRouter));
        assertEq(swapRouter.idrx(), address(idrx));
        assertEq(swapRouter.usdc(), address(usdc));
        assertEq(swapRouter.xaut(), address(xaut));
        assertTrue(address(swapRouter) != address(0));
    }

    function test_SwapRouter_GetQuoteIDRXtoXAUT() public view {
        uint256 amountIn = 1000 * DECIMALS;
        uint256 quote = swapRouter.getQuoteIDRXtoXAUT(amountIn);
        assertGt(quote, 0);
    }

    function test_SwapRouter_GetQuoteXAUTtoIDRX() public view {
        uint256 amountIn = 1 * DECIMALS;
        uint256 quote = swapRouter.getQuoteXAUTtoIDRX(amountIn);
        assertGt(quote, 0);
    }

    function test_SwapRouter_SwapIDRXtoXAUT() public {
        uint256 amountIn = 1000 * DECIMALS;
        uint256 quote = swapRouter.getQuoteIDRXtoXAUT(amountIn);

        vm.startPrank(user1);
        idrx.approve(address(swapRouter), amountIn);

        vm.expectEmit(true, true, true, false);
        emit SwapExecuted(user1, address(idrx), address(xaut), amountIn, 0, 0);

        uint256 amountOut = swapRouter.swapIDRXtoXAUT(
            amountIn,
            quote * 95 / 100, // 5% slippage tolerance
            user1,
            block.timestamp + 300
        );
        vm.stopPrank();

        assertGt(amountOut, 0);
    }

    function test_SwapRouter_SwapXAUTtoIDRX() public {
        uint256 amountIn = 1 * DECIMALS;
        uint256 quote = swapRouter.getQuoteXAUTtoIDRX(amountIn);

        vm.startPrank(user1);
        xaut.approve(address(swapRouter), amountIn);

        vm.expectEmit(true, true, true, false);
        emit SwapExecuted(user1, address(xaut), address(idrx), amountIn, 0, 0);

        uint256 amountOut = swapRouter.swapXAUTtoIDRX(
            amountIn,
            quote * 95 / 100, // 5% slippage tolerance
            user1,
            block.timestamp + 300
        );
        vm.stopPrank();

        assertGt(amountOut, 0);
    }

    function test_SwapRouter_SlippageProtection() public {
        uint256 amountIn = 1000 * DECIMALS;
        uint256 quote = swapRouter.getQuoteIDRXtoXAUT(amountIn);

        vm.startPrank(user1);
        idrx.approve(address(swapRouter), amountIn);

        // Set unrealistic minimum output (higher than actual quote)
        vm.expectRevert("Router: INSUFFICIENT_OUTPUT_AMOUNT");
        swapRouter.swapIDRXtoXAUT(
            amountIn,
            quote * 2, // Expect double the quote
            user1,
            block.timestamp + 300
        );
        vm.stopPrank();
    }

    function test_SwapRouter_DeadlineCheck() public {
        uint256 amountIn = 1000 * DECIMALS;

        vm.startPrank(user1);
        idrx.approve(address(swapRouter), amountIn);

        vm.expectRevert("SwapRouter: expired deadline");
        swapRouter.swapIDRXtoXAUT(
            amountIn,
            1,
            user1,
            block.timestamp - 1 // Past deadline
        );
        vm.stopPrank();
    }

    function test_SwapRouter_EventsEmitted() public {
        uint256 amountIn = 1000 * DECIMALS;
        uint256 quote = swapRouter.getQuoteIDRXtoXAUT(amountIn);

        vm.startPrank(user1);
        idrx.approve(address(swapRouter), amountIn);

        vm.expectEmit(true, true, true, false);
        emit SwapExecuted(user1, address(idrx), address(xaut), amountIn, 0, 0);

        swapRouter.swapIDRXtoXAUT(
            amountIn,
            quote * 95 / 100,
            user1,
            block.timestamp + 300
        );
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                    TEST SUITE 2: INTEGRATION FLOWS
    //////////////////////////////////////////////////////////////*/

    /*==============================================================
            2.1 Full User Journey: New User Onboarding
    ==============================================================*/

    function test_Integration_NewUserOnboarding() public {
        address newUser = address(0x888);

        // Step 1: Admin registers new user in KYC system
        vm.prank(admin);
        identityRegistry.registerIdentity(newUser);
        assertTrue(identityRegistry.isVerified(newUser));

        // Step 2: User receives IDRX (simulating fiat onramp)
        idrx.publicMint(newUser, 10000 * DECIMALS);
        assertEq(idrx.balanceOf(newUser), 10000 * DECIMALS);

        // Step 3: User swaps IDRX to XAUT
        uint256 swapAmount = 5000 * DECIMALS;
        uint256 quote = swapRouter.getQuoteIDRXtoXAUT(swapAmount);

        vm.startPrank(newUser);
        idrx.approve(address(swapRouter), swapAmount);
        uint256 xautReceived = swapRouter.swapIDRXtoXAUT(
            swapAmount,
            quote * 95 / 100,
            newUser,
            block.timestamp + 300
        );
        vm.stopPrank();

        assertGt(xautReceived, 0);
        assertEq(xaut.balanceOf(newUser), xautReceived);

        // Step 4: User deposits XAUT into GoldVault for yield
        vm.startPrank(newUser);
        xaut.approve(address(goldVault), xautReceived);
        uint256 shares = goldVault.deposit(xautReceived, newUser);
        vm.stopPrank();

        assertGt(shares, 0);
        assertEq(goldVault.balanceOf(newUser), shares);
        assertEq(xaut.balanceOf(newUser), 0);

        // Verify user successfully onboarded with gXAUT position
        assertTrue(goldVault.balanceOf(newUser) > 0);
    }

    /*==============================================================
            2.2 Swap Flow: IDRX → XAUT → Vault
    ==============================================================*/

    function test_Integration_IDRXToXAUTToVault() public {
        uint256 initialIDRX = 10000 * DECIMALS;

        // User starts with IDRX
        idrx.publicMint(user1, initialIDRX);
        uint256 totalIDRX = idrx.balanceOf(user1);

        // Swap IDRX to XAUT
        uint256 swapAmount = 5000 * DECIMALS;
        uint256 quote = swapRouter.getQuoteIDRXtoXAUT(swapAmount);

        vm.startPrank(user1);
        idrx.approve(address(swapRouter), swapAmount);
        uint256 xautReceived = swapRouter.swapIDRXtoXAUT(
            swapAmount,
            quote * 95 / 100,
            user1,
            block.timestamp + 300
        );
        vm.stopPrank();

        // Verify IDRX deducted
        assertEq(idrx.balanceOf(user1), totalIDRX - swapAmount);

        // Deposit XAUT to vault
        uint256 xautBalance = xaut.balanceOf(user1);

        vm.startPrank(user1);
        xaut.approve(address(goldVault), xautReceived);
        uint256 shares = goldVault.deposit(xautReceived, user1);
        vm.stopPrank();

        // Verify vault position
        assertEq(goldVault.balanceOf(user1), shares);
        assertEq(xaut.balanceOf(user1), xautBalance - xautReceived);
    }

    /*==============================================================
            2.3 Withdraw Flow: Vault → XAUT → IDRX
    ==============================================================*/

    function test_Integration_VaultToXAUTToIDRX() public {
        // Setup: User has gXAUT in vault
        uint256 depositAmount = 100 * DECIMALS;

        vm.startPrank(user1);
        xaut.approve(address(goldVault), depositAmount);
        uint256 shares = goldVault.deposit(depositAmount, user1);
        vm.stopPrank();

        // Withdraw from vault
        vm.startPrank(user1);
        uint256 withdrawnXAUT = goldVault.redeem(shares, user1, user1);
        vm.stopPrank();

        assertGt(withdrawnXAUT, 0);

        // Swap XAUT back to IDRX
        uint256 quote = swapRouter.getQuoteXAUTtoIDRX(withdrawnXAUT);
        uint256 initialIDRX = idrx.balanceOf(user1);

        vm.startPrank(user1);
        xaut.approve(address(swapRouter), withdrawnXAUT);
        uint256 idrxReceived = swapRouter.swapXAUTtoIDRX(
            withdrawnXAUT,
            quote * 95 / 100,
            user1,
            block.timestamp + 300
        );
        vm.stopPrank();

        assertGt(idrxReceived, 0);
        assertEq(idrx.balanceOf(user1), initialIDRX + idrxReceived);
    }

    /*==============================================================
            2.4 Compliance Flow: Transfer Restrictions
    ==============================================================*/

    function test_Integration_ComplianceRestrictions() public {
        // Unverified user cannot receive XAUT
        vm.prank(user1);
        vm.expectRevert("XAUT: recipient not verified");
        xaut.transfer(unverifiedUser, 10 * DECIMALS);

        // Unverified user cannot deposit to vault (even if somehow has XAUT)
        vm.prank(admin);
        identityRegistry.registerIdentity(unverifiedUser);
        xaut.mint(unverifiedUser, 100 * DECIMALS);

        vm.prank(admin);
        identityRegistry.removeIdentity(unverifiedUser);

        vm.startPrank(unverifiedUser);
        xaut.approve(address(goldVault), 100 * DECIMALS);
        vm.expectRevert("GoldVault: account not verified");
        goldVault.deposit(100 * DECIMALS, unverifiedUser);
        vm.stopPrank();
    }

    /*==============================================================
            2.5 Multi-User Vault Interaction
    ==============================================================*/

    function test_Integration_MultiUserVault() public {
        uint256 deposit1 = 100 * DECIMALS;
        uint256 deposit2 = 200 * DECIMALS;

        // User1 deposits
        vm.startPrank(user1);
        xaut.approve(address(goldVault), deposit1);
        uint256 shares1 = goldVault.deposit(deposit1, user1);
        vm.stopPrank();

        // User2 deposits
        vm.startPrank(user2);
        xaut.approve(address(goldVault), deposit2);
        uint256 shares2 = goldVault.deposit(deposit2, user2);
        vm.stopPrank();

        // Verify total assets
        assertEq(goldVault.totalAssets(), deposit1 + deposit2);

        // Verify individual shares
        assertEq(goldVault.balanceOf(user1), shares1);
        assertEq(goldVault.balanceOf(user2), shares2);

        // User1 withdraws half
        vm.startPrank(user1);
        goldVault.redeem(shares1 / 2, user1, user1);
        vm.stopPrank();

        // User2's position should be unaffected
        assertEq(goldVault.balanceOf(user2), shares2);
    }

    /*==============================================================
            2.6 Emergency Scenarios
    ==============================================================*/

    function test_Integration_PauseUnpause() public {
        // Pause XAUT transfers
        xaut.pause();

        // User cannot swap IDRX to XAUT (because final transfer would fail)
        uint256 swapAmount = 1000 * DECIMALS;
        uint256 quote = swapRouter.getQuoteIDRXtoXAUT(swapAmount);

        vm.startPrank(user1);
        idrx.approve(address(swapRouter), swapAmount);
        vm.expectRevert();
        swapRouter.swapIDRXtoXAUT(
            swapAmount,
            quote * 95 / 100,
            user1,
            block.timestamp + 300
        );
        vm.stopPrank();

        // Unpause
        xaut.unpause();

        // Now swap should work
        vm.startPrank(user1);
        uint256 amountOut = swapRouter.swapIDRXtoXAUT(
            swapAmount,
            quote * 95 / 100,
            user1,
            block.timestamp + 300
        );
        vm.stopPrank();

        assertGt(amountOut, 0);
    }

    function test_Integration_KYCRevocation() public {
        // User1 deposits into vault
        uint256 depositAmount = 100 * DECIMALS;

        vm.startPrank(user1);
        xaut.approve(address(goldVault), depositAmount);
        uint256 shares = goldVault.deposit(depositAmount, user1);
        vm.stopPrank();

        // Admin revokes user1's KYC
        vm.prank(admin);
        identityRegistry.removeIdentity(user1);

        // User1 cannot withdraw (receiver not verified)
        vm.startPrank(user1);
        vm.expectRevert("GoldVault: account not verified");
        goldVault.redeem(shares, user1, user1);
        vm.stopPrank();

        // User1 cannot transfer XAUT
        vm.prank(user1);
        vm.expectRevert("XAUT: sender not verified");
        xaut.transfer(user2, 10 * DECIMALS);
    }

    /*==============================================================
            2.7 Round-Trip Test
    ==============================================================*/

    function test_Integration_FullRoundTrip() public {
        address testUser = address(0x999);
        uint256 startingIDRX = 100000 * DECIMALS;

        // Register user
        vm.prank(admin);
        identityRegistry.registerIdentity(testUser);

        // Give user IDRX
        idrx.publicMint(testUser, startingIDRX);

        // 1. Swap IDRX → XAUT
        uint256 swapAmount = 50000 * DECIMALS;
        uint256 quote1 = swapRouter.getQuoteIDRXtoXAUT(swapAmount);

        vm.startPrank(testUser);
        idrx.approve(address(swapRouter), swapAmount);
        uint256 xautReceived = swapRouter.swapIDRXtoXAUT(
            swapAmount,
            quote1 * 90 / 100,
            testUser,
            block.timestamp + 300
        );
        vm.stopPrank();

        // 2. Deposit XAUT → Vault
        vm.startPrank(testUser);
        xaut.approve(address(goldVault), xautReceived);
        uint256 shares = goldVault.deposit(xautReceived, testUser);
        vm.stopPrank();

        // 3. Withdraw Vault → XAUT
        vm.startPrank(testUser);
        uint256 xautWithdrawn = goldVault.redeem(shares, testUser, testUser);
        vm.stopPrank();

        // 4. Swap XAUT → IDRX
        uint256 quote2 = swapRouter.getQuoteXAUTtoIDRX(xautWithdrawn);

        vm.startPrank(testUser);
        xaut.approve(address(swapRouter), xautWithdrawn);
        swapRouter.swapXAUTtoIDRX(
            xautWithdrawn,
            quote2 * 90 / 100,
            testUser,
            block.timestamp + 300
        );
        vm.stopPrank();

        // Final balance check
        uint256 finalIDRX = idrx.balanceOf(testUser);

        // Should have some IDRX back (accounting for slippage/fees)
        assertGt(finalIDRX, startingIDRX - swapAmount);

        // No remaining vault shares
        assertEq(goldVault.balanceOf(testUser), 0);
    }

    /*==============================================================
            2.8 Batch Operations
    ==============================================================*/

    function test_Integration_BatchKYCAndDeposits() public {
        // Create batch of users
        address[] memory newUsers = new address[](5);
        for (uint256 i = 0; i < 5; i++) {
            newUsers[i] = address(uint160(1000 + i));
        }

        // Batch register
        vm.prank(admin);
        identityRegistry.batchRegisterIdentity(newUsers);

        // Verify all registered
        for (uint256 i = 0; i < 5; i++) {
            assertTrue(identityRegistry.isVerified(newUsers[i]));
        }

        // Each user deposits to vault
        for (uint256 i = 0; i < 5; i++) {
            xaut.mint(newUsers[i], 100 * DECIMALS);

            vm.startPrank(newUsers[i]);
            xaut.approve(address(goldVault), 100 * DECIMALS);
            goldVault.deposit(100 * DECIMALS, newUsers[i]);
            vm.stopPrank();

            assertGt(goldVault.balanceOf(newUsers[i]), 0);
        }

        // Verify total assets
        assertGe(goldVault.totalAssets(), 500 * DECIMALS);
    }
}
