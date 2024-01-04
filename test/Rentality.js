const {
  time,
  loadFixture,
} = require('@nomicfoundation/hardhat-network-helpers')

const { expect } = require('chai')
const { ethers, upgrades, artifacts } = require('hardhat')
const {getMockCarRequest, getEmptySearchCarParams} = require("./utils");

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
      { libraries: { RentalityUtils: await utils.getAddress() } },
    )
    const RentalityCurrencyConverter = await ethers.getContractFactory(
      'RentalityCurrencyConverter',
    )
    const RentalityPaymentService = await ethers.getContractFactory(
      'RentalityPaymentService',
    )
    const RentalityGeoService = await ethers.getContractFactory(
      'RentalityGeoMock');

    const rentalityGeoService = await RentalityGeoService.deploy();

    const RentalityCarToken =
      await ethers.getContractFactory('RentalityCarToken')

    const RentalityPlatform =
      await ethers.getContractFactory('RentalityPlatform',
        {
          libraries:
            {
              RentalityUtils: await utils.getAddress()
            }
        })

    let rentalityMockPriceFeed = await RentalityMockPriceFeed.deploy(
      8,
      200000000000,
    )
    await rentalityMockPriceFeed.waitForDeployment()

    const rentalityUserService = await upgrades.deployProxy(RentalityUserService)
    await rentalityUserService.waitForDeployment()

    await rentalityUserService.connect(owner).grantAdminRole(admin.address)
    await rentalityUserService.connect(owner).grantManagerRole(manager.address)
    await rentalityUserService.connect(owner).grantHostRole(host.address)
    await rentalityUserService.connect(owner).grantGuestRole(guest.address)

    const rentalityCurrencyConverter = await upgrades.deployProxy(RentalityCurrencyConverter,
      [await rentalityMockPriceFeed.getAddress(),
        await rentalityUserService.getAddress()]
    )
    await rentalityCurrencyConverter.waitForDeployment()

    const patrolEngine = await ethers.getContractFactory('RentalityPatrolEngine')
    const pEngine = await patrolEngine.deploy(await rentalityUserService.getAddress())

    const electricEngine = await ethers.getContractFactory('RentalityElectricEngine')
    const elEngine = await electricEngine.deploy(await rentalityUserService.getAddress())

    const hybridEngine = await ethers.getContractFactory('RentalityHybridEngine')
    const hEngine = await hybridEngine.deploy(await rentalityUserService.getAddress())

    const EngineService = await ethers.getContractFactory('RentalityEnginesService')

    const engineService = await upgrades.deployProxy(EngineService,[
      await rentalityUserService.getAddress(),
      [await pEngine.getAddress(),await elEngine.getAddress(),await hEngine.getAddress()]
      ]
    );
    await engineService.waitForDeployment()


    const rentalityCarToken = await upgrades.deployProxy(RentalityCarToken,[await rentalityGeoService.getAddress(),await engineService.getAddress()],{kind:'uups'})
    await rentalityCarToken.waitForDeployment()
    const rentalityPaymentService = await upgrades.deployProxy(RentalityPaymentService,[await rentalityUserService.getAddress()])
    await rentalityPaymentService.waitForDeployment()

    const rentalityTripService = await upgrades.deployProxy(RentalityTripService,[
      await rentalityCurrencyConverter.getAddress(),
      await rentalityCarToken.getAddress(),
      await rentalityPaymentService.getAddress(),
      await rentalityUserService.getAddress(),
      await engineService.getAddress()
    ]);
    await rentalityTripService.waitForDeployment()

    const RentalityClaimService = await ethers.getContractFactory('RentalityClaimService')
    const claimService = await upgrades.deployProxy(RentalityClaimService, [await rentalityUserService.getAddress()])
    await claimService.waitForDeployment()

    const rentalityPlatform = await upgrades.deployProxy(RentalityPlatform, [
      await rentalityCarToken.getAddress(),
      await rentalityCurrencyConverter.getAddress(),
      await rentalityTripService.getAddress(),
      await rentalityUserService.getAddress(),
      await rentalityPaymentService.getAddress(),
      await claimService.getAddress(),
    ])

    await rentalityPlatform.waitForDeployment()

    await rentalityUserService
      .connect(owner)
      .grantHostRole(await rentalityPlatform.getAddress())
    await rentalityUserService
      .connect(owner)
      .grantManagerRole(await rentalityPlatform.getAddress())

    await rentalityUserService
      .connect(owner)
      .grantManagerRole(await rentalityTripService.getAddress())
    await rentalityUserService
      .connect(owner)
      .grantManagerRole(await rentalityCarToken.getAddress())
    await rentalityUserService
      .connect(owner)
      .grantManagerRole(await engineService.getAddress())

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
            fuelPrices: [400],
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
            fuelPrices: [400],
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
            fuelPrices: [400],
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
            fuelPrices: [400],
            ethToCurrencyRate: ethToCurrencyRate,
            ethToCurrencyDecimals: ethToCurrencyDecimals,
          },
          { value: rentPriceInEth },
        ),
      ).not.to.be.reverted

      await expect(rentalityPlatform.connect(host).approveTripRequest(1)).not.to
        .be.reverted
      await expect(rentalityTripService.connect(host).checkInByHost(1, [0, 0]))
        .not.to.be.reverted
      await expect(rentalityTripService.connect(guest).checkInByGuest(1, [0, 0]))
        .not.to.be.reverted
      await expect(rentalityTripService.connect(guest).checkOutByGuest(1, [0, 0]))
        .not.to.be.reverted
      await expect(rentalityTripService.connect(host).checkOutByHost(1, [0, 0]))
        .not.to.be.reverted
      const returnToHost =
        rentPriceInEth -
        (rentPriceInEth *
          (await rentalityPaymentService.getPlatformFeeInPPM())) /
          BigInt(1_000_000)

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
            fuelPrices: [400],
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
            fuelPrices: [400],
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
            fuelPrices: [400],
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
            fuelPrices: [400],
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
            fuelPrices: [400],
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
            fuelPrices: [400],
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
            fuelPrices: [400],
            ethToCurrencyRate: ethToCurrencyRate,
            ethToCurrencyDecimals: ethToCurrencyDecimals,
          },
          { value: rentPriceInEth },
        ),
      ).not.to.be.reverted
      expect(
        (await rentalityTripService.connect(host).getTrip(1)).status,
      ).to.equal(0)

      const balanceAfterRequest =  await ethers.provider.getBalance(await guest.getAddress())

      expect(await rentalityPlatform.connect(host).rejectTripRequest(1)).not.to
        .be.reverted
      expect(
        (await rentalityTripService.connect(host).getTrip(1)).status,
      ).to.equal(7)

      const balanceAfterRejection = await ethers.provider.getBalance(await guest.getAddress())
      const returnAmountDifference =
        rentPriceInEth - (balanceAfterRejection - balanceAfterRequest)
      expect(
        returnAmountDifference === BigInt(0),
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
            fuelPrices: [400],
            ethToCurrencyRate: ethToCurrencyRate,
            ethToCurrencyDecimals: ethToCurrencyDecimals,
          },
          { value: rentPriceInEth },
        ),
      ).not.to.be.reverted
      expect(
        (await rentalityTripService.connect(host).getTrip(1)).status,
      ).to.equal(0)


      const balanceBeforeRejection = await ethers.provider.getBalance(await guest.getAddress())

      const tx = await (
        await rentalityPlatform.connect(guest).rejectTripRequest(1)
      ).wait()

      const gasCost = tx.gasUsed * tx.gasPrice

      const balanceAfterRejection =  await ethers.provider.getBalance(await guest.getAddress())

      const expectedBalance = balanceBeforeRejection
         + rentPriceInEth
        - gasCost

      expect(
        balanceAfterRejection === BigInt(expectedBalance),
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
            fuelPrices: [400],
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

      const balanceBeforeRejection = await ethers.provider.getBalance(await guest.getAddress())

      const tx = await (
        await rentalityPlatform.connect(guest).rejectTripRequest(1)
      ).wait()

      const gasCost = tx.gasUsed * tx.gasPrice

      const balanceAfterRejection =  await ethers.provider.getBalance(await guest.getAddress())

      const expectedBalance = balanceBeforeRejection
        + rentPriceInEth
        - gasCost
        - (pricePerDayInEth / BigInt(2))

      expect(
        balanceAfterRejection === expectedBalance,
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
            fuelPrices: [400],
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
        await rentalityTripService.connect(host).checkInByHost(1, [10, 10]),
      ).not.to.be.reverted
      expect(
        (await rentalityTripService.connect(host).getTrip(1)).status,
      ).to.equal(2)

      const balanceBeforeRejection = await ethers.provider.getBalance(await guest.getAddress())

      const tx = await (
        await rentalityPlatform.connect(guest).rejectTripRequest(1)
      ).wait()

      const gasCost = tx.gasUsed * tx.gasPrice

      const balanceAfterRejection = await ethers.provider.getBalance(await guest.getAddress())

      const expectedBalance = balanceBeforeRejection
        + rentPriceInEth
        - gasCost
        - pricePerDayInEth

      expect(
        balanceAfterRejection === BigInt(expectedBalance),
        'The guest should be refunded minus the gas cost and minus the daily price',
      ).to.be.true
    })
  })
})
