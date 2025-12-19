// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/GoldVault.sol";

contract DeployGoldVault is Script {
    // Mantle Sepolia deployed addresses
    address constant XAUT = 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78;
    address constant IDENTITY_REGISTRY = 0x620870d419F6aFca8AFed5B516619aa50900cadc;
    address constant UNISWAP_ROUTER = 0xF01D09A6CF3938d59326126174bD1b32FB47d8F5;
    address constant USDC = 0x96ABff3a2668B811371d7d763f06B3832CEdf38d;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying GoldVault...");
        GoldVault goldVault = new GoldVault(
            XAUT,
            IDENTITY_REGISTRY,
            UNISWAP_ROUTER,
            USDC
        );
        console.log("GoldVault deployed at:", address(goldVault));

        vm.stopBroadcast();

        // Log deployment info
        console.log("\n=== GOLDVAULT DEPLOYMENT ===");
        console.log("Chain ID: 5003 (Mantle Sepolia)");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Contract:", address(goldVault));

        console.log("\n=== CONSTRUCTOR PARAMETERS ===");
        console.log("XAUT:", XAUT);
        console.log("IdentityRegistry:", IDENTITY_REGISTRY);
        console.log("UniswapRouter:", UNISWAP_ROUTER);
        console.log("USDC:", USDC);

        console.log("\n=== VAULT INFO ===");
        console.log("Name:", goldVault.name());
        console.log("Symbol:", goldVault.symbol());
        console.log("Decimals:", goldVault.decimals());
        console.log("Asset:", goldVault.asset());

        console.log("\n=== NEXT STEPS ===");
        console.log("1. Copy address:", address(goldVault));
        console.log("2. Register in IdentityRegistry");
        console.log("3. Test deposit/withdraw");
    }
}
