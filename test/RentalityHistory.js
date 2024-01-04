const { expect } = require('chai')
const { ethers, upgrades } = require('hardhat')
const {
  time,
  loadFixture,
} = require('@nomicfoundation/hardhat-network-helpers')
const { Contract } = require('hardhat/internal/hardhat-network/stack-traces/model')

const {
  getMockCarRequest,
  TripStatus,
  getEmptySearchCarParams,
  createMockClaimRequest,
  deployDefaultFixture,
} = require('./utils')


describe('Rentality History Service', function() {

  let
    rentalityPlatform,
    rentalityGateway,
    transactionHistory,
    rentalityCurrencyConverter,
    owner,
    admin,
    manager,
    host,
    guest,
    anonymous

  beforeEach(async function() {
    ({
      rentalityPlatform,
      rentalityGateway,
      rentalityCurrencyConverter,
      owner,
      admin,
      manager,
      host,
      guest,
      anonymous,
    } = await loadFixture(deployDefaultFixture))
  })


  it('should create history in case of cancellation', async function() {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0)))
      .not.to.be.reverted
    const myCars = await rentalityGateway
      .connect(host)
      .getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway
      .connect(guest)
      .getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getEthFromUsdLatest(
        rentPriceInUsdCents,
      )

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 1,
          endDateTime: 1,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth },
      ),
    ).not.to.be.reverted

    await expect(rentalityGateway.connect(host).rejectTripRequest(1)).to.not.reverted
    const details = await rentalityGateway.getTrip(1)

    const currentTimeMillis = Date.now()
    const currentTimeSeconds = Math.floor(currentTimeMillis / 1000)

    expect(details.transactionInfo.depositRefund).to.not.be.eq(0)
    expect(details.transactionInfo.dateTime).to.be.approximately(currentTimeSeconds, 2000)
    expect(details.transactionInfo.tripEarnings).to.be.eq(0)
    expect(details.transactionInfo.statusBeforeCancellation).to.be.eq(TripStatus.Created)
  })
  it('Happy case has history', async function() {

    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0)))
      .not.to.be.reverted
    const myCars = await rentalityGateway
      .connect(host)
      .getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway
      .connect(guest)
      .getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getEthFromUsdLatest(
        rentPriceInUsdCents,
      )

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 1,
          endDateTime: 1,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth },
      ),
    ).to.changeEtherBalances(
      [guest, rentalityPlatform],
      [-rentPriceInEth, rentPriceInEth],
    )


    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to
      .be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0]))
      .not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0]))
      .not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [0, 0]))
      .not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0]))
      .not.to.be.reverted

    const returnToHost =
      rentPriceInEth -
      (rentPriceInEth *
        (await rentalityGateway.getPlatformFeeInPPM())) /
      BigInt(1_000_000)

    await expect(
      rentalityGateway.connect(host).finishTrip(1),
    ).to.changeEtherBalances(
      [host, rentalityPlatform],
      [returnToHost, -returnToHost],
    )
    const details = await rentalityGateway.getTrip(1)

    const currentTimeMillis = Date.now()
    const currentTimeSeconds = Math.floor(currentTimeMillis / 1000)

    expect(details.transactionInfo.depositRefund).to.be.eq(0)
    expect(details.transactionInfo.dateTime).to.be.approximately(currentTimeSeconds, 2000)
    expect(details.transactionInfo.tripEarnings).to.be.eq((rentPriceInUsdCents - (rentPriceInUsdCents * 20 / 100 )) )
    expect(details.transactionInfo.rentalityFee).to.be.eq((rentPriceInUsdCents * 20 / 100 ))
    expect(details.transactionInfo.statusBeforeCancellation).to.be.eq(TripStatus.Finished)


  })


})
