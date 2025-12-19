// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title DeployConfig
 * @notice Configuration constants for deployment across different networks
 */
library DeployConfig {
    // Network identifiers
    uint256 constant MANTLE_TESTNET_CHAIN_ID = 5003;
    uint256 constant MANTLE_MAINNET_CHAIN_ID = 5000;
    uint256 constant LOCAL_CHAIN_ID = 31337;

    // Initial token amounts
    uint256 constant INITIAL_IDRX = 1_000_000_000 * 1e18; // 1 billion IDRX
    uint256 constant INITIAL_USDC = 10_000_000 * 1e6;     // 10 million USDC
    uint256 constant INITIAL_XAUT = 100 * 1e6;            // 100 XAUT

    /**
     * @notice Get Uniswap V2 Router address for the current network
     * @param chainId The chain ID to get router for
     * @return router The Uniswap V2 Router address
     */
    function getUniswapRouter(uint256 chainId) internal pure returns (address router) {
        if (chainId == MANTLE_TESTNET_CHAIN_ID) {
            // Mantle Testnet - FusionX V2 Router (Uniswap V2 fork)
            router = 0x0c9E98B4d1B0a7be7b8066A1e9CF70E5e3F3e5E5; // TODO: Update with actual address
        } else if (chainId == MANTLE_MAINNET_CHAIN_ID) {
            // Mantle Mainnet - FusionX V2 Router
            router = 0x0000000000000000000000000000000000000000; // TODO: Update with actual address
        } else if (chainId == LOCAL_CHAIN_ID) {
            // Local testnet - deploy mock router or use test address
            router = 0x0000000000000000000000000000000000000000; // Will be deployed in test
        } else {
            revert("DeployConfig: Unsupported chain ID");
        }
    }

    /**
     * @notice Get network name from chain ID
     * @param chainId The chain ID
     * @return name The network name
     */
    function getNetworkName(uint256 chainId) internal pure returns (string memory name) {
        if (chainId == MANTLE_TESTNET_CHAIN_ID) {
            name = "mantle-testnet";
        } else if (chainId == MANTLE_MAINNET_CHAIN_ID) {
            name = "mantle-mainnet";
        } else if (chainId == LOCAL_CHAIN_ID) {
            name = "localhost";
        } else {
            name = "unknown";
        }
    }

    /**
     * @notice Check if current network is testnet
     * @param chainId The chain ID
     * @return isTestnet True if testnet
     */
    function isTestnet(uint256 chainId) internal pure returns (bool) {
        return chainId == MANTLE_TESTNET_CHAIN_ID || chainId == LOCAL_CHAIN_ID;
    }
}
