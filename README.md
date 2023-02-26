ERC-1363 token collection

This repo contains 3 different ERC-1363 tokens:

* Blacklist token - token which allows an admin to blacklist addresses, effectively banning them from using the token

* Godmode token - token which allows an admin to transfer tokens between addresses at will

* Bonding curve token - token which implements buy and sell using a bonding curve. The token starts at 0 total supply, and it's supply and price increases as people buy it

All of the tokens implement ERC-1363 and all of it's functions:
* transferAndCall, transferFromAndCall, approveAndCall


Bonding Curve Token

This smart contract is a Bonding Curve Token, which is a token (BCT) that follows a specific mathematical formula for determining its price.

The contract's primary purpose is to implement a bonding curve mechanism, a mathematical formula that determines the price of the token in question.

It implements the ERC20 standard for tokens and the Ownable standard from the OpenZeppelin library, which allows the contract to have an owner with specific privileges. The contract has several functions, including buy, sell, withdraw, and getCurrentPrice.

The buy function allows users to purchase tokens with Ether and the sell function allows them to sell tokens at a 10% loss.

The withdraw function allows the owner to withdraw any lost Ether and the getCurrentPrice function returns the current price of the token based on the bonding curve formula.