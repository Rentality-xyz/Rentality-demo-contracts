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

  it('should correctly calculate taxes', async function () {
    let sumToPayInUsdCents = 19500
    let dayInTrip = 3
    let totalTaxes = (sumToPayInUsdCents * 7) / 100 + dayInTrip * 200

    let [sales, gov] = await rentalityPaymentService.calculateTaxes(1, dayInTrip, sumToPayInUsdCents)

    expect(totalTaxes).to.be.eq(sales + gov)
  })
  it('should correctly calculate discount', async function () {
    let sumToPay = 37800
    let threeDayDiscount = sumToPay * 3 - (sumToPay * 3 * 2) / 100
    let sevenDayDiscount = sumToPay * 7 - (sumToPay * 7 * 10) / 100
    let thirtyDiscount = sumToPay * 31 - (sumToPay * 31 * 15) / 100

    let threeDayCalculatedDiscountPrice = await rentalityPaymentService.calculateSumWithDiscount(
      ethToken /*address(0)*/,
      3,
      sumToPay
    )
    expect(threeDayCalculatedDiscountPrice).to.be.eq(threeDayDiscount)

    let sevenDayCalculatedDiscountPrice = await rentalityPaymentService.calculateSumWithDiscount(
      ethToken /*address(0)*/,
      7,
      sumToPay
    )
    expect(sevenDayCalculatedDiscountPrice).to.be.eq(sevenDayDiscount)

    let thirtyDayCalculatedDiscountPrice = await rentalityPaymentService.calculateSumWithDiscount(
      ethToken /*address(0)*/,
      31,
      sumToPay
    )
    expect(thirtyDayCalculatedDiscountPrice).to.be.eq(thirtyDiscount)
  })
  it('guest payed correct value with taxes, without discount', async function () {
    const request = getMockCarRequest(10, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(request, zeroHash)).not.to.be.reverted
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
      emptyLocationInfo
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
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])
  })

  it('guest payed correct value with taxes and 3 days discount', async function () {
    const request = getMockCarRequest(10, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(request, zeroHash)).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    let dayInTrip = 4

    let fourDaysInSec = 345600
    const result = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      dayInTrip,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo
    )

    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + fourDaysInSec,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])
  })
  it('guest payed correct value with taxes and 7 days discount', async function () {
    const request = getMockCarRequest(10, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(request, zeroHash)).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    let dayInTrip = 8
    let eightDaysInSec = 691200

    const result = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      dayInTrip,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo
    )

    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + eightDaysInSec,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])
  })

  it('guest payed correct value with taxes and 30 days discount', async function () {
    const request = getMockCarRequest(10, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(request, zeroHash)).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    let dayInTrip = 31

    let thirtyOneDayInSec = 86400 * 31

    const result = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      dayInTrip,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo
    )

    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + thirtyOneDayInSec,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])
  })
  it('after trip host get correct value', async function () {
    const request = getMockCarRequest(91, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(request, zeroHash)).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    let sumToPayInUsdCents = request.pricePerDayInUsdCents
    let dayInTrip = 31

    const { rentalityFee, taxes } = await calculatePayments(
      rentalityCurrencyConverter,
      rentalityPaymentService,
      sumToPayInUsdCents,
      dayInTrip,
      request.securityDepositPerTripInUsdCents
    )

    let thirtyOneDayInSec = 86400 * 31
    const result = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      31,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo
    )
    const value = result[0]

    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + thirtyOneDayInSec,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        { value }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-value, value])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [0, 0], zeroHash)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted

    const [deposit, ,] = await rentalityCurrencyConverter.getFromUsdLatest(
      ethToken,
      request.securityDepositPerTripInUsdCents
    )

    const returnToHost = value - deposit - rentalityFee - taxes

    await expect(rentalityGateway.connect(host).finishTrip(1, zeroHash)).to.changeEtherBalances(
      [host, rentalityPaymentService],
      [returnToHost, -(result.totalPrice - rentalityFee - taxes)]
    )
  })

  it('Should return user discount, if it exists', async function () {
    await expect(
      rentalityGateway
        .connect(host)
        .addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin), zeroHash)
    ).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const data = {
      threeDaysDiscount: 100_000,
      sevenDaysDiscount: 200_000,
      thirtyDaysDiscount: 1_000_000,
      initialized: true,
    }

    await expect(await rentalityGateway.connect(owner).addUserDiscount(data)).to.not.reverted

    let first = await rentalityPaymentService.connect(owner).calculateSumWithDiscount(owner.address, 3, 1000)
    expect(first).to.be.eq(1000 * 3 - (1000 * 3 * 10) / 100)
    let second = await rentalityPaymentService.connect(owner).calculateSumWithDiscount(owner.address, 8, 1000)
    expect(second).to.be.eq(1000 * 8 - (1000 * 8 * 20) / 100)
    let last = await rentalityPaymentService.connect(owner).calculateSumWithDiscount(owner.address, 31, 1000)
    expect(last).to.be.eq(0)
  })

  it('Calculate payments should return correct calculation', async function () {
    const request = getMockCarRequest(10, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(request, zeroHash)).not.to.be.reverted

    const tripDays = 7

    const { rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals, rentalityFee } = await calculatePayments(
      rentalityCurrencyConverter,
      rentalityPaymentService,
      request.pricePerDayInUsdCents,
      7,
      request.securityDepositPerTripInUsdCents
    )

    const contractResult = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      tripDays,
      '0x0000000000000000000000000000000000000000',
      emptyLocationInfo,
      emptyLocationInfo
    )
    expect(contractResult.totalPrice).to.be.eq(rentPriceInEth)
  })

  it('Calculate payments: can create trip request with calculated sum', async function () {
    const request = getMockCarRequest(10, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(request, zeroHash)).not.to.be.reverted

    const tripDays = 31
    const oneDayInSeconds = 86400

    const { rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals, rentalityFee } = await calculatePayments(
      rentalityCurrencyConverter,
      rentalityPaymentService,
      request.pricePerDayInUsdCents,
      31,
      request.securityDepositPerTripInUsdCents
    )

    const contractResult = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      tripDays,
      '0x0000000000000000000000000000000000000000',
      emptyLocationInfo,
      emptyLocationInfo
    )
    expect(contractResult.totalPrice).to.be.eq(rentPriceInEth)

    await expect(
      rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          host: host.address,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds * tripDays,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: request.pricePerDayInUsdCents,
          depositInUsdCents: request.securityDepositPerTripInUsdCents,
          currencyRate: contractResult.currencyRate,
          currencyDecimals: contractResult.currencyDecimals,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        { value: contractResult.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-contractResult.totalPrice, contractResult.totalPrice])
  })
})
