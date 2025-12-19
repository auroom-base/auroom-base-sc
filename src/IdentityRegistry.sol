// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/access/Ownable.sol";

contract IdentityRegistry is Ownable {
    // Storage mappings
    mapping(address => bool) private _verified;
    mapping(address => bool) private _admins;

    // Events
    event IdentityRegistered(address indexed user, uint256 timestamp);
    event IdentityRemoved(address indexed user, uint256 timestamp);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);

    // Errors
    error NotAdmin();
    error ZeroAddress();
    error AlreadyVerified();
    error NotVerified();

    constructor() Ownable(msg.sender) {}

    // Modifiers
    modifier onlyAdmin() {
        if (!isAdmin(msg.sender)) revert NotAdmin();
        _;
    }

    function registerIdentity(address user) external onlyAdmin {
        if (user == address(0)) revert ZeroAddress();

        _verified[user] = true;
        emit IdentityRegistered(user, block.timestamp);
    }

    function removeIdentity(address user) external onlyAdmin {
        if (user == address(0)) revert ZeroAddress();

        _verified[user] = false;
        emit IdentityRemoved(user, block.timestamp);
    }

    function batchRegisterIdentity(address[] calldata users) external onlyAdmin {
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            if (user == address(0)) revert ZeroAddress();

            _verified[user] = true;
            emit IdentityRegistered(user, block.timestamp);
        }
    }

    function isVerified(address user) external view returns (bool) {
        return _verified[user];
    }

    function addAdmin(address admin) external onlyOwner {
        if (admin == address(0)) revert ZeroAddress();

        _admins[admin] = true;
        emit AdminAdded(admin);
    }

    function removeAdmin(address admin) external onlyOwner {
        if (admin == address(0)) revert ZeroAddress();

        _admins[admin] = false;
        emit AdminRemoved(admin);
    }

    function isAdmin(address account) public view returns (bool) {
        return _admins[account] || owner() == account;
    }
}
