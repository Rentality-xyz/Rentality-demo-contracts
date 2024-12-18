const { expect } = require('chai')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')

const { getMockCarRequest, locationInfo, zeroHash } = require('../utils')
const { deployFixtureWith1Car, deployDefaultFixture } = require('./deployments')

describe('RentalityCarToken: deployment and update', function () {
  it('Should set the right owner', async function () {
    const { rentalityCarToken, owner } = await loadFixture(deployDefaultFixture)

    expect(await rentalityCarToken.owner()).to.equal(owner.address)
  })

  it("Shouldn't contain tokens when deployed", async function () {
    const { rentalityCarToken } = await loadFixture(deployDefaultFixture)

    expect(await rentalityCarToken.totalSupply()).to.equal(0)
  })

  it('deployFixtureWith1Car should contain 1 tokens when deployed', async function () {
    const { rentalityCarToken } = await loadFixture(deployFixtureWith1Car)

    expect(await rentalityCarToken.totalSupply()).to.equal(1)
  })
})
it('Update car without location should work fine', async function () {
  const { rentalityCarToken, rentalityLocationVerifier, admin, rentalityGateway } =
    await loadFixture(deployFixtureWith1Car)

  let request = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
  await expect(rentalityGateway.addCar(request, zeroHash)).not.be.reverted

  let update_params = {
    carId: 2,
    pricePerDayInUsdCents: 2,
    securityDepositPerTripInUsdCents: 2,
    engineParams: [2, 2],
    milesIncludedPerDay: 2,
    timeBufferBetweenTripsInSec: 0,
    currentlyListed: false,
    insuranceRequired: false,
    insurancePriceInUsdCents: 0,
    tokenUri: 'uri',
    engineType: 1,
  }

  await expect(rentalityCarToken.updateCarInfo(update_params, locationInfo, 'das')).not.be.reverted

  let car_info = await rentalityCarToken.getCarInfoById(2)

  expect(car_info.pricePerDayInUsdCents).to.be.equal(update_params.pricePerDayInUsdCents)
  expect(car_info.securityDepositPerTripInUsdCents).to.be.equal(update_params.securityDepositPerTripInUsdCents)
  expect(car_info.engineParams[1]).to.be.equal(update_params.engineParams[0])
  expect(car_info.milesIncludedPerDay).to.be.equal(update_params.milesIncludedPerDay)
})
it('Update car with location, but without api should revert', async function () {
  const { rentalityCarToken, rentalityLocationVerifier, admin,rentalityGateway } = await loadFixture(deployFixtureWith1Car)

  let request = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
  await expect(rentalityCarToken.addCar(request)).not.be.reverted

  let update_params = {
    carId: 2,
    pricePerDayInUsdCents: 2,
    securityDepositPerTripInUsdCents: 2,
    engineParams: [2, 2],
    milesIncludedPerDay: 2,
    timeBufferBetweenTripsInSec: 0,
    currentlyListed: false,
    insuranceRequired: false,
    insurancePriceInUsdCents: 0,
    engineType: 1,
    tokenUri: 'uri',
  }

  await expect(rentalityGateway.updateCarInfoWithLocation(update_params, locationInfo)).to.be.reverted
})
//unused
it.skip('Update with location should pass locationVarification param to false', async function () {
  const { rentalityCarToken, rentalityGeoService, geoParserMock, rentalityLocationVerifier, admin, rentalityGateway } =
    await loadFixture(deployFixtureWith1Car)

  let request = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin, zeroHash)
  await expect(rentalityGateway.addCar(request, zeroHash)).not.be.reverted

  let update_params = {
    carId: 2,
    pricePerDayInUsdCents: 2,
    securityDepositPerTripInUsdCents: 2,
    engineParams: [2],
    timeBufferBetweenTripsInSec: 0,
    milesIncludedPerDay: 2,
    currentlyListed: false,
    insuranceRequired: false,
    insurancePriceInUsdCents: 0,
  }

  await geoParserMock.setCarCoordinateValidity(2, true) // mock

  await expect(rentalityCarToken.verifyGeo(2)).to.not.reverted

  await expect(rentalityCarToken.updateCarInfo(update_params, locationInfo, 'geoApi')).to.not.reverted

  let car_info = await rentalityCarToken.getCarInfoById(2)

  expect(car_info.geoVerified).to.be.equal(false)
})
