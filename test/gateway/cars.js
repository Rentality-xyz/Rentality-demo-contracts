const { expect } = require('chai')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')

const { getMockCarRequest, deployDefaultFixture, getEmptySearchCarParams } = require('../utils')

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
  it('should have all variables after search', async function () {
    let name = 'name'
    let surname = 'surname'
    let number = '+380'
    let photo = 'photo'
    let licenseNumber = 'licenseNumber'
    let expirationDate = 10

    await expect(
      rentalityGateway.connect(host).setKYCInfo(name, surname, number, photo, licenseNumber, expirationDate, true)
    ).to.not.reverted

    let addCarRequest = {
      tokenUri: 'uri',
      carVinNumber: 'VIN_NUMBER',
      brand: 'BRAND',
      model: 'MODEL',
      yearOfProduction: 2020,
      pricePerDayInUsdCents: 1,
      securityDepositPerTripInUsdCents: 1,
      engineParams: [1, 2],
      engineType: 1,
      milesIncludedPerDay: 10,
      timeBufferBetweenTripsInSec: 0,
      locationAddress: 'Michigan Ave, Chicago, IL, USA',
      locationLatitude: '123421',
      locationLongitude: '123421',
      geoApiKey: 'key',
    }
    const searchParams = getEmptySearchCarParams()
    await expect(rentalityCarToken.connect(host).addCar(addCarRequest)).not.be.reverted
    const resultAr = await rentalityGateway.searchAvailableCars(
      new Date().getDate(),
      new Date().getDate() + 100,
      searchParams
    )
    const result = resultAr[0]

    expect(result.carId).to.be.equal(1)
    expect(result.brand).to.be.eq(addCarRequest.brand)
    expect(result.model).to.be.eq(addCarRequest.model)
    expect(result.yearOfProduction).to.be.eq(addCarRequest.yearOfProduction)
    expect(result.pricePerDayInUsdCents).to.be.eq(addCarRequest.pricePerDayInUsdCents)
    expect(result.securityDepositPerTripInUsdCents).to.be.eq(addCarRequest.securityDepositPerTripInUsdCents)
    expect(result.host).be.be.eq(host.address)
    expect(result.hostName).to.be.eq(name)
    expect(result.hostPhotoUrl).to.be.eq(photo)
    expect(result.city).to.be.eq('Chicago')
    expect(result.country).to.be.eq('USA')
    expect(result.state).to.be.eq('IL')
    expect(result.locationLatitude).to.be.eq('123421')
    expect(result.locationLongitude).to.be.eq('123421')
    expect(result.timeZoneId).to.be.eq('America/Chicago')
  })
  it('should return complete details', async function () {
    let name = 'name'
    let surname = 'surname'
    let number = '+380'
    let photo = 'photo'
    let licenseNumber = 'licenseNumber'
    let expirationDate = 10

    await expect(
      await rentalityGateway.connect(host).setKYCInfo(name, surname, number, photo, licenseNumber, expirationDate, true)
    ).to.not.reverted

    let addCarRequest = {
      tokenUri: 'uri',
      carVinNumber: 'VIN_NUMBER',
      brand: 'BRAND',
      model: 'MODEL',
      yearOfProduction: 2020,
      pricePerDayInUsdCents: 1,
      securityDepositPerTripInUsdCents: 1,
      engineParams: [1, 2],
      engineType: 1,
      milesIncludedPerDay: 10,
      timeBufferBetweenTripsInSec: 0,
      locationAddress: 'Michigan Ave, Chicago, IL, USA',
      locationLatitude: '123421',
      locationLongitude: '123421',
      geoApiKey: 'key',
    }
    await expect(await rentalityCarToken.connect(host).addCar(addCarRequest)).not.be.reverted
    const result = await rentalityGateway.connect(guest).getCarDetails(1)

    expect(result.carId).to.be.equal(1)
    expect(result.brand).to.be.eq(addCarRequest.brand)
    expect(result.model).to.be.eq(addCarRequest.model)
    expect(result.yearOfProduction).to.be.eq(addCarRequest.yearOfProduction)
    expect(result.pricePerDayInUsdCents).to.be.eq(addCarRequest.pricePerDayInUsdCents)
    expect(result.securityDepositPerTripInUsdCents).to.be.eq(addCarRequest.securityDepositPerTripInUsdCents)
    expect(result.host).be.be.eq(host.address)
    expect(result.hostName).to.be.eq(name)
    expect(result.hostPhotoUrl).to.be.eq(photo)
    expect(result.city).to.be.eq('Chicago')
    expect(result.country).to.be.eq('USA')
    expect(result.state).to.be.eq('IL')
    expect(result.locationLatitude).to.be.eq('123421')
    expect(result.locationLongitude).to.be.eq('123421')
    expect(result.timeZoneId).to.be.eq('America/Chicago')
    expect(result.milesIncludedPerDay).to.be.equal(addCarRequest.milesIncludedPerDay)
    expect(result.engineType).to.be.equal(addCarRequest.engineType)
    expect(result.engineParams).to.deep.equal(addCarRequest.engineParams)
    expect(result.geoVerified).to.be.true
    expect(result.currentlyListed).to.be.true
  })
  it('Should return public dto', async function () {
    let name = 'name'
    let surname = 'surname'
    let number = '+380'
    let photo = 'photo'
    let licenseNumber = 'licenseNumber'
    let expirationDate = 10

    await expect(
      await rentalityGateway.connect(host).setKYCInfo(name, surname, number, photo, licenseNumber, expirationDate, true)
    ).to.not.reverted

    const addCar = (num) => {
      return {
        tokenUri: 'uri',
        carVinNumber: 'VIN_NUMBER' + num,
        brand: 'BRAND',
        model: 'MODEL',
        yearOfProduction: 2020,
        pricePerDayInUsdCents: 1,
        securityDepositPerTripInUsdCents: 1,
        engineParams: [1, 2],
        engineType: 1,
        milesIncludedPerDay: 10,
        timeBufferBetweenTripsInSec: 0,
        locationAddress: 'Michigan Ave, Chicago, IL, USA',
        locationLatitude: '123421',
        locationLongitude: '123421',
        geoApiKey: 'key',
      }
    }
    await expect(await rentalityCarToken.connect(host).addCar(addCar(0))).not.be.reverted
    await expect(await rentalityCarToken.connect(host).addCar(addCar(1))).not.be.reverted
    await expect(await rentalityCarToken.connect(host).addCar(addCar(2))).not.be.reverted
    await expect(await rentalityCarToken.connect(host).addCar(addCar(3))).not.be.reverted
    await expect(await rentalityCarToken.connect(host).addCar(addCar(4))).not.be.reverted

    await rentalityCarToken.connect(host).burnCar(3)
    const hostCars = await rentalityCarToken.getCarsOfHost(host.address)
    expect(hostCars.length).to.be.eq(4)

    await expect(await rentalityCarToken.connect(guest).addCar(addCar(5))).not.be.reverted
    await expect(await rentalityCarToken.connect(guest).addCar(addCar(6))).not.be.reverted
    await rentalityCarToken.connect(guest).burnCar(6)
    await expect(await rentalityCarToken.connect(guest).addCar(addCar(7))).not.be.reverted

    const guestCars = await rentalityCarToken.getCarsOfHost(guest.address)
    expect(guestCars.length).to.be.eq(2)
  })
})
