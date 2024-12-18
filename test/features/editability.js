const { expect } = require('chai')
const {
  deployDefaultFixture,
  getMockCarRequest,
  ethToken,
  getEmptySearchCarParams,
  calculatePayments,
  emptyLocationInfo,
  zeroHash,
  signLocationInfo,
  emptySignedLocationInfo
} = require('../utils')
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
      rentalityGateway
        .connect(host)
        .addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin), zeroHash)
    ).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsWithDelivery(
        0,
        new Date().getSeconds() + 86400,
        getEmptySearchCarParams(1),
        emptyLocationInfo,
        emptyLocationInfo
      )
    expect(availableCars.length).to.equal(1)
    let dailyPriceInUsdCents = 1000

    const result = await rentalityGateway
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo)
    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + 85600,
          currencyType: ethToken,
          insurancePaid: false,
          photo: '',
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        { value: result.totalPrice }
      )
    ).not.to.be.reverted

    const myNotEditableCars = await rentalityGateway.connect(host).getMyCars()

    expect(myNotEditableCars[0].isEditable).to.be.equal(false)
  })
  it('should not be able to edit car, if it on the trip', async function () {
    await expect(
      rentalityGateway
        .connect(host)
        .addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin), zeroHash)
    ).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsWithDelivery(
        0,
        new Date().getSeconds() + 86400,
        getEmptySearchCarParams(1),
        emptyLocationInfo,
        emptyLocationInfo
      )
    expect(availableCars.length).to.equal(1)
    let dailyPriceInUsdCents = 1000

    const result = await rentalityGateway
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo)
    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + 84700,
          currencyType: ethToken,
          insurancePaid: false,
          photo: '',
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        { value: result.totalPrice }
      )
    ).not.to.be.reverted

    const myNotEditableCars = await rentalityGateway.connect(host).getMyCars()

    expect(myNotEditableCars[0].isEditable).to.be.equal(false)

    let update_params = {
      carId: 1,
      pricePerDayInUsdCents: 2,
      securityDepositPerTripInUsdCents: 2,
      engineParams: [2, 2],
      milesIncludedPerDay: 2,
      timeBufferBetweenTripsInSec: 2,
      currentlyListed: false,
      insuranceIncluded: true,
      engineType: 1,
      tokenUri: 'uri',
      insuranceRequired: false,
      insurancePriceInUsdCents: 0,
    }

    let locationInfo = {
      locationInfo: emptyLocationInfo,
      signature: signLocationInfo(await rentalityLocationVerifier.getAddress(), admin, emptyLocationInfo),
    }
    await expect(
      rentalityGateway.connect(host).updateCarInfoWithLocation(update_params, locationInfo)
    ).to.be.revertedWith('Car is not available for update.')
  })

  it('should be again editable after cancellation', async function () {
    await expect(
      rentalityGateway
        .connect(host)
        .addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin), zeroHash)
    ).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsWithDelivery(
        0,
        new Date().getSeconds() + 86400,
        getEmptySearchCarParams(1),
        emptyLocationInfo,
        emptyLocationInfo
      )
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000

    const result = await rentalityGateway
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo)
    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + 84500,
          currencyType: ethToken,
          insurancePaid: false,
          photo: '',
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        { value: result.totalPrice }
      )
    ).not.to.be.reverted

    const myNotEditableCars = await rentalityGateway.connect(host).getMyCars()

    expect(myNotEditableCars[0].isEditable).to.be.equal(false)

    await rentalityGateway.connect(guest).rejectTripRequest(1)

    const myNotEditableCars2 = await rentalityGateway.connect(host).getMyCars()

    expect(myNotEditableCars2[0].isEditable).to.be.equal(true)
  })
})
