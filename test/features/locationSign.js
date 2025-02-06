const { expect } = require('chai')
const { deployDefaultFixture, locationInfo } = require('../utils')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { ethers } = require('hardhat')
const { keccak256 } = require('hardhat/internal/util/keccak')

describe('Location sign', function () {
  let rentalityGateway,
    rentalityMockPriceFeed,
    rentalityUserService,
    rentalityTripService,
    rentalityCurrencyConverter,
    rentalityCarToken,
    rentalityPaymentService,
    rentalityPlatform,
    engineService,
    rentalityAutomationService,
    deliveryService,
    elEngine,
    pEngine,
    hEngine,
    owner,
    admin,
    manager,
    host,
    guest,
    anonymous,
    rentalityAdminGateway,
    rentalityGeoService,
    rentalityLocationVerifier,
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
      engineService,
      rentalityAutomationService,
      deliveryService,
      elEngine,
      pEngine,
      hEngine,
      owner,
      admin,
      manager,
      host,
      guest,
      anonymous,
      rentalityAdminGateway,
      rentalityGeoService,
      rentalityLocationVerifier,
      rentalityView,
    } = await loadFixture(deployDefaultFixture))
  })

  it('signed location should be verified', async function () {
    let domainInfo = await rentalityLocationVerifier.eip712Domain()

    const domain = {
      name: domainInfo[1],
      version: domainInfo[2],
      chainId: domainInfo[3],
      verifyingContract: domainInfo[4],
    }
    const data = {
      LocationInfo: [
        { name: 'userAddress', type: 'string' },
        { name: 'country', type: 'string' },
        { name: 'state', type: 'string' },
        { name: 'city', type: 'string' },
        { name: 'latitude', type: 'string' },
        { name: 'longitude', type: 'string' },
        { name: 'timeZoneId', type: 'string' },
      ],
    }
    let signedMessage = admin.signTypedData(domain, data, locationInfo)
    let location = {
      locationInfo,
      signature: signedMessage,
    }
    await expect(rentalityGeoService.verifySignedLocationInfo(location)).to.not.reverted
  })
  it.skip('signed location should not be verified with wrong signer', async function () {
    let domainInfo = await rentalityLocationVerifier.eip712Domain()

    const domain = {
      name: 'RentalityLocationVerifier',
      version: '1',
      chainId: 1337,
      verifyingContract: domainInfo[4], // RentalityLocationVerifier address
    }
    const data = {
      LocationInfo: [
        { name: 'userAddress', type: 'string' },
        { name: 'country', type: 'string' },
        { name: 'state', type: 'string' },
        { name: 'city', type: 'string' },
        { name: 'latitude', type: 'string' },
        { name: 'longitude', type: 'string' },
        { name: 'timeZoneId', type: 'string' },
      ],
    }
    let signedMessage = host.signTypedData(domain, data, locationInfo)
    let location = {
      locationInfo,
      signature: signedMessage,
    }
    await expect(rentalityGeoService.verifySignedLocationInfo(location)).to.be.reverted
  })
})
