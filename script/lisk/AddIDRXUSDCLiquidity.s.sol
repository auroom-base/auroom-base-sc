// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
}

interface IMintable {
    function mint(address to, uint256 amount) external;
    function publicMint(address to, uint256 amount) external;
}

/**
 * @title AddIDRXUSDCLiquidity
 * @dev Add liquidity to IDRX/USDC pair
 * Ratio: 1 USDC = 16,500 IDRX
 */
contract AddIDRXUSDCLiquidity is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        address idrx = vm.envAddress("MOCK_IDRX");
        address usdc = vm.envAddress("MOCK_USDC");
        address router = vm.envAddress("UNISWAP_ROUTER");
        
        console.log("==============================================");
        console.log("Adding IDRX/USDC Liquidity");
        console.log("==============================================");
        console.log("IDRX:", idrx);
        console.log("USDC:", usdc);
        console.log("Router:", router);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Amounts
        uint256 idrxAmount = 1_000_000_000 * 10**6;  // 1B IDRX
        uint256 usdcAmount = 60_606 * 10**6;         // 60,606 USDC
        
        console.log("Minting tokens...");
        IMintable(idrx).publicMint(deployer, idrxAmount);
        IMintable(usdc).publicMint(deployer, usdcAmount);
        console.log("  IDRX:", idrxAmount / 10**6);
        console.log("  USDC:", usdcAmount / 10**6);
        console.log("");
        
        console.log("Approving router...");
        IERC20(idrx).approve(router, type(uint256).max);
        IERC20(usdc).approve(router, type(uint256).max);
        console.log("  Approved");
        console.log("");
        
        console.log("Adding liquidity...");
        console.log("  Ratio: 1 USDC = 16,500 IDRX");
        
        (uint amountA, uint amountB, uint liquidity) = IUniswapV2Router02(router).addLiquidity(
            idrx,
            usdc,
            idrxAmount,
            usdcAmount,
            0,
            0,
            deployer,
            block.timestamp + 300
        );
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("==============================================");
        console.log("LIQUIDITY ADDED SUCCESSFULLY");
        console.log("==============================================");
        console.log("IDRX added:", amountA / 10**6);
        console.log("USDC added:", amountB / 10**6);
        console.log("LP tokens:", liquidity);
        console.log("==============================================");
    }
}
