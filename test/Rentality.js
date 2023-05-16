const { time, loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Rentality", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployDefaultFixture() {
    const [owner, admin, manager, host, guest, anonymous] = await ethers.getSigners();

    const RentalityMockPriceFeed = await ethers.getContractFactory("RentalityMockPriceFeed");
    const RentalityUserService = await ethers.getContractFactory("RentalityUserService");
    const RentalityTripService = await ethers.getContractFactory("RentalityTripService");
    const RentalityCurrencyConverter = await ethers.getContractFactory("RentalityCurrencyConverter");
    const RentalityCarToken = await ethers.getContractFactory("RentalityCarToken");
    const Rentality = await ethers.getContractFactory("Rentality");

    let rentalityMockPriceFeed = await RentalityMockPriceFeed.deploy(8, 165000000000);
    await rentalityMockPriceFeed.deployed();

    const rentalityUserService = await RentalityUserService.deploy();
    await rentalityUserService.deployed();

    await rentalityUserService.connect(owner).grantAdminRole(admin.address);
    await rentalityUserService.connect(owner).grantManagerRole(manager.address);
    await rentalityUserService.connect(owner).grantHostRole(host.address);
    await rentalityUserService.connect(owner).grantGuestRole(guest.address);

    const rentalityTripService = await RentalityTripService.deploy();
    await rentalityTripService.deployed();
    
    const rentalityCurrencyConverter = await RentalityCurrencyConverter.deploy(rentalityMockPriceFeed.address);
    await rentalityCurrencyConverter.deployed();

    const rentalityCarToken = await RentalityCarToken.deploy(rentalityUserService.address);
    await rentalityCarToken.deployed();

    const rentality = await Rentality.deploy(
      rentalityCarToken.address,
      rentalityCurrencyConverter.address,
      rentalityTripService.address,
      rentalityUserService.address);
    await rentality.deployed();

    await rentalityUserService.connect(owner).grantHostRole(rentality.address);

    return { rentalityMockPriceFeed, 
      rentalityUserService,
      rentalityTripService,
      rentalityCurrencyConverter,
      rentalityCarToken, 
      rentality, owner, admin, manager, host, guest, anonymous};
  }

  describe("Rentality", function () {
    it("Host can add car to rentality", async function () {
      const { rentality, host} = await loadFixture(deployDefaultFixture);
      
      await expect(rentality.connect(host).addCar("1","2", 3,4,5)).not.to.be.reverted;
      const myCars = await rentality.connect(host).getMyCars();
      expect(myCars.length).to.equal(1);
    });
    it("Host dont see own cars as available", async function () {
      const { rentality, host} = await loadFixture(deployDefaultFixture);
      
      await expect(rentality.connect(host).addCar("1","2", 3,4,5)).not.to.be.reverted;
      const myCars = await rentality.connect(host).getMyCars();
      expect(myCars.length).to.equal(1);
      const availableCars = await rentality.connect(host).getAllAvailableCarsForUser(host.address);
      expect(availableCars.length).to.equal(0);
    });
    it("Guest see cars as available", async function () {
      const { rentality, host, guest} = await loadFixture(deployDefaultFixture);
      
      await expect(rentality.connect(host).addCar("1","2", 3,4,5)).not.to.be.reverted;
      const myCars = await rentality.connect(host).getMyCars();
      expect(myCars.length).to.equal(1);
      const availableCars = await rentality.connect(guest).getAllAvailableCars();
      expect(availableCars.length).to.equal(1);
    });
  });
});
