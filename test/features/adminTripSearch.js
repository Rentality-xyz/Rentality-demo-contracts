const { expect } = require('chai')
const {
  deployDefaultFixture,
  ethToken,
  locationInfo,
  getEmptySearchCarParams,
  signTCMessage,
  getMockCarRequest,
  calculatePayments,
  filter,
  PaymentStatus,
  AdminTripStatus,
} = require('../utils')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { ethers } = require('hardhat')

describe.only('Admin trip searching', function () {
  let rentalityGateway,
    rentalityMockPriceFeed,
    rentalityUserService,
    rentalityTripService,
    rentalityCurrencyConverter,
    rentalityCarToken,
    rentalityPaymentService,
    rentalityPlatform,
    engineService,
    rentalityAutomationService,
    deliveryService,
    elEngine,
    pEngine,
    hEngine,
    owner,
    admin,
    manager,
    host,
    guest,
    anonymous,
    rentalityAdminGateway

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
      engineService,
      rentalityAutomationService,
      deliveryService,
      elEngine,
      pEngine,
      hEngine,
      owner,
      admin,
      manager,
      host,
      guest,
      anonymous,
      rentalityAdminGateway,
    } = await loadFixture(deployDefaultFixture))
  })

  it('Search by location', async function () {
    let request = getMockCarRequest(1)
    request.locationInfo.locationInfo = {
      latitude: '',
      longitude: '',
      userAddress: 'Miami Riverwalk, Miami, Florida, USA',
      country: 'USA',
      state: 'Florida',
      city: 'Miami',

      timeZoneId: 'id',
    }
    await expect(rentalityGateway.connect(host).addCar(request)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const oneDayInSeconds = 86400

    const resultPayments = await rentalityGateway.calculatePayments(1, 1, ethToken)
    let startDateTime = Date.now() - 10
    let endDateTime = Date.now() + oneDayInSeconds + 10
    await expect(
      await rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          currencyType: ethToken,
        },
        { value: resultPayments.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-resultPayments.totalPrice, resultPayments.totalPrice])
    let searchFiler = filter
    searchFiler.location.city = request.locationInfo.locationInfo.city
    searchFiler.location.state = request.locationInfo.locationInfo.state
    searchFiler.location.country = request.locationInfo.locationInfo.country
    searchFiler.startDateTime = startDateTime
    searchFiler.endDateTime = endDateTime

    let result = await rentalityAdminGateway.getAllTrips(searchFiler, 1, 10)
    expect(result.trips.length).to.be.eq(1)

    searchFiler.location.state = 'city'

    let result2 = await rentalityAdminGateway.getAllTrips(searchFiler, 1, 10)
    expect(result2.trips.length).to.be.eq(0)
  })
  it('Pagination test', async function () {
    let request = getMockCarRequest(1)
    request.locationInfo.locationInfo = {
      latitude: '',
      longitude: '',
      userAddress: 'Miami Riverwalk, Miami, Florida, USA',
      country: 'USA',
      state: 'Florida',
      city: 'Miami',

      timeZoneId: 'id',
    }
    await expect(rentalityGateway.connect(host).addCar(request)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const oneDayInSeconds = 86400

    const resultPayments = await rentalityGateway.calculatePayments(1, 2, ethToken)
    let startDateTime = Date.now() - 10
    let endDateTime = Date.now() + oneDayInSeconds * 2
    for (let i = 0; i < 10; i++) {
      await expect(
        await rentalityGateway.connect(guest).createTripRequest(
          {
            carId: 1,
            startDateTime: Date.now(),
            endDateTime: Date.now() + oneDayInSeconds + 10,
            currencyType: ethToken,
          },
          { value: resultPayments.totalPrice }
        )
      ).to.changeEtherBalances(
        [guest, rentalityPaymentService],
        [-resultPayments.totalPrice, resultPayments.totalPrice]
      )
    }
    let searchFiler = filter
    searchFiler.location.city = request.locationInfo.locationInfo.city
    searchFiler.location.state = request.locationInfo.locationInfo.state
    searchFiler.location.country = request.locationInfo.locationInfo.country
    searchFiler.startDateTime = startDateTime
    searchFiler.endDateTime = endDateTime

    let result = await rentalityAdminGateway.getAllTrips(searchFiler, 1, 3)
    expect(result.trips.length).to.be.eq(3)
    expect(result.totalPageCount).to.be.eq(4)

    expect(result.trips[0].tripId).to.be.eq(1)
    expect(result.trips[1].tripId).to.be.eq(2)
    expect(result.trips[2].tripId).to.be.eq(3)

    let result2 = await rentalityAdminGateway.getAllTrips(searchFiler, 2, 3)

    expect(result2.trips.length).to.be.eq(3)

    expect(result2.trips[0].tripId).to.be.eq(4)
    expect(result2.trips[1].tripId).to.be.eq(5)
    expect(result2.trips[2].tripId).to.be.eq(6)

    let result3 = await rentalityAdminGateway.getAllTrips(searchFiler, 3, 3)
    expect(result3.trips.length).to.be.eq(3)

    expect(result3.trips[0].tripId).to.be.eq(7)
    expect(result3.trips[1].tripId).to.be.eq(8)
    expect(result3.trips[2].tripId).to.be.eq(9)

    let result4 = await rentalityAdminGateway.getAllTrips(searchFiler, 4, 3)
    expect(result4.trips.length).to.be.eq(1)
    expect(result4.trips[0].tripId).to.be.eq(10)
  })
  it('Payment status', async function () {
    let request = getMockCarRequest(1)
    request.locationInfo.locationInfo = {
      latitude: '',
      longitude: '',
      userAddress: 'Miami Riverwalk, Miami, Florida, USA',
      country: 'USA',
      state: 'Florida',
      city: 'Miami',

      timeZoneId: 'id',
    }
    await expect(rentalityGateway.connect(host).addCar(request)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const oneDayInSeconds = 86400

    const resultPayments = await rentalityGateway.calculatePayments(1, 2, ethToken)
    let startDateTime = Date.now() - 10
    let endDateTime = Date.now() + oneDayInSeconds * 2
    let searchFiler = filter
    searchFiler.paymentStatus = PaymentStatus.Prepayment

    await expect(
      await rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds + 10,
          currencyType: ethToken,
        },
        { value: resultPayments.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-resultPayments.totalPrice, resultPayments.totalPrice])
    let result = await rentalityAdminGateway.getAllTrips(searchFiler, 1, 3)
    expect(result.trips.length).to.be.eq(1)
    expect(result.trips[0].tripId).to.be.eq(1)

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    result = await rentalityAdminGateway.getAllTrips(searchFiler, 1, 3)
    expect(result.trips.length).to.be.eq(1)
    expect(result.trips[0].tripId).to.be.eq(1)

    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    result = await rentalityAdminGateway.getAllTrips(searchFiler, 1, 3)
    expect(result.trips.length).to.be.eq(1)

    expect(result.trips[0].tripId).to.be.eq(1)

    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
    result = await rentalityAdminGateway.getAllTrips(searchFiler, 1, 3)
    expect(result.trips.length).to.be.eq(1)
    expect(result.trips[0].tripId).to.be.eq(1)

    await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [0, 0])).not.to.be.reverted
    result = await rentalityAdminGateway.getAllTrips(searchFiler, 1, 3)
    expect(result.trips.length).to.be.eq(1)
    expect(result.trips[0].tripId).to.be.eq(1)

    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted
    result = await rentalityAdminGateway.getAllTrips(searchFiler, 1, 3)
    expect(result.trips.length).to.be.eq(1)
    expect(result.trips[0].tripId).to.be.eq(1)

    await expect(rentalityGateway.connect(host).finishTrip(1)).not.to.be.reverted
    result = await rentalityAdminGateway.getAllTrips(searchFiler, 1, 3)
    expect(result.trips.length).to.be.eq(0)

    searchFiler.paymentStatus = PaymentStatus.PaidToHost
    result = await rentalityAdminGateway.getAllTrips(searchFiler, 1, 3)
    expect(result.trips.length).to.be.eq(1)
    expect(result.trips[0].tripId).to.be.eq(1)
  })
  it('Payment status unpaid', async function () {
    let request = getMockCarRequest(1)
    request.locationInfo.locationInfo = {
      latitude: '',
      longitude: '',
      userAddress: 'Miami Riverwalk, Miami, Florida, USA',
      country: 'USA',
      state: 'Florida',
      city: 'Miami',

      timeZoneId: 'id',
    }
    await expect(rentalityGateway.connect(host).addCar(request)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const oneDayInSeconds = 86400

    const resultPayments = await rentalityGateway.calculatePayments(1, 2, ethToken)
    let startDateTime = Date.now() - 10
    let endDateTime = Date.now() + oneDayInSeconds * 2
    let searchFiler = filter
    searchFiler.paymentStatus = PaymentStatus.Prepayment

    await expect(
      await rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds + 10,
          currencyType: ethToken,
        },
        { value: resultPayments.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-resultPayments.totalPrice, resultPayments.totalPrice])
    let result = await rentalityAdminGateway.getAllTrips(searchFiler, 1, 3)
    expect(result.trips.length).to.be.eq(1)
    expect(result.trips[0].tripId).to.be.eq(1)

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    result = await rentalityAdminGateway.getAllTrips(searchFiler, 1, 3)
    expect(result.trips.length).to.be.eq(1)
    expect(result.trips[0].tripId).to.be.eq(1)

    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    result = await rentalityAdminGateway.getAllTrips(searchFiler, 1, 3)
    expect(result.trips.length).to.be.eq(1)

    expect(result.trips[0].tripId).to.be.eq(1)

    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted
    searchFiler.paymentStatus = PaymentStatus.Unpaid
    result = await rentalityAdminGateway.getAllTrips(searchFiler, 1, 3)
    expect(result.trips.length).to.be.eq(1)
    expect(result.trips[0].tripId).to.be.eq(1)

    await expect(rentalityGateway.connect(admin).confirmCheckOut(1)).not.to.be.reverted

    searchFiler.paymentStatus = PaymentStatus.PaidToHost
    result = await rentalityAdminGateway.getAllTrips(searchFiler, 1, 3)
    expect(result.trips.length).to.be.eq(1)
    expect(result.trips[0].tripId).to.be.eq(1)
  })
  it('Payment status refund to guest', async function () {
    let request = getMockCarRequest(1)
    request.locationInfo.locationInfo = {
      latitude: '',
      longitude: '',
      userAddress: 'Miami Riverwalk, Miami, Florida, USA',
      country: 'USA',
      state: 'Florida',
      city: 'Miami',

      timeZoneId: 'id',
    }
    await expect(rentalityGateway.connect(host).addCar(request)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const oneDayInSeconds = 86400

    const resultPayments = await rentalityGateway.calculatePayments(1, 2, ethToken)
    let startDateTime = Date.now() - 10
    let endDateTime = Date.now() + oneDayInSeconds * 2
    let searchFiler = filter
    searchFiler.paymentStatus = PaymentStatus.Prepayment

    await expect(
      await rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds + 10,
          currencyType: ethToken,
        },
        { value: resultPayments.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-resultPayments.totalPrice, resultPayments.totalPrice])

    searchFiler.paymentStatus = PaymentStatus.RefundToGuest

    await expect(rentalityGateway.connect(host).rejectTripRequest(1)).not.to.be.reverted
    let result = await rentalityAdminGateway.getAllTrips(searchFiler, 1, 3)
    expect(result.trips.length).to.be.eq(1)
    expect(result.trips[0].tripId).to.be.eq(1)
  })
  it('Admin status', async function () {
    let request = getMockCarRequest(1)
    request.locationInfo.locationInfo = {
      latitude: '',
      longitude: '',
      userAddress: 'Miami Riverwalk, Miami, Florida, USA',
      country: 'USA',
      state: 'Florida',
      city: 'Miami',

      timeZoneId: 'id',
    }
    await expect(rentalityGateway.connect(host).addCar(request)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const oneDayInSeconds = 86400

    const resultPayments = await rentalityGateway.calculatePayments(1, 2, ethToken)
    let startDateTime = Date.now() - 10
    let endDateTime = Date.now() + oneDayInSeconds * 2
    let searchFiler = filter
    searchFiler.paymentStatus = PaymentStatus.Prepayment
    searchFiler.status = AdminTripStatus.Created

    await expect(
      await rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds + 10,
          currencyType: ethToken,
        },
        { value: resultPayments.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-resultPayments.totalPrice, resultPayments.totalPrice])
    let result = await rentalityAdminGateway.getAllTrips(searchFiler, 1, 3)
    expect(result.trips.length).to.be.eq(1)
    expect(result.trips[0].tripId).to.be.eq(1)

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    searchFiler.status = AdminTripStatus.Approved
    result = await rentalityAdminGateway.getAllTrips(searchFiler, 1, 3)
    expect(result.trips.length).to.be.eq(1)
    expect(result.trips[0].tripId).to.be.eq(1)

    searchFiler.status = AdminTripStatus.CheckedInByHost
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    result = await rentalityAdminGateway.getAllTrips(searchFiler, 1, 3)
    expect(result.trips.length).to.be.eq(1)
    expect(result.trips[0].tripId).to.be.eq(1)

    searchFiler.paymentStatus = PaymentStatus.Unpaid
    searchFiler.status = AdminTripStatus.CompletedWithoutGuestConfirmation
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted
    result = await rentalityAdminGateway.getAllTrips(searchFiler, 1, 3)
    expect(result.trips.length).to.be.eq(1)
    expect(result.trips[0].tripId).to.be.eq(1)

    await expect(rentalityGateway.connect(admin).confirmCheckOut(1)).not.to.be.reverted

    searchFiler.status = AdminTripStatus.CompletedByAdmin
    searchFiler.paymentStatus = PaymentStatus.PaidToHost
    result = await rentalityAdminGateway.getAllTrips(searchFiler, 1, 3)
    expect(result.trips.length).to.be.eq(1)
    expect(result.trips[0].tripId).to.be.eq(1)
  })
})
