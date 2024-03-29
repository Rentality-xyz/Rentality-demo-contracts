const {
  time,
  loadFixture,
} = require('@nomicfoundation/hardhat-network-helpers')
const { anyValue } = require('@nomicfoundation/hardhat-chai-matchers/withArgs')
const { expect } = require('chai')
const { ethers } = require('hardhat')

describe('Rentality', function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployDefaultFixture() {
    const [owner, admin, manager, host, guest, anonymous] =
      await ethers.getSigners()

    const RentalityUtils = await ethers.getContractFactory('RentalityUtils')
    const utils = await RentalityUtils.deploy()
    const RentalityMockPriceFeed = await ethers.getContractFactory(
      'RentalityMockPriceFeed',
    )
    const RentalityUserService = await ethers.getContractFactory(
      'RentalityUserService',
    )
    const RentalityTripService = await ethers.getContractFactory(
      'RentalityTripService',
      { libraries: { RentalityUtils: utils.address } },
    )
    const RentalityCurrencyConverter = await ethers.getContractFactory(
      'RentalityCurrencyConverter',
    )
    const RentalityPaymentService = await ethers.getContractFactory(
      'RentalityPaymentService',
    )
    const RentalityCarToken =
      await ethers.getContractFactory('RentalityCarToken')

    const RentalityPlatform =
      await ethers.getContractFactory('RentalityPlatform',
          {
              libraries:
                  {
                      RentalityUtils: utils.address
                  }
          })

    let rentalityMockPriceFeed = await RentalityMockPriceFeed.deploy(
      8,
      200000000000,
    )
    await rentalityMockPriceFeed.deployed()

    const rentalityUserService = await RentalityUserService.deploy()
    await rentalityUserService.deployed()

    await rentalityUserService.connect(owner).grantAdminRole(admin.address)
    await rentalityUserService.connect(owner).grantManagerRole(manager.address)
    await rentalityUserService.connect(owner).grantHostRole(host.address)
    await rentalityUserService.connect(owner).grantGuestRole(guest.address)

    const rentalityCurrencyConverter = await RentalityCurrencyConverter.deploy(
      rentalityMockPriceFeed.address,
    )
    await rentalityCurrencyConverter.deployed()

    const rentalityCarToken = await RentalityCarToken.deploy()
    await rentalityCarToken.deployed()
    const rentalityPaymentService = await RentalityPaymentService.deploy()
    await rentalityPaymentService.deployed()

    const rentalityTripService = await RentalityTripService.deploy(
      rentalityCurrencyConverter.address,
      rentalityCarToken.address,
      rentalityPaymentService.address,
      rentalityUserService.address,
    )
    await rentalityTripService.deployed()

    const rentalityPlatform = await RentalityPlatform.deploy(
      rentalityCarToken.address,
      rentalityCurrencyConverter.address,
      rentalityTripService.address,
      rentalityUserService.address,
      rentalityPaymentService.address,
    )
    await rentalityPlatform.deployed()

    await rentalityUserService
      .connect(owner)
      .grantHostRole(rentalityPlatform.address)

    await rentalityUserService
      .connect(owner)
      .grantManagerRole(rentalityTripService.address)

    return {
      rentalityMockPriceFeed,
      rentalityUserService,
      rentalityTripService,
      rentalityCurrencyConverter,
      rentalityCarToken,
      rentalityPaymentService,
      rentalityPlatform,
      owner,
      admin,
      manager,
      host,
      guest,
      anonymous,
    }
  }

  function getMockCarRequest(seed) {
    const seedStr = seed?.toString() ?? ''
    const seedInt = Number(seed) ?? 0

    const TOKEN_URI = 'TOKEN_URI' + seedStr
    const VIN_NUMBER = 'VIN_NUMBER' + seedStr
    const BRAND = 'BRAND' + seedStr
    const MODEL = 'MODEL' + seedStr
    const YEAR = '200' + seedStr
    const PRICE_PER_DAY = seedInt * 100 + 2
    const DEPOSIT = seedInt * 100 + 3
    const TANK_VOLUME = seedInt * 100 + 4
    const FUEL_PRICE = seedInt * 100 + 5
    const DISTANCE_INCLUDED = seedInt * 100 + 6
    const COUNTRY = 'COUNTRY' + seedStr
    const STATE = 'STATE' + seedStr
    const CITY = 'CITY' + seedStr
    const LOCATION_LATITUDE = seedInt * 100 + 7
    const LOCATION_LONGITUDE = seedInt * 100 + 8

    return {
      tokenUri: TOKEN_URI,
      carVinNumber: VIN_NUMBER,
      brand: BRAND,
      model: MODEL,
      yearOfProduction: YEAR,
      pricePerDayInUsdCents: PRICE_PER_DAY,
      securityDepositPerTripInUsdCents: DEPOSIT,
      tankVolumeInGal: TANK_VOLUME,
      fuelPricePerGalInUsdCents: FUEL_PRICE,
      milesIncludedPerDay: DISTANCE_INCLUDED,
      country: COUNTRY,
      state: STATE,
      city: CITY,
      locationLatitudeInPPM: LOCATION_LATITUDE,
      locationLongitudeInPPM: LOCATION_LONGITUDE,
    }
  }

  function getMockSearchCarParams(seed) {
    const seedStr = seed?.toString() ?? ''
    const seedInt = Number(seed) ?? 0

    const BRAND = 'BRAND' + seedStr
    const MODEL = 'MODEL' + seedStr
    const COUNTRY = 'COUNTRY' + seedStr
    const STATE = 'STATE' + seedStr
    const CITY = 'CITY' + seedStr
    const YEAR_FROM = 2000 + seedInt
    const YEAR_TO = 2000 + seedInt
    const PRICE_PER_DAY_FROM = seedInt * 100 + 2
    const PRICE_PER_DAY_TO = seedInt * 100 + 2

    return {
      country: COUNTRY,
      state: STATE,
      city: CITY,
      brand: BRAND,
      model: MODEL,
      yearOfProductionFrom: YEAR_FROM,
      yearOfProductionTo: YEAR_TO,
      pricePerDayInUsdCentsFrom: PRICE_PER_DAY_FROM,
      pricePerDayInUsdCentsTo: PRICE_PER_DAY_TO,
    }
  }

  function getEmptySearchCarParams(seed) {
    return {
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
  }

  describe('Rentality', function () {
    it('Host can add car to rentality', async function () {
      const { rentalityCarToken, host } =
        await loadFixture(deployDefaultFixture)

      await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0)))
        .not.to.be.reverted
      const myCars = await rentalityCarToken
        .connect(host)
        .getCarsOwnedByUser(host.address)
      expect(myCars.length).to.equal(1)
    })
    it('Host dont see own cars as available', async function () {
      const { rentalityCarToken, host } =
        await loadFixture(deployDefaultFixture)

      await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0)))
        .not.to.be.reverted
      const myCars = await rentalityCarToken
        .connect(host)
        .getCarsOwnedByUser(host.address)
      expect(myCars.length).to.equal(1)
      const availableCars = await rentalityCarToken
        .connect(host)
        .getAvailableCarsForUser(host.address)
      expect(availableCars.length).to.equal(0)
    })
    it('Guest see cars as available', async function () {
      const { rentalityCarToken, host, guest } =
        await loadFixture(deployDefaultFixture)

      await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0)))
        .not.to.be.reverted
      const myCars = await rentalityCarToken
        .connect(host)
        .getCarsOwnedByUser(host.address)
      expect(myCars.length).to.equal(1)
      const availableCars = await rentalityCarToken
        .connect(guest)
        .getAvailableCarsForUser(guest.address)
      expect(availableCars.length).to.equal(1)
    })
    it('createTripRequest', async function () {
      const {
        rentalityCarToken,
        rentalityPlatform,
        rentalityCurrencyConverter,
        host,
        guest,
      } = await loadFixture(deployDefaultFixture)

      await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0)))
        .not.to.be.reverted
      const myCars = await rentalityCarToken
        .connect(host)
        .getCarsOwnedByUser(host.address)
      expect(myCars.length).to.equal(1)

      const availableCars = await rentalityCarToken
        .connect(guest)
        .getAvailableCarsForUser(guest.address)
      expect(availableCars.length).to.equal(1)

      const rentPriceInUsdCents = 1000
      const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
        await rentalityCurrencyConverter.getEthFromUsdLatest(
          rentPriceInUsdCents,
        )

      await expect(
        rentalityPlatform.connect(guest).createTripRequest(
          {
            carId: 1,
            host: host.address,
            startDateTime: 1,
            endDateTime: 1,
            startLocation: '',
            endLocation: '',
            totalDayPriceInUsdCents: rentPriceInUsdCents,
            taxPriceInUsdCents: 0,
            depositInUsdCents: 0,
            fuelPricePerGalInUsdCents: 400,
            ethToCurrencyRate: ethToCurrencyRate,
            ethToCurrencyDecimals: ethToCurrencyDecimals,
          },
          { value: rentPriceInEth },
        ),
      ).not.to.be.reverted
    })

    it('host can reject created trip', async function () {
      const {
        rentalityPlatform,
        rentalityCarToken,
        rentalityCurrencyConverter,
        host,
        guest,
      } = await loadFixture(deployDefaultFixture)

      await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0)))
        .not.to.be.reverted
      const myCars = await rentalityCarToken
        .connect(host)
        .getCarsOwnedByUser(host.address)
      expect(myCars.length).to.equal(1)

      const availableCars = await rentalityCarToken
        .connect(guest)
        .getAvailableCarsForUser(guest.address)
      expect(availableCars.length).to.equal(1)

      const rentPriceInUsdCents = 1000
      const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
        await rentalityCurrencyConverter.getEthFromUsdLatest(
          rentPriceInUsdCents,
        )

      await expect(
        rentalityPlatform.connect(guest).createTripRequest(
          {
            carId: 1,
            host: host.address,
            startDateTime: 1,
            endDateTime: 1,
            startLocation: '',
            endLocation: '',
            totalDayPriceInUsdCents: rentPriceInUsdCents,
            taxPriceInUsdCents: 0,
            depositInUsdCents: 0,
            fuelPricePerGalInUsdCents: 400,
            ethToCurrencyRate: ethToCurrencyRate,
            ethToCurrencyDecimals: ethToCurrencyDecimals,
          },
          { value: rentPriceInEth },
        ),
      ).to.changeEtherBalances(
        [guest, rentalityPlatform],
        [-rentPriceInEth, rentPriceInEth],
      )

      await expect(
        rentalityPlatform.connect(host).rejectTripRequest(1),
      ).to.changeEtherBalances(
        [guest, rentalityPlatform],
        [rentPriceInEth, -rentPriceInEth],
      )
    })

    it('guest can reject created trip', async function () {
      const {
        rentalityPlatform,
        rentalityCarToken,
        rentalityCurrencyConverter,
        host,
        guest,
      } = await loadFixture(deployDefaultFixture)

      await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0)))
        .not.to.be.reverted
      const myCars = await rentalityCarToken
        .connect(host)
        .getCarsOwnedByUser(host.address)
      expect(myCars.length).to.equal(1)

      const availableCars = await rentalityCarToken
        .connect(guest)
        .getAvailableCarsForUser(guest.address)
      expect(availableCars.length).to.equal(1)

      const rentPriceInUsdCents = 1000
      const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
        await rentalityCurrencyConverter.getEthFromUsdLatest(
          rentPriceInUsdCents,
        )

      await expect(
        rentalityPlatform.connect(guest).createTripRequest(
          {
            carId: 1,
            host: host.address,
            startDateTime: 1,
            endDateTime: 1,
            startLocation: '',
            endLocation: '',
            totalDayPriceInUsdCents: rentPriceInUsdCents,
            taxPriceInUsdCents: 0,
            depositInUsdCents: 0,
            fuelPricePerGalInUsdCents: 400,
            ethToCurrencyRate: ethToCurrencyRate,
            ethToCurrencyDecimals: ethToCurrencyDecimals,
          },
          { value: rentPriceInEth },
        ),
      ).to.changeEtherBalances(
        [guest, rentalityPlatform],
        [-rentPriceInEth, rentPriceInEth],
      )

      await expect(
        rentalityPlatform.connect(guest).rejectTripRequest(1),
      ).to.changeEtherBalances(
        [guest, rentalityPlatform],
        [rentPriceInEth, -rentPriceInEth],
      )
    })

    it('Happy case', async function () {
      const {
        rentalityPlatform,
        rentalityCarToken,
        rentalityCurrencyConverter,
        rentalityPaymentService,
        rentalityTripService,
        host,
        guest,
      } = await loadFixture(deployDefaultFixture)

      await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0)))
        .not.to.be.reverted
      const myCars = await rentalityCarToken
        .connect(host)
        .getCarsOwnedByUser(host.address)
      expect(myCars.length).to.equal(1)
      const availableCars = await rentalityCarToken
        .connect(guest)
        .getAvailableCarsForUser(guest.address)
      expect(availableCars.length).to.equal(1)

      const rentPriceInUsdCents = 1000
      const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
        await rentalityCurrencyConverter.getEthFromUsdLatest(
          rentPriceInUsdCents,
        )

      await expect(
        rentalityPlatform.connect(guest).createTripRequest(
          {
            carId: 1,
            host: host.address,
            startDateTime: 1,
            endDateTime: 1,
            startLocation: '',
            endLocation: '',
            totalDayPriceInUsdCents: rentPriceInUsdCents,
            taxPriceInUsdCents: 0,
            depositInUsdCents: 0,
            fuelPricePerGalInUsdCents: 400,
            ethToCurrencyRate: ethToCurrencyRate,
            ethToCurrencyDecimals: ethToCurrencyDecimals,
          },
          { value: rentPriceInEth },
        ),
      ).not.to.be.reverted

      await expect(rentalityPlatform.connect(host).approveTripRequest(1)).not.to
        .be.reverted
      await expect(rentalityTripService.connect(host).checkInByHost(1, 0, 0))
        .not.to.be.reverted
      await expect(rentalityTripService.connect(guest).checkInByGuest(1, 0, 0))
        .not.to.be.reverted
      await expect(rentalityTripService.connect(guest).checkOutByGuest(1, 0, 0))
        .not.to.be.reverted
      await expect(rentalityTripService.connect(host).checkOutByHost(1, 0, 0))
        .not.to.be.reverted
      const returnToHost =
        rentPriceInEth -
        (rentPriceInEth *
          (await rentalityPaymentService.getPlatformFeeInPPM())) /
          1_000_000

      await expect(
        rentalityPlatform.connect(host).finishTrip(1),
      ).to.changeEtherBalances(
        [host, rentalityPlatform],
        [returnToHost, -returnToHost],
      )
    })

    it('if trip accepted intersect trips should be rejected', async function () {
      const {
        rentalityPlatform,
        rentalityCarToken,
        rentalityTripService,
        rentalityCurrencyConverter,
        host,
        guest,
      } = await loadFixture(deployDefaultFixture)

      await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0)))
        .not.to.be.reverted
      const myCars = await rentalityCarToken
        .connect(host)
        .getCarsOwnedByUser(host.address)
      expect(myCars.length).to.equal(1)
      const availableCars = await rentalityCarToken
        .connect(guest)
        .getAvailableCarsForUser(guest.address)
      expect(availableCars.length).to.equal(1)

      const rentPriceInUsdCents = 1000
      const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
        await rentalityCurrencyConverter.getEthFromUsdLatest(
          rentPriceInUsdCents,
        )

      await expect(
        rentalityPlatform.connect(guest).createTripRequest(
          {
            carId: 1,
            host: host.address,
            startDateTime: 123,
            endDateTime: 321,
            startLocation: '',
            endLocation: '',
            totalDayPriceInUsdCents: rentPriceInUsdCents,
            taxPriceInUsdCents: 0,
            depositInUsdCents: 0,
            fuelPricePerGalInUsdCents: 400,
            ethToCurrencyRate: ethToCurrencyRate,
            ethToCurrencyDecimals: ethToCurrencyDecimals,
          },
          { value: rentPriceInEth },
        ),
      ).not.to.be.reverted

      await expect(
        rentalityPlatform.connect(guest).createTripRequest(
          {
            carId: 1,
            host: host.address,
            startDateTime: 234,
            endDateTime: 456,
            startLocation: '',
            endLocation: '',
            totalDayPriceInUsdCents: rentPriceInUsdCents,
            taxPriceInUsdCents: 0,
            depositInUsdCents: 0,
            fuelPricePerGalInUsdCents: 400,
            ethToCurrencyRate: ethToCurrencyRate,
            ethToCurrencyDecimals: ethToCurrencyDecimals,
          },
          { value: rentPriceInEth },
        ),
      ).not.to.be.reverted

      expect(
        (await rentalityTripService.connect(host).getTrip(1)).status,
      ).to.equal(0)
      expect(
        (await rentalityTripService.connect(host).getTrip(2)).status,
      ).to.equal(0)

      await expect(
        rentalityPlatform.connect(host).approveTripRequest(1),
      ).to.changeEtherBalances(
        [guest, rentalityPlatform],
        [rentPriceInEth, -rentPriceInEth],
      )

      const trip1 = await rentalityTripService.connect(host).getTrip(1)
      const trip2 = await rentalityTripService.connect(host).getTrip(2)
      expect(trip1.status).to.equal(1)
      expect(trip2.status).to.equal(7)
    })

    it("if trip accepted not intersect trips shouldn't be rejected", async function () {
      const {
        rentalityPlatform,
        rentalityCarToken,
        rentalityTripService,
        rentalityCurrencyConverter,
        host,
        guest,
      } = await loadFixture(deployDefaultFixture)

      await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0)))
        .not.to.be.reverted
      const myCars = await rentalityCarToken
        .connect(host)
        .getCarsOwnedByUser(host.address)
      expect(myCars.length).to.equal(1)
      const availableCars = await rentalityCarToken
        .connect(guest)
        .getAvailableCarsForUser(guest.address)
      expect(availableCars.length).to.equal(1)

      const rentPriceInUsdCents = 1000
      const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
        await rentalityCurrencyConverter.getEthFromUsdLatest(
          rentPriceInUsdCents,
        )

      await expect(
        rentalityPlatform.connect(guest).createTripRequest(
          {
            carId: 1,
            host: host.address,
            startDateTime: 123,
            endDateTime: 321,
            startLocation: '',
            endLocation: '',
            totalDayPriceInUsdCents: rentPriceInUsdCents,
            taxPriceInUsdCents: 0,
            depositInUsdCents: 0,
            fuelPricePerGalInUsdCents: 400,
            ethToCurrencyRate: ethToCurrencyRate,
            ethToCurrencyDecimals: ethToCurrencyDecimals,
          },
          { value: rentPriceInEth },
        ),
      ).not.to.be.reverted

      await expect(
        rentalityPlatform.connect(guest).createTripRequest(
          {
            carId: 1,
            host: host.address,
            startDateTime: 456,
            endDateTime: 789,
            startLocation: '',
            endLocation: '',
            totalDayPriceInUsdCents: rentPriceInUsdCents,
            taxPriceInUsdCents: 0,
            depositInUsdCents: 0,
            fuelPricePerGalInUsdCents: 400,
            ethToCurrencyRate: ethToCurrencyRate,
            ethToCurrencyDecimals: ethToCurrencyDecimals,
          },
          { value: rentPriceInEth },
        ),
      ).not.to.be.reverted

      expect(
        (await rentalityTripService.connect(host).getTrip(1)).status,
      ).to.equal(0)
      expect(
        (await rentalityTripService.connect(host).getTrip(2)).status,
      ).to.equal(0)

      await expect(rentalityPlatform.connect(host).approveTripRequest(1)).not.to
        .be.reverted

      const trip1 = await rentalityTripService.connect(host).getTrip(1)
      const trip2 = await rentalityTripService.connect(host).getTrip(2)
      expect(trip1.status).to.equal(1)
      expect(trip2.status).to.equal(0)
    })

    it('searchAvailableCars should return cars with Intersect trip in status Created', async function () {
      const {
        rentalityPlatform,
        rentalityCarToken,
        rentalityTripService,
        rentalityCurrencyConverter,
        host,
        guest,
      } = await loadFixture(deployDefaultFixture)

      await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0)))
        .not.to.be.reverted
      const myCars = await rentalityCarToken
        .connect(host)
        .getCarsOwnedByUser(host.address)
      expect(myCars.length).to.equal(1)

      const timestampNow = Math.floor(Date.now() / 1000)
      const timestampIn1Day = timestampNow + 3600 * 24
      const searchCarParams = getEmptySearchCarParams()
      const availableCars = await rentalityTripService
        .connect(guest)
        .searchAvailableCarsForUser(
          guest.address,
          timestampNow,
          timestampIn1Day,
          searchCarParams,
        )
      expect(availableCars.length).to.equal(1)

      const rentPriceInUsdCents = 1000
      const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
        await rentalityCurrencyConverter.getEthFromUsdLatest(
          rentPriceInUsdCents,
        )

      await expect(
        rentalityPlatform.connect(guest).createTripRequest(
          {
            carId: 1,
            host: host.address,
            startDateTime: timestampNow,
            endDateTime: timestampIn1Day,
            startLocation: '',
            endLocation: '',
            totalDayPriceInUsdCents: rentPriceInUsdCents,
            taxPriceInUsdCents: 0,
            depositInUsdCents: 0,
            fuelPricePerGalInUsdCents: 400,
            ethToCurrencyRate: ethToCurrencyRate,
            ethToCurrencyDecimals: ethToCurrencyDecimals,
          },
          { value: rentPriceInEth },
        ),
      ).not.to.be.reverted

      expect(
        (await rentalityTripService.connect(host).getTrip(1)).status,
      ).to.equal(0)

      //await expect( rentality.connect(host).approveTripRequest(1)).not.to.be.reverted;

      //const trip1 = (await rentality.connect(host).getTrip(1));
      //expect(trip1.status).to.equal(1);
      const availableCars2 = await rentalityTripService
        .connect(guest)
        .searchAvailableCarsForUser(
          guest.address,
          timestampNow,
          timestampIn1Day,
          searchCarParams,
        )
      expect(availableCars2.length).to.equal(1)
    })

    it("searchAvailableCars shouldn't return cars with Intersect trip in status approved", async function () {
      const {
        rentalityPlatform,
        rentalityTripService,
        rentalityCarToken,
        rentalityCurrencyConverter,
        host,
        guest,
      } = await loadFixture(deployDefaultFixture)

      await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0)))
        .not.to.be.reverted
      const myCars = await rentalityCarToken
        .connect(host)
        .getCarsOwnedByUser(host.address)
      expect(myCars.length).to.equal(1)

      const timestampNow = Math.floor(Date.now() / 1000)
      const timestampIn1Day = timestampNow + 3600 * 24
      const searchCarParams = getEmptySearchCarParams()
      const availableCars = await rentalityTripService
        .connect(guest)
        .searchAvailableCarsForUser(
          guest.address,
          timestampNow,
          timestampIn1Day,
          searchCarParams,
        )
      expect(availableCars.length).to.equal(1)

      const rentPriceInUsdCents = 1000
      const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
        await rentalityCurrencyConverter.getEthFromUsdLatest(
          rentPriceInUsdCents,
        )

      await expect(
        rentalityPlatform.connect(guest).createTripRequest(
          {
            carId: 1,
            host: host.address,
            startDateTime: timestampNow,
            endDateTime: timestampIn1Day,
            startLocation: '',
            endLocation: '',
            totalDayPriceInUsdCents: rentPriceInUsdCents,
            taxPriceInUsdCents: 0,
            depositInUsdCents: 0,
            fuelPricePerGalInUsdCents: 400,
            ethToCurrencyRate: ethToCurrencyRate,
            ethToCurrencyDecimals: ethToCurrencyDecimals,
          },
          { value: rentPriceInEth },
        ),
      ).not.to.be.reverted

      expect(
        (await rentalityTripService.connect(host).getTrip(1)).status,
      ).to.equal(0)

      await expect(rentalityPlatform.connect(host).approveTripRequest(1)).not.to
        .be.reverted

      const trip1 = await rentalityTripService.connect(host).getTrip(1)
      expect(trip1.status).to.equal(1)
      const availableCars2 = await rentalityTripService
        .connect(guest)
        .searchAvailableCarsForUser(
          guest.address,
          timestampNow,
          timestampIn1Day,
          searchCarParams,
        )
      expect(availableCars2.length).to.equal(0)
    })
  })

  describe('Reject Trip Request', function () {
    it('Host reject | trip status Created | trip money + deposit returned to guest', async function () {
      const {
        rentalityPlatform,
        rentalityCarToken,
        rentalityCurrencyConverter,
        rentalityTripService,
        host,
        guest,
      } = await loadFixture(deployDefaultFixture)

      await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0)))
        .not.to.be.reverted
      const myCars = await rentalityCarToken
        .connect(host)
        .getCarsOwnedByUser(host.address)
      expect(myCars.length).to.equal(1)
      const availableCars = await rentalityCarToken
        .connect(guest)
        .getAvailableCarsForUser(guest.address)
      expect(availableCars.length).to.equal(1)

      const rentPriceInUsdCents = 1600
      const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
        await rentalityCurrencyConverter.getEthFromUsdLatest(
          rentPriceInUsdCents,
        )

      await expect(
        await rentalityPlatform.connect(guest).createTripRequest(
          {
            carId: 1,
            host: host.address,
            startDateTime: 123,
            endDateTime: 321,
            startLocation: '',
            endLocation: '',
            totalDayPriceInUsdCents: 1000,
            taxPriceInUsdCents: 200,
            depositInUsdCents: 400,
            fuelPricePerGalInUsdCents: 400,
            ethToCurrencyRate: ethToCurrencyRate,
            ethToCurrencyDecimals: ethToCurrencyDecimals,
          },
          { value: rentPriceInEth },
        ),
      ).not.to.be.reverted
      expect(
        (await rentalityTripService.connect(host).getTrip(1)).status,
      ).to.equal(0)

      const balanceAfterRequest = await guest.getBalance()

      expect(await rentalityPlatform.connect(host).rejectTripRequest(1)).not.to
        .be.reverted
      expect(
        (await rentalityTripService.connect(host).getTrip(1)).status,
      ).to.equal(7)

      const balanceAfterRejection = await guest.getBalance()
      const returnAmountDifference =
        rentPriceInEth - balanceAfterRejection.sub(balanceAfterRequest)
      expect(
        returnAmountDifference === 0,
        'Balance should be refunded the amount which is deducted by a trip request',
      ).to.be.true
    })

    it('Guest reject | trip status Created | trip money + deposit - gas fee returned to guest', async function () {
      const {
        rentalityPlatform,
        rentalityCarToken,
        rentalityTripService,
        rentalityCurrencyConverter,
        host,
        guest,
      } = await loadFixture(deployDefaultFixture)

      await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0)))
        .not.to.be.reverted
      const myCars = await rentalityCarToken
        .connect(host)
        .getCarsOwnedByUser(host.address)
      expect(myCars.length).to.equal(1)
      const availableCars = await rentalityCarToken
        .connect(guest)
        .getAvailableCarsForUser(guest.address)
      expect(availableCars.length).to.equal(1)

      const rentPriceInUsdCents = 1600
      const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
        await rentalityCurrencyConverter.getEthFromUsdLatest(
          rentPriceInUsdCents,
        )

      await expect(
        await rentalityPlatform.connect(guest).createTripRequest(
          {
            carId: 1,
            host: host.address,
            startDateTime: 123,
            endDateTime: 321,
            startLocation: '',
            endLocation: '',
            totalDayPriceInUsdCents: 1000,
            taxPriceInUsdCents: 200,
            depositInUsdCents: 400,
            fuelPricePerGalInUsdCents: 400,
            ethToCurrencyRate: ethToCurrencyRate,
            ethToCurrencyDecimals: ethToCurrencyDecimals,
          },
          { value: rentPriceInEth },
        ),
      ).not.to.be.reverted
      expect(
        (await rentalityTripService.connect(host).getTrip(1)).status,
      ).to.equal(0)

      const balanceBeforeRejection = await guest.getBalance()

      const tx = await (
        await rentalityPlatform.connect(guest).rejectTripRequest(1)
      ).wait()

      const gasCost = tx.gasUsed.mul(tx.effectiveGasPrice)

      const balanceAfterRejection = await guest.getBalance()

      const expectedBalance = balanceBeforeRejection
        .add(rentPriceInEth)
        .sub(gasCost)

      expect(
        balanceAfterRejection.eq(expectedBalance),
        'The guest should be refunded minus the gas cost',
      ).to.be.true
    })

    it('Guest reject | trip status Accepted | trip money - 50% price per day - deposit - gas fee returned to guest', async function () {
      const {
        rentalityPlatform,
        rentalityCarToken,
        rentalityTripService,
        rentalityCurrencyConverter,
        host,
        guest,
      } = await loadFixture(deployDefaultFixture)

      await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(1)))
        .not.to.be.reverted
      const myCars = await rentalityCarToken
        .connect(host)
        .getCarsOwnedByUser(host.address)
      expect(myCars.length).to.equal(1)
      const availableCars = await rentalityCarToken
        .connect(guest)
        .getAvailableCarsForUser(guest.address)
      expect(availableCars.length).to.equal(1)

      const pricePerDayInUsdCents = 102
      const dailyPriceInUsdCents = 1000
      const rentPriceInUsdCents = dailyPriceInUsdCents + 600
      const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
        await rentalityCurrencyConverter.getEthFromUsdLatest(
          rentPriceInUsdCents,
        )
      const [pricePerDayInEth] =
        await rentalityCurrencyConverter.getEthFromUsdLatest(
          pricePerDayInUsdCents,
        )

      await expect(
        await rentalityPlatform.connect(guest).createTripRequest(
          {
            carId: 1,
            host: host.address,
            startDateTime: 123,
            endDateTime: 321,
            startLocation: '',
            endLocation: '',
            totalDayPriceInUsdCents: dailyPriceInUsdCents,
            taxPriceInUsdCents: 200,
            depositInUsdCents: 400,
            fuelPricePerGalInUsdCents: 400,
            ethToCurrencyRate: ethToCurrencyRate,
            ethToCurrencyDecimals: ethToCurrencyDecimals,
          },
          { value: rentPriceInEth },
        ),
      ).not.to.be.reverted

      await expect(await rentalityPlatform.connect(host).approveTripRequest(1))
        .not.to.be.reverted

      expect(
        (await rentalityTripService.connect(host).getTrip(1)).status,
      ).to.equal(1)

      const balanceBeforeRejection = await guest.getBalance()

      const tx = await (
        await rentalityPlatform.connect(guest).rejectTripRequest(1)
      ).wait()

      const gasCost = tx.gasUsed.mul(tx.effectiveGasPrice)

      const balanceAfterRejection = await guest.getBalance()

      const expectedBalance = balanceBeforeRejection
        .add(rentPriceInEth)
        .sub(gasCost)
        .sub(pricePerDayInEth / 2)

      expect(
        balanceAfterRejection.eq(expectedBalance),
        'The guest should be refunded minus the gas cost and minus 50% of daily price',
      ).to.be.true
    })

    it('Guest reject | trip status CheckedInByHost | trip money - 100% price per day - deposit - gas fee returned to guest', async function () {
      const {
        rentalityPlatform,
        rentalityCarToken,
        rentalityTripService,
        rentalityCurrencyConverter,
        host,
        guest,
      } = await loadFixture(deployDefaultFixture)

      await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(1)))
        .not.to.be.reverted
      const myCars = await rentalityCarToken
        .connect(host)
        .getCarsOwnedByUser(host.address)
      expect(myCars.length).to.equal(1)
      const availableCars = await rentalityCarToken
        .connect(guest)
        .getAvailableCarsForUser(guest.address)
      expect(availableCars.length).to.equal(1)

      const pricePerDayInUsdCents = 102
      const dailyPriceInUsdCents = 1000
      const rentPriceInUsdCents = dailyPriceInUsdCents + 600
      const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
        await rentalityCurrencyConverter.getEthFromUsdLatest(
          rentPriceInUsdCents,
        )
      const [pricePerDayInEth] =
        await rentalityCurrencyConverter.getEthFromUsdLatest(
          pricePerDayInUsdCents,
        )

      await expect(
        await rentalityPlatform.connect(guest).createTripRequest(
          {
            carId: 1,
            host: host.address,
            startDateTime: 123,
            endDateTime: 321,
            startLocation: '',
            endLocation: '',
            totalDayPriceInUsdCents: dailyPriceInUsdCents,
            taxPriceInUsdCents: 200,
            depositInUsdCents: 400,
            fuelPricePerGalInUsdCents: 400,
            ethToCurrencyRate: ethToCurrencyRate,
            ethToCurrencyDecimals: ethToCurrencyDecimals,
          },
          { value: rentPriceInEth },
        ),
      ).not.to.be.reverted

      await expect(await rentalityPlatform.connect(host).approveTripRequest(1))
        .not.to.be.reverted
      expect(
        (await rentalityTripService.connect(host).getTrip(1)).status,
      ).to.equal(1)

      await expect(
        await rentalityTripService.connect(host).checkInByHost(1, 10, 10),
      ).not.to.be.reverted
      expect(
        (await rentalityTripService.connect(host).getTrip(1)).status,
      ).to.equal(2)

      const balanceBeforeRejection = await guest.getBalance()

      const tx = await (
        await rentalityPlatform.connect(guest).rejectTripRequest(1)
      ).wait()

      const gasCost = tx.gasUsed.mul(tx.effectiveGasPrice)

      const balanceAfterRejection = await guest.getBalance()

      const expectedBalance = balanceBeforeRejection
        .add(rentPriceInEth)
        .sub(gasCost)
        .sub(pricePerDayInEth)

      expect(
        balanceAfterRejection.eq(expectedBalance),
        'The guest should be refunded minus the gas cost and minus the daily price',
      ).to.be.true
    })
  })
})
