const { expect } = require('chai')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')

const {
  getMockCarRequest,
  deployDefaultFixture,
  getEmptySearchCarParams,
  signTCMessage,
  locationInfo,
  signLocationInfo,
  emptyKyc,
} = require('../utils')
const { ethers } = require('hardhat')

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
    anonymous,
    rentalityLocationVerifier,
    rentalityView

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
      rentalityLocationVerifier,
      adminKyc,
      rentalityView,
    } = await loadFixture(deployDefaultFixture))
  })

  it('Host can add car to gateway', async function () {
    await expect(
      rentalityPlatform.connect(host).addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).not.to.be.reverted
    const myCars = await rentalityView.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)
  })
  it('Host dont see own cars as available', async function () {
    await expect(
      rentalityPlatform.connect(host).addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).not.to.be.reverted
    const myCars = await rentalityView.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityView.connect(host).getAvailableCarsForUser(host.address)
    expect(availableCars.length).to.equal(0)
  })
  it('Guest see cars as available', async function () {
    await expect(
      rentalityPlatform.connect(host).addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).not.to.be.reverted
    const myCars = await rentalityView.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityView.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)
  })
  it('should allow only host to update car info', async function () {
    let addCarRequest = getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityPlatform.connect(host).addCar(addCarRequest)).not.be.reverted

    let update_params = {
      carId: 1,
      pricePerDayInUsdCents: 2,
      securityDepositPerTripInUsdCents: 2,
      engineParams: [2],
      milesIncludedPerDay: 2,
      timeBufferBetweenTripsInSec: 2,
      currentlyListed: false,
      insuranceIncluded: true,
    }

    await expect(rentalityPlatform.connect(host).updateCarInfo(update_params)).not.to.be.reverted

    await expect(rentalityPlatform.connect(anonymous).updateCarInfo(update_params)).to.be.revertedWith(
      'Only the owner of the car can update car info'
    )

    let carInfo = await rentalityView.getCarInfoById(update_params.carId)

    expect(carInfo.currentlyListed).to.be.equal(false)
    expect(carInfo.pricePerDayInUsdCents).to.be.equal(update_params.pricePerDayInUsdCents)
    expect(carInfo.milesIncludedPerDay).to.be.equal(update_params.milesIncludedPerDay)
    expect(carInfo.engineParams[1]).to.be.equal(update_params.engineParams[0])
    expect(carInfo.securityDepositPerTripInUsdCents).to.be.equal(update_params.securityDepositPerTripInUsdCents)
  })

  it('should have cars owned by user', async function () {
    let addCarRequest = getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityPlatform.connect(host).addCar(addCarRequest)).not.be.reverted

    let available_cars = await rentalityView.connect(host).getMyCars()

    expect(available_cars.length).to.be.equal(1)

    let cars_not_created = await rentalityView.connect(guest).getMyCars()

    expect(cars_not_created.length).to.be.equal(0)
  })
  it('should have all variables after search', async function () {
    let name = 'name'
    let surname = 'surname'
    let number = '+380'
    let photo = 'photo'
    let licenseNumber = 'licenseNumber'
    let expirationDate = 10

    const hostSignature = await signTCMessage(host)

    let locationInfo1 = {
      locationInfo,
      signature: signLocationInfo(await rentalityLocationVerifier.getAddress(), admin),
    }
    await expect(rentalityPlatform.connect(host).setKYCInfo(name, number, photo, hostSignature)).to.not.reverted

    let addCarRequest = {
      tokenUri: 'uri',
      carVinNumber: 'VIN_NUMBER',
      brand: 'BRAND',
      model: 'MODEL',
      yearOfProduction: 2020,
      pricePerDayInUsdCents: 1000,
      securityDepositPerTripInUsdCents: 1,
      engineParams: [1, 2],
      engineType: 1,
      milesIncludedPerDay: 10,
      timeBufferBetweenTripsInSec: 0,
      geoApiKey: 'key',
      insuranceIncluded: true,
      locationInfo: locationInfo1,
      currentlyListed: true,
    }
    const oneDayInSec = 86400
    const totalTripDays = 7
    const searchParams = getEmptySearchCarParams()
    await expect(rentalityPlatform.connect(host).addCar(addCarRequest)).not.be.reverted
    const resultAr = await rentalityView.searchAvailableCars(
      new Date().getDate(),
      new Date().getDate() + oneDayInSec * totalTripDays,
      searchParams
    )
    const result = resultAr[0].car

    expect(result.carId).to.be.equal(1)
    expect(result.brand).to.be.eq(addCarRequest.brand)
    expect(result.model).to.be.eq(addCarRequest.model)
    expect(result.yearOfProduction).to.be.eq(addCarRequest.yearOfProduction)
    expect(result.pricePerDayInUsdCents).to.be.eq(addCarRequest.pricePerDayInUsdCents)
    expect(result.securityDepositPerTripInUsdCents).to.be.eq(addCarRequest.securityDepositPerTripInUsdCents)
    expect(result.host).be.be.eq(host.address)
    expect(result.hostName).to.be.eq(name)
    expect(result.hostPhotoUrl).to.be.eq(photo)
  })
  it('should return co' + 'locationInfomplete details', async function () {
    let name = 'name'
    let surname = 'surname'
    let number = '+380'
    let photo = 'photo'
    let licenseNumber = 'licenseNumber'
    let expirationDate = 10

    const hostSignature = await signTCMessage(host)
    let locationInfo1 = {
      locationInfo,
      signature: signLocationInfo(await rentalityLocationVerifier.getAddress(), admin),
    }
    await expect(await rentalityPlatform.connect(host).setKYCInfo(name, '', photo, hostSignature)).to.not.reverted

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
      geoApiKey: 'key',
      insuranceIncluded: true,
      locationInfo: locationInfo1,
      currentlyListed: true,
    }
    await expect(await rentalityPlatform.connect(host).addCar(addCarRequest)).not.be.reverted
    const result = await rentalityView.connect(guest).getCarDetails(1)

    expect(result.carId).to.be.equal(1)
    expect(result.brand).to.be.eq(addCarRequest.brand)
    expect(result.model).to.be.eq(addCarRequest.model)
    expect(result.yearOfProduction).to.be.eq(addCarRequest.yearOfProduction)
    expect(result.pricePerDayInUsdCents).to.be.eq(addCarRequest.pricePerDayInUsdCents)
    expect(result.securityDepositPerTripInUsdCents).to.be.eq(addCarRequest.securityDepositPerTripInUsdCents)
    expect(result.host).be.be.eq(host.address)
    expect(result.hostName).to.be.eq(name)
    expect(result.hostPhotoUrl).to.be.eq(photo)
    expect(result.locationInfo.city).to.be.eq('Miami')
    expect(result.locationInfo.country).to.be.eq('USA')
    expect(result.milesIncludedPerDay).to.be.equal(addCarRequest.milesIncludedPerDay)
    expect(result.engineType).to.be.equal(addCarRequest.engineType)
    expect(result.engineParams).to.deep.equal(addCarRequest.engineParams)
    expect(result.currentlyListed).to.be.true
  })
  it('Should return public dto', async function () {
    let name = 'name'
    let surname = 'surname'
    let number = '+380'
    let photo = 'photo'
    let licenseNumber = 'licenseNumber'
    let expirationDate = 10

    const hostSignature = await signTCMessage(host)
    await expect(await rentalityPlatform.connect(host).setKYCInfo(name, '', photo, hostSignature)).to.not.reverted
    let locationInfo1 = {
      locationInfo,
      signature: signLocationInfo(await rentalityLocationVerifier.getAddress(), admin),
    }
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
        geoApiKey: 'key',
        insuranceIncluded: true,
        locationInfo: locationInfo1,
        currentlyListed: true,
      }
    }
    await expect(await rentalityPlatform.connect(host).addCar(addCar(0))).not.be.reverted
    await expect(await rentalityPlatform.connect(host).addCar(addCar(1))).not.be.reverted
    await expect(await rentalityPlatform.connect(host).addCar(addCar(2))).not.be.reverted
    await expect(await rentalityPlatform.connect(host).addCar(addCar(3))).not.be.reverted
    await expect(await rentalityPlatform.connect(host).addCar(addCar(4))).not.be.reverted

    await rentalityCarToken.connect(host).burnCar(3)
    const hostCars = await rentalityCarToken.getCarsOfHost(host.address)
    expect(hostCars.length).to.be.eq(4)

    await expect(await rentalityPlatform.connect(guest).addCar(addCar(5))).not.be.reverted
    await expect(await rentalityPlatform.connect(guest).addCar(addCar(6))).not.be.reverted
    await rentalityCarToken.connect(guest).burnCar(6)
    await expect(await rentalityPlatform.connect(guest).addCar(addCar(7))).not.be.reverted

    const guestCars = await rentalityView.getCarsOfHost(guest.address)
    expect(guestCars.length).to.be.eq(2)
  })
  it('Impossible to transfer nft', async function () {
    let name = 'name'
    let surname = 'surname'
    let number = '+380'
    let photo = 'photo'
    let licenseNumber = 'licenseNumber'
    let expirationDate = 10

    const hostSignature = await signTCMessage(host)
    await expect(await rentalityPlatform.connect(host).setKYCInfo(name, '', photo, hostSignature)).to.not.reverted

    let locationInfo1 = {
      locationInfo,
      signature: signLocationInfo(await rentalityLocationVerifier.getAddress(), admin),
    }
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
        geoApiKey: 'key',
        insuranceIncluded: true,
        locationInfo: locationInfo1,
        currentlyListed: true,
      }
    }
    await expect(await rentalityPlatform.connect(host).addCar(addCar(0))).not.be.reverted

    const tokenContract = await ethers.getContractAt(
      'ERC721URIStorageUpgradeable',
      await rentalityCarToken.getAddress()
    )
    await expect(tokenContract.connect(host).transferFrom(host.address, guest.address, 1)).to.be.revertedWith(
      'Not implemented.'
    )
    await expect(tokenContract.connect(host).safeTransferFrom(host.address, guest.address, 1)).to.be.revertedWith(
      'Not implemented.'
    )
  })
})
