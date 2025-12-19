// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IUniswapV2Router02.sol";

/**
 * @title SwapRouter
 * @dev Router contract for swapping IDRX <-> XAUT through Uniswap V2
 * @notice Swap path: IDRX -> USDC -> XAUT (and vice versa)
 */
contract SwapRouter is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ Events ============

    event SwapExecuted(
        address indexed user,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 timestamp
    );

    // ============ State Variables ============

    /// @notice Uniswap V2 Router instance
    IUniswapV2Router02 public immutable uniswapRouter;

    /// @notice IDRX token address
    address public immutable idrx;

    /// @notice USDC token address
    address public immutable usdc;

    /// @notice XAUT token address
    address public immutable xaut;

    // ============ Constructor ============

    /**
     * @dev Initialize the SwapRouter
     * @param _router Address of Uniswap V2 Router
     * @param _idrx Address of IDRX token
     * @param _usdc Address of USDC token
     * @param _xaut Address of XAUT token
     */
    constructor(
        address _router,
        address _idrx,
        address _usdc,
        address _xaut
    ) {
        require(_router != address(0), "SwapRouter: zero router address");
        require(_idrx != address(0), "SwapRouter: zero IDRX address");
        require(_usdc != address(0), "SwapRouter: zero USDC address");
        require(_xaut != address(0), "SwapRouter: zero XAUT address");

        uniswapRouter = IUniswapV2Router02(_router);
        idrx = _idrx;
        usdc = _usdc;
        xaut = _xaut;
    }

    // ============ Quote Functions ============

    /**
     * @dev Get quote for swapping IDRX to XAUT
     * @param amountIn Amount of IDRX to swap
     * @return amountOut Expected amount of XAUT to receive
     */
    function getQuoteIDRXtoXAUT(uint256 amountIn)
        external
        view
        returns (uint256 amountOut)
    {
        require(amountIn > 0, "SwapRouter: zero amount");

        address[] memory path = new address[](3);
        path[0] = idrx;
        path[1] = usdc;
        path[2] = xaut;

        uint256[] memory amounts = uniswapRouter.getAmountsOut(amountIn, path);
        amountOut = amounts[2];

        return amountOut;
    }

    /**
     * @dev Get quote for swapping XAUT to IDRX
     * @param amountIn Amount of XAUT to swap
     * @return amountOut Expected amount of IDRX to receive
     */
    function getQuoteXAUTtoIDRX(uint256 amountIn)
        external
        view
        returns (uint256 amountOut)
    {
        require(amountIn > 0, "SwapRouter: zero amount");

        address[] memory path = new address[](3);
        path[0] = xaut;
        path[1] = usdc;
        path[2] = idrx;

        uint256[] memory amounts = uniswapRouter.getAmountsOut(amountIn, path);
        amountOut = amounts[2];

        return amountOut;
    }

    /**
     * @dev Get quote with price impact calculation
     * @param amountIn Amount of input token to swap
     * @param idrxToXaut Direction of swap (true = IDRX->XAUT, false = XAUT->IDRX)
     * @return amountOut Expected amount of output token
     * @return priceImpact Price impact in basis points (e.g., 50 = 0.5%)
     */
    function getQuoteWithPriceImpact(uint256 amountIn, bool idrxToXaut)
        external
        view
        returns (uint256 amountOut, uint256 priceImpact)
    {
        require(amountIn > 0, "SwapRouter: zero amount");

        address[] memory path = getPath(idrxToXaut);

        // Get amounts out for the actual swap
        uint256[] memory amounts = uniswapRouter.getAmountsOut(amountIn, path);
        amountOut = amounts[2];

        // Calculate price impact
        // Price impact = (1 - (actualPrice / spotPrice)) * 10000
        // For a 3-hop swap, we calculate the effective price vs ideal price

        // Calculate effective rate: amountOut / amountIn
        // For price impact, we need to compare with a theoretical "no slippage" rate
        // A simplified approach: compare the effective price of first hop + second hop

        // Get spot prices for each hop individually with small amount
        uint256 smallAmount = amountIn / 10000; // Use 0.01% of amount for spot price
        if (smallAmount == 0) smallAmount = 1;

        address[] memory path1 = new address[](2);
        path1[0] = path[0];
        path1[1] = path[1];

        address[] memory path2 = new address[](2);
        path2[0] = path[1];
        path2[1] = path[2];

        uint256[] memory spotAmounts1 = uniswapRouter.getAmountsOut(smallAmount, path1);
        uint256[] memory spotAmounts2 = uniswapRouter.getAmountsOut(spotAmounts1[1], path2);

        // Calculate ideal output based on spot rates
        uint256 idealOutput = (amountIn * spotAmounts2[1]) / smallAmount;

        // Price impact calculation
        if (idealOutput > amountOut) {
            priceImpact = ((idealOutput - amountOut) * 10000) / idealOutput;
        } else {
            priceImpact = 0;
        }

        return (amountOut, priceImpact);
    }

    // ============ Swap Functions ============

    /**
     * @dev Swap IDRX to XAUT
     * @param amountIn Amount of IDRX to swap
     * @param amountOutMin Minimum amount of XAUT to receive (slippage protection)
     * @param to Recipient address for XAUT
     * @param deadline Transaction deadline timestamp
     * @return amountOut Actual amount of XAUT received
     */
    function swapIDRXtoXAUT(
        uint256 amountIn,
        uint256 amountOutMin,
        address to,
        uint256 deadline
    )
        external
        nonReentrant
        returns (uint256 amountOut)
    {
        require(amountIn > 0, "SwapRouter: zero amount");
        require(amountOutMin > 0, "SwapRouter: zero min amount");
        require(to != address(0), "SwapRouter: zero recipient");
        require(deadline >= block.timestamp, "SwapRouter: expired deadline");

        // Transfer IDRX from user to this contract
        IERC20(idrx).safeTransferFrom(msg.sender, address(this), amountIn);

        // Approve router to spend IDRX
        IERC20(idrx).safeIncreaseAllowance(address(uniswapRouter), amountIn);

        // Build swap path
        address[] memory path = new address[](3);
        path[0] = idrx;
        path[1] = usdc;
        path[2] = xaut;

        // Execute swap
        uint256[] memory amounts = uniswapRouter.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );

        amountOut = amounts[2];

        emit SwapExecuted(
            msg.sender,
            idrx,
            xaut,
            amountIn,
            amountOut,
            block.timestamp
        );

        return amountOut;
    }

    /**
     * @dev Swap XAUT to IDRX
     * @param amountIn Amount of XAUT to swap
     * @param amountOutMin Minimum amount of IDRX to receive (slippage protection)
     * @param to Recipient address for IDRX
     * @param deadline Transaction deadline timestamp
     * @return amountOut Actual amount of IDRX received
     */
    function swapXAUTtoIDRX(
        uint256 amountIn,
        uint256 amountOutMin,
        address to,
        uint256 deadline
    )
        external
        nonReentrant
        returns (uint256 amountOut)
    {
        require(amountIn > 0, "SwapRouter: zero amount");
        require(amountOutMin > 0, "SwapRouter: zero min amount");
        require(to != address(0), "SwapRouter: zero recipient");
        require(deadline >= block.timestamp, "SwapRouter: expired deadline");

        // Transfer XAUT from user to this contract
        IERC20(xaut).safeTransferFrom(msg.sender, address(this), amountIn);

        // Approve router to spend XAUT
        IERC20(xaut).safeIncreaseAllowance(address(uniswapRouter), amountIn);

        // Build swap path
        address[] memory path = new address[](3);
        path[0] = xaut;
        path[1] = usdc;
        path[2] = idrx;

        // Execute swap
        uint256[] memory amounts = uniswapRouter.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );

        amountOut = amounts[2];

        emit SwapExecuted(
            msg.sender,
            xaut,
            idrx,
            amountIn,
            amountOut,
            block.timestamp
        );

        return amountOut;
    }

    // ============ Helper Functions ============

    /**
     * @dev Get swap path based on direction
     * @param idrxToXaut Swap direction (true = IDRX->XAUT, false = XAUT->IDRX)
     * @return path Array of token addresses representing the swap path
     */
    function getPath(bool idrxToXaut)
        public
        view
        returns (address[] memory path)
    {
        path = new address[](3);

        if (idrxToXaut) {
            path[0] = idrx;
            path[1] = usdc;
            path[2] = xaut;
        } else {
            path[0] = xaut;
            path[1] = usdc;
            path[2] = idrx;
        }

        return path;
    }
}
