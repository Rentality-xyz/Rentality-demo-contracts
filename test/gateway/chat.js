const { expect } = require('chai')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')

const {
  getMockCarRequest,
  deployDefaultFixture,
  ethToken,
  calculatePayments,
  signTCMessage,
  emptyKyc,
  getEmptySearchCarParams,
} = require('../utils')

describe('RentalityGateway: chat', function () {
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
    rentalityLocationVerifier,
    adminKyc

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
      rentalityLocationVerifier,
      adminKyc,
    } = await loadFixture(deployDefaultFixture))
  })

  it('Should have chat history by guest', async function () {
    let addCarRequest = getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin)

    await expect(rentalityGateway.connect(host).addCar(addCarRequest)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()

    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityGateway
      .connect(guest)
      .searchAvailableCars(0, new Date().getSeconds() + 86400, getEmptySearchCarParams(1))
    expect(availableCars.length).to.equal(1)

    const oneDayInSeconds = 86400

    const dailyPriceInUsdCents = 1000

    const result = await rentalityGateway.calculatePayments(1, 2, ethToken)
    await expect(
      await rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds * 2,
          currencyType: ethToken,
        },
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    let name = 'name'
    let surname = 'surname'
    let number = '+380'
    let photo = 'photo'
    let licenseNumber = 'licenseNumber'
    let expirationDate = 10

    const hostSignature = await signTCMessage(host)
    const guestSignature = await signTCMessage(guest)
    await expect(
      rentalityGateway
        .connect(host)
        .setKYCInfo(name + 'host', number + 'host', photo + 'host', emptyKyc, hostSignature, adminKyc)
    ).not.be.reverted

    await expect(
      rentalityGateway
        .connect(guest)
        .setKYCInfo(name + 'guest', number + 'guest', photo + 'guest', emptyKyc, guestSignature, adminKyc)
    ).not.be.reverted

    let chatInfoArray = await rentalityGateway.connect(guest).getChatInfoForGuest()
    expect(chatInfoArray.length).to.be.equal(1)
    let chatInfo = chatInfoArray[0]

    expect(chatInfo.tripId).to.be.equal(1)
    expect(chatInfo.guestAddress).to.be.equal(guest.address)
    expect(chatInfo.guestPhotoUrl).to.be.equal(photo + 'guest')
    expect(chatInfo.hostAddress).to.be.equal(host.address)
    expect(chatInfo.tripStatus).to.be.equal(0)
    expect(chatInfo.carBrand).to.be.equal(addCarRequest.brand)
    expect(chatInfo.carModel).to.be.equal(addCarRequest.model)
    expect(chatInfo.carYearOfProduction).to.be.equal(Number(addCarRequest.yearOfProduction))
  })
  it('Should have chat history by host', async function () {
    let addCarRequest = getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(addCarRequest)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityGateway
      .connect(guest)
      .searchAvailableCars(0, new Date().getSeconds() + 86400, getEmptySearchCarParams(1))
    expect(availableCars.length).to.equal(1)

    let name = 'name'
    let surname = 'surname'
    let number = '+380'
    let photo = 'photo'
    let licenseNumber = 'licenseNumber'
    let expirationDate = 10
    const hostSignature = await signTCMessage(host)
    const guestSignature = await signTCMessage(guest)
    await expect(
      rentalityGateway
        .connect(host)
        .setKYCInfo(name + 'host', number + 'host', photo + 'host', emptyKyc, hostSignature, adminKyc)
    ).not.be.reverted

    await expect(
      rentalityGateway
        .connect(guest)
        .setKYCInfo(name + 'guest', number + 'guest', photo + 'guest', emptyKyc, guestSignature, adminKyc)
    ).not.be.reverted

    const oneDayInSeconds = 86400

    const result = await rentalityGateway.connect(guest).calculatePayments(1, 1, ethToken)
    await expect(
      await rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          currencyType: ethToken,
        },
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    let chatInfoArray = await rentalityGateway.connect(host).getChatInfoForHost()
    expect(chatInfoArray.length).to.be.equal(1)
    let chatInfo = chatInfoArray[0]

    expect(chatInfo.tripId).to.be.equal(1)
    expect(chatInfo.guestAddress).to.be.equal(guest.address)
    expect(chatInfo.guestPhotoUrl).to.be.equal(photo + 'guest')
    expect(chatInfo.hostAddress).to.be.equal(host.address)
    expect(chatInfo.tripStatus).to.be.equal(0)
    expect(chatInfo.carBrand).to.be.equal(addCarRequest.brand)
    expect(chatInfo.carModel).to.be.equal(addCarRequest.model)
    expect(chatInfo.carYearOfProduction).to.be.equal(Number(addCarRequest.yearOfProduction))
  })
})
