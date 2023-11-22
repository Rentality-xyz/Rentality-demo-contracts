const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { expect } = require('chai')
const { ethers } = require('hardhat')

describe('RentalityCarToken', function () {
  async function deployDefaultFixture() {
    const [owner, admin, manager, host, guest, anonymous] =
      await ethers.getSigners()

    const RentalityUtils = await ethers.getContractFactory('RentalityUtils')
    const utils = await RentalityUtils.deploy()

    const RentalityUserService = await ethers.getContractFactory(
      'RentalityUserService',
    )
    const RentalityCarToken =
      await ethers.getContractFactory('RentalityCarToken')

    const RentalityCurrencyConverter = await ethers.getContractFactory(
      'RentalityCurrencyConverter',
    )
    const RentalityPaymentService = await ethers.getContractFactory(
      'RentalityPaymentService',
    )
    const RentalityMockPriceFeed = await ethers.getContractFactory(
      'RentalityMockPriceFeed',
    )

    let rentalityMockPriceFeed = await RentalityMockPriceFeed.deploy(
      8,
      200000000000,
    )
    const rentalityPaymentService = await RentalityPaymentService.deploy()
    const rentalityCurrencyConverter = await RentalityCurrencyConverter.deploy(
      rentalityMockPriceFeed.address,
    )
    const rentalityUserService = await RentalityUserService.deploy()

    await rentalityUserService.deployed()
    await rentalityCurrencyConverter.deployed()
    await rentalityPaymentService.deployed()
    await rentalityMockPriceFeed.deployed()

    await rentalityUserService.connect(owner).grantAdminRole(admin.address)
    await rentalityUserService.connect(owner).grantManagerRole(manager.address)
    await rentalityUserService.connect(owner).grantHostRole(host.address)
    await rentalityUserService.connect(owner).grantGuestRole(guest.address)

    const rentalityCarToken = await RentalityCarToken.deploy()
    const rentalityCarService = await rentalityCarToken.deployed()

    const RentalityTripService = await ethers.getContractFactory(
      'RentalityTripService',
      { libraries: { RentalityUtils: utils.address } },
    )

    const rentalityTripService = await RentalityTripService.deploy(
      rentalityCurrencyConverter.address,
      rentalityCarService.address,
      rentalityPaymentService.address,
      rentalityUserService.address,
    )

    await rentalityTripService.deployed()

    await rentalityUserService
      .connect(owner)
      .grantManagerRole(rentalityTripService.address)

    return {
      rentalityCarToken,
      rentalityUserService,
      rentalityTripService,
      owner,
      admin,
      manager,
      host,
      guest,
      anonymous,
    }
  }

  async function deployFixtureWith1Car() {
    const {
      rentalityCarToken,
      rentalityUserService,
      rentalityTripService,
      owner,
      admin,
      manager,
      host,
      guest,
      anonymous,
    } = await deployDefaultFixture()

    const request = getMockCarRequest(0)

    await rentalityCarToken.connect(host).addCar(request)

    return {
      rentalityCarToken,
      rentalityUserService,
      rentalityTripService,
      owner,
      admin,
      manager,
      host,
      guest,
      anonymous,
    }
  }

  async function deployFixtureWith2UserService() {
    const [owner, admin1, admin2] = await ethers.getSigners()

    const RentalityUserService1 = await ethers.getContractFactory(
      'RentalityUserService',
    )
    const RentalityUserService2 = await ethers.getContractFactory(
      'RentalityUserService',
    )
    const RentalityCarToken =
      await ethers.getContractFactory('RentalityCarToken')

    const rentalityUserService1 = await RentalityUserService1.deploy()
    await rentalityUserService1.deployed()

    const rentalityUserService2 = await RentalityUserService2.deploy()
    await rentalityUserService2.deployed()

    await rentalityUserService1.connect(owner).grantAdminRole(admin1.address)
    await rentalityUserService2.connect(owner).grantAdminRole(admin2.address)

    const rentalityCarToken = await RentalityCarToken.deploy()
    await rentalityCarToken.deployed()

    return {
      rentalityCarToken,
      rentalityUserService1,
      rentalityUserService2,
      admin1,
      admin2,
    }
  }

  describe('Deployment', function () {
    it('Should set the right owner', async function () {
      const { rentalityCarToken, owner } =
        await loadFixture(deployDefaultFixture)

      expect(await rentalityCarToken.owner()).to.equal(owner.address)
    })

    it("Shouldn't contain tokens when deployed", async function () {
      const { rentalityCarToken } = await loadFixture(deployDefaultFixture)

      expect(await rentalityCarToken.totalSupply()).to.equal(0)
    })

    it('deployFixtureWith1Car should contain 1 tokens when deployed', async function () {
      const { rentalityCarToken } = await loadFixture(deployFixtureWith1Car)

      expect(await rentalityCarToken.totalSupply()).to.equal(1)
    })
  })

  describe('Host functions', function () {
    it('Adding car should emit CarAddedSuccess event', async function () {
      const { rentalityCarToken, host } =
        await loadFixture(deployDefaultFixture)

      const request = getMockCarRequest(0)

      await expect(rentalityCarToken.connect(host).addCar(request))
        .to.emit(rentalityCarToken, 'CarAddedSuccess')
        .withArgs(
          1,
          request.carVinNumber,
          host.address,
          request.pricePerDayInUsdCents,
          true,
        )
    })

    it('Adding car with the same VIN number should be reverted', async function () {
      const { rentalityCarToken, host } =
        await loadFixture(deployDefaultFixture)

      const request1 = getMockCarRequest(0)
      const request2 = {
        ...getMockCarRequest(1),
        carVinNumber: request1.carVinNumber,
      }

      await expect(rentalityCarToken.connect(host).addCar(request1)).not.be
        .reverted
      await expect(rentalityCarToken.connect(host).addCar(request2)).to.be
        .reverted
    })

    it('Adding car with the different VIN number should not be reverted', async function () {
      const { rentalityCarToken, host } =
        await loadFixture(deployDefaultFixture)

      const request1 = getMockCarRequest(0)
      const request2 = getMockCarRequest(1)

      await expect(rentalityCarToken.connect(host).addCar(request1)).not.be
        .reverted
      await expect(rentalityCarToken.connect(host).addCar(request2)).not.be
        .reverted
    })

    it('Only owner of the car can burn token', async function () {
      const { rentalityCarToken, owner, admin, host, anonymous } =
        await loadFixture(deployFixtureWith1Car)

      await expect(rentalityCarToken.connect(anonymous).burnCar(1)).to.be
        .reverted
      await expect(rentalityCarToken.connect(admin).burnCar(1)).to.be.reverted
      await expect(rentalityCarToken.connect(owner).burnCar(1)).to.be.reverted

      expect(await rentalityCarToken.balanceOf(host.address)).to.equal(1)
      await expect(rentalityCarToken.connect(host).burnCar(1)).not.be.reverted
      expect(await rentalityCarToken.balanceOf(host.address)).to.equal(0)
    })

    it('getCarInfoById should return valid info', async function () {
      const { rentalityCarToken, host } = await loadFixture(
        deployFixtureWith1Car,
      )

      const TOKEN_ID = 1
      const request = getMockCarRequest(0)

      const carInfo = await rentalityCarToken
        .connect(host)
        .getCarInfoById(TOKEN_ID)

      expect(carInfo.carVinNumber).to.equal(request.carVinNumber)
      expect(carInfo.createdBy).to.equal(host.address)
      expect(carInfo.pricePerDayInUsdCents).to.equal(
        request.pricePerDayInUsdCents,
      )
      expect(carInfo.securityDepositPerTripInUsdCents).to.equal(
        request.securityDepositPerTripInUsdCents,
      )
      expect(carInfo.tankVolumeInGal).to.equal(request.tankVolumeInGal)
      expect(carInfo.fuelPricePerGalInUsdCents).to.equal(
        request.fuelPricePerGalInUsdCents,
      )
      expect(carInfo.milesIncludedPerDay).to.equal(request.milesIncludedPerDay)
      expect(carInfo.country).to.equal(request.country)
      expect(carInfo.state).to.equal(request.state)
      expect(carInfo.city).to.equal(request.city)
      expect(carInfo.locationLatitudeInPPM).to.equal(
        request.locationLatitudeInPPM,
      )
      expect(carInfo.locationLongitudeInPPM).to.equal(
        request.locationLongitudeInPPM,
      )
      expect(carInfo.currentlyListed).to.equal(true)
    })

    it('getCarsOwnedByUser without cars should return empty array', async function () {
      const { rentalityCarToken, host } =
        await loadFixture(deployDefaultFixture)
      const myCars = await rentalityCarToken
        .connect(host)
        .getCarsOwnedByUser(host.address)

      expect(myCars.length).to.equal(0)
    })

    it('getCarsOwnedByUser after burn car should return empty array', async function () {
      const { rentalityCarToken, host } = await loadFixture(
        deployFixtureWith1Car,
      )

      await rentalityCarToken.connect(host).burnCar(1)
      const myCars = await rentalityCarToken
        .connect(host)
        .getCarsOwnedByUser(host.address)

      expect(myCars.length).to.equal(0)
    })

    it('getCarsOwnedByUser with 1 car should return valid info', async function () {
      const { rentalityCarToken, host } = await loadFixture(
        deployFixtureWith1Car,
      )

      const request = getMockCarRequest(0)

      const myCars = await rentalityCarToken
        .connect(host)
        .getCarsOwnedByUser(host.address)

      expect(myCars.length).to.equal(1)

      expect(myCars[0].carVinNumber).to.equal(request.carVinNumber)
      expect(myCars[0].createdBy).to.equal(host.address)
      expect(myCars[0].pricePerDayInUsdCents).to.equal(
        request.pricePerDayInUsdCents,
      )
      expect(myCars[0].securityDepositPerTripInUsdCents).to.equal(
        request.securityDepositPerTripInUsdCents,
      )
      expect(myCars[0].tankVolumeInGal).to.equal(request.tankVolumeInGal)
      expect(myCars[0].fuelPricePerGalInUsdCents).to.equal(
        request.fuelPricePerGalInUsdCents,
      )
      expect(myCars[0].milesIncludedPerDay).to.equal(
        request.milesIncludedPerDay,
      )
      expect(myCars[0].country).to.equal(request.country)
      expect(myCars[0].state).to.equal(request.state)
      expect(myCars[0].city).to.equal(request.city)
      expect(myCars[0].locationLatitudeInPPM).to.equal(
        request.locationLatitudeInPPM,
      )
      expect(myCars[0].locationLongitudeInPPM).to.equal(
        request.locationLongitudeInPPM,
      )
      expect(myCars[0].currentlyListed).to.equal(true)
    })

    it("getAllAvailableCars with 1 car shouldn't return data for car owner", async function () {
      const { rentalityCarToken, host } = await loadFixture(
        deployFixtureWith1Car,
      )

      const availableCars = await rentalityCarToken.getAvailableCarsForUser(
        host.address,
      )

      expect(availableCars.length).to.equal(0)
    })

    it('getAllAvailableCars with 1 car should return data for guest', async function () {
      const { rentalityCarToken, host, guest } = await loadFixture(
        deployFixtureWith1Car,
      )

      const request = getMockCarRequest(0)

      const availableCars = await rentalityCarToken.getAvailableCarsForUser(
        guest.address,
      )

      expect(availableCars.length).to.equal(1)
      expect(availableCars[0].carVinNumber).to.equal(request.carVinNumber)
      expect(availableCars[0].createdBy).to.equal(host.address)
      expect(availableCars[0].pricePerDayInUsdCents).to.equal(
        request.pricePerDayInUsdCents,
      )
      expect(availableCars[0].securityDepositPerTripInUsdCents).to.equal(
        request.securityDepositPerTripInUsdCents,
      )
      expect(availableCars[0].tankVolumeInGal).to.equal(request.tankVolumeInGal)
      expect(availableCars[0].fuelPricePerGalInUsdCents).to.equal(
        request.fuelPricePerGalInUsdCents,
      )
      expect(availableCars[0].milesIncludedPerDay).to.equal(
        request.milesIncludedPerDay,
      )
      expect(availableCars[0].country).to.equal(request.country)
      expect(availableCars[0].state).to.equal(request.state)
      expect(availableCars[0].city).to.equal(request.city)
      expect(availableCars[0].locationLatitudeInPPM).to.equal(
        request.locationLatitudeInPPM,
      )
      expect(availableCars[0].locationLongitudeInPPM).to.equal(
        request.locationLongitudeInPPM,
      )
      expect(availableCars[0].currentlyListed).to.equal(true)
    })
  })

  describe('Search functions', function () {
    it('Search with empty should return car', async function () {
      const { rentalityCarToken, rentalityTripService, guest } =
        await loadFixture(deployFixtureWith1Car)

      const searchCarParams = {
        country: '',
        state: '',
        city: '',
        brand: '',
        model: '',
        yearOfProductionFrom: 0,
        yearOfProductionTo: 0,
        pricePerDayInUsdCentsFrom: 0,
        pricePerDayInUsdCentsTo: 0,
      }

      const availableCars =
        await rentalityTripService.searchAvailableCarsForUser(
          guest.address,
          0,
          0,
          searchCarParams,
        )

      expect(availableCars.length).to.equal(1)
    })

    it('Search with brand should work', async function () {
      const { rentalityCarToken, rentalityTripService, guest } =
        await loadFixture(deployFixtureWith1Car)

      const request = getMockCarRequest(0)
      const searchCarParams1 = {
        country: '',
        state: '',
        city: '',
        brand: request.brand,
        model: '',
        yearOfProductionFrom: 0,
        yearOfProductionTo: 0,
        pricePerDayInUsdCentsFrom: 0,
        pricePerDayInUsdCentsTo: 0,
      }
      const searchCarParams2 = {
        country: '',
        state: '',
        city: '',
        brand: request.brand + 'other',
        model: '',
        yearOfProductionFrom: 0,
        yearOfProductionTo: 0,
        pricePerDayInUsdCentsFrom: 0,
        pricePerDayInUsdCentsTo: 0,
      }

      const availableCars1 =
        await rentalityTripService.searchAvailableCarsForUser(
          guest.address,
          0,
          0,
          searchCarParams1,
        )

      expect(availableCars1.length).to.equal(1)

      const availableCars2 =
        await rentalityTripService.searchAvailableCarsForUser(
          guest.address,
          0,
          0,
          searchCarParams2,
        )

      expect(availableCars2.length).to.equal(0)
    })

    it('Search with model should work', async function () {
      const { rentalityCarToken, rentalityTripService, guest } =
        await loadFixture(deployFixtureWith1Car)

      const request = getMockCarRequest(0)
      const searchCarParams1 = {
        country: '',
        state: '',
        city: '',
        brand: '',
        model: request.model,
        yearOfProductionFrom: 0,
        yearOfProductionTo: 0,
        pricePerDayInUsdCentsFrom: 0,
        pricePerDayInUsdCentsTo: 0,
      }
      const searchCarParams2 = {
        country: '',
        state: '',
        city: '',
        brand: '',
        model: request.model + 'other',
        yearOfProductionFrom: 0,
        yearOfProductionTo: 0,
        pricePerDayInUsdCentsFrom: 0,
        pricePerDayInUsdCentsTo: 0,
      }

      const availableCars1 =
        await rentalityTripService.searchAvailableCarsForUser(
          guest.address,
          0,
          0,
          searchCarParams1,
        )

      expect(availableCars1.length).to.equal(1)

      const availableCars2 =
        await rentalityTripService.searchAvailableCarsForUser(
          guest.address,
          0,
          0,
          searchCarParams2,
        )

      expect(availableCars2.length).to.equal(0)
    })

    it('Search with yearOfProduction should work', async function () {
      const { rentalityCarToken, rentalityTripService, guest } =
        await loadFixture(deployFixtureWith1Car)

      const request = getMockCarRequest(0)
      const searchCarParams1 = {
        country: '',
        state: '',
        city: '',
        brand: '',
        model: '',
        yearOfProductionFrom: request.yearOfProduction,
        yearOfProductionTo: 0,
        pricePerDayInUsdCentsFrom: 0,
        pricePerDayInUsdCentsTo: 0,
      }
      const searchCarParams2 = {
        country: '',
        state: '',
        city: '',
        brand: '',
        model: '',
        yearOfProductionFrom: request.yearOfProduction + 1,
        yearOfProductionTo: 0,
        pricePerDayInUsdCentsFrom: 0,
        pricePerDayInUsdCentsTo: 0,
      }

      const availableCars1 =
        await rentalityTripService.searchAvailableCarsForUser(
          guest.address,
          0,
          0,
          searchCarParams1,
        )

      expect(availableCars1.length).to.equal(1)

      const availableCars2 =
        await rentalityTripService.searchAvailableCarsForUser(
          guest.address,
          0,
          0,
          searchCarParams2,
        )

      expect(availableCars2.length).to.equal(0)
    })

    it('Search with country should work', async function () {
      const { rentalityCarToken, rentalityTripService, guest } =
        await loadFixture(deployFixtureWith1Car)

      const request = getMockCarRequest(0)
      const searchCarParams1 = {
        country: request.country,
        state: '',
        city: '',
        brand: '',
        model: '',
        yearOfProductionFrom: 0,
        yearOfProductionTo: 0,
        pricePerDayInUsdCentsFrom: 0,
        pricePerDayInUsdCentsTo: 0,
      }
      const searchCarParams2 = {
        country: request.country + '!',
        state: '',
        city: '',
        brand: '',
        model: '',
        yearOfProductionFrom: 0,
        yearOfProductionTo: 0,
        pricePerDayInUsdCentsFrom: 0,
        pricePerDayInUsdCentsTo: 0,
      }

      const availableCars1 =
        await rentalityTripService.searchAvailableCarsForUser(
          guest.address,
          0,
          0,
          searchCarParams1,
        )

      expect(availableCars1.length).to.equal(1)

      const availableCars2 =
        await rentalityTripService.searchAvailableCarsForUser(
          guest.address,
          0,
          0,
          searchCarParams2,
        )

      expect(availableCars2.length).to.equal(0)
    })

    it('Search with state should work', async function () {
      const { rentalityCarToken, rentalityTripService, guest } =
        await loadFixture(deployFixtureWith1Car)

      const request = getMockCarRequest(0)
      const searchCarParams1 = {
        country: '',
        state: request.state,
        city: '',
        brand: '',
        model: '',
        yearOfProductionFrom: 0,
        yearOfProductionTo: 0,
        pricePerDayInUsdCentsFrom: 0,
        pricePerDayInUsdCentsTo: 0,
      }
      const searchCarParams2 = {
        country: '',
        state: request.state + '!',
        city: '',
        brand: '',
        model: '',
        yearOfProductionFrom: 0,
        yearOfProductionTo: 0,
        pricePerDayInUsdCentsFrom: 0,
        pricePerDayInUsdCentsTo: 0,
      }

      const availableCars1 =
        await rentalityTripService.searchAvailableCarsForUser(
          guest.address,
          0,
          0,
          searchCarParams1,
        )

      expect(availableCars1.length).to.equal(1)

      const availableCars2 =
        await rentalityTripService.searchAvailableCarsForUser(
          guest.address,
          0,
          0,
          searchCarParams2,
        )

      expect(availableCars2.length).to.equal(0)
    })

    it('Search with city should work', async function () {
      const { rentalityCarToken, rentalityTripService, guest } =
        await loadFixture(deployFixtureWith1Car)

      const request = getMockCarRequest(0)
      const searchCarParams1 = {
        country: '',
        state: '',
        city: request.city,
        brand: '',
        model: '',
        yearOfProductionFrom: 0,
        yearOfProductionTo: 0,
        pricePerDayInUsdCentsFrom: 0,
        pricePerDayInUsdCentsTo: 0,
      }
      const searchCarParams2 = {
        country: '',
        state: '',
        city: request.city + '!',
        brand: '',
        model: '',
        yearOfProductionFrom: 0,
        yearOfProductionTo: 0,
        pricePerDayInUsdCentsFrom: 0,
        pricePerDayInUsdCentsTo: 0,
      }

      const availableCars1 =
        await rentalityTripService.searchAvailableCarsForUser(
          guest.address,
          0,
          0,
          searchCarParams1,
        )

      expect(availableCars1.length).to.equal(1)

      const availableCars2 =
        await rentalityTripService.searchAvailableCarsForUser(
          guest.address,
          0,
          0,
          searchCarParams2,
        )

      expect(availableCars2.length).to.equal(0)
    })

    it('Search with pricePerDayInUsdCentsFrom should work', async function () {
      const { rentalityCarToken, rentalityTripService, guest } =
        await loadFixture(deployFixtureWith1Car)

      const request = getMockCarRequest(0)
      const searchCarParams1 = {
        country: '',
        state: '',
        city: '',
        brand: '',
        model: '',
        yearOfProductionFrom: 0,
        yearOfProductionTo: 0,
        pricePerDayInUsdCentsFrom: request.pricePerDayInUsdCents,
        pricePerDayInUsdCentsTo: 0,
      }
      const searchCarParams2 = {
        country: '',
        state: '',
        city: '',
        brand: '',
        model: '',
        yearOfProductionFrom: 0,
        yearOfProductionTo: 0,
        pricePerDayInUsdCentsFrom: request.pricePerDayInUsdCents + 1,
        pricePerDayInUsdCentsTo: 0,
      }
      const searchCarParams3 = {
        country: '',
        state: '',
        city: '',
        brand: '',
        model: '',
        yearOfProductionFrom: 0,
        yearOfProductionTo: 0,
        pricePerDayInUsdCentsFrom: request.pricePerDayInUsdCents - 1,
        pricePerDayInUsdCentsTo: 0,
      }

      const availableCars1 =
        await rentalityTripService.searchAvailableCarsForUser(
          guest.address,
          0,
          0,
          searchCarParams1,
        )

      expect(availableCars1.length).to.equal(1)

      const availableCars2 =
        await rentalityTripService.searchAvailableCarsForUser(
          guest.address,
          0,
          0,
          searchCarParams2,
        )

      expect(availableCars2.length).to.equal(0)

      const availableCars3 =
        await rentalityTripService.searchAvailableCarsForUser(
          guest.address,
          0,
          0,
          searchCarParams3,
        )

      expect(availableCars3.length).to.equal(1)
    })

    it('Search with pricePerDayInUsdCentsTo should work', async function () {
      const { rentalityCarToken, rentalityTripService, guest } =
        await loadFixture(deployFixtureWith1Car)

      const request = getMockCarRequest(0)
      const searchCarParams1 = {
        country: '',
        state: '',
        city: '',
        brand: '',
        model: '',
        yearOfProductionFrom: 0,
        yearOfProductionTo: 0,
        pricePerDayInUsdCentsFrom: 0,
        pricePerDayInUsdCentsTo: request.pricePerDayInUsdCents,
      }
      const searchCarParams2 = {
        country: '',
        state: '',
        city: '',
        brand: '',
        model: '',
        yearOfProductionFrom: 0,
        yearOfProductionTo: 0,
        pricePerDayInUsdCentsFrom: 0,
        pricePerDayInUsdCentsTo: request.pricePerDayInUsdCents + 1,
      }
      const searchCarParams3 = {
        country: '',
        state: '',
        city: '',
        brand: '',
        model: '',
        yearOfProductionFrom: 0,
        yearOfProductionTo: 0,
        pricePerDayInUsdCentsFrom: 0,
        pricePerDayInUsdCentsTo: request.pricePerDayInUsdCents - 1,
      }

      const availableCars1 =
        await rentalityTripService.searchAvailableCarsForUser(
          guest.address,
          0,
          0,
          searchCarParams1,
        )

      expect(availableCars1.length).to.equal(1)

      const availableCars2 =
        await rentalityTripService.searchAvailableCarsForUser(
          guest.address,
          0,
          0,
          searchCarParams2,
        )

      expect(availableCars2.length).to.equal(1)

      const availableCars3 =
        await rentalityTripService.searchAvailableCarsForUser(
          guest.address,
          0,
          0,
          searchCarParams3,
        )

      expect(availableCars3.length).to.equal(0)
    })
  })
})
