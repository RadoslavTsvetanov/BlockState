require("@nomiclabs/hardhat-waffle");

tasks("accounts", "Prints the kist of acounts", async (taskArgs, hre) => {
  const accounts = hre.ethers.getSigners();
  for (const account of accounts) {
    console.log(account.address);
  }
});

module.exports = {
  solidity: "0.8.0",
};
