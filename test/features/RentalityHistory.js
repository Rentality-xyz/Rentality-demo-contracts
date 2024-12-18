const { expect } = require('chai')

const {
  getMockCarRequest,
  TripStatus,
  deployDefaultFixture,
  ethToken,
  calculatePayments,
  emptyLocationInfo,
  getEmptySearchCarParams,
  zeroHash,
  emptySignedLocationInfo,
} = require('../utils')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')

describe('Rentality History Service', function () {
  let rentalityPlatform,
    rentalityGateway,
    transactionHistory,
    rentalityCurrencyConverter,
    rentalityAdminGateway,
    rentalityPaymentService,
    owner,
    admin,
    manager,
    host,
    guest,
    anonymous,
    rentalityLocationVerifier

  beforeEach(async function () {
    ;({
      rentalityPlatform,
      rentalityGateway,
      rentalityCurrencyConverter,
      rentalityAdminGateway,
      rentalityPaymentService,
      owner,
      admin,
      manager,
      host,
      guest,
      anonymous,
      rentalityLocationVerifier,
    } = await loadFixture(deployDefaultFixture))
  })

  it('should create history in case of cancellation', async function () {
    await expect(
      rentalityGateway
        .connect(host)
        .addCar(getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin), zeroHash)
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

    const oneDayInSeconds = 86400

    const result = await rentalityGateway
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo)
    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          insurancePaid: false,
          photo: ''

        },
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    await expect(rentalityGateway.connect(host).rejectTripRequest(1)).to.not.reverted
    const details = (await rentalityGateway.getTrip(1)).trip

    const currentTimeMillis = Date.now()
    const currentTimeSeconds = Math.floor(currentTimeMillis / 1000)

    expect(details.transactionInfo.depositRefund).to.not.be.eq(0)
    expect(details.transactionInfo.dateTime).to.be.approximately(currentTimeSeconds, 2000)
    expect(details.transactionInfo.tripEarnings).to.be.eq(0)
    expect(details.transactionInfo.statusBeforeCancellation).to.be.eq(TripStatus.Created)
  })
  it('Happy case has history', async function () {
    const request = getMockCarRequest(55, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(request, zeroHash)).not.to.be.reverted
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

    const oneDayInSeconds = 86400

    const { rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals, rentalityFee, taxes } = await calculatePayments(
      rentalityCurrencyConverter,
      rentalityPaymentService,
      request.pricePerDayInUsdCents,
      1,
      request.securityDepositPerTripInUsdCents
    )
    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          insurancePaid: false,
          photo: '',
        },
        { value: rentPriceInEth }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-rentPriceInEth, rentPriceInEth])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [0, 0], zeroHash)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted

    const trip = await rentalityGateway.getTrip(1)
    const tripDetails = trip['trip']

    const paymentInfo = tripDetails['paymentInfo']

    const depositValue = await rentalityCurrencyConverter.getFromUsd(
      ethToken,
      paymentInfo.depositInUsdCents,
      ethToCurrencyRate,
      ethToCurrencyDecimals
    )

    const returnToHost = rentPriceInEth - depositValue - rentalityFee - taxes

    await expect(rentalityGateway.connect(host).finishTrip(1, zeroHash)).to.changeEtherBalances(
      [host, rentalityPaymentService],
      [returnToHost, -(returnToHost + depositValue)]
    )
    const details = (await rentalityGateway.getTrip(1)).trip

    const currentTimeMillis = Date.now()
    const currentTimeSeconds = Math.floor(currentTimeMillis / 1000)

    expect(details.transactionInfo.depositRefund).to.be.eq(request.securityDepositPerTripInUsdCents)
    expect(details.transactionInfo.dateTime).to.be.approximately(currentTimeSeconds, 2000)
    expect(details.transactionInfo.tripEarnings).to.be.approximately(
      Math.floor(request.pricePerDayInUsdCents - (request.pricePerDayInUsdCents * 20) / 100 /* platform fee*/),
      1
    )
    expect(details.transactionInfo.rentalityFee).to.be.approximately(
      Math.floor((request.pricePerDayInUsdCents * 20) / 100),
      1
    )
    expect(details.transactionInfo.statusBeforeCancellation).to.be.eq(TripStatus.Finished)
  })
  // unused method
  it.skip('Should have receipt after trip end', async function () {
    const request = getMockCarRequest(51, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(request)).not.to.be.reverted
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

    let sumToPayInUsdCents = request.pricePerDayInUsdCents
    let dayInTrip = 7
    let sumToPayWithDiscount = sumToPayInUsdCents * dayInTrip - (sumToPayInUsdCents * dayInTrip * 10) / 100

    let totalTaxes = (sumToPayWithDiscount * 7) / 100 + dayInTrip * 200

    let sevenDays = 86400 * 7

    const payments = await rentalityGateway.calculatePayments(1, 7, ethToken)
    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + sevenDays,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          insurancePaid: false,
        },
        { value: payments.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-payments.totalPrice, payments.totalPrice])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [100, 15], '', '')).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [100, 15])).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [50, 200])).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [50, 200])).not.to.be.reverted

    await expect(rentalityGateway.connect(host).finishTrip(1, false, zeroHash)).to.not.reverted

    let result = await rentalityGateway.getTripReceipt(1)
    expect(result.totalDayPriceInUsdCents).to.be.eq(sumToPayInUsdCents * dayInTrip)
    expect(result.totalTripDays).to.be.eq(7)
    expect(result.discountAmount).to.be.approximately(
      BigInt(Math.floor(sumToPayInUsdCents * 7 - sumToPayWithDiscount)),
      1
    )

    expect(result.salesTax + result.governmentTax).to.be.eq(BigInt(Math.floor(totalTaxes)))
    expect(result.depositReceived).to.be.eq(BigInt(request.securityDepositPerTripInUsdCents))
    expect(result.startFuelLevel).to.be.eq(BigInt(100))
    expect(result.endFuelLevel).to.be.eq(BigInt(50))
    expect(result.startOdometer).to.be.eq(BigInt(15))
    expect(result.endOdometer).to.be.eq(BigInt(200))
  })
})
