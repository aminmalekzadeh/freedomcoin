// Import ethers from Hardhat package
const { ethers } = require("hardhat");

async function main() {
  // Fetch the contract factory
  const FreedomCoin = await ethers.getContractFactory("FreedomCoin");

  // Get the deployer's address using ethers
  const [deployer] = await ethers.getSigners();
  const initialOwner = deployer.address; // Using the deployer's address as the initialOwner

  // Deploy the contract with the deployer as the initial owner
  const freedomCoin = await FreedomCoin.deploy(initialOwner);

  // Wait for the contract to be deployed
  await freedomCoin.deployed();

  console.log("FreedomCoin deployed to (Contract Address):", freedomCoin.address);
  console.log("Contract deployed by (Contract Owner):", initialOwner); // Log the deployer's address
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
