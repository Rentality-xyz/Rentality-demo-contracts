const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { expect } = require('chai')
const { getMockCarRequest } = require('../utils')
const { getEmptySearchCarParams, emptyLocationInfo } = require('../utils')
const { deployDefaultFixture } = require('./deployments')
describe('Rentality: cars', function () {
  it('Host can add car to rentality', async function () {
    const { carGatewayAdapter, rentalityGateway, host, admin, rentalityLocationVerifier } =
      await loadFixture(deployDefaultFixture)

    await expect(
      rentalityGateway.connect(host).addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).not.to.be.reverted
    const myCars = await carGatewayAdapter.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)
  })
  it('Host dont see own cars as available', async function () {
    const { rentalityGateway, carGatewayAdapter, host, rentalityLocationVerifier, admin } =
      await loadFixture(deployDefaultFixture)

    await expect(
      rentalityGateway.connect(host).addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).not.to.be.reverted
    const myCars = await carGatewayAdapter.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)
    const availableCars = await carGatewayAdapter.connect(host).getAvailableCarsForUser(host.address)
    expect(availableCars.length).to.equal(0)
  })
  it('Guest see cars as available', async function () {
    const { carGatewayAdapter, host, guest, rentalityLocationVerifier, admin, rentalityGateway } =
      await loadFixture(deployDefaultFixture)

    await expect(
      rentalityGateway.connect(host).addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).not.to.be.reverted
    const myCars = await carGatewayAdapter.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsWithDelivery(
        0,
        new Date().getSeconds() + 86400,
        getEmptySearchCarParams(1),
        emptyLocationInfo,
        emptyLocationInfo,0,10
      )
    expect(availableCars.cars.length).to.equal(1)
  })
})


