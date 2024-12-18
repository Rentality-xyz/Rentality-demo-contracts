const { expect } = require('chai')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')

const {
  TripStatus,
  getEmptySearchCarParams,
  deployDefaultFixture,
  ethToken,
  calculatePayments,
  locationInfo,
  signTCMessage,
  signLocationInfo,
  emptyLocationInfo,
  zeroHash,
  emptySignedLocationInfo,
} = require('../utils')

describe('RentalityGateway: time buffer', function () {
  let rentalityGateway,
    rentalityMockPriceFeed,
    rentalityUserService,
    rentalityTripService,
    rentalityCurrencyConverter,
    rentalityCarToken,
    rentalityPaymentService,
    rentalityPlatform,
    rentalityGeoService,
    rentalityAdminGateway,
    utils,
    claimService,
    owner,
    admin,
    manager,
    host,
    guest,
    anonymous,
    rentalityLocationVerifier,
      rentalityView,
    tripsQuery

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
      rentalityGeoService,
      rentalityAdminGateway,
      utils,
      claimService,
      owner,
      admin,
      manager,
      host,
      guest,
      anonymous,
      rentalityLocationVerifier,
      rentalityView,
      tripsQuery
    } = await loadFixture(deployDefaultFixture))
  })
  it('should not show car, while time buffer not expired', async function () {
    const oneDayInSec = 86400
    let locationInfo1 = {
      locationInfo,
      signature: signLocationInfo(await rentalityLocationVerifier.getAddress(), admin),
      zeroHash,
    }
    const createCarRequest = {
      tokenUri: 'uri',
      carVinNumber: 'VIN_NUMBER',
      brand: 'BRAND',
      model: 'MODEL',
      yearOfProduction: 2020,
      pricePerDayInUsdCents: 1,
      securityDepositPerTripInUsdCents: 1,
      engineParams: [1, 2],
      engineType: 1,
      milesIncludedPerDay: 10,
      timeBufferBetweenTripsInSec: oneDayInSec * 2,
      geoApiKey: 'key',
      insuranceIncluded: true,
      locationInfo: locationInfo1,
      currentlyListed: true,
      insuranceRequired: false,
      insurancePriceInUsdCents: 0,
    }

    await expect(rentalityGateway.connect(host).addCar(createCarRequest, zeroHash)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const oneDayInSeconds = 86400

    const result = await rentalityGateway
      .connect(host)
      .calculatePaymentsWithDelivery(1, 2, ethToken, emptyLocationInfo, emptyLocationInfo)
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds * 2,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted

    const searchParams = getEmptySearchCarParams()

    const value = await rentalityCarToken.fetchAvailableCarsForUser(guest.address,getEmptySearchCarParams())
    // let rentalityContract = {
    //   carService: await rentalityCarToken.getAddress(),
    //   currencyConverterService: await rentalityCurrencyConverter.getAddress(),
    //   tripService: await rentalityTripService.getAddress(),
    //   userService: await rentalityUserService.getAddress(),
    //   rentalityPlatform: await rentalityPlatform.getAddress(),
    //   paymentService: await rentalityPaymentService.getAddress(),
    //   claimService: await claimService.getAddress(),
    //   adminService: await rentalityAdminGateway.getAddress(),
    //   deliveryService: await rentalityCarDelivery.getAddress(),
    //   viewService: await rentalityView.getAddress()
    // };



    const availableCars = await rentalityView
      .connect(guest)
      .searchAvailableCarsWithDelivery(
        Date.now() + oneDayInSec * 3,
        Date.now() + oneDayInSec * 4,
        searchParams,
        emptyLocationInfo,
        emptyLocationInfo
      )
    expect(availableCars.length).to.be.eq(0)
  })
  it('should show car after time buffer expiration', async function () {
    const oneDayInSec = 86400
    let locationInfo1 = {
      locationInfo,
      signature: signLocationInfo(await rentalityLocationVerifier.getAddress(), admin),
      zeroHash,
    }
    const createCarRequest = {
      tokenUri: 'uri',
      carVinNumber: 'VIN_NUMBER',
      brand: 'BRAND',
      model: 'MODEL',
      yearOfProduction: 2020,
      pricePerDayInUsdCents: 1,
      securityDepositPerTripInUsdCents: 1,
      engineParams: [1, 2],
      engineType: 1,
      milesIncludedPerDay: 10,
      timeBufferBetweenTripsInSec: oneDayInSec,

      geoApiKey: 'key',
      insuranceIncluded: true,
      locationInfo: locationInfo1,
      currentlyListed: true,
      insuranceRequired: false,
      insurancePriceInUsdCents: 0,
    }

    await expect(rentalityGateway.connect(host).addCar(createCarRequest,zeroHash)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const oneDayInSeconds = 86400

    const dailyPriceInUsdCents = 1000

    const result = await rentalityGateway
      .connect(host)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo)
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted

    const searchParams = getEmptySearchCarParams()

    const availableCars = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsWithDelivery(
        Date.now() + oneDayInSec * 2 + oneDayInSec / 2,
        Date.now() + oneDayInSec * 4,
        searchParams,
        emptyLocationInfo,
        emptyLocationInfo
      )
    expect(availableCars.length).to.be.eq(1)
  })
  it('should not be able to create tripRequest if trip buffer not expired', async function () {
    const oneDayInSec = 86400
    let locationInfo1 = {
      locationInfo,
      signature: signLocationInfo(await rentalityLocationVerifier.getAddress(), admin),
    }
    const createCarRequest = {
      tokenUri: 'uri',
      carVinNumber: 'VIN_NUMBER',
      brand: 'BRAND',
      model: 'MODEL',
      yearOfProduction: 2020,
      pricePerDayInUsdCents: 1,
      securityDepositPerTripInUsdCents: 1,
      engineParams: [1, 2],
      engineType: 1,
      milesIncludedPerDay: 10,
      timeBufferBetweenTripsInSec: oneDayInSec,
      insuranceIncluded: true,
      locationInfo: locationInfo1,
      geoApiKey: 'aasda',
      currentlyListed: true,
      insuranceRequired: false,
      insurancePriceInUsdCents: 0,
    }

    await expect(rentalityGateway.connect(host).addCar(createCarRequest, zeroHash)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const dailyPriceInUsdCents = 1000

    const result = await rentalityGateway
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo)
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSec,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted

    await expect(
      rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now() + (oneDayInSec * 3) / 2,
          endDateTime: Date.now() + oneDayInSec * 5,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        { value: result.totalPrice }
      )
    ).to.be.revertedWith('Unavailable for current date.')
  })
  it('should reject created trip with time buffer after approve', async function () {
    const oneDayInSeconds = 86400
    let locationInfo1 = {
      locationInfo,
      signature: signLocationInfo(await rentalityLocationVerifier.getAddress(), admin),
    }
    const createCarRequest = {
      tokenUri: 'uri',
      carVinNumber: 'VIN_NUMBER',
      brand: 'BRAND',
      model: 'MODEL',
      yearOfProduction: 2020,
      pricePerDayInUsdCents: 1,
      securityDepositPerTripInUsdCents: 1,
      engineParams: [1, 2],
      engineType: 1,
      milesIncludedPerDay: 10,
      timeBufferBetweenTripsInSec: oneDayInSeconds,

      geoApiKey: 'key',
      insuranceIncluded: true,
      locationInfo: locationInfo1,
      currentlyListed: true,
      insuranceRequired: false,
      insurancePriceInUsdCents: 0,
    }

    await expect(rentalityGateway.connect(host).addCar(createCarRequest, zeroHash)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const dailyPriceInUsdCents = 1000

    const result = await rentalityGateway
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo)
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    const resultTwoDays = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      2,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo
    )
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 123 + oneDayInSeconds * 2,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        { value: resultTwoDays.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-resultTwoDays.totalPrice, resultTwoDays.totalPrice])

    await expect(await rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted

    const canceledTrip = await rentalityTripService.getTrip(2)

    expect(canceledTrip.status).to.be.eq(TripStatus.Canceled)
  })
})
