// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "../../src/IIdentityRegistry.sol";

/**
 * @title MockIdentityRegistry
 * @dev Mock implementation of IIdentityRegistry for testing
 */
contract MockIdentityRegistry is IIdentityRegistry {
    mapping(address => bool) private verified;

    function setVerified(address _user, bool _isVerified) external {
        verified[_user] = _isVerified;
    }

    function isVerified(address user) external view override returns (bool) {
        return verified[user];
    }
}
