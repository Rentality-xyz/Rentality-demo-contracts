const { expect } = require('chai')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')

const {
  getMockCarRequest,

  deployDefaultFixture,
  getEmptySearchCarParams,
  ethToken,
} = require('../utils')

describe('RentalityGateway: user info', function () {
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

    await expect(
      rentalityGateway.connect(host).setKYCInfo(name, surname, number, photo, licenseNumber, expirationDate, true, true)
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

    await expect(
      rentalityGateway
        .connect(guest)
        .setKYCInfo(name, surname, number, photo, licenseNumber, expirationDate, true, true)
    ).not.be.reverted

    const kycInfo = await rentalityGateway.connect(guest).getMyKYCInfo()

    expect(kycInfo.name).to.equal(name)
    expect(kycInfo.surname).to.equal(surname)
    expect(kycInfo.mobilePhoneNumber).to.equal(number)
    expect(kycInfo.profilePhoto).to.equal(photo)
    expect(kycInfo.licenseNumber).to.equal(licenseNumber)
    expect(kycInfo.expirationDate).to.equal(expirationDate)
  })

  it('Should not anonymous be able to create KYC', async function () {
    let name = 'name'
    let surname = 'surname'
    let number = '+380'
    let photo = 'photo'
    let licenseNumber = 'licenseNumber'
    let expirationDate = 10

    await expect(
      rentalityUserService
        .connect(anonymous)
        .setKYCInfo(name, surname, number, photo, licenseNumber, expirationDate, true, true)
    ).to.be.reverted
  })

  it('Guest should be able to get trip contacts', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 1,
          endDateTime: 1,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted

    let guestNumber = '+380'
    let hostNumber = '+3801'
    await expect(
      rentalityUserService.connect(guest).setKYCInfo('name', 'surname', guestNumber, 'photo', 'number', 1, true, true)
    ).not.be.reverted

    await expect(
      rentalityUserService.connect(host).setKYCInfo('name', 'surname', hostNumber, 'photo', 'number', 1, true, true)
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

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 1,
          endDateTime: 1,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted

    let guestNumber = '+380'
    let hostNumber = '+3801'
    await expect(
      rentalityGateway.connect(guest).setKYCInfo('name', 'surname', guestNumber, 'photo', 'number', 1, true, true)
    ).not.be.reverted

    await expect(
      rentalityGateway.connect(host).setKYCInfo('name', 'surname', hostNumber, 'photo', 'number', 1, true, true)
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

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 1,
          endDateTime: 1,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted

    let guestNumber = '+380'
    let hostNumber = '+3801'
    await expect(
      rentalityGateway.connect(guest).setKYCInfo('name', 'surname', guestNumber, 'photo', 'number', 1, true, true)
    ).not.be.reverted

    await expect(
      rentalityGateway.connect(host).setKYCInfo('name', 'surname', hostNumber, 'photo', 'number', 1, true, true)
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
          true,
          true
        )
    ).not.be.reverted

    const availableCars = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsForUser(guest.address, 0, 0, getEmptySearchCarParams(0))
    expect(availableCars.length).to.equal(1)

    expect(availableCars[0].hostPhotoUrl).to.be.eq(photo + 'host')
    expect(availableCars[0].hostName).to.be.eq(name + 'host')
  })
})
