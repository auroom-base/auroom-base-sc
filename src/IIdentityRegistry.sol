// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title IIdentityRegistry
 * @dev Interface for identity verification registry
 */
interface IIdentityRegistry {
    /**
     * @dev Check if a user is verified
     * @param user Address to check
     * @return bool True if user is verified
     */
    function isVerified(address user) external view returns (bool);
}
