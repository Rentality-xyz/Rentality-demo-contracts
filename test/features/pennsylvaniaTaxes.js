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
  signLocationInfo,
  taxesGOVConst,
  encodeTaxes,
  taxesWithoutRentSign,
} = require('../utils')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { ethers } = require('hardhat')

describe('Rentality taxes & discounts', function () {
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
    rentalityLocationVerifier,
    rentalityPennsylvaniaTaxes

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
      rentalityPennsylvaniaTaxes
    } = await loadFixture(deployDefaultFixture))
  })
 

  it('should correctly calculate taxes', async function () {
    await rentalityPaymentService.addTaxes(
      'Massachusetts',
      0,
      [
        {name:"governmentTax",value:1000, tType:0},
      ]
    )

    
    let sumToPayInUsdCents = 19500
    let dayInTrip = 3
    let totalTaxes = (dayInTrip * 1000)

    let totalTax = await rentalityPaymentService.calculateTaxes(3, dayInTrip, sumToPayInUsdCents)

    expect(totalTaxes).to.be.eq(totalTax)
  })
  it('should correctly calculate taxes with gov static', async function () {


    await rentalityPaymentService.addTaxes(
      'Massachusetts',
      0,
      [{name:"salesTax",value:70_000, tType:2},
        {name:"governmentTax",value:1000, tType:1},
      ]
    )
   
    let sumToPayInUsdCents = 19500
    let dayInTrip = 3
    let totalTaxes = ((sumToPayInUsdCents * 7) / 100) + 1000

    let totalTax = await rentalityPaymentService.calculateTaxes(3, dayInTrip, sumToPayInUsdCents)
    expect(Math.ceil(totalTaxes )).to.be.eq(totalTax)
  })
  it('should correctly calculate taxes with gov only', async function () {


    
    let sumToPayInUsdCents = 19500
    let dayInTrip = 3
    let totalTaxes = (sumToPayInUsdCents * 8) / 100 + (dayInTrip * 200)

    let totalTax = await rentalityPaymentService.calculateTaxes(2, dayInTrip, sumToPayInUsdCents)

    expect(totalTaxes).to.be.eq(totalTax)
  })

  it('guest payed correct value with taxes', async function () {

    let location = {
        userAddress: 'Miami Riverwalk, Miami, Florida, USA',
        country: 'USA',
        state: 'Pennsylvania',
        city: 'Miami',
        latitude: '45.509248',
        longitude: '-122.682653',
        timeZoneId: 'id',
      }
      const signedLocation = {
        locationInfo: location,
        signature: await signLocationInfo(await rentalityLocationVerifier.getAddress(), admin, location)
      }
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
        locationInfo: signedLocation,
        currentlyListed: true,
        insuranceRequired: false,
        insurancePriceInUsdCents: 0,
        dimoTokenId: 0,
        signedDimoTokenId: '0x',
      }
    
    await expect(rentalityGateway.connect(host).addCar(addCarRequest)).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    let dayInTrip = 2

    let twoDaysInSec = 172800

    const result = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      dayInTrip,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo,
      ' '
    )

    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + twoDaysInSec,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])
  })

  it('after trip host get correct value', async function () {
    let location = {
        userAddress: 'Miami Riverwalk, Miami, Florida, USA',
        country: 'USA',
        state: 'Pennsylvania',
        city: 'Miami',
        latitude: '45.509248',
        longitude: '-122.682653',
        timeZoneId: 'id',
      }
      const signedLocation = {
        locationInfo: location,
        signature: await signLocationInfo(await rentalityLocationVerifier.getAddress(), admin, location)
      }
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
        locationInfo: signedLocation,
        currentlyListed: true,
        insuranceRequired: false,
        insurancePriceInUsdCents: 0,
        dimoTokenId: 0,
        signedDimoTokenId: '0x',
      }

    
      await expect(rentalityGateway.connect(host).addCar(addCarRequest)).not.to.be.reverted
      const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
     
      expect(myCars.length).to.equal(1)
    const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    let sumToPayInUsdCents = addCarRequest.pricePerDayInUsdCents
    let dayInTrip = 1

    const { rentalityFee, taxes } = await calculatePayments(
      rentalityCurrencyConverter,
      rentalityPaymentService,
      sumToPayInUsdCents,
      dayInTrip,
      addCarRequest.securityDepositPerTripInUsdCents,
      ethToken,
      2
    )

    let oneDayInSec = 86400
    const result = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      1,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo,
      ' '
    )
    const value = result[0]
   
    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSec,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-value, value])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted

    const [deposit, ,] = await rentalityCurrencyConverter.getFromUsdCentsLatest(
      ethToken,
      addCarRequest.securityDepositPerTripInUsdCents
    )

    const returnToHost = value - deposit - rentalityFee - taxes

    await expect(rentalityGateway.connect(host).finishTrip(1)).to.changeEtherBalances(
      [host, rentalityPaymentService],
      [returnToHost, -(result.totalPrice - rentalityFee - taxes)]
    )
  })
})