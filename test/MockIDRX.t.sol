// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/MockIDRX.sol";

contract MockIDRXTest is Test {
    MockIDRX public token;
    address public owner;
    address public user1;
    address public user2;

    event Mint(address indexed to, uint256 amount);

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        token = new MockIDRX();
    }

    function testInitialState() public view {
        assertEq(token.name(), "Mock IDRX");
        assertEq(token.symbol(), "IDRX");
        assertEq(token.decimals(), 6);
        assertEq(token.totalSupply(), 0);
        assertEq(token.owner(), owner);
    }

    function testPublicMint() public {
        uint256 amount = 1000 * 10**6; // 1000 IDRX

        vm.expectEmit(true, false, false, true);
        emit Mint(user1, amount);

        token.publicMint(user1, amount);

        assertEq(token.balanceOf(user1), amount);
        assertEq(token.totalSupply(), amount);
    }

    function testPublicMintByAnyUser() public {
        uint256 amount = 500 * 10**6; // 500 IDRX

        // User1 mints for themselves
        vm.prank(user1);
        token.publicMint(user1, amount);

        assertEq(token.balanceOf(user1), amount);

        // User2 mints for user1
        vm.prank(user2);
        token.publicMint(user1, amount);

        assertEq(token.balanceOf(user1), amount * 2);
    }

    function testOwnerMint() public {
        uint256 amount = 2000 * 10**6; // 2000 IDRX

        vm.expectEmit(true, false, false, true);
        emit Mint(user2, amount);

        token.mint(user2, amount);

        assertEq(token.balanceOf(user2), amount);
        assertEq(token.totalSupply(), amount);
    }

    function testOwnerMintOnlyByOwner() public {
        uint256 amount = 1000 * 10**6;

        // Should fail when non-owner tries to mint
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user1));
        token.mint(user1, amount);

        // Should succeed when owner mints
        token.mint(user1, amount);
        assertEq(token.balanceOf(user1), amount);
    }

    function testMintToZeroAddress() public {
        uint256 amount = 100 * 10**6;

        // publicMint to zero address should revert
        vm.expectRevert(abi.encodeWithSignature("ERC20InvalidReceiver(address)", address(0)));
        token.publicMint(address(0), amount);

        // owner mint to zero address should revert
        vm.expectRevert(abi.encodeWithSignature("ERC20InvalidReceiver(address)", address(0)));
        token.mint(address(0), amount);
    }

    function testMultipleMints() public {
        uint256 amount1 = 1000 * 10**6;
        uint256 amount2 = 500 * 10**6;
        uint256 amount3 = 250 * 10**6;

        token.publicMint(user1, amount1);
        token.mint(user1, amount2);
        token.publicMint(user2, amount3);

        assertEq(token.balanceOf(user1), amount1 + amount2);
        assertEq(token.balanceOf(user2), amount3);
        assertEq(token.totalSupply(), amount1 + amount2 + amount3);
    }

    function testTransfer() public {
        uint256 mintAmount = 1000 * 10**6;
        uint256 transferAmount = 300 * 10**6;

        token.publicMint(user1, mintAmount);

        vm.prank(user1);
        token.transfer(user2, transferAmount);

        assertEq(token.balanceOf(user1), mintAmount - transferAmount);
        assertEq(token.balanceOf(user2), transferAmount);
    }

    function testApproveAndTransferFrom() public {
        uint256 mintAmount = 1000 * 10**6;
        uint256 approveAmount = 500 * 10**6;

        token.publicMint(user1, mintAmount);

        vm.prank(user1);
        token.approve(user2, approveAmount);

        assertEq(token.allowance(user1, user2), approveAmount);

        vm.prank(user2);
        token.transferFrom(user1, user2, approveAmount);

        assertEq(token.balanceOf(user1), mintAmount - approveAmount);
        assertEq(token.balanceOf(user2), approveAmount);
        assertEq(token.allowance(user1, user2), 0);
    }

    function testFuzzPublicMint(address to, uint256 amount) public {
        vm.assume(to != address(0));
        vm.assume(amount < type(uint256).max / 2);

        token.publicMint(to, amount);

        assertEq(token.balanceOf(to), amount);
        assertEq(token.totalSupply(), amount);
    }

    function testFuzzOwnerMint(address to, uint256 amount) public {
        vm.assume(to != address(0));
        vm.assume(amount < type(uint256).max / 2);

        token.mint(to, amount);

        assertEq(token.balanceOf(to), amount);
        assertEq(token.totalSupply(), amount);
    }
}
