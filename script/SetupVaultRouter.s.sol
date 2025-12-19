// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/IdentityRegistry.sol";
import "../src/GoldVault.sol";

contract SetupVaultRouter is Script {
    // Update these addresses after deployment
    address constant GOLD_VAULT = 0xa039F4E162F8A8C5d01C57b78daDa8dcc976657a;
    address constant SWAP_ROUTER = 0x2737e491775055F7218b40A11DE10dA855968277;

    // Existing deployed addresses
    address constant IDENTITY_REGISTRY = 0x620870d419F6aFca8AFed5B516619aa50900cadc;

    function run() external {
        require(GOLD_VAULT != address(0), "Update GOLD_VAULT address");
        require(SWAP_ROUTER != address(0), "Update SWAP_ROUTER address");

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        IdentityRegistry identityRegistry = IdentityRegistry(IDENTITY_REGISTRY);

        // 1. Register GoldVault as verified (so it can hold XAUT)
        console.log("Registering GoldVault in IdentityRegistry...");
        if (!identityRegistry.isVerified(GOLD_VAULT)) {
            identityRegistry.registerIdentity(GOLD_VAULT);
            console.log("GoldVault registered successfully");
        } else {
            console.log("GoldVault already registered");
        }

        // 2. Register SwapRouter as verified (so it can handle tokens)
        console.log("Registering SwapRouter in IdentityRegistry...");
        if (!identityRegistry.isVerified(SWAP_ROUTER)) {
            identityRegistry.registerIdentity(SWAP_ROUTER);
            console.log("SwapRouter registered successfully");
        } else {
            console.log("SwapRouter already registered");
        }

        vm.stopBroadcast();

        console.log("\n=== SETUP COMPLETE ===");
        console.log("GoldVault is now registered and can hold XAUT");
        console.log("SwapRouter is now registered and can handle swaps");
        console.log("\nYou can now:");
        console.log("1. Deposit XAUT into GoldVault");
        console.log("2. Swap IDRX <-> XAUT via SwapRouter");
    }
}
