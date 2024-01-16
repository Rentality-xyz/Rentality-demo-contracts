const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { expect } = require('chai')
const { getMockCarRequest, getEmptySearchCarParams } = require('../utils')
const { deployDefaultFixture } = require('./deployments')
const { ethers } = require('hardhat')

describe('Rentality: reject Trip Request', function () {
  it('Host reject | trip status Created | trip money + deposit returned to guest', async function () {
    const { rentalityPlatform, rentalityCarToken, rentalityCurrencyConverter, rentalityTripService, host, guest } =
      await loadFixture(deployDefaultFixture)

    await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1600
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getEthFromUsdLatest(rentPriceInUsdCents)

    await expect(
      await rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 123,
          endDateTime: 321,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: 1000,
          taxPriceInUsdCents: 200,
          depositInUsdCents: 400,
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted
    expect((await rentalityTripService.connect(host).getTrip(1)).status).to.equal(0)

    const balanceAfterRequest = await ethers.provider.getBalance(await guest.getAddress())

    expect(await rentalityPlatform.connect(host).rejectTripRequest(1)).not.to.be.reverted
    expect((await rentalityTripService.connect(host).getTrip(1)).status).to.equal(7)

    const balanceAfterRejection = await ethers.provider.getBalance(await guest.getAddress())
    const returnAmountDifference = rentPriceInEth - (balanceAfterRejection - balanceAfterRequest)
    expect(
      returnAmountDifference === BigInt(0),
      'Balance should be refunded the amount which is deducted by a trip request'
    ).to.be.true
  })

  it('Guest reject | trip status Created | trip money + deposit - gas fee returned to guest', async function () {
    const { rentalityPlatform, rentalityCarToken, rentalityTripService, rentalityCurrencyConverter, host, guest } =
      await loadFixture(deployDefaultFixture)

    await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1600
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getEthFromUsdLatest(rentPriceInUsdCents)

    await expect(
      await rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 123,
          endDateTime: 321,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: 1000,
          taxPriceInUsdCents: 200,
          depositInUsdCents: 400,
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted
    expect((await rentalityTripService.connect(host).getTrip(1)).status).to.equal(0)

    const balanceBeforeRejection = await ethers.provider.getBalance(await guest.getAddress())

    const tx = await (await rentalityPlatform.connect(guest).rejectTripRequest(1)).wait()

    const gasCost = tx.gasUsed * tx.gasPrice

    const balanceAfterRejection = await ethers.provider.getBalance(await guest.getAddress())

    const expectedBalance = balanceBeforeRejection + rentPriceInEth - gasCost

    expect(balanceAfterRejection === BigInt(expectedBalance), 'The guest should be refunded minus the gas cost').to.be
      .true
  })

  it('Guest reject | trip status Accepted | trip money - 50% price per day - deposit - gas fee returned to guest', async function () {
    const { rentalityPlatform, rentalityCarToken, rentalityTripService, rentalityCurrencyConverter, host, guest } =
      await loadFixture(deployDefaultFixture)

    await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(1))).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const pricePerDayInUsdCents = 102
    const dailyPriceInUsdCents = 1000
    const rentPriceInUsdCents = dailyPriceInUsdCents + 600
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getEthFromUsdLatest(rentPriceInUsdCents)
    const [pricePerDayInEth] = await rentalityCurrencyConverter.getEthFromUsdLatest(pricePerDayInUsdCents)

    await expect(
      await rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 123,
          endDateTime: 321,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: dailyPriceInUsdCents,
          taxPriceInUsdCents: 200,
          depositInUsdCents: 400,
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted

    await expect(await rentalityPlatform.connect(host).approveTripRequest(1)).not.to.be.reverted

    expect((await rentalityTripService.connect(host).getTrip(1)).status).to.equal(1)

    const balanceBeforeRejection = await ethers.provider.getBalance(await guest.getAddress())

    const tx = await (await rentalityPlatform.connect(guest).rejectTripRequest(1)).wait()

    const gasCost = tx.gasUsed * tx.gasPrice

    const balanceAfterRejection = await ethers.provider.getBalance(await guest.getAddress())

    const expectedBalance = balanceBeforeRejection + rentPriceInEth - gasCost - pricePerDayInEth / BigInt(2)

    expect(
      balanceAfterRejection === expectedBalance,
      'The guest should be refunded minus the gas cost and minus 50% of daily price'
    ).to.be.true
  })

  it('Guest reject | trip status CheckedInByHost | trip money - 100% price per day - deposit - gas fee returned to guest', async function () {
    const { rentalityPlatform, rentalityCarToken, rentalityTripService, rentalityCurrencyConverter, host, guest } =
      await loadFixture(deployDefaultFixture)

    await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(1))).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const pricePerDayInUsdCents = 102
    const dailyPriceInUsdCents = 1000
    const rentPriceInUsdCents = dailyPriceInUsdCents + 600
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getEthFromUsdLatest(rentPriceInUsdCents)
    const [pricePerDayInEth] = await rentalityCurrencyConverter.getEthFromUsdLatest(pricePerDayInUsdCents)

    await expect(
      await rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 123,
          endDateTime: 321,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: dailyPriceInUsdCents,
          taxPriceInUsdCents: 200,
          depositInUsdCents: 400,
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted

    await expect(await rentalityPlatform.connect(host).approveTripRequest(1)).not.to.be.reverted
    expect((await rentalityTripService.connect(host).getTrip(1)).status).to.equal(1)

    await expect(await rentalityTripService.connect(host).checkInByHost(1, [10, 10])).not.to.be.reverted
    expect((await rentalityTripService.connect(host).getTrip(1)).status).to.equal(2)

    const balanceBeforeRejection = await ethers.provider.getBalance(await guest.getAddress())

    const tx = await (await rentalityPlatform.connect(guest).rejectTripRequest(1)).wait()

    const gasCost = tx.gasUsed * tx.gasPrice

    const balanceAfterRejection = await ethers.provider.getBalance(await guest.getAddress())

    const expectedBalance = balanceBeforeRejection + rentPriceInEth - gasCost - pricePerDayInEth

    expect(
      balanceAfterRejection === BigInt(expectedBalance),
      'The guest should be refunded minus the gas cost and minus the daily price'
    ).to.be.true
  })
})
