const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const {
  deployDefaultFixture,
  getMockCarRequest,
  createMockClaimRequest,
  emptyLocationInfo,
  emptySignedLocationInfo,
  zeroHash
} = require('../utils')
const { expect } = require('chai')
const { calculatePaymentsFrom } = require('../utils')

async function mintTo(contract, address, amount) {
  await expect(contract.mint(address, amount * 10 ** 6)).to.not.be.reverted
}

describe('ERC20 payments', function () {
  let rentalityGateway,
    rentalityCurrencyConverter,
    rentalityPlatform,
    rentalityPaymentService,
    usdtContract,
    owner,
    guest,
    host,
    rentalityTripService,
    admin,
    rentalityLocationVerifier
  rentalityAdminGateway = beforeEach(async function () {
    ;({
      rentalityGateway,
      rentalityCurrencyConverter,
      rentalityPlatform,
      rentalityPaymentService,
      usdtContract,
      owner,
      guest,
      host,
      rentalityTripService,
      admin,
      rentalityLocationVerifier,
      rentalityAdminGateway,
    } = await loadFixture(deployDefaultFixture))
  })
  it('Should correctly сreate trip and pay deposit with usdt', async function () {
    let usdt = await usdtContract.getAddress()
    const request = getMockCarRequest(13, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(request, zeroHash)).not.to.be.reverted

    const dailyPriceInUsdCents = 1000

    const { rentPrice, currencyRate, currencyDecimals, rentalityFee } = await calculatePaymentsFrom(
      rentalityCurrencyConverter,
      rentalityPaymentService,
      request.pricePerDayInUsdCents,
      1,
      request.securityDepositPerTripInUsdCents,
      usdt
    )
    await mintTo(usdtContract, guest.address, 1000)
    const balanceBeforeTrip = await usdtContract.balanceOf(guest)

    await usdtContract.connect(guest).approve(await rentalityPaymentService.getAddress(), rentPrice)

    await expect(
      rentalityGateway.connect(guest).createTripRequestWithDelivery({
        carId: 1,
        startDateTime: 1,
        endDateTime: 2,
        currencyType: usdt,
        insurancePaid: false,
        photo: '',
        pickUpInfo: emptySignedLocationInfo,
        returnInfo: emptySignedLocationInfo,
      })
    ).to.not.reverted

    const balanceAfterTrip = await usdtContract.balanceOf(guest.address)
    const rentalityPlatformBalance = await usdtContract.balanceOf(await rentalityPaymentService.getAddress())

    expect(balanceAfterTrip + rentPrice).to.be.eq(balanceBeforeTrip)
    expect(rentalityPlatformBalance).to.be.eq(rentPrice)
  })

  it('should correctly finish trip with usdt, and send tokens to the host', async function () {
    let usdt = await usdtContract.getAddress()
    const request = getMockCarRequest(10, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(request, zeroHash)).not.to.be.reverted

    await mintTo(usdtContract, guest.address, 10000000)

    const guestBalanceBeforeTrip = await usdtContract.balanceOf(guest.address)
    const hostBalanceBeforeTrip = await usdtContract.balanceOf(host.address)

    const { rentPrice, currencyRate, currencyDecimals, rentalityFee, taxes } = await calculatePaymentsFrom(
      rentalityCurrencyConverter,
      rentalityPaymentService,
      request.pricePerDayInUsdCents,
      1,
      request.securityDepositPerTripInUsdCents,
      usdt
    )
    await usdtContract.connect(guest).approve(await rentalityPaymentService.getAddress(), rentPrice)

    await expect(
      rentalityGateway.connect(guest).createTripRequestWithDelivery({
        carId: 1,
        startDateTime: 1,
        endDateTime: 2,
        currencyType: usdt,
        insurancePaid: false,
        photo: '',
        pickUpInfo: emptySignedLocationInfo,
        returnInfo: emptySignedLocationInfo,
      })
    ).to.not.reverted

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [0, 0], zeroHash)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted

    const deposit = await rentalityCurrencyConverter.getFromUsd(
      usdt,
      request.securityDepositPerTripInUsdCents,
      currencyRate,
      currencyDecimals
    )
    await expect(rentalityGateway.connect(host).finishTrip(1, zeroHash)).to.not.reverted

    const guestBalanceAfterTrip = await usdtContract.balanceOf(guest.address)
    const hostBalanceAfterTrip = await usdtContract.balanceOf(host.address)

    const platformBalance = await usdtContract.balanceOf(await rentalityPaymentService.getAddress())

    expect(guestBalanceAfterTrip).to.be.eq(guestBalanceBeforeTrip + deposit - rentPrice)
    expect(hostBalanceAfterTrip).to.be.eq(hostBalanceBeforeTrip + rentPrice - deposit - rentalityFee - taxes)
    expect(platformBalance).to.be.eq(rentalityFee + taxes)
  })

  it('should not be able to create trip with wrong currency type', async function () {
    let usdt = await usdtContract.getAddress()
    await expect(
      rentalityGateway
        .connect(host)
        .addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin), zeroHash)
    ).not.to.be.reverted
    const rentPriceInUsdCents = 1000

    const dailyPriceInUsdCents = 1000

    await mintTo(usdtContract, guest.address, 1000)

    const { rentPrice, currencyRate, currencyDecimals, rentalityFee } = await calculatePaymentsFrom(
      rentalityCurrencyConverter,
      rentalityPaymentService,
      dailyPriceInUsdCents,
      1,
      0,
      usdt
    )

    await usdtContract.connect(guest).approve(await rentalityPaymentService.getAddress(), rentPrice)

    await expect(
      rentalityGateway.connect(guest).createTripRequestWithDelivery({
        carId: 1,
        host: host.address,
        startDateTime: 1,
        endDateTime: 2,
        startLocation: '',
        endLocation: '',
        totalDayPriceInUsdCents: dailyPriceInUsdCents,
        depositInUsdCents: 0,
        currencyRate: currencyRate,
        currencyDecimals: currencyDecimals,
        currencyType: await rentalityPlatform.getAddress(),
        insurancePaid: false,
        photo: '',
        pickUpInfo: emptySignedLocationInfo,
        returnInfo: emptySignedLocationInfo,
      })
    ).to.be.revertedWith('Token is not available.')
  })

  it('should correctly pay claim with usdt', async function () {
    let usdt = await usdtContract.getAddress()
    await expect(
      rentalityGateway
        .connect(host)
        .addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin), zeroHash)
    ).not.to.be.reverted

    await mintTo(usdtContract, guest.address, 10000)

    const dailyPriceInUsdCents = 1000

    const { rentPrice, currencyRate, currencyDecimals, rentalityFee } = await calculatePaymentsFrom(
      rentalityCurrencyConverter,
      rentalityPaymentService,
      dailyPriceInUsdCents,
      1,
      0,
      usdt
    )

    await usdtContract.connect(guest).approve(await rentalityPaymentService.getAddress(), rentPrice)

    await expect(
      rentalityGateway.connect(guest).createTripRequestWithDelivery({
        carId: 1,
        host: host.address,
        startDateTime: 1,
        endDateTime: 2,
        startLocation: '',
        endLocation: '',
        totalDayPriceInUsdCents: dailyPriceInUsdCents,
        depositInUsdCents: 0,
        currencyRate: currencyRate,
        currencyDecimals: currencyDecimals,
        currencyType: usdt,
        insurancePaid: false,
        photo: '',
        pickUpInfo: emptySignedLocationInfo,
        returnInfo: emptySignedLocationInfo,
      })
    ).to.not.reverted

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted

    const amountToPayForClaim = 1000

    const [claimPriceInUsdt, ,] = await rentalityCurrencyConverter.getFromUsdLatest(
      await usdtContract.getAddress(),
      amountToPayForClaim
    )

    await usdtContract.connect(guest).approve(await rentalityPaymentService.getAddress(), claimPriceInUsdt)
    await expect(rentalityGateway.connect(host).createClaim(createMockClaimRequest(1, amountToPayForClaim))).not.to.be
      .reverted
    const hostBalanceBeforeClaim = await usdtContract.balanceOf(host.address)
    const guestBalanceBeforeClaim = await usdtContract.balanceOf(guest.address)

    await expect(rentalityGateway.connect(guest).payClaim(1)).to.not.reverted

    const hostBalanceAfterClaim = await usdtContract.balanceOf(host.address)
    const guestBalanceAfterClaim = await usdtContract.balanceOf(guest.address)

    expect(hostBalanceAfterClaim).to.be.eq(hostBalanceBeforeClaim + claimPriceInUsdt)
    expect(guestBalanceAfterClaim).to.be.eq(guestBalanceBeforeClaim - claimPriceInUsdt)
  })
  it('should be able withdraw usdt from platform ', async function () {
    let usdt = await usdtContract.getAddress()
    const request = getMockCarRequest(10, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(request, zeroHash)).not.to.be.reverted

    await mintTo(usdtContract, guest.address, 1000)

    const dailyPriceInUsdCents = 1000

    const { rentPrice, currencyRate, currencyDecimals, rentalityFee } = await calculatePaymentsFrom(
      rentalityCurrencyConverter,
      rentalityPaymentService,
      request.pricePerDayInUsdCents,
      1,
      request.securityDepositPerTripInUsdCents,
      usdt
    )

    await usdtContract.connect(guest).approve(await rentalityPaymentService.getAddress(), rentPrice)

    await expect(
      rentalityGateway.connect(guest).createTripRequestWithDelivery({
        carId: 1,
        startDateTime: 1,
        endDateTime: 2,
        currencyType: usdt,
        insurancePaid: false,
        photo: '',
        pickUpInfo: emptySignedLocationInfo,
        returnInfo: emptySignedLocationInfo,
      })
    ).to.not.reverted

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [0, 0], zeroHash)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted

    await expect(rentalityGateway.connect(host).finishTrip(1, zeroHash)).to.not.reverted

    await expect(rentalityAdminGateway.connect(admin).withdrawAllFromPlatform(usdt)).to.not.reverted

    const ownerBalance = await usdtContract.balanceOf(owner)
    expect(ownerBalance).to.be.gt(0)
  })
})
