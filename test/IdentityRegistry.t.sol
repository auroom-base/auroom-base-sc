// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/IdentityRegistry.sol";

contract IdentityRegistryTest is Test {
    IdentityRegistry public registry;

    address public owner;
    address public admin1;
    address public admin2;
    address public user1;
    address public user2;
    address public user3;
    address public unauthorized;

    // Events for testing
    event IdentityRegistered(address indexed user, uint256 timestamp);
    event IdentityRemoved(address indexed user, uint256 timestamp);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);

    function setUp() public {
        owner = address(this);
        admin1 = makeAddr("admin1");
        admin2 = makeAddr("admin2");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        unauthorized = makeAddr("unauthorized");

        registry = new IdentityRegistry();
    }

    /*//////////////////////////////////////////////////////////////
                        DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Deployment() public view {
        assertEq(registry.owner(), owner);
        assertTrue(registry.isAdmin(owner));
    }

    /*//////////////////////////////////////////////////////////////
                        ADMIN MANAGEMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_AddAdmin() public {
        vm.expectEmit(true, false, false, false);
        emit AdminAdded(admin1);

        registry.addAdmin(admin1);

        assertTrue(registry.isAdmin(admin1));
    }

    function test_AddAdmin_RevertIf_NotOwner() public {
        vm.prank(unauthorized);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", unauthorized));
        registry.addAdmin(admin1);
    }

    function test_AddAdmin_RevertIf_ZeroAddress() public {
        vm.expectRevert(IdentityRegistry.ZeroAddress.selector);
        registry.addAdmin(address(0));
    }

    function test_RemoveAdmin() public {
        registry.addAdmin(admin1);
        assertTrue(registry.isAdmin(admin1));

        vm.expectEmit(true, false, false, false);
        emit AdminRemoved(admin1);

        registry.removeAdmin(admin1);

        assertFalse(registry.isAdmin(admin1));
    }

    function test_RemoveAdmin_RevertIf_NotOwner() public {
        registry.addAdmin(admin1);

        vm.prank(unauthorized);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", unauthorized));
        registry.removeAdmin(admin1);
    }

    function test_RemoveAdmin_RevertIf_ZeroAddress() public {
        vm.expectRevert(IdentityRegistry.ZeroAddress.selector);
        registry.removeAdmin(address(0));
    }

    function test_IsAdmin_OwnerIsAlwaysAdmin() public view {
        assertTrue(registry.isAdmin(owner));
    }

    function test_IsAdmin_ReturnsFalseForNonAdmin() public view {
        assertFalse(registry.isAdmin(unauthorized));
    }

    /*//////////////////////////////////////////////////////////////
                    IDENTITY REGISTRATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RegisterIdentity() public {
        vm.expectEmit(true, false, false, true);
        emit IdentityRegistered(user1, block.timestamp);

        registry.registerIdentity(user1);

        assertTrue(registry.isVerified(user1));
    }

    function test_RegisterIdentity_ByAdmin() public {
        registry.addAdmin(admin1);

        vm.prank(admin1);
        vm.expectEmit(true, false, false, true);
        emit IdentityRegistered(user1, block.timestamp);

        registry.registerIdentity(user1);

        assertTrue(registry.isVerified(user1));
    }

    function test_RegisterIdentity_RevertIf_NotAdmin() public {
        vm.prank(unauthorized);
        vm.expectRevert(IdentityRegistry.NotAdmin.selector);
        registry.registerIdentity(user1);
    }

    function test_RegisterIdentity_RevertIf_ZeroAddress() public {
        vm.expectRevert(IdentityRegistry.ZeroAddress.selector);
        registry.registerIdentity(address(0));
    }

    function test_RegisterIdentity_CanRegisterMultipleTimes() public {
        registry.registerIdentity(user1);
        assertTrue(registry.isVerified(user1));

        // Register again should not revert
        registry.registerIdentity(user1);
        assertTrue(registry.isVerified(user1));
    }

    /*//////////////////////////////////////////////////////////////
                    IDENTITY REMOVAL TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RemoveIdentity() public {
        registry.registerIdentity(user1);
        assertTrue(registry.isVerified(user1));

        vm.expectEmit(true, false, false, true);
        emit IdentityRemoved(user1, block.timestamp);

        registry.removeIdentity(user1);

        assertFalse(registry.isVerified(user1));
    }

    function test_RemoveIdentity_ByAdmin() public {
        registry.registerIdentity(user1);
        registry.addAdmin(admin1);

        vm.prank(admin1);
        vm.expectEmit(true, false, false, true);
        emit IdentityRemoved(user1, block.timestamp);

        registry.removeIdentity(user1);

        assertFalse(registry.isVerified(user1));
    }

    function test_RemoveIdentity_RevertIf_NotAdmin() public {
        registry.registerIdentity(user1);

        vm.prank(unauthorized);
        vm.expectRevert(IdentityRegistry.NotAdmin.selector);
        registry.removeIdentity(user1);
    }

    function test_RemoveIdentity_RevertIf_ZeroAddress() public {
        vm.expectRevert(IdentityRegistry.ZeroAddress.selector);
        registry.removeIdentity(address(0));
    }

    function test_RemoveIdentity_CanRemoveUnverifiedUser() public {
        assertFalse(registry.isVerified(user1));

        // Should not revert
        registry.removeIdentity(user1);
        assertFalse(registry.isVerified(user1));
    }

    /*//////////////////////////////////////////////////////////////
                    BATCH REGISTRATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_BatchRegisterIdentity() public {
        address[] memory users = new address[](3);
        users[0] = user1;
        users[1] = user2;
        users[2] = user3;

        // Expect events for all users
        vm.expectEmit(true, false, false, true);
        emit IdentityRegistered(user1, block.timestamp);
        vm.expectEmit(true, false, false, true);
        emit IdentityRegistered(user2, block.timestamp);
        vm.expectEmit(true, false, false, true);
        emit IdentityRegistered(user3, block.timestamp);

        registry.batchRegisterIdentity(users);

        assertTrue(registry.isVerified(user1));
        assertTrue(registry.isVerified(user2));
        assertTrue(registry.isVerified(user3));
    }

    function test_BatchRegisterIdentity_EmptyArray() public {
        address[] memory users = new address[](0);

        // Should not revert
        registry.batchRegisterIdentity(users);
    }

    function test_BatchRegisterIdentity_ByAdmin() public {
        registry.addAdmin(admin1);

        address[] memory users = new address[](2);
        users[0] = user1;
        users[1] = user2;

        vm.prank(admin1);
        registry.batchRegisterIdentity(users);

        assertTrue(registry.isVerified(user1));
        assertTrue(registry.isVerified(user2));
    }

    function test_BatchRegisterIdentity_RevertIf_NotAdmin() public {
        address[] memory users = new address[](1);
        users[0] = user1;

        vm.prank(unauthorized);
        vm.expectRevert(IdentityRegistry.NotAdmin.selector);
        registry.batchRegisterIdentity(users);
    }

    function test_BatchRegisterIdentity_RevertIf_ContainsZeroAddress() public {
        address[] memory users = new address[](3);
        users[0] = user1;
        users[1] = address(0); // Zero address
        users[2] = user2;

        vm.expectRevert(IdentityRegistry.ZeroAddress.selector);
        registry.batchRegisterIdentity(users);

        // user1 should not be registered due to revert
        assertFalse(registry.isVerified(user1));
    }

    function test_BatchRegisterIdentity_LargeArray() public {
        uint256 arraySize = 100;
        address[] memory users = new address[](arraySize);

        for (uint256 i = 0; i < arraySize; i++) {
            users[i] = address(uint160(i + 1000));
        }

        registry.batchRegisterIdentity(users);

        // Verify all are registered
        for (uint256 i = 0; i < arraySize; i++) {
            assertTrue(registry.isVerified(users[i]));
        }
    }

    /*//////////////////////////////////////////////////////////////
                        VERIFICATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_IsVerified_ReturnsFalseByDefault() public view {
        assertFalse(registry.isVerified(user1));
    }

    function test_IsVerified_ReturnsTrueAfterRegistration() public {
        registry.registerIdentity(user1);
        assertTrue(registry.isVerified(user1));
    }

    function test_IsVerified_ReturnsFalseAfterRemoval() public {
        registry.registerIdentity(user1);
        registry.removeIdentity(user1);
        assertFalse(registry.isVerified(user1));
    }

    /*//////////////////////////////////////////////////////////////
                        INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Integration_CompleteWorkflow() public {
        // 1. Add admin
        registry.addAdmin(admin1);
        assertTrue(registry.isAdmin(admin1));

        // 2. Admin registers users
        vm.startPrank(admin1);
        registry.registerIdentity(user1);
        registry.registerIdentity(user2);
        vm.stopPrank();

        assertTrue(registry.isVerified(user1));
        assertTrue(registry.isVerified(user2));

        // 3. Owner removes one identity
        registry.removeIdentity(user1);
        assertFalse(registry.isVerified(user1));
        assertTrue(registry.isVerified(user2));

        // 4. Batch register
        address[] memory users = new address[](2);
        users[0] = user1;
        users[1] = user3;
        registry.batchRegisterIdentity(users);

        assertTrue(registry.isVerified(user1));
        assertTrue(registry.isVerified(user2));
        assertTrue(registry.isVerified(user3));

        // 5. Remove admin
        registry.removeAdmin(admin1);
        assertFalse(registry.isAdmin(admin1));

        // 6. Ex-admin cannot register
        vm.prank(admin1);
        vm.expectRevert(IdentityRegistry.NotAdmin.selector);
        registry.registerIdentity(makeAddr("newUser"));
    }

    function test_Integration_MultipleAdmins() public {
        // Add two admins
        registry.addAdmin(admin1);
        registry.addAdmin(admin2);

        // Both can register identities
        vm.prank(admin1);
        registry.registerIdentity(user1);

        vm.prank(admin2);
        registry.registerIdentity(user2);

        assertTrue(registry.isVerified(user1));
        assertTrue(registry.isVerified(user2));

        // Remove one admin
        registry.removeAdmin(admin1);

        // Admin1 can no longer register
        vm.prank(admin1);
        vm.expectRevert(IdentityRegistry.NotAdmin.selector);
        registry.registerIdentity(user3);

        // Admin2 still can
        vm.prank(admin2);
        registry.registerIdentity(user3);
        assertTrue(registry.isVerified(user3));
    }

    /*//////////////////////////////////////////////////////////////
                        FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_RegisterIdentity(address user) public {
        vm.assume(user != address(0));

        registry.registerIdentity(user);
        assertTrue(registry.isVerified(user));
    }

    function testFuzz_RemoveIdentity(address user) public {
        vm.assume(user != address(0));

        registry.registerIdentity(user);
        registry.removeIdentity(user);
        assertFalse(registry.isVerified(user));
    }

    function testFuzz_AddAndRemoveAdmin(address admin) public {
        vm.assume(admin != address(0));

        registry.addAdmin(admin);
        assertTrue(registry.isAdmin(admin));

        registry.removeAdmin(admin);
        assertFalse(registry.isAdmin(admin));
    }

    function testFuzz_BatchRegister(uint8 size) public {
        vm.assume(size > 0 && size <= 50);

        address[] memory users = new address[](size);
        for (uint256 i = 0; i < size; i++) {
            users[i] = address(uint160(i + 1000));
        }

        registry.batchRegisterIdentity(users);

        for (uint256 i = 0; i < size; i++) {
            assertTrue(registry.isVerified(users[i]));
        }
    }
}
