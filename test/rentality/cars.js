const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { expect } = require('chai')
const { getMockCarRequest,getEmptySearchCarParams } = require('../utils')
const { deployDefaultFixture } = require('./deployments')
describe('Rentality: cars', function () {
  it('Host can add car to rentality', async function () {
    const { rentalityCarToken, host, admin, rentalityLocationVerifier } = await loadFixture(deployDefaultFixture)

    await expect(
      rentalityCarToken.connect(host).addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)
  })
  it('Host dont see own cars as available', async function () {
    const { rentalityCarToken, host,rentalityLocationVerifier, rentalityGateway,admin } = await loadFixture(deployDefaultFixture)

    await expect(
      rentalityCarToken.connect(host).addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityCarToken.connect(host).getAvailableCarsForUser(host.address)
    expect(availableCars.length).to.equal(0)
  })
  it('Guest see cars as available', async function () {
    const { rentalityCarToken,rentalityGateway, host, guest, rentalityLocationVerifier, admin } = await loadFixture(deployDefaultFixture)

    await expect(
      rentalityCarToken.connect(host).addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityGateway.connect(guest).searchAvailableCars(0, new Date().getSeconds() + 86400, getEmptySearchCarParams(1))
    expect(availableCars.length).to.equal(1)
  })
})
