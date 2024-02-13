const { expect } = require('chai')
const { ethers, upgrades, network } = require('hardhat')
const { time, loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { Contract } = require('hardhat/internal/hardhat-network/stack-traces/model')
const { deployDefaultFixture, getMockCarRequest, nativeToken} = require('../utils')

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

  it('should correctly verify patrol data', async function () {
    let tankVolume = 15
    let fuelPrice = 375
    let engineTy = await pEngine.getEType()

    await expect(engineService.verifyCreateParams(engineTy, [tankVolume, fuelPrice])).to.not.reverted
    await expect(engineService.verifyCreateParams(engineTy, [0, fuelPrice])).to.be.reverted
    await expect(engineService.verifyCreateParams(engineTy, [tankVolume, 0])).to.be.reverted
  })
  it('should correctly verify electric car engine data', async function () {
    let fromEmptyToTwenty = 10
    let fromTwentyOneToFifty = 20
    let fromFiftyOneToEighty = 30
    let fromEightyOneToOneHundred = 50
    let engineTy = await elEngine.getEType()

    await expect(
      engineService.verifyCreateParams(engineTy, [
        fromEmptyToTwenty,
        fromTwentyOneToFifty,
        fromFiftyOneToEighty,
        fromEightyOneToOneHundred,
      ])
    ).to.not.reverted
    await expect(
      engineService.verifyCreateParams(engineTy, [
        fromTwentyOneToFifty,
        fromFiftyOneToEighty,
        fromEightyOneToOneHundred,
      ])
    ).to.be.reverted
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
    let oldParams = [1, 2, 3, 4]
    let engineTy = await elEngine.getEType()

    let newParams = [5, 6, 7, 9]

    await expect(engineService.verifyUpdateParams(engineTy, [0, 0, 0], [1, 1, 1, 1])).to.be.reverted

    let newVeryfParams = await engineService.verifyUpdateParams(engineTy, newParams, oldParams)

    expect(newVeryfParams[0]).to.be.eq(newParams[0])
    expect(newVeryfParams[1]).to.be.eq(newParams[1])
    expect(newVeryfParams[2]).to.be.eq(newParams[2])
    expect(newVeryfParams[3]).to.be.eq(newParams[3])
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
      let fuelPrices = [300] // Assuming fuel price in USD cents
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
      let fuelPrices = [300] // Assuming fuel price in USD cents
      let carId = 1
      let milesIncludedPerDay = 50
      let pricePerDayInUsdCents = 100
      let tripDays = 3

      let fromEmptyToTwenty = 10
      let fromTwentyOneToFifteen = 20
      let fromFifteenToOneEighteen = 30
      let fromEighteenToOneHundred = 50
      let engineTy = await elEngine.getEType()

      let engineParams = [fromEmptyToTwenty, fromTwentyOneToFifteen, fromFifteenToOneEighteen, fromEighteenToOneHundred]

      let expectedFuelRefund = fromEmptyToTwenty

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

    it('should correctly compute end params', async function () {
      const createCarRequest = getMockCarRequest(0)
      await expect(rentalityGateway.connect(host).addCar(createCarRequest)).not.to.be.reverted

      const oneDayInSeconds = 24 * 60 * 60
      const rentPriceInUsdCents = 1000
      const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
        await rentalityCurrencyConverter.getFromUsdLatest(nativeToken,rentPriceInUsdCents)

      const blockNumBefore = await ethers.provider.getBlockNumber()
      const blockBefore = await ethers.provider.getBlock(blockNumBefore)
      const timestampBefore = blockBefore.timestamp

      await expect(
        rentalityGateway.connect(guest).createTripRequest(
          {
            carId: 1,
            host: host.address,
            startDateTime: timestampBefore,
            endDateTime: timestampBefore + oneDayInSeconds * 2,
            startLocation: '',
            endLocation: '',
            totalDayPriceInUsdCents: rentPriceInUsdCents,
            taxPriceInUsdCents: 0,
            depositInUsdCents: 0,
            currencyRate: ethToCurrencyRate,
            currencyDecimals: ethToCurrencyDecimals,
            currencyType: nativeToken
          },
          { value: rentPriceInEth }
        )
      ).to.not.reverted
      expect(await rentalityGateway.connect(host).approveTripRequest(1)).not.be.reverted

      await expect(rentalityGateway.connect(host).checkInByHost(1, [10, 0])).not.be.reverted

      await expect(rentalityGateway.connect(guest).checkInByGuest(1, [10, 0])).not.be.reverted

      await network.provider.send('evm_setNextBlockTimestamp', [timestampBefore + oneDayInSeconds * 3])

      await expect(rentalityGateway.connect(admin).callOutdated()).not.be.reverted

      const trip = await rentalityTripService.getTrip(1)
      expect(trip.startParamLevels[0]).to.be.eq(trip.endParamLevels[0])
      expect(trip.startParamLevels[1]).to.be.eq(trip.endParamLevels[1])
    })
  })
})
