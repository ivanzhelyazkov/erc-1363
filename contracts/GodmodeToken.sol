//SPDX-License-Identifier: ISC
pragma solidity ^0.8.16;

import "erc-payable-token/contracts/token/ERC1363/ERC1363.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IGodmodeToken.sol";

/**
 * ERC-1363 compliant token which has a special address which can transfer tokens at will
 */
contract GodmodeToken is ERC1363, Ownable, IGodmodeToken {
    uint public constant initialMintAmount = 1_000_000;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        // mint initial token supply to admin
        _mint(msg.sender, initialMintAmount * 10 ** uint256(decimals()));
    }

    /// @inheritdoc IGodmodeToken
    function masterTransfer(
        address from,
        address to,
        uint amount
    ) external onlyOwner returns (bool) {
        _transfer(from, to, amount);
        emit MasterTransfer(from, to, amount);
        return true;
    }
}
