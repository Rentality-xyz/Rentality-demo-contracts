const { expect } = require('chai')

const { getMockCarRequest, TripStatus, deployDefaultFixture, ethToken, calculatePayments } = require('../utils')
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
    anonymous

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
    } = await loadFixture(deployDefaultFixture))
  })

  it('should create history in case of cancellation', async function () {
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
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(1))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const oneDayInSeconds = 86400

    const dailyPriceInUsdCents = 1000

    const { rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals, rentalityFee, taxes } = await calculatePayments(
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
          startDateTime: 1,
          endDateTime: 2,
          startLocation: 'startLocation',
          endLocation: 'endLocation',
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
    await expect(rentalityGateway.connect(host).checkInByHost(1, [100, 2])).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [100, 2])).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [0, 2])).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 2])).not.to.be.reverted

    const returnToHost = rentPriceInEth - rentalityFee - taxes

    await expect(rentalityGateway.connect(host).finishTrip(1)).to.changeEtherBalances(
      [host, rentalityPlatform],
      [returnToHost, -returnToHost]
    )
    const details = (await rentalityGateway.getTrip(1)).trip

    const currentTimeMillis = Date.now()
    const currentTimeSeconds = Math.floor(currentTimeMillis / 1000)

    expect(details.transactionInfo.depositRefund).to.be.eq(0)
    expect(details.transactionInfo.dateTime).to.be.approximately(currentTimeSeconds, 2000)
    expect(details.transactionInfo.tripEarnings).to.be.eq(
      dailyPriceInUsdCents - (dailyPriceInUsdCents * 20) / 100 /* platform fee*/
    )
    expect(details.transactionInfo.rentalityFee).to.be.eq((dailyPriceInUsdCents * 20) / 100)
    expect(details.transactionInfo.statusBeforeCancellation).to.be.eq(TripStatus.Finished)
  })

  it('Should have receipt after trip end', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    let sumToPayInUsdCents = 173800
    let dayInTrip = 7
    let sumToPayWithDiscount = sumToPayInUsdCents * dayInTrip - (sumToPayInUsdCents * dayInTrip * 10) / 100

    let totalTaxes = (sumToPayWithDiscount * 7) / 100 + dayInTrip * 200

    let deposit = 1000

    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(
        ethToken,
        Math.floor(sumToPayWithDiscount + totalTaxes + deposit)
      )

    let sevenDays = 86400 * 7

    await expect(
      await rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: Date.now(),
          endDateTime: Date.now() + sevenDays,
          startLocation: 'startLocation',
          endLocation: 'endLocation',
          totalDayPriceInUsdCents: sumToPayInUsdCents,
          depositInUsdCents: deposit,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).to.changeEtherBalances([guest, rentalityPlatform], [-rentPriceInEth, rentPriceInEth])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [100, 15])).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [100, 15])).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [50, 200])).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [50, 200])).not.to.be.reverted

    await expect(rentalityGateway.connect(host).finishTrip(1)).to.not.reverted

    let result = await rentalityGateway.getTripReceipt(1)

    expect(result.totalDayPriceInUsdCents).to.be.eq(sumToPayInUsdCents)
    expect(result.totalTripDays).to.be.eq(7)
    expect(result.discountAmount).to.be.eq(BigInt(sumToPayInUsdCents * 7 - sumToPayWithDiscount))
    expect(result.taxes).to.be.eq(BigInt(Math.floor(totalTaxes)))
    expect(result.depositReceived).to.be.eq(BigInt(deposit))
    expect(result.startFuelLevel).to.be.eq(BigInt(100))
    expect(result.endFuelLevel).to.be.eq(BigInt(50))
    expect(result.startOdometer).to.be.eq(BigInt(15))
    expect(result.endOdometer).to.be.eq(BigInt(200))
  })
})
