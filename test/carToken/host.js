const { expect } = require('chai')
const { loadFixture, time } = require('@nomicfoundation/hardhat-network-helpers')

const { getMockCarRequest,zeroHash } = require('../utils')
const { deployFixtureWith1Car, deployDefaultFixture } = require('./deployments')

describe('RentalityCarToken: host functions', function () {
  it('Adding car should emit CarAddedSuccess event', async function () {
    const { rentalityCarToken, host, rentalityLocationVerifier, admin, rentalityNotificationService } =
      await loadFixture(deployDefaultFixture)

    const request = getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin)

    await expect(rentalityCarToken.connect(host).addCar(request))
      .to.emit(rentalityNotificationService, 'RentalityEvent')
      .withArgs(0, 1, 0, host.address, host.address, (await time.latest()) + 1)
  })

  it('Adding car with the same VIN number should be reverted', async function () {
    const { rentalityCarToken, host, rentalityLocationVerifier, admin, rentalityGateway } =
      await loadFixture(deployDefaultFixture)

    const request1 = getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin)
    const request2 = {
      ...getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin),
      zeroHash,
      carVinNumber: request1.carVinNumber,
    }

    await expect(rentalityGateway.connect(host).addCar(request1, zeroHash)).not.be.reverted
    await expect(rentalityGateway.connect(host).addCar(request2, zeroHash)).to.be.reverted
  })

  it('Adding car with the different VIN number should not be reverted', async function () {
    const { rentalityCarToken, host, rentalityLocationVerifier, admin, rentalityGateway } =
      await loadFixture(deployDefaultFixture)

    const request1 = getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin)
    const request2 = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)

    await expect(rentalityGateway.connect(host).addCar(request1, zeroHash)).not.be.reverted
    await expect(rentalityGateway.connect(host).addCar(request2, zeroHash)).not.be.reverted
  })

  it('Only owner of the car can burn token', async function () {
    const { rentalityCarToken, owner, admin, host, anonymous } = await loadFixture(deployFixtureWith1Car)

    await expect(rentalityCarToken.connect(anonymous).burnCar(1)).to.be.reverted
    await expect(rentalityCarToken.connect(admin).burnCar(1)).to.be.reverted
    await expect(rentalityCarToken.connect(owner).burnCar(1)).to.be.reverted

    expect(await rentalityCarToken.balanceOf(host.address)).to.equal(1)
    await expect(rentalityCarToken.connect(host).burnCar(1)).not.be.reverted
    expect(await rentalityCarToken.balanceOf(host.address)).to.equal(0)
  })

  it('getCarInfoById should return valid info', async function () {
    const { rentalityCarToken, host, rentalityLocationVerifier, admin, rentalityGateway } =
      await loadFixture(deployFixtureWith1Car)

    const TOKEN_ID = 1
    const request = getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin)

    const carInfo = await rentalityCarToken.connect(host).getCarInfoById(TOKEN_ID)

    expect(carInfo.carVinNumber).to.equal(request.carVinNumber)
    expect(carInfo.createdBy).to.equal(host.address)
    expect(carInfo.pricePerDayInUsdCents).to.equal(request.pricePerDayInUsdCents)
    expect(carInfo.securityDepositPerTripInUsdCents).to.equal(request.securityDepositPerTripInUsdCents)
    expect(carInfo.tankVolumeInGal).to.equal(request.tankVolumeInGal)
    expect(carInfo.fuelPricePerGalInUsdCents).to.equal(request.fuelPricePerGalInUsdCents)
    expect(carInfo.milesIncludedPerDay).to.equal(request.milesIncludedPerDay)
    expect(carInfo.country).to.equal(request.country)
    expect(carInfo.state).to.equal(request.state)
    expect(carInfo.city).to.equal(request.city)
    expect(carInfo.locationLatitudeInPPM).to.equal(request.locationLatitudeInPPM)
    expect(carInfo.locationLongitudeInPPM).to.equal(request.locationLongitudeInPPM)
    expect(carInfo.currentlyListed).to.equal(true)
  })

  it('getCarsOwnedByUser without cars should return empty array', async function () {
    const { rentalityCarToken, host } = await loadFixture(deployDefaultFixture)
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)

    expect(myCars.length).to.equal(0)
  })

  it('getCarsOwnedByUser after burn car should return empty array', async function () {
    const { rentalityCarToken, host } = await loadFixture(deployFixtureWith1Car)

    await rentalityCarToken.connect(host).burnCar(1)
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)

    expect(myCars.length).to.equal(0)
  })

  it('getCarsOwnedByUser with 1 car should return valid info', async function () {
    const { rentalityCarToken, host, rentalityLocationVerifier, admin, rentalityGateway } =
      await loadFixture(deployFixtureWith1Car)

    const request = getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin)

    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)

    expect(myCars.length).to.equal(1)

    expect(myCars[0].carVinNumber).to.equal(request.carVinNumber)
    expect(myCars[0].createdBy).to.equal(host.address)
    expect(myCars[0].pricePerDayInUsdCents).to.equal(request.pricePerDayInUsdCents)
    expect(myCars[0].securityDepositPerTripInUsdCents).to.equal(request.securityDepositPerTripInUsdCents)
    expect(myCars[0].tankVolumeInGal).to.equal(request.tankVolumeInGal)
    expect(myCars[0].fuelPricePerGalInUsdCents).to.equal(request.fuelPricePerGalInUsdCents)
    expect(myCars[0].milesIncludedPerDay).to.equal(request.milesIncludedPerDay)
    expect(myCars[0].country).to.equal(request.country)
    expect(myCars[0].state).to.equal(request.state)
    expect(myCars[0].city).to.equal(request.city)
    expect(myCars[0].locationLatitudeInPPM).to.equal(request.locationLatitudeInPPM)
    expect(myCars[0].locationLongitudeInPPM).to.equal(request.locationLongitudeInPPM)
    expect(myCars[0].currentlyListed).to.equal(true)
  })

  it("getAllAvailableCars with 1 car shouldn't return data for car owner", async function () {
    const { rentalityCarToken, host } = await loadFixture(deployFixtureWith1Car)

    const availableCars = await rentalityCarToken.getAvailableCarsForUser(host.address)

    expect(availableCars.length).to.equal(0)
  })

  // function not using
  it.skip('getAllAvailableCars with 1 car should return data for guest', async function () {
    const { rentalityGateway, host, guest, rentalityLocationVerifier, admin } = await loadFixture(deployFixtureWith1Car)

    const request = getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin)

    const availableCars = await rentalityGateway
      .connect(guest)
      .searchAvailableCars(0, new Date().getSeconds() + 86400, getEmptySearchCarParams(1))

    expect(availableCars.length).to.equal(1)
    expect(availableCars[0].carVinNumber).to.equal(request.carVinNumber)
    expect(availableCars[0].createdBy).to.equal(host.address)
    expect(availableCars[0].pricePerDayInUsdCents).to.equal(request.pricePerDayInUsdCents)
    expect(availableCars[0].securityDepositPerTripInUsdCents).to.equal(request.securityDepositPerTripInUsdCents)
    expect(availableCars[0].tankVolumeInGal).to.equal(request.tankVolumeInGal)
    expect(availableCars[0].fuelPricePerGalInUsdCents).to.equal(request.fuelPricePerGalInUsdCents)
    expect(availableCars[0].milesIncludedPerDay).to.equal(request.milesIncludedPerDay)
    expect(availableCars[0].country).to.equal(request.country)
    expect(availableCars[0].state).to.equal(request.state)
    expect(availableCars[0].city).to.equal(request.city)
    expect(availableCars[0].locationLatitudeInPPM).to.equal(request.locationLatitudeInPPM)
    expect(availableCars[0].locationLongitudeInPPM).to.equal(request.locationLongitudeInPPM)
    expect(availableCars[0].currentlyListed).to.equal(true)
  })
})
