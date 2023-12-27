const { expect } = require('chai')
const { ethers } = require('hardhat')
const {
  time,
  loadFixture,
} = require('@nomicfoundation/hardhat-network-helpers')
const { Contract } = require('hardhat/internal/hardhat-network/stack-traces/model')
const { getMockCarRequest, TripStatus, getEmptySearchCarParams } = require('./utils')

async function deployDefaultFixture() {
  const [owner, admin, manager, host, guest, anonymous] =
    await ethers.getSigners()

  const RentalityUtils = await ethers.getContractFactory('RentalityUtils')
  const utils = await RentalityUtils.deploy()
  const RentalityMockPriceFeed = await ethers.getContractFactory(
    'RentalityMockPriceFeed',
  )
  const RentalityUserService = await ethers.getContractFactory(
    'RentalityUserService',
  )
  const RentalityTripService = await ethers.getContractFactory(
    'RentalityTripService',
    { libraries: { RentalityUtils: utils.address } },
  )
  const RentalityCurrencyConverter = await ethers.getContractFactory(
    'RentalityCurrencyConverter',
  )
  const RentalityPaymentService = await ethers.getContractFactory(
    'RentalityPaymentService',
  )
  const RentalityCarToken =
    await ethers.getContractFactory('RentalityCarToken')

  const RentalityPlatform =
    await ethers.getContractFactory('RentalityPlatform',
      {
        libraries:
          {
            RentalityUtils: utils.address,
          },
      })
  const RentalityGeoService =
    await ethers.getContractFactory('RentalityGeoMock')

  let RentalityGateway = await ethers.getContractFactory(
    'RentalityGateway',
    {
      libraries:
        {
          RentalityUtils: utils.address,
        },
    },
  )

  let rentalityMockPriceFeed = await RentalityMockPriceFeed.deploy(
    8,
    200000000000,
  )
  await rentalityMockPriceFeed.deployed()

  const rentalityUserService = await RentalityUserService.deploy()
  await rentalityUserService.deployed()

  const electricEngine = await ethers.getContractFactory('RentalityElectricEngine')
  const elEngine = await electricEngine.deploy(rentalityUserService.address)

  const patrolEngine = await ethers.getContractFactory('RentalityPatrolEngine')
  const pEngine = await patrolEngine.deploy(rentalityUserService.address)

  const hybridEngine = await ethers.getContractFactory('RentalityHybridEngine')
  const hEngine = await hybridEngine.deploy(rentalityUserService.address)

  const EngineService = await ethers.getContractFactory('RentalityEnginesService')
  const engineService = await EngineService.deploy(
    rentalityUserService.address,
    [pEngine.address, elEngine.address, hEngine.address],
  )
  await engineService.deployed()

  await rentalityUserService.connect(owner).grantAdminRole(admin.address)
  await rentalityUserService.connect(owner).grantManagerRole(manager.address)
  await rentalityUserService.connect(owner).grantHostRole(host.address)
  await rentalityUserService.connect(owner).grantGuestRole(guest.address)

  const rentalityCurrencyConverter = await RentalityCurrencyConverter.deploy(
    rentalityMockPriceFeed.address,
  )
  await rentalityCurrencyConverter.deployed()
  const rentalityGeoService = await RentalityGeoService.deploy()
  await rentalityGeoService.deployed()

  const rentalityCarToken = await RentalityCarToken.deploy(rentalityGeoService.address, engineService.address)
  await rentalityCarToken.deployed()
  const rentalityPaymentService = await RentalityPaymentService.deploy(rentalityUserService.address)
  await rentalityPaymentService.deployed()

  const rentalityTripService = await RentalityTripService.deploy(
    rentalityCurrencyConverter.address,
    rentalityCarToken.address,
    rentalityPaymentService.address,
    rentalityUserService.address,
    engineService.address,
  )
  await rentalityTripService.deployed()

  const rentalityPlatform = await RentalityPlatform.deploy(
    rentalityCarToken.address,
    rentalityCurrencyConverter.address,
    rentalityTripService.address,
    rentalityUserService.address,
    rentalityPaymentService.address,
  )
  await rentalityPlatform.deployed()

  await rentalityUserService
    .connect(owner)
    .grantHostRole(rentalityPlatform.address)
  await rentalityUserService.connect(owner).grantManagerRole(rentalityPlatform.address)
  await rentalityUserService
    .connect(owner)
    .grantManagerRole(rentalityTripService.address)
  await rentalityUserService.connect(owner).grantManagerRole(rentalityPlatform.address)

  let rentalityGateway = await RentalityGateway.connect(owner).deploy(
    rentalityCarToken.address,
    rentalityCurrencyConverter.address,
    rentalityTripService.address,
    rentalityUserService.address,
    rentalityPlatform.address,
    rentalityPaymentService.address,
  )
  await rentalityGateway.deployed()

  await rentalityUserService.connect(owner).grantManagerRole(rentalityGateway.address)
  await rentalityUserService.connect(owner).grantAdminRole(rentalityGateway.address)
  await rentalityUserService
    .connect(owner)
    .grantManagerRole(rentalityCarToken.address)
  await rentalityUserService
    .connect(owner)
    .grantManagerRole(engineService.address)

  return {
    rentalityGateway,
    rentalityMockPriceFeed,
    rentalityUserService,
    rentalityTripService,
    rentalityCurrencyConverter,
    rentalityCarToken,
    rentalityPaymentService,
    rentalityPlatform,
    engineService,
    elEngine,
    pEngine,
    hEngine,
    owner,
    admin,
    manager,
    host,
    guest,
    anonymous,
  }
}


describe('RentalityEngines', function() {

  let rentalityGateway,
    rentalityMockPriceFeed,
    rentalityUserService,
    rentalityTripService,
    rentalityCurrencyConverter,
    rentalityCarToken,
    rentalityPaymentService,
    rentalityPlatform,
    engineService,
    elEngine,
    pEngine,
    hEngine,
    owner,
    admin,
    manager,
    host,
    guest,
    anonymous

  beforeEach(async function() {
    ({
      rentalityGateway,
      rentalityMockPriceFeed,
      rentalityUserService,
      rentalityTripService,
      rentalityCurrencyConverter,
      rentalityCarToken,
      rentalityPaymentService,
      rentalityPlatform,
      engineService,
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

  it('should correctly add car patrol engine data', async function() {
    let tankVolume = 15
    let fuelPrice = 375
    let engineTy = await pEngine.getEType()

    await expect(engineService.addCar(1, engineTy, [tankVolume, fuelPrice]))
      .to.not.reverted

    let data = await pEngine.getEngineData(1)

    expect(data.tankVolumeInGal).to.be.eq(tankVolume)
    expect(data.fuelPricePerGalInUsdCents).to.be.eq(fuelPrice)

  })
  it('should correctly add electric car engine data', async function() {
    let fromEmptyToTwenty = 10
    let fromTwentyOneToFifty = 20
    let fromFiftyOneToEighty = 30
    let fromEightyOneToOneHundred = 50
    let engineTy = await elEngine.getEType()

    await expect(
      engineService.addCar(1, engineTy, [
        fromEmptyToTwenty,
        fromTwentyOneToFifty,
        fromFiftyOneToEighty,
        fromEightyOneToOneHundred,
      ]),
    ).to.not.reverted

    let data = await elEngine.getEngineData(1)

    expect(data.fromEmptyToTwenty).to.be.eq(fromEmptyToTwenty)
    expect(data.fromTwentyOneToFifty).to.be.eq(fromTwentyOneToFifty)
    expect(data.fromFiftyOneToEighty).to.be.eq(fromFiftyOneToEighty)
    expect(data.fromEightyOneToOneHundred).to.be.eq(fromEightyOneToOneHundred)
  })
  it('should correctly add hybrid car engine data', async function() {

    let tankVolume = 15
    let fuelPrice = 375
    let engineTy = await hEngine.getEType()

    await expect(engineService.addCar(1, engineTy, [tankVolume, fuelPrice]))
      .to.not.reverted

    let data = await hEngine.getEngineData(1)

    expect(data.tankVolumeInGal).to.be.eq(tankVolume)
    expect(data.fuelPricePerGalInUsdCents).to.be.eq(fuelPrice)
  })
  it('should correctly update patrol car engine data', async function() {

    let tankVolume = 50
    let fuelPrice = 375
    let engineTy = await pEngine.getEType()

    await expect(engineService.addCar(1, engineTy, [tankVolume, fuelPrice]))
      .to.not.reverted

    let data = await pEngine.getEngineData(1)

    expect(data.tankVolumeInGal).to.be.eq(tankVolume)
    expect(data.fuelPricePerGalInUsdCents).to.be.eq(fuelPrice)

    await expect(engineService.updateCar(1, engineTy, [0]))
      .to.be.reverted

    let newFprice = 1

    await expect(engineService.updateCar(1, engineTy, [newFprice]))
      .to.not.reverted

    let data1 = await pEngine.getEngineData(1)

    expect(data1.fuelPricePerGalInUsdCents).to.be.eq(newFprice)
  })
  it('should correctly update electric car engine data', async function() {

    let fromEmptyToTwenty = 10
    let fromTwentyOneToFifty = 20
    let fromFiftyOneToEighty = 30
    let fromEightyOneToOneHundred = 50
    let engineTy = await elEngine.getEType()

    await expect(
      engineService.addCar(1, engineTy, [
        fromEmptyToTwenty,
        fromTwentyOneToFifty,
        fromFiftyOneToEighty,
        fromEightyOneToOneHundred,
      ]),
    ).to.not.reverted

    let data = await elEngine.getEngineData(1)

    expect(data.fromEmptyToTwenty).to.be.eq(fromEmptyToTwenty)
    expect(data.fromTwentyOneToFifty).to.be.eq(fromTwentyOneToFifty)
    expect(data.fromFiftyOneToEighty).to.be.eq(fromFiftyOneToEighty)
    expect(data.fromEightyOneToOneHundred).to.be.eq(fromEightyOneToOneHundred)

    let newFromEmptyToTwenty = 15
    let newFromTwentyOneToFifty = 25
    let newFromFiftyOneToEighty = 35
    let newFromEightyOneToOneHundred = 55

    await expect(
      engineService.updateCar(1, engineTy, [
        newFromEmptyToTwenty,
        newFromTwentyOneToFifty,
        newFromFiftyOneToEighty,
        newFromEightyOneToOneHundred,
      ]),
    ).to.not.reverted

    let newData = await elEngine.getEngineData(1)

    expect(newData.fromEmptyToTwenty).to.be.eq(newFromEmptyToTwenty)
    expect(newData.fromTwentyOneToFifty).to.be.eq(newFromTwentyOneToFifty)
    expect(newData.fromFiftyOneToEighty).to.be.eq(newFromFiftyOneToEighty)
    expect(newData.fromEightyOneToOneHundred).to.be.eq(
      newFromEightyOneToOneHundred,
    )
  })
  it('should correctly update hybrid car engine data', async function() {


    let tankVolume = 50
    let fuelPrice = 375
    let engineTy = await hEngine.getEType()

    await expect(engineService.addCar(1, engineTy, [tankVolume, fuelPrice]))
      .to.not.reverted

    let data = await hEngine.getEngineData(1)

    expect(data.tankVolumeInGal).to.be.eq(tankVolume)
    expect(data.fuelPricePerGalInUsdCents).to.be.eq(fuelPrice)

    await expect(engineService.updateCar(1, engineTy, [0]))
      .to.be.reverted

    let newFprice = 1

    await expect(engineService.updateCar(1, engineTy, [newFprice]))
      .to.not.reverted

    let data1 = await hEngine.getEngineData(1)

    expect(data1.fuelPricePerGalInUsdCents).to.be.eq(newFprice)
  })
  it('should correctly burn patrol car engine data', async function() {


    let tankVolume = 50
    let fuelPrice = 375
    let engineTy = await pEngine.getEType()

    await expect(engineService.addCar(1, engineTy, [tankVolume, fuelPrice]))
      .to.not.reverted

    let data = await pEngine.getEngineData(1)

    expect(data.tankVolumeInGal).to.be.eq(tankVolume)
    expect(data.fuelPricePerGalInUsdCents).to.be.eq(fuelPrice)


    await expect(engineService.burnCar(1, engineTy))
      .to.not.reverted

    let data1 = await pEngine.getEngineData(1)

    expect(data1.fuelPricePerGalInUsdCents).to.be.eq(0)
  })
  it('should correctly burn electric car engine data', async function() {


    let fromEmptyToTwenty = 10
    let fromTwentyOneToFifty = 20
    let fromFiftyOneToEighty = 30
    let fromEightyOneToOneHundred = 50
    let engineTy = await elEngine.getEType()

    await expect(
      engineService.addCar(1, engineTy, [
        fromEmptyToTwenty,
        fromTwentyOneToFifty,
        fromFiftyOneToEighty,
        fromEightyOneToOneHundred,
      ]),
    ).to.not.reverted

    let data = await elEngine.getEngineData(1)

    expect(data.fromEmptyToTwenty).to.be.eq(fromEmptyToTwenty)
    expect(data.fromTwentyOneToFifty).to.be.eq(fromTwentyOneToFifty)
    expect(data.fromFiftyOneToEighty).to.be.eq(fromFiftyOneToEighty)
    expect(data.fromEightyOneToOneHundred).to.be.eq(fromEightyOneToOneHundred)

    await expect(engineService.burnCar(1, engineTy)).to.not.reverted

    let newData = await elEngine.getEngineData(1)

    expect(newData.fromEmptyToTwenty).to.be.eq(0)
    expect(newData.fromTwentyOneToFifty).to.be.eq(0)
    expect(newData.fromFiftyOneToEighty).to.be.eq(0)
    expect(newData.fromEightyOneToOneHundred).to.be.eq(0)
  })
  it('should correctly burn hybrid car engine data', async function() {


    let tankVolume = 50
    let fuelPrice = 375
    let engineTy = await hEngine.getEType()

    await expect(engineService.addCar(1, engineTy, [tankVolume, fuelPrice]))
      .to.not.reverted

    let data = await hEngine.getEngineData(1)

    expect(data.tankVolumeInGal).to.be.eq(tankVolume)
    expect(data.fuelPricePerGalInUsdCents).to.be.eq(fuelPrice)


    await expect(engineService.burnCar(1, engineTy))
      .to.not.reverted

    let data1 = await hEngine.getEngineData(1)

    expect(data1.fuelPricePerGalInUsdCents).to.be.eq(0)
  })
  describe('Access control tests', function() {
    it('revert if not manager add patrol car', async function() {

      let tankVolume = 50
      let fuelPrice = 375
      let engineTy = await pEngine.getEType()

      await expect(engineService.connect(anonymous).addCar(1, engineTy, [tankVolume, fuelPrice]))
        .to.be.revertedWith('Only for Manager.')
      await expect(engineService.connect(host).addCar(1, engineTy, [tankVolume, fuelPrice]))
        .to.be.revertedWith('Only for Manager.')
      await expect(engineService.connect(guest).addCar(1, engineTy, [tankVolume, fuelPrice]))
        .to.be.revertedWith('Only for Manager.')
    })
    it('revert if not manager add hybrid car', async function() {
      let tankVolume = 50
      let fuelPrice = 375
      let engineTy = await hEngine.getEType()

      await expect(engineService.connect(anonymous).addCar(1, engineTy, [tankVolume, fuelPrice]))
        .to.be.revertedWith('Only for Manager.')
      await expect(engineService.connect(host).addCar(1, engineTy, [tankVolume, fuelPrice]))
        .to.be.revertedWith('Only for Manager.')
      await expect(engineService.connect(guest).addCar(1, engineTy, [tankVolume, fuelPrice]))
        .to.be.revertedWith('Only for Manager.')
    })
    it('revert if not manager add electric car', async function() {

      let fromEmptyToTwenty = 10
      let fromTwentyOneToFifty = 20
      let fromFiftyOneToEighty = 30
      let fromEightyOneToOneHundred = 50
      let engineTy = await elEngine.getEType()

      await expect(
        engineService
          .connect(anonymous)
          .addCar(1, engineTy, [
            fromEmptyToTwenty,
            fromTwentyOneToFifty,
            fromFiftyOneToEighty,
            fromEightyOneToOneHundred,
          ]),
      ).to.be.revertedWith('Only for Manager.')
      await expect(
        engineService
          .connect(guest)
          .addCar(1, engineTy, [
            fromEmptyToTwenty,
            fromTwentyOneToFifty,
            fromFiftyOneToEighty,
            fromEightyOneToOneHundred,
          ]),
      ).to.be.revertedWith('Only for Manager.')

      await expect(
        engineService
          .connect(host)
          .addCar(1, engineTy, [
            fromEmptyToTwenty,
            fromTwentyOneToFifty,
            fromFiftyOneToEighty,
            fromEightyOneToOneHundred,
          ]),
      ).to.be.revertedWith('Only for Manager.')
    })
  })
  describe('Correct params', function() {
    it('should correctly verify start params', async function() {
      let engineTy = await pEngine.getEType()
      let correctParams = [10, 5]
      let wrongParams1 = [0]
      let wrongParams2 = [1, 2, 4, 5, 6]
      let wrongParams3 = [-1, 2]
      let wrongParams4 = [101, 15]

      await expect(engineService.verifyStartParams(wrongParams1, engineTy)).to.be.reverted
      await expect(engineService.verifyStartParams(wrongParams2, engineTy)).to.be.reverted
      await expect(engineService.verifyStartParams(wrongParams3, engineTy)).to.be.reverted
      await expect(engineService.verifyStartParams(wrongParams4, engineTy)).to.be.reverted
      await expect(engineService.verifyStartParams(correctParams, engineTy)).to.not.reverted
    })
    it('should correctly verify end params', async function() {

      let engineTy = await elEngine.getEType()
      let correctStartParams = [10, 5]
      let correctEndParams = [15,6]
      let wrongStartParams1 = [0]
      let wrongEndParams1 = [10,2]
      let wrongStartParams2 = [10,16]
      let wrongEndParams2 = [101,15]
      let wrongStartParams3 = [10,16]
      let wrongEndParams3 = [10,15]

      await expect(engineService.verifyEndParams(wrongStartParams1, wrongEndParams1, engineTy)).to.be.reverted
      await expect(engineService.verifyEndParams(wrongStartParams2, wrongEndParams2, engineTy)).to.be.reverted
      await expect(engineService.verifyEndParams(wrongStartParams3,wrongEndParams3 ,engineTy)).to.be.reverted
      await expect(engineService.verifyEndParams(correctStartParams, correctEndParams, engineTy)).to.not.reverted
    })
    it('should correctly compare params', async function() {

      let engineTy = await hEngine.getEType()
      let correctStartParams = [10, 10]
      let correctEndParams = [10,10]
      let wrongStartParams1 = [10]
      let wrongEndParams1 = [10,15]
      let wrongStartParams2 = [15,15]
      let wrongEndParams2 = [15,14]


      await expect(engineService.compareParams(wrongStartParams1, wrongEndParams1, engineTy)).to.be.reverted
      await expect(engineService.compareParams(wrongStartParams2, wrongEndParams2, engineTy)).to.be.reverted
      await expect(engineService.compareParams(correctStartParams, correctEndParams, engineTy)).to.not.reverted
    })
    })
  describe('Computation', function() {
    it('should correctly compute patrol refund', async function() {

      let startParams = [50, 100]; // Assuming startFuelLevelInPercents and startOdometr
      let endParams = [20, 200]; // Assuming endFuelLevelInPercents and endOdometr
      let fuelPrices = [300]; // Assuming fuel price in USD cents
      let carId = 1;
      let milesIncludedPerDay = 50;
      let pricePerDayInUsdCents = 100;
      let tripDays = 3;


      // Set patrol engine data for the car
      let tankVolume = 15;
      let fuelPrice = 375;
      let engineTy = await pEngine.getEType();
      await engineService.addCar(carId, engineTy, [tankVolume, fuelPrice]);

      let expectedFuelRefund = ((50 - 20)/*difference in percents*/
      * tankVolume / 100) /*compute difference in gallons*/
      * 300 /* compute refund in usd cents by price*/

     let result = await engineService.callStatic.getResolveAmountInUsdCents(
        engineTy,
        fuelPrices,
        startParams,
        endParams,
        carId,
        milesIncludedPerDay,
        pricePerDayInUsdCents,
        tripDays
      );
     expect(result[1]).to.be.eq(expectedFuelRefund);

    })
    it('should correctly compute electric refund', async function() {

      let startParams = [50, 100]; // Assuming startFuelLevelInPercents and startOdometr
      let endParams = [20, 200]; // Assuming endFuelLevelInPercents and endOdometr
      let fuelPrices = [300]; // Assuming fuel price in USD cents
      let carId = 1;
      let milesIncludedPerDay = 50;
      let pricePerDayInUsdCents = 100;
      let tripDays = 3;


      let fromEmptyToTwenty = 10
      let fromTwentyOneToFifteen = 20
      let fromFifteenToOneEighteen = 30
      let fromEighteenToOneHundred = 50
      let engineTy = await elEngine.getEType()

      await expect(engineService.addCar(1, engineTy, [
        fromEmptyToTwenty,
        fromTwentyOneToFifteen,
        fromFifteenToOneEighteen,
        fromEighteenToOneHundred,
      ]))
        .to.not.reverted

      let expectedFuelRefund = fromEmptyToTwenty;

      let result = await engineService.callStatic.getResolveAmountInUsdCents(
        engineTy,
        fuelPrices,
        startParams,
        endParams,
        carId,
        milesIncludedPerDay,
        pricePerDayInUsdCents,
        tripDays
      );
      expect(result[1]).to.be.eq(expectedFuelRefund);

    })
  })
})