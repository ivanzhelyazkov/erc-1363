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
    event TokensBought(address indexed user, uint indexed tokenAmount, uint indexed ethAmount);
    // Emitted on successful sell of tokens
    event TokensSold(address indexed user, uint indexed tokenAmount, uint indexed ethAmount);

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

    function testCannotBuyTokensWithoutSendingEth() public {
        vm.prank(users[1]);
        vm.expectRevert(IBondingCurveBuyback.NotEnoughETHToBuyTokens.selector);
        token.buyTokens();
    }

    /**
     * @dev Test user can buy tokens by sending eth to contract
     */
    function testCanBuyTokensWithSend(uint amount) public {
        // fuzz test with < 100 eth (that's the initial balance of users)
        vm.assume(amount > 0 && amount < 100 ether);
        // calculate expected amount to be sent to user
        uint expectedBoughtAmount = token.getExpectedTokensBought(amount);
        vm.startPrank(users[1]);
        uint balanceBefore = token.balanceOf(users[1]);
        // transfer tokens manually
        (bool res, ) = address(token).call{value: amount}("");
        assertTrue(res);

        uint balanceAfter = token.balanceOf(users[1]);
        uint gain = balanceAfter - balanceBefore;

        assertEq(gain, expectedBoughtAmount);
        vm.stopPrank();
    }

    /**
     * @dev Test user can sell tokens
     */
    function testCanSellTokens(uint ethAmount) public {
        // fuzz test with < 100 eth (that's the initial balance of users)
        vm.assume(ethAmount > 0.1 ether && ethAmount < 100 ether);
        vm.startPrank(users[1]);
        // buy tokens so as to have a balance to sell
        token.buyTokens{value: ethAmount}();

        uint amountToSell = 1 ether;

        // calculate expected amount to be sent to user
        uint expectedEthGained = token.getExpectedEthReceived(amountToSell);
        // get eth and token balances before sell
        uint ethBefore = users[1].balance;
        uint balanceBefore = token.balanceOf(users[1]);

        // sell tokens
        token.sellTokens(amountToSell);

        // get eth and token balances after sell
        uint balanceAfter = token.balanceOf(users[1]);
        uint ethAfter = users[1].balance;
        // check tokens sent to contract
        uint tokensSent = balanceBefore - balanceAfter;
        // check eth received
        uint ethGain = ethAfter - ethBefore;
        // assert equality of expected amounts
        assertEq(ethGain, expectedEthGained);
        assertEq(tokensSent, amountToSell);
        vm.stopPrank();
    }

    /**
     * @dev Test user can sell tokens by sending tokens to contract with `transferAndCall`
     */
    function testCanSellTokensBySendingToContract(uint ethAmount) public {
        // fuzz test with < 100 eth (that's the initial balance of users)
        vm.assume(ethAmount > 0.1 ether && ethAmount < 100 ether);
        vm.startPrank(users[1]);
        // buy tokens so as to have a balance to sell
        token.buyTokens{value: ethAmount}();

        uint amountToSell = 1 ether;

        // calculate expected amount to be sent to user
        uint expectedEthGained = token.getExpectedEthReceived(amountToSell);
        // get eth and token balances before sell
        uint ethBefore = users[1].balance;
        uint balanceBefore = token.balanceOf(users[1]);

        // sell tokens by sending to contract
        token.transferAndCall(address(token), amountToSell);

        // get eth and token balances after sell
        uint balanceAfter = token.balanceOf(users[1]);
        uint ethAfter = users[1].balance;
        // check tokens sent to contract
        uint tokensSent = balanceBefore - balanceAfter;
        // check eth received
        uint ethGain = ethAfter - ethBefore;
        // assert equality of expected amounts
        assertEq(ethGain, expectedEthGained);
        assertEq(tokensSent, amountToSell);
        vm.stopPrank();
    }

    /**
     * @dev Test buying tokens emits event
     */
    function testBuyTokensEmitsEvent() public {
        uint ethAmount = 1 ether;
        uint expectedTokensReceived = token.getExpectedTokensBought(ethAmount);
        vm.prank(users[1]);
        // check all topics match the next emitted event
        vm.expectEmit(true, true, true, true);
        emit TokensBought(users[1], expectedTokensReceived, ethAmount);
        token.buyTokens{value: ethAmount}();
    }

    /**
     * @dev Test selling tokens emits event
     */
    function testSellTokensEmitsEvent() public {
        vm.startPrank(users[1]);
        uint ethAmount = 1 ether;
        token.buyTokens{value: ethAmount}();

        uint tokenSellAmount = 1 ether;
        uint expectedEthReceived = token.getExpectedEthReceived(tokenSellAmount);
        // check all topics match the next emitted event
        vm.expectEmit(true, true, true, true);
        emit TokensSold(users[1], tokenSellAmount, expectedEthReceived);
        token.sellTokens(tokenSellAmount);

        vm.stopPrank();
    }

    /**
     * @dev Test that sending less than required for 1 wei of tokens reverts
     */
    function testCannotBuyWithoutSendingEth() public {
        vm.prank(users[1]);
        vm.expectRevert(IBondingCurveBuyback.NotEnoughETHToBuyTokens.selector);
        token.buyTokens();
    }

    /**
     * @dev Test that user cannot sell more than his available tokens
     */
    function testCannotSellMoreThanAvailableTokens() public {
        vm.startPrank(users[1]);
        uint ethAmount = 1 ether;
        token.buyTokens{value: ethAmount}();

        uint receivedTokens = token.balanceOf(users[1]);

        // expect the transaction to revert with custom message
        vm.expectRevert(IBondingCurveBuyback.NotEnoughBalanceToBurn.selector);
        token.sellTokens(receivedTokens + 1);
        vm.stopPrank();
    }

    /**
     * @dev Test buying 0 tokens returns spot price
     */
    function testShouldReturnSpotPriceWhenBuyingZeroTokens() public {
        uint amount = 0;
        uint spotPrice = token.getTokenPrice();
        uint price = token.getTokenPriceOnBuy(amount);
        assertEq(spotPrice, price);
    }

    /**
     * @dev Test selling 0 tokens returns spot price
     */
    function testShouldReturnSpotPriceWhenSellingZeroTokens() public {
        uint amount = 0;
        uint spotPrice = token.getTokenPrice();
        uint price = token.getTokenPriceOnSell(amount);
        assertEq(spotPrice, price);
    }

    /**
     * @dev Test buying tokens with zero eth returns spot price
     */
    function testShouldReturnSpotPriceWhenBuyingTokensWithZeroETH() public {
        uint amount = 0;
        uint spotPrice = token.getTokenPrice();
        uint ethSpot = 1e36 / spotPrice;
        uint price = token.getEthPriceOnBuy(amount);
        assertEq(ethSpot, price);
    }

    /**
     * @dev Test selling more than the total supply of tokens is capped at the max amount
     */
    function testShouldLimitSellPriceToTotalSupply() public {
        vm.prank(users[1]);
        // buy some tokens
        token.buyTokens{ value: 1 ether }();
        uint totalSupply = token.totalSupply();
        // get price for more than total supply
        uint amount = totalSupply * 2;
        uint price = token.getTokenPriceOnSell(amount);
        // get price for total supply
        uint priceForTotalSupply = token.getTokenPriceOnSell(totalSupply);
        // assert both prices are equal
        assertEq(priceForTotalSupply, price);
    }
}