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
      rentalityCarToken.connect(host).burnCar(1);
      
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
  // describe("Role management", function () {
  //   it("Admin should have Manager role", async function () {
  //     const { rentalityUserService, admin } = await loadFixture(deployFixtureWithUsers);

  //     expect(await rentalityUserService.isAdmin(admin.address)).to.equal(true);
  //     expect(await rentalityUserService.isManager(admin.address)).to.equal(true);
  //     expect(await rentalityUserService.isHost(admin.address)).to.equal(false);
  //     expect(await rentalityUserService.isGuest(admin.address)).to.equal(false);
  //   });

  //   it("Anonymous shouldn't get any role", async function () {
  //     const { rentalityUserService, anonymous } = await loadFixture(deployFixtureWithUsers);

  //     expect(await rentalityUserService.isAdmin(anonymous.address)).to.equal(false);
  //     expect(await rentalityUserService.isManager(anonymous.address)).to.equal(false);
  //     expect(await rentalityUserService.isHost(anonymous.address)).to.equal(false);
  //     expect(await rentalityUserService.isGuest(anonymous.address)).to.equal(false);
  //   });

  //   it("Only Admin can grandAdminRole", async function () {
  //     const { rentalityUserService, admin, manager, host, guest, anonymous } = await loadFixture(deployFixtureWithUsers);

  //     await expect(rentalityUserService.connect(admin).grantAdminRole(admin.address)).not.to.be.reverted;
  //     await expect(rentalityUserService.connect(manager).grantAdminRole(admin.address)).to.be.reverted;
  //     await expect(rentalityUserService.connect(host).grantAdminRole(admin.address)).to.be.reverted;
  //     await expect(rentalityUserService.connect(guest).grantAdminRole(admin.address)).to.be.reverted;
  //     await expect(rentalityUserService.connect(anonymous).grantAdminRole(admin.address)).to.be.reverted;
  //   });

  //   it("Only Admin can revokeAdminRole", async function () {
  //     const { rentalityUserService, owner, admin, manager, host, guest, anonymous } = await loadFixture(deployFixtureWithUsers);

  //     await expect(rentalityUserService.connect(anonymous).revokeAdminRole(owner.address)).to.be.reverted;
  //     await expect(rentalityUserService.connect(guest).revokeAdminRole(owner.address)).to.be.reverted;
  //     await expect(rentalityUserService.connect(host).revokeAdminRole(owner.address)).to.be.reverted;
  //     await expect(rentalityUserService.connect(manager).revokeAdminRole(owner.address)).to.be.reverted;
  //     await expect(rentalityUserService.connect(admin).revokeAdminRole(owner.address)).not.to.be.reverted;
  //   });

  //   it("Only Admin can grantManagerRole", async function () {
  //     const { rentalityUserService, admin, manager, host, guest, anonymous } = await loadFixture(deployFixtureWithUsers);

  //     await expect(rentalityUserService.connect(admin).grantManagerRole(manager.address)).not.to.be.reverted;
  //     await expect(rentalityUserService.connect(manager).grantManagerRole(manager.address)).to.be.reverted;
  //     await expect(rentalityUserService.connect(host).grantManagerRole(manager.address)).to.be.reverted;
  //     await expect(rentalityUserService.connect(guest).grantManagerRole(manager.address)).to.be.reverted;
  //     await expect(rentalityUserService.connect(anonymous).grantManagerRole(manager.address)).to.be.reverted;
  //   });

  //   it("Only Admin can revokeManagerRole", async function () {
  //     const { rentalityUserService, admin, manager, host, guest, anonymous } = await loadFixture(deployFixtureWithUsers);

  //     await expect(rentalityUserService.connect(anonymous).revokeManagerRole(manager.address)).to.be.reverted;
  //     await expect(rentalityUserService.connect(guest).revokeManagerRole(manager.address)).to.be.reverted;
  //     await expect(rentalityUserService.connect(host).revokeManagerRole(manager.address)).to.be.reverted;
  //     await expect(rentalityUserService.connect(manager).revokeManagerRole(manager.address)).to.be.reverted;
  //     await expect(rentalityUserService.connect(admin).revokeManagerRole(manager.address)).not.to.be.reverted;
  //   });

  //   it("Only Admin and Manager can grantHostRole", async function () {
  //     const { rentalityUserService, admin, manager, host, guest, anonymous } = await loadFixture(deployFixtureWithUsers);

  //     await expect(rentalityUserService.connect(admin).grantHostRole(host.address)).not.to.be.reverted;
  //     await expect(rentalityUserService.connect(manager).grantHostRole(host.address)).not.to.be.reverted;
  //     await expect(rentalityUserService.connect(host).grantHostRole(host.address)).to.be.reverted;
  //     await expect(rentalityUserService.connect(guest).grantHostRole(host.address)).to.be.reverted;
  //     await expect(rentalityUserService.connect(anonymous).grantHostRole(host.address)).to.be.reverted;
  //   });

  //   it("Only Admin and Manager can revokeHostRole", async function () {
  //     const { rentalityUserService, admin, manager, host, guest, anonymous } = await loadFixture(deployFixtureWithUsers);

  //     await expect(rentalityUserService.connect(anonymous).revokeHostRole(host.address)).to.be.reverted;
  //     await expect(rentalityUserService.connect(guest).revokeHostRole(host.address)).to.be.reverted;
  //     await expect(rentalityUserService.connect(host).revokeHostRole(host.address)).to.be.reverted;
  //     await expect(rentalityUserService.connect(manager).revokeHostRole(host.address)).not.to.be.reverted;
  //     await expect(rentalityUserService.connect(admin).revokeHostRole(host.address)).not.to.be.reverted;
  //   });

  //   it("Only Admin and Manager can grantGuestRole", async function () {
  //     const { rentalityUserService, admin, manager, host, guest, anonymous } = await loadFixture(deployFixtureWithUsers);

  //     await expect(rentalityUserService.connect(admin).grantGuestRole(guest.address)).not.to.be.reverted;
  //     await expect(rentalityUserService.connect(manager).grantGuestRole(guest.address)).not.to.be.reverted;
  //     await expect(rentalityUserService.connect(host).grantGuestRole(guest.address)).to.be.reverted;
  //     await expect(rentalityUserService.connect(guest).grantGuestRole(guest.address)).to.be.reverted;
  //     await expect(rentalityUserService.connect(anonymous).grantGuestRole(guest.address)).to.be.reverted;
  //   });

  //   it("Only Admin and Manager can revokeGuestRole", async function () {
  //     const { rentalityUserService, admin, manager, host, guest, anonymous } = await loadFixture(deployFixtureWithUsers);

  //     await expect(rentalityUserService.connect(anonymous).revokeGuestRole(guest.address)).to.be.reverted;
  //     await expect(rentalityUserService.connect(guest).revokeGuestRole(guest.address)).to.be.reverted;
  //     await expect(rentalityUserService.connect(host).revokeGuestRole(guest.address)).to.be.reverted;
  //     await expect(rentalityUserService.connect(manager).revokeGuestRole(guest.address)).not.to.be.reverted;
  //     await expect(rentalityUserService.connect(admin).revokeGuestRole(guest.address)).not.to.be.reverted;
  //   });
  // });

  // describe("KYC management", function () {
  //   it("By default user doesn't have valid KYC", async function () {
  //     const { rentalityUserService, anonymous } = await loadFixture(deployFixtureWithUsers);

  //     expect(await rentalityUserService.hasValidKYC(anonymous.address)).to.equal(false);
  //   });

  //   it("After adding valid KYCInfo user has valid KYC", async function () {
  //     const { rentalityUserService, anonymous } = await loadFixture(deployFixtureWithUsers);
  //     const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
  //     const expirationDate = (await time.latest()) + ONE_YEAR_IN_SECS;

  //     await rentalityUserService.setKYCInfo(anonymous.address, {licenseNumber:"licenseNumber", expirationDate:expirationDate});

  //     expect(await rentalityUserService.hasValidKYC(anonymous.address)).to.equal(true);
  //   });

  //   it("After adding invalid KYCInfo user doesn't have valid KYC", async function () {
  //     const { rentalityUserService, anonymous } = await loadFixture(deployFixtureWithUsers);
  //     const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
  //     const expirationDate = (await time.latest()) + ONE_YEAR_IN_SECS;
      
  //     await rentalityUserService.setKYCInfo(anonymous.address, {licenseNumber:"licenseNumber", expirationDate:expirationDate});
  //     await time.increaseTo(expirationDate + 1);

  //     expect(await rentalityUserService.hasValidKYC(anonymous.address)).to.equal(false);
  //   });
  // });
});
