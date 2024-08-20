const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { expect } = require('chai')
const { getMockCarRequest, zeroHash} = require('../utils')
const { deployDefaultFixture } = require('./deployments')
describe('Rentality: cars', function () {
  it('Host can add car to rentality', async function () {
    const { rentalityCarToken, host } = await loadFixture(deployDefaultFixture)

    await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0),zeroHash)).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)
  })
  it('Host dont see own cars as available', async function () {
    const { rentalityCarToken, host } = await loadFixture(deployDefaultFixture)

    await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0),zeroHash)).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityCarToken.connect(host).getAvailableCarsForUser(host.address)
    expect(availableCars.length).to.equal(0)
  })
  it('Guest see cars as available', async function () {
    const { rentalityCarToken, host, guest } = await loadFixture(deployDefaultFixture)

    await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0),zeroHash)).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)
  })
})
