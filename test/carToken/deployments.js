const { ethers, upgrades } = require('hardhat')
const { getMockCarRequest, ethToken } = require('../utils')

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

  const RentalityGeoService = await ethers.getContractFactory('RentalityGeoService')

  const RentalityUserService = await ethers.getContractFactory('RentalityUserService')
  const RentalityCarToken = await ethers.getContractFactory('RentalityCarToken', {
    libraries: {
      RentalityQuery: await query.getAddress(),
    },
  })

  const RentalityCurrencyConverter = await ethers.getContractFactory('RentalityCurrencyConverter')
  const RentalityPaymentService = await ethers.getContractFactory('RentalityPaymentService')
  const RentalityMockPriceFeed = await ethers.getContractFactory('RentalityMockPriceFeed')

  let rentalityMockPriceFeed = await RentalityMockPriceFeed.deploy(8, 200000000000)

  const MockCivic = await ethers.getContractFactory('CivicMockVerifier')
  const mockCivic = await MockCivic.deploy()
  await mockCivic.waitForDeployment()

  const rentalityUserService = await upgrades.deployProxy(RentalityUserService, [await mockCivic.getAddress(), 0])

  await rentalityUserService.waitForDeployment()

  const GeoParserMock = await ethers.getContractFactory('RentalityGeoMock')
  const geoParserMock = await GeoParserMock.deploy()
  await geoParserMock.waitForDeployment()

  const rentalityGeoService = await upgrades.deployProxy(RentalityGeoService, [
    await rentalityUserService.getAddress(),
    await geoParserMock.getAddress(),
  ])
  await rentalityGeoService.waitForDeployment()
  await geoParserMock.setGeoService(await rentalityGeoService.getAddress())

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

  const rentalityCurrencyConverter = await upgrades.deployProxy(RentalityCurrencyConverter, [
    await rentalityUserService.getAddress(),
    await ethContract.getAddress(),
  ])
  await rentalityCurrencyConverter.waitForDeployment()

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

  const rentalityCarToken = await upgrades.deployProxy(RentalityCarToken, [
    await rentalityGeoService.getAddress(),
    await engineService.getAddress(),
    await rentalityUserService.getAddress(),
  ])

  await rentalityCarToken.waitForDeployment()

  const RentalityTripService = await ethers.getContractFactory('RentalityTripService', {
    libraries: {
      RentalityUtils: await utils.getAddress(),
      RentalityQuery: await query.getAddress(),
    },
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

  await rentalityUserService.connect(host).setKYCInfo(' ', ' ', ' ', ' ', ' ', 1, true)
  await rentalityUserService.connect(guest).setKYCInfo(' ', ' ', ' ', ' ', ' ', 1, true)
  await rentalityUserService.setKYCInfo(' ', ' ', ' ', ' ', ' ', 1, true)

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
    geoParserMock,
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
    geoParserMock,
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
    geoParserMock,
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

module.exports = {
  deployDefaultFixture,
  deployFixtureWith1Car,
  deployFixtureWith2UserService,
}
