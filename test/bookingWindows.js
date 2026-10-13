const { expect } = require('chai')
const { ethers } = require('hardhat')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')

const HOUR = 3600
const DAY = 24 * HOUR

describe('Booking windows', function () {
  async function deployHarnesses() {
    const [host, guest, otherGuest] = await ethers.getSigners()

    const exclusive = await (await ethers.getContractFactory('ExclusiveBookingHarness')).deploy()
    const open = await (await ethers.getContractFactory('OpenBookingHarness')).deploy()

    return { exclusive, open, host: host.address, guest: guest.address, otherGuest: otherGuest.address }
  }

  it('holds the hours of the booking it took', async function () {
    const { exclusive, host, guest } = await loadFixture(deployHarnesses)

    await exclusive.book(1, host, guest, DAY, 2 * DAY)

    expect(await exclusive.isWindowFree(1, DAY, 2 * DAY)).to.equal(false)
    expect(await exclusive.isBookedAt(1, DAY + HOUR)).to.equal(true)
    expect(await exclusive.isBookedAt(1, 3 * DAY)).to.equal(false)
  })

  it('refuses a second booking over hours already taken', async function () {
    const { exclusive, host, guest, otherGuest } = await loadFixture(deployHarnesses)

    await exclusive.book(1, host, guest, DAY, 2 * DAY)

    await expect(exclusive.book(1, host, otherGuest, DAY + 7 * HOUR, 2 * DAY + 7 * HOUR))
      .to.be.revertedWithCustomError(exclusive, 'BookingWindowTaken')
      .withArgs(1, 1)
  })

  it('allows a booking that starts exactly when another ends', async function () {
    const { exclusive, host, guest, otherGuest } = await loadFixture(deployHarnesses)

    await exclusive.book(1, host, guest, DAY, 2 * DAY)
    await exclusive.book(1, host, otherGuest, 2 * DAY, 3 * DAY)

    expect((await exclusive.getActiveBookings(1)).length).to.equal(2)
  })

  it('leaves other resources alone', async function () {
    const { exclusive, host, guest, otherGuest } = await loadFixture(deployHarnesses)

    await exclusive.book(1, host, guest, DAY, 2 * DAY)
    await exclusive.book(2, host, otherGuest, DAY, 2 * DAY)

    expect(await exclusive.isWindowFree(3, DAY, 2 * DAY)).to.equal(true)
  })

  it('frees the hours once the booking is released', async function () {
    const { exclusive, host, guest, otherGuest } = await loadFixture(deployHarnesses)

    await exclusive.book(1, host, guest, DAY, 2 * DAY)
    await exclusive.release(1)

    expect(await exclusive.isWindowFree(1, DAY, 2 * DAY)).to.equal(true)
    await exclusive.book(1, host, otherGuest, DAY, 2 * DAY)
  })

  it('lets a booking move, but not onto another one', async function () {
    const { exclusive, host, guest, otherGuest } = await loadFixture(deployHarnesses)

    await exclusive.book(1, host, guest, DAY, 2 * DAY)
    await exclusive.book(1, host, otherGuest, 3 * DAY, 4 * DAY)

    await exclusive.move(1, DAY + HOUR, 2 * DAY + HOUR)
    expect(await exclusive.isBookedAt(1, DAY)).to.equal(false)

    await expect(exclusive.move(1, 2 * DAY, 3 * DAY + HOUR))
      .to.be.revertedWithCustomError(exclusive, 'BookingWindowTaken')
      .withArgs(1, 2)
  })

  // Rentality's own trips work this way: several guests may ask for the same car and the same dates,
  // and the host picks one. The base must not take that choice away from a model that wants it.
  it('takes overlapping bookings when a model asks for them', async function () {
    const { open, host, guest, otherGuest } = await loadFixture(deployHarnesses)

    await open.book(1, host, guest, DAY, 2 * DAY)
    await open.book(1, host, otherGuest, DAY + HOUR, 2 * DAY + HOUR)

    expect((await open.getActiveBookings(1)).length).to.equal(2)
    expect(await open.isBookedAt(1, DAY + 2 * HOUR)).to.equal(true)
  })
})
