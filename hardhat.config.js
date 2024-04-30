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
    apiKey: "JXX2RRKDRW5SMRZ4FT5DM1YWF3BG4PDPUS",
  },
  sourcify: {
    // Disabled by default
    // Doesn't need an API key
    enabled: true
  },
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    sepolia: {
      url: `https://sepolia.infura.io/v3/${process.env.API_KEY_ACCESS}`,
      accounts: [`0x${process.env.PRIVATE_KEY_TO_DEPLOY}`]
    },
  },
};