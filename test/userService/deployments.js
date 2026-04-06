const { ethers, upgrades } = require('hardhat')
const { deployDefaultFixture } = require('../utils')

async function deployFixtureWithUsers() {
  const [owner, admin, manager, host, guest, anonymous] = await ethers.getSigners()
  const RentalityUserService = await ethers.getContractFactory('RentalityUserService')

  const MockCivic = await ethers.getContractFactory('CivicMockVerifier')
  const mockCivic = await MockCivic.deploy()
  await mockCivic.waitForDeployment()

  const rentalityUserService = await upgrades.deployProxy(RentalityUserService, [await mockCivic.getAddress(), 0])
  await rentalityUserService.grantPlatformRole(owner.address)
  await rentalityUserService.grantPlatformRole(admin.address)

  await rentalityUserService.connect(owner).grantAdminRole(admin.address)
  await rentalityUserService.connect(owner).grantPlatformRole(manager.address)
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
