const { expect } = require('chai')
const { ethers, upgrades } = require('hardhat')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { deployDefaultFixture } = require('../utils')

describe('RentalityGateway: proxy', function () {
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
    query,
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
      query,
      claimService,
      owner,
      admin,
      manager,
      host,
      guest,
      anonymous,
    } = await loadFixture(deployDefaultFixture))
  })

  it('should not be able to update carToken without access', async function () {
    const RentalityCarToken = await ethers.getContractFactory('RentalityCarToken', {
      libraries: {
        RentalityUtils: await utils.getAddress(),
      },
      signer: anonymous,
    })

    const RentalityCarTokenHost = await ethers.getContractFactory('RentalityCarToken', {
      libraries: {
        RentalityUtils: await utils.getAddress(),
      },
      signer: host,
    })
    const RentalityCarTokenGuest = await ethers.getContractFactory('RentalityCarToken', {
      libraries: {
        RentalityUtils: await utils.getAddress(),
      },
      signer: guest,
    })
    const RentalityCarTokenOwner = await ethers.getContractFactory('RentalityCarToken', {
      libraries: {
        RentalityUtils: await utils.getAddress(),
      },
      signer: owner,
    })
    const carTokenAddress = await rentalityCarToken.getAddress()

    await expect(upgrades.upgradeProxy(carTokenAddress, RentalityCarToken, { kind: 'uups' })).to.be.revertedWith(
      'Ownable: caller is not the owner'
    )
    await expect(upgrades.upgradeProxy(carTokenAddress, RentalityCarTokenHost, { kind: 'uups' })).to.be.revertedWith(
      'Ownable: caller is not the owner'
    )
    await expect(upgrades.upgradeProxy(carTokenAddress, RentalityCarTokenGuest, { kind: 'uups' })).to.be.revertedWith(
      'Ownable: caller is not the owner'
    )
    expect(await upgrades.upgradeProxy(carTokenAddress, RentalityCarTokenOwner, { kind: 'uups' })).to.not.reverted
  })
  it('should not be able to update chatHelper without access', async function () {
    const ChatHelper = await ethers.getContractFactory('RentalityChatHelper', {
      libraries: {},
    })
    const chatHelper = await upgrades.deployProxy(ChatHelper, [await rentalityUserService.getAddress()])
    await chatHelper.waitForDeployment()

    const ChatHelperAnon = await ethers.getContractFactory('RentalityChatHelper', anonymous)
    const ChatHelperGuest = await ethers.getContractFactory('RentalityChatHelper', guest)
    const ChatHelperHost = await ethers.getContractFactory('RentalityChatHelper', host)
    const ChatHelperAdmin = await ethers.getContractFactory('RentalityChatHelper', admin)
    const chatHelperAdd = await chatHelper.getAddress()

    await expect(upgrades.upgradeProxy(chatHelperAdd, ChatHelperAnon, { kind: 'uups' })).to.be.revertedWith(
      'Only for Admin.'
    )
    await expect(upgrades.upgradeProxy(chatHelperAdd, ChatHelperGuest, { kind: 'uups' })).to.be.revertedWith(
      'Only for Admin.'
    )
    await expect(upgrades.upgradeProxy(chatHelperAdd, ChatHelperHost, { kind: 'uups' })).to.be.revertedWith(
      'Only for Admin.'
    )
    expect(await upgrades.upgradeProxy(chatHelperAdd, ChatHelperAdmin, { kind: 'uups' })).to.not.reverted
  })
  it('should not be able to update gateway without access', async function () {
    const GatewayAnonn = await ethers.getContractFactory('RentalityGateway', {
      libraries: {},
      signer: anonymous,
    })
    const GatewayGuest = await ethers.getContractFactory('RentalityGateway', {
      libraries: {},
      signer: guest,
    })
    const GatewayHost = await ethers.getContractFactory('RentalityGateway', {
      libraries: {},
      signer: host,
    })
    const GatewayOwner = await ethers.getContractFactory('RentalityGateway', {
      libraries: {},
      signer: owner,
    })
    const gatewayAdd = await rentalityGateway.getAddress()

    await expect(upgrades.upgradeProxy(gatewayAdd, GatewayAnonn, { kind: 'uups' })).to.be.revertedWith(
      'Ownable: caller is not the owner'
    )
    await expect(upgrades.upgradeProxy(gatewayAdd, GatewayGuest, { kind: 'uups' })).to.be.revertedWith(
      'Ownable: caller is not the owner'
    )
    await expect(upgrades.upgradeProxy(gatewayAdd, GatewayHost, { kind: 'uups' })).to.be.revertedWith(
      'Ownable: caller is not the owner'
    )
    expect(await upgrades.upgradeProxy(gatewayAdd, GatewayOwner, { kind: 'uups' })).to.not.reverted
  })

  it('should not be able to update platform without access', async function () {
    const RentalityPlatformAnnon = await ethers.getContractFactory('RentalityPlatform', {
      libraries: {
        RentalityUtils: await utils.getAddress(),
      },
      signer: anonymous,
    })
    const RentalityPlatformHost = await ethers.getContractFactory('RentalityPlatform', {
      libraries: {
        RentalityUtils: await utils.getAddress(),
      },
      signer: host,
    })
    const RentalityPlatformGuest = await ethers.getContractFactory('RentalityPlatform', {
      libraries: {
        RentalityUtils: await utils.getAddress(),
      },
      signer: guest,
    })
    const RentalityPlatformOwner = await ethers.getContractFactory('RentalityPlatform', {
      libraries: {
        RentalityUtils: await utils.getAddress(),
      },
      signer: owner,
    })
    const platformAdd = await rentalityPlatform.getAddress()

    await expect(upgrades.upgradeProxy(platformAdd, RentalityPlatformAnnon, { kind: 'uups' })).to.be.revertedWith(
      'Ownable: caller is not the owner'
    )
    await expect(upgrades.upgradeProxy(platformAdd, RentalityPlatformGuest, { kind: 'uups' })).to.be.revertedWith(
      'Ownable: caller is not the owner'
    )
    await expect(upgrades.upgradeProxy(platformAdd, RentalityPlatformHost, { kind: 'uups' })).to.be.revertedWith(
      'Ownable: caller is not the owner'
    )
    expect(await upgrades.upgradeProxy(platformAdd, RentalityPlatformOwner, { kind: 'uups' })).to.not.reverted
  })
})
