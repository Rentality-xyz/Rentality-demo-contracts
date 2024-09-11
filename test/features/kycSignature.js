const { expect } = require('chai')
const {
  deployDefaultFixture,
  ethToken,
  locationInfo,
  getEmptySearchCarParams,
  signTCMessage,
  signLocationInfo,
  signKycInfo,
  emptyKyc,
} = require('../utils')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { ethers } = require('hardhat')

describe('Rentality Kyc signature', function () {
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
      hostSignature,
    } = await loadFixture(deployDefaultFixture))
  })

  it('should set signed kyc Info', async function () {
    let kyc = {
      fullName: 'fullName',
      licenseNumber: '123123',
      expirationDate: 123,
      issueCountry: 'USA',
      email: 'USER@EMAIL.COM',
    }
    let nickName = 'nickName'
    let photo = 'photo'
    let mobile = '+380'
    let adminSignKyc = signKycInfo(await rentalityLocationVerifier.getAddress(), admin, kyc)
    await expect(rentalityGateway.connect(host).setKYCInfo(nickName, mobile, photo, kyc, hostSignature, adminSignKyc))
      .to.not.reverted

    let myKyc = await rentalityGateway.connect(host).getMyFullKYCInfo()

    expect(myKyc.kyc.name).to.be.eq(nickName)
    expect(myKyc.kyc.surname).to.be.eq(kyc.fullName)
    expect(myKyc.kyc.mobilePhoneNumber).to.be.eq(mobile)
    expect(myKyc.kyc.profilePhoto).to.be.eq(photo)
    expect(myKyc.kyc.licenseNumber).to.be.eq(kyc.licenseNumber)
    expect(myKyc.kyc.expirationDate).to.be.eq(kyc.expirationDate)
    expect(myKyc.additionalKYC.email).to.be.eq(kyc.email)
    expect(myKyc.additionalKYC.issueCountry).to.be.eq(kyc.issueCountry)
  })

  it('possible to update without civic', async function () {
    let kyc = {
      fullName: 'fullName',
      licenseNumber: '123123',
      expirationDate: 123,
      issueCountry: 'USA',
      email: 'USER@EMAIL.COM',
    }
    let nickName = 'nickName'
    let photo = 'photo'
    let mobile = '+380'
    let adminSignKyc = signKycInfo(await rentalityLocationVerifier.getAddress(), admin, kyc)
    await expect(rentalityGateway.connect(host).setKYCInfo(nickName, mobile, photo, kyc, hostSignature, adminSignKyc))
      .to.not.reverted

    let myKyc = await rentalityGateway.connect(host).getMyFullKYCInfo()

    expect(myKyc.kyc.name).to.be.eq(nickName)
    expect(myKyc.kyc.surname).to.be.eq(kyc.fullName)
    expect(myKyc.kyc.mobilePhoneNumber).to.be.eq(mobile)
    expect(myKyc.kyc.profilePhoto).to.be.eq(photo)
    expect(myKyc.kyc.licenseNumber).to.be.eq(kyc.licenseNumber)
    expect(myKyc.kyc.expirationDate).to.be.eq(kyc.expirationDate)
    expect(myKyc.additionalKYC.email).to.be.eq(kyc.email)
    expect(myKyc.additionalKYC.issueCountry).to.be.eq(kyc.issueCountry)

    let newNick = 'newNIck'
    let newPhoto = 'newPhoto'
    let newPhone = 'newPhone'

    await expect(rentalityGateway.connect(host).setKYCInfo(newNick, newPhone, newPhoto, emptyKyc, hostSignature, '0x'))
      .to.not.reverted

    myKyc = await rentalityGateway.connect(host).getMyFullKYCInfo()

    expect(myKyc.kyc.name).to.be.eq(newNick)
    expect(myKyc.kyc.surname).to.be.eq(kyc.fullName)
    expect(myKyc.kyc.mobilePhoneNumber).to.be.eq(newPhone)
    expect(myKyc.kyc.profilePhoto).to.be.eq(newPhoto)
    expect(myKyc.kyc.licenseNumber).to.be.eq(kyc.licenseNumber)
    expect(myKyc.kyc.expirationDate).to.be.eq(kyc.expirationDate)
    expect(myKyc.additionalKYC.email).to.be.eq(kyc.email)
    expect(myKyc.additionalKYC.issueCountry).to.be.eq(kyc.issueCountry)
  })
})
