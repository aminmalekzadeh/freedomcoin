require("@nomiclabs/hardhat-waffle");
// require("@nomicfoundation/hardhat-toolbox")

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
    // Disabled by default
    // Doesn't need an API key
    enabled: true
  },
  solidity: {
    version: "0.8.10",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    sepolia: {
      url: "https://sepolia.infura.io/v3/6eaa3174aee0413ab852145e02fc306f",
      accounts: ['0x63de17d346d140f9337d0e1ae524314aa27913f3ef526f7fb0c5a0afc31f374e']
    },
  },
};