const { expect } = require('chai')
const {
  deployDefaultFixture,
  getMockCarRequest,
  ethToken,
  calculatePayments,
  getEmptySearchCarParams,
  TripStatus,
  zeroHash,
  emptyLocationInfo,
  emptySignedLocationInfo,
} = require('../utils')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { ethers } = require('hardhat')

describe('Check out without guest', function () {
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

  it('Host can check out without guest', async function () {
    let request = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
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
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          currencyType: ethToken,
          insurancePaid: false,
          photo: '',
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        { value: rentPriceInEth }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-rentPriceInEth, rentPriceInEth])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted
  })

  it('Car is available on search after check out without guest', async function () {
    let request = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
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
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          currencyType: ethToken,
          insurancePaid: false,
          photo: '',
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        { value: rentPriceInEth }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-rentPriceInEth, rentPriceInEth])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted

    const searchParams = getEmptySearchCarParams()
    const resultAr = await rentalityGateway.searchAvailableCarsWithDelivery(
      new Date().getDate(),
      new Date().getDate() + 100,
      searchParams,
      emptyLocationInfo,
      emptyLocationInfo
    )
    const carId = resultAr[0].car.carId

    expect(carId).to.be.eq(1)
  })

  it('Host can not check out and finish trip without confirmation', async function () {
    let request = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
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
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          currencyType: ethToken,
          insurancePaid: false,
          photo: '',
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        { value: rentPriceInEth }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-rentPriceInEth, rentPriceInEth])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.be.reverted
    await expect(rentalityGateway.connect(host).finishTrip(1, zeroHash)).to.be.reverted
  })
  it('Happy case, with guest confirmation', async function () {
    let request = getMockCarRequest(3, await rentalityLocationVerifier.getAddress(), admin)
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
    let oneDayInSeconds = 86400
    let dayInTrip = 31

    const { rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals, rentalityFee, taxes } = await calculatePayments(
      rentalityCurrencyConverter,
      rentalityPaymentService,
      request.pricePerDayInUsdCents,
      dayInTrip,
      request.securityDepositPerTripInUsdCents
    )

    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds * dayInTrip,
          currencyType: ethToken,
          insurancePaid: false,
          photo: '',
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        { value: rentPriceInEth }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-rentPriceInEth, rentPriceInEth])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(host).confirmCheckOut(1, zeroHash)).to.be.reverted

    const depositValue = await rentalityCurrencyConverter.getFromUsd(
      ethToken,
      request.securityDepositPerTripInUsdCents,
      ethToCurrencyRate,
      ethToCurrencyDecimals
    )

    const returnToHost = rentPriceInEth - rentalityFee - taxes - depositValue

    await expect(rentalityGateway.connect(guest).confirmCheckOut(1, zeroHash)).to.changeEtherBalances(
      [host, rentalityPaymentService],
      [returnToHost, -(rentPriceInEth - taxes - rentalityFee)]
    )
    const trip = await rentalityTripService.getTrip(1)

    expect(trip.status).to.be.eq(TripStatus.Finished)
  })
  it('Happy case, with admin confirmation', async function () {
    const request = getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin)
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
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          currencyType: ethToken,
          insurancePaid: false,
          photo: '',
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        { value: rentPriceInEth }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-rentPriceInEth, rentPriceInEth])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted

    const depositValue = await rentalityCurrencyConverter.getFromUsd(
      ethToken,
      request.securityDepositPerTripInUsdCents,
      ethToCurrencyRate,
      ethToCurrencyDecimals
    )

    const returnToHost = rentPriceInEth - rentalityFee - taxes - depositValue

    await expect(rentalityGateway.connect(admin).confirmCheckOut(1, zeroHash)).to.changeEtherBalances(
      [host, rentalityPaymentService],
      [returnToHost, -(rentPriceInEth - taxes - rentalityFee)]
    )
    const trip = await rentalityTripService.getTrip(1)

    expect(trip.status).to.be.eq(TripStatus.Finished)
  })

  it('Admin can reject trip, after check out without guest', async function () {
    let request = getMockCarRequest(2, await rentalityLocationVerifier.getAddress(), admin)
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
    let dayInTrip = 31

    const oneDayInSeconds = 86400

    const { rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals, rentalityFee, taxes } = await calculatePayments(
      rentalityCurrencyConverter,
      rentalityPaymentService,
      request.pricePerDayInUsdCents,
      dayInTrip,
      request.securityDepositPerTripInUsdCents
    )

    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds * dayInTrip,
          currencyType: ethToken,
          insurancePaid: false,
          photo: '',
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        { value: rentPriceInEth }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-rentPriceInEth, rentPriceInEth])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted

    await expect(rentalityGateway.connect(guest).rejectTripRequest(1)).to.be.reverted
    await expect(rentalityGateway.connect(host).rejectTripRequest(1)).to.be.reverted

    await expect(rentalityGateway.connect(admin).rejectTripRequest(1)).to.changeEtherBalances(
      [guest, rentalityPaymentService],
      [rentPriceInEth, -rentPriceInEth]
    )
    const trip = await rentalityTripService.getTrip(1)

    expect(trip.status).to.be.eq(TripStatus.Canceled)
  })
})
