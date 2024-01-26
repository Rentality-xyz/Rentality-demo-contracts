const { loadFixture, time } = require('@nomicfoundation/hardhat-network-helpers')
const { expect } = require('chai')
const { getMockCarRequest } = require('../utils')
const { deployFixtureWithUsers, deployDefaultFixture } = require('./deployments')

describe('RentalityUserService: KYC management', function () {
  it("By default user doesn't have valid KYC", async function () {
    const { rentalityUserService, anonymous } = await loadFixture(deployFixtureWithUsers)

    expect(await rentalityUserService.hasValidKYC(anonymous.address)).to.equal(false)
  })

  it('After adding valid KYCInfo user has valid KYC', async function () {
    const { rentalityUserService, guest } = await loadFixture(deployFixtureWithUsers)
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60
    const expirationDate = (await time.latest()) + ONE_YEAR_IN_SECS

    await rentalityUserService
      .connect(guest)
      .setKYCInfo('name', 'surname', 'phoneNumber', 'profilePicture', 'licenseNumber', expirationDate, true, true)

    expect(await rentalityUserService.hasValidKYC(guest.address)).to.equal(true)
  })

  it("After adding invalid KYCInfo user doesn't have valid KYC", async function () {
    const { rentalityUserService, guest } = await loadFixture(deployFixtureWithUsers)
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60
    const expirationDate = (await time.latest()) + ONE_YEAR_IN_SECS

    await rentalityUserService
      .connect(guest)
      .setKYCInfo('name', 'surname', 'phoneNumber', 'profilePicture', 'licenseNumber', expirationDate, true, true)
    await time.increaseTo(expirationDate + 1)

    expect(await rentalityUserService.hasValidKYC(guest.address)).to.equal(false)
  })

  it('After adding valid KYCInfo, user can get their own KYCInfo', async function () {
    const { rentalityUserService, guest } = await loadFixture(deployFixtureWithUsers)
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60
    const expirationDate = (await time.latest()) + ONE_YEAR_IN_SECS

    await rentalityUserService
      .connect(guest)
      .setKYCInfo('name', 'surname', 'phoneNumber', 'profilePicture', 'licenseNumber', expirationDate, true, true)

    const kycInfo = await rentalityUserService.connect(guest).getMyKYCInfo()

    expect(kycInfo.name).to.equal('name')
    expect(kycInfo.surname).to.equal('surname')
    expect(kycInfo.mobilePhoneNumber).to.equal('phoneNumber')
    expect(kycInfo.profilePhoto).to.equal('profilePicture')
    expect(kycInfo.licenseNumber).to.equal('licenseNumber')
    expect(kycInfo.expirationDate).to.equal(expirationDate)
  })

  it('User cannot get other users KYCInfo', async function () {
    const { rentalityUserService, guest, host } = await loadFixture(deployFixtureWithUsers)
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60
    const expirationDate = (await time.latest()) + ONE_YEAR_IN_SECS

    await rentalityUserService
      .connect(guest)
      .setKYCInfo('name', 'surname', 'phoneNumber', 'profilePicture', 'licenseNumber', expirationDate, true, true)

    await expect(rentalityUserService.connect(host).getKYCInfo(guest.address)).to.be.reverted
  })

  it('Manager can get other users KYCInfo', async function () {
    const { rentalityUserService, guest, manager } = await loadFixture(deployFixtureWithUsers)
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60
    const expirationDate = (await time.latest()) + ONE_YEAR_IN_SECS

    await rentalityUserService
      .connect(guest)
      .setKYCInfo('name', 'surname', 'phoneNumber', 'profilePicture', 'licenseNumber', expirationDate, true, true)

    const isManager = await rentalityUserService.isManager(manager.address)
    expect(isManager).to.equal(true)

    const kycInfo = await rentalityUserService.connect(manager).getKYCInfo(guest.address)

    expect(kycInfo.name).to.equal('name')
    expect(kycInfo.surname).to.equal('surname')
    expect(kycInfo.mobilePhoneNumber).to.equal('phoneNumber')
    expect(kycInfo.profilePhoto).to.equal('profilePicture')
    expect(kycInfo.licenseNumber).to.equal('licenseNumber')
    expect(kycInfo.expirationDate).to.equal(expirationDate)
  })
  it('After a trip is requested, the host or guest can get the contact numbers of the host and guest', async function () {
    const {
      rentalityPlatform,
      rentalityCurrencyConverter,
      host,
      rentalityCarToken,
      guest,
      rentalityTripService,
      rentalityUserService,
    } = await loadFixture(deployDefaultFixture)

    await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)
    const rentPriceInUsdCents = 1600
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getEthFromUsdLatest(rentPriceInUsdCents)
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60
    const expirationDate = (await time.latest()) + ONE_YEAR_IN_SECS

    await rentalityUserService
      .connect(guest)
      .setKYCInfo('name', 'surname', 'phoneNumberGuest', 'profilePicture', 'licenseNumber', expirationDate, true, true)
    await rentalityUserService
      .connect(host)
      .setKYCInfo('name', 'surname', 'phoneNumberHost', 'profilePicture', 'licenseNumber', expirationDate, true, true)
    await expect(
      await rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 123,
          endDateTime: 321,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: 1000,
          taxPriceInUsdCents: 200,
          depositInUsdCents: 400,
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted
    expect((await rentalityTripService.connect(host).getTrip(1)).status).to.equal(0)

    let [guestPhoneNumber, hostPhoneNumber] = await rentalityPlatform.connect(guest).getTripContactInfo(1)

    expect(guestPhoneNumber).to.equal('phoneNumberGuest')
    expect(hostPhoneNumber).to.equal('phoneNumberHost')[(guestPhoneNumber, hostPhoneNumber)] = await rentalityPlatform
      .connect(host)
      .getTripContactInfo(1)
    expect(guestPhoneNumber).to.equal('phoneNumberGuest')
    expect(hostPhoneNumber).to.equal('phoneNumberHost')
  })
})
