const { expect } = require('chai')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')

const {
  getMockCarRequest,
  TripStatus,
  deployDefaultFixture,
  ethToken,
  calculatePayments,
  locationInfo,
  signTCMessage,
  signLocationInfo,
  emptyLocationInfo,
  getEmptySearchCarParams,
  zeroHash,
  emptySignedLocationInfo,
} = require('../utils')
const { ethers } = require('hardhat')

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
    } = await loadFixture(deployDefaultFixture))
  })

  it('createTripRequest', async function () {
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

    const result = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      1,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo,
      ' '
    )
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])
  })

  it('Return valid trip data', async function () {
    const mockCreateCarRequest = getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(mockCreateCarRequest)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    let tax = (mockCreateCarRequest.pricePerDayInUsdCents * 7) / 100
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

    const result = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      1,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo,
      ' '
    )
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    let trip = (await rentalityGateway.getTrip(1)).trip
    const carLocation = await rentalityGeoService.hashLocationInfo(locationInfo)

    expect(trip.tripId).to.be.equal(1, 'trip.tripId)')
    expect(trip.carId).to.be.equal(1, 'trip.carId')
    expect(trip.status).to.be.equal(TripStatus.Created, 'trip.status')
    expect(trip.guest).to.be.equal(guest.address, 'trip.guest')
    expect(trip.host).to.be.equal(host.address, 'trip.host')
    expect(trip.pricePerDayInUsdCents).to.be.equal(2, 'trip.pricePerDayInUsdCents')
    expect(trip.startDateTime).to.be.equal(123, 'trip.startDateTime')
    expect(trip.endDateTime).to.be.equal(321, 'trip.pickUpHash')
    expect(trip.pickUpHash).to.be.equal(carLocation, 'trip.returnHash')
    expect(trip.returnHash).to.be.equal(carLocation, 'trip.endLocation')
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
        BigInt(mockCreateCarRequest.pricePerDayInUsdCents),
        BigInt(0),
        BigInt(200),
        BigInt(mockCreateCarRequest.pricePerDayInUsdCents),
        mockCreateCarRequest.securityDepositPerTripInUsdCents,
        0n,
        ethToken,
        result.currencyRate,
        result.currencyDecimals,
        0n,
        0n,
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
    const locationInfo = {
      userAddress: 'Miami Riverwalk, Miami, Florida, USA',
      country: 'USA',
      state: 'Florida',
      city: 'Miami',
      latitude: '1.2',
      longitude: '1.3',
      timeZoneId: 'id',
    }
    let locationInfo1 = {
      locationInfo,
      signature: signLocationInfo(await rentalityLocationVerifier.getAddress(), admin, locationInfo),
    }
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
      geoApiKey: 'key',
      insuranceIncluded: true,
      locationInfo: locationInfo1,
      currentlyListed: true,
      insuranceRequired: false,
      insurancePriceInUsdCents: 0,
dimoTokenId: 0,
signedDimoTokenId: '0x'
    }

    await expect(rentalityGateway.connect(host).addCar(mockCreateCarRequest)).not.to.be.reverted

    const dailyPriceInUsdCents = 1000

    const result = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      1,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo,
      ' '
    )
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

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
      geoApiKey: 'key',
      insuranceIncluded: true,
      locationInfo: locationInfo1,
      currentlyListed: true,
      insuranceRequired: false,
      insurancePriceInUsdCents: 0,
dimoTokenId: 0,
signedDimoTokenId: '0x'
    }
    await expect(rentalityGateway.connect(host).addCar(mockPatrolCreateCarRequest)).not.to.be.reverted
    const resultPatrol = await rentalityGateway.calculatePaymentsWithDelivery(
      2,
      1,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo,
      ' '
    )
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 2,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: resultPatrol.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-resultPatrol.totalPrice, resultPatrol.totalPrice])

    let tripWithPatrol = (await rentalityGateway.getTrip(2)).trip

    expect(tripWithPatrol.fuelPrice).to.equal(mockPatrolCreateCarRequest.engineParams[1])
  })

  it('Host can not create trip request for own car ', async function () {
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

    const oneDayInSeconds = 86400

    const dailyPriceInUsdCents = 1000

    const { rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals, rentalityFee } = await calculatePayments(
      rentalityCurrencyConverter,
      rentalityPaymentService,
      dailyPriceInUsdCents,
      1,
      0
    )

    await expect(
      rentalityGateway.connect(host).createTripRequestWithDelivery(
        {
          carId: 1,
          host: host.address,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          startLocation: '',
          endLocation: '',
          totalDayPriceInUsdCents: dailyPriceInUsdCents,
          depositInUsdCents: 0,
          currencyRate: ethToCurrencyRate,
          currencyDecimals: ethToCurrencyDecimals,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: rentPriceInEth }
      )
    ).to.be.revertedWith('Car is not available for creator')
  })

  it('host can reject created trip', async function () {
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

    const result = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      1,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo,
      ' '
    )
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    await expect(rentalityGateway.connect(host).rejectTripRequest(1)).to.changeEtherBalances(
      [guest, rentalityPaymentService],
      [result.totalPrice, -result.totalPrice]
    )
  })

  it('guest can reject created trip', async function () {
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

    const result = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      1,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo,
      ' '
    )
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    await expect(rentalityGateway.connect(guest).rejectTripRequest(1)).to.changeEtherBalances(
      [guest, rentalityPaymentService],
      [result.totalPrice, -result.totalPrice]
    )
  })

  it('Only host or guest can reject trip', async function () {
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

    const result = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      1,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo,
      ' '
    )
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    await expect(rentalityGateway.connect(anonymous).rejectTripRequest(1)).to.be.reverted

    await expect(rentalityGateway.connect(admin).rejectTripRequest(1)).to.be.reverted

    await expect(rentalityGateway.connect(owner).rejectTripRequest(1)).to.be.reverted

    let trip = (await rentalityGateway.getTrip(1)).trip

    expect(trip.status).to.be.equal(TripStatus.Created)
  })

  it('Only host can approve the trip', async function () {
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

    const result = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      1,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo,
      ' '
    )
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

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

    const result = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      1,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo,
      ' '
    )
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).to.be.reverted

    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).to.be.reverted

    await expect(rentalityGateway.connect(host).finishTrip(1)).to.be.reverted

    let trip = (await rentalityGateway.getTrip(1)).trip

    expect(trip.status).to.be.equal(TripStatus.Created)
  })

  it('Only host can checkin after approve', async function () {
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

    const result = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      1,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo,
      ' '
    )
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    expect(await rentalityGateway.connect(host).approveTripRequest(1)).not.be.reverted

    await expect(rentalityGateway.connect(guest).checkInByHost(1, [0, 0], '', '')).to.be.reverted

    await expect(rentalityGateway.connect(anonymous).checkInByHost(1, [0, 0], '', '')).to.be.reverted

    await expect(rentalityGateway.connect(admin).checkInByHost(1, [0, 0], '', '')).to.be.reverted

    await expect(rentalityGateway.connect(owner).checkInByHost(1, [0, 0], '', '')).to.be.reverted

    let trip = (await rentalityGateway.getTrip(1)).trip

    expect(trip.status).to.be.equal(TripStatus.Approved)

    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.be.reverted

    let trip_checkin = (await rentalityGateway.getTrip(1)).trip

    expect(trip_checkin.status).to.be.equal(2)
  })

  it('Only guest can checkin after host', async function () {
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

    const result = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      1,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo,
      ' '
    )
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    expect(await rentalityGateway.connect(host).approveTripRequest(1)).not.be.reverted

    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.be.reverted

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

    const result = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      1,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo,
      ' '
    )
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])
    expect(await rentalityGateway.connect(host).approveTripRequest(1)).not.be.reverted

    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.be.reverted

    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.be.reverted

    await expect(rentalityGateway.connect(anonymous).checkOutByGuest(1, [0, 0])).to.be.reverted

    await expect(rentalityGateway.connect(admin).checkOutByGuest(1, [0, 0])).to.be.reverted

    await expect(rentalityGateway.connect(owner).checkOutByGuest(1, [0, 0])).to.be.reverted

    let trip = (await rentalityGateway.getTrip(1)).trip

    expect(trip.status).to.be.equal(TripStatus.CheckedInByGuest)

    await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [0, 0])).not.be.reverted

    let trip_checkout = (await rentalityGateway.connect(guest).getTrip(1)).trip

    expect(trip_checkout.status).to.be.equal(TripStatus.CheckedOutByGuest)
  })

  it('Only host can checkout after guest checkout', async function () {
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

    const result = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      1,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo,
      ' '
    )
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    expect(await rentalityGateway.connect(host).approveTripRequest(1)).not.be.reverted

    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.be.reverted

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
    const request = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(request)).not.to.be.reverted
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

    const oneDayInSeconds = 86400

    const { rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals, rentalityFee, taxes } = await calculatePayments(
      rentalityCurrencyConverter,
      rentalityPaymentService,
      request.pricePerDayInUsdCents,
      1,
      request.securityDepositPerTripInUsdCents
    )
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: rentPriceInEth }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-rentPriceInEth, rentPriceInEth])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted

    const depositValue = await rentalityCurrencyConverter.getFromUsd(
      ethToken,
      request.securityDepositPerTripInUsdCents,
      ethToCurrencyRate,
      ethToCurrencyDecimals
    )

    const returnToHost = rentPriceInEth - depositValue - rentalityFee - taxes

    await expect(rentalityGateway.connect(host).finishTrip(1)).to.changeEtherBalances(
      [host, rentalityPaymentService],
      [returnToHost, -(rentPriceInEth - rentalityFee - taxes)]
    )
  })

  it('Should not be able to create trip request after approve on the same time', async function () {
    let addCarRequest = getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(addCarRequest)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const oneDayInSeconds = 86400

    const result = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      1,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo,
      ' '
    )
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).not.to.be.reverted

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted

    const result2Days = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      2,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo,
      ' '
    )
    await expect(
      rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds * 2,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result2Days.totalPrice }
      )
    ).to.be.revertedWith('Unavailable for current date.')

    await expect(
      rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now() + oneDayInSeconds * 3,
          endDateTime: Date.now() + oneDayInSeconds * 4,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).not.to.be.reverted
  })

  it('Can not checkInBy host while car on the trip', async function () {
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

    const oneDayInSeconds = 86400
    const dailyPriceInUsdCents = 1000

    const result = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      1,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo,
      ' '
    )
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).to.not.reverted

    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).to.not.reverted

    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).to.not.reverted

    await expect(
      rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now() + oneDayInSeconds * 3,
          endDateTime: Date.now() + oneDayInSeconds * 4,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    await expect(rentalityGateway.connect(host).approveTripRequest(2)).not.be.reverted

    await expect(rentalityGateway.connect(host).checkInByHost(2, [0, 0], '', '')).to.be.revertedWith('Car on the trip.')
  })
  it('Return correct total trip price', async function () {
    const mockCreateCarRequest = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(mockCreateCarRequest)).not.to.be.reverted
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

    let dayInSeconds = 86400
    let tripDays = 4
    const result = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      tripDays,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo,
      ' '
    )
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + dayInSeconds * tripDays,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    let paymentInfo = (await rentalityGateway.getTrip(1)).trip.paymentInfo

    expect(paymentInfo.totalDayPriceInUsdCents).to.be.eq(mockCreateCarRequest.pricePerDayInUsdCents * tripDays)
  })

  it('Return in reject same value as in trip start', async function () {
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

    const oneDayInSeconds = 86400
    const dailyPriceInUsdCents = 1000

    const result = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      1,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo,
      ' '
    )
    let value = result.totalPrice - result.totalPrice / BigInt(100)
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: value }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-value, value])

    await expect(await rentalityGateway.connect(guest).rejectTripRequest(1)).to.changeEtherBalances(
      [guest, rentalityPaymentService],
      [value, -value]
    )
  })

  it('Migration test', async function () {
    const mockCreateCarRequest = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(mockCreateCarRequest)).not.to.be.reverted
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

    let dayInSeconds = 86400
    let tripDays = 4
    const result = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      tripDays,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo,
      ' '
    )
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + dayInSeconds * tripDays,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + dayInSeconds * tripDays,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + dayInSeconds * tripDays,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])
let guestTrips = await rentalityTripService.getTripsByUser(guest.address)
let hostTrips = await rentalityTripService.getTripsByUser(host.address)

let guestActiveTrips = await rentalityTripService.getActiveTripsByUser(guest.address)
let hostActiveTrips = await rentalityTripService.getActiveTripsByUser(host.address)
 expect(guestTrips.length).to.be.eq(3)
 expect(hostTrips.length).to.be.eq(3)
 expect(guestActiveTrips.length).to.be.eq(3)
 expect(hostActiveTrips.length).to.be.eq(3)

 await rentalityTripService.setUserTrips(1,0)
  guestTrips = await rentalityTripService.getTripsByUser(guest.address)
 hostTrips = await rentalityTripService.getTripsByUser(host.address)

 guestActiveTrips = await rentalityTripService.getActiveTripsByUser(guest.address)
 hostActiveTrips = await rentalityTripService.getActiveTripsByUser(host.address)
 expect(guestTrips.length).to.be.eq(6)
 expect(hostTrips.length).to.be.eq(6)
 expect(guestActiveTrips.length).to.be.eq(6)
 expect(hostActiveTrips.length).to.be.eq(6)
  })
  it('Get only host trips', async function () {
    const mockCreateCarRequest = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityGateway.connect(host).addCar(mockCreateCarRequest)).not.to.be.reverted
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

    let dayInSeconds = 86400
    let tripDays = 4
    const result = await rentalityGateway.calculatePaymentsWithDelivery(
      1,
      tripDays,
      ethToken,
      emptyLocationInfo,
      emptyLocationInfo,
      ' '
    )
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + dayInSeconds * tripDays,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])
    
     await expect(await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + dayInSeconds * tripDays,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + dayInSeconds * tripDays,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])
    const mockCreateCarRequest2 = getMockCarRequest(1, await rentalityLocationVerifier.getAddress(), admin)
    mockCreateCarRequest2.carVinNumber = "my vin number"
    await expect(rentalityGateway.connect(guest).addCar(mockCreateCarRequest2)).not.to.be.reverted

    await expect(
      await rentalityGateway.connect(host).createTripRequestWithDelivery(
        {
          carId: 2,
          startDateTime: Date.now(),
          endDateTime: Date.now() + dayInSeconds * tripDays,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([host, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    await expect(
      await rentalityGateway.connect(host).createTripRequestWithDelivery(
        {
          carId: 2,
          startDateTime: Date.now(),
          endDateTime: Date.now() + dayInSeconds * tripDays,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([host, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    await expect(
      await rentalityGateway.connect(host).createTripRequestWithDelivery(
        {
          carId: 2,
          startDateTime: Date.now(),
          endDateTime: Date.now() + dayInSeconds * tripDays,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        ' ',
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([host, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    const asGuestTrips = await rentalityGateway.connect(guest).getTripsAs(false)
    const asHostTrips = await rentalityGateway.connect(host).getTripsAs(true)
    expect(asGuestTrips.length).to.be.eq(3)
    expect(asHostTrips.length).to.be.eq(3)
  })
 
})
