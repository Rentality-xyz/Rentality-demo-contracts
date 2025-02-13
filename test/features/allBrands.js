const { expect } = require('chai')
const {
  deployDefaultFixture,
  getMockCarRequest,
  ethToken,
  calculatePayments,
  getEmptySearchCarParams,
  TripStatus,
  zeroHash,
  emptyLocationInfo,
  emptySignedLocationInfo,
} = require('../utils')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { ethers } = require('hardhat')

describe('All brands, models by brand filters', function () {
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
    elEngine,
    pEngine,
    hEngine,
    owner,
    admin,
    manager,
    host,
    guest,
    anonymous,
    rentalityLocationVerifier
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
      elEngine,
      pEngine,
      hEngine,
      owner,
      admin,
      manager,
      host,
      guest,
      anonymous,
      rentalityLocationVerifier,
    } = await loadFixture(deployDefaultFixture))
  })

  it('can get all brands correctly', async function () {
    let request1 = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
    let request2 = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
    let request3 = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
    let request4 = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
    request1.brand = 'bmw'
    request1.carVinNumber = "12"
    request2.brand = 'bmw'
    request3.carVinNumber = "123"
    request3.brand = 'mercedez'
    request4.brand = 'audi'
    request4.carVinNumber = "1235"

    await expect(rentalityGateway.connect(host).addCar(request1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).addCar(request2)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).addCar(request3)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).addCar(request4)).not.to.be.reverted

    const brands = await rentalityGateway.getUniqCarsBrand()
    console.log("BRANDS",brands)
    expect(brands.length).to.be.eq(3)
    expect(brands.find(b => b === 'bmw')).to.not.be.eq(undefined)
    expect(brands.find(b => b === 'mercedez')).to.not.be.eq(undefined)
    expect(brands.find(b => b === 'audi')).to.not.be.eq(undefined)


})
it('can get all models by brand', async function () {
    let request1 = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
    let request2 = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
    let request3 = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
    let request4 = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
    request1.brand = 'bmw'
    request1.model = 'z3'
    request2.carVinNumber = "123"
    request2.brand = 'bmw'
    request2.model = 'x5'
    request3.brand = 'bmw'
    request3.model = 'i8'
    request3.carVinNumber = "124"
    request4.brand = 'audi'
    request4.model = 'q7'
    request4.carVinNumber = "1235"

    await expect(rentalityGateway.connect(host).addCar(request1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).addCar(request2)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).addCar(request3)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).addCar(request4)).not.to.be.reverted

    const models = await rentalityGateway.getUniqModelsByBrand('bmw')
    expect(models.length).to.be.eq(3)
    expect(models.find(b => b === 'z3')).to.not.be.eq(undefined)
    expect(models.find(b => b === 'x5')).to.not.be.eq(undefined)
    expect(models.find(b => b === 'i8')).to.not.be.eq(undefined)

    const models2 = await rentalityGateway.getUniqModelsByBrand('audi')
    expect(models2.length).to.be.eq(1)
    expect(models2[0]).to.be.eq('q7')


})

})