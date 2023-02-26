// SPDX-License-Identifier: ISC
pragma solidity ^0.8.16;

import {Test} from "forge-std/Test.sol";
import {Utils} from "./Utils.t.sol";
import {IBondingCurveBuyback} from "../contracts/interfaces/IBondingCurveBuyback.sol";
import {BondingCurveBuyback} from "../contracts/BondingCurveBuyback.sol";

import "hardhat/console.sol";

contract BondingCurveBuybackTest is Test {
    Utils internal utils;
    BondingCurveBuyback internal token;
    address payable[] internal users;
    address payable internal admin;

    // Events
    // Emitted on successful buying of tokens
    event TokensBought(address indexed user, uint indexed amount);
    // Emitted on successful sell of tokens
    event TokensSold(address indexed user, uint indexed amount);

    /// @dev function to set up state before tests
    function setUp() public virtual {
        utils = new Utils();
        // create 10 users
        users = utils.createUsers(4);
        admin = users[0];

        // 1 USDX token = 0.001 eth at deployment
        uint startPrice = 0.001 ether;
        // 1% price increase for each 10 000 tokens bought
        uint slope = (0.001 ether * 0.01) / 10000; // = 0.000000001 ether per token

        // deploy token from admin
        vm.prank(admin);
        token = new BondingCurveBuyback("USDX", "USDX", slope, startPrice);
    }

    /**
     * @dev Test initial total supply is correct
     */
    function testInitialTotalSupply() public {
        assertEq(token.totalSupply(), 0);
    }

    function testPriceIncreasesLinearly() public {
        vm.startPrank(users[1]);
        uint tokenAmount = 10000e18;
        uint buyPrice = token.getTokenPriceOnBuy(tokenAmount);
        uint256 ethAmount = token.getExpectedEthToSend(tokenAmount);
        
        uint ethStartBalance = users[1].balance;
        token.buyTokens{value: ethAmount}();
        uint balance = token.balanceOf(users[1]);
        uint receivedEth = token.getExpectedEthReceived(balance);
        uint sellPrice = token.getTokenPriceOnSell(tokenAmount);
        token.sellTokens(balance);
        assertEq(buyPrice, sellPrice);
    }

    /**
     * @dev Test user can buy tokens
     */
    function testCanBuyTokens(uint ethAmount) public {
        // fuzz test with < 100 eth (that's the initial balance of users)
        vm.assume(ethAmount < 100 ether);
        // calculate expected amount to be sent to user
        uint expectedBoughtAmount = token.getExpectedTokensBought(ethAmount);
        // assume token amount bought > 0
        vm.assume(expectedBoughtAmount > 0);
        vm.startPrank(users[1]);
        uint balanceBefore = token.balanceOf(users[1]);
        token.buyTokens{value: ethAmount}();
        uint balanceAfter = token.balanceOf(users[1]);
        uint gain = balanceAfter - balanceBefore;

        assertEq(gain, expectedBoughtAmount);
        vm.stopPrank();
    }

    // function testPriceIncreasesByOnePercentFor10kTokens() public {
    //     uint amount = 10 ether; // 10 eth * 0.001 eth per token = 10 000 tokens (9999 due to curve price increasing)
    //     uint startPrice = token.getTokenPrice();
    //     uint expectedBoughtAmount = token.getExpectedTokensBought(amount);

    //     vm.startPrank(users[1]);
    //     token.buyTokens{value: amount}();

    //     uint endPrice = token.getTokenPrice();

    //     uint ethForOneToken = token.getExpectedEthToSend(1e18);
    //     token.buyTokens{value: ethForOneToken}();

    //     uint bal = token.balanceOf(users[1]);

    //     uint onePercentStartPrice = (startPrice) / 100;

    //     assertEq(startPrice + onePercentStartPrice - onePercentStartPrice / 1000, endPrice);
    // }

    function testCannotBuyTokensWithoutSendingEth() public {
        vm.prank(users[1]);
        vm.expectRevert(IBondingCurveBuyback.NotEnoughETHToBuyTokens.selector);
        token.buyTokens();
    }

    /**
     * @dev Test user can buy tokens by sending eth to contract
     */
    // function testCanBuyTokensWithSend(uint amount) public {
    //     // fuzz test with < 100 eth (that's the initial balance of users)
    //     vm.assume(amount > 0 && amount < 100 ether);
    //     // calculate expected amount to be sent to user
    //     uint expectedBoughtAmount = token.getExpectedTokensBought(amount);
    //     vm.startPrank(users[1]);
    //     uint balanceBefore = token.balanceOf(users[1]);
    //     // transfer tokens manually
    //     (bool res, ) = address(token).call{value: amount}("");
    //     assertTrue(res);

    //     uint balanceAfter = token.balanceOf(users[1]);
    //     uint gain = balanceAfter - balanceBefore;

    //     assertEq(gain, expectedBoughtAmount);
    //     vm.stopPrank();
    // }

    /**
     * @dev Test user can sell tokens
     */
    function testCanSellTokens() public {
        // fuzz test with < 100 eth (that's the initial balance of users)
        //vm.assume(amount > 0.0011 ether && amount < 100 ether);
        uint amount = 50 ether;
        vm.startPrank(users[1]);
        // buy tokens so as to have a balance to sell
        token.buyTokens{value: amount}();
        console.log("eth sent in the beginning: %s", amount);

        uint tokenBalance = token.balanceOf(users[1]);

        uint tokenPriceOnSell = token.getTokenPriceOnSell(tokenBalance);
        console.log('token price on sell: %s', tokenPriceOnSell);

        // calculate expected amount to be sent to user
        uint expectedEthGained = token.getExpectedEthReceived(tokenBalance);
        console.log("expected eth to send back to user: %s", expectedEthGained);
        console.log("eth in contract: %s", address(token).balance);
        // get eth and token balances before sell
        uint ethBefore = users[1].balance;
        uint balanceBefore = token.balanceOf(users[1]);
        // sell tokens
        token.sellTokens(tokenBalance);
        // get eth and token balances after sell
        uint balanceAfter = token.balanceOf(users[1]);
        uint ethAfter = users[1].balance;
        // check tokens sent to contract
        uint tokensSent = balanceBefore - balanceAfter;
        // check eth received
        uint ethGain = ethAfter - ethBefore;
        // assert equality of expected amounts
        assertEq(ethGain, expectedEthGained);
        assertEq(tokensSent, tokenBalance);
        vm.stopPrank();
    }

    /**
     * @dev Test user can sell tokens by sending tokens to contract
     */
    // function test(uint amount) public {
    //     // fuzz test with < 100 eth (that's the initial balance of users)
    //     vm.assume(amount > 0 && amount < 100 ether);
    //     vm.startPrank(users[1]);
    //     uint expectedBoughtAmount = token.getExpectedTokensBought(amount);
    //     token.buyTokens{value: amount}();

    //     // calculate expected amount to be sent to user
    //     uint expectedEthGained = token.getExpectedEthReceived(expectedBoughtAmount);
    //     // get eth and token balances before sell
    //     uint ethBefore = users[1].balance;
    //     uint balanceBefore = token.balanceOf(users[1]);
    //     // sell tokens
    //     token.sellTokens(expectedBoughtAmount);
    //     // get eth and token balances after sell
    //     uint balanceAfter = token.balanceOf(users[1]);
    //     uint ethAfter = users[1].balance;
    //     // check tokens sent to contract
    //     uint tokensSent = balanceBefore - balanceAfter;
    //     // check eth received
    //     uint ethGain = ethAfter - ethBefore;
    //     // assert equality of expected amounts
    //     assertEq(ethGain, expectedEthGained);
    //     assertEq(tokensSent, expectedBoughtAmount);
    //     vm.stopPrank();
    // }

    /**
     * @dev Test master transfer emits event
     */
    // function testMasterTransferEmitsEvent() public {
    //     uint amount = 1000e18;
    //     vm.prank(admin);
    //     // check all topics match the next emitted event
    //     vm.expectEmit(true, true, true, true);
    //     emit MasterTransfer(users[1], users[2], amount);
    //     token.masterTransfer(users[1], users[2], amount);
    // }
}