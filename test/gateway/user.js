const { expect } = require('chai')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')

const {
  getMockCarRequest,

  deployDefaultFixture,
  getEmptySearchCarParams,
  ethToken,
  calculatePayments,
  signTCMessage,
  emptyLocationInfo,
} = require('../utils')

describe('RentalityGateway: user info', function () {
  let rentalityGateway,
    rentalityMockPriceFeed,
    rentalityUserService,
    rentalityTripService,
    rentalityCurrencyConverter,
    rentalityCarToken,
    rentalityGeoService,
    rentalityAdminGateway,
    utils,
    claimService,
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
      rentalityGateway,
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
    } = await loadFixture(deployDefaultFixture))
  })

  it('Should host be able to create KYC', async function () {
    let name = 'name'
    let surname = 'surname'
    let number = '+380'
    let photo = 'photo'
    let licenseNumber = 'licenseNumber'
    let expirationDate = 10

    const hostSignature = await signTCMessage(host)

    await expect(
      rentalityGateway
        .connect(host)
        .setKYCInfo(name, surname, number, photo, licenseNumber, expirationDate, hostSignature)
    ).not.be.reverted

    const kycInfo = await rentalityGateway.connect(host).getMyKYCInfo()

    expect(kycInfo.name).to.equal(name)
    expect(kycInfo.surname).to.equal(surname)
    expect(kycInfo.mobilePhoneNumber).to.equal(number)
    expect(kycInfo.profilePhoto).to.equal(photo)
    expect(kycInfo.licenseNumber).to.equal(licenseNumber)
    expect(kycInfo.expirationDate).to.equal(expirationDate)
  })
  it('Should guest be able to create KYC', async function () {
    let name = 'name'
    let surname = 'surname'
    let number = '+380'
    let photo = 'photo'
    let licenseNumber = 'licenseNumber'
    let expirationDate = 10

    const guestSignature = await signTCMessage(guest)
    await expect(
      rentalityGateway
        .connect(guest)
        .setKYCInfo(name, surname, number, photo, licenseNumber, expirationDate, guestSignature)
    ).not.be.reverted

    const kycInfo = await rentalityGateway.connect(guest).getMyKYCInfo()

    expect(kycInfo.name).to.equal(name)
    expect(kycInfo.surname).to.equal(surname)
    expect(kycInfo.mobilePhoneNumber).to.equal(number)
    expect(kycInfo.profilePhoto).to.equal(photo)
    expect(kycInfo.licenseNumber).to.equal(licenseNumber)
    expect(kycInfo.expirationDate).to.equal(expirationDate)
  })

  it('Guest should be able to get trip contacts', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const dailyPriceInUsdCents = 1000

    const result = await rentalityGateway.calculatePayments(1, 1, ethToken, false)
    await expect(
      await rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          insurancePaid: false,
          photo: '',
          pickUpInfo: {
            signature: guest.address,
            locationInfo: emptyLocationInfo,
          },
          returnInfo: {
            signature: guest.address,
            locationInfo: emptyLocationInfo,
          },
        },
        { value: result.totalPrice }
      )
    ).not.to.be.reverted

    const hostSignature = await signTCMessage(host)
    const guestSignature = await signTCMessage(guest)

    let guestNumber = '+380'
    let hostNumber = '+3801'
    await expect(
      rentalityUserService
        .connect(guest)
        .setKYCInfo('name', 'surname', guestNumber, 'photo', 'number', 1, guestSignature)
    ).not.be.reverted

    await expect(
      rentalityUserService.connect(host).setKYCInfo('name', 'surname', hostNumber, 'photo', 'number', 1, hostSignature)
    ).not.be.reverted

    let [guestPhoneNumber, hostPhoneNumber] = await rentalityGateway.connect(guest).getTripContactInfo(1)

    expect(guestPhoneNumber).to.be.equal(guestNumber)
    expect(hostPhoneNumber).to.be.equal(hostNumber)
  })

  it('Host should be able to get trip contacts', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const dailyPriceInUsdCents = 1000

    const result = await rentalityGateway.calculatePayments(1, 1, ethToken, false)
    await expect(
      await rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          insurancePaid: false,
          photo: '',
          pickUpInfo: {
            signature: guest.address,
            locationInfo: emptyLocationInfo,
          },
          returnInfo: {
            signature: guest.address,
            locationInfo: emptyLocationInfo,
          },
        },
        { value: result.totalPrice }
      )
    ).not.to.be.reverted

    const hostSignature = await signTCMessage(host)
    const guestSignature = await signTCMessage(guest)
    let guestNumber = '+380'
    let hostNumber = '+3801'
    await expect(
      rentalityGateway.connect(guest).setKYCInfo('name', 'surname', guestNumber, 'photo', 'number', 1, guestSignature)
    ).not.be.reverted

    await expect(
      rentalityGateway.connect(host).setKYCInfo('name', 'surname', hostNumber, 'photo', 'number', 1, hostSignature)
    ).not.be.reverted

    let [guestPhoneNumber, hostPhoneNumber] = await rentalityGateway.connect(host).getTripContactInfo(1)

    expect(guestPhoneNumber).to.be.equal(guestNumber)
    expect(hostPhoneNumber).to.be.equal(hostNumber)
  })

  it('Only host and guest should be able to get trip contacts', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const dailyPriceInUsdCents = 1000

    const result = await rentalityGateway.calculatePayments(1, 1, ethToken, false)
    await expect(
      await rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          insurancePaid: false,
          photo: '',
          pickUpInfo: {
            signature: guest.address,
            locationInfo: emptyLocationInfo,
          },
          returnInfo: {
            signature: guest.address,
            locationInfo: emptyLocationInfo,
          },
        },
        { value: result.totalPrice }
      )
    ).not.to.be.reverted

    const hostSignature = await signTCMessage(host)
    const guestSignature = await signTCMessage(guest)
    let guestNumber = '+380'
    let hostNumber = '+3801'
    await expect(
      rentalityGateway.connect(guest).setKYCInfo('name', 'surname', guestNumber, 'photo', 'number', 1, guestSignature)
    ).not.be.reverted

    await expect(
      rentalityGateway.connect(host).setKYCInfo('name', 'surname', hostNumber, 'photo', 'number', 1, hostSignature)
    ).not.be.reverted

    await expect(rentalityGateway.connect(anonymous).getTripContactInfo(1)).to.be.reverted
  })
  it('Should have host photoUrl and host name in available car response ', async function () {
    let addCarRequest = getMockCarRequest(0)
    await expect(rentalityGateway.connect(host).addCar(addCarRequest)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    let name = 'name'
    let surname = 'surname'
    let number = '+380'
    let photo = 'photo'
    let licenseNumber = 'licenseNumber'
    let expirationDate = 10

    const hostSignature = await signTCMessage(host)

    await expect(
      rentalityGateway
        .connect(host)
        .setKYCInfo(
          name + 'host',
          surname + 'host',
          number + 'host',
          photo + 'host',
          licenseNumber + 'host',
          expirationDate,
          hostSignature
        )
    ).not.be.reverted

    const availableCars = await rentalityGateway.connect(guest).searchAvailableCars(0, 1, getEmptySearchCarParams(0))
    expect(availableCars.length).to.equal(1)
    expect(availableCars[0].car.hostPhotoUrl).to.be.eq(photo + 'host')
    expect(availableCars[0].car.hostName).to.be.eq(name + 'host')
  })
})
