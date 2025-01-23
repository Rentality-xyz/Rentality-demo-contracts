const { expect } = require('chai')
const {
  deployDefaultFixture,
  ethToken,
  locationInfo,
  getEmptySearchCarParams,
  signTCMessage,
  signLocationInfo,
  zeroHash,
  emptyLocationInfo,
} = require('../utils')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { ethers } = require('hardhat')

describe('Rentality Delivery', function () {
  let rentalityGateway,
    rentalityMockPriceFeed,
    rentalityUserService,
    rentalityTripService,
    rentalityCurrencyConverter,
    rentalityCarToken,
    rentalityPaymentService,
    rentalityPlatform,
    engineService,
    rentalityAutomationService,
    deliveryService,
    elEngine,
    pEngine,
    hEngine,
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
      engineService,
      rentalityAutomationService,
      deliveryService,
      elEngine,
      pEngine,
      hEngine,
      owner,
      admin,
      manager,
      host,
      guest,
      anonymous,
      rentalityLocationVerifier,
    } = await loadFixture(deployDefaultFixture))
  })

  it('should correctly calculate distance', async function () {
    let resultLong = await deliveryService.calculateDistance('25.820121', '-80.120817', '33.829662', '-84.363986')
    expect(resultLong).to.be.approximately(600, 10, 'Huge distance, 592 calculated by CHAT GPT')

    let resultSmall = await deliveryService.calculateDistance('25.820121', '-80.120817', '25.771325', '-80.185969')

    expect(resultSmall).to.be.approximately(4, 1, 'Small distance, 3.47 calculated by CHAT GPT')

    let resultMedium = await deliveryService.calculateDistance('25.623529', '-80.343476', '25.797641', '-80.202987')

    expect(resultMedium).to.be.approximately(16, 3, 'Medium distance, 16.87 calculated by CHAT GPT')
  }),
    it('should correctly calculate price in usd cents with return to another address, above 25', async function () {
      let homeLat = '25.820121'
      let homeLon = '-80.120817'
      let pickUpLat = '33.829662'
      let pickUpLon = '-84.363986'

      let locationInfo = {
        latitude: pickUpLat,
        longitude: pickUpLon,
        userAddress: 'Miami Riverwalk, Miami, Florida, USA',
        country: 'USA',
        state: 'Florida',
        city: 'Miami',

        timeZoneId: 'id',
      }

      let locationInfo2 = {
        latitude: pickUpLat,
        longitude: pickUpLon,
        userAddress: 'Miami Riverwalk, Miami, Florida, USA',
        country: 'USA',
        state: 'Florida',
        city: 'Miami',

        timeZoneId: 'id',
      }
      let result = await deliveryService.calculatePriceByDeliveryDataInUsdCents(
        locationInfo,
        locationInfo2,
        homeLat,
        homeLon,
        host
      )

      let expectedResult = 608 /*miles*/ * 250 /*price in usd cents*/ * 2
      expect(result).to.be.eq(expectedResult)
    })
  it('should correctly calculate price in usd cents with return to home, under 25', async function () {
    let homeLat = '25.623529'
    let homeLon = '-80.343476'
    let pickUpLat = '25.797641'
    let pickUpLon = '-80.202987'

    let locationInfo = {
      latitude: pickUpLat,
      longitude: pickUpLon,
      userAddress: 'Miami Riverwalk, Miami, Florida, USA',
      country: 'USA',
      state: 'Florida',
      city: 'Miami',

      timeZoneId: 'id',
    }
    let locationInfo2 = {
      latitude: homeLat,
      longitude: homeLon,
      userAddress: 'Miami Riverwalk, Miami, Florida, USA',
      country: 'USA',
      state: 'Florida',
      city: 'Miami',

      timeZoneId: 'id',
    }
    let result = await deliveryService.calculatePriceByDeliveryDataInUsdCents(
      locationInfo,
      locationInfo2,
      homeLat,
      homeLon,
      host
    )

    let expectedResult = 14 /*miles*/ * 300 /*price in usd cents*/
    expect(result).to.be.eq(expectedResult, 'Return price should be 0, because it has same address as home')
  })
  it('should correctly calculate price with user data', async function () {
    let homeLat = '25.623529'
    let homeLon = '-80.343476'
    let pickUpLat = '25.797641'
    let pickUpLon = '-80.202987'
    let locationInfo = {
      latitude: pickUpLat,
      longitude: pickUpLon,
      userAddress: 'Miami Riverwalk, Miami, Florida, USA',
      country: 'USA',
      state: 'Florida',
      city: 'Miami',

      timeZoneId: 'id',
    }
    let locationInfo2 = {
      latitude: homeLat,
      longitude: homeLon,
      userAddress: 'Miami Riverwalk, Miami, Florida, USA',
      country: 'USA',
      state: 'Florida',
      city: 'Miami',

      timeZoneId: 'id',
    }

    await rentalityGateway.connect(host).addUserDeliveryPrices(500, 500)
    let result = await deliveryService
      .connect(host)
      .calculatePriceByDeliveryDataInUsdCents(locationInfo, locationInfo2, homeLat, homeLon, host)

    let expectedResult = 14 /*miles*/ * 500 /*price in usd cents*/
    expect(result).to.be.eq(expectedResult, 'Return price should be 0, because it has same address as home')
  })
  it('Happy case with delivery', async function () {
    let homeLat = '25.623529'
    let homeLon = '-80.343476'
    let pickUpLat = '25.797641'
    let pickUpLon = '-80.202987'

    let locationInfo = {
      latitude: pickUpLat,
      longitude: pickUpLon,
      userAddress: 'Miami Riverwalk, Miami, Florida, USA',
      country: 'USA',
      state: 'Florida',
      city: 'Miami',

      timeZoneId: 'id',
    }

    let locationInfo1 = {
      locationInfo,
      signature: signLocationInfo(await rentalityLocationVerifier.getAddress(), admin, locationInfo),
    }
    const mockCreateCarRequest = {
      tokenUri: 'uri',
      carVinNumber: 'VIN_NUMBER',
      brand: 'BRAND',
      model: 'MODEL',
      yearOfProduction: 2020,
      pricePerDayInUsdCents: 1000,
      securityDepositPerTripInUsdCents: 0,
      engineParams: [10],
      engineType: 2,
      milesIncludedPerDay: 1000000,
      timeBufferBetweenTripsInSec: 0,
      geoApiKey: 'key',
      locationInfo: locationInfo1,
      currentlyListed: true,
      insuranceRequired: false,
      insurancePriceInUsdCents: 0,
      dimoTokenId: 0,
      insuranceIncluded: true,
    }

    await expect(rentalityGateway.connect(host).addCar(mockCreateCarRequest)).not.to.be.reverted
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

    let locationInfo2 = {
      latitude: homeLat,
      longitude: homeLon,
      userAddress: 'Miami Riverwalk, Miami, Florida, USA',
      country: 'USA',
      state: 'Florida',
      city: 'Miami',

      timeZoneId: 'id',
    }
    let result = await rentalityGateway.calculatePaymentsWithDelivery(1, 1, ethToken, locationInfo, locationInfo2, '')
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          useRefferalDiscount: false,
          pickUpInfo: {
            signature: signLocationInfo(await rentalityLocationVerifier.getAddress(), admin, locationInfo),
            locationInfo,
          },
          returnInfo: {
            signature: signLocationInfo(await rentalityLocationVerifier.getAddress(), admin, locationInfo2),
            locationInfo: locationInfo2,
          },
        },
        ' ',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(host).finishTrip(1)).to.not.reverted

    let totalDeliveryPrice = await deliveryService
      .connect(host)
      .calculatePriceByDeliveryDataInUsdCents(locationInfo, locationInfo2, homeLat, homeLon, host)

    let trip = await rentalityTripService.getTrip(1)
    let fee = (mockCreateCarRequest.pricePerDayInUsdCents * 20) / 100
    expect(trip.transactionInfo.tripEarnings).to.be.eq(
      BigInt(mockCreateCarRequest.pricePerDayInUsdCents - fee) +
        (totalDeliveryPrice - (totalDeliveryPrice * BigInt(20)) / BigInt(100))
    )
  })
  it('should sort cars', async function () {
    let homeLat = '25.623529'
    let homeLon = '-80.343476'
    let pickUpLat = '25.797641'
    let pickUpLon = '-80.202987'

    let signature = await signTCMessage(owner)
    let locationInfo = {
      locationInfo: {
        latitude: homeLat,
        longitude: homeLon,
        userAddress: 'Miami Riverwalk, Miami, Florida, USA',
        country: 'USA',
        state: 'Florida',
        city: 'Miami',

        timeZoneId: 'id',
      },
    }
    locationInfo.signature = signLocationInfo(
      await rentalityLocationVerifier.getAddress(),
      admin,
      locationInfo.locationInfo
    )
    let locationInfo1 = {
      locationInfo: {
        latitude: '33.829662',
        longitude: '-84.363986',
        userAddress: 'Miami Riverwalk, Miami, Florida, USA',
        country: 'USA',
        state: 'Florida',
        city: 'Miami',

        timeZoneId: 'id',
      },
    }
    ;(locationInfo1.signature = signLocationInfo(
      await rentalityLocationVerifier.getAddress(),
      admin,
      locationInfo1.locationInfo
    )),
      (locationInfo2 = {
        locationInfo: {
          latitude: '25.771325',
          longitude: '-80.185969',
          userAddress: 'Miami Riverwalk, Miami, Florida, USA',
          country: 'USA',
          state: 'Florida',
          city: 'Miami',

          timeZoneId: 'id',
        },
      })
    locationInfo2.signature = signLocationInfo(
      await rentalityLocationVerifier.getAddress(),
      admin,
      locationInfo2.locationInfo
    )
    const mockCreateCarRequest = {
      tokenUri: 'uri',
      carVinNumber: 'VIN_NфвUMBER',
      brand: 'BRAND',
      model: 'MODEL',
      yearOfProduction: 2020,
      pricePerDayInUsdCents: 1000,
      securityDepositPerTripInUsdCents: 0,
      engineParams: [10],
      engineType: 2,
      milesIncludedPerDay: 1000000,
      timeBufferBetweenTripsInSec: 0,
      geoApiKey: 'key',
      locationInfo,
      insuranceIncluded: true,
      currentlyListed: true,
      insuranceRequired: false,
      insurancePriceInUsdCents: 0,
dimoTokenId: 0
    }
    await expect(rentalityGateway.connect(host).addCar(mockCreateCarRequest)).not.to.be.reverted

    const mockCreateCarRequest1 = {
      tokenUri: 'uri',
      carVinNumber: 'VIN_NUdadMBER',
      brand: 'BRAND',
      model: 'MODEL',
      yearOfProduction: 2020,
      pricePerDayInUsdCents: 1000,
      securityDepositPerTripInUsdCents: 0,
      engineParams: [10],
      engineType: 2,
      milesIncludedPerDay: 1000000,
      timeBufferBetweenTripsInSec: 0,
      geoApiKey: 'key',
      locationInfo: locationInfo1,
      insuranceIncluded: true,
      currentlyListed: true,
      insuranceRequired: false,
      insurancePriceInUsdCents: 0,
dimoTokenId: 0
    }
    await expect(rentalityGateway.connect(host).addCar(mockCreateCarRequest1)).not.to.be.reverted

    const mockCreateCarRequest2 = {
      tokenUri: 'uri',
      carVinNumber: 'VIN_NUadadaMBER',
      brand: 'BRAND',
      model: 'MODEL',
      yearOfProduction: 2020,
      pricePerDayInUsdCents: 1000,
      securityDepositPerTripInUsdCents: 0,
      engineParams: [10],
      engineType: 2,
      milesIncludedPerDay: 1000000,
      timeBufferBetweenTripsInSec: 0,
      geoApiKey: 'key',
      locationInfo: locationInfo2,
      insuranceIncluded: true,
      currentlyListed: true,
      insuranceRequired: false,
      insurancePriceInUsdCents: 0,
dimoTokenId: 0
    }
    await expect(rentalityGateway.connect(host).addCar(mockCreateCarRequest2)).not.to.be.reverted
    let loc = {
      latitude: pickUpLat,
      longitude: pickUpLon,
      userAddress: 'Miami Riverwalk, Miami, Florida, USA',
      country: 'USA',
      state: 'Florida',
      city: 'Miami',

      timeZoneId: 'id',
    }
    const mockCreateCarRequest5 = {
      tokenUri: 'uri',
      carVinNumber: 'VIN_NUadaadsdaMBER',
      brand: 'BRAND',
      model: 'MODEL',
      yearOfProduction: 2020,
      pricePerDayInUsdCents: 1000,
      securityDepositPerTripInUsdCents: 0,
      engineParams: [10],
      engineType: 2,
      milesIncludedPerDay: 1000000,
      timeBufferBetweenTripsInSec: 0,
      geoApiKey: 'key',
      locationInfo: locationInfo1,
      insuranceIncluded: true,
      currentlyListed: true,
      insuranceRequired: false,
      insurancePriceInUsdCents: 0,
dimoTokenId: 0
    }
    const mockCreateCarRequest3 = {
      tokenUri: 'uri',
      carVinNumber: 'VIN_NUadaadasdaMBER',
      brand: 'BRAND',
      model: 'MODEL',
      yearOfProduction: 2020,
      pricePerDayInUsdCents: 1000,
      securityDepositPerTripInUsdCents: 0,
      engineParams: [10],
      engineType: 2,
      milesIncludedPerDay: 1000000,
      timeBufferBetweenTripsInSec: 0,
      geoApiKey: 'key',
      locationInfo: locationInfo,
      insuranceIncluded: true,
      currentlyListed: true,
      insuranceRequired: false,
      insurancePriceInUsdCents: 0,
dimoTokenId: 0
    }
    const mockCreateCarRequest4 = {
      tokenUri: 'uri',
      carVinNumber: 'VIN_NUada132daMBER',
      brand: 'BRAND',
      model: 'MODEL',
      yearOfProduction: 2020,
      pricePerDayInUsdCents: 1000,
      securityDepositPerTripInUsdCents: 0,
      engineParams: [10],
      engineType: 2,
      milesIncludedPerDay: 1000000,
      timeBufferBetweenTripsInSec: 0,
      geoApiKey: 'key',
      locationInfo: locationInfo2,
      insuranceIncluded: true,
      currentlyListed: true,
      insuranceRequired: false,
      insurancePriceInUsdCents: 0,
dimoTokenId: 0
    }
    await expect(rentalityGateway.connect(host).addCar(mockCreateCarRequest4)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).addCar(mockCreateCarRequest5)).not.to.be.reverted

    await expect(rentalityGateway.connect(host).addCar(mockCreateCarRequest3)).not.to.be.reverted

    let emptySearchParams = { ...getEmptySearchCarParams(), userLocation: loc }
    let result = await rentalityGateway.searchAvailableCarsWithDelivery(0, 1, emptySearchParams, loc, loc)
  })
})
