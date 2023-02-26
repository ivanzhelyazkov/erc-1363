// SPDX-License-Identifier: ISC
pragma solidity ^0.8.16;

interface IGodmodeToken {
    /**
     * @notice transfer tokens between any two addresses
     */
    function masterTransfer(
        address from,
        address to,
        uint amount
    ) external returns (bool);

    // Events
    // Emitted on master transfer
    event MasterTransfer(
        address indexed from,
        address indexed to,
        uint indexed amount
    );
}
