const { expect } = require('chai')

const { deployDefaultFixture } = require('../utils')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')

describe('RentalityGateway: update fields', function () {
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
    rentalityView

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
      rentalityView,
    } = await loadFixture(deployDefaultFixture))
  })

  it('should has right owner', async function () {
    expect(await rentalityGateway.owner()).to.equal(owner.address)
  })

  it('should allow only admin to update car service address', async function () {
    await expect(rentalityAdminGateway.connect(guest).updateCarService(await rentalityCarToken.getAddress())).to.be
      .reverted

    await expect(rentalityAdminGateway.connect(host).updateCarService(await rentalityCarToken.getAddress())).to.be
      .reverted

    await expect(rentalityAdminGateway.connect(anonymous).updateCarService(await rentalityCarToken.getAddress())).to.be
      .reverted

    await expect(rentalityAdminGateway.connect(admin).updateCarService(await rentalityCarToken.getAddress())).not.be
      .reverted
  })
  it('should allow only admin to update rentality platform address', async function () {
    await expect(rentalityAdminGateway.connect(guest).updateRentalityPlatform(await rentalityPlatform.getAddress())).to
      .be.reverted

    await expect(rentalityAdminGateway.connect(host).updateRentalityPlatform(await rentalityPlatform.getAddress())).to
      .be.reverted

    await expect(rentalityAdminGateway.connect(anonymous).updateRentalityPlatform(await rentalityPlatform.getAddress()))
      .to.be.reverted

    await expect(rentalityAdminGateway.connect(admin).updateRentalityPlatform(await rentalityPlatform.getAddress())).not
      .be.reverted
  })

  it('should allow only admin to update currency converter service address', async function () {
    await expect(
      rentalityAdminGateway.connect(guest).updateCurrencyConverterService(await rentalityCurrencyConverter.getAddress())
    ).to.be.reverted

    await expect(
      rentalityAdminGateway.connect(host).updateCurrencyConverterService(await rentalityCurrencyConverter.getAddress())
    ).to.be.reverted

    await expect(
      rentalityAdminGateway
        .connect(anonymous)
        .updateCurrencyConverterService(await rentalityCurrencyConverter.getAddress())
    ).to.be.reverted

    await expect(
      rentalityAdminGateway.connect(admin).updateCurrencyConverterService(await rentalityCurrencyConverter.getAddress())
    ).not.be.reverted
  })

  it('should allow only admin to update trip service address', async function () {
    await expect(rentalityAdminGateway.connect(admin).updateTripService(await rentalityTripService.getAddress())).not.be
      .reverted

    await expect(rentalityAdminGateway.connect(host).updateTripService(await rentalityTripService.getAddress())).to.be
      .reverted

    await expect(rentalityAdminGateway.connect(guest).updateTripService(await rentalityTripService.getAddress())).to.be
      .reverted

    await expect(rentalityAdminGateway.connect(anonymous).updateTripService(await rentalityTripService.getAddress())).to
      .be.reverted
  })

  it('should allow only admin to update user service address', async function () {
    await expect(rentalityAdminGateway.connect(anonymous).updateUserService(await rentalityUserService.getAddress())).to
      .be.reverted

    await expect(rentalityAdminGateway.connect(host).updateUserService(await rentalityUserService.getAddress())).to.be
      .reverted

    await expect(rentalityAdminGateway.connect(guest).updateUserService(await rentalityUserService.getAddress())).to.be
      .reverted

    await expect(rentalityAdminGateway.connect(admin).updateUserService(await rentalityUserService.getAddress())).not.be
      .reverted
  })

  it('should allow only admin to set platform fee in PPM', async function () {
    await expect(rentalityAdminGateway.connect(admin).setPlatformFeeInPPM(10)).not.to.be.reverted

    await expect(rentalityAdminGateway.connect(host).setPlatformFeeInPPM(10)).to.be.reverted

    await expect(rentalityAdminGateway.connect(guest).setPlatformFeeInPPM(10)).to.be.reverted

    await expect(rentalityAdminGateway.connect(anonymous).setPlatformFeeInPPM(10)).to.be.reverted
  })

  it('should update platform Fee in PMM', async function () {
    let platformFeeInPMM = 10101

    await expect(rentalityAdminGateway.connect(owner).setPlatformFeeInPPM(platformFeeInPMM)).not.to.be.reverted

    expect(await rentalityAdminGateway.getPlatformFeeInPPM()).to.equal(platformFeeInPMM)
  })
})
