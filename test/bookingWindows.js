const { expect } = require('chai')
const { ethers } = require('hardhat')
const { loadFixture, time } = require('@nomicfoundation/hardhat-network-helpers')

const HOUR = 3600
const DAY = 24 * HOUR

// Every window is measured from the chain's own clock. Fixed numbers would be timestamps in 1970,
// and a booking whose hours are fifty years behind us is one this contract deliberately ignores.
describe('Booking windows', function () {
  async function deployHarnesses() {
    const [host, guest, otherGuest] = await ethers.getSigners()

    const exclusive = await (await ethers.getContractFactory('ExclusiveBookingHarness')).deploy()
    const open = await (await ethers.getContractFactory('OpenBookingHarness')).deploy()
    const travelling = await (await ethers.getContractFactory('TimeTravelBookingHarness')).deploy()

    return {
      exclusive,
      open,
      travelling,
      soon: (await time.latest()) + DAY,
      host: host.address,
      guest: guest.address,
      otherGuest: otherGuest.address,
    }
  }

  it('holds the hours of the booking it took', async function () {
    const { exclusive, soon, host, guest } = await loadFixture(deployHarnesses)

    await exclusive.book(1, host, guest, soon, soon + DAY)

    expect(await exclusive.isWindowFree(1, soon, soon + DAY)).to.equal(false)
    expect(await exclusive.isBookedAt(1, soon + HOUR)).to.equal(true)
    expect(await exclusive.isBookedAt(1, soon + 2 * DAY)).to.equal(false)
  })

  it('refuses a second booking over hours already taken', async function () {
    const { exclusive, soon, host, guest, otherGuest } = await loadFixture(deployHarnesses)

    await exclusive.book(1, host, guest, soon, soon + DAY)

    await expect(exclusive.book(1, host, otherGuest, soon + 7 * HOUR, soon + DAY + 7 * HOUR))
      .to.be.revertedWithCustomError(exclusive, 'BookingWindowTaken')
      .withArgs(1, 1)
  })

  it('allows a booking that starts exactly when another ends', async function () {
    const { exclusive, soon, host, guest, otherGuest } = await loadFixture(deployHarnesses)

    await exclusive.book(1, host, guest, soon, soon + DAY)
    await exclusive.book(1, host, otherGuest, soon + DAY, soon + 2 * DAY)

    expect((await exclusive.getActiveBookings(1)).length).to.equal(2)
  })

  it('leaves other resources alone', async function () {
    const { exclusive, soon, host, guest, otherGuest } = await loadFixture(deployHarnesses)

    await exclusive.book(1, host, guest, soon, soon + DAY)
    await exclusive.book(2, host, otherGuest, soon, soon + DAY)

    expect(await exclusive.isWindowFree(3, soon, soon + DAY)).to.equal(true)
  })

  it('frees the hours once the booking is released', async function () {
    const { exclusive, soon, host, guest, otherGuest } = await loadFixture(deployHarnesses)

    await exclusive.book(1, host, guest, soon, soon + DAY)
    await exclusive.release(1)

    expect(await exclusive.isWindowFree(1, soon, soon + DAY)).to.equal(true)
    await exclusive.book(1, host, otherGuest, soon, soon + DAY)
  })

  it('lets a booking move, but not onto another one', async function () {
    const { exclusive, soon, host, guest, otherGuest } = await loadFixture(deployHarnesses)

    await exclusive.book(1, host, guest, soon, soon + DAY)
    await exclusive.book(1, host, otherGuest, soon + 2 * DAY, soon + 3 * DAY)

    await exclusive.move(1, soon + HOUR, soon + DAY + HOUR)
    expect(await exclusive.isBookedAt(1, soon)).to.equal(false)

    await expect(exclusive.move(1, soon + DAY, soon + 2 * DAY + HOUR))
      .to.be.revertedWithCustomError(exclusive, 'BookingWindowTaken')
      .withArgs(1, 2)
  })

  // Rentality's own trips work this way: several guests may ask for the same car and the same dates,
  // and the host picks one. The base must not take that choice away from a model that wants it.
  it('takes overlapping bookings when a model asks for them', async function () {
    const { open, soon, host, guest, otherGuest } = await loadFixture(deployHarnesses)

    await open.book(1, host, guest, soon, soon + DAY)
    await open.book(1, host, otherGuest, soon + HOUR, soon + DAY + HOUR)

    expect((await open.getActiveBookings(1)).length).to.equal(2)
    expect(await open.isBookedAt(1, soon + 2 * HOUR)).to.equal(true)
  })

  // A booking nobody confirmed or cancelled used to hold its hours for ever, because only
  // cancelling or completing gave them back. Once those hours are behind us the resource is free,
  // whatever state the paperwork was left in.
  it('stops holding hours that have already gone by', async function () {
    const { travelling, soon, host, guest, otherGuest } = await loadFixture(deployHarnesses)

    await travelling.book(1, host, guest, soon, soon + DAY)
    expect(await travelling.isWindowFree(1, soon, soon + DAY)).to.equal(false)

    await time.increaseTo(soon + DAY + 1)

    expect(await travelling.isWindowFree(1, soon, soon + DAY)).to.equal(true)
    // Asked about now, which is what a listing badge asks. Asked about an hour that has passed it
    // would still say true, and rightly: the resource was taken then.
    expect(await travelling.isBookedAt(1, await time.latest())).to.equal(false)
    await travelling.book(1, host, otherGuest, soon, soon + DAY)
  })

  it('still holds hours that have not arrived yet', async function () {
    // This is about windows that ran out, not about requests nobody answered. A hold on next month
    // is a hold, whoever has or has not replied to it.
    const { travelling, host, guest, otherGuest } = await loadFixture(deployHarnesses)
    const later = (await time.latest()) + 30 * DAY

    await travelling.book(1, host, guest, later, later + DAY)
    await time.increase(DAY)

    await expect(travelling.book(1, host, otherGuest, later, later + DAY))
      .to.be.revertedWithCustomError(travelling, 'BookingWindowTaken')
      .withArgs(1, 1)
  })

  it('forgets ended bookings instead of scanning past them for ever', async function () {
    const { travelling, soon, host, guest } = await loadFixture(deployHarnesses)

    await travelling.book(1, host, guest, soon, soon + HOUR)
    await travelling.book(1, host, guest, soon + 2 * HOUR, soon + 3 * HOUR)
    await travelling.book(1, host, guest, soon + 40 * DAY, soon + 41 * DAY)
    expect(await travelling.activeCount(1)).to.equal(3n)

    await time.increaseTo(soon + DAY)
    await travelling.forgetEnded(1)

    // The two that ended are gone; the one still ahead of us stays.
    expect(await travelling.activeCount(1)).to.equal(1n)
    expect(await travelling.isWindowFree(1, soon + 40 * DAY, soon + 41 * DAY)).to.equal(false)
  })

  it('prunes without being asked, when the next booking is made', async function () {
    const { travelling, soon, host, guest } = await loadFixture(deployHarnesses)

    await travelling.book(1, host, guest, soon, soon + HOUR)
    await time.increaseTo(soon + DAY)
    await travelling.book(1, host, guest, soon + 2 * DAY, soon + 3 * DAY)

    // The ended one went out as the new one came in, so the list cannot grow without bound.
    expect(await travelling.activeCount(1)).to.equal(1n)
  })
})

// The production risk this guard exists for: TripMain reads the same list to refuse handing over a
// car that is already out, and a trip due back yesterday but never closed is exactly the one that
// must keep holding its car.
describe('Booking windows, where a model allows overlaps', function () {
  it('leaves its active list alone, ended windows included', async function () {
    const [owner, guest] = await ethers.getSigners()
    const open = await (await ethers.getContractFactory('OpenBookingHarness')).deploy()
    const soon = (await time.latest()) + DAY

    await open.book(1, owner.address, guest.address, soon, soon + HOUR)
    await time.increaseTo(soon + DAY)
    await open.book(1, owner.address, guest.address, soon + 2 * DAY, soon + 3 * DAY)

    expect((await open.getActiveBookings(1)).length).to.equal(2)
  })
})
