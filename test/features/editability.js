const { expect } = require('chai')
const { ethers, upgrades, network } = require('hardhat')
const { time, loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { Contract } = require('hardhat/internal/hardhat-network/stack-traces/model')
const { deployDefaultFixture, getMockCarRequest } = require('../utils')

describe('Ability to update car during trip', function () {
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

  it('should has editable, - false, if car on trip ', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getEthFromUsdLatest(rentPriceInUsdCents)

    const oneDayInMilliseconds = 24 * 60 * 60 * 1000
    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInMilliseconds,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth }
      )
    ).to.changeEtherBalances([guest, rentalityPlatform], [-rentPriceInEth, rentPriceInEth])

    const myNotEditableCars = await rentalityGateway.connect(host).getMyCars()

    expect(myNotEditableCars[0].isEditable).to.be.equal(false)
  })
  it('should not be able to edit car, if it on the trip', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getEthFromUsdLatest(rentPriceInUsdCents)

    const oneDayInMilliseconds = 24 * 60 * 60 * 1000
    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInMilliseconds,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth }
      )
    ).to.changeEtherBalances([guest, rentalityPlatform], [-rentPriceInEth, rentPriceInEth])

    const myNotEditableCars = await rentalityGateway.connect(host).getMyCars()

    expect(myNotEditableCars[0].isEditable).to.be.equal(false)

    let update_params = {
      carId: 1,
      pricePerDayInUsdCents: 2,
      securityDepositPerTripInUsdCents: 2,
      engineParams: [2],
      milesIncludedPerDay: 2,
      timeBufferBetweenTripsInSec: 2,
      currentlyListed: false,
    }

    await expect(rentalityGateway.connect(host).updateCarInfo(update_params)).to.be.revertedWith(
      'Car is not available for update.'
    )
  })

  it('should be again editable after cancellation', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getEthFromUsdLatest(rentPriceInUsdCents)

    const oneDayInMilliseconds = 24 * 60 * 60 * 1000
    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInMilliseconds,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth }
      )
    ).to.changeEtherBalances([guest, rentalityPlatform], [-rentPriceInEth, rentPriceInEth])

    const myNotEditableCars = await rentalityGateway.connect(host).getMyCars()

    expect(myNotEditableCars[0].isEditable).to.be.equal(false)

    await rentalityGateway.connect(guest).rejectTripRequest(1)

    const myNotEditableCars2 = await rentalityGateway.connect(host).getMyCars()

    expect(myNotEditableCars2[0].isEditable).to.be.equal(true)
  })
})
