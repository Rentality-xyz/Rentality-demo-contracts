const { expect } = require('chai')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')

const {
  getMockCarRequest,
  getMockCarRequestWithAddress,
  locationInfo,
  signTCMessage,
  zeroHash,
  emptyLocationInfo,
} = require('../utils')
const { deployFixtureWith1Car } = require('./deployments')

describe('RentalityCarToken: search functions', function () {
  it('Search with empty should return car', async function () {
    const { rentalityCarToken, rentalityTripService, guest, rentalityGateway } =
      await loadFixture(deployFixtureWith1Car)

    const searchCarParams = {
      country: '',
      state: '',
      city: '',
      brand: '',
      model: '',
      yearOfProductionFrom: 0,
      yearOfProductionTo: 0,
      pricePerDayInUsdCentsFrom: 0,
      pricePerDayInUsdCentsTo: 0,
      userLocation: locationInfo,
    }

    const availableCars = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsWithDelivery(0, 0, searchCarParams, emptyLocationInfo, emptyLocationInfo)

    expect(availableCars.length).to.equal(1)
  })

  it('Search with brand should work', async function () {
    const { rentalityCarToken, rentalityTripService, guest, rentalityGateway, rentalityLocationVerifier, admin } =
      await loadFixture(deployFixtureWith1Car)

    const request = getMockCarRequest(0, rentalityLocationVerifier, admin)
    const searchCarParams1 = {
      country: '',
      state: '',
      city: '',
      brand: request.brand,
      model: '',
      yearOfProductionFrom: 0,
      yearOfProductionTo: 0,
      pricePerDayInUsdCentsFrom: 0,
      pricePerDayInUsdCentsTo: 0,
      userLocation: locationInfo,
    }
    const searchCarParams2 = {
      country: '',
      state: '',
      city: '',
      brand: request.brand + 'other',
      model: '',
      yearOfProductionFrom: 0,
      yearOfProductionTo: 0,
      pricePerDayInUsdCentsFrom: 0,
      pricePerDayInUsdCentsTo: 0,
      userLocation: locationInfo,
    }

    const availableCars1 = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsWithDelivery(0, 0, searchCarParams1, emptyLocationInfo, emptyLocationInfo)

    expect(availableCars1.length).to.equal(1)

    const availableCars2 = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsWithDelivery(0, 0, searchCarParams2, emptyLocationInfo, emptyLocationInfo)

    expect(availableCars2.length).to.equal(0)
  })

  it('Search with model should work', async function () {
    const { rentalityCarToken, rentalityTripService, guest, rentalityGateway, rentalityLocationVerifier, admin } =
      await loadFixture(deployFixtureWith1Car)

    const request = getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin)
    const searchCarParams1 = {
      country: '',
      state: '',
      city: '',
      brand: '',
      model: request.model,
      yearOfProductionFrom: 0,
      yearOfProductionTo: 0,
      pricePerDayInUsdCentsFrom: 0,
      pricePerDayInUsdCentsTo: 0,
      userLocation: locationInfo,
    }
    const searchCarParams2 = {
      country: '',
      state: '',
      city: '',
      brand: '',
      model: request.model + 'other',
      yearOfProductionFrom: 0,
      yearOfProductionTo: 0,
      pricePerDayInUsdCentsFrom: 0,
      pricePerDayInUsdCentsTo: 0,
      userLocation: locationInfo,
    }

    const availableCars1 = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsWithDelivery(0, 0, searchCarParams1, emptyLocationInfo, emptyLocationInfo)

    expect(availableCars1.length).to.equal(1)

    const availableCars2 = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsWithDelivery(0, 0, searchCarParams2, emptyLocationInfo, emptyLocationInfo)

    expect(availableCars2.length).to.equal(0)
  })

  it('Search with yearOfProduction should work', async function () {
    const { rentalityCarToken, rentalityTripService, guest, rentalityGateway, rentalityLocationVerifier, admin } =
      await loadFixture(deployFixtureWith1Car)

    const request = getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin)
    const searchCarParams1 = {
      country: '',
      state: '',
      city: '',
      brand: '',
      model: '',
      yearOfProductionFrom: request.yearOfProduction,
      yearOfProductionTo: 0,
      pricePerDayInUsdCentsFrom: 0,
      pricePerDayInUsdCentsTo: 0,
      userLocation: locationInfo,
    }
    const searchCarParams2 = {
      country: '',
      state: '',
      city: '',
      brand: '',
      model: '',
      yearOfProductionFrom: request.yearOfProduction + 1,
      yearOfProductionTo: 0,
      pricePerDayInUsdCentsFrom: 0,
      pricePerDayInUsdCentsTo: 0,
      userLocation: locationInfo,
    }

    const availableCars1 = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsWithDelivery(0, 0, searchCarParams1, emptyLocationInfo, emptyLocationInfo)

    expect(availableCars1.length).to.equal(1)

    const availableCars2 = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsWithDelivery(0, 0, searchCarParams2, emptyLocationInfo, emptyLocationInfo)

    expect(availableCars2.length).to.equal(0)
  })

  it('Search with country should work', async function () {
    const { rentalityCarToken, rentalityTripService, guest, rentalityGateway, host, rentalityLocationVerifier, admin } =
      await loadFixture(deployFixtureWith1Car)

    let location = {
      userAddress: 'Miami Riverwalk, Miami, Florida, USA',
      country: 'USA',
      state: 'Florida',
      city: 'Miami',
      latitude: '45.509248',
      longitude: '-122.682653',
      timeZoneId: 'id',
    }
    location.country = 'Country'
    let carRequest = getMockCarRequest(2, await rentalityLocationVerifier.getAddress(), admin, location)

    await rentalityGateway.addCar(carRequest, zeroHash)

    const searchCarParams1 = {
      country: 'Country',
      state: '',
      city: '',
      brand: '',
      model: '',
      yearOfProductionFrom: 0,
      yearOfProductionTo: 0,
      pricePerDayInUsdCentsFrom: 0,
      pricePerDayInUsdCentsTo: 0,
      userLocation: locationInfo,
    }
    const searchCarParams2 = {
      country: '!',
      state: '',
      city: '',
      brand: '',
      model: '',
      yearOfProductionFrom: 0,
      yearOfProductionTo: 0,
      pricePerDayInUsdCentsFrom: 0,
      pricePerDayInUsdCentsTo: 0,
      userLocation: locationInfo,
    }

    const availableCars1 = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsWithDelivery(0, 0, searchCarParams1, emptyLocationInfo, emptyLocationInfo)

    expect(availableCars1.length).to.equal(1)

    const availableCars2 = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsWithDelivery(0, 0, searchCarParams2, emptyLocationInfo, emptyLocationInfo)

    expect(availableCars2.length).to.equal(0)
  })

  it('Search with state should work', async function () {
    const {
      rentalityCarToken,
      rentalityTripService,
      guest,
      geoParserMock,
      rentalityGateway,
      rentalityLocationVerifier,
      admin,
    } = await loadFixture(deployFixtureWith1Car)

    let location = {
      userAddress: 'Miami Riverwalk, Miami, Florida, USA',
      country: 'USA',
      state: 'Florida',
      city: 'Miami',
      latitude: '45.509248',
      longitude: '-122.682653',
      timeZoneId: 'id',
    }
    location.state = 'Florida'
    let carRequest = getMockCarRequest(2, await rentalityLocationVerifier.getAddress(), admin, location)
    await rentalityGateway.addCar(carRequest, zeroHash)

    const searchCarParams1 = {
      country: '',
      state: 'Florida',
      city: '',
      brand: '',
      model: '',
      yearOfProductionFrom: 0,
      yearOfProductionTo: 0,
      pricePerDayInUsdCentsFrom: 0,
      pricePerDayInUsdCentsTo: 0,
      userLocation: locationInfo,
    }
    const searchCarParams2 = {
      country: '',
      state: '!',
      city: '',
      brand: '',
      model: '',
      yearOfProductionFrom: 0,
      yearOfProductionTo: 0,
      pricePerDayInUsdCentsFrom: 0,
      pricePerDayInUsdCentsTo: 0,
      userLocation: locationInfo,
    }

    const availableCars1 = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsWithDelivery(0, 0, searchCarParams1, emptyLocationInfo, emptyLocationInfo)

    expect(availableCars1.length).to.equal(2)

    const availableCars2 = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsWithDelivery(0, 0, searchCarParams2, emptyLocationInfo, emptyLocationInfo)

    expect(availableCars2.length).to.equal(0)
  })

  it('Search with city should work', async function () {
    const {
      rentalityCarToken,
      rentalityTripService,
      guest,
      geoParserMock,
      rentalityGateway,
      rentalityLocationVerifier,
      admin,
    } = await loadFixture(deployFixtureWith1Car)

    let location = {
      userAddress: 'Miami Riverwalk, Miami, Florida, USA',
      country: 'USA',
      state: 'Florida',
      city: 'Miami',
      latitude: '45.509248',
      longitude: '-122.682653',
      timeZoneId: 'id',
    }
    location.city = 'City'
    let carRequest = getMockCarRequest(2, await rentalityLocationVerifier.getAddress(), admin, location)
    await rentalityGateway.addCar(carRequest, zeroHash)

    const searchCarParams1 = {
      country: '',
      state: '',
      city: 'City',
      brand: '',
      model: '',
      yearOfProductionFrom: 0,
      yearOfProductionTo: 0,
      pricePerDayInUsdCentsFrom: 0,
      pricePerDayInUsdCentsTo: 0,
      userLocation: locationInfo,
    }
    const searchCarParams2 = {
      country: '',
      state: '',
      city: '!',
      brand: '',
      model: '',
      yearOfProductionFrom: 0,
      yearOfProductionTo: 0,
      pricePerDayInUsdCentsFrom: 0,
      pricePerDayInUsdCentsTo: 0,
      userLocation: locationInfo,
    }

    const availableCars1 = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsWithDelivery(0, 0, searchCarParams1, emptyLocationInfo, emptyLocationInfo)

    expect(availableCars1.length).to.equal(1)

    const availableCars2 = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsWithDelivery(0, 0, searchCarParams2, emptyLocationInfo, emptyLocationInfo)

    expect(availableCars2.length).to.equal(0)
  })

  it('Search with pricePerDayInUsdCentsFrom should work', async function () {
    const { rentalityCarToken, rentalityTripService, guest, rentalityGateway, rentalityLocationVerifier, admin } =
      await loadFixture(deployFixtureWith1Car)

    const request = getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin)
    const searchCarParams1 = {
      country: '',
      state: '',
      city: '',
      brand: '',
      model: '',
      yearOfProductionFrom: 0,
      yearOfProductionTo: 0,
      pricePerDayInUsdCentsFrom: request.pricePerDayInUsdCents,
      pricePerDayInUsdCentsTo: 0,
      userLocation: locationInfo,
    }
    const searchCarParams2 = {
      country: '',
      state: '',
      city: '',
      brand: '',
      model: '',
      yearOfProductionFrom: 0,
      yearOfProductionTo: 0,
      pricePerDayInUsdCentsFrom: request.pricePerDayInUsdCents + 1,
      pricePerDayInUsdCentsTo: 0,
      userLocation: locationInfo,
    }
    const searchCarParams3 = {
      country: '',
      state: '',
      city: '',
      brand: '',
      model: '',
      yearOfProductionFrom: 0,
      yearOfProductionTo: 0,
      pricePerDayInUsdCentsFrom: request.pricePerDayInUsdCents - 1,
      pricePerDayInUsdCentsTo: 0,
      userLocation: locationInfo,
    }

    const availableCars1 = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsWithDelivery(0, 0, searchCarParams1, emptyLocationInfo, emptyLocationInfo)

    expect(availableCars1.length).to.equal(1)

    const availableCars2 = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsWithDelivery(0, 0, searchCarParams2, emptyLocationInfo, emptyLocationInfo)

    expect(availableCars2.length).to.equal(0)

    const availableCars3 = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsWithDelivery(0, 0, searchCarParams3, emptyLocationInfo, emptyLocationInfo)

    expect(availableCars3.length).to.equal(1)
  })

  it('Search with pricePerDayInUsdCentsTo should work', async function () {
    const { rentalityCarToken, rentalityTripService, guest, rentalityGateway, rentalityLocationVerifier, admin } =
      await loadFixture(deployFixtureWith1Car)

    const request = getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin)
    const searchCarParams1 = {
      country: '',
      state: '',
      city: '',
      brand: '',
      model: '',
      yearOfProductionFrom: 0,
      yearOfProductionTo: 0,
      pricePerDayInUsdCentsFrom: 0,
      pricePerDayInUsdCentsTo: request.pricePerDayInUsdCents,
      userLocation: locationInfo,
    }
    const searchCarParams2 = {
      country: '',
      state: '',
      city: '',
      brand: '',
      model: '',
      yearOfProductionFrom: 0,
      yearOfProductionTo: 0,
      pricePerDayInUsdCentsFrom: 0,
      pricePerDayInUsdCentsTo: request.pricePerDayInUsdCents + 1,
      userLocation: locationInfo,
    }
    const searchCarParams3 = {
      country: '',
      state: '',
      city: '',
      brand: '',
      model: '',
      yearOfProductionFrom: 0,
      yearOfProductionTo: 0,
      pricePerDayInUsdCentsFrom: 0,
      pricePerDayInUsdCentsTo: request.pricePerDayInUsdCents - 1,
      userLocation: locationInfo,
    }

    const availableCars1 = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsWithDelivery(0, 0, searchCarParams1, emptyLocationInfo, emptyLocationInfo)

    expect(availableCars1.length).to.equal(1)

    const availableCars2 = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsWithDelivery(0, 0, searchCarParams2, emptyLocationInfo, emptyLocationInfo)

    expect(availableCars2.length).to.equal(1)

    const availableCars3 = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsWithDelivery(0, 0, searchCarParams3, emptyLocationInfo, emptyLocationInfo)

    expect(availableCars3.length).to.equal(0)
  })
})
