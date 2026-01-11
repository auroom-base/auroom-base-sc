// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Script.sol";
import "../../../src/MockIDRX.sol";

/**
 * @title Deploy01_MockIDRX
 * @notice Deploy MockIDRX token to Base Sepolia
 * 
 * Usage:
 *   forge script script/base/deployment/Deploy01_MockIDRX.s.sol \
 *     --rpc-url $BASE_SEPOLIA_RPC \
 *     --broadcast \
 *     --verify
 */
contract Deploy01_MockIDRX is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("==============================================");
        console.log("Deploy01: MockIDRX Token");
        console.log("Network: Base Sepolia (Chain ID: 84532)");
        console.log("==============================================");
        console.log("");
        console.log("Deployer:", deployer);
        console.log("Balance:", deployer.balance / 1e18, "ETH");
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        MockIDRX idrx = new MockIDRX();
        
        vm.stopBroadcast();
        
        console.log("==============================================");
        console.log("DEPLOYMENT SUCCESSFUL!");
        console.log("==============================================");
        console.log("MockIDRX deployed at:", address(idrx));
        console.log("");
        console.log("Token Info:");
        console.log("  Name:", idrx.name());
        console.log("  Symbol:", idrx.symbol());
        console.log("  Decimals:", idrx.decimals());
        console.log("");
        console.log("Add to .env file:");
        console.log("MOCK_IDRX=", address(idrx));
        console.log("");
        console.log("Verify on Basescan:");
        console.log("https://sepolia.basescan.org/address/", address(idrx));
        console.log("==============================================");
    }
}
