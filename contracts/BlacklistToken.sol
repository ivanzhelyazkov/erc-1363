//SPDX-License-Identifier: ISC
pragma solidity ^0.8.16;

import "erc-payable-token/contracts/token/ERC1363/ERC1363.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IBlacklistToken.sol";

/**
 * ERC-1363 compliant token which has a blacklist for banning addresses from using the token
 */
contract BlacklistToken is ERC1363, Ownable, ReentrancyGuard, IBlacklistToken {
    mapping(address => bool) public blacklisted;

    uint public constant initialMintAmount = 1_000_000;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        // mint initial token supply to admin
        _mint(msg.sender, initialMintAmount * 10 ** uint256(decimals()));
    }

    /// @dev Override ERC-20 transfer function to enforce blacklist
    function transfer(
        address to,
        uint amount
    ) public override(ERC20, IERC20) returns (bool) {
        if (blacklisted[msg.sender] || blacklisted[to]) {
            revert UserBlacklisted();
        }
        return super.transfer(to, amount);
    }

    /// @dev Override ERC-20 transferFrom function to enforce blacklist
    function transferFrom(
        address from,
        address to,
        uint amount
    ) public override(ERC20, IERC20) returns (bool) {
        if (blacklisted[msg.sender] || blacklisted[to]) {
            revert UserBlacklisted();
        }
        return super.transferFrom(from, to, amount);
    }

    /// @dev Override ERC-1363 transferAndCall function to enforce blacklist
    function transferAndCall(
        address to,
        uint amount
    ) public override returns (bool) {
        if (blacklisted[msg.sender]) {
            revert UserBlacklisted();
        }
        return super.transferAndCall(to, amount);
    }

    /// @dev Override ERC-1363 transferAndCall function to enforce blacklist
    function transferAndCall(
        address to,
        uint amount,
        bytes memory data
    ) public override returns (bool) {
        if (blacklisted[msg.sender]) {
            revert UserBlacklisted();
        }
        return super.transferAndCall(to, amount, data);
    }

    /// @dev Override ERC-1363 transferFromAndCall function to enforce blacklist
    function transferFromAndCall(
        address from,
        address to,
        uint amount
    ) public override returns (bool) {
        if (blacklisted[from]) {
            revert UserBlacklisted();
        }
        return super.transferFromAndCall(from, to, amount);
    }

    /// @dev Override ERC-1363 transferFromAndCall function to enforce blacklist
    function transferFromAndCall(
        address from,
        address to,
        uint amount,
        bytes memory data
    ) public override returns (bool) {
        if (blacklisted[from]) {
            revert UserBlacklisted();
        }
        return super.transferFromAndCall(from, to, amount, data);
    }

    /// @inheritdoc IBlacklistToken
    function addToBlacklist(address user) external onlyOwner nonReentrant {
        if (!blacklisted[user]) {
            blacklisted[user] = true;
            emit Blacklisted(user);
        }
    }

    /// @inheritdoc IBlacklistToken
    function removeFromBlacklist(address user) external onlyOwner nonReentrant {
        if (blacklisted[user]) {
            blacklisted[user] = false;
            emit RemovedFromBlacklist(user);
        }
    }
}
