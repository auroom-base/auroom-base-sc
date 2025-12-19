// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../../src/interfaces/IUniswapV2Factory.sol";
import "./MockUniswapV2Pair.sol";

/**
 * @title MockUniswapV2Factory
 * @dev Mock implementation of Uniswap V2 Factory for testing
 */
contract MockUniswapV2Factory is IUniswapV2Factory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    address public feeTo;
    address public feeToSetter;

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "PAIR_EXISTS");

        MockUniswapV2Pair newPair = new MockUniswapV2Pair(token0, token1);
        pair = address(newPair);

        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);

        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        feeToSetter = _feeToSetter;
    }
}
