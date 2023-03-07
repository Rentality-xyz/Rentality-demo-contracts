const {
    time,
    loadFixture,
  } = require("@nomicfoundation/hardhat-network-helpers");
  const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
  const { expect } = require("chai");
  const { ethers } = require("hardhat");

  describe("RentCar", function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    async function deployFixture() {    
      // Contracts are deployed using the first signer/account by default
      const [owner, host, guest] = await ethers.getSigners();
      const MockEthToUsdPriceFeed = await ethers.getContractFactory("MockEthToUsdPriceFeed");
      const RentCar = await ethers.getContractFactory("RentCar");
  
      const mockEthToUsdPriceFeed = await MockEthToUsdPriceFeed.deploy(8, 200000000000);
      await mockEthToUsdPriceFeed.deployed();
      const mockEthToUsdPriceFeedAddress = mockEthToUsdPriceFeed.address;

      const rentCar = await RentCar.deploy(mockEthToUsdPriceFeedAddress);
      await rentCar.deployed();
  
      return { rentCar, mockEthToUsdPriceFeed, owner, host, guest };
    }

    async function deployFixtureWith1Car() {    
      // Contracts are deployed using the first signer/account by default
      const [owner, host, guest] = await ethers.getSigners();
      const MockEthToUsdPriceFeed = await ethers.getContractFactory("MockEthToUsdPriceFeed");
      const RentCar = await ethers.getContractFactory("RentCar");
  
      const mockEthToUsdPriceFeed = await MockEthToUsdPriceFeed.deploy(8, 200000000000);
      await mockEthToUsdPriceFeed.deployed();
      const mockEthToUsdPriceFeedAddress = mockEthToUsdPriceFeed.address;

      const rentCar = await RentCar.deploy(mockEthToUsdPriceFeedAddress);
      await rentCar.deployed();
      
      const PRICE_PER_DAY = 1;
      await rentCar.connect(host).addCar("tokenUri1", PRICE_PER_DAY);

      return { rentCar, mockEthToUsdPriceFeed, owner, host, guest };
    }

    describe("Deployment", function () {
      it("Should set the right owner", async function () {
        const { rentCar, owner } = await loadFixture(deployFixture);

        expect(await rentCar.getOwner()).to.equal(owner.address);
      });

      it("Shouldn't contain tokens when deployed", async function () {
        const { rentCar } = await loadFixture(deployFixture);
  
        expect(await rentCar.getCurrentToken()).to.equal(0);
      });
    });

    describe("Host functions", function () {
      it("Adding car should emit CarAddedSuccess event", async function () {
        const { rentCar, host } = await loadFixture(deployFixture);
        const PRICE_PER_DAY = 1;

        await expect(rentCar.connect(host).addCar("tokenUri1", PRICE_PER_DAY))
        .to.emit(rentCar, "CarAddedSuccess")
        .withArgs(1, host.address, PRICE_PER_DAY,true);
      });

      it("getCarToRentForId should return valid info", async function () {
        const { rentCar, host } = await loadFixture(deployFixture);
        const PRICE_PER_DAY = 1;
        await rentCar.connect(host).addCar("tokenUri1", PRICE_PER_DAY);
        const TOKEN_ID = 1;
        const carToRent = await rentCar.connect(host).getCarToRentForId(TOKEN_ID);

        expect(carToRent.tokenId).to.equal(TOKEN_ID);
        expect(carToRent.owner).to.equal(host.address);
        expect(carToRent.pricePerDayInUsdCents).to.equal(PRICE_PER_DAY);
        expect(carToRent.currentlyListed).to.equal(true);
      });

      it("getMyCars without cars should return empty array", async function () {
        const { rentCar, host } = await loadFixture(deployFixture);
        const myCars = await rentCar.connect(host).getMyCars();

        expect(myCars.length).to.equal(0);
      });

      it("getMyCars with 1 car should return valid info", async function () {
        const { rentCar, host } = await loadFixture(deployFixture);
        const PRICE_PER_DAY = 1;
        await rentCar.connect(host).addCar("tokenUri1", PRICE_PER_DAY);
        const TOKEN_ID = 1;
        const myCars = await rentCar.connect(host).getMyCars();

        expect(myCars.length).to.equal(1);
        expect(myCars[0].tokenId).to.equal(TOKEN_ID);
        expect(myCars[0].owner).to.equal(host.address);
        expect(myCars[0].pricePerDayInUsdCents).to.equal(PRICE_PER_DAY);
        expect(myCars[0].currentlyListed).to.equal(true);
      });

      it("getAllAvailableCars with 1 car shouldn't return data for car owner", async function () {
        const { rentCar, host } = await loadFixture(deployFixture);
        const PRICE_PER_DAY = 1;
        await rentCar.connect(host).addCar("tokenUri1", PRICE_PER_DAY);
        const availableCars = await rentCar.connect(host).getAllAvailableCars();
        
        expect(availableCars.length).to.equal(0);
      });

      it("getAllAvailableCars with 1 car should return data for guest", async function () {
        const { rentCar, host, guest } = await loadFixture(deployFixture);
        const PRICE_PER_DAY = 1;
        await rentCar.connect(host).addCar("tokenUri1", PRICE_PER_DAY);
        const TOKEN_ID = 1;
        const availableCars = await rentCar.connect(guest).getAllAvailableCars();
        
        expect(availableCars.length).to.equal(1);
        expect(availableCars[0].tokenId).to.equal(TOKEN_ID);
        expect(availableCars[0].owner).to.equal(host.address);
        expect(availableCars[0].pricePerDayInUsdCents).to.equal(PRICE_PER_DAY);
        expect(availableCars[0].currentlyListed).to.equal(true);
      });
    });


  
    // describe("Withdrawals", function () {
    //   describe("Validations", function () {
    //     it("Should revert with the right error if called too soon", async function () {
    //       const { lock } = await loadFixture(deployOneYearLockFixture);
  
    //       await expect(lock.withdraw()).to.be.revertedWith(
    //         "You can't withdraw yet"
    //       );
    //     });
  
    //     it("Should revert with the right error if called from another account", async function () {
    //       const { lock, unlockTime, otherAccount } = await loadFixture(
    //         deployOneYearLockFixture
    //       );
  
    //       // We can increase the time in Hardhat Network
    //       await time.increaseTo(unlockTime);
  
    //       // We use lock.connect() to send a transaction from another account
    //       await expect(lock.connect(otherAccount).withdraw()).to.be.revertedWith(
    //         "You aren't the owner"
    //       );
    //     });
  
    //     it("Shouldn't fail if the unlockTime has arrived and the owner calls it", async function () {
    //       const { lock, unlockTime } = await loadFixture(
    //         deployOneYearLockFixture
    //       );
  
    //       // Transactions are sent using the first signer by default
    //       await time.increaseTo(unlockTime);
  
    //       await expect(lock.withdraw()).not.to.be.reverted;
    //     });
    //   });
  
    //   describe("Events", function () {
    //     it("Should emit an event on withdrawals", async function () {
    //       const { lock, unlockTime, lockedAmount } = await loadFixture(
    //         deployOneYearLockFixture
    //       );
  
    //       await time.increaseTo(unlockTime);
  
    //       await expect(lock.withdraw())
    //         .to.emit(lock, "Withdrawal")
    //         .withArgs(lockedAmount, anyValue); // We accept any value as `when` arg
    //     });
    //   });
  
    //   describe("Transfers", function () {
    //     it("Should transfer the funds to the owner", async function () {
    //       const { lock, unlockTime, lockedAmount, owner } = await loadFixture(
    //         deployOneYearLockFixture
    //       );
  
    //       await time.increaseTo(unlockTime);
  
    //       await expect(lock.withdraw()).to.changeEtherBalances(
    //         [owner, lock],
    //         [lockedAmount, -lockedAmount]
    //       );
    //     });
    //   });
    // });
  });
  