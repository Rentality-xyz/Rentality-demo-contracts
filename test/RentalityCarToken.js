const { time, loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("RentalityCarToken", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployDefaultFixture() {
    const [owner, admin, manager, host, guest, anonymous] = await ethers.getSigners();

    const RentalityUserService = await ethers.getContractFactory("RentalityUserService");
    const RentalityCarToken = await ethers.getContractFactory("RentalityCarToken");

    const rentalityUserService = await RentalityUserService.deploy();
    await rentalityUserService.deployed();

    await rentalityUserService.connect(owner).grantAdminRole(admin.address);
    await rentalityUserService.connect(owner).grantManagerRole(manager.address);
    await rentalityUserService.connect(owner).grantHostRole(host.address);
    await rentalityUserService.connect(owner).grantGuestRole(guest.address);

    const rentalityCarToken = await RentalityCarToken.deploy(rentalityUserService.address);
    await rentalityCarToken.deployed();

    return { rentalityCarToken, rentalityUserService, owner, admin, manager, host, guest, anonymous};
  }

  async function deployFixtureWith1Car() {
    const { rentalityCarToken, rentalityUserService, owner, admin, manager, host, guest, anonymous} = await deployDefaultFixture();

    const TOKEN_URI = "TOKEN_URI";
    const VIN_NUMBER = "VIN_NUMBER";
    const PRICE_PER_DAY = 2;
    const TANK_VOLUME = 3;
    const DISTANCE_INCLUDED = 4;
    await rentalityCarToken.connect(host).addCar(TOKEN_URI, VIN_NUMBER, PRICE_PER_DAY, TANK_VOLUME, DISTANCE_INCLUDED);

    return { rentalityCarToken, rentalityUserService, owner, admin, manager, host, guest, anonymous};
  }

  async function deployFixtureWith2UserService() {
    const [owner, admin1, admin2] = await ethers.getSigners();

    const RentalityUserService1 = await ethers.getContractFactory("RentalityUserService");
    const RentalityUserService2 = await ethers.getContractFactory("RentalityUserService");
    const RentalityCarToken = await ethers.getContractFactory("RentalityCarToken");

    const rentalityUserService1 = await RentalityUserService1.deploy();
    await rentalityUserService1.deployed();

    const rentalityUserService2 = await RentalityUserService2.deploy();
    await rentalityUserService2.deployed();

    await rentalityUserService1.connect(owner).grantAdminRole(admin1.address);
    await rentalityUserService2.connect(owner).grantAdminRole(admin2.address);

    const rentalityCarToken = await RentalityCarToken.deploy(rentalityUserService1.address);
    await rentalityCarToken.deployed();

    return { rentalityCarToken, rentalityUserService1, rentalityUserService2, admin1, admin2 };
  }

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      const { rentalityCarToken, owner } = await loadFixture(deployDefaultFixture);

      expect(await rentalityCarToken.owner()).to.equal(owner.address);
    });    

    it("Shouldn't contain tokens when deployed", async function () {
      const { rentalityCarToken } = await loadFixture(deployDefaultFixture);

      expect(await rentalityCarToken.totalSupply()).to.equal(0);
    });

    it("deployFixtureWith1Car should contain 1 tokens when deployed", async function () {
      const { rentalityCarToken } = await loadFixture(deployFixtureWith1Car);

      expect(await rentalityCarToken.totalSupply()).to.equal(1);
    });
  });

  describe("User service", function () {
    it("Only Admin can update UserService", async function () {
      const { rentalityCarToken, rentalityUserService, owner, admin, manager, host, guest, anonymous } = await loadFixture(deployDefaultFixture);
      
      await expect(rentalityCarToken.connect(anonymous).updateUserService(rentalityUserService.address)).to.be.reverted;
      await expect(rentalityCarToken.connect(guest).updateUserService(rentalityUserService.address)).to.be.reverted;
      await expect(rentalityCarToken.connect(host).updateUserService(rentalityUserService.address)).to.be.reverted;
      await expect(rentalityCarToken.connect(manager).updateUserService(rentalityUserService.address)).to.be.reverted;
      await expect(rentalityCarToken.connect(admin).updateUserService(rentalityUserService.address)).not.to.be.reverted;
      await expect(rentalityCarToken.connect(owner).updateUserService(rentalityUserService.address)).not.to.be.reverted;
    });
    
    it("After updateUserService there is new admin", async function () {
      const { rentalityCarToken, rentalityUserService1, rentalityUserService2, admin1, admin2 } = await loadFixture(deployFixtureWith2UserService);
      
      await expect(rentalityCarToken.connect(admin1).updateUserService(rentalityUserService2.address)).not.to.be.reverted;
      await expect(rentalityCarToken.connect(admin1).updateUserService(rentalityUserService1.address)).to.be.reverted;
      await expect(rentalityCarToken.connect(admin2).updateUserService(rentalityUserService1.address)).not.to.be.reverted;
      await expect(rentalityCarToken.connect(admin2).updateUserService(rentalityUserService2.address)).to.be.reverted;
    });
  });

  describe("Host functions", function () {
    it("Adding car should emit CarAddedSuccess event", async function () {
      const { rentalityCarToken, host } = await loadFixture(deployDefaultFixture);
      
      const TOKEN_URI = "TOKEN_URI";
      const VIN_NUMBER = "VIN_NUMBER";
      const PRICE_PER_DAY = 2;
      const TANK_VOLUME = 3;
      const DISTANCE_INCLUDED = 4;

      await expect(rentalityCarToken.connect(host).addCar(TOKEN_URI, VIN_NUMBER, PRICE_PER_DAY, TANK_VOLUME, DISTANCE_INCLUDED))
      .to.emit(rentalityCarToken, "CarAddedSuccess")
      .withArgs(VIN_NUMBER, host.address, PRICE_PER_DAY, true);
    });

    it("Adding car with the same VIN number should be reverted", async function () {
      const { rentalityCarToken, host } = await loadFixture(deployDefaultFixture);
      
      const TOKEN_URI1 = "TOKEN_URI1";
      const VIN_NUMBER1 = "VIN_NUMBER";
      const PRICE_PER_DAY1 = 2;
      const TANK_VOLUME1 = 3;
      const DISTANCE_INCLUDED1 = 4;

      const TOKEN_URI2 = "TOKEN_URI2";
      const VIN_NUMBER2 = "VIN_NUMBER";
      const PRICE_PER_DAY2 = 5;
      const TANK_VOLUME2 = 6;
      const DISTANCE_INCLUDED2 = 7;

      await expect(rentalityCarToken.connect(host).addCar(TOKEN_URI1, VIN_NUMBER1, PRICE_PER_DAY1, TANK_VOLUME1, DISTANCE_INCLUDED1)).not.be.reverted;
      await expect(rentalityCarToken.connect(host).addCar(TOKEN_URI2, VIN_NUMBER2, PRICE_PER_DAY2, TANK_VOLUME2, DISTANCE_INCLUDED2)).to.be.reverted;
    });

    it("Adding car with the different VIN number should not be reverted", async function () {
      const { rentalityCarToken, host } = await loadFixture(deployDefaultFixture);
      
      const TOKEN_URI1 = "TOKEN_URI1";
      const VIN_NUMBER1 = "VIN_NUMBER1";
      const PRICE_PER_DAY1 = 2;
      const TANK_VOLUME1 = 3;
      const DISTANCE_INCLUDED1 = 4;

      const TOKEN_URI2 = "TOKEN_URI2";
      const VIN_NUMBER2 = "VIN_NUMBER2";
      const PRICE_PER_DAY2 = 5;
      const TANK_VOLUME2 = 6;
      const DISTANCE_INCLUDED2 = 7;

      await expect(rentalityCarToken.connect(host).addCar(TOKEN_URI1, VIN_NUMBER1, PRICE_PER_DAY1, TANK_VOLUME1, DISTANCE_INCLUDED1)).not.be.reverted;
      await expect(rentalityCarToken.connect(host).addCar(TOKEN_URI2, VIN_NUMBER2, PRICE_PER_DAY2, TANK_VOLUME2, DISTANCE_INCLUDED2)).not.be.reverted;
    });

    it("Only owner of the car can burn token", async function () {
      const { rentalityCarToken, owner, admin, host, anonymous } = await loadFixture(deployFixtureWith1Car);
      
      await expect(rentalityCarToken.connect(anonymous).burnCar(1)).to.be.reverted;
      await expect(rentalityCarToken.connect(admin).burnCar(1)).to.be.reverted;
      await expect(rentalityCarToken.connect(owner).burnCar(1)).to.be.reverted;

      expect(await rentalityCarToken.balanceOf(host.address)).to.equal(1);
      await expect(rentalityCarToken.connect(host).burnCar(1)).not.be.reverted;
      expect(await rentalityCarToken.balanceOf(host.address)).to.equal(0);
    });

    it("getCarInfoById should return valid info", async function () {
      const { rentalityCarToken, host } = await loadFixture(deployFixtureWith1Car);
      
      const TOKEN_ID = 1;
      const VIN_NUMBER = "VIN_NUMBER";
      const PRICE_PER_DAY = 2;
      const TANK_VOLUME = 3;
      const DISTANCE_INCLUDED = 4;
      
      const carInfo = await rentalityCarToken.connect(host).getCarInfoById(TOKEN_ID);

      expect(carInfo.carVinNumber).to.equal(VIN_NUMBER);
      expect(carInfo.createdBy).to.equal(host.address);
      expect(carInfo.pricePerDayInUsdCents).to.equal(PRICE_PER_DAY);
      expect(carInfo.tankVolumeInGal).to.equal(TANK_VOLUME);
      expect(carInfo.distanceIncludedInMi).to.equal(DISTANCE_INCLUDED);
      expect(carInfo.currentlyListed).to.equal(true);
    });

    it("getMyCars without cars should return empty array", async function () {
      const { rentalityCarToken, host } = await loadFixture(deployDefaultFixture);
      const myCars = await rentalityCarToken.connect(host).getMyCars();

      expect(myCars.length).to.equal(0);
    });

    it("getMyCars after burn car should return empty array", async function () {
      const { rentalityCarToken, host } = await loadFixture(deployFixtureWith1Car);

      await rentalityCarToken.connect(host).burnCar(1);      
      const myCars = await rentalityCarToken.connect(host).getMyCars();

      expect(myCars.length).to.equal(0);
    });

    it("getMyCars with 1 car should return valid info", async function () {
      const { rentalityCarToken, host } = await loadFixture(deployFixtureWith1Car);
      
      const VIN_NUMBER = "VIN_NUMBER";
      const PRICE_PER_DAY = 2;
      const TANK_VOLUME = 3;
      const DISTANCE_INCLUDED = 4;
      
      const myCars = await rentalityCarToken.connect(host).getMyCars();

      expect(myCars.length).to.equal(1);
      expect(myCars[0].carVinNumber).to.equal(VIN_NUMBER);
      expect(myCars[0].createdBy).to.equal(host.address);
      expect(myCars[0].pricePerDayInUsdCents).to.equal(PRICE_PER_DAY);
      expect(myCars[0].tankVolumeInGal).to.equal(TANK_VOLUME);
      expect(myCars[0].distanceIncludedInMi).to.equal(DISTANCE_INCLUDED);
      expect(myCars[0].currentlyListed).to.equal(true);
    });

    it("getAllAvailableCars with 1 car shouldn't return data for car owner", async function () {
      const { rentalityCarToken, host } = await loadFixture(deployFixtureWith1Car);
      
      const availableCars = await rentalityCarToken.getAllAvailableCarsForUser(host.address);
      
      expect(availableCars.length).to.equal(0);
    });

    it("getAllAvailableCars with 1 car should return data for guest", async function () {
      const { rentalityCarToken, host, guest } = await loadFixture(deployFixtureWith1Car);
      
      const VIN_NUMBER = "VIN_NUMBER";
      const PRICE_PER_DAY = 2;
      const TANK_VOLUME = 3;
      const DISTANCE_INCLUDED = 4;
      
      const availableCars = await rentalityCarToken.getAllAvailableCarsForUser(guest.address);
      
      expect(availableCars.length).to.equal(1);
      expect(availableCars[0].carVinNumber).to.equal(VIN_NUMBER);
      expect(availableCars[0].createdBy).to.equal(host.address);
      expect(availableCars[0].pricePerDayInUsdCents).to.equal(PRICE_PER_DAY);
      expect(availableCars[0].tankVolumeInGal).to.equal(TANK_VOLUME);
      expect(availableCars[0].distanceIncludedInMi).to.equal(DISTANCE_INCLUDED);
      expect(availableCars[0].currentlyListed).to.equal(true);
    });
  });
});
