const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { expect } = require('chai')
const { getMockCarRequest, deployDefaultFixture, ethToken, getEmptySearchCarParams, emptyLocationInfo, emptySignedLocationInfo } = require('../utils')
const { ethers } = require('hardhat')

describe('Rentality investment', function () {
  let rentalityGateway,
    rentalityMockPriceFeed,
    rentalityUserService,
    rentalityTripService,
    rentalityCurrencyConverter,
    rentalityCarToken,
    rentalityPaymentService,
    rentalityPlatform,
    rentalityGeoService,
    rentalityAdminGateway,
    utils,
    claimService,
    owner,
    admin,
    manager,
    host,
    guest,
    anonymous,
    investorsService,
    rentalityLocationVerifier,
    rentalityView

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
      rentalityGeoService,
      rentalityAdminGateway,
      utils,
      claimService,
      owner,
      admin,
      manager,
      host,
      guest,
      anonymous,
      investorsService,
      rentalityLocationVerifier,
      rentalityView
    } = await loadFixture(deployDefaultFixture))

})
  it('Host can create investment', async function () {

    let mockCarInvestment = {
      car: getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin),
      priceInUsd: 10000,
      inProgress: true,
      creatorPercents: 10,
    }
    await expect(await investorsService.connect(host).createCarInvestment(mockCarInvestment, 'name', 'sym')).to.not
      .reverted
  })
  it('Guest can invest', async function () {
    let mockCarInvestment = {
      car: getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin),
      priceInUsd: 10000,
      inProgress: true,
      creatorPercents: 10,
    }
    await expect(await investorsService.connect(host).createCarInvestment(mockCarInvestment, 'name', 'sym')).to.not
      .reverted

    await expect(investorsService.connect(guest).invest(1, { value: 10000 })).to.not.reverted
    let investment = await investorsService.getAllInvestments()
  })
  it('Possible to create car after investment', async function () {
    let mockCarInvestment = {
      car: getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin),
      priceInUsd: 10000,
      inProgress: true,
      creatorPercents: 10,
    }
    await expect(await investorsService.connect(host).createCarInvestment(mockCarInvestment, 'name', 'sym')).to.not
      .reverted

    let fromUsd = await rentalityCurrencyConverter.getFromUsdLatest(ethToken, mockCarInvestment.priceInUsd)
    await expect(investorsService.connect(guest).invest(1, { value: fromUsd[0] })).to.not.reverted

    await expect(investorsService.connect(host).claimAndCreatePool(1)).to.not.reverted
    let cars = await rentalityView
    .connect(guest)
    .searchAvailableCarsWithDelivery(
      0,
      new Date().getSeconds() + 86400,
      getEmptySearchCarParams(1),
      emptyLocationInfo,
      emptyLocationInfo
    )
    expect(cars.length).to.be.eq(1)
  })

  it('Has claims after pool creating', async function () {
    let mockCarInvestment = {
      car: getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin),
      priceInUsd: 10000,
      inProgress: true,
      creatorPercents: 10,
    }
    await expect(await investorsService.connect(host).createCarInvestment(mockCarInvestment, 'name', 'sym')).to.not
      .reverted

    let fromUsd = await rentalityCurrencyConverter.getFromUsdLatest(ethToken, mockCarInvestment.priceInUsd)
    await expect(investorsService.connect(guest).invest(1, { value: fromUsd[0] })).to.not.reverted

    await expect(investorsService.connect(host).claimAndCreatePool(1)).to.not.reverted

    let claimsGuestCanDo = await investorsService.connect(guest).getAllInvestments()
    expect(claimsGuestCanDo[0].isCarBought).to.be.eq(true)
  })

  it('Happy case with investors car', async function () {
    let mockCarInvestment = {
      car: getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin),
      priceInUsd: 10000,
      inProgress: true,
      creatorPercents: 10,
    }
    await expect(await investorsService.connect(host).createCarInvestment(mockCarInvestment, 'name', 'sym')).to.not
      .reverted

    let fromUsd = await rentalityCurrencyConverter.getFromUsdLatest(ethToken, mockCarInvestment.priceInUsd)
    await expect(investorsService.connect(guest).invest(1, { value: fromUsd[0] })).to.not.reverted

    await expect(investorsService.connect(host).claimAndCreatePool(1)).to.not.reverted
    let cars =  await rentalityView
      .connect(guest)
      .searchAvailableCarsWithDelivery(
        0,
        new Date().getSeconds() + 86400,
        getEmptySearchCarParams(1),
        emptyLocationInfo,
        emptyLocationInfo
      )
    expect(cars.length).to.be.eq(1)

    const oneDayInSeconds = 86400
    let result = await rentalityGateway.calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, ' ')
    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
" ",
        { value: result[0]}
      )
    ).to.not.reverted
    await expect(rentalityPlatform.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityPlatform.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityPlatform.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityPlatform.connect(guest).checkOutByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityPlatform.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted

    await expect(await rentalityPlatform.connect(host).finishTrip(1)).to.not.reverted

    let claimsGuestCanDo = await investorsService.connect(guest).getAllInvestments()
    expect(claimsGuestCanDo[0].isCarBought).to.be.eq(true)
  })

  it('Investor can claim after income', async function () {
    let mockCarInvestment = {
      car: getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin),
      priceInUsd: 10000,
      inProgress: true,
      creatorPercents: 10,
    }
    await expect(await investorsService.connect(host).createCarInvestment(mockCarInvestment, 'name', 'sym')).to.not
      .reverted

    let fromUsd = await rentalityCurrencyConverter.getFromUsdLatest(ethToken, mockCarInvestment.priceInUsd)
    await expect(investorsService.connect(guest).invest(1, { value: fromUsd[0] })).to.not.reverted

    await expect(investorsService.connect(host).claimAndCreatePool(1)).to.not.reverted
    let cars =  await rentalityView
      .connect(guest)
      .searchAvailableCarsWithDelivery(
        0,
        new Date().getSeconds() + 86400,
        getEmptySearchCarParams(1),
        emptyLocationInfo,
        emptyLocationInfo
      )
    expect(cars.length).to.be.eq(1)

    const oneDayInSeconds = 86400

    let result = await rentalityGateway.calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, ' ')

    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },"",
        { value: result[0] }
      )
    ).to.not.reverted

    await expect(rentalityPlatform.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityPlatform.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityPlatform.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityPlatform.connect(guest).checkOutByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityPlatform.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted

    await expect(await rentalityPlatform.connect(host).finishTrip(1)).to.not.reverted

    let claimsGuestCanDo = await investorsService.connect(guest).getAllInvestments()
    expect(claimsGuestCanDo[0].isCarBought).to.be.eq(true)

    await expect(investorsService.connect(guest).claimAllMy(1)).to.changeEtherBalance(guest, 7200000000000)
  })
  it('Can not claim twice', async function () {
    let mockCarInvestment = {
      car: getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin),
      priceInUsd: 10000,
      inProgress: true,
      creatorPercents: 10,
    }
    await expect(await investorsService.connect(host).createCarInvestment(mockCarInvestment, 'name', 'sym')).to.not
      .reverted

    let fromUsd = await rentalityCurrencyConverter.getFromUsdLatest(ethToken, mockCarInvestment.priceInUsd)
    await expect(investorsService.connect(guest).invest(1, { value: fromUsd[0] })).to.not.reverted

    await expect(investorsService.connect(host).claimAndCreatePool(1)).to.not.reverted
    let cars =  await rentalityView
      .connect(guest)
      .searchAvailableCarsWithDelivery(
        0,
        new Date().getSeconds() + 86400,
        getEmptySearchCarParams(1),
        emptyLocationInfo,
        emptyLocationInfo
      )
    expect(cars.length).to.be.eq(1)

    const oneDayInSeconds = 86400

    let result = await rentalityGateway.calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, ' ')

    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds ,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        "",
        { value: result[0] }
      )
    ).to.not.reverted

    await expect(rentalityPlatform.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityPlatform.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityPlatform.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityPlatform.connect(guest).checkOutByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityPlatform.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted

    await expect(await rentalityPlatform.connect(host).finishTrip(1)).to.not.reverted

    let claimsGuestCanDo = await investorsService.connect(guest).getAllInvestments()
    expect(claimsGuestCanDo[0].isCarBought).to.be.eq(true)

    await expect(investorsService.connect(guest).claimAllMy(1)).to.changeEtherBalance(guest, 7200000000000)
    await expect(investorsService.connect(guest).claimAllMy(1)).to.to.changeEtherBalance(guest, 0)
  })
  it('Calculation test: 1 investor has 2 investments', async function () {
    let mockCarInvestment = {
      car: getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin),
      priceInUsd: 10000,
      inProgress: true,
      creatorPercents: 10,
    }
    mockCarInvestment.car.pricePerDayInUsdCents = 10000
    await expect(await investorsService.connect(host).createCarInvestment(mockCarInvestment, 'name', 'sym')).to.not
      .reverted

    let fromUsd = await rentalityCurrencyConverter.getFromUsdLatest(ethToken, mockCarInvestment.priceInUsd)
    await expect(investorsService.connect(guest).invest(1, { value: fromUsd[0] / BigInt(2) })).to.not.reverted

    await expect(investorsService.connect(guest).invest(1, { value: fromUsd[0] / BigInt(2) })).to.not.reverted

    await expect(investorsService.connect(host).claimAndCreatePool(1)).to.not.reverted
    let cars =  await rentalityView
      .connect(guest)
      .searchAvailableCarsWithDelivery(
        0,
        new Date().getSeconds() + 86400,
        getEmptySearchCarParams(1),
        emptyLocationInfo,
        emptyLocationInfo
      )
    expect(cars.length).to.be.eq(1)

    let priceForDayInETH = await rentalityCurrencyConverter.getFromUsdLatest(
      ethToken,
      mockCarInvestment.car.pricePerDayInUsdCents - (mockCarInvestment.car.pricePerDayInUsdCents / 100) * 20
    )

    const oneDayInSeconds = 86400

    let result = await rentalityGateway.calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, ' ')

    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
" ",
        { value: result[0]}
      )
    ).to.not.reverted

    await expect(rentalityPlatform.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityPlatform.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityPlatform.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityPlatform.connect(guest).checkOutByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityPlatform.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted

    await expect(await rentalityPlatform.connect(host).finishTrip(1)).to.changeEtherBalance(
      host,
      priceForDayInETH[0] / BigInt(10)
    )

    await expect(investorsService.connect(guest).claimAllMy(1)).to.changeEtherBalance(
      guest,
      priceForDayInETH[0] - priceForDayInETH[0] / BigInt(10)
    )
  })
  it('Calculation test: 1 investor has 2 investments and 3 finished trips', async function () {
    let mockCarInvestment = {
      car: getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin),
      priceInUsd: 10000,
      inProgress: true,
      creatorPercents: 10,
    }
    mockCarInvestment.car.pricePerDayInUsdCents = 10000
    await expect(await investorsService.connect(host).createCarInvestment(mockCarInvestment, 'name', 'sym')).to.not
      .reverted

    let fromUsd = await rentalityCurrencyConverter.getFromUsdLatest(ethToken, mockCarInvestment.priceInUsd)
    await expect(investorsService.connect(guest).invest(1, { value: fromUsd[0] / BigInt(2) })).to.not.reverted

    await expect(investorsService.connect(guest).invest(1, { value: fromUsd[0] / BigInt(2) })).to.not.reverted

    await expect(investorsService.connect(host).claimAndCreatePool(1)).to.not.reverted
    let cars =  await rentalityView
      .connect(guest)
      .searchAvailableCarsWithDelivery(
        0,
        new Date().getSeconds() + 86400,
        getEmptySearchCarParams(1),
        emptyLocationInfo,
        emptyLocationInfo
      )
    expect(cars.length).to.be.eq(1)

    let priceForDayInETH = await rentalityCurrencyConverter.getFromUsdLatest(
      ethToken,
      mockCarInvestment.car.pricePerDayInUsdCents - (mockCarInvestment.car.pricePerDayInUsdCents / 100) * 20
    )

    const oneDayInSeconds = 86400

    let result = await rentalityGateway.calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, ' ')

    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
" ",
        { value: result[0]}
      )
    ).to.not.reverted

    await expect(rentalityPlatform.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityPlatform.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityPlatform.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityPlatform.connect(guest).checkOutByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityPlatform.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted

    await expect(await rentalityPlatform.connect(host).finishTrip(1)).to.changeEtherBalance(
      host,
      priceForDayInETH[0] / BigInt(10)
    )
    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
" ",
        { value: result[0]}
      )
    ).to.not.reverted

    await expect(rentalityPlatform.connect(host).approveTripRequest(2)).not.to.be.reverted
    await expect(rentalityPlatform.connect(host).checkInByHost(2, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityPlatform.connect(guest).checkInByGuest(2, [0, 0])).not.to.be.reverted
    await expect(rentalityPlatform.connect(guest).checkOutByGuest(2, [0, 0])).not.to.be.reverted
    await expect(rentalityPlatform.connect(host).checkOutByHost(2, [0, 0])).not.to.be.reverted

    await expect(await rentalityPlatform.connect(host).finishTrip(2)).to.changeEtherBalance(
      host,
      priceForDayInETH[0] / BigInt(10)
    )

    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
" ",
        { value: result[0]}
      )
    ).to.not.reverted

    await expect(rentalityPlatform.connect(host).approveTripRequest(3)).not.to.be.reverted
    await expect(rentalityPlatform.connect(host).checkInByHost(3, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityPlatform.connect(guest).checkInByGuest(3, [0, 0])).not.to.be.reverted
    await expect(rentalityPlatform.connect(guest).checkOutByGuest(3, [0, 0])).not.to.be.reverted
    await expect(rentalityPlatform.connect(host).checkOutByHost(3, [0, 0])).not.to.be.reverted
    await expect(await rentalityPlatform.connect(host).finishTrip(3)).to.changeEtherBalance(
      host,
      priceForDayInETH[0] / BigInt(10)
    )

    await expect(investorsService.connect(guest).claimAllMy(1)).to.changeEtherBalance(
      guest,
      (priceForDayInETH[0] - priceForDayInETH[0] / BigInt(10)) * BigInt(3)
    )
  })

  it('Calculation test: 3 investors has 1 investments and 3 finished trips', async function () {
    let mockCarInvestment = {
      car: getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin),
      priceInUsd: 10000,
      inProgress: true,
      creatorPercents: 10,
    }
    mockCarInvestment.car.pricePerDayInUsdCents = 10000
    await expect(await investorsService.connect(host).createCarInvestment(mockCarInvestment, 'name', 'sym')).to.not
      .reverted

    let fromUsd = await rentalityCurrencyConverter.getFromUsdLatest(ethToken, mockCarInvestment.priceInUsd)
    await expect(investorsService.connect(guest).invest(1, { value: fromUsd[0] / BigInt(2) })).to.not.reverted

    await expect(investorsService.connect(anonymous).invest(1, { value: fromUsd[0] / BigInt(4) })).to.not.reverted

    await expect(investorsService.connect(manager).invest(1, { value: fromUsd[0] / BigInt(4) })).to.not.reverted

    await expect(investorsService.connect(host).claimAndCreatePool(1)).to.not.reverted
    let cars =  await rentalityView
      .connect(guest)
      .searchAvailableCarsWithDelivery(
        0,
        new Date().getSeconds() + 86400,
        getEmptySearchCarParams(1),
        emptyLocationInfo,
        emptyLocationInfo
      )
    expect(cars.length).to.be.eq(1)

    let priceForDayInETH = await rentalityCurrencyConverter.getFromUsdLatest(
      ethToken,
      mockCarInvestment.car.pricePerDayInUsdCents - (mockCarInvestment.car.pricePerDayInUsdCents / 100) * 20
    )

    const oneDayInSeconds = 86400

    let result = await rentalityGateway.calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, ' ')

    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
" ",
        { value: result[0]}
      )
    ).to.not.reverted

    await expect(rentalityPlatform.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityPlatform.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityPlatform.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityPlatform.connect(guest).checkOutByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityPlatform.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted

    await expect(await rentalityPlatform.connect(host).finishTrip(1)).to.changeEtherBalance(
      host,
      priceForDayInETH[0] / BigInt(10)
    )
    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
" ",
        { value: result[0]}
      )
    ).to.not.reverted

    await expect(rentalityPlatform.connect(host).approveTripRequest(2)).not.to.be.reverted
    await expect(rentalityPlatform.connect(host).checkInByHost(2, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityPlatform.connect(guest).checkInByGuest(2, [0, 0])).not.to.be.reverted
    await expect(rentalityPlatform.connect(guest).checkOutByGuest(2, [0, 0])).not.to.be.reverted
    await expect(rentalityPlatform.connect(host).checkOutByHost(2, [0, 0])).not.to.be.reverted

    await expect(await rentalityPlatform.connect(host).finishTrip(2)).to.changeEtherBalance(
      host,
      priceForDayInETH[0] / BigInt(10)
    )

    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
" ",
        { value: result[0]}
      )
    ).to.not.reverted

    await expect(rentalityPlatform.connect(host).approveTripRequest(3)).not.to.be.reverted
    await expect(rentalityPlatform.connect(host).checkInByHost(3, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityPlatform.connect(guest).checkInByGuest(3, [0, 0])).not.to.be.reverted
    await expect(rentalityPlatform.connect(guest).checkOutByGuest(3, [0, 0])).not.to.be.reverted
    await expect(rentalityPlatform.connect(host).checkOutByHost(3, [0, 0])).not.to.be.reverted

    await expect(await rentalityPlatform.connect(host).finishTrip(3)).to.changeEtherBalance(
      host,
      priceForDayInETH[0] / BigInt(10)
    )

    await expect(investorsService.connect(guest).claimAllMy(1)).to.changeEtherBalance(
      guest,
      ((priceForDayInETH[0] - priceForDayInETH[0] / BigInt(10)) * BigInt(3)) / BigInt(2)
    )

    await expect(investorsService.connect(anonymous).claimAllMy(1)).to.changeEtherBalance(
      anonymous,
      ((priceForDayInETH[0] - priceForDayInETH[0] / BigInt(10)) * BigInt(3)) / BigInt(4)
    )

    await expect(investorsService.connect(manager).claimAllMy(1)).to.changeEtherBalance(
      manager,
      ((priceForDayInETH[0] - priceForDayInETH[0] / BigInt(10)) * BigInt(3)) / BigInt(4)
    )
  })
  it('Nft transfer allow to claim for new owner', async function () {
    let mockCarInvestment = {
      car: getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin),
      priceInUsd: 10000,
      inProgress: true,
      creatorPercents: 10,
    }
    await expect(await investorsService.connect(host).createCarInvestment(mockCarInvestment, 'name', 'sym')).to.not
      .reverted

    let fromUsd = await rentalityCurrencyConverter.getFromUsdLatest(ethToken, mockCarInvestment.priceInUsd)
    await expect(investorsService.connect(guest).invest(1, { value: fromUsd[0] })).to.not.reverted

    await expect(investorsService.connect(host).claimAndCreatePool(1)).to.not.reverted
    let cars =  await rentalityView
      .connect(guest)
      .searchAvailableCarsWithDelivery(
        0,
        new Date().getSeconds() + 86400,
        getEmptySearchCarParams(1),
        emptyLocationInfo,
        emptyLocationInfo
      )
    expect(cars.length).to.be.eq(1)

    const oneDayInSeconds = 86400

    let result = await rentalityGateway.calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo, ' ')

    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
" ",
        { value: result[0]}
      )
    ).to.not.reverted

    await expect(rentalityPlatform.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityPlatform.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityPlatform.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityPlatform.connect(guest).checkOutByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityPlatform.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted

    await expect(await rentalityPlatform.connect(host).finishTrip(1)).to.not.reverted

    let claimsGuestCanDo = await investorsService.connect(guest).getAllInvestments()
    expect(claimsGuestCanDo[0].isCarBought).to.be.eq(true)

    let investments = await investorsService.getAllInvestments()
    let nft = await ethers.getContractAt('RentalityInvestmentNft', investments[0].nft)

    await expect(nft.connect(guest).transferFrom(guest.address, anonymous.address, 1)).to.not.reverted

    await expect(investorsService.connect(guest).claimAllMy(1)).to.changeEtherBalance(guest, 0)
    await expect(investorsService.connect(anonymous).claimAllMy(1)).to.to.changeEtherBalance(
      anonymous,
      BigInt(7200000000000)
    )
  })
})
