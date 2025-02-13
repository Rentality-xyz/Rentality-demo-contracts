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
  signKycInfo,
  RefferalProgram,
  signTCMessage,
  AdminTripStatus,
  PaymentStatus,
} = require('../utils')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { ethers } = require('hardhat')

async function calculateTripFinish(
  rentalityCurrencyConverter,
  rentalityPaymentService,
  pricePerDayInUsdCents,
  days,
  securityDepositPerTripInUsdCents
) {
  const rentPriceInEth = await rentalityCurrencyConverter.convertUsdToEth(pricePerDayInUsdCents * days)
  const ethToCurrencyRate = await rentalityCurrencyConverter.getEthToCurrencyRate()
  const ethToCurrencyDecimals = await rentalityCurrencyConverter.getEthToCurrencyDecimals()
  const rentalityFee = (pricePerDayInUsdCents * days * 20) / 100
  const taxes = (pricePerDayInUsdCents * days * 7) / 100

  return {
    rentPriceInEth,
    ethToCurrencyRate,
    ethToCurrencyDecimals,
    rentalityFee,
    taxes,
  }
}

async function calculateTripPriceWithCurrencyConversion(
  carPricePerDay,
  daysOfTrip,
  deliveryFee,
  securityDeposit,
  rentalityCurrencyConverter,
  discountPercent = null,
  taxRates = { sales: 0.07, gov: 200 },
  insurancePricePerDay = 0,
  isGuestInsured = false
) {
  let tripCost = Math.floor(carPricePerDay * daysOfTrip)

  tripCost += deliveryFee

  const salesTaxes = Math.floor(tripCost * taxRates.sales)
  const govTaxes = Math.floor(daysOfTrip * taxRates.gov)

  let totalCostBeforeDiscount = tripCost + salesTaxes + govTaxes

  let totalCost

  if (discountPercent !== null) {
    totalCostBeforeDiscount -= Math.floor((totalCostBeforeDiscount * discountPercent) / 100)
    totalCost = totalCostBeforeDiscount + securityDeposit
  } else {
    totalCost = totalCostBeforeDiscount + securityDeposit
  }

  if (!isGuestInsured) {
    totalCost += insurancePricePerDay * daysOfTrip
  }

  const valueSumInCurrency = await rentalityCurrencyConverter.getFromUsdLatest(ethToken, totalCost)

  return {
    tripCost,
    salesTaxes,
    govTaxes,
    totalCost,
    valueInEth: valueSumInCurrency[0],
  }
}

describe('Rentality promoService Service', function () {
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
    rentalityLocationVerifier,
    promoService,
    refferalProgram

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
      promoService,
      refferalProgram,
    } = await loadFixture(deployDefaultFixture))
  })

  it('should give 100 percents discount', async function () {
    const mockCarRequest = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(mockCarRequest)).not.to.be.reverted
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

    await promoService.generateNumbers(1, 10000, 10, 0, (Math.floor(new Date().getTime() / 1000)) + (86400 * 10), 'A')
    const promos = await promoService.getPromoCodes()

    const result = await rentalityGateway
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, promos[0])

    const resultWithoutPromo = await rentalityGateway
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, '')
    expect(result.totalPrice).to.be.not.eq(resultWithoutPromo.totalPrice)


    await expect(
      rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime:Math.floor(new Date().getTime() / 1000),
          endDateTime: Math.floor(new Date().getTime() / 1000) + 86400,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          insurancePaid: false,
          photo: '',
        },
        promos[0],
        { value: resultWithoutPromo.totalPrice }
      )
    ).to.be.reverted

    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime:Math.floor(new Date().getTime() / 1000),
          endDateTime: Math.floor(new Date().getTime() / 1000) + 86400,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          insurancePaid: false,
          photo: '',
        },
        promos[0],
        { value: 0 }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [0, 0])
  })
  it('90 percents promo works fine', async function () {
    const mockCarRequest = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(mockCarRequest)).not.to.be.reverted
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


    await promoService.generateNumbers(1, 10000, 10, Math.floor(new Date().getTime() / 1000), new Date().getTime(), 'A')
    await promoService.generateNumbers(1, 10000, 10, Math.floor(new Date().getTime() / 1000), Math.floor(new Date().getTime() / 1000) + (86400 * 10), 'B')
    const promos = await promoService.getPromoCodes()

    const result = await rentalityGateway
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, promos[promos.length - 1])

    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime:Math.floor(new Date().getTime() / 1000),
          endDateTime: Math.floor(new Date().getTime() / 1000) + 86400,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          insurancePaid: false,
          photo: '',
        },
        promos[promos.length - 1],
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])
  })

  it('should do nothing in case of wrong promo', async function () {
    const mockCarRequest = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(mockCarRequest)).not.to.be.reverted
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


    await promoService.generateNumbers(1, 10000, 10, Math.floor(new Date().getTime() / 1000),Math.floor(new Date().getTime() / 1000) + (86400 * 10), 'A')
    await promoService.generateNumbers(1, 10000, 10, Math.floor(new Date().getTime() / 1000), Math.floor(new Date().getTime() / 1000) + (86400 * 10), 'B')
    const promos = await promoService.getPromoCodes()

    const jsPrice = await calculateTripPriceWithCurrencyConversion(
      mockCarRequest.pricePerDayInUsdCents,
      1,
      0,
      mockCarRequest.securityDepositPerTripInUsdCents,
      rentalityCurrencyConverter,
      0
    )
    const result = await rentalityGateway
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, 'A12312')

    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime:Math.floor(new Date().getTime() / 1000),
          endDateTime: Math.floor(new Date().getTime() / 1000) + 86400,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          insurancePaid: false,
          photo: '',
        },
        'A12312',
        { value: result.totalPrice }
      )
    ).to.not.reverted
  })

  it('general promo works fine', async function () {
    const mockCarRequest = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(mockCarRequest)).not.to.be.reverted
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

    const jsPrice = await calculateTripPriceWithCurrencyConversion(
      mockCarRequest.pricePerDayInUsdCents,
      1,
      0,
      mockCarRequest.securityDepositPerTripInUsdCents,
      rentalityCurrencyConverter,
      20
    )
    const result = await rentalityGateway
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, 'D12345')

    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + 86400,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          insurancePaid: false,
          photo: '',
        },
        'D12345',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])
  })

  it('general promo works fine after reject', async function () {
    const mockCarRequest = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(mockCarRequest)).not.to.be.reverted
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

    const jsPrice = await calculateTripPriceWithCurrencyConversion(
      mockCarRequest.pricePerDayInUsdCents,
      1,
      0,
      mockCarRequest.securityDepositPerTripInUsdCents,
      rentalityCurrencyConverter,
      20
    )

    const generalPromo = await promoService.getGeneralPromoCode()
    const result = await rentalityGateway
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, generalPromo)

      const resultWithoutPromo = await rentalityGateway
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, "")
      expect(result.totalPrice).to.not.eq(resultWithoutPromo.totalPrice)

    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Math.floor(new Date().getTime() / 1000),
          endDateTime: Math.floor(new Date().getTime() / 1000) + 86400,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          insurancePaid: false,
          photo: '',
        },
        generalPromo,
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    await expect(rentalityGateway.connect(guest).rejectTripRequest(1)).to.not.reverted

    
    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Math.floor(new Date().getTime() / 1000),
          endDateTime: Math.floor(new Date().getTime() / 1000) + 86400,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          insurancePaid: false,
          photo: '',
        },
        generalPromo,
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Math.floor(new Date().getTime() / 1000),
          endDateTime: Math.floor(new Date().getTime() / 1000) + 86400,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          insurancePaid: false,
          photo: '',
        },
        generalPromo,
        { value: resultWithoutPromo.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-resultWithoutPromo.totalPrice, resultWithoutPromo.totalPrice])


  })


  it('use general promo twice do nothing', async function () {
    const mockCarRequest = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(mockCarRequest)).not.to.be.reverted
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

    const generalPromo = await promoService.getGeneralPromoCode()
    const result = await rentalityGateway
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, generalPromo)

    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime:Math.floor(new Date().getTime() / 1000),
          endDateTime: Math.floor(new Date().getTime() / 1000) + 86400,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          insurancePaid: false,
          photo: '',
        },
        generalPromo,
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    const resultWithoutPromo = await rentalityGateway
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, '')

    expect(resultWithoutPromo.totalPrice).to.be.not.eq(result.totalPrice)

    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime:Math.floor(new Date().getTime() / 1000),
          endDateTime: Math.floor(new Date().getTime() / 1000) + 86400,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          insurancePaid: false,
          photo: '',
        },
        generalPromo,
        { value: resultWithoutPromo.totalPrice }
      )
    ).to.not.reverted
  })

  it('two user use general code', async function () {
    const mockCarRequest = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(mockCarRequest)).not.to.be.reverted
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

    const result = await rentalityGateway
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, 'D12345')

    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + 86400,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          insurancePaid: false,
          photo: '',
        },
        'D12345',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    await expect(
      await rentalityPlatform.connect(admin).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + 86400,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          insurancePaid: false,
          photo: '',
        },
        'D12345',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([admin, rentalityPaymentService], [-result.totalPrice, result.totalPrice])
  })

  it('use promo twice do nothing', async function () {
    const mockCarRequest = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(mockCarRequest)).not.to.be.reverted
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
 
    await promoService.generateNumbers(1, 10000, 10, Math.floor(new Date().getTime() / 1000), Math.floor(new Date().getTime() / 1000) + (86400 * 10), 'A')
    const promos = await promoService.getPromoCodes()
    const result = await rentalityGateway
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, promos[0])

    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime:Math.floor(new Date().getTime() / 1000),
          endDateTime: Math.floor(new Date().getTime() / 1000) + 86400,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          insurancePaid: false,
          photo: '',
        },
        promos[0],
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    const resultWithoutPromo = await rentalityGateway
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, promos[0])

    expect(resultWithoutPromo.totalPrice).to.be.not.eq(result.totalPrice)

    await expect(
      await rentalityPlatform.connect(admin).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + 86400,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          insurancePaid: false,
          photo: '',
        },
        promos[0],
        { value: resultWithoutPromo.totalPrice }
      )
    ).to.changeEtherBalances(
      [admin, rentalityPaymentService],
      [-resultWithoutPromo.totalPrice, resultWithoutPromo.totalPrice]
    )
  })

  it('reject trip make promo usable', async function () {
    const mockCarRequest = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(mockCarRequest)).not.to.be.reverted
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

    
    await promoService.generateNumbers(1, 10000, 10, Math.floor(new Date().getTime() / 1000), Math.floor(new Date().getTime() / 1000) + (86400 * 10), 'A')
    const promos = await promoService.getPromoCodes()
    const result = await rentalityGateway
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, promos[0])

    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime:Math.floor(new Date().getTime() / 1000),
          endDateTime: Math.floor(new Date().getTime() / 1000) + 86400,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          insurancePaid: false,
          photo: '',
        },
        promos[0],
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    await expect(rentalityPlatform.connect(guest).rejectTripRequest(1)).to.not.be.reverted

    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime:Math.floor(new Date().getTime() / 1000),
          endDateTime: Math.floor(new Date().getTime() / 1000) + 86400,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          insurancePaid: false,
          photo: '',
        },
        promos[0],
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])
  })

  it('Happy case ', async function () {
    const mockCarRequest = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(mockCarRequest)).not.to.be.reverted
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

    const promos = await promoService.getPromoCodes()
    const result = await rentalityGateway
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, 'WAGMI2025')

    const priceWithoutDiscount = await rentalityGateway
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, '')

    const { rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals, rentalityFee, taxes } = await calculatePayments(
      rentalityCurrencyConverter,
      rentalityPaymentService,
      mockCarRequest.pricePerDayInUsdCents,
      1,
      mockCarRequest.securityDepositPerTripInUsdCents
    )

    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime:Math.floor(new Date().getTime() / 1000),
          endDateTime: Math.floor(new Date().getTime() / 1000) + 86400,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          insurancePaid: false,
          photo: '',
        },
       'WAGMI2025',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted

    const trip = await rentalityGateway.getTrip(1)
    const tripDetails = trip['trip']

    const paymentInfo = tripDetails['paymentInfo']

    const depositValue = await rentalityCurrencyConverter.getFromUsd(
      ethToken,
      paymentInfo.depositInUsdCents,
      paymentInfo.currencyRate,
      paymentInfo.currencyDecimals
    )

    const returnToHost = priceWithoutDiscount.totalPrice - depositValue - rentalityFee - taxes

    await owner.sendTransaction({
      to: await rentalityPaymentService.getAddress(),
      value: ethers.parseEther('1.0'),
    })

    await expect(rentalityGateway.connect(host).finishTrip(1)).to.changeEtherBalances(
      [host, rentalityPaymentService],
      [returnToHost, -(rentPriceInEth - rentalityFee - taxes)]
    )
  })

  it('Happy case 100 percents', async function () {
    const mockCarRequest = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(mockCarRequest)).not.to.be.reverted
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

    await promoService.generateNumbers(1, 10000, 10, Math.floor(new Date().getTime() / 1000), Math.floor(new Date().getTime() / 1000) + (86400 * 10), 'A')
    const promos = await promoService.getPromoCodes()
    const result = await rentalityGateway
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, promos[0])

    const priceWithoutDiscount = await rentalityGateway
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, '')

    const { rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals, rentalityFee, taxes } = await calculatePayments(
      rentalityCurrencyConverter,
      rentalityPaymentService,
      mockCarRequest.pricePerDayInUsdCents,
      1,
      mockCarRequest.securityDepositPerTripInUsdCents
    )

    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime:Math.floor(new Date().getTime() / 1000),
          endDateTime: Math.floor(new Date().getTime() / 1000) + 86400,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          insurancePaid: false,
          photo: '',
        },
        promos[0],
        { value: 0}
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted

    const trip = await rentalityGateway.getTrip(1)
    const tripDetails = trip['trip']

    const paymentInfo = tripDetails['paymentInfo']

    const depositValue = await rentalityCurrencyConverter.getFromUsd(
      ethToken,
      paymentInfo.depositInUsdCents,
      paymentInfo.currencyRate,
      paymentInfo.currencyDecimals
    )

    const returnToHost = priceWithoutDiscount.totalPrice - depositValue - rentalityFee - taxes

    await owner.sendTransaction({
      to: await rentalityPaymentService.getAddress(),
      value: ethers.parseEther('1.0'),
    })

    await expect(rentalityGateway.connect(host).finishTrip(1)).to.changeEtherBalances(
      [host, guest],
      [returnToHost, 0]
    )
  })

  it.skip('Set KYC INFO with promo give ref points', async function () {
    const mockCarRequest = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(mockCarRequest)).not.to.be.reverted
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

    await promoService.generateNumbers(1, 10000, 10, 0, 17361747333920 + 86200, 'C')
    await promoService.generateGeneralCode(0, new Date().getTime() + 86400)

    const promos = await promoService.getPromoCodes()
    const promoInBytes32 = ethers.encodeBytes32String(promos[0].toString())

    const ownerSignature = await signTCMessage(owner)
    await rentalityGateway.connect(owner).setKYCInfo('name', 'name', 'name', ownerSignature, promoInBytes32)
    const readyToClaim = await refferalProgram.getReadyToClaim(owner.address)

    const amount = readyToClaim.toClaim.find((obj) => obj.refType === BigInt(RefferalProgram.SetKYC)).points
    expect(amount).to.be.eq(500)

    await expect(refferalProgram.claimPoints(owner.address)).to.not.reverted
    expect(await refferalProgram.addressToPoints(owner.address)).to.be.eq(520)
  })

  it('Promo is not working second time', async function () {
    const mockCarRequest = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(mockCarRequest)).not.to.be.reverted
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


    await promoService.generateNumbers(1, 10000, 10, Math.floor(new Date().getTime() / 1000), new Date().getTime(), 'A')
    await promoService.generateNumbers(1, 10000, 10, Math.floor(new Date().getTime() / 1000), Math.floor(new Date().getTime() / 1000) + (86400 * 10), 'B')
    const promos = await promoService.getPromoCodes()

    const result = await rentalityGateway
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, promos[promos.length - 1])

      const resultWithoutPromo = await rentalityGateway
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo,"")
      expect(result.totalPrice).to.be.not.eq(resultWithoutPromo.totalPrice)
    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime:Math.floor(new Date().getTime() / 1000),
          endDateTime: Math.floor(new Date().getTime() / 1000) + 86400,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          insurancePaid: false,
          photo: '',
        },
        promos[promos.length - 1],
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])


    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime:Math.floor(new Date().getTime() / 1000),
          endDateTime: Math.floor(new Date().getTime() / 1000) + 86400,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          insurancePaid: false,
          photo: '',
        },
        promos[promos.length - 1],
        { value: resultWithoutPromo.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-resultWithoutPromo.totalPrice, resultWithoutPromo.totalPrice])
  })


  it('Trip with promo has promo info', async function () {
    const mockCarRequest = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(mockCarRequest)).not.to.be.reverted
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


    await promoService.generateNumbers(1, 10000, 10, Math.floor(new Date().getTime() / 1000), new Date().getTime(), 'A')
    const promos = await promoService.getPromoCodes()

    const result = await rentalityGateway
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, promos[promos.length - 1])

      const resultWithoutPromo = await rentalityGateway
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo,"")
      expect(result.totalPrice).to.be.not.eq(resultWithoutPromo.totalPrice)
    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime:Math.floor(new Date().getTime() / 1000),
          endDateTime: Math.floor(new Date().getTime() / 1000) + 86400,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          insurancePaid: false,
          photo: '',
        },
        promos[promos.length - 1],
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])


    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime:Math.floor(new Date().getTime() / 1000),
          endDateTime: Math.floor(new Date().getTime() / 1000) + 86400,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          insurancePaid: false,
          photo: '',
        },
        promos[promos.length - 1],
        { value: resultWithoutPromo.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-resultWithoutPromo.totalPrice, resultWithoutPromo.totalPrice])
    const filter = {
      paymentStatus: PaymentStatus.Any,
      status: AdminTripStatus.Any,
      location: emptyLocationInfo,
      startDateTime: 0,
      endDateTime: Math.floor(new Date().getTime() / 1000) + 86400,
    }
    filter.location.city = mockCarRequest.locationInfo.locationInfo.city
    filter.location.state = mockCarRequest.locationInfo.locationInfo.state
    filter.location.country = mockCarRequest.locationInfo.locationInfo.country
    const totalTrips = await rentalityAdminGateway.getAllTrips(filter, 1, 10)
    console.log(await promoService.connect(guest).getUserPromoData())
    console.log(totalTrips[0])
    console.log(totalTrips[1])

  })



})
