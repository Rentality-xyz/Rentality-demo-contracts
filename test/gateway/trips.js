const { expect } = require('chai')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')

const { getMockCarRequest, TripStatus, deployDefaultFixture, ethToken } = require('../utils')

describe('RentalityGateway: trips', function () {
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

  it('createTripRequest', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
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

  it('Return valid trip data', async function () {
    const mockCreateCarRequest = getMockCarRequest(0)
    await expect(rentalityGateway.connect(host).addCar(mockCreateCarRequest)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 1,
          endDateTime: 1,
          startLocation: 'startLocation',
          endLocation: 'endLocation',
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

    let trip = (await rentalityGateway.getTrip(1)).trip

    expect(trip.tripId).to.be.equal(1, 'trip.tripId)')
    expect(trip.carId).to.be.equal(1, 'trip.carId')
    expect(trip.status).to.be.equal(TripStatus.Created, 'trip.status')
    expect(trip.guest).to.be.equal(guest.address, 'trip.guest')
    expect(trip.host).to.be.equal(host.address, 'trip.host')
    expect(trip.pricePerDayInUsdCents).to.be.equal(2, 'trip.pricePerDayInUsdCents')
    expect(trip.startDateTime).to.be.equal(1, 'trip.startDateTime')
    expect(trip.endDateTime).to.be.equal(1, 'trip.endDateTime')
    expect(trip.startLocation).to.be.equal('startLocation', 'trip.startLocation')
    expect(trip.endLocation).to.be.equal('endLocation', 'trip.endLocation')
    expect(trip.milesIncludedPerDay).to.be.equal(6, 'trip.milesIncludedPerDay')
    expect(BigInt(trip.fuelPrice)).to.deep.equal(
      mockCreateCarRequest.engineParams[1] /*[0] - is tank volume,
     [1] - fuel price per gal*/,
      'trip.fuelPrices'
    )
    expect(trip.paymentInfo).to.deep.equal(
      [
        1n,
        guest.address,
        await rentalityPlatform.getAddress(),
        BigInt(rentPriceInUsdCents),
        0n,
        0n,
        0n,
        0n,
        ethToCurrencyRate,
        ethToCurrencyDecimals,
        0n,
        0n,
      ],
      'trip.paymentInfo'
    )
    expect(trip.createdDateTime).to.be.greaterThan(0, 'trip.createdDateTime')
    expect(trip.approvedDateTime).to.be.equal(0, 'trip.approvedDateTime')
    expect(trip.rejectedDateTime).to.be.equal(0, 'trip.rejectedDateTime')
    expect(trip.rejectedBy).to.be.equal('0x0000000000000000000000000000000000000000', 'trip.rejectedBy')
    expect(trip.checkedInByHostDateTime).to.be.equal(0, 'trip.checkedInByHostDateTime')
    expect(trip.startParamLevels).to.deep.equal([0, 0], 'trip.startParamLevels')
    expect(trip.checkedInByGuestDateTime).to.be.equal(0, 'trip.checkedInByGuestDateTime')
    expect(trip.tripStartedBy).to.be.equal('0x0000000000000000000000000000000000000000', 'trip.tripStartedBy')
    expect(trip.checkedOutByGuestDateTime).to.be.equal(0, 'trip.checkedOutByGuestDateTime')
    expect(trip.tripFinishedBy).to.be.equal('0x0000000000000000000000000000000000000000', 'trip.tripFinishedBy')
    expect(trip.endParamLevels).to.deep.equal([0, 0], 'trip.endParamLevels')
    expect(trip.checkedOutByHostDateTime).to.be.equal(0, 'trip.checkedOutByHostDateTime')
    expect(trip.transactionInfo).to.deep.equal([0n, 0n, 0n, 0n, 0n], 'trip.transactionInfo')
    expect(trip.guestName).to.be.equal(' ', 'trip.guestName')
    expect(trip.hostName).to.be.equal(' ', 'trip.hostName')
  })

  it('Return valid fuel prices', async function () {
    const mockCreateCarRequest = {
      tokenUri: 'uri',
      carVinNumber: 'VIN_NUMBER',
      brand: 'BRAND',
      model: 'MODEL',
      yearOfProduction: 2020,
      pricePerDayInUsdCents: 1,
      securityDepositPerTripInUsdCents: 1,
      engineParams: [10],
      engineType: 2,
      milesIncludedPerDay: 10,
      timeBufferBetweenTripsInSec: 0,
      locationAddress: 'location',
      locationLatitude: '123421',
      locationLongitude: '123421',
      geoApiKey: 'key',
    }

    await expect(rentalityGateway.connect(host).addCar(mockCreateCarRequest)).not.to.be.reverted

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 1,
          endDateTime: 1,
          startLocation: 'startLocation',
          endLocation: 'endLocation',
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

    let trip = (await rentalityGateway.getTrip(1)).trip

    expect(trip.fuelPrice).to.deep.equal(mockCreateCarRequest.engineParams[0])

    const mockPatrolCreateCarRequest = {
      tokenUri: 'uri',
      carVinNumber: 'VIN_NUMBER1',
      brand: 'BRAND',
      model: 'MODEL',
      yearOfProduction: 2020,
      pricePerDayInUsdCents: 1,
      securityDepositPerTripInUsdCents: 1,
      engineParams: [1, 400],
      engineType: 1,
      milesIncludedPerDay: 10,
      timeBufferBetweenTripsInSec: 0,
      locationAddress: 'location',
      locationLatitude: '123421',
      locationLongitude: '123421',
      geoApiKey: 'key',
    }
    await expect(rentalityGateway.connect(host).addCar(mockPatrolCreateCarRequest)).not.to.be.reverted
    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 2,
          host: host.address,
          startDateTime: 1,
          endDateTime: 1,
          startLocation: 'startLocation',
          endLocation: 'endLocation',
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

    let tripWithPatrol = (await rentalityGateway.getTrip(2)).trip

    expect(tripWithPatrol.fuelPrice).to.equal(mockPatrolCreateCarRequest.engineParams[1])
  })

  it('Host can not create trip request for own car ', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityGateway.connect(host).createTripRequest(
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
    ).to.be.revertedWith('Car is not available for creator')
  })

  it('host can reject created trip', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
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

    await expect(rentalityGateway.connect(host).rejectTripRequest(1)).to.changeEtherBalances(
      [guest, rentalityPlatform],
      [rentPriceInEth, -rentPriceInEth]
    )
  })

  it('guest can reject created trip', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
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

    await expect(rentalityGateway.connect(guest).rejectTripRequest(1)).to.changeEtherBalances(
      [guest, rentalityPlatform],
      [rentPriceInEth, -rentPriceInEth]
    )
  })

  it('Only host or guest can reject trip', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
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

    await expect(rentalityGateway.connect(anonymous).rejectTripRequest(1)).to.be.reverted

    await expect(rentalityGateway.connect(admin).rejectTripRequest(1)).to.be.reverted

    await expect(rentalityGateway.connect(owner).rejectTripRequest(1)).to.be.reverted

    let trip = (await rentalityGateway.getTrip(1)).trip

    expect(trip.status).to.be.equal(TripStatus.Created)
  })

  it('Only host can approve the trip', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
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

    await expect(rentalityGateway.connect(anonymous).approveTripRequest(1)).to.be.reverted

    await expect(rentalityGateway.connect(guest).approveTripRequest(1)).to.be.reverted

    await expect(rentalityGateway.connect(admin).approveTripRequest(1)).to.be.reverted

    await expect(rentalityGateway.connect(owner).approveTripRequest(1)).to.be.reverted

    let trip = (await rentalityGateway.getTrip(1)).trip

    expect(trip.status).to.be.equal(TripStatus.Created)

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.be.reverted

    let trip_approved = (await rentalityGateway.getTrip(1)).trip

    expect(trip_approved.status).to.be.equal(1)
  })

  it('Host can not cheng status before approve', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
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
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0])).to.be.reverted

    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).to.be.reverted

    await expect(rentalityPlatform.connect(host).finishTrip(1)).to.be.reverted

    let trip = (await rentalityGateway.getTrip(1)).trip

    expect(trip.status).to.be.equal(TripStatus.Created)
  })

  it('Only host can checkin after approve', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
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
    expect(await rentalityGateway.connect(host).approveTripRequest(1)).not.be.reverted

    await expect(rentalityGateway.connect(guest).checkInByHost(1, [0, 0])).to.be.reverted

    await expect(rentalityGateway.connect(anonymous).checkInByHost(1, [0, 0])).to.be.reverted

    await expect(rentalityGateway.connect(admin).checkInByHost(1, [0, 0])).to.be.reverted

    await expect(rentalityGateway.connect(owner).checkInByHost(1, [0, 0])).to.be.reverted

    let trip = (await rentalityGateway.getTrip(1)).trip

    expect(trip.status).to.be.equal(TripStatus.Approved)

    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0])).not.be.reverted

    let trip_checkin = (await rentalityGateway.getTrip(1)).trip

    expect(trip_checkin.status).to.be.equal(2)
  })

  it('Only guest can checkin after host', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
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
    expect(await rentalityGateway.connect(host).approveTripRequest(1)).not.be.reverted

    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0])).not.be.reverted

    await expect(rentalityGateway.connect(anonymous).checkInByGuest(1, [0, 0])).to.be.reverted

    await expect(rentalityGateway.connect(host).checkInByGuest(1, [0, 0])).to.be.reverted

    await expect(rentalityGateway.connect(admin).checkInByGuest(1, [0, 0])).to.be.reverted

    await expect(rentalityGateway.connect(owner).checkInByGuest(1, [0, 0])).to.be.reverted

    let trip = (await rentalityGateway.getTrip(1)).trip

    expect(trip.status).to.be.equal(TripStatus.CheckedInByHost)

    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.be.reverted

    let trip_checkin = (await rentalityGateway.connect(guest).getTrip(1)).trip

    expect(trip_checkin.status).to.be.equal(TripStatus.CheckedInByGuest)
  })

  it('Only guest can checkout after checkin', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    const currentTimestampInSeconds = Math.floor(Date.now() / 1000)
    const tomorrow = currentTimestampInSeconds + 60 * 60 * 24
    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: 1,
          endDateTime: tomorrow,
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
    expect(await rentalityGateway.connect(host).approveTripRequest(1)).not.be.reverted

    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0])).not.be.reverted

    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.be.reverted

    await expect(rentalityGateway.connect(anonymous).checkOutByGuest(1, [0, 0])).to.be.reverted

    await expect(rentalityGateway.connect(host).checkOutByGuest(1, [0, 0])).to.be.reverted

    await expect(rentalityGateway.connect(admin).checkOutByGuest(1, [0, 0])).to.be.reverted

    await expect(rentalityGateway.connect(owner).checkOutByGuest(1, [0, 0])).to.be.reverted

    let trip = (await rentalityGateway.getTrip(1)).trip

    expect(trip.status).to.be.equal(TripStatus.CheckedInByGuest)

    await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [0, 0])).not.be.reverted

    let trip_checkout = (await rentalityGateway.connect(guest).getTrip(1)).trip

    expect(trip_checkout.status).to.be.equal(TripStatus.CheckedOutByGuest)
  })

  it('Only host can checkout after guest checkout', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
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
    expect(await rentalityGateway.connect(host).approveTripRequest(1)).not.be.reverted

    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0])).not.be.reverted

    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.be.reverted

    await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [0, 0])).not.be.reverted

    await expect(rentalityGateway.connect(anonymous).checkOutByHost(1, [0, 0])).to.be.reverted

    await expect(rentalityGateway.connect(guest).checkOutByHost(1, [0, 0])).to.be.reverted

    await expect(rentalityGateway.connect(admin).checkOutByHost(1, [0, 0])).to.be.reverted

    await expect(rentalityGateway.connect(owner).checkOutByHost(1, [0, 0])).to.be.reverted

    let trip = (await rentalityGateway.getTrip(1)).trip

    expect(trip.status).to.be.equal(TripStatus.CheckedOutByGuest)

    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.be.reverted

    let trip_checkout = (await rentalityGateway.connect(guest).getTrip(1)).trip

    expect(trip_checkout.status).to.be.equal(TripStatus.CheckedOutByHost)
  })

  it('Happy case', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
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

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted

    const returnToHost =
      rentPriceInEth - (rentPriceInEth * (await rentalityAdminGateway.getPlatformFeeInPPM())) / BigInt(1_000_000)

    await expect(rentalityGateway.connect(host).finishTrip(1)).to.changeEtherBalances(
      [host, rentalityPlatform],
      [returnToHost, -returnToHost]
    )
  })

  it('Should not be able to create trip request after approve on the same time', async function () {
    let addCarRequest = getMockCarRequest(0)
    await expect(rentalityGateway.connect(host).addCar(addCarRequest)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const oneDayInMilliseconds = 24 * 60 * 60 * 1000

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInMilliseconds,
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

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInMilliseconds * 2,
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
    ).to.be.revertedWith('Unavailable for current date.')

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: Date.now() * 3,
          endDateTime: Date.now() + oneDayInMilliseconds * 4,
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

  it('Can not checkInBy host while car on the trip', async function () {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getFromUsdLatest(ethToken, rentPriceInUsdCents)
    const oneDayInMilliseconds = 24 * 60 * 60 * 1000
    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInMilliseconds,
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

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).to.not.reverted

    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0])).to.not.reverted

    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).to.not.reverted

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          host: host.address,
          startDateTime: Date.now() + oneDayInMilliseconds * 3,
          endDateTime: Date.now() + oneDayInMilliseconds * 4,
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

    await expect(rentalityGateway.connect(host).approveTripRequest(2)).not.be.reverted

    await expect(rentalityGateway.connect(host).checkInByHost(2, [0, 0])).to.be.revertedWith('Car on the trip.')
  })
})
