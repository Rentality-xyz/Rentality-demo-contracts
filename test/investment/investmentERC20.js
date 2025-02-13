const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { expect } = require('chai')
const { getMockCarRequest, deployDefaultFixture, ethToken, getEmptySearchCarParams, emptyLocationInfo, emptySignedLocationInfo } = require('../utils')
const { ethers } = require('hardhat')

describe('Rentality investment with erc20', function () {
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
    rentalityView,
    usdtContract

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
      rentalityView,
      usdtContract
    } = await loadFixture(deployDefaultFixture))

})
  it('Happy case with erc20', async function () {
    let usdt = await usdtContract.getAddress()
    await usdtContract.mint(guest.address, 100000000000000)
    let mockCarInvestment = {
        car: getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin),
        priceInUsd: 10000,
        inProgress: true,
        creatorPercents: 10,
      }
      mockCarInvestment.car.pricePerDayInUsdCents = 10000
      await expect(await investorsService.connect(host).createCarInvestment(mockCarInvestment, 'name',usdt)).to.not
        .reverted
  
      let fromUsd = await rentalityCurrencyConverter.getFromUsdLatest(usdt, mockCarInvestment.priceInUsd)
      
      await expect(investorsService.connect(guest).invest(1,fromUsd[0])).to.be.revertedWith('Investment: wrong allowance')
     
      await expect(usdtContract.connect(guest).approve(await investorsService.getAddress(), fromUsd[0])).to.not.reverted
      await expect(investorsService.connect(guest).invest(1, fromUsd[0])).to.not.reverted

      const balanceBeforeClaim = await usdtContract.balanceOf(host)
      await expect(investorsService.connect(host).claimAndCreatePool(1)).to.not.reverted
      const balanceAfterClaim = await usdtContract.balanceOf(host)
      expect(balanceBeforeClaim + fromUsd[0]).to.be.eq(balanceAfterClaim)

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
  
      let result = await rentalityGateway.calculatePaymentsWithDelivery(1, 1, usdt, emptyLocationInfo, emptyLocationInfo, ' ')
  
      await expect(usdtContract.connect(guest).approve(await rentalityPaymentService.getAddress(), result[0])).to.not.reverted
      await expect(
        await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
          {
            carId: 1,
            startDateTime: Date.now(),
            endDateTime: Date.now() + oneDayInSeconds,
            currencyType: usdt,
            pickUpInfo: emptySignedLocationInfo,
            returnInfo: emptySignedLocationInfo,
          },"",
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
  
      const balanceBeforeClaimTokens = await usdtContract.balanceOf(guest)
      
      await expect(investorsService.connect(guest).claimAllMy(1)).to.not.reverted

      let priceForDay = await rentalityCurrencyConverter.getFromUsdLatest(
        usdt,
        mockCarInvestment.car.pricePerDayInUsdCents - (mockCarInvestment.car.pricePerDayInUsdCents / 100) * 20
      )
      
      const balanceAfterClaimTokens = await usdtContract.balanceOf(guest)
      expect(Number(balanceAfterClaimTokens)).to.be.eq(
        Number(balanceBeforeClaimTokens) + (Number(priceForDay[0]) - Number(priceForDay[0])  / 10)
    )
    })
})