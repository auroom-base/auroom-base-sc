// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router02 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function factory() external pure returns (address);
}

/**
 * @title SetupDEXPairs
 * @notice Creates trading pairs and adds initial liquidity
 * @dev Creates IDRX/USDC and XAUT/USDC pairs
 */
contract SetupDEXPairs is Script {
    // Deployed contract addresses
    address constant IDRX = 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05;
    address constant USDC = 0x96ABff3a2668B811371d7d763f06B3832CEdf38d;
    address constant XAUT = 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78;

    // DEX addresses (will be updated after deployment)
    address factory;
    address router;

    function run() external {
        // Load DEX addresses from environment
        factory = vm.envAddress("UNISWAP_FACTORY");
        router = vm.envAddress("UNISWAP_ROUTER");

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deployer:", deployer);
        console.log("Factory:", factory);
        console.log("Router:", router);

        vm.startBroadcast(deployerPrivateKey);

        // Create pairs
        createPairs();

        // Add liquidity
        addInitialLiquidity(deployer);

        vm.stopBroadcast();
    }

    function createPairs() internal {
        IUniswapV2Factory factoryContract = IUniswapV2Factory(factory);

        // 1. Create IDRX/USDC pair
        console.log("\n1. Creating IDRX/USDC pair...");
        address pairIDRX_USDC = factoryContract.getPair(IDRX, USDC);
        if (pairIDRX_USDC == address(0)) {
            pairIDRX_USDC = factoryContract.createPair(IDRX, USDC);
            console.log("IDRX/USDC pair created at:", pairIDRX_USDC);
        } else {
            console.log("IDRX/USDC pair already exists at:", pairIDRX_USDC);
        }

        // 2. Create XAUT/USDC pair
        console.log("\n2. Creating XAUT/USDC pair...");
        address pairXAUT_USDC = factoryContract.getPair(XAUT, USDC);
        if (pairXAUT_USDC == address(0)) {
            pairXAUT_USDC = factoryContract.createPair(XAUT, USDC);
            console.log("XAUT/USDC pair created at:", pairXAUT_USDC);
        } else {
            console.log("XAUT/USDC pair already exists at:", pairXAUT_USDC);
        }
    }

    function addInitialLiquidity(address deployer) internal {
        // Approve tokens first
        approveTokens();

        // Add liquidity to both pairs
        addIDRXUSDCLiquidity(deployer);
        addXAUTUSDCLiquidity(deployer);
    }

    function approveTokens() internal {
        console.log("\n3. Approving tokens...");
        uint256 idxAmount = 1_000_000 * 10**2;  // 1M IDRX
        uint256 totalUSDC = 335_000 * 10**6;     // 335K USDC total
        uint256 xautAmount = 100 * 10**6;        // 100 XAUT

        IERC20(IDRX).approve(router, idxAmount);
        IERC20(USDC).approve(router, totalUSDC);
        IERC20(XAUT).approve(router, xautAmount);
    }

    function addIDRXUSDCLiquidity(address deployer) internal {
        console.log("\n4. Adding IDRX/USDC liquidity...");

        uint256 idxAmount = 1_000_000 * 10**2;   // 1M IDRX
        uint256 usdcAmount = 65_000 * 10**6;     // 65K USDC
        uint256 deadline = block.timestamp + 300;

        console.log("IDRX amount:", idxAmount);
        console.log("USDC amount:", usdcAmount);

        IUniswapV2Router02(router).addLiquidity(
            IDRX,
            USDC,
            idxAmount,
            usdcAmount,
            (idxAmount * 95) / 100,
            (usdcAmount * 95) / 100,
            deployer,
            deadline
        );
    }

    function addXAUTUSDCLiquidity(address deployer) internal {
        console.log("\n5. Adding XAUT/USDC liquidity...");

        uint256 xautAmount = 100 * 10**6;         // 100 XAUT
        uint256 usdcAmount = 270_000 * 10**6;     // 270K USDC
        uint256 deadline = block.timestamp + 300;

        console.log("XAUT amount:", xautAmount);
        console.log("USDC amount:", usdcAmount);

        IUniswapV2Router02(router).addLiquidity(
            XAUT,
            USDC,
            xautAmount,
            usdcAmount,
            (xautAmount * 95) / 100,
            (usdcAmount * 95) / 100,
            deployer,
            deadline
        );
    }
}
