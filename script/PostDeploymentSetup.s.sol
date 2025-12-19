// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/IdentityRegistry.sol";
import "../src/XAUT.sol";
import "../src/GoldVault.sol";
import "../src/MockIDRX.sol";
import "../src/MockUSDC.sol";

/**
 * @title PostDeploymentSetup
 * @notice Helper script untuk setup tambahan setelah deployment
 * @dev Berguna untuk register users, mint tokens, dan konfigurasi lainnya
 */
contract PostDeploymentSetup is Script {
    struct DeploymentAddresses {
        address idrx;
        address usdc;
        address identityRegistry;
        address xaut;
        address goldVault;
        address swapRouter;
    }

    function run() external {
        string memory network = vm.envString("NETWORK");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        console.log("==============================================");
        console.log("Post-Deployment Setup");
        console.log("Network:", network);
        console.log("==============================================\n");

        // DeploymentAddresses memory addresses = readDeploymentAddresses(network);

        vm.startBroadcast(deployerPrivateKey);

        // Uncomment functions yang ingin dijalankan
        // DeploymentAddresses memory addresses = readDeploymentAddresses(network);
        // registerAdditionalUsers(addresses);
        // mintTokensToUsers(addresses);
        // setupVaultPermissions(addresses);

        vm.stopBroadcast();

        console.log("\nSetup completed successfully!");
    }

    /**
     * @notice Read deployment addresses from JSON file
     */
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

        return addresses;
    }

    /**
     * @notice Register additional users di IdentityRegistry
     * @dev Edit addresses array sesuai kebutuhan
     */
    function registerAdditionalUsers(DeploymentAddresses memory addresses) internal {
        console.log("Registering additional users...");

        IdentityRegistry registry = IdentityRegistry(addresses.identityRegistry);

        // List of addresses to register
        address[] memory users = new address[](3);
        users[0] = 0x1111111111111111111111111111111111111111;
        users[1] = 0x2222222222222222222222222222222222222222;
        users[2] = 0x3333333333333333333333333333333333333333;

        // Batch register
        registry.batchRegisterIdentity(users);

        console.log("  Registered", users.length, "users");
        for (uint256 i = 0; i < users.length; i++) {
            console.log("  -", users[i]);
        }
        console.log("");
    }

    /**
     * @notice Mint tokens ke specific addresses
     * @dev Edit addresses dan amounts sesuai kebutuhan
     */
    function mintTokensToUsers(DeploymentAddresses memory addresses) internal {
        console.log("Minting tokens to users...");

        MockIDRX idrx = MockIDRX(addresses.idrx);
        MockUSDC usdc = MockUSDC(addresses.usdc);
        XAUT xaut = XAUT(addresses.xaut);

        // Example: Mint ke test user
        address testUser = 0x1111111111111111111111111111111111111111;

        // Mint IDRX
        uint256 idrxAmount = 100_000 * 1e18; // 100k IDRX
        idrx.mint(testUser, idrxAmount);
        console.log("  Minted", idrxAmount / 1e18, "IDRX to", testUser);

        // Mint USDC
        uint256 usdcAmount = 10_000 * 1e6; // 10k USDC
        usdc.mint(testUser, usdcAmount);
        console.log("  Minted", usdcAmount / 1e6, "USDC to", testUser);

        // Mint XAUT (only if user is verified)
        if (IdentityRegistry(addresses.identityRegistry).isVerified(testUser)) {
            uint256 xautAmount = 10 * 1e6; // 10 XAUT
            xaut.mint(testUser, xautAmount);
            console.log("  Minted", xautAmount / 1e6, "XAUT to", testUser);
        }

        console.log("");
    }

    /**
     * @notice Setup permissions untuk GoldVault
     * @dev Contoh: Approve vault untuk spend tokens, dll
     */
    function setupVaultPermissions(DeploymentAddresses memory /* addresses */) internal pure {
        // console.log("Setting up vault permissions...");

        // Example setup code here
        // GoldVault vault = GoldVault(addresses.goldVault);
        // XAUT xaut = XAUT(addresses.xaut);

        // Approve vault to spend XAUT
        // xaut.approve(addresses.goldVault, type(uint256).max);

        // console.log("  Vault permissions configured");
        // console.log("");
    }

    /**
     * @notice Verify deployment integrity
     * @dev Check if all contracts are properly configured
     */
    function verifyDeployment(DeploymentAddresses memory addresses) internal view {
        console.log("Verifying deployment integrity...");

        // Check if contracts exist
        require(addresses.idrx.code.length > 0, "MockIDRX not deployed");
        require(addresses.usdc.code.length > 0, "MockUSDC not deployed");
        require(addresses.identityRegistry.code.length > 0, "IdentityRegistry not deployed");
        require(addresses.xaut.code.length > 0, "XAUT not deployed");
        require(addresses.goldVault.code.length > 0, "GoldVault not deployed");
        require(addresses.swapRouter.code.length > 0, "SwapRouter not deployed");

        // Check contract configurations
        XAUT xaut = XAUT(addresses.xaut);
        require(address(xaut.identityRegistry()) == addresses.identityRegistry, "XAUT: incorrect registry");

        GoldVault vault = GoldVault(payable(addresses.goldVault));
        require(address(vault.asset()) == addresses.xaut, "GoldVault: incorrect asset");
        require(address(vault.identityRegistry()) == addresses.identityRegistry, "GoldVault: incorrect registry");

        console.log("  All contracts verified successfully");
        console.log("");
    }
}
