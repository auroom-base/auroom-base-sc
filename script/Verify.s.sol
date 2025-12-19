// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "forge-std/console.sol";

/**
 * @title Verify
 * @notice Script to verify deployed contracts on block explorer
 * @dev Reads deployment addresses from JSON and verifies each contract
 */
contract Verify is Script {
    struct DeploymentAddresses {
        address idrx;
        address usdc;
        address identityRegistry;
        address xaut;
        address goldVault;
        address swapRouter;
        address uniswapRouter;
    }

    function run() external {
        string memory network = vm.envString("NETWORK");
        console.log("Verifying contracts on network:", network);

        // Read deployment addresses
        DeploymentAddresses memory addresses = readDeploymentAddresses(network);

        // Verify each contract
        console.log("\n==============================================");
        console.log("Starting Contract Verification");
        console.log("==============================================\n");

        verifyMockIDRX(addresses.idrx);
        verifyMockUSDC(addresses.usdc);
        verifyIdentityRegistry(addresses.identityRegistry);
        verifyXAUT(addresses.xaut, addresses.identityRegistry);
        verifyGoldVault(
            addresses.goldVault,
            addresses.xaut,
            addresses.identityRegistry,
            addresses.uniswapRouter,
            addresses.usdc
        );
        verifySwapRouter(
            addresses.swapRouter,
            addresses.uniswapRouter,
            addresses.idrx,
            addresses.usdc,
            addresses.xaut
        );

        console.log("\n==============================================");
        console.log("Verification Complete");
        console.log("==============================================");
    }

    function readDeploymentAddresses(string memory network) internal view returns (DeploymentAddresses memory) {
        string memory filepath = string.concat(
            vm.projectRoot(),
            "/deployments/",
            network,
            ".json"
        );

        string memory json = vm.readFile(filepath);

        DeploymentAddresses memory addresses;
        addresses.idrx = vm.parseJsonAddress(json, ".MockIDRX");
        addresses.usdc = vm.parseJsonAddress(json, ".MockUSDC");
        addresses.identityRegistry = vm.parseJsonAddress(json, ".IdentityRegistry");
        addresses.xaut = vm.parseJsonAddress(json, ".XAUT");
        addresses.goldVault = vm.parseJsonAddress(json, ".GoldVault");
        addresses.swapRouter = vm.parseJsonAddress(json, ".SwapRouter");

        // Read Uniswap router from environment or config
        addresses.uniswapRouter = vm.envAddress("UNISWAP_ROUTER");

        return addresses;
    }

    function verifyMockIDRX(address contractAddress) internal {
        console.log("Verifying MockIDRX at:", contractAddress);

        string[] memory args = new string[](7);
        args[0] = "forge";
        args[1] = "verify-contract";
        args[2] = vm.toString(contractAddress);
        args[3] = "src/MockIDRX.sol:MockIDRX";
        args[4] = "--chain-id";
        args[5] = vm.toString(block.chainid);
        args[6] = "--watch";

        vm.ffi(args);
        console.log("  MockIDRX verified successfully\n");
    }

    function verifyMockUSDC(address contractAddress) internal {
        console.log("Verifying MockUSDC at:", contractAddress);

        string[] memory args = new string[](7);
        args[0] = "forge";
        args[1] = "verify-contract";
        args[2] = vm.toString(contractAddress);
        args[3] = "src/MockUSDC.sol:MockUSDC";
        args[4] = "--chain-id";
        args[5] = vm.toString(block.chainid);
        args[6] = "--watch";

        vm.ffi(args);
        console.log("  MockUSDC verified successfully\n");
    }

    function verifyIdentityRegistry(address contractAddress) internal {
        console.log("Verifying IdentityRegistry at:", contractAddress);

        string[] memory args = new string[](7);
        args[0] = "forge";
        args[1] = "verify-contract";
        args[2] = vm.toString(contractAddress);
        args[3] = "src/IdentityRegistry.sol:IdentityRegistry";
        args[4] = "--chain-id";
        args[5] = vm.toString(block.chainid);
        args[6] = "--watch";

        vm.ffi(args);
        console.log("  IdentityRegistry verified successfully\n");
    }

    function verifyXAUT(address contractAddress, address identityRegistry) internal {
        console.log("Verifying XAUT at:", contractAddress);
        console.log("  Constructor args: identityRegistry =", identityRegistry);

        string[] memory args = new string[](9);
        args[0] = "forge";
        args[1] = "verify-contract";
        args[2] = vm.toString(contractAddress);
        args[3] = "src/XAUT.sol:XAUT";
        args[4] = "--chain-id";
        args[5] = vm.toString(block.chainid);
        args[6] = "--constructor-args";
        args[7] = vm.toString(abi.encode(identityRegistry));
        args[8] = "--watch";

        vm.ffi(args);
        console.log("  XAUT verified successfully\n");
    }

    function verifyGoldVault(
        address contractAddress,
        address xaut,
        address identityRegistry,
        address uniswapRouter,
        address usdc
    ) internal {
        console.log("Verifying GoldVault at:", contractAddress);
        console.log("  Constructor args:");
        console.log("    xaut =", xaut);
        console.log("    identityRegistry =", identityRegistry);
        console.log("    uniswapRouter =", uniswapRouter);
        console.log("    usdc =", usdc);

        string[] memory args = new string[](9);
        args[0] = "forge";
        args[1] = "verify-contract";
        args[2] = vm.toString(contractAddress);
        args[3] = "src/GoldVault.sol:GoldVault";
        args[4] = "--chain-id";
        args[5] = vm.toString(block.chainid);
        args[6] = "--constructor-args";
        args[7] = vm.toString(abi.encode(xaut, identityRegistry, uniswapRouter, usdc));
        args[8] = "--watch";

        vm.ffi(args);
        console.log("  GoldVault verified successfully\n");
    }

    function verifySwapRouter(
        address contractAddress,
        address uniswapRouter,
        address idrx,
        address usdc,
        address xaut
    ) internal {
        console.log("Verifying SwapRouter at:", contractAddress);
        console.log("  Constructor args:");
        console.log("    uniswapRouter =", uniswapRouter);
        console.log("    idrx =", idrx);
        console.log("    usdc =", usdc);
        console.log("    xaut =", xaut);

        string[] memory args = new string[](9);
        args[0] = "forge";
        args[1] = "verify-contract";
        args[2] = vm.toString(contractAddress);
        args[3] = "src/SwapRouter.sol:SwapRouter";
        args[4] = "--chain-id";
        args[5] = vm.toString(block.chainid);
        args[6] = "--constructor-args";
        args[7] = vm.toString(abi.encode(uniswapRouter, idrx, usdc, xaut));
        args[8] = "--watch";

        vm.ffi(args);
        console.log("  SwapRouter verified successfully\n");
    }
}
