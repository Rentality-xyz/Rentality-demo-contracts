const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { expect } = require('chai')
const { deployFixtureWithUsers } = require('./deployments')

describe('RentalityUserService: role management', function () {
  it('Admin should have Manager role', async function () {
    const { rentalityUserService, admin } = await loadFixture(deployFixtureWithUsers)

    expect(await rentalityUserService.isAdmin(admin.address)).to.equal(true)
    expect(await rentalityUserService.isManager(admin.address)).to.equal(true)
    expect(await rentalityUserService.isHost(admin.address)).to.equal(false)
    expect(await rentalityUserService.isGuest(admin.address)).to.equal(false)
  })

  it("Anonymous shouldn't get any role", async function () {
    const { rentalityUserService, anonymous } = await loadFixture(deployFixtureWithUsers)

    expect(await rentalityUserService.isAdmin(anonymous.address)).to.equal(false)
    expect(await rentalityUserService.isManager(anonymous.address)).to.equal(false)
    expect(await rentalityUserService.isHost(anonymous.address)).to.equal(false)
    expect(await rentalityUserService.isGuest(anonymous.address)).to.equal(false)
  })

  it('Only Admin can grandAdminRole', async function () {
    const { rentalityUserService, admin, manager, host, guest, anonymous } = await loadFixture(deployFixtureWithUsers)

    await expect(rentalityUserService.connect(admin).grantAdminRole(admin.address)).not.to.be.reverted
    await expect(rentalityUserService.connect(manager).grantAdminRole(admin.address)).to.be.reverted
    await expect(rentalityUserService.connect(host).grantAdminRole(admin.address)).to.be.reverted
    await expect(rentalityUserService.connect(guest).grantAdminRole(admin.address)).to.be.reverted
    await expect(rentalityUserService.connect(anonymous).grantAdminRole(admin.address)).to.be.reverted
  })

  it('Only Admin can revokeAdminRole', async function () {
    const { rentalityUserService, owner, admin, manager, host, guest, anonymous } =
      await loadFixture(deployFixtureWithUsers)

    await expect(rentalityUserService.connect(anonymous).revokeAdminRole(owner.address)).to.be.reverted
    await expect(rentalityUserService.connect(guest).revokeAdminRole(owner.address)).to.be.reverted
    await expect(rentalityUserService.connect(host).revokeAdminRole(owner.address)).to.be.reverted
    await expect(rentalityUserService.connect(manager).revokeAdminRole(owner.address)).to.be.reverted
    await expect(rentalityUserService.connect(admin).revokeAdminRole(owner.address)).not.to.be.reverted
  })

  it('Only Admin can grantManagerRole', async function () {
    const { rentalityUserService, admin, manager, host, guest, anonymous } = await loadFixture(deployFixtureWithUsers)

    await expect(rentalityUserService.connect(admin).grantManagerRole(manager.address)).not.to.be.reverted
    await expect(rentalityUserService.connect(manager).grantManagerRole(manager.address)).to.be.reverted
    await expect(rentalityUserService.connect(host).grantManagerRole(manager.address)).to.be.reverted
    await expect(rentalityUserService.connect(guest).grantManagerRole(manager.address)).to.be.reverted
    await expect(rentalityUserService.connect(anonymous).grantManagerRole(manager.address)).to.be.reverted
  })

  it('Only Admin can revokeManagerRole', async function () {
    const { rentalityUserService, admin, manager, host, guest, anonymous } = await loadFixture(deployFixtureWithUsers)

    await expect(rentalityUserService.connect(anonymous).revokeManagerRole(manager.address)).to.be.reverted
    await expect(rentalityUserService.connect(anonymous).revokeManagerRole(manager.address)).to.be.reverted
    await expect(rentalityUserService.connect(anonymous).revokeManagerRole(manager.address)).to.be.reverted
    await expect(rentalityUserService.connect(manager).revokeManagerRole(manager.address)).to.be.reverted
    await expect(rentalityUserService.connect(admin).revokeManagerRole(manager.address)).not.to.be.reverted
  })

  it('Only Admin and Manager can grantHostRole', async function () {
    const { rentalityUserService, admin, manager, host, guest, anonymous } = await loadFixture(deployFixtureWithUsers)

    await expect(rentalityUserService.connect(admin).grantHostRole(host.address)).not.to.be.reverted
    await expect(rentalityUserService.connect(manager).grantHostRole(host.address)).not.to.be.reverted
    await expect(rentalityUserService.connect(anonymous).grantHostRole(host.address)).to.be.reverted
    await expect(rentalityUserService.connect(anonymous).grantHostRole(host.address)).to.be.reverted
    await expect(rentalityUserService.connect(anonymous).grantHostRole(host.address)).to.be.reverted
  })

  it('Only Admin and Manager can revokeHostRole', async function () {
    const { rentalityUserService, admin, manager, host, guest, anonymous } = await loadFixture(deployFixtureWithUsers)

    await expect(rentalityUserService.connect(anonymous).revokeHostRole(host.address)).to.be.reverted
    await expect(rentalityUserService.connect(anonymous).revokeHostRole(host.address)).to.be.reverted
    await expect(rentalityUserService.connect(anonymous).revokeHostRole(host.address)).to.be.reverted
    await expect(rentalityUserService.connect(manager).revokeHostRole(host.address)).not.to.be.reverted
    await expect(rentalityUserService.connect(admin).revokeHostRole(host.address)).not.to.be.reverted
  })

  it('Only Admin and Manager can grantGuestRole', async function () {
    const { rentalityUserService, admin, manager, host, guest, anonymous } = await loadFixture(deployFixtureWithUsers)

    await expect(rentalityUserService.connect(admin).grantGuestRole(guest.address)).not.to.be.reverted
    await expect(rentalityUserService.connect(manager).grantGuestRole(guest.address)).not.to.be.reverted
    // await expect(rentalityUserService.connect(host).grantGuestRole(guest.address)).to.be.reverted
    // await expect(rentalityUserService.connect(guest).grantGuestRole(guest.address)).to.be.reverted
    // await expect(rentalityUserService.connect(anonymous).grantGuestRole(guest.address)).to.be.reverted
  })

  it('Only Admin and Manager can revokeGuestRole', async function () {
    const { rentalityUserService, admin, manager, host, guest, anonymous } = await loadFixture(deployFixtureWithUsers)

    await expect(rentalityUserService.connect(anonymous).revokeGuestRole(guest.address)).to.be.reverted
    await expect(rentalityUserService.connect(anonymous).revokeGuestRole(guest.address)).to.be.reverted
    await expect(rentalityUserService.connect(anonymous).revokeGuestRole(guest.address)).to.be.reverted
    await expect(rentalityUserService.connect(manager).revokeGuestRole(guest.address)).not.to.be.reverted
    await expect(rentalityUserService.connect(admin).revokeGuestRole(guest.address)).not.to.be.reverted
  })
})
