const { getMockCarRequest, deployDefaultFixture } = require('../utils')

async function deployFixtureWith1Car() {
  const fixture = await deployDefaultFixture()
  const { rentalityGateway, rentalityLocationVerifier, admin } = fixture

  const request = getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin)
  await rentalityGateway.connect(fixture.host).addCar(request)

  return fixture
}

module.exports = {
  deployDefaultFixture,
  deployFixtureWith1Car,
}
