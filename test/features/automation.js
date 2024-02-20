const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { deployDefaultFixture, getMockCarRequest, createMockClaimRequest, ethToken } = require('../utils')
const { expect } = require('chai')
const { ethers, network } = require('hardhat')

describe('RentalityAutomatuin', function () {
  let rentalityGateway,
    rentalityMockPriceFeed,
    rentalityUserService,
    rentalityTripService,
    rentalityCurrencyConverter,
    rentalityCarToken,
    rentalityPaymentService,
    rentalityPlatform,
    claimService,
    rentalityAutomationService,
    rentalityAdminGateway,
    owner,
    admin,
    manager,
    host,
    guest,
    anonymous

  beforeEach(async function () {
    ;({
      rentalityGateway,
      rentalityMockPriceFeed,
      rentalityUserService,
      rentalityTripService,
      rentalityCurrencyConverter,
      rentalityCarToken,
      rentalityPaymentService,
      rentalityPlatform,
      claimService,
      rentalityAutomationService,
      rentalityAdminGateway,
      owner,
      admin,
      manager,
      host,
      guest,
      anonymous,
    } = await loadFixture(deployDefaultFixture))
  })
  it('Has automation after trip creation', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000

    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 1,
          endDateTime: 1,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          fuelPrices: [400],
          currencyType: ethToken,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted

    const automation = await rentalityAutomationService.getAutomation(1, 0)

    expect(automation.tripId).to.be.eq(1)

    const blockNumBefore = await ethers.provider.getBlockNumber()
    const blockBefore = await ethers.provider.getBlock(blockNumBefore)
    const timestampBefore = blockBefore.timestamp
    expect(automation.whenToCallInSec).to.be.approximately(timestampBefore + 1 * 60 * 60, 200)
  })

  it('Automation remove after approve', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 1,
          endDateTime: 1,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted

    const automation = await rentalityAutomationService.getAutomation(1, 0)

    expect(automation.tripId).to.be.eq(0)

    expect(automation.whenToCallInSec).to.be.eq(0)
  })

  it('Automation removed after reject', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 1,
          endDateTime: 1,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted

    await expect(rentalityGateway.connect(host).rejectTripRequest(1)).not.to.be.reverted

    const automation = await rentalityAutomationService.getAutomation(1, 0)

    expect(automation.tripId).to.be.eq(0)

    expect(automation.whenToCallInSec).to.be.eq(0)
  })
  it('Automation сreate after CheckInByHost', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 1,
          endDateTime: 1,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted

    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0])).not.be.reverted
    const automation = await rentalityAutomationService.getAutomation(1, 1)

    expect(automation.tripId).to.be.eq(1)
    expect(automation.aType).to.be.eq(1)
    const blockNumBefore = await ethers.provider.getBlockNumber()
    const blockBefore = await ethers.provider.getBlock(blockNumBefore)
    const timestampBefore = blockBefore.timestamp

    expect(automation.whenToCallInSec).to.be.approximately(timestampBefore + 1 * 60 * 60, 200)
  })
  it('Automation removed after CheckInByGuest', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 1,
          endDateTime: 1,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted

    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0])).not.be.reverted
    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.be.reverted
    const automation = await rentalityAutomationService.getAutomation(1, 1)

    expect(automation.tripId).to.be.eq(0)
    expect(automation.aType).to.be.eq(0)
    expect(automation.whenToCallInSec).to.be.eq(0)
  })

  it('Automation created after CheckInByGuest', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    const blockNumBefore = await ethers.provider.getBlockNumber()
    const blockBefore = await ethers.provider.getBlock(blockNumBefore)
    const timestampBefore = blockBefore.timestamp

    let tomorrow = timestampBefore + 60 * 60 * 24

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 1,
          endDateTime: tomorrow,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted

    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0])).not.be.reverted
    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.be.reverted
    const automation = await rentalityAutomationService.getAutomation(1, 2)

    expect(automation.tripId).to.be.eq(1)
    expect(automation.aType).to.be.eq(2)
    expect(automation.whenToCallInSec).to.be.approximately(tomorrow + 60 * 60, 2000)
  })

  it('Automation removed after CheckOutByGuest', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 1,
          endDateTime: 1,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted

    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0])).not.be.reverted
    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.be.reverted
    await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [0, 0])).not.be.reverted
    const automation = await rentalityAutomationService.getAutomation(1, 2)

    expect(automation.tripId).to.be.eq(0)
    expect(automation.aType).to.be.eq(0)
    expect(automation.whenToCallInSec).to.be.eq(0)
  })
  it('Reject all outdated & not approved trips', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 1,
          endDateTime: 1,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted

    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(1))).not.to.be.reverted

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 2,
          host: host.address,
          startDateTime: 1,
          endDateTime: 1,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted

    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(2))).not.to.be.reverted

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 3,
          host: host.address,
          startDateTime: 1,
          endDateTime: 1,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted

    await expect(rentalityGateway.connect(host).approveTripRequest(3)).to.not.reverted

    /// Time travel for 1 h
    await network.provider.send('evm_increaseTime', [60 * 60 + 1])

    await expect(rentalityGateway.connect(admin).callOutdated()).not.be.reverted

    const trip1 = await rentalityGateway.connect(admin).getTrip(1)
    expect(trip1.status).to.be.eq(7)
    const trip2 = await rentalityGateway.connect(admin).getTrip(2)
    expect(trip2.status).to.be.eq(7)
    const trip3 = await rentalityGateway.connect(admin).getTrip(3)
    expect(trip3.status).to.be.eq(1)
  })

  it('CheckInByGuest all outdated checkedInByHost trips', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 1,
          endDateTime: 1,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted
    await expect(rentalityGateway.connect(host).approveTripRequest(1)).to.not.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0])).to.not.reverted

    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(1))).not.to.be.reverted

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 2,
          host: host.address,
          startDateTime: 1,
          endDateTime: 1,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted
    await expect(rentalityGateway.connect(host).approveTripRequest(2)).to.not.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(2, [0, 0])).to.not.reverted

    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(2))).not.to.be.reverted

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 3,
          host: host.address,
          startDateTime: 1,
          endDateTime: 1,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted
    await expect(rentalityGateway.connect(host).approveTripRequest(3)).to.not.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(3, [0, 0])).to.not.reverted

    /// Time travel for 1 h
    await network.provider.send('evm_increaseTime', [60 * 60 + 1])

    await expect(rentalityGateway.connect(admin).callOutdated()).not.be.reverted

    const trip1 = await rentalityGateway.connect(admin).getTrip(1)
    expect(trip1.status).to.be.eq(3)
    const trip2 = await rentalityGateway.connect(admin).getTrip(2)
    expect(trip2.status).to.be.eq(3)
    const trip3 = await rentalityGateway.connect(admin).getTrip(3)
    expect(trip3.status).to.be.eq(3)
  })
  it('CheckOutByGuest all outdated checkedInByGuest trips', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    const blockNumBefore = await ethers.provider.getBlockNumber()
    const blockBefore = await ethers.provider.getBlock(blockNumBefore)
    const timestampBefore = blockBefore.timestamp

    let tomorrow = timestampBefore + 60 * 60 * 24
    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 1,
          endDateTime: tomorrow,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted
    await expect(rentalityGateway.connect(host).approveTripRequest(1)).to.not.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0])).to.not.reverted
    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).to.not.reverted

    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(1))).not.to.be.reverted

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 2,
          host: host.address,
          startDateTime: 1,
          endDateTime: 1,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted
    await expect(rentalityGateway.connect(host).approveTripRequest(2)).to.not.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(2, [0, 0])).to.not.reverted
    await expect(rentalityGateway.connect(guest).checkInByGuest(2, [0, 0])).to.not.reverted

    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(2))).not.to.be.reverted

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 3,
          host: host.address,
          startDateTime: 1,
          endDateTime: 1,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted
    await expect(rentalityGateway.connect(host).approveTripRequest(3)).to.not.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(3, [0, 0])).to.not.reverted
    await expect(rentalityGateway.connect(guest).checkInByGuest(3, [0, 0])).to.not.reverted

    /// Time travel for 1 h
    await network.provider.send('evm_increaseTime', [tomorrow + 1])

    await expect(rentalityGateway.connect(admin).callOutdated()).not.be.reverted

    const trip1 = await rentalityGateway.connect(admin).getTrip(1)
    expect(trip1.status).to.be.eq(4)
    const trip2 = await rentalityGateway.connect(admin).getTrip(2)
    expect(trip2.status).to.be.eq(4)
    const trip3 = await rentalityGateway.connect(admin).getTrip(3)
    expect(trip3.status).to.be.eq(4)
  })
  it('Mixed Types of Trips - CheckInByGuest and CheckOutByGuest', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 1,
          endDateTime: 1,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).to.not.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0])).to.not.reverted

    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(1))).not.to.be.reverted

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 2,
          host: host.address,
          startDateTime: 1,
          endDateTime: 1,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted

    await expect(rentalityGateway.connect(host).approveTripRequest(2)).to.not.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(2, [0, 0])).to.not.reverted
    await expect(rentalityGateway.connect(guest).checkInByGuest(2, [0, 0])).to.not.reverted

    // Time travel for 1 hour
    await network.provider.send('evm_increaseTime', [60 * 60 + 1])

    await expect(rentalityGateway.connect(admin).callOutdated()).not.be.reverted

    const trip1 = await rentalityGateway.connect(admin).getTrip(1)
    expect(trip1.status).to.be.eq(3)
    const trip2 = await rentalityGateway.connect(admin).getTrip(2)
    expect(trip2.status).to.be.eq(4)
  })
})
