// scripts/deploy.js
const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const PropertyManager = await ethers.getContractFactory("PropertyManager");
  const propertyManager = await PropertyManager.deploy();

  await propertyManager.deployed();

  console.log("PropertyManager contract deployed to:", propertyManager.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
