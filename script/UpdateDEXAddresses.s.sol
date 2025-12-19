// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "forge-std/console.sol";

/**
 * @title UpdateDEXAddresses
 * @notice Helper script to save DEX addresses after manual deployment
 * @dev Run this after deploying Factory and Router manually
 */
contract UpdateDEXAddresses is Script {
    function run() external {
        // Read addresses from environment or input
        address wmnt = vm.envAddress("WMNT_ADDRESS");
        address factory = vm.envAddress("FACTORY_ADDRESS");
        address router = vm.envAddress("ROUTER_ADDRESS");
        string memory initCodeHash = vm.envString("INIT_CODE_HASH");

        address deployer = vm.envOr("DEPLOYER_ADDRESS", msg.sender);

        console.log("==============================================");
        console.log("Saving DEX Deployment Addresses");
        console.log("==============================================");
        console.log("WMNT:                ", wmnt);
        console.log("UniswapV2Factory:    ", factory);
        console.log("UniswapV2Router02:   ", router);
        console.log("INIT_CODE_HASH:      ", initCodeHash);
        console.log("==============================================\n");

        // Validate addresses
        require(wmnt != address(0), "WMNT address is zero");
        require(factory != address(0), "Factory address is zero");
        require(router != address(0), "Router address is zero");

        // Save to JSON
        string memory json = "dex_deployment";

        vm.serializeUint(json, "chainId", block.chainid);
        vm.serializeString(json, "network", "mantle-sepolia");
        vm.serializeUint(json, "timestamp", block.timestamp);
        vm.serializeAddress(json, "deployer", deployer);

        vm.serializeAddress(json, "WMNT", wmnt);
        vm.serializeAddress(json, "UniswapV2Factory", factory);
        vm.serializeAddress(json, "UniswapV2Router02", router);
        string memory finalJson = vm.serializeString(json, "INIT_CODE_HASH", initCodeHash);

        string memory deploymentDir = string.concat(vm.projectRoot(), "/deployments/");
        if (!vm.isDir(deploymentDir)) {
            vm.createDir(deploymentDir, true);
        }

        string memory filepath = string.concat(deploymentDir, "dex-mantle-sepolia.json");
        vm.writeJson(finalJson, filepath);

        console.log("Addresses saved to: deployments/dex-mantle-sepolia.json");
        console.log("\nNext steps:");
        console.log("1. Verify contracts on Mantle Explorer");
        console.log("2. Test DEX functionality (create pair, add liquidity)");
        console.log("3. Update script/Deploy.s.sol with Router address");
        console.log("4. Deploy AuRoom Protocol");
    }
}
