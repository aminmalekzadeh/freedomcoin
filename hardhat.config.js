// require("@nomiclabs/hardhat-waffle");
require("@nomicfoundation/hardhat-toolbox")
require("dotenv").config()

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  etherscan: {
    apiKey: "AHJFQN9UTSYFGA4BAYNDSG9QJ21W4X1WIT",
  },
  sourcify: {
    enabled: true
  },  
  solidity: {
    version: "0.8.25",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${process.env.API_KEY_ACCESS}`,
      accounts: [`0x${process.env.PRIVATE_KEY_TO_DEPLOY}`]
    },
    mainnet: {
      url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.API_KEY_ACCESS}`,
      accounts: [`0x${process.env.PRIVATE_KEY_TO_DEPLOY}`],
      chainId: 137,
    }
  },
};