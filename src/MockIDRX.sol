// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MockIDRX
 * @notice Mock IDRX token for testing with burn functionality
 * @dev Mimics real IDRX contract's burnWithAccountNumber function
 */
contract MockIDRX is ERC20, Ownable {
    
    // ============ Events ============
    
    event Mint(address indexed to, uint256 amount);
    
    /// @notice Emitted when tokens are burned with bank account hash
    /// @dev Matches real IDRX contract event signature
    event BurnWithAccountNumber(
        address indexed user,
        uint256 amount,
        string hashedAccountNumber
    );
    
    // ============ Constructor ============
    
    constructor() ERC20("Mock IDRX", "IDRX") Ownable(msg.sender) {}
    
    // ============ Token Configuration ============
    
    function decimals() public pure override returns (uint8) {
        return 6;
    }
    
    // ============ Minting Functions ============
    
    /// @notice Public mint for testing (anyone can mint)
    function publicMint(address to, uint256 amount) public {
        _mint(to, amount);
        emit Mint(to, amount);
    }
    
    /// @notice Owner-only mint
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
        emit Mint(to, amount);
    }
    
    // ============ Burn Functions (NEW!) ============
    
    /**
     * @notice Burn tokens with bank account hash
     * @dev Mimics real IDRX contract for redeem flow
     * @param amount Amount of IDRX to burn (6 decimals)
     * @param accountNumber Hashed bank account string (SHA256)
     */
    function burnWithAccountNumber(
        uint256 amount,
        string memory accountNumber
    ) external {
        require(amount > 0, "Amount must be > 0");
        require(bytes(accountNumber).length > 0, "Account number required");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        
        // Burn tokens from caller
        _burn(msg.sender, amount);
        
        // Emit event for backend to track
        emit BurnWithAccountNumber(msg.sender, amount, accountNumber);
    }
    
    /**
     * @notice Standard burn function
     * @param amount Amount to burn
     */
    function burn(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        _burn(msg.sender, amount);
    }
    
    /**
     * @notice Burn from another account (with approval)
     * @param account Account to burn from
     * @param amount Amount to burn
     */
    function burnFrom(address account, uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        _spendAllowance(account, msg.sender, amount);
        _burn(account, amount);
    }
}
