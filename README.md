# ERC-1363 token collection

This repo contains 3 different ERC-1363 tokens:

* Blacklist token - token which allows an admin to blacklist addresses, effectively banning them from using the token

* Godmode token - token which allows an admin to transfer tokens between addresses at will

* Bonding curve token - token which implements buy and sell using a bonding curve. The token starts at 0 total supply, and it's supply and price increases as people buy it. The curve used here is linear. Tokens are bought with ETH.  

All of the tokens implement ERC-1363 and all of it's functions:
* `transferAndCall`, `transferFromAndCall`, `approveAndCall`

# Instructions for project

All commands are in package.json.  
Make sure to run `npm i` first.  

To run tests:  
`npm run test`  
To get code coverage:  
`npm run coverage`  
To get gas reports:  
`npm run gas-report`  
To get slither static analysis report:  
`npm run slither`  
