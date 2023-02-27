//SPDX-License-Identifier: ISC
pragma solidity ^0.8.16;

import "erc-payable-token/contracts/token/ERC1363/ERC1363.sol";
import "erc-payable-token/contracts/token/ERC1363/IERC1363Receiver.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IBondingCurveBuyback.sol";

import "hardhat/console.sol";

/**
 * Token sale and buyback smart contract using a bonding curve
 * The contract is an ERC-1363 token, starting with supply = 0
 * Increases and decreases supply by buying and selling tokens with ETH
 */
contract BondingCurveBuyback is
    ERC1363,
    IERC1363Receiver,
    IBondingCurveBuyback,
    ReentrancyGuard
{
    // rate of growth -> 100 wei = token price increases by 100 wei for each token bought
    uint public immutable slope;
    // start price for the token
    uint public immutable startPrice;

    constructor(
        string memory name,
        string memory symbol,
        uint256 _slope,
        uint _intercept
    ) ERC20(name, symbol) {
        slope = _slope;
        startPrice = _intercept;
    }

    /// @inheritdoc IBondingCurveBuyback
    function buyTokens() public payable override nonReentrant {
        // calculate tokens to buy
        uint256 tokenAmount = getExpectedTokensBought(msg.value);
        // validate the amount is > 0
        if (tokenAmount == 0) {
            revert NotEnoughETHToBuyTokens();
        }
        // mint tokens to user
        _mint(msg.sender, tokenAmount);
        // emit event
        emit TokensBought(msg.sender, tokenAmount);
    }

    /// @inheritdoc IBondingCurveBuyback
    function sellTokens(uint256 amount) external override nonReentrant {
        // check if user has enough tokens to sell
        if (balanceOf(msg.sender) < amount) {
            revert NotEnoughBalanceToBurn();
        }
        // calculate how much ether to send to user
        uint256 etherAmount = getExpectedEthReceived(amount);
        // check if enough ether in contract
        if (address(this).balance < etherAmount) {
            revert InsufficientETHInContract();
        }
        // burn tokens from user
        _burn(msg.sender, amount);
        // send eth to user
        (bool res, ) = msg.sender.call{value: etherAmount}("");
        if (!res) {
            revert ETHNotSent();
        }
        // emit event
        emit TokensSold(msg.sender, etherAmount);
    }

    /**
     * Can sell tokens by directly transferring them to the contract
     * Calculates how much eth to send and transfers it to spender
     */
    function onTransferReceived(
        address spender,
        address,
        uint256 amount,
        bytes calldata
    ) external override nonReentrant returns (bytes4) {
        // calculate how much ether to send to user
        uint256 etherAmount = getExpectedEthReceived(amount);
        // check if enough ether in contract
        if (address(this).balance < etherAmount) {
            revert InsufficientETHInContract();
        }
        // burn tokens from contract
        _burn(address(this), amount);
        // send eth to user (address which is authorized to spend)
        (bool res, ) = spender.call{value: etherAmount}("");
        require(res, "ETH not sent");
        return
            bytes4(
                keccak256("onTransferReceived(address,address,uint256,bytes)")
            );
    }

    /**
     * Can buy tokens by directly transferring ETH to the contract
     * Calculates how much tokens to send and transfers them to msg.sender
     */
    receive() external payable {
        buyTokens();
    }

    /// @inheritdoc IBondingCurveBuyback
    function getTokenPrice() public view returns (uint) {
        return startPrice + (slope * totalSupply()) / 1e18;
    }

    /// @inheritdoc IBondingCurveBuyback
    function getTokenPriceOnBuy(uint tokenAmount) public view returns (uint) {
        if(tokenAmount == 0) {
            return getTokenPrice();
        }
        // buyPrice = (m * S) + (m * n) + i
        return getTokenPrice() + (tokenAmount * slope) / 1e18;
    }

    /// @inheritdoc IBondingCurveBuyback
    function getTokenPriceOnSell(uint tokenAmount) public view returns (uint) {
        if(tokenAmount == 0) {
            return getTokenPrice();
        }
        uint totalSupply = totalSupply();
        if(tokenAmount > totalSupply) {
            return (slope * tokenAmount) / 1e18;
        }
        // sellPrice = (m * (S + n)) - (m * n) + i
        return startPrice + (slope * (totalSupply + tokenAmount) - (slope * tokenAmount)) / 1e18;
    }


    /// @inheritdoc IBondingCurveBuyback
    function getEthPriceOnBuy(uint ethAmount) public view returns (uint) {
        if (ethAmount == 0) {
            return 1e36 / getTokenPrice();
        }
        // get token amount if we were buying at spot price
        uint tokenAmount = (ethAmount * 1e18) / getTokenPrice();
        if (tokenAmount == 0) {
            return 1e36 / getTokenPrice();
        }
        // get 1 token = x eth
        uint effectiveTokenPrice = getTokenPriceOnBuy(tokenAmount);
        if (ethAmount < effectiveTokenPrice) {
            return 1e36 / getTokenPrice();
        }
        // get 1 eth = x tokens when buying
        return ((ethAmount * 1e18) / effectiveTokenPrice) / 1e18;
    }

    function getExpectedEthToSend(
        uint tokenAmount
    ) public view returns (uint ethAmount) {
        return (tokenAmount * getTokenPriceOnBuy(tokenAmount)) / 1e18;
    }

    /// @inheritdoc IBondingCurveBuyback
    function getExpectedTokensBought(
        uint ethAmount
    ) public view returns (uint tokenAmount) {
        return ethAmount * getEthPriceOnBuy(ethAmount);
    }

    /// @inheritdoc IBondingCurveBuyback
    function getExpectedEthReceived(
        uint tokenAmount
    ) public view returns (uint ethAmount) {
        return (tokenAmount * getTokenPriceOnSell(tokenAmount)) / 1e18;
    }
}
