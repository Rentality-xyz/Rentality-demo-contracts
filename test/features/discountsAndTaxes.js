const { expect } = require('chai')
const { deployDefaultFixture, getMockCarRequest, ethToken } = require('../utils')
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

  it('should correctly calculate taxes', async function () {
    let sumToPayInUsdCents = 19500
    let dayInTrip = 3
    let totalTaxes = (sumToPayInUsdCents * 7) / 100 + dayInTrip * 200

    let calculatedTaxes = await rentalityPaymentService.calculateTaxes(1, dayInTrip, sumToPayInUsdCents)

    expect(totalTaxes).to.be.eq(calculatedTaxes)
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
    await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    let sumToPayInUsdCents = 19500
    let dayInTrip = 2
    let totalTaxes = (sumToPayInUsdCents * dayInTrip * 7) / 100 + dayInTrip * 200

    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, sumToPayInUsdCents * dayInTrip + totalTaxes)

    let twoDaysInSec = 172800

    await expect(
      rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: Date.now(),
          endDateTime: Date.now() + twoDaysInSec,
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
  })

  it('guest payed correct value with taxes and 3 days discount', async function () {
    await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    let sumToPayInUsdCents = 199500
    let dayInTrip = 4
    let sumToPayWithDiscount = sumToPayInUsdCents * dayInTrip - (sumToPayInUsdCents * dayInTrip * 2) / 100

    let totalTaxes = (sumToPayWithDiscount * 7) / 100 + dayInTrip * 200

    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, Math.floor(sumToPayWithDiscount + totalTaxes))

    let fourDaysInSec = 345600

    await expect(
      rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: Date.now(),
          endDateTime: Date.now() + fourDaysInSec,
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
  })
  it('guest payed correct value with taxes and 7 days discount', async function () {
    await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    let sumToPayInUsdCents = 43100
    let dayInTrip = 8
    let sumToPayWithDiscount = sumToPayInUsdCents * dayInTrip - (sumToPayInUsdCents * dayInTrip * 10) / 100

    let totalTaxes = (sumToPayWithDiscount * 7) / 100 + dayInTrip * 200

    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, Math.floor(sumToPayWithDiscount + totalTaxes))

    let eightDaysInSec = 691200

    await expect(
      rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: Date.now(),
          endDateTime: Date.now() + eightDaysInSec,
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
  })

  it('guest payed correct value with taxes and 30 days discount', async function () {
    await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    let sumToPayInUsdCents = 173800
    let dayInTrip = 31
    let sumToPayWithDiscount = sumToPayInUsdCents * dayInTrip - (sumToPayInUsdCents * dayInTrip * 15) / 100

    let totalTaxes = (sumToPayWithDiscount * 7) / 100 + dayInTrip * 200

    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, Math.floor(sumToPayWithDiscount + totalTaxes))

    let thirtyOneDayInSec = 86400 * 31

    await expect(
      rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: Date.now(),
          endDateTime: Date.now() + thirtyOneDayInSec,
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
  })
  it('after trip host get correct value', async function () {
    await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    let sumToPayInUsdCents = 173800
    let dayInTrip = 31
    let sumToPayWithDiscount = sumToPayInUsdCents * dayInTrip - (sumToPayInUsdCents * dayInTrip * 15) / 100

    let totalTaxes = (sumToPayWithDiscount * 7) / 100 + dayInTrip * 200

    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, Math.floor(sumToPayWithDiscount + totalTaxes))

    let thirtyOneDayInSec = 86400 * 31

    await expect(
      rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: Date.now(),
          endDateTime: Date.now() + thirtyOneDayInSec,
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
    await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted

    const [valueInEthWithoutTaxes, ,] = await rentalityCurrencyConverter.getFromUsdLatest(
      ethToken,
      Math.floor(sumToPayWithDiscount)
    )

    const returnToHost = rentPriceInEth - (await rentalityPaymentService.getPlatformFeeFrom(valueInEthWithoutTaxes))

    await expect(rentalityGateway.connect(host).finishTrip(1)).to.changeEtherBalances(
      [host, rentalityPlatform],
      [returnToHost, -returnToHost]
    )
  })

  it('Should return user discount, if it exists', async function () {
    await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
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

    let abiEncoder = ethers.AbiCoder.defaultAbiCoder()
    const encodedData = abiEncoder.encode(
      ['uint32', 'uint32', 'uint32', 'bool'],
      [data.threeDaysDiscount, data.sevenDaysDiscount, data.thirtyDaysDiscount, data.initialized]
    )

    await expect(await rentalityPaymentService.connect(owner).addUserDiscount(encodedData)).to.not.reverted

    let first = await rentalityPaymentService.connect(owner).calculateSumWithDiscount(owner.address, 3, 1000)
    expect(first).to.be.eq(1000 * 3 - (1000 * 3 * 10) / 100)
    let second = await rentalityPaymentService.connect(owner).calculateSumWithDiscount(owner.address, 8, 1000)
    expect(second).to.be.eq(1000 * 8 - (1000 * 8 * 20) / 100)
    let last = await rentalityPaymentService.connect(owner).calculateSumWithDiscount(owner.address, 31, 1000)
    expect(last).to.be.eq(0)
  })
})
