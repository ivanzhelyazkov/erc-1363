
module.exports = {
  networks: {
    hardhat: {

    },
    // mainnet: {
    //   url: process.env.ALCHEMY_URL,
    //   accounts: [process.env.DEPLOYER_PRIVATE_KEY],
    //   gasPrice: 50000000000, // 50 gwei
    //   gas: 3333333 // 3M gas limit
    // }
  },
  solidity: {
    version: "0.8.16",
    settings: {
      optimizer: {
        enabled: true,
        runs: 7777
      }
    }
  }
};
