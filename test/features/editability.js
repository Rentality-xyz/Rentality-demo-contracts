const { expect } = require('chai')
const { deployDefaultFixture, getMockCarRequest, ethToken, calculatePayments } = require('../utils')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')

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
    anonymous,
    rentalityLocationVerifier

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
      rentalityLocationVerifier,
    } = await loadFixture(deployDefaultFixture))
  })

  it('should has editable: false, if car on the trip', async function () {
    await expect(
      rentalityPlatform.connect(host).addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).not.to.be.reverted
    const myCars = await rentalityView.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityView.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)
    let dailyPriceInUsdCents = 1000

    const result = await  rentalityView.calculatePayments(1, 1, ethToken)
    await expect(
      await rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + 85600,
          currencyType: ethToken,
        },
        { value: result.totalPrice }
      )
    ).not.to.be.reverted

    const myNotEditableCars = await rentalityView.connect(host).getMyCars()

    expect(myNotEditableCars[0].isEditable).to.be.equal(false)
  })
  it('should not be able to edit car, if it on the trip', async function () {
    await expect(
      rentalityPlatform.connect(host).addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).not.to.be.reverted
    const myCars = await rentalityView.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityView.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)
    let dailyPriceInUsdCents = 1000

    const result = await  rentalityView.calculatePayments(1, 1, ethToken)
    await expect(
      await rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + 84700,
          currencyType: ethToken,
        },
        { value: result.totalPrice }
      )
    ).not.to.be.reverted

    const myNotEditableCars = await rentalityView.connect(host).getMyCars()

    expect(myNotEditableCars[0].isEditable).to.be.equal(false)

    let update_params = {
      carId: 1,
      pricePerDayInUsdCents: 2,
      securityDepositPerTripInUsdCents: 2,
      engineParams: [2],
      milesIncludedPerDay: 2,
      timeBufferBetweenTripsInSec: 2,
      currentlyListed: false,
      insuranceIncluded: true,
    }

    await expect(rentalityPlatform.connect(host).updateCarInfo(update_params)).to.be.revertedWith(
      'Car is not available for update.'
    )
  })

  it('should be again editable after cancellation', async function () {
    await expect(
      rentalityPlatform.connect(host).addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).not.to.be.reverted
    const myCars = await rentalityView.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityView.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000

    const result = await  rentalityView.calculatePayments(1, 1, ethToken)
    await expect(
      await rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + 84500,
          currencyType: ethToken,
        },
        { value: result.totalPrice }
      )
    ).not.to.be.reverted

    const myNotEditableCars = await rentalityView.connect(host).getMyCars()

    expect(myNotEditableCars[0].isEditable).to.be.equal(false)

    await rentalityGateway.connect(guest).rejectTripRequest(1)

    const myNotEditableCars2 = await rentalityView.connect(host).getMyCars()

    expect(myNotEditableCars2[0].isEditable).to.be.equal(true)
  })
})
