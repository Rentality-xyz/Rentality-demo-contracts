const { ethers, upgrades } = require('hardhat')

// We define a fixture to reuse the same setup in every test.
// We use loadFixture to run this setup once, snapshot that state,
// and reset Hardhat Network to that snapshot in every test.
async function deployDefaultFixture() {
  const [owner, admin, manager, host, guest, anonymous] = await ethers.getSigners()

  const RentalityUtils = await ethers.getContractFactory('RentalityUtils')
  const utils = await RentalityUtils.deploy()

  await utils.waitForDeployment()

  const RentalityMockPriceFeed = await ethers.getContractFactory('RentalityMockPriceFeed')
  const RentalityUserService = await ethers.getContractFactory('RentalityUserService')
  const RentalityTripService = await ethers.getContractFactory('RentalityTripService')
  // , {
  // libraries: {RentalityUtils: await utils.getAddress()},
  // })
  const RentalityCurrencyConverter = await ethers.getContractFactory('RentalityCurrencyConverter')
  const RentalityPaymentService = await ethers.getContractFactory('RentalityPaymentService')
  const RentalityGeoService = await ethers.getContractFactory('RentalityGeoMock')

  const RentalityCarToken = await ethers.getContractFactory('RentalityCarToken')
  const RentalityPlatform = await ethers.getContractFactory('RentalityPlatform', {
    libraries: {
      RentalityUtils: await utils.getAddress(),
    },
  })

  let rentalityMockPriceFeed = await RentalityMockPriceFeed.deploy(8, 200000000000)
  await rentalityMockPriceFeed.waitForDeployment()

  const rentalityUserService = await upgrades.deployProxy(RentalityUserService)
  await rentalityUserService.waitForDeployment()

  const electricEngine = await ethers.getContractFactory('RentalityElectricEngine')
  const elEngine = await electricEngine.deploy(await rentalityUserService.getAddress())
  await elEngine.waitForDeployment()

  const patrolEngine = await ethers.getContractFactory('RentalityPatrolEngine')
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

  const rentalityCurrencyConverter = await upgrades.deployProxy(RentalityCurrencyConverter, [
    await rentalityMockPriceFeed.getAddress(),
    await rentalityUserService.getAddress(),
  ])

  const rentalityGeoService = await RentalityGeoService.deploy()
  await rentalityGeoService.waitForDeployment()

  const rentalityCarToken = await upgrades.deployProxy(
    RentalityCarToken,
    [await rentalityGeoService.getAddress(), await engineService.getAddress()],
    { kind: 'uups' }
  )

  await rentalityCarToken.waitForDeployment()

  const rentalityPaymentService = await upgrades.deployProxy(RentalityPaymentService, [
    await rentalityUserService.getAddress(),
  ])

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

  await rentalityUserService.connect(owner).grantHostRole(await rentalityPlatform.getAddress())
  await rentalityUserService.connect(owner).grantManagerRole(await rentalityPlatform.getAddress())
  await rentalityUserService.connect(owner).grantManagerRole(await rentalityTripService.getAddress())
  await rentalityUserService.connect(owner).grantManagerRole(await rentalityCarToken.getAddress())
  await rentalityUserService.connect(owner).grantManagerRole(await engineService.getAddress())

  return {
    rentalityMockPriceFeed,
    rentalityUserService,
    rentalityTripService,
    rentalityCurrencyConverter,
    rentalityCarToken,
    rentalityPlatform,
    owner,
    admin,
    manager,
    host,
    guest,
    anonymous,
  }
}

async function deployFixtureWithUsers() {
  const [owner, admin, manager, host, guest, anonymous] = await ethers.getSigners()
  const RentalityUserService = await ethers.getContractFactory('RentalityUserService')

  const rentalityUserService = await upgrades.deployProxy(RentalityUserService)
  await rentalityUserService.waitForDeployment()

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