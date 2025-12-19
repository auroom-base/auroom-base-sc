// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockUSDC is ERC20, Ownable {
    event Mint(address indexed to, uint256 amount);

    constructor() ERC20("Mock USDC", "USDC") Ownable(msg.sender) {}

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function publicMint(address to, uint256 amount) public {
        _mint(to, amount);
        emit Mint(to, amount);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
        emit Mint(to, amount);
    }
}
