const { expect } = require('chai')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')

const {
  getMockCarRequest,
  deployDefaultFixture,
  getEmptySearchCarParams,
  signTCMessage,
  locationInfo,
  signLocationInfo,
  zeroHash,
  emptyKyc,
  emptyLocationInfo,
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
    rentalityLocationVerifier

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
    } = await loadFixture(deployDefaultFixture))
  })

  it('Host can add car to gateway', async function () {
    await expect(
      rentalityGateway
        .connect(host)
        .addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)
  })
  it('Host dont see own cars as available', async function () {
    await expect(
      rentalityGateway
        .connect(host)
        .addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityGateway
      .connect(host)
      .searchAvailableCarsWithDelivery(
        0,
        new Date().getSeconds() + 86400,
        getEmptySearchCarParams(1),
        emptyLocationInfo,
        emptyLocationInfo
      )
    expect(availableCars.length).to.equal(0)
  })
  it('Guest see cars as available', async function () {
    await expect(
      rentalityGateway
        .connect(host)
        .addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsWithDelivery(
        0,
        new Date().getSeconds() + 86400,
        getEmptySearchCarParams(1),
        emptyLocationInfo,
        emptyLocationInfo
      )
    expect(availableCars.length).to.equal(1)
  })
  it('should allow only host to update car info', async function () {
    let addCarRequest = getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(addCarRequest)).not.be.reverted

    let update_params = {
      carId: 1,
      pricePerDayInUsdCents: 2,
      securityDepositPerTripInUsdCents: 2,
      engineParams: [2, 2],
      milesIncludedPerDay: 2,
      timeBufferBetweenTripsInSec: 2,
      currentlyListed: false,
      insuranceIncluded: true,
      engineType: 1,
      tokenUri: 'uri',
      insuranceRequired: false,
      insurancePriceInUsdCents: 0,
dimoTokenId: 0
    }
    let locationInfo = {
      locationInfo: emptyLocationInfo,
      signature: signLocationInfo(await rentalityLocationVerifier.getAddress(), admin, emptyLocationInfo),
    }
    await expect(rentalityGateway.connect(host).updateCarInfoWithLocation(update_params, locationInfo)).not.to.be
      .reverted

    await expect(
      rentalityGateway.connect(anonymous).updateCarInfoWithLocation(update_params, locationInfo)
    ).to.be.revertedWith('For car owner')

    let carInfo = await rentalityGateway.getCarInfoById(update_params.carId)

    expect(carInfo.carInfo.currentlyListed).to.be.equal(false)
    expect(carInfo.carInfo.pricePerDayInUsdCents).to.be.equal(update_params.pricePerDayInUsdCents)
    expect(carInfo.carInfo.milesIncludedPerDay).to.be.equal(update_params.milesIncludedPerDay)
    expect(carInfo.carInfo.engineParams[1]).to.be.equal(update_params.engineParams[0])
    expect(carInfo.carInfo.securityDepositPerTripInUsdCents).to.be.equal(update_params.securityDepositPerTripInUsdCents)
  })

  it('should have cars owned by user', async function () {
    let addCarRequest = getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(addCarRequest)).not.be.reverted

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

    const hostSignature = await signTCMessage(host)

    let locationInfo1 = {
      locationInfo,
      signature: signLocationInfo(await rentalityLocationVerifier.getAddress(), admin),
    }
    await expect(rentalityGateway.connect(host).setKYCInfo(name, number, photo,"", hostSignature, zeroHash)).to.not
      .reverted

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
      insuranceRequired: false,
      insurancePriceInUsdCents: 0,
dimoTokenId: 0
    }
    const oneDayInSec = 86400
    const totalTripDays = 7
    const searchParams = getEmptySearchCarParams()
    await expect(rentalityGateway.connect(host).addCar(addCarRequest)).not.be.reverted
    const resultAr = await rentalityGateway.searchAvailableCarsWithDelivery(
      new Date().getDate(),
      new Date().getDate() + oneDayInSec * totalTripDays,
      searchParams,
      emptyLocationInfo,
      emptyLocationInfo
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
    await expect(await rentalityGateway.connect(host).setKYCInfo(name, '', photo,"", hostSignature, zeroHash)).to.not
      .reverted

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
      insuranceRequired: false,
      insurancePriceInUsdCents: 0,
dimoTokenId: 0
    }
    await expect(await rentalityGateway.connect(host).addCar(addCarRequest)).not.be.reverted
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
    await expect(await rentalityGateway.connect(host).setKYCInfo(name, '', photo,"", hostSignature, zeroHash)).to.not
      .reverted
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
        insuranceRequired: false,
        insurancePriceInUsdCents: 0,
      }
    }
    await expect(
      await rentalityGateway
        .connect(host)
        .addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    )
    await expect(
      await rentalityGateway
        .connect(host)
        .addCar(getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin))
    )
    await expect(
      await rentalityGateway
        .connect(host)
        .addCar(getMockCarRequest(2, await rentalityLocationVerifier.getAddress(), admin))
    )
    await expect(
      await rentalityGateway
        .connect(host)
        .addCar(getMockCarRequest(3, await rentalityLocationVerifier.getAddress(), admin))
    )
    await expect(
      await rentalityGateway
        .connect(host)
        .addCar(getMockCarRequest(4, await rentalityLocationVerifier.getAddress(), admin))
    )

    await rentalityCarToken.connect(host).burnCar(3)
    const hostCars = await rentalityCarToken.getCarsOfHost(host.address)
    expect(hostCars.length).to.be.eq(4)

    await expect(
      await rentalityGateway
        .connect(guest)
        .addCar(getMockCarRequest(5, await rentalityLocationVerifier.getAddress(), admin))
    )
    await expect(
      await rentalityGateway
        .connect(guest)
        .addCar(getMockCarRequest(6, await rentalityLocationVerifier.getAddress(), admin))
    )
    await rentalityCarToken.connect(guest).burnCar(6)
    await expect(
      await rentalityGateway
        .connect(guest)
        .addCar(getMockCarRequest(7, await rentalityLocationVerifier.getAddress(), admin))
    )

    const guestCars = await rentalityCarToken.getCarsOfHost(guest.address)
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
    await expect(await rentalityGateway.connect(host).setKYCInfo(name, '', photo,"", hostSignature, zeroHash)).to.not
      .reverted

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
        insuranceRequired: false,
        insurancePriceInUsdCents: 0,
      }
    }
    await expect(
      await rentalityGateway
        .connect(host)
        .addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    )

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
