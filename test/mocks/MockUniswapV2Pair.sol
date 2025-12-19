// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../src/interfaces/IUniswapV2Pair.sol";

/**
 * @title MockUniswapV2Pair
 * @dev Simplified mock of Uniswap V2 Pair for testing
 */
contract MockUniswapV2Pair is ERC20, IUniswapV2Pair {
    address public override token0;
    address public override token1;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    uint public constant override MINIMUM_LIQUIDITY = 10**3;
    address public override factory;

    uint public override price0CumulativeLast;
    uint public override price1CumulativeLast;
    uint public override kLast;

    constructor(address _token0, address _token1) ERC20("Uniswap V2", "UNI-V2") {
        token0 = _token0;
        token1 = _token1;
        factory = msg.sender;
    }

    // Override ERC20 functions to satisfy both ERC20 and IUniswapV2Pair
    function totalSupply() public view override(ERC20, IUniswapV2Pair) returns (uint) {
        return ERC20.totalSupply();
    }

    function balanceOf(address account) public view override(ERC20, IUniswapV2Pair) returns (uint) {
        return ERC20.balanceOf(account);
    }

    function DOMAIN_SEPARATOR() external pure override returns (bytes32) {
        return bytes32(0);
    }

    function PERMIT_TYPEHASH() external pure override returns (bytes32) {
        return bytes32(0);
    }

    function nonces(address) external pure override returns (uint) {
        return 0;
    }

    function permit(address, address, uint, uint, uint8, bytes32, bytes32) external override {}

    function getReserves() external view override returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function mint(address to) external override returns (uint liquidity) {
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0 - reserve0;
        uint amount1 = balance1 - reserve1;

        uint _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            liquidity = sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(1), MINIMUM_LIQUIDITY);
        } else {
            liquidity = min((amount0 * _totalSupply) / reserve0, (amount1 * _totalSupply) / reserve1);
        }

        require(liquidity > 0, "INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(balance0, balance1);
        emit Mint(msg.sender, amount0, amount1);
    }

    function burn(address to) external override returns (uint amount0, uint amount1) {
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint liquidity = balanceOf(address(this));

        uint _totalSupply = totalSupply();
        amount0 = (liquidity * balance0) / _totalSupply;
        amount1 = (liquidity * balance1) / _totalSupply;

        require(amount0 > 0 && amount1 > 0, "INSUFFICIENT_LIQUIDITY_BURNED");
        _burn(address(this), liquidity);

        IERC20(token0).transfer(to, amount0);
        IERC20(token1).transfer(to, amount1);

        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));

        _update(balance0, balance1);
        emit Burn(msg.sender, amount0, amount1, to);
    }

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata) external override {
        require(amount0Out > 0 || amount1Out > 0, "INSUFFICIENT_OUTPUT_AMOUNT");

        if (amount0Out > 0) IERC20(token0).transfer(to, amount0Out);
        if (amount1Out > 0) IERC20(token1).transfer(to, amount1Out);

        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));

        _update(balance0, balance1);
        emit Swap(msg.sender, 0, 0, amount0Out, amount1Out, to);
    }

    function skim(address to) external override {
        IERC20(token0).transfer(to, IERC20(token0).balanceOf(address(this)) - reserve0);
        IERC20(token1).transfer(to, IERC20(token1).balanceOf(address(this)) - reserve1);
    }

    function sync() external override {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)));
    }

    function initialize(address _token0, address _token1) external override {
        token0 = _token0;
        token1 = _token1;
    }

    function _update(uint balance0, uint balance1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, "OVERFLOW");
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = uint32(block.timestamp % 2**32);
        emit Sync(reserve0, reserve1);
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }
}
