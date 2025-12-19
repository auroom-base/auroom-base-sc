// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./IIdentityRegistry.sol";

/**
 * @title XAUT - Mock Tether Gold Token
 * @dev ERC20 token representing tokenized gold (1 XAUT = 1 troy oz)
 * @dev Implements ERC-3643 inspired compliance checks
 * @dev Only verified wallets can hold and transfer tokens
 */
contract XAUT is ERC20, Ownable, Pausable {
    /// @notice Identity registry for wallet verification
    IIdentityRegistry public identityRegistry;

    /// @notice Emitted when identity registry is updated
    event IdentityRegistryUpdated(address indexed oldRegistry, address indexed newRegistry);

    /**
     * @dev Modifier to check if addresses are verified in identity registry
     * @param from Sender address (can be address(0) for minting)
     * @param to Recipient address (can be address(0) for burning)
     */
    modifier onlyVerified(address from, address to) {
        if (from != address(0)) {
            require(identityRegistry.isVerified(from), "XAUT: sender not verified");
        }
        if (to != address(0)) {
            require(identityRegistry.isVerified(to), "XAUT: recipient not verified");
        }
        _;
    }

    /**
     * @dev Constructor
     * @param _identityRegistry Address of the identity registry contract
     */
    constructor(address _identityRegistry) ERC20("Mock Tether Gold", "XAUT") Ownable(msg.sender) {
        require(_identityRegistry != address(0), "XAUT: invalid registry address");
        identityRegistry = IIdentityRegistry(_identityRegistry);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    /**
     * @dev Transfer tokens with compliance checks
     * @param to Recipient address
     * @param amount Amount to transfer
     * @return bool True if transfer succeeds
     */
    function transfer(address to, uint256 amount)
        public
        override
        whenNotPaused
        onlyVerified(msg.sender, to)
        returns (bool)
    {
        return super.transfer(to, amount);
    }

    /**
     * @dev Transfer tokens from address with compliance checks
     * @param from Sender address
     * @param to Recipient address
     * @param amount Amount to transfer
     * @return bool True if transfer succeeds
     */
    function transferFrom(address from, address to, uint256 amount)
        public
        override
        whenNotPaused
        onlyVerified(from, to)
        returns (bool)
    {
        return super.transferFrom(from, to, amount);
    }

    /**
     * @dev Check if a transfer would succeed
     * @param from Sender address
     * @param to Recipient address
     * @param amount Amount to transfer
     * @return bool True if transfer would succeed
     */
    function canTransfer(address from, address to, uint256 amount) external view returns (bool) {
        // Check if contract is paused
        if (paused()) {
            return false;
        }

        // Check if sender is verified (skip for minting)
        if (from != address(0) && !identityRegistry.isVerified(from)) {
            return false;
        }

        // Check if recipient is verified (skip for burning)
        if (to != address(0) && !identityRegistry.isVerified(to)) {
            return false;
        }

        // Check if sender has sufficient balance (skip for minting)
        if (from != address(0) && balanceOf(from) < amount) {
            return false;
        }

        return true;
    }

    /**
     * @dev Update the identity registry address
     * @param _registry New identity registry address
     */
    function setIdentityRegistry(address _registry) external onlyOwner {
        require(_registry != address(0), "XAUT: invalid registry address");
        address oldRegistry = address(identityRegistry);
        identityRegistry = IIdentityRegistry(_registry);
        emit IdentityRegistryUpdated(oldRegistry, _registry);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        require(identityRegistry.isVerified(to), "XAUT: recipient not verified");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
