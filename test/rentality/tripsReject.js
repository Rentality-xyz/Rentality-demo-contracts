const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { expect } = require('chai')
const { getMockCarRequest, getEmptySearchCarParams, ethToken, calculatePayments } = require('../utils')
const { deployDefaultFixture } = require('./deployments')
const { ethers } = require('hardhat')

describe('Rentality: reject Trip Request', function () {
  it('Host reject | trip status Created | trip money + deposit returned to guest', async function () {
    const {
      rentalityPlatform,
      rentalityPaymentService,
      rentalityCarToken,
      rentalityCurrencyConverter,
      rentalityTripService,
      host,
      guest,
    } = await loadFixture(deployDefaultFixture)

    await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const dailyPriceInUsdCents = 1000
    const deposit = 400

    const result = await rentalityPlatform.calculatePayments(1, 1, ethToken)
    await expect(
      await rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
        },
        { value: result.totalPrice }
      )
    ).not.to.be.reverted
    expect((await rentalityTripService.connect(host).getTrip(1)).status).to.equal(0)

    const balanceAfterRequest = await ethers.provider.getBalance(await guest.getAddress())

    expect(await rentalityPlatform.connect(host).rejectTripRequest(1)).not.to.be.reverted
    expect((await rentalityTripService.connect(host).getTrip(1)).status).to.equal(7)

    const balanceAfterRejection = await ethers.provider.getBalance(await guest.getAddress())
    const returnAmountDifference = result.totalPrice - (balanceAfterRejection - balanceAfterRequest)
    expect(
      returnAmountDifference === BigInt(0),
      'Balance should be refunded the amount which is deducted by a trip request'
    ).to.be.true
  })

  it('Guest reject | trip status Created | trip money + deposit - gas fee returned to guest', async function () {
    const {
      rentalityPlatform,
      rentalityPaymentService,
      rentalityCarToken,
      rentalityTripService,
      rentalityCurrencyConverter,
      host,
      guest,
    } = await loadFixture(deployDefaultFixture)

    await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const result = await rentalityPlatform.calculatePayments(1, 1, ethToken)

    await expect(
      await rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
        },
        { value: result.totalPrice }
      )
    ).not.to.be.reverted
    expect((await rentalityTripService.connect(host).getTrip(1)).status).to.equal(0)

    const balanceBeforeRejection = await ethers.provider.getBalance(await guest.getAddress())

    const tx = await (await rentalityPlatform.connect(guest).rejectTripRequest(1)).wait()

    const gasCost = tx.gasUsed * tx.gasPrice

    const balanceAfterRejection = await ethers.provider.getBalance(await guest.getAddress())

    const expectedBalance = balanceBeforeRejection + result.totalPrice - gasCost

    expect(balanceAfterRejection === BigInt(expectedBalance), 'The guest should be refunded minus the gas cost').to.be
      .true
  })

  it('Guest reject | trip status Accepted', async function () {
    const {
      rentalityPlatform,
      rentalityCarToken,
      rentalityTripService,
      rentalityCurrencyConverter,
      rentalityPaymentService,
      host,
      guest,
    } = await loadFixture(deployDefaultFixture)

    await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(1))).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const result = await rentalityPlatform.calculatePayments(1, 1, ethToken)
    await expect(
      await rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
        },
        { value: result.totalPrice }
      )
    ).not.to.be.reverted

    await expect(await rentalityPlatform.connect(host).approveTripRequest(1)).not.to.be.reverted

    expect((await rentalityTripService.connect(host).getTrip(1)).status).to.equal(1)
  })

  it('Guest reject | trip status CheckedInByHost', async function () {
    const { rentalityPlatform, rentalityCarToken, rentalityTripService, host, guest } =
      await loadFixture(deployDefaultFixture)

    await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(1))).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const result = await rentalityPlatform.calculatePayments(1, 1, ethToken)

    await expect(
      await rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
        },
        { value: result.totalPrice }
      )
    ).not.to.be.reverted

    await expect(await rentalityPlatform.connect(host).approveTripRequest(1)).not.to.be.reverted
    expect((await rentalityTripService.connect(host).getTrip(1)).status).to.equal(1)

    await expect(await rentalityTripService.connect(host).checkInByHost(1, [10, 10])).not.to.be.reverted
    expect((await rentalityTripService.connect(host).getTrip(1)).status).to.equal(2)
  })
})
