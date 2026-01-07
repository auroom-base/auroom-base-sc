// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../../src/BorrowingProtocolV2.sol";
import "../../src/XAUT.sol";
import "../../src/MockIDRX.sol";
import "../../src/IdentityRegistry.sol";

/**
 * @title TestBorrowFlow
 * @dev Test the complete borrow flow with BorrowingProtocolV2
 */
contract TestBorrowFlow is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        address borrowingProtocol = vm.envAddress("BORROWING_PROTOCOL_V2");
        address xaut = vm.envAddress("XAUT");
        address idrx = vm.envAddress("MOCK_IDRX");
        address identityRegistry = vm.envAddress("IDENTITY_REGISTRY");
        
        console.log("==============================================");
        console.log("Testing BorrowingProtocolV2");
        console.log("==============================================");
        console.log("Protocol:", borrowingProtocol);
        console.log("Test User:", deployer);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Register user in IdentityRegistry
        console.log("Step 1: Registering user...");
        IdentityRegistry registry = IdentityRegistry(identityRegistry);
        if (!registry.isVerified(deployer)) {
            registry.registerIdentity(deployer);
            console.log("  User registered");
        } else {
            console.log("  User already registered");
        }
        console.log("");
        
        // Step 2: Mint XAUT to user
        console.log("Step 2: Minting XAUT...");
        uint256 xautAmount = 1000000; // 1 XAUT (6 decimals)
        XAUT xautToken = XAUT(xaut);
        xautToken.publicMint(deployer, xautAmount);
        console.log("  Minted:", xautAmount / 10**6, "XAUT");
        console.log("");
        
        // Step 3: Approve XAUT
        console.log("Step 3: Approving XAUT...");
        xautToken.approve(borrowingProtocol, xautAmount);
        console.log("  Approved");
        console.log("");
        
        // Step 4: Check treasury IDRX balance
        console.log("Step 4: Checking treasury...");
        MockIDRX idrxToken = MockIDRX(idrx);
        BorrowingProtocolV2 protocol = BorrowingProtocolV2(borrowingProtocol);
        address treasury = protocol.treasury();
        uint256 treasuryBalance = idrxToken.balanceOf(treasury);
        console.log("  Treasury:", treasury);
        console.log("  Treasury IDRX balance:", treasuryBalance / 10**6, "IDRX");
        console.log("");
        
        // Step 5: Try to borrow
        console.log("Step 5: Borrowing IDRX...");
        uint256 borrowAmount = 10000000; // 10 IDRX (6 decimals)
        
        try protocol.depositAndBorrow(xautAmount, borrowAmount) {
            console.log("  SUCCESS! Borrowed:", borrowAmount / 10**6, "IDRX");
            console.log("");
            
            // Check balances
            uint256 userIDRX = idrxToken.balanceOf(deployer);
            uint256 userDebt = protocol.debt(deployer);
            uint256 userCollateral = protocol.collateral(deployer);
            
            console.log("Results:");
            console.log("  User IDRX balance:", userIDRX / 10**6);
            console.log("  User debt:", userDebt / 10**6);
            console.log("  User collateral:", userCollateral / 10**6);
            
        } catch Error(string memory reason) {
            console.log("  FAILED!");
            console.log("  Reason:", reason);
        } catch (bytes memory) {
            console.log("  FAILED!");
            console.log("  Unknown error");
        }
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("==============================================");
        console.log("Test Complete");
        console.log("==============================================");
    }
}
