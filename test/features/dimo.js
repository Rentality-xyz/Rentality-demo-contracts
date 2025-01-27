const { getEmptySearchCarParams, signDimoToken } = require("../utils")

const { expect } = require('chai')
const {
  deployDefaultFixture,
  getMockCarRequest,
  ethToken,
  calculatePayments,
  calculatePaymentsFrom,
  zeroHash,
  emptyLocationInfo,
  emptySignedLocationInfo,
} = require('../utils')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { ethers } = require('hardhat')

describe('Rentality dimo', function () {
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

it('should be able to save dimo token with signature only', async function () {

    const dimoSign = await signDimoToken(owner,17)

    let addCarRequest = {
      tokenUri: 'uri',
      carVinNumber: 'VIN_NUMBER',
      brand: 'BRAND',
      model: 'MODEL',
      yearOfProduction: 2020,
      pricePerDayInUsdCents: 1000,
      securityDepositPerTripInUsdCents: 1,
      engineParams: [1, 2],
      engineType: 1,
      milesIncludedPerDay: 10,
      timeBufferBetweenTripsInSec: 0,
      geoApiKey: 'key',
      insuranceIncluded: true,
      locationInfo: emptySignedLocationInfo,
      currentlyListed: true,
      insuranceRequired: false,
      insurancePriceInUsdCents: 0,
dimoTokenId: 17,
signedDimoTokenId: dimoSign
    }
    const oneDayInSec = 86400
    const totalTripDays = 7
    const searchParams = getEmptySearchCarParams()
    await expect(rentalityGateway.connect(host).addCar(addCarRequest)).not.be.reverted


    let addCarRequest2 = {
      tokenUri: 'uri',
      carVinNumber: 'VIN_NUMBER2',
      brand: 'BRAND',
      model: 'MODEL',
      yearOfProduction: 2020,
      pricePerDayInUsdCents: 1000,
      securityDepositPerTripInUsdCents: 1,
      engineParams: [1, 2],
      engineType: 1,
      milesIncludedPerDay: 10,
      timeBufferBetweenTripsInSec: 0,
      geoApiKey: 'key',
      insuranceIncluded: true,
      locationInfo: emptySignedLocationInfo,
      currentlyListed: true,
      insuranceRequired: false,
      insurancePriceInUsdCents: 0,
dimoTokenId: 7,
signedDimoTokenId: dimoSign
    }
    await expect(rentalityGateway.connect(host).addCar(addCarRequest2)).to.be.revertedWith('dimo: wrong signature')

    const resultAr = await rentalityGateway.searchAvailableCarsWithDelivery(
      new Date().getDate(),
      new Date().getDate() + oneDayInSec * totalTripDays,
      searchParams,
      emptyLocationInfo,
      emptyLocationInfo
    )
})
})