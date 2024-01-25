const { ethers, upgrades } = require('hardhat')
const { getMockCarRequest } = require('../utils')
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

  const AutomationService = await ethers.getContractFactory('RentalityAutomation')
  const rentalityAutomationService = await upgrades.deployProxy(AutomationService, [
    await rentalityUserService.getAddress(),
  ])
  await rentalityAutomationService.waitForDeployment()

  const RentalityTripService = await ethers.getContractFactory('RentalityTripService', {
    libraries: { RentalityUtils: await utils.getAddress() },
  })

  const rentalityTripService = await upgrades.deployProxy(RentalityTripService, [
    await rentalityCurrencyConverter.getAddress(),
    await rentalityCarToken.getAddress(),
    await rentalityPaymentService.getAddress(),
    await rentalityUserService.getAddress(),
    await engineService.getAddress(),
    await rentalityAutomationService.getAddress(),
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
module.exports = {
  deployDefaultFixture,
  deployFixtureWith1Car,
  deployFixtureWith2UserService,
}
