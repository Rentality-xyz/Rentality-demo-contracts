const { ethers, upgrades } = require('hardhat')
const ethToken = ethers.getAddress('0x0000000000000000000000000000000000000000')

const calculatePayments = async (currencyConverter, paymentService, value, tripDays, deposit) => {
  let priceWithDiscount = await paymentService.calculateSumWithDiscount(
    '0x0000000000000000000000000000000000000000',
    tripDays,
    value
  )
  let totalTaxes = await paymentService.calculateTaxes(1, tripDays, priceWithDiscount)

  const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] = await currencyConverter.getFromUsdLatest(
    ethToken,
    priceWithDiscount + totalTaxes + BigInt(deposit)
  )

  const [priceWithoutTaxes, ,] = await currencyConverter.getFromUsdLatest(ethToken, priceWithDiscount)

  const rentalityFee = await paymentService.getPlatformFeeFrom(priceWithoutTaxes)

  return {
    rentPriceInEth,
    ethToCurrencyRate,
    ethToCurrencyDecimals,
    rentalityFee,
  }
}

const calculatePaymentsFrom = async (currencyConverter, paymentService, value, tripDays, deposit, token) => {
  let priceWithDiscount = await paymentService.calculateSumWithDiscount(
    '0x0000000000000000000000000000000000000000',
    tripDays,
    value
  )
  let totalTaxes = await paymentService.calculateTaxes(1, tripDays, value)

  const [rentPrice, currencyRate, currencyDecimals] = await currencyConverter.getFromUsdLatest(
    token,
    priceWithDiscount + totalTaxes + BigInt(deposit)
  )

  const [priceWithoutTaxes, ,] = await currencyConverter.getFromUsdLatest(token, priceWithDiscount)

  const rentalityFee = await paymentService.getPlatformFeeFrom(priceWithoutTaxes)

  return {
    rentPrice,
    currencyRate,
    currencyDecimals,
    rentalityFee,
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
  const ENGINE_PARAMS = [seedInt * 100 + 4, seedInt * 100 + 5]
  const ETYPE = 1
  const DISTANCE_INCLUDED = seedInt * 100 + 6
  const location = 'kyiv ukraine'
  const locationCoordinates = ' ' + seedInt
  const apiKey = process.env.GOOGLE_API_KEY || ' '
  const timeBufferBetweenTripsInSec = 0
  const locationLatitude = seedStr
  const locationLongitude = seedStr

  return {
    tokenUri: TOKEN_URI,
    carVinNumber: VIN_NUMBER,
    brand: BRAND,
    model: MODEL,
    yearOfProduction: YEAR,
    pricePerDayInUsdCents: PRICE_PER_DAY,
    securityDepositPerTripInUsdCents: DEPOSIT,
    engineParams: ENGINE_PARAMS,
    engineType: ETYPE,
    milesIncludedPerDay: DISTANCE_INCLUDED,
    timeBufferBetweenTripsInSec: timeBufferBetweenTripsInSec,
    locationAddress: location,
    locationLatitude,
    locationLongitude,
    geoApiKey: apiKey,
  }
}

function getMockCarRequestWithAddress(seed, address) {
  return { ...getMockCarRequest(seed), locationAddress: address }
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
  const ENGINE_PARAMS = [seedInt * 100 + 4, seedInt * 100 + 5]
  const ETYPE = 1
  const DISTANCE_INCLUDED = seedInt * 100 + 6
  const location = 'Miami Riverwalk, Miami, Florida, USA'
  const locationCoordinates = ' ' + seedInt
  const apiKey = process.env.GOOGLE_API_KEY || ' '
  const timeBufferBetweenTripsInSec = 0
  const locationLatitude = seedStr
  const locationLongitude = seedStr

  return {
    tokenUri: TOKEN_URI,
    carVinNumber: VIN_NUMBER,
    brand: BRAND,
    model: MODEL,
    yearOfProduction: YEAR,
    pricePerDayInUsdCents: PRICE_PER_DAY,
    securityDepositPerTripInUsdCents: DEPOSIT,
    engineParams: ENGINE_PARAMS,
    engineType: ETYPE,
    milesIncludedPerDay: DISTANCE_INCLUDED,
    timeBufferBetweenTripsInSec: timeBufferBetweenTripsInSec,
    locationAddress: location,
    locationLatitude,
    locationLongitude,
    geoApiKey: apiKey,
  }
}

function createMockClaimRequest(tripId, amountToClaim) {
  return {
    tripId: tripId,
    claimType: 1,
    description: 'Some des',
    amountInUsdCents: amountToClaim,
  }
}

const TripStatus = {
  Created: 0,
  Approved: 1,
  CheckedInByHost: 2,
  CheckedInByGuest: 3,
  CheckedOutByGuest: 4,
  CheckedOutByHost: 5,
  Finished: 6,
  Canceled: 7,
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

async function deployDefaultFixture() {
  const [owner, admin, manager, host, guest, anonymous] = await ethers.getSigners()

  const chainId = (await owner.provider?.getNetwork())?.chainId ?? -1

  if (chainId !== 1337n) {
    console.log('Can be running only on localhost')
    process.exit(1)
  }

  const RentalityUtils = await ethers.getContractFactory('RentalityUtils')
  const utils = await RentalityUtils.deploy()

  const RentalityQuery = await ethers.getContractFactory('RentalityQuery')
  const query = await RentalityQuery.deploy()

  const RentalityMockPriceFeed = await ethers.getContractFactory('RentalityMockPriceFeed')
  const RentalityUserService = await ethers.getContractFactory('RentalityUserService')
  const RentalityTripService = await ethers.getContractFactory('RentalityTripService', {
    libraries: {
      RentalityQuery: await query.getAddress(),
      RentalityUtils: await utils.getAddress(),
    },
  })

  const RentalityCurrencyConverter = await ethers.getContractFactory('RentalityCurrencyConverter')
  const RentalityPaymentService = await ethers.getContractFactory('RentalityPaymentService')
  const RentalityCarToken = await ethers.getContractFactory('RentalityCarToken', {
    libraries: {
      RentalityQuery: await query.getAddress(),
    },
  })

  const RentalityPlatform = await ethers.getContractFactory('RentalityPlatform', {
    libraries: {
      RentalityUtils: await utils.getAddress(),
      RentalityQuery: await query.getAddress(),
    },
  })
  const RentalityGeoService = await ethers.getContractFactory('RentalityGeoService')

  let RentalityGateway = await ethers.getContractFactory('RentalityGateway', {
    libraries: {
      RentalityQuery: await query.getAddress(),
      RentalityUtils: await utils.getAddress(),
    },
  })

  let rentalityMockPriceFeed = await RentalityMockPriceFeed.deploy(8, 200000000000)
  await rentalityMockPriceFeed.waitForDeployment()

  let rentalityMockUsdtPriceFeed = await RentalityMockPriceFeed.deploy(6, 100)
  await rentalityMockPriceFeed.waitForDeployment()

  const MockCivic = await ethers.getContractFactory('CivicMockVerifier')
  const mockCivic = await MockCivic.deploy()
  await mockCivic.waitForDeployment()

  const rentalityUserService = await upgrades.deployProxy(RentalityUserService, [await mockCivic.getAddress(), 0])

  await rentalityUserService.waitForDeployment()

  const electricEngine = await ethers.getContractFactory('RentalityElectricEngine')
  const elEngine = await electricEngine.deploy(await rentalityUserService.getAddress())

  const patrolEngine = await ethers.getContractFactory('RentalityPatrolEngine')
  const pEngine = await patrolEngine.deploy(await rentalityUserService.getAddress())

  const hybridEngine = await ethers.getContractFactory('RentalityHybridEngine')
  const hEngine = await hybridEngine.deploy(await rentalityUserService.getAddress())

  const EngineService = await ethers.getContractFactory('RentalityEnginesService')
  const engineService = await upgrades.deployProxy(EngineService, [
    await rentalityUserService.getAddress(),
    [await pEngine.getAddress(), await elEngine.getAddress(), await hEngine.getAddress()],
  ])
  await engineService.waitForDeployment()

  await rentalityUserService.connect(owner).grantAdminRole(admin.address)
  await rentalityUserService.connect(owner).grantManagerRole(manager.address)
  await rentalityUserService.connect(owner).grantHostRole(host.address)
  await rentalityUserService.connect(owner).grantGuestRole(guest.address)

  const RentalityEth = await ethers.getContractFactory('RentalityETHConvertor')

  const ethContract = await upgrades.deployProxy(RentalityEth, [
    await rentalityUserService.getAddress(),
    ethToken,
    await rentalityMockPriceFeed.getAddress(),
  ])

  await ethContract.waitForDeployment()

  const TestUsdt = await ethers.getContractFactory('RentalityTestUSDT')
  const usdtContract = await TestUsdt.deploy()
  await usdtContract.waitForDeployment()

  const RentalityUSDT = await ethers.getContractFactory('RentalityUSDTConverter')

  const usdtPaymentContract = await upgrades.deployProxy(RentalityUSDT, [
    await rentalityUserService.getAddress(),
    await usdtContract.getAddress(),
    await rentalityMockUsdtPriceFeed.getAddress(),
  ])
  await usdtContract.waitForDeployment()

  const rentalityCurrencyConverter = await upgrades.deployProxy(RentalityCurrencyConverter, [
    await rentalityUserService.getAddress(),
    await ethContract.getAddress(),
  ])
  await rentalityCurrencyConverter.waitForDeployment()

  const GeoParserMock = await ethers.getContractFactory('RentalityGeoMock')
  const geoParserMock = await GeoParserMock.deploy()
  await geoParserMock.waitForDeployment()

  const rentalityGeoService = await upgrades.deployProxy(RentalityGeoService, [
    await rentalityUserService.getAddress(),
    await geoParserMock.getAddress(),
  ])
  await rentalityGeoService.waitForDeployment()
  await geoParserMock.setGeoService(await rentalityGeoService.getAddress())

  const rentalityCarToken = await upgrades.deployProxy(RentalityCarToken, [
    await rentalityGeoService.getAddress(),
    await engineService.getAddress(),
    await rentalityUserService.getAddress(),
  ])
  await rentalityCarToken.waitForDeployment()

  const RentalityFloridaTaxes = await ethers.getContractFactory('RentalityFloridaTaxes')

  const rentalityFloridaTaxes = await upgrades.deployProxy(RentalityFloridaTaxes, [
    await rentalityUserService.getAddress(),
  ])

  const RentalityBaseDiscount = await ethers.getContractFactory('RentalityBaseDiscount')

  const rentalityBaseDiscount = await upgrades.deployProxy(RentalityBaseDiscount, [
    await rentalityUserService.getAddress(),
  ])

  const rentalityPaymentService = await upgrades.deployProxy(RentalityPaymentService, [
    await rentalityUserService.getAddress(),
    await rentalityFloridaTaxes.getAddress(),
    await rentalityBaseDiscount.getAddress(),
  ])
  await rentalityPaymentService.waitForDeployment()

  const rentalityTripService = await upgrades.deployProxy(RentalityTripService, [
    await rentalityCurrencyConverter.getAddress(),
    await rentalityCarToken.getAddress(),
    await rentalityPaymentService.getAddress(),
    await rentalityUserService.getAddress(),
    await engineService.getAddress(),
  ])
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

  const RentalityAdminGateway = await ethers.getContractFactory('RentalityAdminGateway')
  const rentalityAdminGateway = await upgrades.deployProxy(RentalityAdminGateway, [
    await rentalityCarToken.getAddress(),
    await rentalityCurrencyConverter.getAddress(),
    await rentalityTripService.getAddress(),
    await rentalityUserService.getAddress(),
    await rentalityPlatform.getAddress(),
    await rentalityPaymentService.getAddress(),
    await claimService.getAddress(),
  ])
  await rentalityAdminGateway.waitForDeployment()

  await rentalityUserService.connect(owner).grantHostRole(await rentalityPlatform.getAddress())

  await rentalityUserService.connect(owner).grantManagerRole(await rentalityPlatform.getAddress())

  await rentalityUserService.connect(owner).grantManagerRole(await rentalityTripService.getAddress())

  await rentalityUserService.connect(owner).grantManagerRole(await rentalityPlatform.getAddress())

  let rentalityGateway = await upgrades.deployProxy(RentalityGateway.connect(owner), [
    await rentalityCarToken.getAddress(),
    await rentalityCurrencyConverter.getAddress(),
    await rentalityTripService.getAddress(),
    await rentalityUserService.getAddress(),
    await rentalityPlatform.getAddress(),
    await rentalityPaymentService.getAddress(),
    await claimService.getAddress(),
    await rentalityAdminGateway.getAddress(),
  ])
  await rentalityGateway.waitForDeployment()

  await rentalityUserService.connect(owner).grantManagerRole(await rentalityAdminGateway.getAddress())
  await rentalityUserService.connect(owner).grantManagerRole(await rentalityGateway.getAddress())
  await rentalityUserService.connect(owner).grantAdminRole(await rentalityGateway.getAddress())
  await rentalityUserService.connect(owner).grantAdminRole(await rentalityAdminGateway.getAddress())
  await rentalityUserService.connect(owner).grantManagerRole(await rentalityCarToken.getAddress())
  await rentalityUserService.connect(owner).grantManagerRole(await engineService.getAddress())
  await rentalityUserService.connect(owner).grantManagerRole(await rentalityPaymentService.getAddress())

  await rentalityGateway.connect(host).setKYCInfo(' ', ' ', ' ', ' ', ' ', 1, true)
  await rentalityGateway.connect(guest).setKYCInfo(' ', ' ', ' ', ' ', ' ', 1, true)

  await rentalityCurrencyConverter.addCurrencyType(
    await usdtContract.getAddress(),
    await usdtPaymentContract.getAddress()
  )

  return {
    rentalityGateway,
    rentalityMockPriceFeed,
    rentalityUserService,
    rentalityTripService,
    rentalityCurrencyConverter,
    rentalityCarToken,
    rentalityPaymentService,
    rentalityPlatform,
    rentalityAdminGateway,
    utils,
    query,
    engineService,
    elEngine,
    pEngine,
    hEngine,
    owner,
    admin,
    manager,
    host,
    guest,
    anonymous,
    usdtContract,
    geoParserMock,
    rentalityFloridaTaxes,
    rentalityBaseDiscount,
  }
}

module.exports = {
  getMockCarRequest,
  getEmptySearchCarParams,
  createMockClaimRequest,
  deployDefaultFixture,
  TripStatus,
  ethToken,
  getMockCarRequestWithAddress,
  calculatePayments,
  calculatePaymentsFrom,
}
