const { ethers, upgrades } = require('hardhat')
const { ethToken, signTCMessage, signKycInfo, emptyKyc, zeroHash } = require('../utils')

// We define a fixture to reuse the same setup in every test.
// We use loadFixture to run this setup once, snapshot that state,
// and reset Hardhat Network to that snapshot in every test.
async function deployDefaultFixture() {
  const [owner, admin, manager, host, guest, anonymous] = await ethers.getSigners()

  const chainId = (await owner.provider?.getNetwork())?.chainId ?? -1

  if (chainId !== 1337n) throw new Error('Can be running only on localhost')

  const RentalityUtils = await ethers.getContractFactory('RentalityUtils')
  const utils = await RentalityUtils.deploy()

  await utils.waitForDeployment()


  const RentalityViewLib = await ethers.getContractFactory('RentalityViewLib', {
    libraries:
     {
      RentalityUtils: await utils.getAddress(),
    }
  }
  )

  const viewLib = await RentalityViewLib.deploy()


  const RentalityQuery = await ethers.getContractFactory('RentalityQuery')
  const query = await RentalityQuery.deploy()

  const RentalityMockPriceFeed = await ethers.getContractFactory('RentalityMockPriceFeed')
  const RentalityUserService = await ethers.getContractFactory('RentalityUserService')
  const RentalityTripService = await ethers.getContractFactory('RentalityTripService', {
    libraries: {},
  })
  const RentalityCurrencyConverter = await ethers.getContractFactory('RentalityCurrencyConverter')
  const RentalityPaymentService = await ethers.getContractFactory('RentalityPaymentService')
  const RentalityGeoService = await ethers.getContractFactory('RentalityGeoService')

  const RentalityCarToken = await ethers.getContractFactory('RentalityCarToken', {
    libraries: { RentalityUtils: await utils.getAddress() },
  })
  let TripsQuery = await ethers.getContractFactory('RentalityTripsQuery', {
    libraries: {

    },
  })
  let tripsQuery = await TripsQuery.deploy()
  const RentalityPlatform = await ethers.getContractFactory('RentalityPlatform', {
    libraries: {
      RentalityUtils: await utils.getAddress(),
    },
  })

  let rentalityMockPriceFeed = await RentalityMockPriceFeed.deploy(8, 200000000000)
  await rentalityMockPriceFeed.waitForDeployment()

  const MockCivic = await ethers.getContractFactory('CivicMockVerifier')
  const mockCivic = await MockCivic.deploy()
  await mockCivic.waitForDeployment()

  const rentalityUserService = await upgrades.deployProxy(RentalityUserService, [await mockCivic.getAddress(), 0])

  const RentalityNotificationService = await ethers.getContractFactory('RentalityNotificationService')

  const rentalityNotificationService = await upgrades.deployProxy(RentalityNotificationService, [
    await rentalityUserService.getAddress(),
  ])
  await rentalityNotificationService.waitForDeployment()
  const electricEngine = await ethers.getContractFactory('RentalityElectricEngine')
  const elEngine = await electricEngine.deploy(await rentalityUserService.getAddress())
  await elEngine.waitForDeployment()

  const patrolEngine = await ethers.getContractFactory('RentalityPetrolEngine')
  const pEngine = await patrolEngine.deploy(await rentalityUserService.getAddress())
  await pEngine.waitForDeployment()

  const hybridEngine = await ethers.getContractFactory('RentalityHybridEngine')
  const hEngine = await hybridEngine.deploy(await rentalityUserService.getAddress())
  await hEngine.waitForDeployment()

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

  const PromoService = await ethers.getContractFactory('RentalityPromoService')
  const promoService = await upgrades.deployProxy(PromoService, [await rentalityUserService.getAddress()])

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

  const GeoParserMock = await ethers.getContractFactory('RentalityGeoMock')
  const geoParserMock = await GeoParserMock.deploy()
  await geoParserMock.waitForDeployment()

  const RentalityVerifier = await ethers.getContractFactory('RentalityLocationVerifier')

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

  const rentalityCarToken = await upgrades.deployProxy(RentalityCarToken, [
    await rentalityGeoService.getAddress(),
    await engineService.getAddress(),
    await rentalityUserService.getAddress(),
    await rentalityNotificationService.getAddress(),
  ])

  await rentalityCarToken.waitForDeployment()


  const DimoService = await ethers.getContractFactory('RentalityDimoService')
  const dimoService = await upgrades.deployProxy(DimoService, [await rentalityUserService.getAddress(), await rentalityCarToken.getAddress()])

  let RefferalLibFactory = await ethers.getContractFactory('RentalityRefferalLib')
  let refferalLib = await RefferalLibFactory.deploy()
  await refferalLib.waitForDeployment()

  let ReffProgram = await ethers.getContractFactory('RentalityReferralProgram', {
    libraries: {
      RentalityRefferalLib: await refferalLib.getAddress(),
    },
  })

  const refferalProgram = await upgrades.deployProxy(ReffProgram, [
    await rentalityUserService.getAddress(),
    await refferalLib.getAddress(),
    await rentalityCarToken.getAddress(),
  ])
  await refferalProgram.waitForDeployment()

  const RentalityFloridaTaxes = await ethers.getContractFactory('RentalityFloridaTaxes')

  const rentalityFloridaTaxes = await upgrades.deployProxy(RentalityFloridaTaxes, [
    await rentalityUserService.getAddress(),
  ])
  const RentalityInsurance = await ethers.getContractFactory('RentalityInsurance')
  const insuranceService = await upgrades.deployProxy(RentalityInsurance, [
    await rentalityUserService.getAddress(),
    await rentalityCarToken.getAddress(),
  ])
  await insuranceService.waitForDeployment()

  const RentalityBaseDiscount = await ethers.getContractFactory('RentalityBaseDiscount')

  const rentalityBaseDiscount = await upgrades.deployProxy(RentalityBaseDiscount, [
    await rentalityUserService.getAddress(),
  ])
  let InvestFactory = await ethers.getContractFactory('RentalityInvestment',{
    libraries: {
      RentalityViewLib: await viewLib.getAddress()
    }
  })
  let investorsService = await upgrades.deployProxy(InvestFactory, [
      await rentalityUserService.getAddress(),
      await rentalityCurrencyConverter.getAddress(),
      await rentalityCarToken.getAddress(),
      await insuranceService.getAddress(),
  ])
  await investorsService.waitForDeployment()

  const rentalityPaymentService = await upgrades.deployProxy(RentalityPaymentService, [
    await rentalityUserService.getAddress(),
    await rentalityFloridaTaxes.getAddress(),
    await rentalityBaseDiscount.getAddress(),
    await investorsService.getAddress()
  ])

  const rentalityTripService = await upgrades.deployProxy(RentalityTripService, [
    await rentalityCurrencyConverter.getAddress(),
    await rentalityCarToken.getAddress(),
    await rentalityPaymentService.getAddress(),
    await rentalityUserService.getAddress(),
    await engineService.getAddress(),
    await rentalityNotificationService.getAddress(),
  ])

  await rentalityTripService.waitForDeployment()
  const RentalityClaimService = await ethers.getContractFactory('RentalityClaimService')
  const claimService = await upgrades.deployProxy(RentalityClaimService, [
    await rentalityUserService.getAddress(),
    await rentalityNotificationService.getAddress(),
  ])
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

  let RentalityTripsView = await ethers.getContractFactory('RentalityTripsView', {
    libraries: {
      RentalityTripsQuery: await tripsQuery.getAddress(),
    },
  })

  const rentalityTripsView = await upgrades.deployProxy(RentalityTripsView, [
    await rentalityCarToken.getAddress(),
    await rentalityCurrencyConverter.getAddress(),
    await rentalityTripService.getAddress(),
    await rentalityUserService.getAddress(),
    await rentalityPaymentService.getAddress(),
    await claimService.getAddress(),
    await deliveryService.getAddress(),
    await insuranceService.getAddress(),
    await promoService.getAddress(),
    await dimoService.getAddress()
  ])
  await rentalityTripsView.waitForDeployment()

  let RentalityView = await ethers.getContractFactory('RentalityView', {
    libraries: {
      RentalityUtils: await utils.getAddress(),
      RentalityQuery: await query.getAddress(),
      RentalityTripsQuery: await tripsQuery.getAddress(),
      RentalityViewLib: await viewLib.getAddress()
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
    await insuranceService.getAddress(),
    await rentalityTripsView.getAddress(),

    await refferalProgram.getAddress(),
    await promoService.getAddress(),
    await dimoService.getAddress()
  ])
  await rentalityView.waitForDeployment()

  const RentalityPlatformHelper = await ethers.getContractFactory('RentalityPlatformHelper', {
    libraries: {
      RentalityUtils: await utils.getAddress()
    },
  })



  const rentalityPlatformHelper = await upgrades.deployProxy(RentalityPlatformHelper, [
    await rentalityCarToken.getAddress(),
    await rentalityCurrencyConverter.getAddress(),
    await rentalityTripService.getAddress(),
    await rentalityUserService.getAddress(),
    await rentalityPaymentService.getAddress(),
    await claimService.getAddress(),
    await deliveryService.getAddress(),
    await rentalityView.getAddress(),
    await insuranceService.getAddress(),
    await refferalProgram.getAddress(),
    await promoService.getAddress(),
    await dimoService.getAddress()
  ])
  await rentalityPlatformHelper.waitForDeployment()

  const rentalityPlatform = await upgrades.deployProxy(RentalityPlatform, [
    await rentalityCarToken.getAddress(),
    await rentalityCurrencyConverter.getAddress(),
    await rentalityTripService.getAddress(),
    await rentalityUserService.getAddress(),
    await rentalityPaymentService.getAddress(),
    await claimService.getAddress(),
    await deliveryService.getAddress(),
    await rentalityView.getAddress(),
    await insuranceService.getAddress(),
    await refferalProgram.getAddress(),
    await promoService.getAddress(),
    await dimoService.getAddress(),
    await rentalityPlatformHelper.getAddress()
  ])

  await rentalityPlatform.waitForDeployment()

  await rentalityUserService.connect(owner).grantHostRole(await rentalityPlatform.getAddress())
  await rentalityUserService.connect(owner).grantManagerRole(await rentalityPlatform.getAddress())
  await rentalityUserService.connect(owner).grantManagerRole(await rentalityCarToken.getAddress())
  await rentalityUserService.connect(owner).grantManagerRole(await rentalityUserService.getAddress())
  await rentalityUserService.connect(owner).grantManagerRole(await rentalityTripService.getAddress())
  await rentalityUserService.connect(owner).grantManagerRole(await rentalityCarToken.getAddress())
  await rentalityUserService.connect(owner).grantManagerRole(await engineService.getAddress())

  const hostSignature = await signTCMessage(host)
  const guestSignature = await signTCMessage(guest)
  const adminKyc = signKycInfo(await rentalityLocationVerifier.getAddress(), admin)
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
    await ethContract.getAddress(),
    await ethContract.getAddress(),
    await rentalityView.getAddress(),
  ])
  await rentalityGateway.waitForDeployment()
  await rentalityPlatform.setTrustedForwarder(await rentalityGateway.getAddress())
  await rentalityView.setTrustedForwarder(await rentalityGateway.getAddress())
  await rentalityTripsView.setTrustedForwarder(await rentalityGateway.getAddress())
  await rentalityPlatformHelper.setTrustedForwarder(await rentalityGateway.getAddress())

  rentalityGateway = await ethers.getContractAt('IRentalityGateway', await rentalityGateway.getAddress())

  await rentalityGateway.connect(host).setKYCInfo(' ', ' ', ' ', ' ',hostSignature, zeroHash)
  await rentalityGateway.connect(guest).setKYCInfo(' ', ' ', ' ', ' ',guestSignature,zeroHash)

  const RentalityAdminGateway = await ethers.getContractFactory('RentalityAdminGateway', {
    libraries: {
      RentalityViewLib: await viewLib.getAddress(),
      RentalityUtils: await utils.getAddress(),
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
    await insuranceService.getAddress(),
    await rentalityTripsView.getAddress(),
    await refferalProgram.getAddress(),
    await promoService.getAddress(),
    await dimoService.getAddress(),
    await investorsService.getAddress()
  ])
  await rentalityAdminGateway.waitForDeployment()
  await rentalityUserService.connect(owner).grantManagerRole(await rentalityView.getAddress())
  await rentalityUserService.connect(owner).grantManagerRole(await rentalityAdminGateway.getAddress())
  await rentalityUserService.connect(owner).grantManagerRole(await rentalityGateway.getAddress())
  await rentalityUserService.connect(owner).grantAdminRole(await rentalityGateway.getAddress())
  await rentalityUserService.connect(owner).grantAdminRole(await rentalityAdminGateway.getAddress())
  await rentalityUserService.connect(owner).grantManagerRole(await rentalityCarToken.getAddress())
  await rentalityUserService.connect(owner).grantManagerRole(await engineService.getAddress())
  await rentalityUserService.connect(owner).grantManagerRole(await rentalityPaymentService.getAddress())
  await rentalityUserService.connect(owner).grantManagerRole(await rentalityTripsView.getAddress())
  return {
    rentalityMockPriceFeed,
    rentalityUserService,
    rentalityTripService,
    rentalityCurrencyConverter,
    rentalityCarToken,
    rentalityPlatform,
    rentalityPaymentService,
    rentalityGateway,
    owner,
    admin,
    manager,
    host,
    guest,
    anonymous,
    rentalityLocationVerifier,
    adminKyc,
    rentalityAdminGateway
  }
}

async function deployFixtureWithUsers() {
  const [owner, admin, manager, host, guest, anonymous, rentalityPlatform] = await ethers.getSigners()
  const RentalityUserService = await ethers.getContractFactory('RentalityUserService')

  const MockCivic = await ethers.getContractFactory('CivicMockVerifier')
  const mockCivic = await MockCivic.deploy()
  await mockCivic.waitForDeployment()

  const rentalityUserService = await upgrades.deployProxy(RentalityUserService, [await mockCivic.getAddress(), 0])

  await rentalityUserService.connect(owner).grantAdminRole(admin.address)
  await rentalityUserService.connect(owner).grantManagerRole(manager.address)
  await rentalityUserService.connect(owner).grantHostRole(host.address)
  await rentalityUserService.connect(owner).grantGuestRole(guest.address)

  return {
    rentalityUserService,
    owner,
    admin,
    manager,
    host,
    guest,
    anonymous,
  }
}

module.exports = {
  deployDefaultFixture,
  deployFixtureWithUsers,
}
