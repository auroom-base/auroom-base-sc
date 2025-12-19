// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../src/XAUT.sol";
import "../src/GoldVault.sol";
import "../src/SwapRouter.sol";

/**
 * @title DeploySimple
 * @dev Simple deployment for remaining contracts
 */
contract DeploySimple is Script {
    function run() external {
        // Get addresses from environment
        address identityRegistry = vm.envAddress("IDENTITY_REGISTRY");
        address idrx = vm.envAddress("IDRX");
        address usdc = vm.envAddress("USDC");
        address uniswapRouter = vm.envOr("UNISWAP_ROUTER", address(0));

        require(identityRegistry != address(0), "IDENTITY_REGISTRY not set");
        require(idrx != address(0), "IDRX not set");
        require(usdc != address(0), "USDC not set");

        console.log("Deploying remaining contracts...");
        console.log("IdentityRegistry:", identityRegistry);
        console.log("IDRX:", idrx);
        console.log("USDC:", usdc);

        vm.startBroadcast();

        // Deploy XAUT
        console.log("\nDeploying XAUT...");
        XAUT xaut = new XAUT(identityRegistry);
        console.log("XAUT deployed at:", address(xaut));

        // Only deploy vault and router if Uniswap Router is set
        if (uniswapRouter != address(0)) {
            console.log("\nDeploying GoldVault...");
            GoldVault goldVault = new GoldVault(
                address(xaut),
                identityRegistry,
                uniswapRouter,
                usdc
            );
            console.log("GoldVault deployed at:", address(goldVault));

            console.log("\nDeploying SwapRouter...");
            SwapRouter swapRouter = new SwapRouter(
                uniswapRouter,
                idrx,
                usdc,
                address(xaut)
            );
            console.log("SwapRouter deployed at:", address(swapRouter));
        } else {
            console.log("\nSkipping GoldVault and SwapRouter (UNISWAP_ROUTER not set)");
        }

        vm.stopBroadcast();

        console.log("\nDeployment complete!");
    }
}
