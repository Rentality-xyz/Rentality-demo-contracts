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

    let rentalityMockPriceFeed = await RentalityMockPriceFeed.deploy(8, 200000000000);
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
      const availableCars = await rentality.connect(host).getAvailableCarsForUser(host.address);
      expect(availableCars.length).to.equal(0);
    });
    it("Guest see cars as available", async function () {
      const { rentality, host, guest} = await loadFixture(deployDefaultFixture);
      
      await expect(rentality.connect(host).addCar("1","2", 3,4,5)).not.to.be.reverted;
      const myCars = await rentality.connect(host).getMyCars();
      expect(myCars.length).to.equal(1);
      const availableCars = await rentality.connect(guest).getAvailableCars();
      expect(availableCars.length).to.equal(1);
    });
    it("createTripRequest", async function () {
      const { rentality, rentalityCurrencyConverter, host, guest} = await loadFixture(deployDefaultFixture);
      
      await expect(rentality.connect(host).addCar("1","2", 3,4,5)).not.to.be.reverted;
      const myCars = await rentality.connect(host).getMyCars();
      expect(myCars.length).to.equal(1);

      const availableCars = await rentality.connect(guest).getAvailableCars();
      expect(availableCars.length).to.equal(1);

      const rentPriceInUsdCents = 1000;
      const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
        await rentalityCurrencyConverter.getEthFromUsdLatest(
          rentPriceInUsdCents
        );

      await expect(rentality.connect(guest).createTripRequest({carId:1,
        host:host.address,
        startDateTime:1,
        endDateTime:1,
        startLocation:"",
        endLocation:"",
        totalDayPriceInUsdCents:rentPriceInUsdCents,
        taxPriceInUsdCents:0,
        depositInUsdCents:0,
        ethToCurrencyRate:ethToCurrencyRate,
        ethToCurrencyDecimals:ethToCurrencyDecimals}, {value: rentPriceInEth})).not.to.be.reverted;
    });

    it("reject case", async function () {
      const { rentality, rentalityCurrencyConverter, host, guest} = await loadFixture(deployDefaultFixture);
      
      await expect(rentality.connect(host).addCar("1","2", 3,4,5)).not.to.be.reverted;
      const myCars = await rentality.connect(host).getMyCars();
      expect(myCars.length).to.equal(1);

      const availableCars = await rentality.connect(guest).getAvailableCars();
      expect(availableCars.length).to.equal(1);

      const rentPriceInUsdCents = 1000;
      const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
        await rentalityCurrencyConverter.getEthFromUsdLatest(
          rentPriceInUsdCents
        );

      await expect(rentality.connect(guest).createTripRequest({carId:1,
        host:host.address,
        startDateTime:1,
        endDateTime:1,
        startLocation:"",
        endLocation:"",
        totalDayPriceInUsdCents:rentPriceInUsdCents,
        taxPriceInUsdCents:0,
        depositInUsdCents:0,
        ethToCurrencyRate:ethToCurrencyRate,
        ethToCurrencyDecimals:ethToCurrencyDecimals}, {value: rentPriceInEth})).to.changeEtherBalances(
                    [guest, rentality],
                     [-rentPriceInEth, rentPriceInEth]);

      await expect( rentality.connect(host).rejectTripRequest(1)).to.changeEtherBalances(
                    [guest, rentality],
                     [rentPriceInEth, -rentPriceInEth]);
    });

    it("Happy case", async function () {
      const { rentality, rentalityCurrencyConverter, host, guest} = await loadFixture(deployDefaultFixture);
      
      await expect(rentality.connect(host).addCar("1","2", 3,4,5)).not.to.be.reverted;
      const myCars = await rentality.connect(host).getMyCars();
      expect(myCars.length).to.equal(1);
      const availableCars = await rentality.connect(guest).getAvailableCars();
      expect(availableCars.length).to.equal(1);

      const rentPriceInUsdCents = 1000;
      const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
        await rentalityCurrencyConverter.getEthFromUsdLatest(
          rentPriceInUsdCents
        );

      await expect(rentality.connect(guest).createTripRequest({carId:1,
        host:host.address,
        startDateTime:1,
        endDateTime:1,
        startLocation:"",
        endLocation:"",
        totalDayPriceInUsdCents:rentPriceInUsdCents,
        taxPriceInUsdCents:0,
        depositInUsdCents:0,
        ethToCurrencyRate:ethToCurrencyRate,
        ethToCurrencyDecimals:ethToCurrencyDecimals}, {value: rentPriceInEth})).not.to.be.reverted;

      await expect( rentality.connect(host).approveTripRequest(1)).not.to.be.reverted;
      await expect( rentality.connect(host).checkInByHost(1, 0, 0)).not.to.be.reverted;
      await expect( rentality.connect(guest).checkInByGuest(1, 0, 0)).not.to.be.reverted;
      await expect( rentality.connect(guest).checkOutByGuest(1, 0, 0)).not.to.be.reverted;
      await expect( rentality.connect(host).checkOutByHost(1, 0, 0)).not.to.be.reverted;
      const returnToHost = rentPriceInEth - (rentPriceInEth* (await rentality.getPlatformFeeInPPM())) / 1_000_000;
      await expect( rentality.connect(host).finishTrip(1)).to.changeEtherBalances(
        [host, rentality],
         [returnToHost, -returnToHost]);
    });
  });
});
