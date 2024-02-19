const { ethers } = require('hardhat')
const { expect } = require('chai')
describe('Rentality geoMock tests', function () {
  it('Should correctly parse address arguments', async function () {
    const RentalityMockGeo = await ethers.getContractFactory('RentalityGeoMock')
    const rentalityGeo = await RentalityMockGeo.deploy(RentalityMockGeo)

    await rentalityGeo.executeRequest('Michigan Ave, Chicago, IL, USA', ' ', ' ', ' ', 1)
    const data = await rentalityGeo.parseGeoResponse(1)
    expect(data.city).to.be.eq('Chicago')
    expect(data.country).to.be.eq('USA')
    expect(data.timeZoneId).to.be.eq('America/Chicago')
  })
})
