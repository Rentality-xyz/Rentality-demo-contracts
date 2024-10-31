const { loadFixture, time } = require('@nomicfoundation/hardhat-network-helpers')
const { expect } = require('chai')
const {
  getMockCarRequest,
  ethToken,
  calculatePayments,
  signTCMessage,
  emptyKyc,
  signKycInfo,
  UserRole,
} = require('../utils')
const { deployFixtureWithUsers, deployDefaultFixture } = require('./deployments')

describe('RentalityUserService: KYC management', function () {
  it("By default user doesn't have valid KYC", async function () {
    const { rentalityUserService, anonymous } = await loadFixture(deployFixtureWithUsers)

    expect(await rentalityUserService.hasValidKYC(anonymous.address)).to.equal(false)
  })

  it('After adding valid KYCInfo user has valid KYC', async function () {
    const { rentalityUserService, guest, owner, anonymous, rentalityGateway, rentalityPlatform, admin } =
      await loadFixture(deployDefaultFixture)
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60
    const expirationDate = (await time.latest()) + ONE_YEAR_IN_SECS

    const guestSignature = await signTCMessage(guest)

    let kyc = {
      fullName: '',
      licenseNumber: '',
      expirationDate: expirationDate,
      issueCountry: '',
      email: '',
    }
    await rentalityPlatform.connect(guest).setKYCInfo('name', 'surname', 'phoneNumber', guestSignature)

    await expect(
      await rentalityUserService.connect(owner).manageRole(UserRole.KYCManager, await anonymous.getAddress(), true)
    ).to.not.reverted

    await expect(rentalityPlatform.connect(anonymous).setCivicKYCInfo(guest.address, kyc)).to.not.reverted

    expect(await rentalityUserService.hasValidKYC(guest.address)).to.equal(true)
  })

  it("After adding invalid KYCInfo user doesn't have valid KYC", async function () {
    const { rentalityUserService, guest, rentalityPlatform, adminKyc } = await loadFixture(deployDefaultFixture)
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60
    const expirationDate = (await time.latest()) + ONE_YEAR_IN_SECS

    const guestSignature = await signTCMessage(guest)
    await rentalityPlatform.connect(guest).setKYCInfo('name', 'surname', 'phoneNumber', guestSignature)
    await time.increaseTo(expirationDate + 1)

    expect(await rentalityUserService.hasValidKYC(guest.address)).to.equal(false)
  })

  it('After adding valid KYCInfo, user can get their own KYCInfo', async function () {
    const { rentalityUserService, guest, rentalityPlatform, adminKyc } = await loadFixture(deployDefaultFixture)
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60
    const expirationDate = (await time.latest()) + ONE_YEAR_IN_SECS
    const guestSignature = await signTCMessage(guest)
    await rentalityPlatform.connect(guest).setKYCInfo('name', 'phoneNumber', 'profilePicture', guestSignature)

    const kycInfo = await rentalityUserService.connect(guest).getMyKYCInfo(guest.address)

    expect(kycInfo.name).to.equal('name')
    expect(kycInfo.surname).to.equal('')
    expect(kycInfo.mobilePhoneNumber).to.equal('phoneNumber')
    expect(kycInfo.profilePhoto).to.equal('profilePicture')
  })

  it('User cannot get other users KYCInfo', async function () {
    const { rentalityUserService, guest, host, rentalityPlatform, adminKyc } = await loadFixture(deployDefaultFixture)
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60
    const expirationDate = (await time.latest()) + ONE_YEAR_IN_SECS

    const guestSignature = await signTCMessage(guest)
    await rentalityPlatform.connect(guest).setKYCInfo('name', 'surname', 'phoneNumber', guestSignature)

    await expect(rentalityUserService.connect(host).getKYCInfo(guest.address)).to.be.reverted
  })

  it('Manager can get other users KYCInfo', async function () {
    const { rentalityUserService, guest, manager, owner, anonymous, rentalityPlatform } =
      await loadFixture(deployDefaultFixture)
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60
    const expirationDate = (await time.latest()) + ONE_YEAR_IN_SECS
    let kyc = {
      fullName: 'fullName',
      licenseNumber: 'licenseNumber',
      expirationDate: expirationDate,
      issueCountry: '',
      email: '',
    }

    const guestSignature = await signTCMessage(guest)
    await rentalityPlatform.connect(guest).setKYCInfo('name', 'phoneNumber', 'profilePicture', guestSignature)

    const isManager = await rentalityUserService.isManager(manager.address)
    expect(isManager).to.equal(true)

    await expect(
      await rentalityUserService.connect(owner).manageRole(UserRole.KYCManager, await anonymous.getAddress(), true)
    ).to.not.reverted

    await expect(rentalityPlatform.connect(anonymous).setCivicKYCInfo(guest.address, kyc)).to.not.reverted

    const kycInfo = await rentalityUserService.connect(manager).getKYCInfo(guest.address)

    expect(kycInfo.name).to.equal('name')
    expect(kycInfo.surname).to.equal('fullName')
    expect(kycInfo.mobilePhoneNumber).to.equal('phoneNumber')
    expect(kycInfo.profilePhoto).to.equal('profilePicture')
    expect(kycInfo.licenseNumber).to.equal('licenseNumber')
    expect(kycInfo.expirationDate).to.equal(expirationDate)
  })
  it('After a trip is requested, the host or guest can get the contact numbers of the host and guest', async function () {
    const {
      rentalityPlatform,
      rentalityPaymentService,
      rentalityCurrencyConverter,
      host,
      rentalityCarToken,
      guest,
      rentalityTripService,
      rentalityUserService,
      rentalityLocationVerifier,
      admin,
      adminKyc,
      rentalityView
    } = await loadFixture(deployDefaultFixture)

    const carRequest = getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityPlatform.connect(host).addCar(carRequest)).not.to.be.reverted
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

    await rentalityPlatform.connect(guest).setKYCInfo('name', 'phoneNumberGuest', 'surname', guestSignature)
    await rentalityPlatform.connect(host).setKYCInfo('name', 'phoneNumberHost', 'surname', hostSignature)
    await expect(
      await rentalityPlatform.connect(guest).createTripRequest(
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

    let [guestPhoneNumber, hostPhoneNumber] = await rentalityView.connect(guest).getTripContactInfo(1)

    expect(guestPhoneNumber).to.equal('phoneNumberGuest')
    expect(hostPhoneNumber).to.equal('phoneNumberHost')[(guestPhoneNumber, hostPhoneNumber)] = await rentalityView
      .connect(host)
      .getTripContactInfo(1)
    expect(guestPhoneNumber).to.equal('phoneNumberGuest')
    expect(hostPhoneNumber).to.equal('phoneNumberHost')
  })
  it('TC signature verification', async function () {
    const { host, guest, owner, rentalityUserService, rentalityPlatform, adminKyc } =
      await loadFixture(deployDefaultFixture)

    const signature = await signTCMessage(host)

    await rentalityPlatform.connect(host).setKYCInfo('name', 'surname', '13123', signature)
    const hostData = await rentalityUserService.connect(owner).getKYCInfo(host.address)

    expect(hostData.isTCPassed).to.be.true
    expect(hostData.TCSignature).to.be.eq(signature)

    await expect(rentalityPlatform.connect(guest).setKYCInfo('name', 'surname', '13123', signature)).to.be.revertedWith(
      'Wrong signature.'
    )
  })
})
