const { expect } = require('chai')
const {
  deployDefaultFixture,
  getMockCarRequest,
  ethToken,
  calculatePayments,
  getEmptySearchCarParams,
  TripStatus,
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
    } = await loadFixture(deployDefaultFixture))
  })

  it('Host can check out without guest', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const oneDayInSeconds = 86400

    const dailyPriceInUsdCents = 1000

    const { rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals, rentalityFee } = await calculatePayments(
      rentalityCurrencyConverter,
      rentalityPaymentService,
      dailyPriceInUsdCents,
      1,
      0
    )

    await expect(
      await rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: dailyPriceInUsdCents,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).to.changeEtherBalances([guest, rentalityPlatform], [-rentPriceInEth, rentPriceInEth])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByGuest(1, [0, 0])).not.to.be.reverted
  })

  it('Car is available on search after check out without guest', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const oneDayInSeconds = 86400

    const dailyPriceInUsdCents = 1000

    const { rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals, rentalityFee } = await calculatePayments(
      rentalityCurrencyConverter,
      rentalityPaymentService,
      dailyPriceInUsdCents,
      1,
      0
    )

    await expect(
      await rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: dailyPriceInUsdCents,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).to.changeEtherBalances([guest, rentalityPlatform], [-rentPriceInEth, rentPriceInEth])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByGuest(1, [0, 0])).not.to.be.reverted

    const searchParams = getEmptySearchCarParams()
    const resultAr = await rentalityGateway.searchAvailableCars(
      new Date().getDate(),
      new Date().getDate() + 100,
      searchParams
    )
    const carId = resultAr[0].carId

    expect(carId).to.be.eq(1)
  })

  it('Host can not check out and finish trip without confirmation', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const oneDayInSeconds = 86400

    const dailyPriceInUsdCents = 1000

    const { rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals, rentalityFee } = await calculatePayments(
      rentalityCurrencyConverter,
      rentalityPaymentService,
      dailyPriceInUsdCents,
      1,
      0
    )

    await expect(
      await rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: dailyPriceInUsdCents,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).to.changeEtherBalances([guest, rentalityPlatform], [-rentPriceInEth, rentPriceInEth])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).to.be.reverted
    await expect(rentalityGateway.connect(host).finishTrip(1)).to.be.reverted
  })
  it('Happy case, with guest confirmation', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)
    let oneDayInSeconds = 86400
    let sumToPayInUsdCents = 173800
    let dayInTrip = 31
    let sumToPayWithDiscount = sumToPayInUsdCents * dayInTrip - (sumToPayInUsdCents * dayInTrip * 15) / 100

    const { rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals, rentalityFee } = await calculatePayments(
      rentalityCurrencyConverter,
      rentalityPaymentService,
      sumToPayInUsdCents,
      dayInTrip,
      0
    )

    await expect(
      await rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds * 31,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: sumToPayInUsdCents,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).to.changeEtherBalances([guest, rentalityPlatform], [-rentPriceInEth, rentPriceInEth])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(host).confirmCheckOut(1)).to.be.reverted

    const [valueInEthWithoutTaxes, ,] = await rentalityCurrencyConverter.getFromUsdLatest(
      ethToken,
      Math.floor(sumToPayWithDiscount)
    )

    const returnToHost = rentPriceInEth - (await rentalityPaymentService.getPlatformFeeFrom(valueInEthWithoutTaxes))

    await expect(rentalityGateway.connect(guest).confirmCheckOut(1)).to.changeEtherBalances(
      [host, rentalityPlatform],
      [returnToHost, -returnToHost]
    )
    const trip = await rentalityTripService.getTrip(1)

    expect(trip.status).to.be.eq(TripStatus.Finished)
  })
  it('Happy case, with admin confirmation', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)
    let oneDayInSeconds = 86400
    let sumToPayInUsdCents = 173800
    let dayInTrip = 31
    let sumToPayWithDiscount = sumToPayInUsdCents * dayInTrip - (sumToPayInUsdCents * dayInTrip * 15) / 100

    const { rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals, rentalityFee } = await calculatePayments(
      rentalityCurrencyConverter,
      rentalityPaymentService,
      sumToPayInUsdCents,
      dayInTrip,
      0
    )

    await expect(
      await rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds * 31,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: sumToPayInUsdCents,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).to.changeEtherBalances([guest, rentalityPlatform], [-rentPriceInEth, rentPriceInEth])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByGuest(1, [0, 0])).not.to.be.reverted

    const [valueInEthWithoutTaxes, ,] = await rentalityCurrencyConverter.getFromUsdLatest(
      ethToken,
      Math.floor(sumToPayWithDiscount)
    )

    const returnToHost = rentPriceInEth - (await rentalityPaymentService.getPlatformFeeFrom(valueInEthWithoutTaxes))

    await expect(rentalityGateway.connect(admin).confirmCheckOut(1)).to.changeEtherBalances(
      [host, rentalityPlatform],
      [returnToHost, -returnToHost]
    )
    const trip = await rentalityTripService.getTrip(1)

    expect(trip.status).to.be.eq(TripStatus.Finished)
  })

  it('Admin can reject trip, after check out without guest', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)
    let oneDayInSeconds = 86400
    let sumToPayInUsdCents = 173800
    let dayInTrip = 31
    let sumToPayWithDiscount = sumToPayInUsdCents * dayInTrip - (sumToPayInUsdCents * dayInTrip * 15) / 100

    const { rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals, rentalityFee } = await calculatePayments(
      rentalityCurrencyConverter,
      rentalityPaymentService,
      sumToPayInUsdCents,
      dayInTrip,
      0
    )

    await expect(
      await rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds * 31,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: sumToPayInUsdCents,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).to.changeEtherBalances([guest, rentalityPlatform], [-rentPriceInEth, rentPriceInEth])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByGuest(1, [0, 0])).not.to.be.reverted

    await expect(rentalityGateway.connect(guest).rejectTripRequest(1)).to.be.reverted
    await expect(rentalityGateway.connect(host).rejectTripRequest(1)).to.be.reverted

    await expect(rentalityGateway.connect(admin).rejectTripRequest(1)).to.changeEtherBalances(
      [guest, rentalityPlatform],
      [rentPriceInEth, -rentPriceInEth]
    )
    const trip = await rentalityTripService.getTrip(1)

    expect(trip.status).to.be.eq(TripStatus.Canceled)
  })
})