const { loadFixture, time } = require('@nomicfoundation/hardhat-network-helpers')
const { expect } = require('chai')
const {
  getMockCarRequest,
  ethToken,
  calculatePayments,
  signTCMessage,
  emptyKyc,
  signKycInfo,
  getEmptySearchCarParams,
  UserRole,
  zeroHash,
  emptyLocationInfo,
  emptySignedLocationInfo,
} = require('../utils')
const { deployFixtureWithUsers, deployDefaultFixture } = require('./deployments')

describe('RentalityUserService: KYC management', function () {
  it("By default user doesn't have valid KYC", async function () {
    const { rentalityUserService, anonymous } = await loadFixture(deployFixtureWithUsers)

    expect(await rentalityUserService.hasValidKYC(anonymous.address)).to.equal(false)
  })

  it('After adding valid KYCInfo user has valid KYC', async function () {
    const { rentalityUserService, guest, owner, anonymous, rentalityGateway, rentalityLocationVerifier, admin } =
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
    await rentalityGateway.connect(guest).setKYCInfo('name', 'surname', 'phoneNumber', guestSignature)

    await expect(
      await rentalityUserService.connect(owner).manageRole(UserRole.KYCManager, await anonymous.getAddress(), true)
    ).to.not.reverted

    await expect(rentalityGateway.connect(anonymous).setCivicKYCInfo(guest.address, kyc)).to.not.reverted

    expect(await rentalityUserService.hasValidKYC(guest.address)).to.equal(true)
  })

  it("After adding invalid KYCInfo user doesn't have valid KYC", async function () {
    const { rentalityUserService, guest, rentalityGateway, adminKyc } = await loadFixture(deployDefaultFixture)
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60
    const expirationDate = (await time.latest()) + ONE_YEAR_IN_SECS

    const guestSignature = await signTCMessage(guest)
    await rentalityGateway.connect(guest).setKYCInfo('name', 'surname', 'phoneNumber', guestSignature)
    await time.increaseTo(expirationDate + 1)

    expect(await rentalityUserService.hasValidKYC(guest.address)).to.equal(false)
  })

  it('After adding valid KYCInfo, user can get their own KYCInfo', async function () {
    const { rentalityUserService, guest, rentalityGateway, adminKyc } = await loadFixture(deployDefaultFixture)
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60
    const expirationDate = (await time.latest()) + ONE_YEAR_IN_SECS
    const guestSignature = await signTCMessage(guest)
    await rentalityGateway.connect(guest).setKYCInfo('name', 'phoneNumber', 'profilePicture', guestSignature)

    const kycInfo = await rentalityUserService.connect(guest).getMyKYCInfo()

    expect(kycInfo.name).to.equal('name')
    expect(kycInfo.surname).to.equal('')
    expect(kycInfo.mobilePhoneNumber).to.equal('phoneNumber')
    expect(kycInfo.profilePhoto).to.equal('profilePicture')
  })

  it.skip('User cannot get other users KYCInfo', async function () {
    const { rentalityUserService, guest, host, rentalityGateway, adminKyc } = await loadFixture(deployDefaultFixture)
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60
    const expirationDate = (await time.latest()) + ONE_YEAR_IN_SECS

    const guestSignature = await signTCMessage(guest)
    await rentalityGateway.connect(guest).setKYCInfo('name', 'surname', 'phoneNumber', guestSignature)

    await expect(rentalityUserService.connect(host).getMyKYCInfo(guest.address)).to.be.reverted
  })

  it('Manager can get other users KYCInfo', async function () {
    const { rentalityUserService, guest, manager, owner, anonymous, rentalityGateway } =
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
    await rentalityGateway.connect(guest).setKYCInfo('name', 'phoneNumber', 'profilePicture', guestSignature)

    const isManager = await rentalityUserService.isManager(manager.address)
    expect(isManager).to.equal(true)

    await expect(
      await rentalityUserService.connect(owner).manageRole(UserRole.KYCManager, await anonymous.getAddress(), true)
    ).to.not.reverted

    await expect(rentalityGateway.connect(anonymous).setCivicKYCInfo(guest.address, kyc)).to.not.reverted

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
      rentalityGateway,
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
    } = await loadFixture(deployDefaultFixture)

    const carRequest = getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(carRequest)).not.to.be.reverted
    const availableCars = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsWithDelivery(
        0,
        new Date().getSeconds() + 86400,
        getEmptySearchCarParams(1),
        emptyLocationInfo,
        emptyLocationInfo
      )
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

    await rentalityGateway.connect(guest).setKYCInfo('name', 'phoneNumberGuest', 'surname', guestSignature)
    await rentalityGateway.connect(host).setKYCInfo('name', 'phoneNumberHost', 'surname', hostSignature)
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
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
  it('TC Signature verification', async function () {
    const { host, guest, owner, rentalityUserService, rentalityGateway, adminKyc } =
      await loadFixture(deployDefaultFixture)

    const Signature = await signTCMessage(host)

    await rentalityGateway.connect(host).setKYCInfo('name', 'surname', '13123', Signature)
    const hostData = await rentalityUserService.connect(owner).getKYCInfo(host.address)

    expect(hostData.isTCPassed).to.be.true
    expect(hostData.TCSignature).to.be.eq(Signature)

    await expect(
      rentalityGateway.connect(guest).setKYCInfo('name', 'surname', '13123', Signature)
    ).to.be.revertedWith('Wrong signature.')
  })
})
