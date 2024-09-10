const { expect } = require('chai')
const {
  deployDefaultFixture,
  ethToken,
  locationInfo,
  getEmptySearchCarParams,
  signTCMessage,
  signLocationInfo,
  signKycInfo,
} = require('../utils')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { ethers } = require('hardhat')

describe('Rentality Delivery', function () {
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
    deliveryService,
    elEngine,
    pEngine,
    hEngine,
    owner,
    admin,
    manager,
    host,
    guest,
    anonymous,
    rentalityLocationVerifier,
    guestSignature,
    hostSignature

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
      deliveryService,
      elEngine,
      pEngine,
      hEngine,
      owner,
      admin,
      manager,
      host,
      guest,
      anonymous,
      rentalityLocationVerifier,
      guestSignature,
      hostSignature
    } = await loadFixture(deployDefaultFixture))
  })

  it('should set signed kyc Info', async function () {
    let kyc = {
        name:"fullName",
        licenseNumber:"123123",
        expirationDate:123,
        country: "USA",
        email:"USER@EMAIL.COM"
    }
    let nickName = "nickName"
    let photo = "photo"
    let mobile = "+380"
    let adminSignKyc = signKycInfo(await rentalityLocationVerifier.getAddress(),admin, kyc)
    await expect(
        rentalityGateway.connect(host).setKYCInfo(nickName,mobile,photo,kyc,hostSignature, adminSignKyc)
    ).to.not.reverted

  })})