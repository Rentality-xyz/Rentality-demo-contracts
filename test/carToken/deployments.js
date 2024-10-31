const { ethers, upgrades } = require('hardhat')
const { getMockCarRequest, ethToken, signTCMessage, signKycInfo, emptyKyc } = require('../utils')

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
      RentalityUtils: await utils.getAddress(),
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
  let RentalityVerifier = await ethers.getContractFactory('RentalityLocationVerifier')

  let rentalityLocationVerifier = await upgrades.deployProxy(RentalityVerifier, [
    await rentalityUserService.getAddress(),
    admin.address,
  ])
  await rentalityLocationVerifier.waitForDeployment()

  const rentalityGeoService = await upgrades.deployProxy(RentalityGeoService, [
    await rentalityUserService.getAddress(),
    await rentalityLocationVerifier.getAddress(),
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

  const patrolEngine = await ethers.getContractFactory('RentalityPetrolEngine')
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
    libraries: {},
  })

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

  const RealMath = await ethers.getContractFactory('RealMath')
  const realMath = await RealMath.deploy()

  const DeliveryService = await ethers.getContractFactory('RentalityCarDelivery', {
    libraries: {
      RealMath: await realMath.getAddress(),
      RentalityUtils: await utils.getAddress(),
    },
  })
  const deliveryService = await upgrades.deployProxy(DeliveryService, [await rentalityUserService.getAddress()])

  let TripsQuery = await ethers.getContractFactory('RentalityTripsQuery')
  let tripsQuery = await TripsQuery.deploy()
  const RentalityPlatform = await ethers.getContractFactory('RentalityPlatform', {
    libraries: {
      RentalityUtils: await utils.getAddress(),
      RentalityQuery: await query.getAddress(),
    },
  })

  let RentalityView = await ethers.getContractFactory('RentalityView', {
    libraries: {
      RentalityUtils: await utils.getAddress(),
      RentalityQuery: await query.getAddress(),
      RentalityTripsQuery: await tripsQuery.getAddress(),
    },
  })

  const rentalityView = await upgrades.deployProxy(RentalityView, [
    await rentalityCarToken.getAddress(),
    await rentalityCurrencyConverter.getAddress(),
    await rentalityTripService.getAddress(),
    await rentalityUserService.getAddress(),
    await rentalityPaymentService.getAddress(),
    await claimService.getAddress(),
    await deliveryService.getAddress(),
  ])
  await rentalityView.waitForDeployment()
  const rentalityPlatform = await upgrades.deployProxy(RentalityPlatform, [
    await rentalityCarToken.getAddress(),
    await rentalityCurrencyConverter.getAddress(),
    await rentalityTripService.getAddress(),
    await rentalityUserService.getAddress(),
    await rentalityPaymentService.getAddress(),
    await claimService.getAddress(),
    await deliveryService.getAddress(),
    await rentalityView.getAddress(),
  ])
  await rentalityPlatform.waitForDeployment()

  const RentalityAdminGateway = await ethers.getContractFactory('RentalityAdminGateway', {
    libraries: {
      RentalityUtils: await utils.getAddress(),
      RentalityQuery: await query.getAddress(),
    },
  })
  const rentalityAdminGateway = await upgrades.deployProxy(RentalityAdminGateway, [
    await rentalityCarToken.getAddress(),
    await rentalityCurrencyConverter.getAddress(),
    await rentalityTripService.getAddress(),
    await rentalityUserService.getAddress(),
    await rentalityPlatform.getAddress(),
    await rentalityPaymentService.getAddress(),
    await claimService.getAddress(),
    await deliveryService.getAddress(),
    await rentalityView.getAddress(),
  ])
  await rentalityAdminGateway.waitForDeployment()

  let RentalityGateway = await ethers.getContractFactory('RentalityGateway', {
    libraries: {},
  })
  let rentalityGateway = await upgrades.deployProxy(RentalityGateway.connect(owner), [
    await rentalityCarToken.getAddress(),
    await rentalityCurrencyConverter.getAddress(),
    await rentalityTripService.getAddress(),
    await rentalityUserService.getAddress(),
    await rentalityPlatform.getAddress(),
    await rentalityPaymentService.getAddress(),
    await claimService.getAddress(),
    await rentalityAdminGateway.getAddress(),
    await deliveryService.getAddress(),
    await rentalityView.getAddress(),
  ])
  await rentalityGateway.waitForDeployment()

  rentalityGateway = await ethers.getContractAt('IRentalityGateway', await rentalityGateway.getAddress())

  await rentalityUserService.connect(owner).grantHostRole(await rentalityPlatform.getAddress())

  await rentalityUserService.connect(owner).grantManagerRole(await rentalityView.getAddress())
  await rentalityUserService.connect(owner).grantManagerRole(await rentalityAdminGateway.getAddress())
  await rentalityUserService.connect(owner).grantManagerRole(await rentalityGateway.getAddress())
  await rentalityUserService.connect(owner).grantAdminRole(await rentalityGateway.getAddress())
  await rentalityUserService.connect(owner).grantAdminRole(await rentalityAdminGateway.getAddress())
  await rentalityUserService.connect(owner).grantManagerRole(await rentalityCarToken.getAddress())
  await rentalityUserService.connect(owner).grantManagerRole(await engineService.getAddress())
  await rentalityUserService.connect(owner).grantManagerRole(await rentalityPlatform.getAddress())
  await rentalityUserService.connect(owner).grantManagerRole(await rentalityPaymentService.getAddress())

  const hostSignature = await signTCMessage(host)
  const guestSignature = await signTCMessage(guest)
  const deployerSignature = await signTCMessage(owner)
  const adminKyc = signKycInfo(await rentalityLocationVerifier.getAddress(), admin)
  await rentalityPlatform.connect(host).setKYCInfo(' ', ' ', ' ', hostSignature)
  await rentalityPlatform.connect(guest).setKYCInfo(' ', ' ', ' ', guestSignature)
  await rentalityPlatform.setKYCInfo(' ', ' ', ' ', deployerSignature)

  return {
    rentalityCarToken,
    rentalityUserService,
    rentalityTripService,
    rentalityGeoService,
    rentalityGateway,
    owner,
    admin,
    manager,
    host,
    guest,
    anonymous,
    geoParserMock,
    rentalityLocationVerifier,
  }
}

async function deployFixtureWith1Car() {
  const {
    rentalityCarToken,
    rentalityUserService,
    rentalityTripService,
    rentalityGeoService,
    rentalityGateway,
    owner,
    admin,
    manager,
    host,
    guest,
    anonymous,
    geoParserMock,
    rentalityLocationVerifier,
  } = await deployDefaultFixture()

  const request = getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin)

  await rentalityPlatform.connect(host).addCar(request)

  return {
    rentalityCarToken,
    rentalityUserService,
    rentalityTripService,
    rentalityGeoService,
    rentalityGateway,
    owner,
    admin,
    manager,
    host,
    guest,
    anonymous,
    geoParserMock,
    rentalityLocationVerifier,
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

  const patrolEngine = await ethers.getContractFactory('RentalityPetrolEngine.sol')
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
