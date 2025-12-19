// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SwapRouter.sol";

contract DeploySwapRouter is Script {
    // Mantle Sepolia deployed addresses
    address constant UNISWAP_ROUTER = 0xF01D09A6CF3938d59326126174bD1b32FB47d8F5;
    address constant IDRX = 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05;
    address constant USDC = 0x96ABff3a2668B811371d7d763f06B3832CEdf38d;
    address constant XAUT = 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

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
        console.log("\n=== SWAPROUTER DEPLOYMENT ===");
        console.log("Chain ID: 5003 (Mantle Sepolia)");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Contract:", address(swapRouter));

        console.log("\n=== CONSTRUCTOR PARAMETERS ===");
        console.log("UniswapRouter:", UNISWAP_ROUTER);
        console.log("IDRX:", IDRX);
        console.log("USDC:", USDC);
        console.log("XAUT:", XAUT);

        console.log("\n=== ROUTER INFO ===");
        console.log("Uniswap Router:", address(swapRouter.uniswapRouter()));
        console.log("IDRX:", address(swapRouter.idrx()));
        console.log("USDC:", address(swapRouter.usdc()));
        console.log("XAUT:", address(swapRouter.xaut()));

        console.log("\n=== NEXT STEPS ===");
        console.log("1. Copy address:", address(swapRouter));
        console.log("2. Register in IdentityRegistry");
        console.log("3. Test IDRX <-> XAUT swaps");
    }
}
