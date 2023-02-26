// SPDX-License-Identifier: ISC
pragma solidity ^0.8.16;

import {Test} from "forge-std/Test.sol";
import {Utils} from "./Utils.t.sol";
import {IBlacklistToken} from "../contracts/interfaces/IBlacklistToken.sol";
import {BlacklistToken} from "../contracts/BlacklistToken.sol";

contract BlacklistTokenTest is Test {
    Utils internal utils;
    BlacklistToken internal token;
    address payable[] internal users;
    address payable internal admin;

    // Events
    // Emitted on successful adding of user to blacklist
    event Blacklisted(address indexed user);
    // Emitted on successful removal of user from blacklist
    event RemovedFromBlacklist(address indexed user);

    /// @dev function to set up state before tests
    function setUp() public virtual {
        utils = new Utils();
        // create 10 users
        users = utils.createUsers(4);
        admin = users[0];

        // deploy token from admin
        vm.startPrank(admin);
        token = new BlacklistToken("USDX", "USDX");

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
     * @dev Test admin can blacklist
     */
    function testAdminCanBlacklist() public {
        vm.prank(admin);
        token.addToBlacklist(users[1]);
        bool blacklisted = token.blacklisted(users[1]);
        assertTrue(blacklisted);
    }

    /**
     * @dev Test admin can remove from blacklist
     */
    function testAdminCanRemoveFromBlacklist() public {
        // blacklist address
        vm.prank(admin);
        token.addToBlacklist(users[1]);
        bool blacklisted = token.blacklisted(users[1]);
        assertTrue(blacklisted);

        // remove from blacklist
        vm.prank(admin);
        token.removeFromBlacklist(users[1]);
        blacklisted = token.blacklisted(users[1]);
        assertFalse(blacklisted);
    }

    /**
     * @dev Test blacklist emits Blacklisted event
     */
    function testBlacklistEmitsEvent() public {
        vm.prank(admin);
        // check all topics match the next emitted event
        vm.expectEmit(true, true, true, true);
        emit Blacklisted(users[1]);
        token.addToBlacklist(users[1]);
    }

    /**
     * @dev Test remove from blacklist emits RemovedFromBlacklist event
     */
    function testRemoveFromBlacklistEmitsEvent() public {
        vm.startPrank(admin);
        token.addToBlacklist(users[1]);
        // check all topics match the next emitted event
        vm.expectEmit(true, true, true, true);
        emit RemovedFromBlacklist(users[1]);
        token.removeFromBlacklist(users[1]);
    }

    /**
     * @dev Test non-admin cannot blacklist
     */
    function testNonAdminCannotBlacklist() public {
        // simulate sending tx from user 1 and attempt to blacklist admin
        vm.prank(users[1]);
        // expect tx to revert
        vm.expectRevert();
        token.addToBlacklist(admin);
    }

    /**
     * @dev Test blacklisted address cannot transfer
     */
    function testBlacklistedAddressCannotTransferTokens() public {
        vm.prank(admin);
        token.addToBlacklist(users[1]);

        vm.prank(users[1]);
        uint transferAmount = 1000e18;
        vm.expectRevert(IBlacklistToken.UserBlacklisted.selector);
        token.transfer(users[2], transferAmount);
    }

    /**
     * @dev Test cannot transfer to blacklisted address
     */
    function testCannotTransferToBlacklistedAddress() public {
        vm.prank(admin);
        token.addToBlacklist(users[1]);

        vm.prank(users[2]);
        uint transferAmount = 1000e18;
        vm.expectRevert(IBlacklistToken.UserBlacklisted.selector);
        token.transfer(users[1], transferAmount);
    }

    /**
     * @dev Test blacklisted address cannot call transfer from
     */
    function testBlacklistedAddressCannotCallTransferFrom() public {
        uint amount = 1000e18;
        // approve tokens to user 1
        vm.prank(users[2]);
        token.approve(users[1], amount);

        // blacklist user 1
        vm.prank(admin);
        token.addToBlacklist(users[1]);

        // attempt to call transferFrom user 1
        vm.prank(users[1]);
        vm.expectRevert(IBlacklistToken.UserBlacklisted.selector);
        token.transferFrom(users[2], users[3], amount);
    }

    /**
     * @dev Test blacklisted address cannot call transfer from
     */
    function testCannotCallTransferFromToBlacklistedAddress() public {
        uint amount = 1000e18;
        // approve tokens to user 1
        vm.prank(users[2]);
        token.approve(users[3], amount);

        // blacklist user 1
        vm.prank(admin);
        token.addToBlacklist(users[1]);

        // attempt to call transferFrom user 3 to send token to user 1
        vm.prank(users[3]);
        vm.expectRevert(IBlacklistToken.UserBlacklisted.selector);
        token.transferFrom(users[2], users[1], amount);
    }

    /**
     * @dev Test blacklisted address cannot transferAndCall
     */
    function testBlacklistedAddressCannotTransferAndCall() public {
        vm.prank(admin);
        token.addToBlacklist(users[1]);

        vm.startPrank(users[1]);
        uint transferAmount = 1000e18;
        // test without data
        vm.expectRevert(IBlacklistToken.UserBlacklisted.selector);
        token.transferAndCall(users[2], transferAmount);
        // test with data
        vm.expectRevert(IBlacklistToken.UserBlacklisted.selector);
        token.transferAndCall(users[2], transferAmount, "0x0");
        vm.stopPrank();
    }

    /**
     * @dev Test cannot transferAndCall to blacklisted address
     */
    function testCannotTransferAndCallToBlacklistedAddress() public {
        vm.prank(admin);
        token.addToBlacklist(users[1]);

        vm.startPrank(users[2]);
        uint transferAmount = 1000e18;
        // test without data
        vm.expectRevert(IBlacklistToken.UserBlacklisted.selector);
        token.transferAndCall(users[1], transferAmount);
        // test with data
        vm.expectRevert(IBlacklistToken.UserBlacklisted.selector);
        token.transferAndCall(users[1], transferAmount, "0x0");
        vm.stopPrank();
    }

    /**
     * @dev Test blacklisted address cannot call transfer from
     */
    function testBlacklistedAddressCannotCallTransferFromAndCall() public {
        uint amount = 1000e18;
        // approve tokens to user 1
        vm.prank(users[2]);
        token.approve(users[1], amount);

        // blacklist user 1
        vm.prank(admin);
        token.addToBlacklist(users[1]);

        // attempt to call transferFrom user 1
        vm.startPrank(users[1]);
        // test without data
        vm.expectRevert(IBlacklistToken.UserBlacklisted.selector);
        token.transferFromAndCall(users[2], users[3], amount);
        // test with data
        vm.expectRevert(IBlacklistToken.UserBlacklisted.selector);
        token.transferFromAndCall(users[2], users[3], amount, "0x0");
        vm.stopPrank();
    }

    /**
     * @dev Test cannot call transfer from to blacklisted address
     */
    function testCannotCallTransferFromAndCallToBlacklistedAddress() public {
        uint amount = 1000e18;
        // approve tokens to user 1
        vm.prank(users[2]);
        token.approve(users[3], amount);

        // blacklist user 1
        vm.prank(admin);
        token.addToBlacklist(users[1]);

        // attempt to call transferFrom user 3 to send token to user 1
        vm.startPrank(users[3]);
        // no data
        vm.expectRevert(IBlacklistToken.UserBlacklisted.selector);
        token.transferFromAndCall(users[2], users[1], amount);
        // with data
        vm.expectRevert(IBlacklistToken.UserBlacklisted.selector);
        token.transferFromAndCall(users[2], users[1], amount, "0x0");
        vm.stopPrank();
    }
}
