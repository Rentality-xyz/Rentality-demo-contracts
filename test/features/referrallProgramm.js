const { loadFixture, time } = require('@nomicfoundation/hardhat-network-helpers')
const {
  deployDefaultFixture,
  signTCMessage,
  zeroHash,
  getMockCarRequest,
  UserRole,
  ethToken,
  RefferalProgram,
  emptyLocationInfo,
  signLocationInfo,
  emptySignedLocationInfo,
} = require('../utils')
const { expect } = require('chai')
const { ethers } = require('hardhat')

describe('Referral program', function () {
  let rentalityGateway,
    refferalProgram,
    rentalityMockPriceFeed,
    rentalityUserService,
    rentalityTripService,
    rentalityCurrencyConverter,
    rentalityCarToken,
    rentalityPaymentService,
    rentalityPlatform,
    claimService,
    rentalityAutomationService,
    rentalityAdminGateway,
    owner,
    admin,
    manager,
    host,
    guest,
    anonymous,
    hashCreator,
    rentalityLocationVerifier

  beforeEach(async function () {
    ;({
      rentalityGateway,
      refferalProgram,
      rentalityMockPriceFeed,
      rentalityUserService,
      rentalityTripService,
      rentalityCurrencyConverter,
      rentalityCarToken,
      rentalityPaymentService,
      rentalityPlatform,
      claimService,
      rentalityAutomationService,
      rentalityAdminGateway,
      owner,
      admin,
      manager,
      host,
      guest,
      anonymous,
      hashCreator,
      rentalityLocationVerifier,
    } = await loadFixture(deployDefaultFixture))
  })

  it('should be able to setKyc with referral code', async function () {
    expect(await rentalityGateway.connect(hashCreator).setKYCInfo(' ', ' ', ' ', ' ',signTCMessage(hashCreator),zeroHash)).to.not
    .reverted

    let hash = await refferalProgram.referralHashV2(hashCreator.address)
   
    expect(await rentalityGateway.connect(anonymous).setKYCInfo(' ', ' ', ' ', ' ',signTCMessage(anonymous),hash)).to.not
      .reverted

    const readyToClaim = await refferalProgram.getReadyToClaim(anonymous.address)

    const amount = readyToClaim.toClaim.find((obj) => obj.refType === BigInt(RefferalProgram.SetKYC)).points

    expect(amount).to.be.eq(125)

    await expect(refferalProgram.claimPoints(anonymous.address)).to.not.reverted
    expect(await refferalProgram.addressToPoints(anonymous.address)).to.be.eq(145) // daily + kyc
    const hashPoints = await refferalProgram.getReadyToClaimFromRefferalHash(hashCreator.address)
    const hashCreatorPoints = hashPoints.toClaim.find((obj) => obj.refType === BigInt(RefferalProgram.SetKYC)).points

    expect(hashCreatorPoints).to.be.eq(10)

    await expect(refferalProgram.claimRefferalPoints(hashCreator.address)).to.not.reverted

    expect(await refferalProgram.addressToPoints(hashCreator.address)).to.be.eq(10)
  })
  it('should be able to add car with referral code', async function () {
    expect(await rentalityGateway.connect(hashCreator).setKYCInfo(' ', ' ', ' ', ' ',signTCMessage(hashCreator),zeroHash)).to.not
    .reverted

    let hash = await refferalProgram.referralHashV2(hashCreator.address)
    expect(await rentalityGateway.connect(anonymous).setKYCInfo(' ', ' ', ' ', ' ',signTCMessage(anonymous),hash)).to.not
      .reverted

    const readyToClaim = await refferalProgram.getReadyToClaim(anonymous.address)

    const amount = readyToClaim.toClaim.find((obj) => obj.refType === BigInt(RefferalProgram.SetKYC)).points

    expect(amount).to.be.eq(125)

    const hashPoints = await refferalProgram.getReadyToClaimFromRefferalHash(hashCreator.address)
    const hashCreatorPoints = hashPoints.toClaim.find((obj) => obj.refType === BigInt(RefferalProgram.SetKYC)).points
    expect(hashCreatorPoints).to.be.eq(10)

    expect(
      await rentalityGateway
        .connect(anonymous)
        .addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).to.not.reverted

    const hashPointsCar = await refferalProgram.getReadyToClaimFromRefferalHash(hashCreator.address)
    const hashCreatorPointsCar = hashPointsCar.toClaim.find(
      (obj) => obj.refType === BigInt(RefferalProgram.AddCar)
    ).points

    expect(hashCreatorPointsCar).to.be.eq(250)

    const readyToClaimCar = await refferalProgram.getReadyToClaim(anonymous.address)

    const amountCar = readyToClaimCar.toClaim.find(
      (obj) => obj.refType === BigInt(RefferalProgram.AddCar) && obj.oneTime
    ).points
    expect(amountCar).to.be.eq(2000)
    
    await time.increase(86400);
    await expect(refferalProgram.claimPoints(anonymous.address)).to.not.reverted


    await expect(refferalProgram.claimRefferalPoints(hashCreator.address)).to.not.reverted

    expect(await refferalProgram.addressToPoints(anonymous.address)).to.be.eq(2155)
    expect(await refferalProgram.addressToPoints(hashCreator.address)).to.be.eq(260)
  })
  it('update car should deacrease points', async function () {
    expect(await rentalityGateway.connect(hashCreator).setKYCInfo(' ', ' ', ' ', ' ',signTCMessage(hashCreator),zeroHash)).to.not
    .reverted

    let hash = await refferalProgram.referralHashV2(hashCreator.address)
   
    expect(await rentalityGateway.connect(anonymous).setKYCInfo(' ', ' ', ' ', ' ',signTCMessage(anonymous),hash)).to.not
      .reverted

    const readyToClaim = await refferalProgram.getReadyToClaim(anonymous.address)

    const amount = readyToClaim.toClaim.find((obj) => obj.refType === BigInt(RefferalProgram.SetKYC)).points

    expect(amount).to.be.eq(125)

    const hashPoints = await refferalProgram.getReadyToClaimFromRefferalHash(hashCreator.address)
    const hashCreatorPoints = hashPoints.toClaim.find((obj) => obj.refType === BigInt(RefferalProgram.SetKYC)).points

    expect(hashCreatorPoints).to.be.eq(10)

    expect(
      await rentalityGateway
        .connect(anonymous)
        .addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).to.not.reverted

    const hashPointsCar = await refferalProgram.getReadyToClaimFromRefferalHash(hashCreator.address)
    const hashCreatorPointsCar = hashPointsCar.toClaim.find(
      (obj) => obj.refType === BigInt(RefferalProgram.AddCar)
    ).points

    expect(hashCreatorPointsCar).to.be.eq(250)

    const toClaim = await refferalProgram.getReadyToClaim(anonymous.address)
    const amountAddCar = toClaim.toClaim.find(
      (obj) => obj.refType === BigInt(RefferalProgram.AddCar) && obj.oneTime
    ).points

    expect(amountAddCar).to.be.eq(2000)
    await expect(refferalProgram.claimPoints(anonymous.address)).to.not.reverted

    await expect(refferalProgram.claimRefferalPoints(hashCreator.address)).to.not.reverted

    expect(await refferalProgram.addressToPoints(anonymous.address)).to.be.eq(2145)
    expect(await refferalProgram.addressToPoints(hashCreator.address)).to.be.eq(260)

    let update_params = {
      carId: 1,
      pricePerDayInUsdCents: 2,
      securityDepositPerTripInUsdCents: 2,
      engineParams: [2, 2],
      timeBufferBetweenTripsInSec: 0,
      milesIncludedPerDay: 2,
      currentlyListed: false,
      insuranceIncluded: true,
      engineType: 1,
      tokenUri: '',
      insuranceRequired: false,
      insurancePriceInUsdCents: 0,
dimoTokenId: 0
    }

    let locationInfo = {
      locationInfo: emptyLocationInfo,
      signature: signLocationInfo(await rentalityLocationVerifier.getAddress(), admin, emptyLocationInfo),
    }
    await expect(rentalityGateway.connect(anonymous).updateCarInfoWithLocation(update_params, locationInfo)).to.not
      .reverted

    expect(await refferalProgram.addressToPoints(anonymous.address)).to.be.eq(1645)
    await expect(rentalityGateway.connect(anonymous).updateCarInfoWithLocation(update_params, locationInfo)).to.not
      .reverted
    expect(await refferalProgram.addressToPoints(anonymous.address)).to.be.eq(1645)
  })
  it('should be able to pass civic with referral code', async function () {
    expect(await rentalityGateway.connect(hashCreator).setKYCInfo(' ', ' ', ' ', ' ',signTCMessage(hashCreator),zeroHash)).to.not
    .reverted

    let hash = await refferalProgram.referralHashV2(hashCreator.address)
   
    expect(await rentalityGateway.connect(anonymous).setKYCInfo(' ', ' ', ' ', ' ',signTCMessage(anonymous),hash)).to.not
      .reverted

    const readyToClaim = await refferalProgram.getReadyToClaim(anonymous.address)

    const amount = readyToClaim.toClaim.find((obj) => obj.refType === BigInt(RefferalProgram.SetKYC)).points

    expect(amount).to.be.eq(125)

    const hashPoints = await refferalProgram.getReadyToClaimFromRefferalHash(hashCreator.address)
    const hashCreatorPoints = hashPoints.toClaim.find((obj) => obj.refType === BigInt(RefferalProgram.SetKYC)).points

    expect(hashCreatorPoints).to.be.eq(10)

    let kyc = {
      fullName: 'zf',
      licenseNumber: 'asdas',
      expirationDate: Date.now() + 86400,
      issueCountry: 'ISSUE',
      email: 'EMAIL',
    }

    await expect(
      await rentalityUserService.connect(owner).manageRole(UserRole.KYCManager, await host.getAddress(), true)
    ).to.not.reverted
    await expect(rentalityGateway.connect(host).setCivicKYCInfo(anonymous.address, kyc)).to.not.reverted

    const toClaim = await refferalProgram.getReadyToClaim(anonymous.address)
    const amountСivic = toClaim.toClaim.find((obj) => obj.refType === BigInt(RefferalProgram.PassCivic)).points

    expect(amountСivic).to.be.eq(625)

    const hashPointsCivic = await refferalProgram.getReadyToClaimFromRefferalHash(hashCreator.address)
    const hashCreatorPointsCivic = hashPointsCivic.toClaim.find(
      (obj) => obj.refType === BigInt(RefferalProgram.PassCivic)
    ).points

    expect(hashCreatorPointsCivic).to.be.eq(50)

    await expect(refferalProgram.claimPoints(anonymous.address)).to.not.reverted
    await expect(refferalProgram.claimRefferalPoints(hashCreator.address)).to.not.reverted

    expect(await refferalProgram.addressToPoints(anonymous.address)).to.be.eq(770)
    expect(await refferalProgram.addressToPoints(hashCreator.address)).to.be.eq(60)
  })

  it('should have points with refferal hash after trip finish as guest', async function () {
    expect(await rentalityGateway.connect(hashCreator).setKYCInfo(' ', ' ', ' ', ' ',signTCMessage(hashCreator),zeroHash)).to.not
    .reverted

    let hash = await refferalProgram.referralHashV2(hashCreator.address)
   
    expect(await rentalityGateway.connect(anonymous).setKYCInfo(' ', ' ', ' ', ' ',signTCMessage(anonymous),hash)).to.not
      .reverted

    expect(
      await rentalityGateway
        .connect(host)
        .addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).to.not.reverted

    const result = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      1,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo,
      ' '
    )
    await expect(
      await rentalityGateway.connect(anonymous).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + 86400,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          useRefferalDiscount: false,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).to.not.reverted

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityGateway.connect(anonymous).checkInByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(anonymous).checkOutByGuest(1, [0, 0])).not.to.be.reverted

    const toClaim = await refferalProgram.getReadyToClaim(anonymous.address)
    const amountTripFinish = toClaim.toClaim.find(
      (obj) => obj.refType === BigInt(RefferalProgram.FinishTripAsGuest) && obj.oneTime
    ).points

    expect(amountTripFinish).to.be.eq(1250)

    const hashPointsCivic = await refferalProgram.getReadyToClaimFromRefferalHash(hashCreator.address)
    const hashCreatorPointsCivic = hashPointsCivic.toClaim.find(
      (obj) => obj.refType === BigInt(RefferalProgram.FinishTripAsGuest)
    ).points

    expect(hashCreatorPointsCivic).to.be.eq(1000)

    await expect(refferalProgram.claimPoints(anonymous.address)).to.not.reverted
    await expect(refferalProgram.claimRefferalPoints(hashCreator.address)).to.not.reverted

    expect(await refferalProgram.addressToPoints(anonymous.address)).to.be.eq(1395)
    expect(await refferalProgram.addressToPoints(hashCreator.address)).to.be.eq(1010)
  })

  it('should have points with refferal hash after trip finish as guest', async function () {
    expect(await rentalityGateway.connect(hashCreator).setKYCInfo(' ', ' ', ' ', ' ',signTCMessage(hashCreator),zeroHash)).to.not
    .reverted

    let hash = await refferalProgram.referralHashV2(hashCreator.address)
   
    expect(await rentalityGateway.connect(anonymous).setKYCInfo(' ', ' ', ' ', ' ',signTCMessage(anonymous),hash)).to.not
      .reverted

    expect(
      await rentalityGateway
        .connect(anonymous)
        .addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).to.not.reverted

    expect(
      await rentalityGateway
        .connect(anonymous)
        .addCar(getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin))
    ).to.not.reverted

    const toClaim = await refferalProgram.getReadyToClaim(anonymous.address)
    const amountAddCar = toClaim.toClaim.find((obj) => obj.refType === BigInt(RefferalProgram.AddCar)).points

    expect(amountAddCar).to.be.eq(500)
    await expect(refferalProgram.claimPoints(anonymous.address)).to.not.reverted
    expect(await refferalProgram.addressToPoints(anonymous.address)).to.be.eq(2645)
  })
  it('should be able to get permanent guest trip bonus for 10 days', async function () {
    expect(await rentalityGateway.connect(hashCreator).setKYCInfo(' ', ' ', ' ', ' ',signTCMessage(hashCreator),zeroHash)).to.not
    .reverted


    let hash = await refferalProgram.referralHashV2(hashCreator.address)
   
    expect(await rentalityGateway.connect(anonymous).setKYCInfo(' ', ' ', ' ', ' ',signTCMessage(anonymous),hash)).to.not
      .reverted

    expect(
      await rentalityGateway
        .connect(host)
        .addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).to.not.reverted

    const result = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      1,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo,
      ' '
    )
    await expect(
      await rentalityGateway.connect(anonymous).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + 86400,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          useRefferalDiscount: false,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).to.not.reverted

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityGateway.connect(anonymous).checkInByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(anonymous).checkOutByGuest(1, [0, 0])).not.to.be.reverted

    expect(
      await rentalityGateway
        .connect(host)
        .addCar(getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin))
    ).to.not.reverted

    const result2 = await rentalityGateway.calculatePaymentsWithDelivery(
      2,
      10,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo,
      ' '
    )
    await expect(
      await rentalityGateway.connect(anonymous).createTripRequestWithDelivery(
        {
          carId: 2,
          startDateTime: Date.now(),
          endDateTime: Date.now() + 86400 * 10,
          currencyType: ethToken,
          useRefferalDiscount: false,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result2.totalPrice }
      )
    ).to.not.reverted

    await expect(rentalityGateway.connect(host).approveTripRequest(2)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(2, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityGateway.connect(anonymous).checkInByGuest(2, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(anonymous).checkOutByGuest(2, [0, 0])).not.to.be.reverted

    await expect(refferalProgram.claimPoints(anonymous.address)).to.not.reverted

    expect(await refferalProgram.addressToPoints(anonymous.address)).to.be.eq(1895)
  })

  it.skip('should be able to get permanent host trip bonus for 10 days', async function () {
    expect(await refferalProgram.connect(hashCreator).generateReferralHash()).to.not.reverted

    let hash = await refferalProgram.referralHashV2(hashCreator.address)

    expect(await rentalityGateway.connect(anonymous).setKYCInfo(' ', ' ', ' ', ' ',signTCMessage(anonymous),hash)).to
      .not.reverted
    expect(
      await rentalityGateway
        .connect(host)
        .addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).to.not.reverted

    const result = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      1,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo,
      ' '
    )
    await expect(
      await rentalityGateway.connect(anonymous).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + 86400,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          useRefferalDiscount: false,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).to.not.reverted

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityGateway.connect(anonymous).checkInByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(anonymous).checkOutByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(host).finishTrip(1)).to.not.reverted

    expect(
      await rentalityGateway
        .connect(host)
        .addCar(getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin))
    ).to.not.reverted

    const result2 = await rentalityGateway.calculatePaymentsWithDelivery(
      2,
      10,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo,
      ' '
    )
    await expect(
      await rentalityGateway.connect(anonymous).createTripRequestWithDelivery(
        {
          carId: 2,
          startDateTime: Date.now(),
          endDateTime: Date.now() + 86400 * 10,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          useRefferalDiscount: false,
        },
        ' ',
        { value: result2.totalPrice }
      )
    ).to.not.reverted

    await expect(rentalityGateway.connect(host).approveTripRequest(2)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(2, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityGateway.connect(anonymous).checkInByGuest(2, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(anonymous).checkOutByGuest(2, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(2, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(host).finishTrip(2)).to.not.reverted

    await expect(refferalProgram.claimPoints(host.address)).to.not.reverted

    expect(await refferalProgram.addressToPoints(host.address)).to.be.eq(2640)
  })
  it('Can use hash a lot of time', async function () {

    let hash = await refferalProgram.referralHashV2(host.address)
   
    await expect(rentalityGateway.connect(anonymous).setKYCInfo(' ', ' ', ' ', ' ',signTCMessage(anonymous),hash)).to.not
      .reverted
    await expect(rentalityGateway.connect(manager).setKYCInfo(' ', ' ', ' ', ' ',signTCMessage(manager),hash)).to.not
      .reverted

    const hashPoints = await refferalProgram.getReadyToClaimFromRefferalHash(host.address)

    await expect(refferalProgram.claimPoints(anonymous.address)).to.not.reverted
    await expect(refferalProgram.claimPoints(manager.address)).to.not.reverted
    await expect(refferalProgram.claimRefferalPoints(host.address)).to.not.reverted

    expect(await refferalProgram.addressToPoints(anonymous.address)).to.be.eq(145)
    expect(await refferalProgram.addressToPoints(manager.address)).to.be.eq(145)
    expect(await refferalProgram.addressToPoints(host.address)).to.be.eq(20)
  })
  it('Already pass program, use code again: do nothing', async function () {

    let hash = await refferalProgram.referralHashV2(host.address)
   
    await expect(rentalityGateway.connect(anonymous).setKYCInfo(' ', ' ', ' ', ' ',signTCMessage(anonymous),hash)).to.not
      .reverted

    await expect(refferalProgram.claimPoints(anonymous.address)).to.not.reverted
    expect(await refferalProgram.addressToPoints(anonymous.address)).to.be.eq(145)

    await expect(rentalityGateway.connect(anonymous).setKYCInfo(' ', ' ', ' ', ' ',signTCMessage(anonymous),hash)).to.not
      .reverted

    await expect(refferalProgram.claimPoints(anonymous.address)).to.not.reverted
    expect(await refferalProgram.addressToPoints(anonymous.address)).to.be.eq(145)
  })

  it('Can get all points info', async function () {
    let result = await refferalProgram.getRefferalPointsInfo()
    expect(result.programPoints.length).to.be.eq(9)
    expect(result.hashPoints.length).to.be.eq(4)
    expect(result.discounts.length).to.be.eq(6)
    expect(result.tear.length).to.be.eq(4)
  })

  it('Admin can manage points points', async function () {
    await expect(rentalityAdminGateway.connect(owner).manageRefferalBonusAccrual(0, RefferalProgram.SetKYC, 500, 1000))
      .to.not.reverted

    await expect(rentalityAdminGateway.connect(owner).manageRefferalHashPoints(RefferalProgram.SetKYC, 500)).to.not
      .reverted
      expect(await rentalityGateway.connect(hashCreator).setKYCInfo(' ', ' ', ' ', ' ',signTCMessage(hashCreator),zeroHash)).to.not
      .reverted

    let hash = await refferalProgram.referralHashV2(hashCreator.address)
   
    expect(await rentalityGateway.connect(anonymous).setKYCInfo(' ', ' ', ' ', ' ',signTCMessage(anonymous),hash)).to.not
      .reverted
  

    const readyToClaim = await refferalProgram.getReadyToClaim(anonymous.address)

    const amount = readyToClaim.toClaim.find((obj) => obj.refType === BigInt(RefferalProgram.SetKYC)).points

    expect(amount).to.be.eq(1000)

    await expect(refferalProgram.claimPoints(anonymous.address)).to.not.reverted
    expect(await refferalProgram.addressToPoints(anonymous.address)).to.be.eq(1020) // daily + kyc

    const hashPoints = await refferalProgram.getReadyToClaimFromRefferalHash(hashCreator.address)
    const hashCreatorPoints = hashPoints.toClaim.find((obj) => obj.refType === BigInt(RefferalProgram.SetKYC)).points

    expect(hashCreatorPoints).to.be.eq(500)

    await expect(refferalProgram.claimRefferalPoints(hashCreator.address)).to.not.reverted

    expect(await refferalProgram.addressToPoints(hashCreator.address)).to.be.eq(500)
  })
  it('Admin can manage discounts', async function () {
    await expect(rentalityAdminGateway.connect(owner).manageRefferalDiscount(RefferalProgram.SetKYC, 1, 5000, 10)).to
      .not.reverted

    let result = await refferalProgram.getRefferalPointsInfo()
    result = result.discounts.find((d) => d.method === BigInt(RefferalProgram.SetKYC) && d.tear === BigInt(1))

    expect(result.discount.percents).to.be.eq(10)
    expect(result.discount.pointsCosts).to.be.eq(5000)
  })
})
