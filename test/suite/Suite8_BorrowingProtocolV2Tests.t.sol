// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Suite8_BorrowingProtocolV2Tests
 * @notice Integration tests for BorrowingProtocolV2 on Base Sepolia
 * @dev Fork-based tests interacting with deployed contracts
 * 
 * Run with:
 *   forge test --match-contract Suite8_BorrowingProtocolV2Tests -vvv --fork-url $BASE_SEPOLIA_RPC
 */

// Interfaces
interface IBorrowingProtocolV2 {
    function depositAndBorrow(uint256 collateralAmount, uint256 borrowAmount) external;
    function repayAndWithdraw(uint256 repayAmount, uint256 withdrawAmount) external;
    function closePosition() external;
    function depositCollateral(uint256 amount) external;
    function withdrawCollateral(uint256 amount) external;
    function borrow(uint256 amount) external;
    function repay(uint256 amount) external;
    function repayFull() external;
    
    function previewDepositAndBorrow(address user, uint256 collateral, uint256 borrow) external view 
        returns (uint256 amountReceived, uint256 fee, uint256 newLTV, bool allowed);
    function previewRepayAndWithdraw(address user, uint256 repay, uint256 withdraw) external view 
        returns (bool success, uint256 newLTV);
    function previewBorrow(address user, uint256 amount) external view 
        returns (uint256 received, uint256 fee, uint256 newLTV);
    function previewWithdraw(address user, uint256 amount) external view 
        returns (bool success, uint256 newLTV);
    
    function collateralBalance(address user) external view returns (uint256);
    function debtBalance(address user) external view returns (uint256);
    function getLTV(address user) external view returns (uint256);
    function getCollateral(address user) external view returns (uint256);
    function getDebt(address user) external view returns (uint256);
    function getCollateralValue(address user) external view returns (uint256);
    function getMaxBorrow(address user) external view returns (uint256);
    function getHealthFactor(address user) external view returns (uint256);
    
    function xautPriceInIDRX() external view returns (uint256);
    function borrowFeeBps() external view returns (uint256);
    function admin() external view returns (address);
    function treasury() external view returns (address);
    
    function MAX_LTV() external view returns (uint256);
    function WARNING_LTV() external view returns (uint256);
    function LIQUIDATION_LTV() external view returns (uint256);
    
    function updatePrice(uint256 newPrice) external;
    function setBorrowFee(uint256 newFeeBps) external;
    function setTreasury(address newTreasury) external;
}

interface IIdentityRegistry {
    function isVerified(address user) external view returns (bool);
    function registerIdentity(address user) external;
    function removeIdentity(address user) external;
}

interface IMockToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function publicMint(address to, uint256 amount) external;
}

interface IXAUT is IERC20 {
    function mint(address to, uint256 amount) external;
}

contract Suite8_BorrowingProtocolV2Tests is Test {
    // ========================================
    // DEPLOYED CONTRACT ADDRESSES (Base Sepolia)
    // ========================================
    
    address constant MOCK_IDRX = 0x998ceb700e57f535873D189a6b1B7E2aA8C594EB;
    address constant MOCK_USDC = 0xCd88C2886A1958BA36238A070e71B51CF930b44d;
    address constant XAUT_TOKEN = 0x56EeDF50c3C4B47Ca9762298B22Cb86468f834FC;
    address constant IDENTITY_REGISTRY = 0xA8F2b8180caFC670f4a24114FDB9c50361038857;
    address constant BORROWING_PROTOCOL_V2 = 0x3A1229F6D51940DBa65710F9F6ab0296FD56718B;
    
    // Network Configuration
    uint256 constant BASE_SEPOLIA_CHAIN_ID = 84532;
    string constant BASE_SEPOLIA_RPC = "https://sepolia.base.org";
    address constant DEPLOYER = 0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1;
    
    // Test amounts (6 decimals)
    uint256 constant ONE_XAUT = 1_000_000;      // 1 XAUT
    uint256 constant TEN_XAUT = 10_000_000;     // 10 XAUT
    uint256 constant ONE_M_IDRX = 1_000_000_000_000;    // 1M IDRX
    uint256 constant THIRTY_M_IDRX = 30_000_000_000_000; // 30M IDRX
    uint256 constant FORTY_M_IDRX = 40_000_000_000_000;  // 40M IDRX
    
    // ========================================
    // CONTRACT INSTANCES
    // ========================================
    
    IBorrowingProtocolV2 public protocol;
    IIdentityRegistry public identityRegistry;
    IMockToken public idrx;
    IXAUT public xaut;
    
    // ========================================
    // TEST ACCOUNTS
    // ========================================
    
    address public deployer = DEPLOYER;
    address public alice;
    address public bob;
    address public charlie;
    
    // ========================================
    // SETUP
    // ========================================
    
    function setUp() public {
        // Skip tests if addresses not configured
        if (BORROWING_PROTOCOL_V2 == address(0)) {
            console.log("=== Suite8: SKIPPED (addresses not configured) ===");
            console.log("Fill contract addresses after Base Sepolia deployment");
            return;
        }
        
        // Fork Base Sepolia
        vm.createSelectFork(BASE_SEPOLIA_RPC);
        
        // Verify we're on correct chain
        require(block.chainid == BASE_SEPOLIA_CHAIN_ID, "Wrong chain ID");
        
        // Initialize contract instances
        protocol = IBorrowingProtocolV2(BORROWING_PROTOCOL_V2);
        identityRegistry = IIdentityRegistry(IDENTITY_REGISTRY);
        idrx = IMockToken(MOCK_IDRX);
        xaut = IXAUT(XAUT_TOKEN);
        
        // Create test accounts
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");
        
        // Fund test accounts with ETH (native token)
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(charlie, 100 ether);
        
        // Setup test users
        _setupTestUser(alice);
        _setupTestUser(bob);
        
        console.log("=== Suite8: BorrowingProtocolV2 Test Setup ===");
        console.log("Chain ID:", block.chainid);
        console.log("Block Number:", block.number);
        console.log("Protocol:", address(protocol));
        console.log("Alice:", alice);
        console.log("Bob:", bob);
    }
    
    function _setupTestUser(address user) internal {
        // Register in KYC
        vm.prank(DEPLOYER);
        identityRegistry.registerIdentity(user);
        
        // Mint tokens
        vm.startPrank(DEPLOYER);
        idrx.publicMint(user, 1000 * ONE_M_IDRX);
        xaut.mint(user, 100 * ONE_XAUT);
        vm.stopPrank();
    }
    
    // ========================================
    // MODIFIER: Skip if not configured
    // ========================================
    
    modifier skipIfNotConfigured() {
        if (BORROWING_PROTOCOL_V2 == address(0)) {
            console.log("Test skipped: addresses not configured");
            return;
        }
        _;
    }
    
    // ========================================
    // SUITE 8.1: BASIC OPERATIONS
    // ========================================
    
    function test_DepositAndBorrow_Success() public skipIfNotConfigured {
        console.log("=== Test: DepositAndBorrow Success ===");
        
        uint256 collateralAmount = TEN_XAUT;
        uint256 borrowAmount = THIRTY_M_IDRX;
        
        vm.startPrank(alice);
        xaut.approve(address(protocol), collateralAmount);
        
        uint256 xautBefore = xaut.balanceOf(alice);
        uint256 idrxBefore = idrx.balanceOf(alice);
        
        protocol.depositAndBorrow(collateralAmount, borrowAmount);
        vm.stopPrank();
        
        // Calculate expected values
        uint256 fee = (borrowAmount * protocol.borrowFeeBps()) / 10000;
        uint256 expectedReceived = borrowAmount - fee;
        
        // Verify collateral deposited
        assertEq(protocol.collateralBalance(alice), collateralAmount, "Collateral not deposited");
        assertEq(xaut.balanceOf(alice), xautBefore - collateralAmount, "XAUT not transferred");
        
        // Verify debt created
        assertEq(protocol.debtBalance(alice), borrowAmount, "Debt not recorded");
        
        // Verify IDRX received (minus fee)
        assertEq(idrx.balanceOf(alice), idrxBefore + expectedReceived, "IDRX not received");
        
        // Verify LTV
        uint256 ltv = protocol.getLTV(alice);
        assertTrue(ltv > 0 && ltv <= protocol.MAX_LTV(), "LTV out of range");
        
        console.log("Collateral:", collateralAmount);
        console.log("Borrowed:", borrowAmount);
        console.log("Fee:", fee);
        console.log("LTV:", ltv);
        console.log("=== PASSED ===");
    }
    
    function test_RepayAndWithdraw_Success() public skipIfNotConfigured {
        console.log("=== Test: RepayAndWithdraw Success ===");
        
        // Setup: deposit and borrow first
        vm.startPrank(alice);
        xaut.approve(address(protocol), TEN_XAUT);
        protocol.depositAndBorrow(TEN_XAUT, THIRTY_M_IDRX);
        
        // Approve IDRX for repayment
        idrx.approve(address(protocol), THIRTY_M_IDRX);
        
        // Repay half and withdraw some
        uint256 repayAmount = 15 * ONE_M_IDRX;
        uint256 withdrawAmount = 3 * ONE_XAUT;
        
        uint256 xautBefore = xaut.balanceOf(alice);
        
        protocol.repayAndWithdraw(repayAmount, withdrawAmount);
        vm.stopPrank();
        
        // Verify debt reduced
        assertEq(protocol.debtBalance(alice), THIRTY_M_IDRX - repayAmount, "Debt not reduced");
        
        // Verify collateral reduced
        assertEq(protocol.collateralBalance(alice), TEN_XAUT - withdrawAmount, "Collateral not reduced");
        
        // Verify XAUT received
        assertEq(xaut.balanceOf(alice), xautBefore + withdrawAmount, "XAUT not received");
        
        console.log("Repaid:", repayAmount);
        console.log("Withdrawn:", withdrawAmount);
        console.log("Remaining debt:", protocol.debtBalance(alice));
        console.log("Remaining collateral:", protocol.collateralBalance(alice));
        console.log("=== PASSED ===");
    }
    
    function test_ClosePosition_Success() public skipIfNotConfigured {
        console.log("=== Test: ClosePosition Success ===");
        
        vm.startPrank(alice);
        xaut.approve(address(protocol), TEN_XAUT);
        protocol.depositAndBorrow(TEN_XAUT, THIRTY_M_IDRX);
        
        idrx.approve(address(protocol), THIRTY_M_IDRX);
        
        uint256 xautBefore = xaut.balanceOf(alice);
        
        protocol.closePosition();
        vm.stopPrank();
        
        // Position should be fully closed
        assertEq(protocol.debtBalance(alice), 0, "Debt should be zero");
        assertEq(protocol.collateralBalance(alice), 0, "Collateral should be zero");
        
        // User should have received all collateral back
        assertEq(xaut.balanceOf(alice), xautBefore + TEN_XAUT, "XAUT not returned");
        
        console.log("Position closed successfully");
        console.log("XAUT returned:", TEN_XAUT);
        console.log("=== PASSED ===");
    }
    
    // ========================================
    // SUITE 8.2: PREVIEW FUNCTIONS
    // ========================================
    
    function test_PreviewDepositAndBorrow() public skipIfNotConfigured {
        console.log("=== Test: PreviewDepositAndBorrow ===");
        
        uint256 collateralAmount = TEN_XAUT;
        uint256 borrowAmount = THIRTY_M_IDRX;
        
        (
            uint256 amountReceived,
            uint256 fee,
            uint256 newLTV,
            bool allowed
        ) = protocol.previewDepositAndBorrow(alice, collateralAmount, borrowAmount);
        
        uint256 expectedFee = (borrowAmount * protocol.borrowFeeBps()) / 10000;
        assertEq(fee, expectedFee, "Fee calculation incorrect");
        assertEq(amountReceived, borrowAmount - expectedFee, "Amount received incorrect");
        assertTrue(newLTV > 0 && newLTV <= protocol.MAX_LTV(), "LTV out of range");
        assertTrue(allowed, "Should be allowed");
        
        console.log("Amount received:", amountReceived);
        console.log("Fee:", fee);
        console.log("New LTV:", newLTV);
        console.log("Allowed:", allowed);
        console.log("=== PASSED ===");
    }
    
    function test_PreviewRepayAndWithdraw() public skipIfNotConfigured {
        console.log("=== Test: PreviewRepayAndWithdraw ===");
        
        // Setup position
        vm.startPrank(alice);
        xaut.approve(address(protocol), TEN_XAUT);
        protocol.depositAndBorrow(TEN_XAUT, THIRTY_M_IDRX);
        vm.stopPrank();
        
        // Preview repay and withdraw
        uint256 repayAmount = 15 * ONE_M_IDRX;
        uint256 withdrawAmount = 3 * ONE_XAUT;
        
        (bool success, uint256 newLTV) = protocol.previewRepayAndWithdraw(
            alice, repayAmount, withdrawAmount
        );
        
        assertTrue(newLTV <= protocol.MAX_LTV(), "LTV should be valid");
        assertTrue(success, "Should be allowed");
        
        console.log("Success:", success);
        console.log("New LTV:", newLTV);
        console.log("=== PASSED ===");
    }
    
    // ========================================
    // SUITE 8.3: LTV MANAGEMENT
    // ========================================
    
    function test_MaxLTV_Boundary() public skipIfNotConfigured {
        console.log("=== Test: MaxLTV Boundary ===");
        
        uint256 collateralAmount = TEN_XAUT;
        // Calculate max borrow at 75% LTV
        uint256 collateralValue = (collateralAmount * protocol.xautPriceInIDRX()) / 1e8;
        uint256 maxBorrow = (collateralValue * protocol.MAX_LTV()) / 10000;
        
        vm.startPrank(alice);
        xaut.approve(address(protocol), collateralAmount);
        
        // Should succeed at exactly 75% LTV
        protocol.depositAndBorrow(collateralAmount, maxBorrow);
        vm.stopPrank();
        
        uint256 ltv = protocol.getLTV(alice);
        assertApproxEqAbs(ltv, protocol.MAX_LTV(), 10, "LTV should be ~75%");
        
        console.log("Collateral value:", collateralValue);
        console.log("Max borrow:", maxBorrow);
        console.log("Actual LTV:", ltv);
        console.log("=== PASSED ===");
    }
    
    function test_ExceedsLTV_Reverts() public skipIfNotConfigured {
        console.log("=== Test: ExceedsLTV Reverts ===");
        
        uint256 collateralAmount = ONE_XAUT; // 1 XAUT = ~66M IDRX value
        uint256 borrowAmount = 60 * ONE_M_IDRX; // 60M IDRX = ~90% LTV
        
        vm.startPrank(alice);
        xaut.approve(address(protocol), collateralAmount);
        
        vm.expectRevert("LTV exceeds maximum");
        protocol.depositAndBorrow(collateralAmount, borrowAmount);
        vm.stopPrank();
        
        console.log("Correctly reverted for exceeding LTV");
        console.log("=== PASSED ===");
    }
    
    // ========================================
    // SUITE 8.4: ACCESS CONTROL
    // ========================================
    
    function test_RevertIfNotVerified() public skipIfNotConfigured {
        console.log("=== Test: RevertIfNotVerified ===");
        
        // Charlie is not verified
        assertFalse(identityRegistry.isVerified(charlie), "Charlie should not be verified");
        
        // Mint tokens to charlie (bypassing KYC for test)
        vm.prank(DEPLOYER);
        idrx.publicMint(charlie, 1000 * ONE_M_IDRX);
        
        vm.startPrank(charlie);
        xaut.approve(address(protocol), TEN_XAUT);
        
        vm.expectRevert("Not verified");
        protocol.depositAndBorrow(TEN_XAUT, THIRTY_M_IDRX);
        vm.stopPrank();
        
        console.log("Correctly reverted for unverified user");
        console.log("=== PASSED ===");
    }
    
    // ========================================
    // SUITE 8.5: EDGE CASES
    // ========================================
    
    function test_ZeroAmounts_Revert() public skipIfNotConfigured {
        console.log("=== Test: ZeroAmounts Revert ===");
        
        vm.startPrank(alice);
        
        // Zero collateral
        vm.expectRevert("Collateral must be > 0");
        protocol.depositAndBorrow(0, THIRTY_M_IDRX);
        
        // Zero borrow
        xaut.approve(address(protocol), TEN_XAUT);
        vm.expectRevert("Borrow amount must be > 0");
        protocol.depositAndBorrow(TEN_XAUT, 0);
        
        vm.stopPrank();
        
        console.log("Correctly reverted for zero amounts");
        console.log("=== PASSED ===");
    }
    
    function test_RepayAndWithdraw_BothZero_Reverts() public skipIfNotConfigured {
        console.log("=== Test: RepayAndWithdraw BothZero Reverts ===");
        
        vm.startPrank(alice);
        xaut.approve(address(protocol), TEN_XAUT);
        protocol.depositCollateral(TEN_XAUT);
        
        vm.expectRevert("Both amounts cannot be zero");
        protocol.repayAndWithdraw(0, 0);
        vm.stopPrank();
        
        console.log("Correctly reverted for both zero amounts");
        console.log("=== PASSED ===");
    }
    
    // ========================================
    // SUITE 8.6: FEE CALCULATION
    // ========================================
    
    function test_BorrowFee_Calculation() public skipIfNotConfigured {
        console.log("=== Test: BorrowFee Calculation ===");
        
        uint256 borrowAmount = 100 * ONE_M_IDRX; // 100M IDRX
        uint256 feeBps = protocol.borrowFeeBps();
        uint256 expectedFee = (borrowAmount * feeBps) / 10000;
        
        vm.startPrank(alice);
        xaut.approve(address(protocol), 50 * ONE_XAUT);
        
        uint256 idrxBefore = idrx.balanceOf(alice);
        protocol.depositAndBorrow(50 * ONE_XAUT, borrowAmount);
        uint256 idrxAfter = idrx.balanceOf(alice);
        
        uint256 actualReceived = idrxAfter - idrxBefore;
        assertEq(actualReceived, borrowAmount - expectedFee, "Fee calculation incorrect");
        
        vm.stopPrank();
        
        console.log("Borrow amount:", borrowAmount);
        console.log("Fee bps:", feeBps);
        console.log("Expected fee:", expectedFee);
        console.log("Actual received:", actualReceived);
        console.log("=== PASSED ===");
    }
    
    // ========================================
    // SUITE 8.7: MULTI-USER
    // ========================================
    
    function test_MultipleUsers_IndependentPositions() public skipIfNotConfigured {
        console.log("=== Test: MultipleUsers IndependentPositions ===");
        
        // Alice deposits and borrows
        vm.startPrank(alice);
        xaut.approve(address(protocol), TEN_XAUT);
        protocol.depositAndBorrow(TEN_XAUT, 20 * ONE_M_IDRX);
        vm.stopPrank();
        
        // Bob deposits and borrows
        vm.startPrank(bob);
        xaut.approve(address(protocol), 5 * ONE_XAUT);
        protocol.depositAndBorrow(5 * ONE_XAUT, 10 * ONE_M_IDRX);
        vm.stopPrank();
        
        // Verify independent positions
        assertEq(protocol.collateralBalance(alice), TEN_XAUT, "Alice collateral");
        assertEq(protocol.debtBalance(alice), 20 * ONE_M_IDRX, "Alice debt");
        
        assertEq(protocol.collateralBalance(bob), 5 * ONE_XAUT, "Bob collateral");
        assertEq(protocol.debtBalance(bob), 10 * ONE_M_IDRX, "Bob debt");
        
        // Alice closes position
        vm.startPrank(alice);
        idrx.approve(address(protocol), 20 * ONE_M_IDRX);
        protocol.closePosition();
        vm.stopPrank();
        
        // Bob should be unaffected
        assertEq(protocol.collateralBalance(bob), 5 * ONE_XAUT, "Bob collateral unchanged");
        assertEq(protocol.debtBalance(bob), 10 * ONE_M_IDRX, "Bob debt unchanged");
        
        console.log("Alice position closed, Bob unaffected");
        console.log("=== PASSED ===");
    }
    
    // ========================================
    // SUITE 8.8: V1 COMPATIBILITY
    // ========================================
    
    function test_V1Functions_StillWork() public skipIfNotConfigured {
        console.log("=== Test: V1Functions StillWork ===");
        
        vm.startPrank(alice);
        xaut.approve(address(protocol), TEN_XAUT * 2);
        
        // V1: depositCollateral
        protocol.depositCollateral(TEN_XAUT);
        assertEq(protocol.getCollateral(alice), TEN_XAUT);
        
        // V1: borrow
        protocol.borrow(20 * ONE_M_IDRX);
        assertEq(protocol.getDebt(alice), 20 * ONE_M_IDRX);
        
        // V1: repay
        idrx.approve(address(protocol), 100 * ONE_M_IDRX);
        protocol.repay(5 * ONE_M_IDRX);
        assertEq(protocol.getDebt(alice), 15 * ONE_M_IDRX);
        
        // V1: withdrawCollateral
        protocol.withdrawCollateral(2 * ONE_XAUT);
        assertEq(protocol.getCollateral(alice), 8 * ONE_XAUT);
        
        // V1: repayFull
        protocol.repayFull();
        assertEq(protocol.getDebt(alice), 0);
        
        vm.stopPrank();
        
        console.log("All V1 functions work correctly");
        console.log("=== PASSED ===");
    }
    
    // ========================================
    // SUITE 8.9: PRICE UPDATE
    // ========================================
    
    function test_UpdatePrice_RevertIfNotAdmin() public skipIfNotConfigured {
        console.log("=== Test: UpdatePrice RevertIfNotAdmin ===");
        
        vm.prank(alice);
        vm.expectRevert(); // Contract reverts without specific message
        protocol.updatePrice(7_000_000_000_000_000);
        
        console.log("Correctly reverted for non-admin price update");
        console.log("=== PASSED ===");
    }
    
    // ========================================
    // SUITE 8.10: VIEW FUNCTIONS
    // ========================================
    
    function test_ViewFunctions() public skipIfNotConfigured {
        console.log("=== Test: ViewFunctions ===");
        
        vm.startPrank(alice);
        xaut.approve(address(protocol), TEN_XAUT);
        protocol.depositAndBorrow(TEN_XAUT, THIRTY_M_IDRX);
        vm.stopPrank();
        
        // Test all view functions
        assertEq(protocol.getCollateral(alice), TEN_XAUT);
        assertEq(protocol.getDebt(alice), THIRTY_M_IDRX);
        assertTrue(protocol.getCollateralValue(alice) > 0);
        assertTrue(protocol.getLTV(alice) > 0);
        assertTrue(protocol.getHealthFactor(alice) > 0);
        
        console.log("Collateral:", protocol.getCollateral(alice));
        console.log("Debt:", protocol.getDebt(alice));
        console.log("Collateral Value:", protocol.getCollateralValue(alice));
        console.log("LTV:", protocol.getLTV(alice));
        console.log("Health Factor:", protocol.getHealthFactor(alice));
        console.log("=== PASSED ===");
    }
    
    // ========================================
    // SUITE 8.11: PROTOCOL PARAMETERS
    // ========================================
    
    function test_ProtocolParameters() public skipIfNotConfigured {
        console.log("=== Test: ProtocolParameters ===");
        
        assertEq(protocol.MAX_LTV(), 7500, "MAX_LTV should be 75%");
        assertEq(protocol.WARNING_LTV(), 8000, "WARNING_LTV should be 80%");
        assertEq(protocol.LIQUIDATION_LTV(), 9000, "LIQUIDATION_LTV should be 90%");
        assertEq(protocol.borrowFeeBps(), 50, "Borrow fee should be 0.5%");
        assertTrue(protocol.xautPriceInIDRX() > 0, "XAUT price should be set");
        assertTrue(protocol.admin() != address(0), "Admin should be set");
        assertTrue(protocol.treasury() != address(0), "Treasury should be set");
        
        console.log("MAX_LTV:", protocol.MAX_LTV());
        console.log("WARNING_LTV:", protocol.WARNING_LTV());
        console.log("LIQUIDATION_LTV:", protocol.LIQUIDATION_LTV());
        console.log("Borrow Fee:", protocol.borrowFeeBps(), "bps");
        console.log("XAUT Price:", protocol.xautPriceInIDRX());
        console.log("Admin:", protocol.admin());
        console.log("Treasury:", protocol.treasury());
        console.log("=== PASSED ===");
    }
}
