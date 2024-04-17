// test/RentalProperty.test.js
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("RentalProperty", function () {
  let RentalProperty;
  let rentalProperty;
  let owner;
  let rentCollector;
  let investor1;
  let investor2;

  beforeEach(async function () {
    [owner, rentCollector, investor1, investor2] = await ethers.getSigners();

    RentalProperty = await ethers.getContractFactory("RentalProperty");
    rentalProperty = await RentalProperty.deploy(
      "Property",
      "P1",
      rentCollector.address
    );
    await rentalProperty.deployed();
  });

  it("Should deploy RentalProperty contract", async function () {
    expect(rentalProperty.address).to.not.be.undefined;
  });

  it("Should pay rent", async function () {
    const initialRentCollectorBalance = await ethers.provider.getBalance(
      rentCollector.address
    );
    const rentAmount = ethers.utils.parseEther("0.1");
    await rentalProperty.payRent({ value: rentAmount });
    const finalRentCollectorBalance = await ethers.provider.getBalance(
      rentCollector.address
    );
    expect(finalRentCollectorBalance.sub(initialRentCollectorBalance)).to.equal(
      rentAmount
    );
  });

  it("Should get collected rent", async function () {
    const rentAmount = ethers.utils.parseEther("0.1");
    await rentalProperty.payRent({ value: rentAmount });
    const collectedRent = await rentalProperty.seeCollectedRent();
    expect(collectedRent).to.equal(rentAmount);
  });

  it("Should withdraw share of rent", async function () {
    const rentAmount = ethers.utils.parseEther("0.1");
    await rentalProperty.payRent({ value: rentAmount });
    const initialBalance = await ethers.provider.getBalance(investor1.address);
    await rentalProperty.connect(investor1).withdrawShareOfRent();
    const finalBalance = await ethers.provider.getBalance(investor1.address);
    expect(finalBalance.sub(initialBalance)).to.equal(rentAmount.div(100)); // Assuming 1% share
  });

  it("Should buy property shares", async function () {
    const numberOfShares = 10;
    await rentalProperty.buyPropertyShares(numberOfShares);
    const balance = await rentalProperty.balanceOf(owner.address);
    expect(balance).to.equal(numberOfShares * ethers.constants.WeiPerEther); // Assuming 1 share costs 1 ether
  });

  it("Should start and complete mortgage", async function () {
    const mortgageAmount = ethers.utils.parseEther("1");
    const mortgageDuration = 30 * 24 * 60 * 60; // 30 days in seconds
    await rentalProperty.startMortage(owner.address, mortgageAmount);
    await ethers.provider.send("evm_increaseTime", [mortgageDuration]); // Fast-forward time
    await ethers.provider.send("evm_mine"); // Mine a new block to finalize the time change
    await rentalProperty.completeMortage();
    const balance = await ethers.provider.getBalance(rentCollector.address);
    expect(balance).to.equal(mortgageAmount);
  });

  it("Should transfer ownership", async function () {
    await rentalProperty.transferOwnership(investor1.address);
    const newOwner = await rentalProperty.owner();
    expect(newOwner).to.equal(investor1.address);
  });

  it("Should get balance", async function () {
    const balance = await rentalProperty.getBalance(owner.address);
    expect(balance).to.equal(await ethers.provider.getBalance(owner.address));
  });
});
