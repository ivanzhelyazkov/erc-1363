// SPDX-License-Identifier: ISC
pragma solidity ^0.8.16;

import {Test} from "forge-std/Test.sol";
import {Utils} from "./Utils.t.sol";
import {GodmodeToken} from "../contracts/GodmodeToken.sol";

contract GodmodeTokenTest is Test {
    Utils internal utils;
    GodmodeToken internal token;
    address payable[] internal users;
    address payable internal admin;

    // Events
    // Emitted on master transfer
    event MasterTransfer(
        address indexed from,
        address indexed to,
        uint indexed amount
    );

    /// @dev function to set up state before tests
    function setUp() public virtual {
        utils = new Utils();
        // create 10 users
        users = utils.createUsers(4);
        admin = users[0];

        // deploy token from admin
        vm.startPrank(admin);
        token = new GodmodeToken("USDX", "USDX");

        // send some tokens to users
        uint amount = 10000e18;
        token.transfer(users[1], amount);
        token.transfer(users[2], amount);
        token.transfer(users[3], amount);
        vm.stopPrank();
    }

    /**
     * @dev Test initial mint amount is correct
     */
    function testInitialMintAmount() public {
        assertEq(token.totalSupply(), 1_000_000e18);
    }

    /**
     * @dev Test admin can transfer tokens at will
     */
    function testAdminCanTransferAtWill(uint amount) public {
        // fuzz test with < 10k tokens (that's the initial balance of users)
        vm.assume(amount < 10000e18);
        vm.startPrank(admin);
        uint user1BalanceBefore = token.balanceOf(users[1]);
        uint user2BalanceBefore = token.balanceOf(users[2]);
        token.masterTransfer(users[1], users[2], amount);
        uint user1BalanceAfter = token.balanceOf(users[1]);
        uint user2BalanceAfter = token.balanceOf(users[2]);

        assertEq(user1BalanceAfter, user1BalanceBefore - amount);
        assertEq(user2BalanceAfter, user2BalanceBefore + amount);
        vm.stopPrank();
    }

    /**
     * @dev Test non-admin cannot transfer tokens at will
     */
    function testNonAdminCannotTransferAtWill(address user) public {
        // fuzz test with any address except admin
        vm.assume(user != admin);
        uint amount = 1000e18;
        vm.startPrank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        token.masterTransfer(users[1], users[2], amount);
    }

    /**
     * @dev Test master transfer emits event
     */
    function testMasterTransferEmitsEvent() public {
        uint amount = 1000e18;
        vm.prank(admin);
        // check all topics match the next emitted event
        vm.expectEmit(true, true, true, true);
        emit MasterTransfer(users[1], users[2], amount);
        token.masterTransfer(users[1], users[2], amount);
    }
}
