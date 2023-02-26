// SPDX-License-Identifier: ISC
pragma solidity ^0.8.16;

interface IBlacklistToken {
    /**
     * @notice blacklisted addresses mapping - returns true if user has been blacklisted
     */
    function blacklisted(address) external view returns (bool);

    // Error when blacklisted user attempts transfer
    error UserBlacklisted();

    /**
     * @notice adds an user to the blacklist, effectively banning him from using the token
     */
    function addToBlacklist(address user) external;

    /**
     * @notice adds an user to the blacklist, effectively banning him from using the token
     */
    function removeFromBlacklist(address user) external;

    // Events
    // Emitted on successful adding of user to blacklist
    event Blacklisted(address indexed user);
    // Emitted on successful removal of user from blacklist
    event RemovedFromBlacklist(address indexed user);
}
