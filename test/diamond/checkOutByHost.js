const { expect } = require('chai')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')

const {
  getMockCarRequest,
  TripStatus,
  deployDefaultFixture,
  ethToken,
  locationInfo,
  signTCMessage,
  signLocationInfo,
  emptyLocationInfo,
  getEmptySearchCarParams,
  zeroHash,
  emptySignedLocationInfo,
} = require('../utils')
const {deployDefault, calculatePayments} = require('./deploy')
const { ethers } = require('hardhat')

describe.only('RentalityGateway: trips', function () {
  let rentalityGateway,
    rentalityLocationVerifier,
    owner,
    admin,
    manager,
    host,
    guest,
    anonymous

  beforeEach(async function () {
    ;({
      rentalityGateway,
      rentalityLocationVerifier,
      owner,
      admin,
      manager,
      host,
      guest,
      anonymous,
    } = await loadFixture(deployDefault))
  })

  it('Host can check out without guest', async function () {
    let request = await getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
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

    const oneDayInSeconds = 86400

    const { rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals, rentalityFee, taxes } = await calculatePayments(
      rentalityGateway,
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
        ' ',
        { value: rentPriceInEth }
      )
    ).to.changeEtherBalances([guest, rentalityGateway], [-rentPriceInEth, rentPriceInEth])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted
  })

  it('Car is available on search after check out without guest', async function () {
    let request = await getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
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

    const oneDayInSeconds = 86400
    const { rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals, rentalityFee, taxes } = await calculatePayments(
      rentalityGateway,
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
        ' ',
        { value: rentPriceInEth }
      )
    ).to.changeEtherBalances([guest, rentalityGateway], [-rentPriceInEth, rentPriceInEth])

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
    let request = await getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
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

    const oneDayInSeconds = 86400

    const { rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals, rentalityFee, taxes } = await calculatePayments(
      rentalityGateway,
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
        ' ',
        { value: rentPriceInEth }
      )
    ).to.changeEtherBalances([guest, rentalityGateway], [-rentPriceInEth, rentPriceInEth])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.be.reverted
    await expect(rentalityGateway.connect(host).finishTrip(1)).to.be.reverted
  })
  it('Happy case, with guest confirmation', async function () {
    let request = await getMockCarRequest(3, await rentalityLocationVerifier.getAddress(), admin)
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
    let oneDayInSeconds = 86400
    let dayInTrip = 31

    const { rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals, rentalityFee, taxes } = await calculatePayments(
      rentalityGateway,
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
        ' ',
        { value: rentPriceInEth }
      )
    ).to.changeEtherBalances([guest, rentalityGateway], [-rentPriceInEth, rentPriceInEth])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(host).confirmCheckOut(1)).to.be.reverted

    const depositValue = await rentalityGateway.getFromUsd(
      ethToken,
      request.securityDepositPerTripInUsdCents,
      ethToCurrencyRate,
      ethToCurrencyDecimals
    )

    const returnToHost = rentPriceInEth - rentalityFee - taxes - depositValue

    await expect(rentalityGateway.connect(guest).confirmCheckOut(1)).to.changeEtherBalances(
      [host, rentalityGateway],
      [returnToHost, -(rentPriceInEth - taxes - rentalityFee)]
    )
    const trip = await rentalityGateway.getTrip(1)

    expect(trip.trip.status).to.be.eq(TripStatus.Finished)
  })
  it('Happy case, with admin confirmation', async function () {
    const request = await getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin)
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
    const oneDayInSeconds = 86400

    const { rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals, rentalityFee, taxes } = await calculatePayments(
      rentalityGateway,
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
        ' ',
        { value: rentPriceInEth }
      )
    ).to.changeEtherBalances([guest, rentalityGateway], [-rentPriceInEth, rentPriceInEth])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted

    const depositValue = await rentalityGateway.getFromUsd(
      ethToken,
      request.securityDepositPerTripInUsdCents,
      ethToCurrencyRate,
      ethToCurrencyDecimals
    )

    const returnToHost = rentPriceInEth - rentalityFee - taxes - depositValue

    await expect(rentalityGateway.connect(owner).confirmCheckOut(1)).to.changeEtherBalances(
      [host, rentalityGateway],
      [returnToHost, -(rentPriceInEth - taxes - rentalityFee)]
    )
    const trip = await rentalityGateway.getTrip(1)

    expect(trip.trip.status).to.be.eq(TripStatus.Finished)
  })

  it.only('Admin can reject trip, after check out without guest', async function () {
    let request = await getMockCarRequest(2, await rentalityLocationVerifier.getAddress(), admin)
    request.engineType = 2
    request.engineParams = [1]
    await rentalityGateway.connect(host).addCar(request)
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
      rentalityGateway,
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
        ' ',
        { value: rentPriceInEth }
      )
    ).to.changeEtherBalances([guest, rentalityGateway], [-rentPriceInEth, rentPriceInEth])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [10, 1], '', '')).not.to.be.reverted
    const t = await rentalityGateway.getTrip(1)
    console.log(t.trip.startParamLevels)
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [10, 1])).not.to.be.reverted

    await expect(rentalityGateway.connect(guest).rejectTripRequest(1)).to.be.reverted
    await expect(rentalityGateway.connect(host).rejectTripRequest(1)).to.be.reverted

    await expect(rentalityGateway.connect(owner).rejectTripRequest(1)).to.changeEtherBalances(
      [guest, rentalityGateway],
      [rentPriceInEth, -rentPriceInEth]
    )
    const trip = await rentalityGateway.getTrip(1)

    expect(trip.trip.status).to.be.eq(TripStatus.Canceled)
  })
})
