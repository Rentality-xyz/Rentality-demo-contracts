const { expect } = require('chai')
const { ethers, upgrades, network } = require('hardhat')
const { deployDefaultFixture, getMockCarRequest, ethToken, calculatePayments } = require('../utils')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')

describe('RentalityEngines', function () {
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
    rentalityView,
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
      rentalityView,
    } = await loadFixture(deployDefaultFixture))
  })

  it('should correctly verify patrol data', async function () {
    let tankVolume = 15
    let fuelPrice = 375
    let engineTy = await pEngine.getEType()

    await expect(engineService.verifyCreateParams(engineTy, [tankVolume, fuelPrice])).to.not.reverted
    await expect(engineService.verifyCreateParams(engineTy, [0, fuelPrice])).to.be.reverted
    await expect(engineService.verifyCreateParams(engineTy, [tankVolume, 0])).to.be.reverted
  })
  it('should correctly verify electric car engine data', async function () {
    let price = 10
    let engineTy = await elEngine.getEType()

    await expect(engineService.verifyCreateParams(engineTy, [price])).to.not.reverted
    await expect(engineService.verifyCreateParams(engineTy, [price, price])).to.be.reverted
  })

  it('should correctly verify hybrid car engine data', async function () {
    let tankVolume = 15
    let fuelPrice = 375
    let engineTy = await pEngine.getEType()

    await expect(engineService.verifyCreateParams(engineTy, [tankVolume, fuelPrice])).to.not.reverted
    await expect(engineService.verifyCreateParams(engineTy, [0, fuelPrice])).to.be.reverted
    await expect(engineService.verifyCreateParams(engineTy, [tankVolume, 0])).to.be.reverted
  })
  it('should correctly update patrol car engine data', async function () {
    let oldParams = [10, 15]
    let newParams = [1]
    let engineTy = await pEngine.getEType()

    await expect(engineService.verifyUpdateParams(engineTy, [0], oldParams)).to.be.reverted

    let newCorrectParams = await engineService.verifyUpdateParams(engineTy, newParams, oldParams)

    expect(newCorrectParams[1]).to.be.eq(newParams[0])
  })
  it('should correctly update electric car engine data', async function () {
    let oldParams = [5]
    let engineTy = await elEngine.getEType()

    let newParams = [5]

    await expect(engineService.verifyUpdateParams(engineTy, [0, 0, 0], [1, 1, 1, 1])).to.be.reverted

    let newVeryfParams = await engineService.verifyUpdateParams(engineTy, newParams, oldParams)

    expect(newVeryfParams[0]).to.be.eq(newParams[0])
  })
  it('should correctly update hybrid car engine data', async function () {
    let oldParams = [10, 15]
    let newParams = [1]
    let engineTy = await pEngine.getEType()

    await expect(engineService.verifyUpdateParams(engineTy, [0], oldParams)).to.be.reverted

    let newCorrectParams = await engineService.verifyUpdateParams(engineTy, newParams, oldParams)

    expect(newCorrectParams[1]).to.be.eq(newParams[0])
  })

  describe('Correct params', function () {
    it('should correctly verify start params', async function () {
      let engineTy = await pEngine.getEType()
      let correctParams = [10, 5]
      let wrongParams1 = [0]
      let wrongParams2 = [1, 2, 4, 5, 6]
      let wrongParams4 = [101, 15]

      await expect(engineService.verifyStartParams(wrongParams1, engineTy)).to.be.reverted
      await expect(engineService.verifyStartParams(wrongParams2, engineTy)).to.be.reverted
      await expect(engineService.verifyStartParams(wrongParams4, engineTy)).to.be.reverted
      await expect(engineService.verifyStartParams(correctParams, engineTy)).to.not.reverted
    })
    it('should correctly verify end params', async function () {
      let engineTy = await elEngine.getEType()
      let correctStartParams = [10, 5]
      let correctEndParams = [15, 6]
      let wrongStartParams1 = [0]
      let wrongEndParams1 = [10, 2]
      let wrongStartParams2 = [10, 16]
      let wrongEndParams2 = [101, 15]
      let wrongStartParams3 = [10, 16]
      let wrongEndParams3 = [10, 15]

      await expect(engineService.verifyEndParams(wrongStartParams1, wrongEndParams1, engineTy)).to.be.reverted
      await expect(engineService.verifyEndParams(wrongStartParams2, wrongEndParams2, engineTy)).to.be.reverted
      await expect(engineService.verifyEndParams(wrongStartParams3, wrongEndParams3, engineTy)).to.be.reverted
      await expect(engineService.verifyEndParams(correctStartParams, correctEndParams, engineTy)).to.not.reverted
    })
    it('should correctly compare params', async function () {
      let engineTy = await hEngine.getEType()
      let correctStartParams = [10, 10]
      let correctEndParams = [10, 10]
      let wrongStartParams1 = [10]
      let wrongEndParams1 = [10, 15]
      let wrongStartParams2 = [15, 15]
      let wrongEndParams2 = [15, 14]

      await expect(engineService.compareParams(wrongStartParams1, wrongEndParams1, engineTy)).to.be.reverted
      await expect(engineService.compareParams(wrongStartParams2, wrongEndParams2, engineTy)).to.be.reverted
      await expect(engineService.compareParams(correctStartParams, correctEndParams, engineTy)).to.not.reverted
    })
  })
  describe('Computation', function () {
    it('should correctly compute patrol refund', async function () {
      let startParams = [50, 100] // Assuming startFuelLevelInPercents and startOdometr
      let endParams = [20, 200] // Assuming endFuelLevelInPercents and endOdometr
      let fuelPrices = 300 // Assuming fuel price in USD cents
      let carId = 1
      let milesIncludedPerDay = 50
      let pricePerDayInUsdCents = 100
      let tripDays = 3

      // Set patrol engine data for the car
      let tankVolume = 15
      let fuelPrice = 375
      let engineTy = await pEngine.getEType()

      let expectedFuelRefund =
        (((50 - 20) /*difference in percents*/ * tankVolume) / 100) /*compute difference in gallons*/ *
        300 /* compute refund in usd cents by price*/

      let result = await engineService.getResolveAmountInUsdCents(
        engineTy,
        fuelPrices,
        startParams,
        endParams,
        [tankVolume, fuelPrice],
        milesIncludedPerDay,
        pricePerDayInUsdCents,
        tripDays
      )
      expect(result[1]).to.be.eq(expectedFuelRefund)
    })
    it('should correctly compute electric refund', async function () {
      let startParams = [50, 100] // Assuming startFuelLevelInPercents and startOdometr
      let endParams = [20, 200] // Assuming endFuelLevelInPercents and endOdometr
      let fuelPrices = 300 // Assuming fuel price in USD cents
      let carId = 1
      let milesIncludedPerDay = 50
      let pricePerDayInUsdCents = 100
      let tripDays = 3

      let engineTy = await elEngine.getEType()

      let engineParams = [fuelPrices]

      let diff = startParams[0] - endParams[0]
      let expectedFuelRefund = (diff * fuelPrices) / 100

      let result = await engineService.getResolveAmountInUsdCents(
        engineTy,
        fuelPrices,
        startParams,
        endParams,
        engineParams,
        milesIncludedPerDay,
        pricePerDayInUsdCents,
        tripDays
      )
      expect(result[1]).to.be.eq(expectedFuelRefund)
    })
  })
})
