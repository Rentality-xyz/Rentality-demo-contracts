const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { expect } = require('chai')
const { getMockCarRequest, getEmptySearchCarParams, ethToken } = require('../utils')
const { deployDefaultFixture } = require('./deployments')

describe('Rentality: trips', function () {
  it('createTripRequest', async function () {
    const { rentalityCarToken, rentalityPlatform, rentalityCurrencyConverter, host, guest } =
      await loadFixture(deployDefaultFixture)

    await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 1,
          endDateTime: 1,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted
  })

  it('host can reject created trip', async function () {
    const { rentalityPlatform, rentalityCarToken, rentalityCurrencyConverter, host, guest } =
      await loadFixture(deployDefaultFixture)

    await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 1,
          endDateTime: 1,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).to.changeEtherBalances([guest, rentalityPlatform], [-rentPriceInEth, rentPriceInEth])

    await expect(rentalityPlatform.connect(host).rejectTripRequest(1)).to.changeEtherBalances(
      [guest, rentalityPlatform],
      [rentPriceInEth, -rentPriceInEth]
    )
  })

  it('guest can reject created trip', async function () {
    const { rentalityPlatform, rentalityCarToken, rentalityCurrencyConverter, host, guest } =
      await loadFixture(deployDefaultFixture)

    await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 1,
          endDateTime: 1,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).to.changeEtherBalances([guest, rentalityPlatform], [-rentPriceInEth, rentPriceInEth])

    await expect(rentalityPlatform.connect(guest).rejectTripRequest(1)).to.changeEtherBalances(
      [guest, rentalityPlatform],
      [rentPriceInEth, -rentPriceInEth]
    )
  })

  it('Happy case', async function () {
    const {
      rentalityPlatform,
      rentalityCarToken,
      rentalityCurrencyConverter,
      rentalityPaymentService,
      rentalityTripService,
      host,
      guest,
    } = await loadFixture(deployDefaultFixture)

    await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 1,
          endDateTime: 1,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted

    await expect(rentalityPlatform.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityTripService.connect(host).checkInByHost(1, [0, 0])).not.to.be.reverted
    await expect(rentalityTripService.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityTripService.connect(guest).checkOutByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityTripService.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted
    const returnToHost =
      rentPriceInEth - (rentPriceInEth * (await rentalityPaymentService.getPlatformFeeInPPM())) / BigInt(1_000_000)

    await expect(rentalityPlatform.connect(host).finishTrip(1)).to.changeEtherBalances(
      [host, rentalityPlatform],
      [returnToHost, -returnToHost]
    )
  })

  it('if trip accepted intersect trips should be rejected', async function () {
    const { rentalityPlatform, rentalityCarToken, rentalityTripService, rentalityCurrencyConverter, host, guest } =
      await loadFixture(deployDefaultFixture)

    await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 123,
          endDateTime: 321,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted

    await expect(
      rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 234,
          endDateTime: 456,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted

    expect((await rentalityTripService.connect(host).getTrip(1)).status).to.equal(0)
    expect((await rentalityTripService.connect(host).getTrip(2)).status).to.equal(0)

    await expect(rentalityPlatform.connect(host).approveTripRequest(1)).to.changeEtherBalances(
      [guest, rentalityPlatform],
      [rentPriceInEth, -rentPriceInEth]
    )

    const trip1 = await rentalityTripService.connect(host).getTrip(1)
    const trip2 = await rentalityTripService.connect(host).getTrip(2)
    expect(trip1.status).to.equal(1)
    expect(trip2.status).to.equal(7)
  })

  it("if trip accepted not intersect trips shouldn't be rejected", async function () {
    const { rentalityPlatform, rentalityCarToken, rentalityTripService, rentalityCurrencyConverter, host, guest } =
      await loadFixture(deployDefaultFixture)

    await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 123,
          endDateTime: 321,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted

    await expect(
      rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 456,
          endDateTime: 789,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted

    expect((await rentalityTripService.connect(host).getTrip(1)).status).to.equal(0)
    expect((await rentalityTripService.connect(host).getTrip(2)).status).to.equal(0)

    await expect(rentalityPlatform.connect(host).approveTripRequest(1)).not.to.be.reverted

    const trip1 = await rentalityTripService.connect(host).getTrip(1)
    const trip2 = await rentalityTripService.connect(host).getTrip(2)
    expect(trip1.status).to.equal(1)
    expect(trip2.status).to.equal(0)
  })

  it('searchAvailableCars should return cars with Intersect trip in status Created', async function () {
    const { rentalityPlatform, rentalityCarToken, rentalityTripService, rentalityCurrencyConverter, host, guest } =
      await loadFixture(deployDefaultFixture)

    await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)

    const timestampNow = Math.floor(Date.now() / 1000)
    const timestampIn1Day = timestampNow + 3600 * 24
    const searchCarParams = getEmptySearchCarParams()
    const availableCars = await rentalityTripService
      .connect(guest)
      .searchAvailableCarsForUser(guest.address, timestampNow, timestampIn1Day, searchCarParams)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: timestampNow,
          endDateTime: timestampIn1Day,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted

    expect((await rentalityTripService.connect(host).getTrip(1)).status).to.equal(0)

    //await expect( rentality.connect(host).approveTripRequest(1)).not.to.be.reverted;

    //const trip1 = (await rentality.connect(host).getTrip(1));
    //expect(trip1.status).to.equal(1);
    const availableCars2 = await rentalityTripService
      .connect(guest)
      .searchAvailableCarsForUser(guest.address, timestampNow, timestampIn1Day, searchCarParams)
    expect(availableCars2.length).to.equal(1)
  })

  it("searchAvailableCars shouldn't return cars with Intersect trip in status approved", async function () {
    const { rentalityPlatform, rentalityTripService, rentalityCarToken, rentalityCurrencyConverter, host, guest } =
      await loadFixture(deployDefaultFixture)

    await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)

    const timestampNow = Math.floor(Date.now() / 1000)
    const timestampIn1Day = timestampNow + 3600 * 24
    const searchCarParams = getEmptySearchCarParams()
    const availableCars = await rentalityTripService
      .connect(guest)
      .searchAvailableCarsForUser(guest.address, timestampNow, timestampIn1Day, searchCarParams)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: timestampNow,
          endDateTime: timestampIn1Day,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: rentPriceInUsdCents,
          taxPriceInUsdCents: 0,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
        },
        { value: rentPriceInEth }
      )
    ).not.to.be.reverted

    expect((await rentalityTripService.connect(host).getTrip(1)).status).to.equal(0)

    await expect(rentalityPlatform.connect(host).approveTripRequest(1)).not.to.be.reverted

    const trip1 = await rentalityTripService.connect(host).getTrip(1)
    expect(trip1.status).to.equal(1)
    const availableCars2 = await rentalityTripService
      .connect(guest)
      .searchAvailableCarsForUser(guest.address, timestampNow, timestampIn1Day, searchCarParams)
    expect(availableCars2.length).to.equal(0)
  })
})
