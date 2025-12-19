// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IIdentityRegistry.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Factory.sol";

/**
 * @title GoldVault
 * @dev ERC4626 vault that accepts XAUT and provides yield through Uniswap V2 LP provision
 * @notice Users deposit XAUT and receive gXAUT (share tokens)
 * Strategy: LP provision to Uniswap V2 XAUT/USDC pool
 */
contract GoldVault is ERC4626, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ Events ============

    event StrategyDeployed(uint256 xautAmount, uint256 usdcAmount, uint256 lpReceived);
    event StrategyWithdrawn(uint256 lpAmount, uint256 xautReceived, uint256 usdcReceived);
    event Harvested(uint256 xautProfit, uint256 usdcProfit);
    event ComplianceCheckFailed(address indexed user, string reason);

    // ============ State Variables ============

    /// @notice Identity registry for KYC/compliance checks
    IIdentityRegistry public identityRegistry;

    /// @notice Uniswap V2 Router for liquidity operations
    IUniswapV2Router02 public uniswapRouter;

    /// @notice USDC token address
    address public usdcToken;

    /// @notice Uniswap V2 LP token (XAUT/USDC pair) address
    address public lpToken;

    /// @notice Total LP tokens held by the vault
    uint256 public totalLPTokens;

    /// @notice Timestamp when LP was last deployed
    uint256 public lastDeploymentTime;

    /// @notice Total fees accumulated (in XAUT)
    uint256 public totalFeesAccumulated;

    // ============ Constructor ============

    /**
     * @dev Initialize the GoldVault
     * @param _xaut Address of XAUT token (the underlying asset)
     * @param _identityRegistry Address of the identity registry
     * @param _uniswapRouter Address of Uniswap V2 Router
     * @param _usdc Address of USDC token
     */
    constructor(
        address _xaut,
        address _identityRegistry,
        address _uniswapRouter,
        address _usdc
    )
        ERC4626(IERC20(_xaut))
        ERC20("Gold Vault Token", "gXAUT")
        Ownable(msg.sender)
    {
        require(_xaut != address(0), "GoldVault: zero XAUT address");
        require(_identityRegistry != address(0), "GoldVault: zero registry address");
        require(_uniswapRouter != address(0), "GoldVault: zero router address");
        require(_usdc != address(0), "GoldVault: zero USDC address");

        identityRegistry = IIdentityRegistry(_identityRegistry);
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        usdcToken = _usdc;

        // Get or create the LP pair address
        address factory = uniswapRouter.factory();
        lpToken = IUniswapV2Factory(factory).getPair(_xaut, _usdc);

        // If pair doesn't exist, it will be created on first deployment
        if (lpToken == address(0)) {
            lpToken = IUniswapV2Factory(factory).createPair(_xaut, _usdc);
        }
    }

    // ============ Compliance Modifiers ============

    /**
     * @dev Modifier to check if an address is verified
     * @param account Address to check
     */
    modifier onlyVerified(address account) {
        require(
            identityRegistry.isVerified(account),
            "GoldVault: account not verified"
        );
        _;
    }

    // ============ ERC4626 Overrides with Compliance ============

    /**
     * @dev Deposit assets into the vault
     * @param assets Amount of XAUT to deposit
     * @param receiver Address to receive gXAUT shares
     * @return shares Amount of gXAUT shares minted
     */
    function deposit(uint256 assets, address receiver)
        public
        virtual
        override
        onlyVerified(receiver)
        nonReentrant
        returns (uint256 shares)
    {
        shares = super.deposit(assets, receiver);
        return shares;
    }

    /**
     * @dev Mint shares from the vault
     * @param shares Amount of gXAUT shares to mint
     * @param receiver Address to receive gXAUT shares
     * @return assets Amount of XAUT assets deposited
     */
    function mint(uint256 shares, address receiver)
        public
        virtual
        override
        onlyVerified(receiver)
        nonReentrant
        returns (uint256 assets)
    {
        assets = super.mint(shares, receiver);
        return assets;
    }

    /**
     * @dev Withdraw assets from the vault
     * @param assets Amount of XAUT to withdraw
     * @param receiver Address to receive XAUT
     * @param owner Address of the share owner
     * @return shares Amount of gXAUT shares burned
     */
    function withdraw(uint256 assets, address receiver, address owner)
        public
        virtual
        override
        onlyVerified(receiver)
        nonReentrant
        returns (uint256 shares)
    {
        shares = super.withdraw(assets, receiver, owner);
        return shares;
    }

    /**
     * @dev Redeem shares for assets
     * @param shares Amount of gXAUT shares to redeem
     * @param receiver Address to receive XAUT
     * @param owner Address of the share owner
     * @return assets Amount of XAUT assets withdrawn
     */
    function redeem(uint256 shares, address receiver, address owner)
        public
        virtual
        override
        onlyVerified(receiver)
        nonReentrant
        returns (uint256 assets)
    {
        assets = super.redeem(shares, receiver, owner);
        return assets;
    }

    // ============ ERC20 Transfer Overrides with Compliance ============

    /**
     * @dev Transfer gXAUT tokens with compliance check
     * @param to Recipient address
     * @param value Amount to transfer
     * @return bool Success status
     */
    function transfer(address to, uint256 value)
        public
        virtual
        override(ERC20, IERC20)
        onlyVerified(msg.sender)
        onlyVerified(to)
        returns (bool)
    {
        return super.transfer(to, value);
    }

    /**
     * @dev Transfer gXAUT tokens from one address to another with compliance check
     * @param from Sender address
     * @param to Recipient address
     * @param value Amount to transfer
     * @return bool Success status
     */
    function transferFrom(address from, address to, uint256 value)
        public
        virtual
        override(ERC20, IERC20)
        onlyVerified(from)
        onlyVerified(to)
        returns (bool)
    {
        return super.transferFrom(from, to, value);
    }

    // ============ Strategy Functions ============

    /**
     * @dev Deploy XAUT to Uniswap V2 liquidity pool strategy
     * @param xautAmount Amount of XAUT to deploy
     * @param usdcAmount Amount of USDC to pair with XAUT
     * @param minXautAmount Minimum XAUT to add (slippage protection)
     * @param minUsdcAmount Minimum USDC to add (slippage protection)
     */
    function deployToStrategy(
        uint256 xautAmount,
        uint256 usdcAmount,
        uint256 minXautAmount,
        uint256 minUsdcAmount
    )
        external
        onlyOwner
        nonReentrant
    {
        require(xautAmount > 0, "GoldVault: zero XAUT amount");
        require(usdcAmount > 0, "GoldVault: zero USDC amount");

        address xaut = asset();

        // Check vault has enough XAUT
        uint256 vaultBalance = IERC20(xaut).balanceOf(address(this));
        require(vaultBalance >= xautAmount, "GoldVault: insufficient XAUT");

        // Transfer USDC from owner/treasury to vault
        IERC20(usdcToken).safeTransferFrom(msg.sender, address(this), usdcAmount);

        // Approve router to spend tokens
        IERC20(xaut).safeIncreaseAllowance(address(uniswapRouter), xautAmount);
        IERC20(usdcToken).safeIncreaseAllowance(address(uniswapRouter), usdcAmount);

        // Add liquidity
        (uint256 xautAdded, uint256 usdcAdded, uint256 liquidity) = uniswapRouter.addLiquidity(
            xaut,
            usdcToken,
            xautAmount,
            usdcAmount,
            minXautAmount,
            minUsdcAmount,
            address(this),
            block.timestamp + 300 // 5 minute deadline
        );

        // Update LP token tracking
        totalLPTokens += liquidity;
        lastDeploymentTime = block.timestamp;

        emit StrategyDeployed(xautAdded, usdcAdded, liquidity);
    }

    /**
     * @dev Withdraw LP tokens from strategy and remove liquidity
     * @param lpAmount Amount of LP tokens to withdraw
     * @param minXautAmount Minimum XAUT to receive (slippage protection)
     * @param minUsdcAmount Minimum USDC to receive (slippage protection)
     */
    function withdrawFromStrategy(
        uint256 lpAmount,
        uint256 minXautAmount,
        uint256 minUsdcAmount
    )
        external
        onlyOwner
        nonReentrant
    {
        require(lpAmount > 0, "GoldVault: zero LP amount");
        require(lpAmount <= totalLPTokens, "GoldVault: insufficient LP tokens");

        address xaut = asset();

        // Approve router to spend LP tokens
        IERC20(lpToken).safeIncreaseAllowance(address(uniswapRouter), lpAmount);

        // Remove liquidity
        (uint256 xautReceived, uint256 usdcReceived) = uniswapRouter.removeLiquidity(
            xaut,
            usdcToken,
            lpAmount,
            minXautAmount,
            minUsdcAmount,
            address(this),
            block.timestamp + 300 // 5 minute deadline
        );

        // Update LP token tracking
        totalLPTokens -= lpAmount;

        // USDC can be sent to owner/treasury or kept in vault
        IERC20(usdcToken).safeTransfer(owner(), usdcReceived);

        emit StrategyWithdrawn(lpAmount, xautReceived, usdcReceived);
    }

    /**
     * @dev Harvest profits by removing and re-adding liquidity to collect fees
     * @notice This is a simplified harvest - removes all LP and re-adds to collect accumulated fees
     */
    function harvest() external onlyOwner nonReentrant {
        require(totalLPTokens > 0, "GoldVault: no LP tokens to harvest");

        address xaut = asset();
        uint256 lpAmount = totalLPTokens;

        // Record balances before harvest
        uint256 xautBefore = IERC20(xaut).balanceOf(address(this));
        uint256 usdcBefore = IERC20(usdcToken).balanceOf(address(this));

        // Approve router
        IERC20(lpToken).safeIncreaseAllowance(address(uniswapRouter), lpAmount);

        // Remove all liquidity
        (uint256 xautReceived, uint256 usdcReceived) = uniswapRouter.removeLiquidity(
            xaut,
            usdcToken,
            lpAmount,
            0, // Accept any amount for harvest
            0,
            address(this),
            block.timestamp + 300
        );

        totalLPTokens = 0;

        // Calculate profit (difference from what we should have gotten without fees)
        uint256 xautProfit = IERC20(xaut).balanceOf(address(this)) - xautBefore;
        uint256 usdcProfit = IERC20(usdcToken).balanceOf(address(this)) - usdcBefore;

        // Track accumulated fees in XAUT
        totalFeesAccumulated += xautProfit;

        // Re-add liquidity with all received tokens
        IERC20(xaut).safeIncreaseAllowance(address(uniswapRouter), xautReceived);
        IERC20(usdcToken).safeIncreaseAllowance(address(uniswapRouter), usdcReceived);

        (,, uint256 newLiquidity) = uniswapRouter.addLiquidity(
            xaut,
            usdcToken,
            xautReceived,
            usdcReceived,
            0,
            0,
            address(this),
            block.timestamp + 300
        );

        totalLPTokens = newLiquidity;

        emit Harvested(xautProfit, usdcProfit);
    }

    // ============ Accounting Functions ============

    /**
     * @dev Calculate total assets under management
     * @return Total XAUT value (vault balance + LP position value)
     */
    function totalAssets() public view virtual override returns (uint256) {
        address xaut = asset();
        uint256 vaultBalance = IERC20(xaut).balanceOf(address(this));
        uint256 lpValue = _calculateLPValue();
        return vaultBalance + lpValue;
    }

    /**
     * @dev Calculate the XAUT value of current LP position
     * @return xautValue The amount of XAUT represented by LP tokens
     */
    function _calculateLPValue() internal view returns (uint256 xautValue) {
        if (totalLPTokens == 0 || lpToken == address(0)) {
            return 0;
        }

        IUniswapV2Pair pair = IUniswapV2Pair(lpToken);

        // Get total LP supply and reserves
        uint256 totalSupply = pair.totalSupply();
        if (totalSupply == 0) {
            return 0;
        }

        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();

        // Determine which reserve is XAUT
        address token0 = pair.token0();
        uint256 xautReserve = (token0 == asset()) ? uint256(reserve0) : uint256(reserve1);

        // Calculate XAUT value: (our LP tokens / total LP supply) * total XAUT in pool
        xautValue = (totalLPTokens * xautReserve) / totalSupply;

        return xautValue;
    }

    // ============ View Functions ============

    /**
     * @dev Get current estimated APY
     * @return apy Estimated APY in basis points (e.g., 500 = 5%)
     * @notice This is a simplified calculation based on fees accumulated
     */
    function getCurrentAPY() external view returns (uint256 apy) {
        if (totalLPTokens == 0 || lastDeploymentTime == 0) {
            return 0;
        }

        uint256 timeElapsed = block.timestamp - lastDeploymentTime;
        if (timeElapsed == 0) {
            return 0;
        }

        uint256 lpValue = _calculateLPValue();
        if (lpValue == 0) {
            return 0;
        }

        // Calculate annualized return based on fees accumulated
        // APY = (fees accumulated / LP value) * (seconds in year / time elapsed) * 10000
        uint256 secondsPerYear = 365 days;
        apy = (totalFeesAccumulated * secondsPerYear * 10000) / (lpValue * timeElapsed);

        return apy;
    }

    /**
     * @dev Get detailed strategy information
     * @return totalLPBalance Total LP tokens held
     * @return xautInLP XAUT value in LP position
     * @return vaultXautBalance XAUT balance in vault
     * @return totalValue Total XAUT value (vault + LP)
     * @return lpPairAddress Address of the LP pair
     */
    function getStrategyInfo()
        external
        view
        returns (
            uint256 totalLPBalance,
            uint256 xautInLP,
            uint256 vaultXautBalance,
            uint256 totalValue,
            address lpPairAddress
        )
    {
        totalLPBalance = totalLPTokens;
        xautInLP = _calculateLPValue();
        vaultXautBalance = IERC20(asset()).balanceOf(address(this));
        totalValue = totalAssets();
        lpPairAddress = lpToken;
    }

    /**
     * @dev Get LP reserves information
     * @return reserve0 Reserve of token0
     * @return reserve1 Reserve of token1
     * @return token0 Address of token0
     * @return token1 Address of token1
     */
    function getLPReserves()
        external
        view
        returns (
            uint256 reserve0,
            uint256 reserve1,
            address token0,
            address token1
        )
    {
        if (lpToken == address(0)) {
            return (0, 0, address(0), address(0));
        }

        IUniswapV2Pair pair = IUniswapV2Pair(lpToken);
        (uint112 _reserve0, uint112 _reserve1,) = pair.getReserves();

        reserve0 = uint256(_reserve0);
        reserve1 = uint256(_reserve1);
        token0 = pair.token0();
        token1 = pair.token1();
    }

    // ============ Admin Functions ============

    /**
     * @dev Update identity registry address
     * @param _newRegistry New identity registry address
     */
    function updateIdentityRegistry(address _newRegistry) external onlyOwner {
        require(_newRegistry != address(0), "GoldVault: zero registry address");
        identityRegistry = IIdentityRegistry(_newRegistry);
    }

    /**
     * @dev Emergency withdraw - recover tokens sent by mistake
     * @param token Token address to recover
     * @param amount Amount to recover
     * @notice Cannot withdraw XAUT, USDC, or LP tokens through this function
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        require(token != asset(), "GoldVault: cannot withdraw XAUT");
        require(token != usdcToken, "GoldVault: cannot withdraw USDC");
        require(token != lpToken, "GoldVault: cannot withdraw LP");

        IERC20(token).safeTransfer(owner(), amount);
    }
}
