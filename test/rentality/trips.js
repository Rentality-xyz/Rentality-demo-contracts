const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { expect } = require('chai')
const {
  getMockCarRequest,
  getEmptySearchCarParams,
  ethToken,
  calculatePayments,
  emptyLocationInfo,
  emptySignedLocationInfo,
  zeroHash,
} = require('../utils')
const { deployDefaultFixture } = require('./deployments')

describe('Rentality: trips', function () {
  it('createTripRequest', async function () {
    const { rentalityCarToken, rentalityGateway, rentalityPlatform, host, guest, rentalityLocationVerifier, admin } =
      await loadFixture(deployDefaultFixture)

    await expect(
      rentalityGateway
        .connect(host)
        .addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
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

    const result = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      1,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo,
      ' '
    )
    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).not.to.be.reverted
  })

  it('host can reject created trip', async function () {
    const {
      rentalityPlatform,
      rentalityGateway,
      rentalityCarToken,
      host,
      guest,
      rentalityPaymentService,
      rentalityLocationVerifier,
      admin,
    } = await loadFixture(deployDefaultFixture)

    await expect(
      rentalityGateway
        .connect(host)
        .addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
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
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, ' ')
    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    await expect(rentalityPlatform.connect(host).rejectTripRequest(1)).to.changeEtherBalances(
      [guest, rentalityPaymentService],
      [result.totalPrice, -result.totalPrice]
    )
  })

  it('guest can reject created trip', async function () {
    const {
      rentalityPlatform,
      rentalityGateway,
      rentalityCarToken,
      host,
      guest,
      rentalityPaymentService,
      rentalityLocationVerifier,
      admin,
    } = await loadFixture(deployDefaultFixture)

    await expect(
      rentalityGateway
        .connect(host)
        .addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
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
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, ' ')
    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    await expect(rentalityPlatform.connect(guest).rejectTripRequest(1)).to.changeEtherBalances(
      [guest, rentalityPaymentService],
      [result.totalPrice, -result.totalPrice]
    )
  })

  it('Happy case', async function () {
    const {
      rentalityPlatform,
      rentalityGateway,
      rentalityCarToken,
      rentalityTripService,
      rentalityPaymentService,
      rentalityCurrencyConverter,
      host,
      guest,
      rentalityLocationVerifier,
      admin,
    } = await loadFixture(deployDefaultFixture)

    const request = getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(request)).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
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
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted

    const depositValue = await rentalityCurrencyConverter.getFromUsd(
      ethToken,
      request.securityDepositPerTripInUsdCents,
      ethToCurrencyRate,
      ethToCurrencyDecimals
    )

    const returnToHost = rentPriceInEth - depositValue - rentalityFee - taxes

    await expect(rentalityPlatform.connect(host).finishTrip(1)).to.changeEtherBalances(
      [host, rentalityPaymentService],
      [returnToHost, -(rentPriceInEth - rentalityFee - taxes)]
    )
  })

  it('if trip accepted intersect trips should be rejected', async function () {
    const {
      rentalityPlatform,
      rentalityGateway,
      rentalityPaymentService,
      rentalityCarToken,
      rentalityTripService,
      rentalityCurrencyConverter,
      host,
      guest,
      admin,
      rentalityLocationVerifier,
    } = await loadFixture(deployDefaultFixture)

    await expect(
      rentalityGateway
        .connect(host)
        .addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
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
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, ' ')
    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).not.to.be.reverted

    await expect(
      rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 234,
          endDateTime: 456,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).not.to.be.reverted

    expect((await rentalityTripService.connect(host).getTrip(1)).status).to.equal(0)
    expect((await rentalityTripService.connect(host).getTrip(2)).status).to.equal(0)

    await expect(rentalityPlatform.connect(host).approveTripRequest(1)).to.changeEtherBalances(
      [guest, rentalityPaymentService],
      [result.totalPrice, -result.totalPrice]
    )

    const trip1 = await rentalityTripService.connect(host).getTrip(1)
    const trip2 = await rentalityTripService.connect(host).getTrip(2)
    expect(trip1.status).to.equal(1)
    expect(trip2.status).to.equal(7)
  })

  it("if trip accepted not intersect trips shouldn't be rejected", async function () {
    const {
      rentalityPlatform,
      rentalityGateway,
      rentalityCarToken,
      rentalityTripService,
      host,
      guest,
      admin,
      rentalityLocationVerifier,
    } = await loadFixture(deployDefaultFixture)

    await expect(
      rentalityGateway
        .connect(host)
        .addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
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

    const dailyPriceInUsdCents = 1000

    const result = await rentalityGateway
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, ' ')
    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).not.to.be.reverted

    await expect(
      rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 456,
          endDateTime: 789,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).not.to.be.reverted

    expect((await rentalityTripService.connect(host).getTrip(1)).status).to.equal(0)
    expect((await rentalityTripService.connect(host).getTrip(2)).status).to.equal(0)

    await expect(rentalityPlatform.connect(host).approveTripRequest(1)).not.to.be.reverted

    const trip1 = await rentalityTripService.connect(host).getTrip(1)
    const trip2 = await rentalityTripService.connect(host).getTrip(2)
    expect(trip1.status).to.equal(1)
    expect(trip2.status).to.equal(0)
  })

  it('searchAvailableCarsWithDelivery should return cars with Intersect trip in status Created', async function () {
    const {
      rentalityPlatform,
      rentalityGateway,
      rentalityCarToken,
      rentalityTripService,
      host,
      guest,
      admin,
      rentalityLocationVerifier,
    } = await loadFixture(deployDefaultFixture)

    await expect(
      rentalityGateway
        .connect(host)
        .addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)

    const timestampNow = Math.floor(Date.now() / 1000)
    const timestampIn1Day = timestampNow + 3600 * 24
    const searchCarParams = getEmptySearchCarParams()
    const availableCars = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsWithDelivery(
        timestampNow,
        timestampIn1Day,
        searchCarParams,
        emptyLocationInfo,
        emptyLocationInfo
      )
    expect(availableCars.length).to.equal(1)

    const result = await rentalityGateway
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, ' ')
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
        ' ',
        { value: result.totalPrice }
      )
    ).not.to.be.reverted

    expect((await rentalityTripService.connect(host).getTrip(1)).status).to.equal(0)

    const availableCars2 = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsWithDelivery(
        timestampNow,
        timestampIn1Day,
        searchCarParams,
        emptyLocationInfo,
        emptyLocationInfo
      )
    expect(availableCars2.length).to.equal(1)
  })

  it("searchAvailableCarsWithDelivery shouldn't return cars with Intersect trip in status approved", async function () {
    const {
      rentalityPlatform,
      rentalityGateway,
      rentalityCarToken,
      rentalityTripService,
      host,
      guest,
      admin,
      rentalityLocationVerifier,
    } = await loadFixture(deployDefaultFixture)

    await expect(
      rentalityGateway
        .connect(host)
        .addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)

    const timestampNow = Math.floor(Date.now() / 1000)
    const timestampIn1Day = timestampNow + 3600 * 24
    const searchCarParams = getEmptySearchCarParams()
    const availableCars = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsWithDelivery(
        timestampNow,
        timestampIn1Day,
        searchCarParams,
        emptyLocationInfo,
        emptyLocationInfo
      )
    expect(availableCars.length).to.equal(1)

    const result = await rentalityGateway
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, ' ')
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: timestampNow,
          endDateTime: timestampIn1Day,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).not.to.be.reverted

    expect((await rentalityTripService.connect(host).getTrip(1)).status).to.equal(0)

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted

    const trip1 = await rentalityTripService.connect(host).getTrip(1)
    expect(trip1.status).to.equal(1)
    const availableCars2 = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsWithDelivery(
        timestampNow,
        timestampIn1Day,
        searchCarParams,
        emptyLocationInfo,
        emptyLocationInfo
      )
    expect(availableCars2.length).to.equal(0)
  })
})
