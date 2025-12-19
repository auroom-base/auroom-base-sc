// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../src/MockIDRX.sol";
import "../src/MockUSDC.sol";
import "../src/IdentityRegistry.sol";
import "../src/XAUT.sol";
import "../src/GoldVault.sol";
import "../src/SwapRouter.sol";

/**
 * @title DeployAuRoom
 * @dev Comprehensive deployment script for Productive Gold Platform
 * @notice Deploys all contracts in correct order with proper initialization
 */
contract DeployAuRoom is Script {
    // Deployed contracts
    MockIDRX public idrx;
    MockUSDC public usdc;
    IdentityRegistry public identityRegistry;
    XAUT public xaut;
    GoldVault public goldVault;
    SwapRouter public swapRouter;

    // Uniswap V2 addresses (must be deployed first via deploy-dex.sh)
    address public uniswapRouter;
    address public uniswapFactory;

    // Deployment addresses
    address public deployer;

    function run() external {
        // Get deployer address
        deployer = msg.sender;

        // Load Uniswap addresses from environment or use provided addresses
        uniswapRouter = vm.envOr("UNISWAP_ROUTER", address(0));

        require(uniswapRouter != address(0), "DeployAuRoom: UNISWAP_ROUTER not set in .env");

        console.log("==============================================");
        console.log("Deploying Productive Gold Platform (AuRoom)");
        console.log("==============================================");
        console.log("Network:", block.chainid);
        console.log("Deployer:", deployer);
        console.log("Uniswap Router:", uniswapRouter);
        console.log("");

        vm.startBroadcast();

        // Step 1: Deploy Mock Tokens
        console.log("Step 1: Deploying Mock Tokens...");
        idrx = new MockIDRX();
        console.log("  MockIDRX deployed at:", address(idrx));

        usdc = new MockUSDC();
        console.log("  MockUSDC deployed at:", address(usdc));
        console.log("");

        // Step 2: Deploy IdentityRegistry
        console.log("Step 2: Deploying IdentityRegistry...");
        identityRegistry = new IdentityRegistry();
        console.log("  IdentityRegistry deployed at:", address(identityRegistry));
        console.log("");

        // Step 3: Deploy XAUT
        console.log("Step 3: Deploying XAUT...");
        xaut = new XAUT(address(identityRegistry));
        console.log("  XAUT deployed at:", address(xaut));
        console.log("");

        // Step 4: Deploy GoldVault
        console.log("Step 4: Deploying GoldVault...");
        goldVault = new GoldVault(
            address(xaut),
            address(identityRegistry),
            uniswapRouter,
            address(usdc)
        );
        console.log("  GoldVault deployed at:", address(goldVault));
        console.log("");

        // Step 5: Deploy SwapRouter
        console.log("Step 5: Deploying SwapRouter...");
        swapRouter = new SwapRouter(
            uniswapRouter,
            address(idrx),
            address(usdc),
            address(xaut)
        );
        console.log("  SwapRouter deployed at:", address(swapRouter));
        console.log("");

        // Step 6: Initial Setup - Register deployer and contracts in KYC
        console.log("Step 6: Initial Setup - KYC Registration...");
        identityRegistry.registerIdentity(deployer);
        console.log("  Deployer registered in KYC");

        identityRegistry.registerIdentity(address(goldVault));
        console.log("  GoldVault registered in KYC");

        identityRegistry.registerIdentity(address(swapRouter));
        console.log("  SwapRouter registered in KYC");
        console.log("");

        vm.stopBroadcast();

        // Print deployment summary
        printDeploymentSummary();

        // Save deployment addresses
        saveDeploymentAddresses();
    }

    function printDeploymentSummary() internal view {
        console.log("==============================================");
        console.log("DEPLOYMENT SUMMARY");
        console.log("==============================================");
        console.log("");
        console.log("Network Information:");
        console.log("  Chain ID:", block.chainid);
        console.log("  Deployer:", deployer);
        console.log("");
        console.log("Deployed Contracts:");
        console.log("  MockIDRX:          ", address(idrx));
        console.log("  MockUSDC:          ", address(usdc));
        console.log("  IdentityRegistry:  ", address(identityRegistry));
        console.log("  XAUT:              ", address(xaut));
        console.log("  GoldVault:         ", address(goldVault));
        console.log("  SwapRouter:        ", address(swapRouter));
        console.log("");
        console.log("External Dependencies:");
        console.log("  Uniswap Router:    ", uniswapRouter);
        console.log("");
        console.log("Initial Setup Completed:");
        console.log("  - Deployer registered in KYC");
        console.log("  - GoldVault registered in KYC");
        console.log("  - SwapRouter registered in KYC");
        console.log("");
        console.log("==============================================");
        console.log("NEXT STEPS");
        console.log("==============================================");
        console.log("1. Verify contracts on block explorer");
        console.log("2. Create Uniswap pairs:");
        console.log("   - IDRX/USDC pair");
        console.log("   - USDC/XAUT pair");
        console.log("3. Add initial liquidity to pairs");
        console.log("4. Mint initial tokens for testing");
        console.log("5. Test full user flow");
        console.log("==============================================");
    }

    function saveDeploymentAddresses() internal {
        string memory json = "deploymentData";

        vm.serializeUint(json, "chainId", block.chainid);
        vm.serializeAddress(json, "deployer", deployer);
        vm.serializeAddress(json, "MockIDRX", address(idrx));
        vm.serializeAddress(json, "MockUSDC", address(usdc));
        vm.serializeAddress(json, "IdentityRegistry", address(identityRegistry));
        vm.serializeAddress(json, "XAUT", address(xaut));
        vm.serializeAddress(json, "GoldVault", address(goldVault));
        vm.serializeAddress(json, "SwapRouter", address(swapRouter));
        string memory finalJson = vm.serializeAddress(json, "UniswapRouter", uniswapRouter);

        string memory network;
        if (block.chainid == 5003) {
            network = "mantle-sepolia";
        } else if (block.chainid == 5000) {
            network = "mantle-mainnet";
        } else if (block.chainid == 5001) {
            network = "mantle-testnet";
        } else {
            network = "unknown";
        }

        string memory filename = string.concat("deployments/auroom-", network, ".json");
        vm.writeJson(finalJson, filename);

        console.log("");
        console.log("Deployment addresses saved to:", filename);
    }
}
