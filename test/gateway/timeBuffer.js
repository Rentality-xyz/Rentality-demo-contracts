const { expect } = require('chai')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')

const { TripStatus, getEmptySearchCarParams, deployDefaultFixture, ethToken, calculatePayments } = require('../utils')

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
    } = await loadFixture(deployDefaultFixture))
  })
  it('should not show car, while time buffer not expired', async function () {
    const oneDayInSec = 86400
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
      locationAddress: 'Miami Riverwalk, Miami, Florida, USA',
      locationLatitude: '123421',
      locationLongitude: '123421',
      geoApiKey: 'key',
    }

    await expect(rentalityGateway.connect(host).addCar(createCarRequest)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const oneDayInSeconds = 86400

    const result = await rentalityPlatform.calculatePayments(1, 2, ethToken)
    await expect(
      await rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds * 2,
          currencyType: ethToken,
        },
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPlatform], [-result.totalPrice, result.totalPrice])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted

    const searchParams = getEmptySearchCarParams()

    const availableCars = await rentalityGateway
      .connect(guest)
      .searchAvailableCars(Date.now() + oneDayInSec * 3, Date.now() + oneDayInSec * 4, searchParams)
    expect(availableCars.length).to.be.eq(0)
  })
  it('should show car after time buffer expiration', async function () {
    const oneDayInSec = 86400
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
      locationAddress: 'Miami Riverwalk, Miami, Florida, USA',
      locationLatitude: '123421',
      locationLongitude: '123421',
      geoApiKey: 'key',
    }

    await expect(rentalityGateway.connect(host).addCar(createCarRequest)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const oneDayInSeconds = 86400

    const dailyPriceInUsdCents = 1000

    const result = await rentalityPlatform.calculatePayments(1, 1, ethToken)
    await expect(
      await rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
        },
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPlatform], [-result.totalPrice, result.totalPrice])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted

    const searchParams = getEmptySearchCarParams()

    const availableCars = await rentalityGateway
      .connect(guest)
      .searchAvailableCars(Date.now() + oneDayInSec * 2 + oneDayInSec / 2, Date.now() + oneDayInSec * 4, searchParams)
    expect(availableCars.length).to.be.eq(1)
  })
  it('should not be able to create tripRequest if trip buffer not expired', async function () {
    const oneDayInSec = 86400

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
      locationAddress: 'Miami Riverwalk, Miami, Florida, USA',
      locationLatitude: '123421',
      locationLongitude: '123421',
      geoApiKey: 'key',
    }

    await expect(rentalityGateway.connect(host).addCar(createCarRequest)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const dailyPriceInUsdCents = 1000

    const result = await rentalityPlatform.calculatePayments(1, 1, ethToken)
    await expect(
      await rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSec,
          currencyType: ethToken,
        },
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPlatform], [-result.totalPrice, result.totalPrice])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: Date.now() + (oneDayInSec * 3) / 2,
          endDateTime: Date.now() + oneDayInSec * 5,
          currencyType: ethToken,
        },
        { value: result.totalPrice }
      )
    ).to.be.revertedWith('Unavailable for current date.')
  })
  it('should reject created trip with time buffer after approve', async function () {
    const oneDayInSeconds = 86400

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
      locationAddress: 'Miami Riverwalk, Miami, Florida, USA',
      locationLatitude: '123421',
      locationLongitude: '123421',

      geoApiKey: 'key',
    }

    await expect(rentalityGateway.connect(host).addCar(createCarRequest)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const dailyPriceInUsdCents = 1000

    const result = await rentalityPlatform.calculatePayments(1, 1, ethToken)
    await expect(
      await rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
        },
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPlatform], [-result.totalPrice, result.totalPrice])

    const resultTwoDays = await rentalityPlatform.calculatePayments(1, 2, ethToken)
    await expect(
      await rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 123 + oneDayInSeconds * 2,
          currencyType: ethToken,
        },
        { value: resultTwoDays.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPlatform], [-resultTwoDays.totalPrice, resultTwoDays.totalPrice])

    await expect(await rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted

    const canceledTrip = await rentalityTripService.getTrip(2)

    expect(canceledTrip.status).to.be.eq(TripStatus.Canceled)
  })
})
