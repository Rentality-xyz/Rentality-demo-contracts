const { loadFixture, time } = require('@nomicfoundation/hardhat-network-helpers')
const { expect } = require('chai')
const { getMockCarRequest, ethToken, calculatePayments, signTCMessage } = require('../utils')
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

    const guestSignature = await signTCMessage(guest)
    await rentalityUserService
      .connect(guest)
      .setKYCInfo('name', 'surname', 'phoneNumber', 'profilePicture', 'licenseNumber', expirationDate, guestSignature)

    expect(await rentalityUserService.hasValidKYC(guest.address)).to.equal(true)
  })

  it("After adding invalid KYCInfo user doesn't have valid KYC", async function () {
    const { rentalityUserService, guest } = await loadFixture(deployFixtureWithUsers)
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60
    const expirationDate = (await time.latest()) + ONE_YEAR_IN_SECS

    const guestSignature = await signTCMessage(guest)
    await rentalityUserService
      .connect(guest)
      .setKYCInfo('name', 'surname', 'phoneNumber', 'profilePicture', 'licenseNumber', expirationDate, guestSignature)
    await time.increaseTo(expirationDate + 1)

    expect(await rentalityUserService.hasValidKYC(guest.address)).to.equal(false)
  })

  it('After adding valid KYCInfo, user can get their own KYCInfo', async function () {
    const { rentalityUserService, guest } = await loadFixture(deployFixtureWithUsers)
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60
    const expirationDate = (await time.latest()) + ONE_YEAR_IN_SECS
    const guestSignature = await signTCMessage(guest)
    await rentalityUserService
      .connect(guest)
      .setKYCInfo('name', 'surname', 'phoneNumber', 'profilePicture', 'licenseNumber', expirationDate, guestSignature)

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

    const guestSignature = await signTCMessage(guest)
    await rentalityUserService
      .connect(guest)
      .setKYCInfo('name', 'surname', 'phoneNumber', 'profilePicture', 'licenseNumber', expirationDate, guestSignature)

    await expect(rentalityUserService.connect(host).getKYCInfo(guest.address)).to.be.reverted
  })

  it('Manager can get other users KYCInfo', async function () {
    const { rentalityUserService, guest, manager } = await loadFixture(deployFixtureWithUsers)
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60
    const expirationDate = (await time.latest()) + ONE_YEAR_IN_SECS

    const guestSignature = await signTCMessage(guest)
    await rentalityUserService
      .connect(guest)
      .setKYCInfo('name', 'surname', 'phoneNumber', 'profilePicture', 'licenseNumber', expirationDate, guestSignature)

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
      rentalityGateway,
      rentalityPaymentService,
      rentalityCurrencyConverter,
      host,
      rentalityCarToken,
      guest,
      rentalityTripService,
      rentalityUserService,
    } = await loadFixture(deployDefaultFixture)

    const carRequest = getMockCarRequest(0)
    await expect(rentalityCarToken.connect(host).addCar(carRequest)).not.to.be.reverted
    const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)
    const rentPrice = carRequest.pricePerDayInUsdCents
    const deposit = carRequest.securityDepositPerTripInUsdCents

    const { rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals } = await calculatePayments(
      rentalityCurrencyConverter,
      rentalityPaymentService,
      rentPrice,
      1,
      deposit
    )

    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60
    const expirationDate = (await time.latest()) + ONE_YEAR_IN_SECS

    const hostSignature = await signTCMessage(host)
    const guestSignature = await signTCMessage(guest)

    await rentalityUserService
      .connect(guest)
      .setKYCInfo(
        'name',
        'surname',
        'phoneNumberGuest',
        'profilePicture',
        'licenseNumber',
        expirationDate,
        guestSignature
      )
    await rentalityUserService
      .connect(host)
      .setKYCInfo(
        'name',
        'surname',
        'phoneNumberHost',
        'profilePicture',
        'licenseNumber',
        expirationDate,
        hostSignature
      )
    await expect(
      await rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted

    expect((await rentalityTripService.connect(host).getTrip(1)).status).to.equal(0)

    let [guestPhoneNumber, hostPhoneNumber] = await rentalityGateway.connect(guest).getTripContactInfo(1)

    expect(guestPhoneNumber).to.equal('phoneNumberGuest')
    expect(hostPhoneNumber).to.equal('phoneNumberHost')[(guestPhoneNumber, hostPhoneNumber)] = await rentalityGateway
      .connect(host)
      .getTripContactInfo(1)
    expect(guestPhoneNumber).to.equal('phoneNumberGuest')
    expect(hostPhoneNumber).to.equal('phoneNumberHost')
  })
  it('TC signature verification', async function () {
    const { host, guest, owner, rentalityUserService, rentalityGateway } = await loadFixture(deployDefaultFixture)

    const signature = await signTCMessage(host)

    await rentalityUserService.connect(host).setKYCInfo('name', 'surname', '13123', 'photo', 'num', 123123, signature)
    const hostData = await rentalityUserService.connect(owner).getKYCInfo(host.address)

    expect(hostData.isTCPassed).to.be.true
    expect(hostData.TCSignature).to.be.eq(signature)

    await expect(
      rentalityUserService.connect(guest).setKYCInfo('name', 'surname', '13123', 'photo', 'num', 123123, signature)
    ).to.be.revertedWith('Wrong signature.')
  })
})
