const { expect } = require('chai')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')

const { getMockCarRequest, deployDefaultFixture } = require('../utils')

describe('RentalityGateway: car', function () {
  let rentalityGateway,
    rentalityMockPriceFeed,
    rentalityUserService,
    rentalityTripService,
    rentalityCurrencyConverter,
    rentalityCarToken,
    rentalityPaymentService,
    rentalityPlatform,
    rentalityGeoService,
    rentalityAdminGateway,
    utils,
    claimService,
    owner,
    admin,
    manager,
    host,
    guest,
    anonymous

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
      rentalityGeoService,
      rentalityAdminGateway,
      utils,
      claimService,
      owner,
      admin,
      manager,
      host,
      guest,
      anonymous,
    } = await loadFixture(deployDefaultFixture))
  })

  it('Host can add car to gateway', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)
  })
  it('Host dont see own cars as available', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityGateway.connect(host).getAvailableCarsForUser(host.address)
    expect(availableCars.length).to.equal(0)
  })
  it('Guest see cars as available', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)
  })
  it('should allow only host to update car info', async function () {
    let addCarRequest = getMockCarRequest(0)
    await expect(rentalityGateway.connect(host).addCar(addCarRequest)).not.be.reverted

    let update_params = {
      carId: 1,
      pricePerDayInUsdCents: 2,
      securityDepositPerTripInUsdCents: 2,
      engineParams: [2],
      milesIncludedPerDay: 2,
      timeBufferBetweenTripsInSec: 2,
      currentlyListed: false,
    }

    await expect(rentalityGateway.connect(host).updateCarInfo(update_params)).not.to.be.reverted

    await expect(rentalityGateway.connect(guest).updateCarInfo(update_params)).to.be.revertedWith('User is not a host')

    await expect(rentalityGateway.connect(anonymous).updateCarInfo(update_params)).to.be.revertedWith(
      'User is not a host'
    )

    let carInfo = await rentalityGateway.getCarInfoById(update_params.carId)

    expect(carInfo.currentlyListed).to.be.equal(false)
    expect(carInfo.pricePerDayInUsdCents).to.be.equal(update_params.pricePerDayInUsdCents)
    expect(carInfo.milesIncludedPerDay).to.be.equal(update_params.milesIncludedPerDay)
    expect(carInfo.engineParams[1]).to.be.equal(update_params.engineParams[0])
    expect(carInfo.securityDepositPerTripInUsdCents).to.be.equal(update_params.securityDepositPerTripInUsdCents)
  })

  it('should allow only host to update car token URI', async function () {
    let addCarRequest = getMockCarRequest(0)
    await expect(rentalityGateway.connect(host).addCar(addCarRequest)).not.be.reverted

    await expect(rentalityGateway.connect(host).updateCarTokenUri(1, ' ')).not.to.be.reverted

    await expect(rentalityGateway.connect(guest).updateCarTokenUri(1, ' ')).to.be.revertedWith('User is not a host')

    await expect(rentalityGateway.connect(anonymous).updateCarTokenUri(1, ' ')).to.be.revertedWith('User is not a host')
  })

  it('should allow only host to burn car', async function () {
    let addCarRequest = getMockCarRequest(0)
    await expect(rentalityGateway.connect(host).addCar(addCarRequest)).not.be.reverted

    await expect(rentalityGateway.connect(host).burnCar(1)).not.to.be.reverted

    await expect(rentalityGateway.connect(guest).burnCar(1)).to.be.revertedWith('User is not a host')

    await expect(rentalityGateway.connect(anonymous).burnCar(1)).to.be.revertedWith('User is not a host')
  })

  it('should have available cars', async function () {
    let addCarRequest = getMockCarRequest(0)
    await expect(rentalityGateway.connect(host).addCar(addCarRequest)).not.be.reverted

    let available_cars = await rentalityGateway.connect(guest).getAvailableCars()

    expect(available_cars.length).to.be.equal(1)
  })

  it('should have cars owned by user', async function () {
    let addCarRequest = getMockCarRequest(0)
    await expect(rentalityCarToken.connect(host).addCar(addCarRequest)).not.be.reverted

    let available_cars = await rentalityGateway.connect(host).getMyCars()

    expect(available_cars.length).to.be.equal(1)

    let cars_not_created = await rentalityGateway.connect(guest).getMyCars()

    expect(cars_not_created.length).to.be.equal(0)
  })
})
