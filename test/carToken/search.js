const { expect } = require('chai')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')

const { getMockCarRequest, getMockCarRequestWithAddress } = require('../utils')
const { deployFixtureWith1Car } = require('./deployments')

describe('RentalityCarToken: search functions', function () {
  it('Search with empty should return car', async function () {
    const { rentalityCarToken, rentalityTripService, guest } = await loadFixture(deployFixtureWith1Car)

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
    }

    const availableCars = await rentalityTripService.searchAvailableCarsForUser(guest.address, 0, 0, searchCarParams)

    expect(availableCars.length).to.equal(1)
  })

  it('Search with brand should work', async function () {
    const { rentalityCarToken, rentalityTripService, guest } = await loadFixture(deployFixtureWith1Car)

    const request = getMockCarRequest(0)
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
    }

    const availableCars1 = await rentalityTripService.searchAvailableCarsForUser(guest.address, 0, 0, searchCarParams1)

    expect(availableCars1.length).to.equal(1)

    const availableCars2 = await rentalityTripService.searchAvailableCarsForUser(guest.address, 0, 0, searchCarParams2)

    expect(availableCars2.length).to.equal(0)
  })

  it('Search with model should work', async function () {
    const { rentalityCarToken, rentalityTripService, guest } = await loadFixture(deployFixtureWith1Car)

    const request = getMockCarRequest(0)
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
    }

    const availableCars1 = await rentalityTripService.searchAvailableCarsForUser(guest.address, 0, 0, searchCarParams1)

    expect(availableCars1.length).to.equal(1)

    const availableCars2 = await rentalityTripService.searchAvailableCarsForUser(guest.address, 0, 0, searchCarParams2)

    expect(availableCars2.length).to.equal(0)
  })

  it('Search with yearOfProduction should work', async function () {
    const { rentalityCarToken, rentalityTripService, guest } = await loadFixture(deployFixtureWith1Car)

    const request = getMockCarRequest(0)
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
    }

    const availableCars1 = await rentalityTripService.searchAvailableCarsForUser(guest.address, 0, 0, searchCarParams1)

    expect(availableCars1.length).to.equal(1)

    const availableCars2 = await rentalityTripService.searchAvailableCarsForUser(guest.address, 0, 0, searchCarParams2)

    expect(availableCars2.length).to.equal(0)
  })

  it('Search with country should work', async function () {
    const { rentalityCarToken, rentalityTripService, guest } = await loadFixture(deployFixtureWith1Car)

    const carRequest = getMockCarRequestWithAddress(2, 'Michigan Ave, Chicago, Florida, USA')
    await rentalityCarToken.addCar(carRequest)

    const searchCarParams1 = {
      country: 'usa',
      state: '',
      city: '',
      brand: '',
      model: '',
      yearOfProductionFrom: 0,
      yearOfProductionTo: 0,
      pricePerDayInUsdCentsFrom: 0,
      pricePerDayInUsdCentsTo: 0,
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
    }

    const availableCars1 = await rentalityTripService.searchAvailableCarsForUser(guest.address, 0, 0, searchCarParams1)

    expect(availableCars1.length).to.equal(2) // It has one car with 'usa' in country params, adds during deployment

    const availableCars2 = await rentalityTripService.searchAvailableCarsForUser(guest.address, 0, 0, searchCarParams2)

    expect(availableCars2.length).to.equal(0)
  })

  it('Search with state should work', async function () {
    const { rentalityCarToken, rentalityTripService, guest, geoParserMock } = await loadFixture(deployFixtureWith1Car)

    const carRequest = getMockCarRequestWithAddress(2, 'Michigan Ave, Chicago, Florida, USA')
    await rentalityCarToken.addCar(carRequest)

    const searchCarParams1 = {
      country: '',
      state: '',
      city: 'chicago',
      brand: '',
      model: '',
      yearOfProductionFrom: 0,
      yearOfProductionTo: 0,
      pricePerDayInUsdCentsFrom: 0,
      pricePerDayInUsdCentsTo: 0,
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
    }

    const availableCars1 = await rentalityTripService.searchAvailableCarsForUser(guest.address, 0, 0, searchCarParams1)

    expect(availableCars1.length).to.equal(1)

    const availableCars2 = await rentalityTripService.searchAvailableCarsForUser(guest.address, 0, 0, searchCarParams2)

    expect(availableCars2.length).to.equal(0)
  })

  it('Search with city should work', async function () {
    const { rentalityCarToken, rentalityTripService, guest, geoParserMock } = await loadFixture(deployFixtureWith1Car)

    const carRequest = getMockCarRequestWithAddress(2, 'Michigan Ave, Chicago, Florida, USA')
    await rentalityCarToken.addCar(carRequest)

    const searchCarParams1 = {
      country: '',
      state: '',
      city: 'Chicago',
      brand: '',
      model: '',
      yearOfProductionFrom: 0,
      yearOfProductionTo: 0,
      pricePerDayInUsdCentsFrom: 0,
      pricePerDayInUsdCentsTo: 0,
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
    }

    const availableCars1 = await rentalityTripService.searchAvailableCarsForUser(guest.address, 0, 0, searchCarParams1)

    expect(availableCars1.length).to.equal(1)

    const availableCars2 = await rentalityTripService.searchAvailableCarsForUser(guest.address, 0, 0, searchCarParams2)

    expect(availableCars2.length).to.equal(0)
  })

  it('Search with pricePerDayInUsdCentsFrom should work', async function () {
    const { rentalityCarToken, rentalityTripService, guest } = await loadFixture(deployFixtureWith1Car)

    const request = getMockCarRequest(0)
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
    }

    const availableCars1 = await rentalityTripService.searchAvailableCarsForUser(guest.address, 0, 0, searchCarParams1)

    expect(availableCars1.length).to.equal(1)

    const availableCars2 = await rentalityTripService.searchAvailableCarsForUser(guest.address, 0, 0, searchCarParams2)

    expect(availableCars2.length).to.equal(0)

    const availableCars3 = await rentalityTripService.searchAvailableCarsForUser(guest.address, 0, 0, searchCarParams3)

    expect(availableCars3.length).to.equal(1)
  })

  it('Search with pricePerDayInUsdCentsTo should work', async function () {
    const { rentalityCarToken, rentalityTripService, guest } = await loadFixture(deployFixtureWith1Car)

    const request = getMockCarRequest(0)
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
    }

    const availableCars1 = await rentalityTripService.searchAvailableCarsForUser(guest.address, 0, 0, searchCarParams1)

    expect(availableCars1.length).to.equal(1)

    const availableCars2 = await rentalityTripService.searchAvailableCarsForUser(guest.address, 0, 0, searchCarParams2)

    expect(availableCars2.length).to.equal(1)

    const availableCars3 = await rentalityTripService.searchAvailableCarsForUser(guest.address, 0, 0, searchCarParams3)

    expect(availableCars3.length).to.equal(0)
  })
})
