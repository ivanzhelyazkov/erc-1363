// SPDX-License-Identifier: ISC
pragma solidity ^0.8.16;

interface IBondingCurveBuyback {
    /**
     * @dev Returns the current price of the token based on the slope
     * @dev token price is returned with 18 decimals
     */
    function getTokenPrice() external view returns (uint);

    /**
     * @dev Get token price on buy
     * @dev token price is returned with 18 decimals
     */
    function getTokenPriceOnBuy(uint tokenAmount) external view returns (uint);

    /**
     * @dev Get token price on sell
     * @dev token price is returned with 18 decimals
     */
    function getTokenPriceOnSell(uint tokenAmount) external view returns (uint);

    /**
     * @dev Get eth price on buy
     * @dev meaning, 1 ETH = x tokens when buying ethAmount of eth
     * @dev token price is returned with 18 decimals
     */
    function getEthPriceOnBuy(uint ethAmount) external view returns (uint);

    /**
     * @dev Returns the expected tokens received when buying with eth
     * @return tokenAmount token amount bought
     */
    function getExpectedTokensBought(
        uint ethAmount
    ) external view returns (uint tokenAmount);

    /**
     * @dev Returns the expected eth amount received when selling tokens
     * @return ethAmount token amount bought
     */
    function getExpectedEthReceived(
        uint tokenAmount
    ) external view returns (uint ethAmount);

    /// @notice Error user hasn't sent enough ETH to buy tokens
    error NotEnoughETHToBuyTokens();
    /// @notice Error user doesn't buy enough tokens for eth
    error InvalidETHAmount();
    /// @notice Error when user doesn't have enough balance to burn
    error NotEnoughBalanceToBurn();
    /// @notice Error when there is not enough ETH in contract to transfer to user
    error InsufficientETHInContract();
    /// @notice Error when sending ETH to user
    error ETHNotSent();

    /**
     * @notice buy tokens from the contract with ETH
     */
    function buyTokens() external payable;

    /**
     * @notice sell tokens to the contract and receive ETH
     */
    function sellTokens(uint amount) external;

    // Events
    // Emitted on successful buying of tokens
    event TokensBought(address indexed user, uint indexed amount);
    // Emitted on successful sell of tokens
    event TokensSold(address indexed user, uint indexed amount);
}
