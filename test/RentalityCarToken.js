const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { expect } = require('chai')
const { ethers, upgrades } = require('hardhat')
const { getMockCarRequest } = require('./utils')

describe('RentalityCarToken', function () {
  async function deployDefaultFixture() {
    const [owner, admin, manager, host, guest, anonymous] = await ethers.getSigners()

    const RentalityUtils = await ethers.getContractFactory('RentalityUtils')
    const utils = await RentalityUtils.deploy()

    const RentalityGeoService = await ethers.getContractFactory('RentalityGeoMock')

    const rentalityGeoService = await RentalityGeoService.deploy()
    await rentalityGeoService.waitForDeployment()

    const RentalityUserService = await ethers.getContractFactory('RentalityUserService')
    const RentalityCarToken = await ethers.getContractFactory('RentalityCarToken', {
      libraries: {
        RentalityUtils: await utils.getAddress(),
      },
    })

    const RentalityCurrencyConverter = await ethers.getContractFactory('RentalityCurrencyConverter')
    const RentalityPaymentService = await ethers.getContractFactory('RentalityPaymentService')
    const RentalityMockPriceFeed = await ethers.getContractFactory('RentalityMockPriceFeed')

    let rentalityMockPriceFeed = await RentalityMockPriceFeed.deploy(8, 200000000000)
    const rentalityUserService = await upgrades.deployProxy(RentalityUserService)

    await rentalityUserService.waitForDeployment()

    const rentalityPaymentService = await upgrades.deployProxy(RentalityPaymentService, [
      await rentalityUserService.getAddress(),
    ])

    const rentalityCurrencyConverter = await upgrades.deployProxy(RentalityCurrencyConverter, [
      await rentalityMockPriceFeed.getAddress(),
      await rentalityUserService.getAddress(),
    ])

    await rentalityCurrencyConverter.waitForDeployment()
    await rentalityPaymentService.waitForDeployment()
    await rentalityMockPriceFeed.waitForDeployment()

    await rentalityUserService.connect(owner).grantAdminRole(admin.address)
    await rentalityUserService.connect(owner).grantManagerRole(manager.address)
    await rentalityUserService.connect(owner).grantHostRole(host.address)
    await rentalityUserService.connect(owner).grantGuestRole(guest.address)

    const patrolEngine = await ethers.getContractFactory('RentalityPatrolEngine')
    const pEngine = await patrolEngine.deploy(await rentalityUserService.getAddress())

    const electricEngine = await ethers.getContractFactory('RentalityElectricEngine')
    const elEngine = await electricEngine.deploy(await rentalityUserService.getAddress())

    const hybridEngine = await ethers.getContractFactory('RentalityHybridEngine')
    const hEngine = await hybridEngine.deploy(await rentalityUserService.getAddress())

    const EngineService = await ethers.getContractFactory('RentalityEnginesService')

    const engineService = await upgrades.deployProxy(EngineService, [
      await rentalityUserService.getAddress(),
      [await pEngine.getAddress(), await elEngine.getAddress(), await hEngine.getAddress()],
    ])
    await engineService.waitForDeployment()

    const rentalityCarToken = await upgrades.deployProxy(
      RentalityCarToken,
      [await rentalityGeoService.getAddress(), await engineService.getAddress()],
      { kind: 'uups' }
    )

    await rentalityCarToken.waitForDeployment()

    const RentalityTripService = await ethers.getContractFactory('RentalityTripService', {
      libraries: { RentalityUtils: await utils.getAddress() },
    })

    const rentalityTripService = await upgrades.deployProxy(RentalityTripService, [
      await rentalityCurrencyConverter.getAddress(),
      await rentalityCarToken.getAddress(),
      await rentalityPaymentService.getAddress(),
      await rentalityUserService.getAddress(),
      await engineService.getAddress(),
    ])

    await rentalityTripService.waitForDeployment()

    await rentalityUserService.connect(owner).grantManagerRole(await rentalityTripService.getAddress())
    await rentalityUserService.connect(owner).grantManagerRole(await rentalityCarToken.getAddress())
    await rentalityUserService.connect(owner).grantManagerRole(await engineService.getAddress())

    return {
      rentalityCarToken,
      rentalityUserService,
      rentalityTripService,
      rentalityGeoService,
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
      rentalityGeoService,
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
      rentalityGeoService,
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

    const RentalityUserService1 = await ethers.getContractFactory('RentalityUserService')
    const RentalityUserService2 = await ethers.getContractFactory('RentalityUserService')
    const RentalityCarToken = await ethers.getContractFactory('RentalityCarToken')

    const rentalityUserService1 = await upgrades.deployProxy(RentalityUserService1)
    await rentalityUserService1.waitForDeployment()

    const rentalityUserService2 = await upgrades.deployProxy(RentalityUserService2)
    await rentalityUserService2.waitForDeployment()

    await rentalityUserService1.connect(owner).grantAdminRole(admin1.address)
    await rentalityUserService2.connect(owner).grantAdminRole(admin2.address)

    const RentalityGeoService = await ethers.getContractFactory('RentalityGeoMock')

    const rentalityGeoService = await RentalityGeoService.deploy()
    await rentalityGeoService.waitForDeployment()

    const patrolEngine = await ethers.getContractFactory('RentalityPatrolEngine')
    const pEngine = await patrolEngine.deploy(await rentalityUserService.getAddress()())

    const electricEngine = await ethers.getContractFactory('RentalityElectricEngine')
    const elEngine = await electricEngine.deploy(await rentalityUserService.getAddress()())

    const hybridEngine = await ethers.getContractFactory('RentalityHybridEngine')
    const hEngine = await hybridEngine.deploy(await rentalityUserService.getAddress()())

    const EngineService = await ethers.getContractFactory('RentalityEnginesService')

    const engineService = await EngineService.deploy(await rentalityUserService.getAddress(), [
      await pEngine.getAddress(),
      await elEngine.getAddress(),
      await hEngine.getAddress(),
    ])
    await engineService.waitForDeployment()

    const rentalityCarToken = await upgrades.deployProxy(RentalityCarToken, [
      await rentalityGeoService.getAddress(),
      await engineService.getAddress(),
    ])
    await rentalityCarToken.waitForDeployment()

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
      const { rentalityCarToken, owner } = await loadFixture(deployDefaultFixture)

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
  it('Update car without location should work fine', async function () {
    const { rentalityCarToken } = await loadFixture(deployFixtureWith1Car)

    let request = getMockCarRequest(1)
    await expect(rentalityCarToken.addCar(request)).not.be.reverted

    let update_params = {
      carId: 2,
      pricePerDayInUsdCents: 2,
      securityDepositPerTripInUsdCents: 2,
      engineParams: [2],
      milesIncludedPerDay: 2,
      timeBufferBetweenTripsInSec: 0,
      currentlyListed: false,
    }

    await expect(rentalityCarToken.updateCarInfo(update_params, '', '')).not.be.reverted

    let car_info = await rentalityCarToken.getCarInfoById(2)

    expect(car_info.pricePerDayInUsdCents).to.be.equal(update_params.pricePerDayInUsdCents)
    expect(car_info.securityDepositPerTripInUsdCents).to.be.equal(update_params.securityDepositPerTripInUsdCents)
    expect(car_info.engineParams[1]).to.be.equal(update_params.engineParams[0])
    expect(car_info.milesIncludedPerDay).to.be.equal(update_params.milesIncludedPerDay)
  })
  it('Update car with location, but without api should revert', async function () {
    const { rentalityCarToken } = await loadFixture(deployFixtureWith1Car)

    let request = getMockCarRequest(1)
    await expect(rentalityCarToken.addCar(request)).not.be.reverted

    let update_params = {
      carId: 2,
      pricePerDayInUsdCents: 2,
      securityDepositPerTripInUsdCents: 2,
      engineParams: [2],
      milesIncludedPerDay: 2,
      timeBufferBetweenTripsInSec: 0,
      currentlyListed: false,
    }

    await expect(rentalityCarToken.updateCarInfo(update_params, 'location', '')).to.be.reverted
  })
  it('Update with location should pass locationVarification param to false', async function () {
    const { rentalityCarToken, rentalityGeoService } = await loadFixture(deployFixtureWith1Car)

    let request = getMockCarRequest(1)
    await expect(rentalityCarToken.addCar(request)).not.be.reverted

    let update_params = {
      carId: 2,
      pricePerDayInUsdCents: 2,
      securityDepositPerTripInUsdCents: 2,
      engineParams: [2],
      timeBufferBetweenTripsInSec: 0,
      milesIncludedPerDay: 2,
      currentlyListed: false,
    }

    await rentalityGeoService.setCarCoordinateValidity(2, true) // mock

    await expect(rentalityCarToken.verifyGeo(2)).to.not.reverted

    await expect(rentalityCarToken.updateCarInfo(update_params, 'location', 'geoApi')).to.not.reverted

    let car_info = await rentalityCarToken.getCarInfoById(2)

    expect(car_info.geoVerified).to.be.equal(false)
  })

  describe('Host functions', function () {
    it('Adding car should emit CarAddedSuccess event', async function () {
      const { rentalityCarToken, host } = await loadFixture(deployDefaultFixture)

      const request = getMockCarRequest(0)

      await expect(rentalityCarToken.connect(host).addCar(request))
        .to.emit(rentalityCarToken, 'CarAddedSuccess')
        .withArgs(1, request.carVinNumber, host.address, request.pricePerDayInUsdCents, true)
    })

    it('Adding car with the same VIN number should be reverted', async function () {
      const { rentalityCarToken, host } = await loadFixture(deployDefaultFixture)

      const request1 = getMockCarRequest(0)
      const request2 = {
        ...getMockCarRequest(1),
        carVinNumber: request1.carVinNumber,
      }

      await expect(rentalityCarToken.connect(host).addCar(request1)).not.be.reverted
      await expect(rentalityCarToken.connect(host).addCar(request2)).to.be.reverted
    })

    it('Adding car with the different VIN number should not be reverted', async function () {
      const { rentalityCarToken, host } = await loadFixture(deployDefaultFixture)

      const request1 = getMockCarRequest(0)
      const request2 = getMockCarRequest(1)

      await expect(rentalityCarToken.connect(host).addCar(request1)).not.be.reverted
      await expect(rentalityCarToken.connect(host).addCar(request2)).not.be.reverted
    })

    it('Only owner of the car can burn token', async function () {
      const { rentalityCarToken, owner, admin, host, anonymous } = await loadFixture(deployFixtureWith1Car)

      await expect(rentalityCarToken.connect(anonymous).burnCar(1)).to.be.reverted
      await expect(rentalityCarToken.connect(admin).burnCar(1)).to.be.reverted
      await expect(rentalityCarToken.connect(owner).burnCar(1)).to.be.reverted

      expect(await rentalityCarToken.balanceOf(host.address)).to.equal(1)
      await expect(rentalityCarToken.connect(host).burnCar(1)).not.be.reverted
      expect(await rentalityCarToken.balanceOf(host.address)).to.equal(0)
    })

    it('getCarInfoById should return valid info', async function () {
      const { rentalityCarToken, host } = await loadFixture(deployFixtureWith1Car)

      const TOKEN_ID = 1
      const request = getMockCarRequest(0)

      const carInfo = await rentalityCarToken.connect(host).getCarInfoById(TOKEN_ID)

      expect(carInfo.carVinNumber).to.equal(request.carVinNumber)
      expect(carInfo.createdBy).to.equal(host.address)
      expect(carInfo.pricePerDayInUsdCents).to.equal(request.pricePerDayInUsdCents)
      expect(carInfo.securityDepositPerTripInUsdCents).to.equal(request.securityDepositPerTripInUsdCents)
      expect(carInfo.tankVolumeInGal).to.equal(request.tankVolumeInGal)
      expect(carInfo.fuelPricePerGalInUsdCents).to.equal(request.fuelPricePerGalInUsdCents)
      expect(carInfo.milesIncludedPerDay).to.equal(request.milesIncludedPerDay)
      expect(carInfo.country).to.equal(request.country)
      expect(carInfo.state).to.equal(request.state)
      expect(carInfo.city).to.equal(request.city)
      expect(carInfo.locationLatitudeInPPM).to.equal(request.locationLatitudeInPPM)
      expect(carInfo.locationLongitudeInPPM).to.equal(request.locationLongitudeInPPM)
      expect(carInfo.currentlyListed).to.equal(true)
    })

    it('getCarsOwnedByUser without cars should return empty array', async function () {
      const { rentalityCarToken, host } = await loadFixture(deployDefaultFixture)
      const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)

      expect(myCars.length).to.equal(0)
    })

    it('getCarsOwnedByUser after burn car should return empty array', async function () {
      const { rentalityCarToken, host } = await loadFixture(deployFixtureWith1Car)

      await rentalityCarToken.connect(host).burnCar(1)
      const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)

      expect(myCars.length).to.equal(0)
    })

    it('getCarsOwnedByUser with 1 car should return valid info', async function () {
      const { rentalityCarToken, host } = await loadFixture(deployFixtureWith1Car)

      const request = getMockCarRequest(0)

      const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)

      expect(myCars.length).to.equal(1)

      expect(myCars[0].carVinNumber).to.equal(request.carVinNumber)
      expect(myCars[0].createdBy).to.equal(host.address)
      expect(myCars[0].pricePerDayInUsdCents).to.equal(request.pricePerDayInUsdCents)
      expect(myCars[0].securityDepositPerTripInUsdCents).to.equal(request.securityDepositPerTripInUsdCents)
      expect(myCars[0].tankVolumeInGal).to.equal(request.tankVolumeInGal)
      expect(myCars[0].fuelPricePerGalInUsdCents).to.equal(request.fuelPricePerGalInUsdCents)
      expect(myCars[0].milesIncludedPerDay).to.equal(request.milesIncludedPerDay)
      expect(myCars[0].country).to.equal(request.country)
      expect(myCars[0].state).to.equal(request.state)
      expect(myCars[0].city).to.equal(request.city)
      expect(myCars[0].locationLatitudeInPPM).to.equal(request.locationLatitudeInPPM)
      expect(myCars[0].locationLongitudeInPPM).to.equal(request.locationLongitudeInPPM)
      expect(myCars[0].currentlyListed).to.equal(true)
    })

    it("getAllAvailableCars with 1 car shouldn't return data for car owner", async function () {
      const { rentalityCarToken, host } = await loadFixture(deployFixtureWith1Car)

      const availableCars = await rentalityCarToken.getAvailableCarsForUser(host.address)

      expect(availableCars.length).to.equal(0)
    })

    it('getAllAvailableCars with 1 car should return data for guest', async function () {
      const { rentalityCarToken, host, guest } = await loadFixture(deployFixtureWith1Car)

      const request = getMockCarRequest(0)

      const availableCars = await rentalityCarToken.getAvailableCarsForUser(guest.address)

      expect(availableCars.length).to.equal(1)
      expect(availableCars[0].carVinNumber).to.equal(request.carVinNumber)
      expect(availableCars[0].createdBy).to.equal(host.address)
      expect(availableCars[0].pricePerDayInUsdCents).to.equal(request.pricePerDayInUsdCents)
      expect(availableCars[0].securityDepositPerTripInUsdCents).to.equal(request.securityDepositPerTripInUsdCents)
      expect(availableCars[0].tankVolumeInGal).to.equal(request.tankVolumeInGal)
      expect(availableCars[0].fuelPricePerGalInUsdCents).to.equal(request.fuelPricePerGalInUsdCents)
      expect(availableCars[0].milesIncludedPerDay).to.equal(request.milesIncludedPerDay)
      expect(availableCars[0].country).to.equal(request.country)
      expect(availableCars[0].state).to.equal(request.state)
      expect(availableCars[0].city).to.equal(request.city)
      expect(availableCars[0].locationLatitudeInPPM).to.equal(request.locationLatitudeInPPM)
      expect(availableCars[0].locationLongitudeInPPM).to.equal(request.locationLongitudeInPPM)
      expect(availableCars[0].currentlyListed).to.equal(true)
    })
  })

  describe('Search functions', function () {
    it('Search with empty should return car', async function () {
      const { rentalityCarToken, rentalityTripService, guest } = await loadFixture(deployFixtureWith1Car)

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

      const availableCars = await rentalityTripService.searchAvailableCarsForUser(guest.address, 0, 0, searchCarParams)

      expect(availableCars.length).to.equal(1)
    })

    it('Search with brand should work', async function () {
      const { rentalityCarToken, rentalityTripService, guest } = await loadFixture(deployFixtureWith1Car)

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

      const availableCars1 = await rentalityTripService.searchAvailableCarsForUser(
        guest.address,
        0,
        0,
        searchCarParams1
      )

      expect(availableCars1.length).to.equal(1)

      const availableCars2 = await rentalityTripService.searchAvailableCarsForUser(
        guest.address,
        0,
        0,
        searchCarParams2
      )

      expect(availableCars2.length).to.equal(0)
    })

    it('Search with model should work', async function () {
      const { rentalityCarToken, rentalityTripService, guest } = await loadFixture(deployFixtureWith1Car)

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

      const availableCars1 = await rentalityTripService.searchAvailableCarsForUser(
        guest.address,
        0,
        0,
        searchCarParams1
      )

      expect(availableCars1.length).to.equal(1)

      const availableCars2 = await rentalityTripService.searchAvailableCarsForUser(
        guest.address,
        0,
        0,
        searchCarParams2
      )

      expect(availableCars2.length).to.equal(0)
    })

    it('Search with yearOfProduction should work', async function () {
      const { rentalityCarToken, rentalityTripService, guest } = await loadFixture(deployFixtureWith1Car)

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

      const availableCars1 = await rentalityTripService.searchAvailableCarsForUser(
        guest.address,
        0,
        0,
        searchCarParams1
      )

      expect(availableCars1.length).to.equal(1)

      const availableCars2 = await rentalityTripService.searchAvailableCarsForUser(
        guest.address,
        0,
        0,
        searchCarParams2
      )

      expect(availableCars2.length).to.equal(0)
    })

    it('Search with country should work', async function () {
      const { rentalityGeoService, rentalityTripService, guest } = await loadFixture(deployFixtureWith1Car)

      let carId = 0
      await rentalityGeoService.setCarCountry(++carId, 'usa') //mock

      const searchCarParams1 = {
        country: 'usa',
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
        country: '!',
        state: '',
        city: '',
        brand: '',
        model: '',
        yearOfProductionFrom: 0,
        yearOfProductionTo: 0,
        pricePerDayInUsdCentsFrom: 0,
        pricePerDayInUsdCentsTo: 0,
      }

      const availableCars1 = await rentalityTripService.searchAvailableCarsForUser(
        guest.address,
        0,
        0,
        searchCarParams1
      )

      expect(availableCars1.length).to.equal(1)

      const availableCars2 = await rentalityTripService.searchAvailableCarsForUser(
        guest.address,
        0,
        0,
        searchCarParams2
      )

      expect(availableCars2.length).to.equal(0)
    })

    it('Search with state should work', async function () {
      const { rentalityGeoService, rentalityTripService, guest } = await loadFixture(deployFixtureWith1Car)

      let carId = 0
      await rentalityGeoService.setCarState(++carId, 'kyiv') //mock

      const searchCarParams1 = {
        country: '',
        state: 'kyiv',
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
        state: '!',
        city: '',
        brand: '',
        model: '',
        yearOfProductionFrom: 0,
        yearOfProductionTo: 0,
        pricePerDayInUsdCentsFrom: 0,
        pricePerDayInUsdCentsTo: 0,
      }

      const availableCars1 = await rentalityTripService.searchAvailableCarsForUser(
        guest.address,
        0,
        0,
        searchCarParams1
      )

      expect(availableCars1.length).to.equal(1)

      const availableCars2 = await rentalityTripService.searchAvailableCarsForUser(
        guest.address,
        0,
        0,
        searchCarParams2
      )

      expect(availableCars2.length).to.equal(0)
    })

    it('Search with city should work', async function () {
      const { rentalityGeoService, rentalityTripService, guest } = await loadFixture(deployFixtureWith1Car)

      let carId = 0
      await rentalityGeoService.setCarCity(++carId, 'kyiv') //mock

      const searchCarParams1 = {
        country: '',
        state: '',
        city: 'kyiv',
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
        city: '!',
        brand: '',
        model: '',
        yearOfProductionFrom: 0,
        yearOfProductionTo: 0,
        pricePerDayInUsdCentsFrom: 0,
        pricePerDayInUsdCentsTo: 0,
      }

      const availableCars1 = await rentalityTripService.searchAvailableCarsForUser(
        guest.address,
        0,
        0,
        searchCarParams1
      )

      expect(availableCars1.length).to.equal(1)

      const availableCars2 = await rentalityTripService.searchAvailableCarsForUser(
        guest.address,
        0,
        0,
        searchCarParams2
      )

      expect(availableCars2.length).to.equal(0)
    })

    it('Search with pricePerDayInUsdCentsFrom should work', async function () {
      const { rentalityCarToken, rentalityTripService, guest } = await loadFixture(deployFixtureWith1Car)

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

      const availableCars1 = await rentalityTripService.searchAvailableCarsForUser(
        guest.address,
        0,
        0,
        searchCarParams1
      )

      expect(availableCars1.length).to.equal(1)

      const availableCars2 = await rentalityTripService.searchAvailableCarsForUser(
        guest.address,
        0,
        0,
        searchCarParams2
      )

      expect(availableCars2.length).to.equal(0)

      const availableCars3 = await rentalityTripService.searchAvailableCarsForUser(
        guest.address,
        0,
        0,
        searchCarParams3
      )

      expect(availableCars3.length).to.equal(1)
    })

    it('Search with pricePerDayInUsdCentsTo should work', async function () {
      const { rentalityCarToken, rentalityTripService, guest } = await loadFixture(deployFixtureWith1Car)

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

      const availableCars1 = await rentalityTripService.searchAvailableCarsForUser(
        guest.address,
        0,
        0,
        searchCarParams1
      )

      expect(availableCars1.length).to.equal(1)

      const availableCars2 = await rentalityTripService.searchAvailableCarsForUser(
        guest.address,
        0,
        0,
        searchCarParams2
      )

      expect(availableCars2.length).to.equal(1)

      const availableCars3 = await rentalityTripService.searchAvailableCarsForUser(
        guest.address,
        0,
        0,
        searchCarParams3
      )

      expect(availableCars3.length).to.equal(0)
    })
  })
})
