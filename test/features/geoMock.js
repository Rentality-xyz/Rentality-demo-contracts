const { ethers } = require('hardhat')
const { expect } = require('chai')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { deployDefaultFixture } = require('../utils')
describe('Rentality geoMock tests', function () {
  let rentalityGeoService

  beforeEach(async function () {
    ;({ rentalityGeoService } = await loadFixture(deployDefaultFixture))
  })
  it('Should correctly parse address arguments', async function () {
    await rentalityGeoService.executeRequest('Michigan Ave, Chicago, IL, USA', ' ', ' ', ' ', 1)

    const city = await rentalityGeoService.getCarCity(1)
    const country = await rentalityGeoService.getCarCountry(1)
    const timeZoneId = await rentalityGeoService.getCarTimeZoneId(1)

    expect(city).to.be.eq('Chicago')
    expect(country).to.be.eq('USA')
    expect(timeZoneId).to.be.eq('America/Chicago')
  })
})
