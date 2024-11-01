const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { expect } = require('chai')
const { getMockCarRequest } = require('../utils')
const { deployDefaultFixture } = require('./deployments')
describe('Rentality: cars', function () {
  it('Host can add car to rentality', async function () {
    const { rentalityCarToken, host, admin, rentalityLocationVerifier, rentalityPlatform } =
      await loadFixture(deployDefaultFixture)

    await expect(
      rentalityPlatform.connect(host).addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)
  })
  it('Host dont see own cars as available', async function () {
    const { rentalityCarToken, host, rentalityLocationVerifier, admin, rentalityPlatform } =
      await loadFixture(deployDefaultFixture)

    await expect(
      rentalityPlatform.connect(host).addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityCarToken.connect(host).getAvailableCarsForUser(host.address)
    expect(availableCars.length).to.equal(0)
  })
  it('Guest see cars as available', async function () {
    const { rentalityCarToken, rentalityPlatform, host, guest, rentalityLocationVerifier, admin } =
      await loadFixture(deployDefaultFixture)

    await expect(
      rentalityPlatform.connect(host).addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)
  })
})
