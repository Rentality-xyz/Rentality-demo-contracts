const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { expect } = require('chai')
const { deployDefaultFixture, deployFixtureWithUsers } = require('./deployments')

describe('RentalityUserService: deployment', function () {
  it('Owner should have all roles', async function () {
    const { rentalityUserService, owner } = await loadFixture(deployDefaultFixture)

    expect(await rentalityUserService.isAdmin(owner.address)).to.equal(true)
    expect(await rentalityUserService.isManager(owner.address)).to.equal(true)
    expect(await rentalityUserService.isHost(owner.address)).to.equal(true)
    expect(await rentalityUserService.isGuest(owner.address)).to.equal(true)
  })

  it('deployFixtureWithUsers: users should have correct roles', async function () {
    const { rentalityUserService, admin, manager, host, guest } = await loadFixture(deployFixtureWithUsers)

    expect(await rentalityUserService.isAdmin(admin.address)).to.equal(true)
    expect(await rentalityUserService.isManager(manager.address)).to.equal(true)
    expect(await rentalityUserService.isHost(host.address)).to.equal(true)
    expect(await rentalityUserService.isGuest(guest.address)).to.equal(true)
  })
})
