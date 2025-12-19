// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/MockIDRX.sol";
import "../src/MockUSDC.sol";
import "../src/IdentityRegistry.sol";
import "../src/XAUT.sol";
import "../src/GoldVault.sol";
import "../src/SwapRouter.sol";

/**
 * @title DeploymentInfo
 * @notice Display detailed information about deployed contracts
 * @dev Reads deployment addresses and queries contract states
 */
contract DeploymentInfo is Script {
    struct DeploymentAddresses {
        address idrx;
        address usdc;
        address identityRegistry;
        address xaut;
        address goldVault;
        address swapRouter;
    }

    function run() external view {
        string memory network = vm.envString("NETWORK");

        console.log("==============================================");
        console.log("Deployment Information");
        console.log("==============================================");
        console.log("Network:", network);
        console.log("Chain ID:", block.chainid);
        console.log("==============================================\n");

        DeploymentAddresses memory addresses = readDeploymentAddresses(network);

        // Display all contract info
        displayMockIDRXInfo(addresses.idrx);
        displayMockUSDCInfo(addresses.usdc);
        displayIdentityRegistryInfo(addresses.identityRegistry);
        displayXAUTInfo(addresses.xaut);
        displayGoldVaultInfo(addresses.goldVault);
        displaySwapRouterInfo(addresses.swapRouter);

        console.log("\n==============================================");
        console.log("End of Deployment Information");
        console.log("==============================================");
    }

    function readDeploymentAddresses(string memory network) internal view returns (DeploymentAddresses memory) {
        string memory filepath = string.concat(
            vm.projectRoot(),
            "/deployments/",
            network,
            ".json"
        );

        require(vm.exists(filepath), "Deployment file not found");

        string memory json = vm.readFile(filepath);

        DeploymentAddresses memory addresses;
        addresses.idrx = vm.parseJsonAddress(json, ".MockIDRX");
        addresses.usdc = vm.parseJsonAddress(json, ".MockUSDC");
        addresses.identityRegistry = vm.parseJsonAddress(json, ".IdentityRegistry");
        addresses.xaut = vm.parseJsonAddress(json, ".XAUT");
        addresses.goldVault = vm.parseJsonAddress(json, ".GoldVault");
        addresses.swapRouter = vm.parseJsonAddress(json, ".SwapRouter");

        return addresses;
    }

    function displayMockIDRXInfo(address contractAddress) internal view {
        console.log("MockIDRX:");
        console.log("  Address:", contractAddress);

        MockIDRX idrx = MockIDRX(contractAddress);
        console.log("  Name:", idrx.name());
        console.log("  Symbol:", idrx.symbol());
        console.log("  Decimals:", idrx.decimals());
        console.log("  Total Supply:", idrx.totalSupply() / 1e18, "IDRX");
        console.log("");
    }

    function displayMockUSDCInfo(address contractAddress) internal view {
        console.log("MockUSDC:");
        console.log("  Address:", contractAddress);

        MockUSDC usdc = MockUSDC(contractAddress);
        console.log("  Name:", usdc.name());
        console.log("  Symbol:", usdc.symbol());
        console.log("  Decimals:", usdc.decimals());
        console.log("  Total Supply:", usdc.totalSupply() / 1e6, "USDC");
        console.log("");
    }

    function displayIdentityRegistryInfo(address contractAddress) internal view {
        console.log("IdentityRegistry:");
        console.log("  Address:", contractAddress);

        IdentityRegistry registry = IdentityRegistry(contractAddress);
        console.log("  Owner:", registry.owner());

        // Check if deployer is verified
        address deployer = vm.envAddress("DEPLOYER_ADDRESS");
        if (deployer != address(0)) {
            console.log("  Deployer Verified:", registry.isVerified(deployer));
        }
        console.log("");
    }

    function displayXAUTInfo(address contractAddress) internal view {
        console.log("XAUT:");
        console.log("  Address:", contractAddress);

        XAUT xaut = XAUT(contractAddress);
        console.log("  Name:", xaut.name());
        console.log("  Symbol:", xaut.symbol());
        console.log("  Decimals:", xaut.decimals());
        console.log("  Total Supply:", xaut.totalSupply() / 1e6, "XAUT");
        console.log("  Identity Registry:", address(xaut.identityRegistry()));
        console.log("  Owner:", xaut.owner());
        console.log("");
    }

    function displayGoldVaultInfo(address contractAddress) internal view {
        console.log("GoldVault:");
        console.log("  Address:", contractAddress);

        GoldVault vault = GoldVault(payable(contractAddress));
        console.log("  Name:", vault.name());
        console.log("  Symbol:", vault.symbol());
        console.log("  Asset (XAUT):", vault.asset());
        console.log("  Total Assets:", vault.totalAssets() / 1e6, "XAUT");
        console.log("  Total Supply:", vault.totalSupply() / 1e6, "gXAUT");
        console.log("  Identity Registry:", address(vault.identityRegistry()));
        console.log("  Uniswap Router:", address(vault.uniswapRouter()));
        console.log("  USDC Token:", vault.usdcToken());
        console.log("  LP Token:", vault.lpToken());
        console.log("  Total LP Tokens:", vault.totalLPTokens());
        console.log("  Owner:", vault.owner());
        console.log("");
    }

    function displaySwapRouterInfo(address contractAddress) internal view {
        console.log("SwapRouter:");
        console.log("  Address:", contractAddress);

        SwapRouter router = SwapRouter(contractAddress);
        console.log("  Uniswap Router:", address(router.uniswapRouter()));
        console.log("  IDRX Token:", router.idrx());
        console.log("  USDC Token:", router.usdc());
        console.log("  XAUT Token:", router.xaut());
        console.log("");
    }
}
