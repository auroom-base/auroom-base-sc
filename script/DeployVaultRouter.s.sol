// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/GoldVault.sol";
import "../src/SwapRouter.sol";

contract DeployVaultRouter is Script {
    // Mantle Sepolia deployed addresses
    address constant XAUT = 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78;
    address constant IDENTITY_REGISTRY = 0x620870d419F6aFca8AFed5B516619aa50900cadc;
    address constant UNISWAP_ROUTER = 0xF01D09A6CF3938d59326126174bD1b32FB47d8F5;
    address constant USDC = 0x96ABff3a2668B811371d7d763f06B3832CEdf38d;
    address constant IDRX = 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy GoldVault
        console.log("Deploying GoldVault...");
        GoldVault goldVault = new GoldVault(
            XAUT,
            IDENTITY_REGISTRY,
            UNISWAP_ROUTER,
            USDC
        );
        console.log("GoldVault deployed at:", address(goldVault));

        // 2. Deploy SwapRouter
        console.log("Deploying SwapRouter...");
        SwapRouter swapRouter = new SwapRouter(
            UNISWAP_ROUTER,
            IDRX,
            USDC,
            XAUT
        );
        console.log("SwapRouter deployed at:", address(swapRouter));

        vm.stopBroadcast();

        // Log deployment info
        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("Chain ID: 5003 (Mantle Sepolia)");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("\nDeployed Contracts:");
        console.log("GoldVault:", address(goldVault));
        console.log("SwapRouter:", address(swapRouter));

        console.log("\n=== CONSTRUCTOR PARAMETERS ===");
        console.log("GoldVault:");
        console.log("  - XAUT:", XAUT);
        console.log("  - IdentityRegistry:", IDENTITY_REGISTRY);
        console.log("  - UniswapRouter:", UNISWAP_ROUTER);
        console.log("  - USDC:", USDC);

        console.log("\nSwapRouter:");
        console.log("  - UniswapRouter:", UNISWAP_ROUTER);
        console.log("  - IDRX:", IDRX);
        console.log("  - USDC:", USDC);
        console.log("  - XAUT:", XAUT);

        console.log("\n=== NEXT STEPS ===");
        console.log("1. Register GoldVault in IdentityRegistry");
        console.log("2. Test deposit/withdraw flow");
        console.log("3. Test swap flow");
        console.log("4. Update deployment JSON");
    }
}
