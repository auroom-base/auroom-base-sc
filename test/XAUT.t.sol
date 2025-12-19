// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/XAUT.sol";
import "../src/IdentityRegistry.sol";

contract XAUTTest is Test {
    XAUT public xaut;
    IdentityRegistry public identityRegistry;

    address public owner;
    address public verifiedUser1;
    address public verifiedUser2;
    address public unverifiedUser;

    event IdentityRegistryUpdated(address indexed oldRegistry, address indexed newRegistry);

    function setUp() public {
        owner = address(this);
        verifiedUser1 = makeAddr("verifiedUser1");
        verifiedUser2 = makeAddr("verifiedUser2");
        unverifiedUser = makeAddr("unverifiedUser");

        // Deploy IdentityRegistry
        identityRegistry = new IdentityRegistry();

        // Deploy XAUT
        xaut = new XAUT(address(identityRegistry));

        // Register verified users (owner is admin by default)
        identityRegistry.registerIdentity(verifiedUser1);
        identityRegistry.registerIdentity(verifiedUser2);
    }

    // ============ Constructor Tests ============

    function test_Constructor() public view {
        assertEq(xaut.name(), "Mock Tether Gold");
        assertEq(xaut.symbol(), "XAUT");
        assertEq(xaut.decimals(), 6);
        assertEq(address(xaut.identityRegistry()), address(identityRegistry));
        assertEq(xaut.owner(), owner);
    }

    function test_RevertConstructor_InvalidRegistry() public {
        vm.expectRevert("XAUT: invalid registry address");
        new XAUT(address(0));
    }

    // ============ Mint Tests ============

    function test_Mint() public {
        uint256 amount = 100 * 10 ** 6; // 100 XAUT

        xaut.mint(verifiedUser1, amount);

        assertEq(xaut.balanceOf(verifiedUser1), amount);
        assertEq(xaut.totalSupply(), amount);
    }

    function test_RevertMint_NotOwner() public {
        vm.prank(verifiedUser1);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", verifiedUser1));
        xaut.mint(verifiedUser1, 100 * 10 ** 6);
    }

    function test_RevertMint_RecipientNotVerified() public {
        vm.expectRevert("XAUT: recipient not verified");
        xaut.mint(unverifiedUser, 100 * 10 ** 6);
    }

    // ============ Burn Tests ============

    function test_Burn() public {
        uint256 amount = 100 * 10 ** 6;
        xaut.mint(verifiedUser1, amount);

        xaut.burn(verifiedUser1, 50 * 10 ** 6);

        assertEq(xaut.balanceOf(verifiedUser1), 50 * 10 ** 6);
        assertEq(xaut.totalSupply(), 50 * 10 ** 6);
    }

    function test_RevertBurn_NotOwner() public {
        uint256 amount = 100 * 10 ** 6;
        xaut.mint(verifiedUser1, amount);

        vm.prank(verifiedUser1);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", verifiedUser1));
        xaut.burn(verifiedUser1, 50 * 10 ** 6);
    }

    function test_RevertBurn_InsufficientBalance() public {
        uint256 amount = 100 * 10 ** 6;
        xaut.mint(verifiedUser1, amount);

        vm.expectRevert(abi.encodeWithSignature("ERC20InsufficientBalance(address,uint256,uint256)", verifiedUser1, amount, 150 * 10 ** 6));
        xaut.burn(verifiedUser1, 150 * 10 ** 6);
    }

    // ============ Transfer Tests ============

    function test_Transfer() public {
        uint256 amount = 100 * 10 ** 6;
        xaut.mint(verifiedUser1, amount);

        vm.prank(verifiedUser1);
        bool success = xaut.transfer(verifiedUser2, 50 * 10 ** 6);

        assertTrue(success);
        assertEq(xaut.balanceOf(verifiedUser1), 50 * 10 ** 6);
        assertEq(xaut.balanceOf(verifiedUser2), 50 * 10 ** 6);
    }

    function test_RevertTransfer_SenderNotVerified() public {
        // Mint to verified user, then remove verification
        uint256 amount = 100 * 10 ** 6;
        xaut.mint(verifiedUser1, amount);
        identityRegistry.removeIdentity(verifiedUser1);

        vm.prank(verifiedUser1);
        vm.expectRevert("XAUT: sender not verified");
        xaut.transfer(verifiedUser2, 50 * 10 ** 6);
    }

    function test_RevertTransfer_RecipientNotVerified() public {
        uint256 amount = 100 * 10 ** 6;
        xaut.mint(verifiedUser1, amount);

        vm.prank(verifiedUser1);
        vm.expectRevert("XAUT: recipient not verified");
        xaut.transfer(unverifiedUser, 50 * 10 ** 6);
    }

    function test_RevertTransfer_WhenPaused() public {
        uint256 amount = 100 * 10 ** 6;
        xaut.mint(verifiedUser1, amount);
        xaut.pause();

        vm.prank(verifiedUser1);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        xaut.transfer(verifiedUser2, 50 * 10 ** 6);
    }

    function test_RevertTransfer_InsufficientBalance() public {
        uint256 amount = 100 * 10 ** 6;
        xaut.mint(verifiedUser1, amount);

        vm.prank(verifiedUser1);
        vm.expectRevert(abi.encodeWithSignature("ERC20InsufficientBalance(address,uint256,uint256)", verifiedUser1, amount, 150 * 10 ** 6));
        xaut.transfer(verifiedUser2, 150 * 10 ** 6);
    }

    // ============ TransferFrom Tests ============

    function test_TransferFrom() public {
        uint256 amount = 100 * 10 ** 6;
        xaut.mint(verifiedUser1, amount);

        vm.prank(verifiedUser1);
        xaut.approve(verifiedUser2, 50 * 10 ** 6);

        vm.prank(verifiedUser2);
        bool success = xaut.transferFrom(verifiedUser1, verifiedUser2, 50 * 10 ** 6);

        assertTrue(success);
        assertEq(xaut.balanceOf(verifiedUser1), 50 * 10 ** 6);
        assertEq(xaut.balanceOf(verifiedUser2), 50 * 10 ** 6);
    }

    function test_RevertTransferFrom_FromNotVerified() public {
        uint256 amount = 100 * 10 ** 6;
        xaut.mint(verifiedUser1, amount);

        vm.prank(verifiedUser1);
        xaut.approve(verifiedUser2, 50 * 10 ** 6);

        identityRegistry.removeIdentity(verifiedUser1);

        vm.prank(verifiedUser2);
        vm.expectRevert("XAUT: sender not verified");
        xaut.transferFrom(verifiedUser1, verifiedUser2, 50 * 10 ** 6);
    }

    function test_RevertTransferFrom_ToNotVerified() public {
        uint256 amount = 100 * 10 ** 6;
        xaut.mint(verifiedUser1, amount);

        vm.prank(verifiedUser1);
        xaut.approve(verifiedUser2, 50 * 10 ** 6);

        vm.prank(verifiedUser2);
        vm.expectRevert("XAUT: recipient not verified");
        xaut.transferFrom(verifiedUser1, unverifiedUser, 50 * 10 ** 6);
    }

    function test_RevertTransferFrom_WhenPaused() public {
        uint256 amount = 100 * 10 ** 6;
        xaut.mint(verifiedUser1, amount);

        vm.prank(verifiedUser1);
        xaut.approve(verifiedUser2, 50 * 10 ** 6);

        xaut.pause();

        vm.prank(verifiedUser2);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        xaut.transferFrom(verifiedUser1, verifiedUser2, 50 * 10 ** 6);
    }

    // ============ CanTransfer Tests ============

    function test_CanTransfer_Success() public {
        uint256 amount = 100 * 10 ** 6;
        xaut.mint(verifiedUser1, amount);

        bool canTransfer = xaut.canTransfer(verifiedUser1, verifiedUser2, 50 * 10 ** 6);
        assertTrue(canTransfer);
    }

    function test_CanTransfer_Paused() public {
        uint256 amount = 100 * 10 ** 6;
        xaut.mint(verifiedUser1, amount);
        xaut.pause();

        bool canTransfer = xaut.canTransfer(verifiedUser1, verifiedUser2, 50 * 10 ** 6);
        assertFalse(canTransfer);
    }

    function test_CanTransfer_SenderNotVerified() public {
        uint256 amount = 100 * 10 ** 6;
        xaut.mint(verifiedUser1, amount);
        identityRegistry.removeIdentity(verifiedUser1);

        bool canTransfer = xaut.canTransfer(verifiedUser1, verifiedUser2, 50 * 10 ** 6);
        assertFalse(canTransfer);
    }

    function test_CanTransfer_RecipientNotVerified() public {
        uint256 amount = 100 * 10 ** 6;
        xaut.mint(verifiedUser1, amount);

        bool canTransfer = xaut.canTransfer(verifiedUser1, unverifiedUser, 50 * 10 ** 6);
        assertFalse(canTransfer);
    }

    function test_CanTransfer_InsufficientBalance() public {
        uint256 amount = 100 * 10 ** 6;
        xaut.mint(verifiedUser1, amount);

        bool canTransfer = xaut.canTransfer(verifiedUser1, verifiedUser2, 150 * 10 ** 6);
        assertFalse(canTransfer);
    }

    function test_CanTransfer_Mint() public view {
        // From address(0) means minting - should work
        bool canTransfer = xaut.canTransfer(address(0), verifiedUser1, 100 * 10 ** 6);
        assertTrue(canTransfer);
    }

    function test_CanTransfer_Burn() public {
        // To address(0) means burning - should work if balance sufficient
        uint256 amount = 100 * 10 ** 6;
        xaut.mint(verifiedUser1, amount);

        bool canTransfer = xaut.canTransfer(verifiedUser1, address(0), 50 * 10 ** 6);
        assertTrue(canTransfer);
    }

    // ============ Pause/Unpause Tests ============

    function test_Pause() public {
        xaut.pause();
        assertTrue(xaut.paused());
    }

    function test_Unpause() public {
        xaut.pause();
        xaut.unpause();
        assertFalse(xaut.paused());
    }

    function test_RevertPause_NotOwner() public {
        vm.prank(verifiedUser1);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", verifiedUser1));
        xaut.pause();
    }

    function test_RevertUnpause_NotOwner() public {
        xaut.pause();

        vm.prank(verifiedUser1);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", verifiedUser1));
        xaut.unpause();
    }

    function test_TransferAfterUnpause() public {
        uint256 amount = 100 * 10 ** 6;
        xaut.mint(verifiedUser1, amount);

        xaut.pause();
        xaut.unpause();

        vm.prank(verifiedUser1);
        bool success = xaut.transfer(verifiedUser2, 50 * 10 ** 6);
        assertTrue(success);
    }

    // ============ SetIdentityRegistry Tests ============

    function test_SetIdentityRegistry() public {
        IdentityRegistry newRegistry = new IdentityRegistry();

        vm.expectEmit(true, true, false, false);
        emit IdentityRegistryUpdated(address(identityRegistry), address(newRegistry));

        xaut.setIdentityRegistry(address(newRegistry));

        assertEq(address(xaut.identityRegistry()), address(newRegistry));
    }

    function test_RevertSetIdentityRegistry_InvalidAddress() public {
        vm.expectRevert("XAUT: invalid registry address");
        xaut.setIdentityRegistry(address(0));
    }

    function test_RevertSetIdentityRegistry_NotOwner() public {
        IdentityRegistry newRegistry = new IdentityRegistry();

        vm.prank(verifiedUser1);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", verifiedUser1));
        xaut.setIdentityRegistry(address(newRegistry));
    }

    function test_TransferAfterRegistryUpdate() public {
        // Setup: mint tokens with old registry
        uint256 amount = 100 * 10 ** 6;
        xaut.mint(verifiedUser1, amount);

        // Deploy new registry and verify users
        IdentityRegistry newRegistry = new IdentityRegistry();
        newRegistry.registerIdentity(verifiedUser1);
        newRegistry.registerIdentity(verifiedUser2);

        // Update registry
        xaut.setIdentityRegistry(address(newRegistry));

        // Transfer should work with new registry
        vm.prank(verifiedUser1);
        bool success = xaut.transfer(verifiedUser2, 50 * 10 ** 6);
        assertTrue(success);
    }

    // ============ Fuzz Tests ============

    function testFuzz_Mint(uint256 amount) public {
        vm.assume(amount > 0 && amount <= type(uint256).max);

        xaut.mint(verifiedUser1, amount);
        assertEq(xaut.balanceOf(verifiedUser1), amount);
    }

    function testFuzz_Transfer(uint256 amount) public {
        vm.assume(amount > 0 && amount <= type(uint128).max);

        xaut.mint(verifiedUser1, amount);

        vm.prank(verifiedUser1);
        xaut.transfer(verifiedUser2, amount);

        assertEq(xaut.balanceOf(verifiedUser1), 0);
        assertEq(xaut.balanceOf(verifiedUser2), amount);
    }

    // ============ Integration Tests ============

    function test_CompleteWorkflow() public {
        // 1. Mint tokens to verifiedUser1
        uint256 initialAmount = 1000 * 10 ** 6; // 1000 XAUT
        xaut.mint(verifiedUser1, initialAmount);
        assertEq(xaut.balanceOf(verifiedUser1), initialAmount);

        // 2. Transfer some tokens to verifiedUser2
        vm.prank(verifiedUser1);
        xaut.transfer(verifiedUser2, 300 * 10 ** 6);
        assertEq(xaut.balanceOf(verifiedUser1), 700 * 10 ** 6);
        assertEq(xaut.balanceOf(verifiedUser2), 300 * 10 ** 6);

        // 3. Approve and transferFrom
        vm.prank(verifiedUser1);
        xaut.approve(verifiedUser2, 200 * 10 ** 6);

        vm.prank(verifiedUser2);
        xaut.transferFrom(verifiedUser1, verifiedUser2, 200 * 10 ** 6);
        assertEq(xaut.balanceOf(verifiedUser1), 500 * 10 ** 6);
        assertEq(xaut.balanceOf(verifiedUser2), 500 * 10 ** 6);

        // 4. Burn some tokens
        xaut.burn(verifiedUser1, 100 * 10 ** 6);
        assertEq(xaut.balanceOf(verifiedUser1), 400 * 10 ** 6);
        assertEq(xaut.totalSupply(), 900 * 10 ** 6);

        // 5. Pause and attempt transfer (should fail)
        xaut.pause();
        vm.prank(verifiedUser1);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        xaut.transfer(verifiedUser2, 50 * 10 ** 6);

        // 6. Unpause and transfer (should succeed)
        xaut.unpause();
        vm.prank(verifiedUser1);
        xaut.transfer(verifiedUser2, 50 * 10 ** 6);
        assertEq(xaut.balanceOf(verifiedUser1), 350 * 10 ** 6);
        assertEq(xaut.balanceOf(verifiedUser2), 550 * 10 ** 6);
    }

    function test_ComplianceEnforcement() public {
        uint256 amount = 100 * 10 ** 6;
        xaut.mint(verifiedUser1, amount);

        // Scenario 1: Remove sender verification
        identityRegistry.removeIdentity(verifiedUser1);
        vm.prank(verifiedUser1);
        vm.expectRevert("XAUT: sender not verified");
        xaut.transfer(verifiedUser2, 50 * 10 ** 6);

        // Re-verify sender
        identityRegistry.registerIdentity(verifiedUser1);

        // Scenario 2: Try to transfer to unverified user
        vm.prank(verifiedUser1);
        vm.expectRevert("XAUT: recipient not verified");
        xaut.transfer(unverifiedUser, 50 * 10 ** 6);

        // Scenario 3: Successful transfer after both verified
        vm.prank(verifiedUser1);
        bool success = xaut.transfer(verifiedUser2, 50 * 10 ** 6);
        assertTrue(success);
    }
}
