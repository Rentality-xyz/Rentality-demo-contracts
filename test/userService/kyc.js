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
} = require('../utils')
const { deployFixtureWithUsers, deployDefaultFixture } = require('./deployments')

describe('RentalityUserService: KYC management', function () {
  it("By default user doesn't have valid KYC", async function () {
    const { rentalityUserService, anonymous } = await loadFixture(deployFixtureWithUsers)

    expect(await rentalityUserService.hasValidKYC(anonymous.address)).to.equal(false)
  })

  it('After adding valid KYCInfo user has valid KYC', async function () {
    const { rentalityUserService, guest, adminKyc, rentalityGateway, rentalityLocationVerifier, admin } =
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
    const adminKYCSign = signKycInfo(await rentalityLocationVerifier.getAddress(), admin, kyc)
    await rentalityGateway
      .connect(guest)
      .setKYCInfo('name', 'surname', 'phoneNumber', kyc, guestSignature, adminKYCSign)

    expect(await rentalityUserService.hasValidKYC(guest.address)).to.equal(true)
  })

  it("After adding invalid KYCInfo user doesn't have valid KYC", async function () {
    const { rentalityUserService, guest, rentalityGateway, adminKyc } = await loadFixture(deployDefaultFixture)
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60
    const expirationDate = (await time.latest()) + ONE_YEAR_IN_SECS

    const guestSignature = await signTCMessage(guest)
    await rentalityGateway
      .connect(guest)
      .setKYCInfo('name', 'surname', 'phoneNumber', emptyKyc, guestSignature, adminKyc)
    await time.increaseTo(expirationDate + 1)

    expect(await rentalityUserService.hasValidKYC(guest.address)).to.equal(false)
  })

  it('After adding valid KYCInfo, user can get their own KYCInfo', async function () {
    const { rentalityUserService, guest, rentalityGateway, adminKyc } = await loadFixture(deployDefaultFixture)
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60
    const expirationDate = (await time.latest()) + ONE_YEAR_IN_SECS
    const guestSignature = await signTCMessage(guest)
    await rentalityGateway
      .connect(guest)
      .setKYCInfo('name', 'phoneNumber', 'profilePicture', emptyKyc, guestSignature, adminKyc)

    const kycInfo = await rentalityUserService.connect(guest).getMyKYCInfo()

    expect(kycInfo.name).to.equal('name')
    expect(kycInfo.surname).to.equal('')
    expect(kycInfo.mobilePhoneNumber).to.equal('phoneNumber')
    expect(kycInfo.profilePhoto).to.equal('profilePicture')
  })

  it('User cannot get other users KYCInfo', async function () {
    const { rentalityUserService, guest, host, rentalityGateway, adminKyc } = await loadFixture(deployDefaultFixture)
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60
    const expirationDate = (await time.latest()) + ONE_YEAR_IN_SECS

    const guestSignature = await signTCMessage(guest)
    await rentalityGateway
      .connect(guest)
      .setKYCInfo('name', 'surname', 'phoneNumber', emptyKyc, guestSignature, adminKyc)

    await expect(rentalityUserService.connect(host).getKYCInfo(guest.address)).to.be.reverted
  })

  it('Manager can get other users KYCInfo', async function () {
    const { rentalityUserService, guest, manager, adminKyc, rentalityLocationVerifier, admin, rentalityGateway } =
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
    let signature = signKycInfo(await rentalityLocationVerifier.getAddress(), admin, kyc)

    const guestSignature = await signTCMessage(guest)
    await rentalityGateway
      .connect(guest)
      .setKYCInfo('name', 'phoneNumber', 'profilePicture', kyc, guestSignature, signature)

    const isManager = await rentalityUserService.isManager(manager.address)
    expect(isManager).to.equal(true)

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
    await expect(rentalityCarToken.connect(host).addCar(carRequest)).not.to.be.reverted
    const availableCars = await rentalityGateway
      .connect(guest)
      .searchAvailableCars(0, new Date().getSeconds() + 86400, getEmptySearchCarParams(1))
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

    await rentalityGateway
      .connect(guest)
      .setKYCInfo('name', 'phoneNumberGuest', 'surname', emptyKyc, guestSignature, adminKyc)
    await rentalityGateway
      .connect(host)
      .setKYCInfo('name', 'phoneNumberHost', 'surname', emptyKyc, hostSignature, adminKyc)
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
    const { host, guest, owner, rentalityUserService, rentalityGateway, adminKyc } =
      await loadFixture(deployDefaultFixture)

    const signature = await signTCMessage(host)

    await rentalityGateway.connect(host).setKYCInfo('name', 'surname', '13123', emptyKyc, signature, adminKyc)
    const hostData = await rentalityUserService.connect(owner).getKYCInfo(host.address)

    expect(hostData.isTCPassed).to.be.true
    expect(hostData.TCSignature).to.be.eq(signature)

    await expect(
      rentalityGateway.connect(guest).setKYCInfo('name', 'surname', '13123', emptyKyc, signature, adminKyc)
    ).to.be.revertedWith('Wrong signature.')
  })
})
