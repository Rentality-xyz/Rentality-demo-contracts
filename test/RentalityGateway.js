const { expect } = require('chai')
const { ethers } = require('hardhat')
const {
  time,
  loadFixture,
} = require('@nomicfoundation/hardhat-network-helpers')
const { Contract } = require('hardhat/internal/hardhat-network/stack-traces/model')
const {
  getMockCarRequest,
  TripStatus,
  getEmptySearchCarParams,
  createMockClaimRequest,
  deployDefaultFixture,
} = require('./utils')


describe('RentalityGateway', function() {

  let rentalityGateway,
    rentalityMockPriceFeed,
    rentalityUserService,
    rentalityTripService,
    rentalityCurrencyConverter,
    rentalityCarToken,
    rentalityPaymentService,
    rentalityPlatform,
    claimService,
    owner,
    admin,
    manager,
    host,
    guest,
    anonymous

  beforeEach(async function() {
    ({
      rentalityGateway,
      rentalityMockPriceFeed,
      rentalityUserService,
      rentalityTripService,
      rentalityCurrencyConverter,
      rentalityCarToken,
      rentalityPaymentService,
      rentalityPlatform,
      claimService,
      owner,
      admin,
      manager,
      host,
      guest,
      anonymous,
    } = await loadFixture(deployDefaultFixture))
  })

  it('should has right owner', async function() {

    expect(await rentalityGateway.owner()).to.equal(owner.address)
  })

  it('should allow only admin to update car service address', async function() {
    await expect(
      rentalityGateway.connect(guest).updateCarService(rentalityCarToken.address)).to.be.reverted

    await expect(
      rentalityGateway.connect(host).updateCarService(rentalityCarToken.address)).to.be.reverted

    await expect(
      rentalityGateway.connect(anonymous).updateCarService(rentalityCarToken.address)).to.be.reverted

    await expect(
      rentalityGateway.connect(admin)
        .updateCarService(rentalityCarToken.address)).not.be.reverted

  })
  it('should allow only admin to update rentality platform address', async function() {
    await expect(
      rentalityGateway.connect(guest).updateRentalityPlatform(rentalityPlatform.address)).to.be.reverted

    await expect(
      rentalityGateway.connect(host).updateRentalityPlatform(rentalityPlatform.address)).to.be.reverted

    await expect(
      rentalityGateway.connect(anonymous).updateRentalityPlatform(rentalityPlatform.address)).to.be.reverted

    await expect(
      rentalityGateway.connect(admin)
        .updateRentalityPlatform(rentalityPlatform.address)).not.be.reverted
  })

  it('should allow only admin to update currency converter service address', async function() {
    await expect(
      rentalityGateway.connect(guest).updateCurrencyConverterService(rentalityCurrencyConverter.address)).to.be.reverted

    await expect(
      rentalityGateway.connect(host).updateCurrencyConverterService(rentalityCurrencyConverter.address)).to.be.reverted

    await expect(
      rentalityGateway.connect(anonymous).updateCurrencyConverterService(rentalityCurrencyConverter.address)).to.be.reverted


    await expect(
      rentalityGateway.connect(admin)
        .updateCurrencyConverterService(rentalityCurrencyConverter.address)).not.be.reverted
  })

  it('should allow only admin to update trip service address', async function() {
    await expect(
      rentalityGateway.connect(admin)
        .updateTripService(rentalityTripService.address)).not.be.reverted

    await expect(
      rentalityGateway.connect(host)
        .updateTripService(rentalityTripService.address)).to.be.reverted

    await expect(
      rentalityGateway.connect(guest)
        .updateTripService(rentalityTripService.address)).to.be.reverted

    await expect(
      rentalityGateway.connect(anonymous)
        .updateTripService(rentalityTripService.address)).to.be.reverted
  })

  it('should allow only admin to update user service address', async function() {
    await expect(
      rentalityGateway.connect(anonymous)
        .updateUserService(rentalityUserService.address)).to.be.reverted

    await expect(
      rentalityGateway.connect(host)
        .updateUserService(rentalityUserService.address)).to.be.reverted

    await expect(
      rentalityGateway.connect(guest)
        .updateUserService(rentalityUserService.address)).to.be.reverted

    await expect(
      rentalityGateway.connect(admin)
        .updateUserService(rentalityUserService.address)).not.be.reverted

  })

  it('should allow only admin to set platform fee in PPM', async function() {
    await expect(
      rentalityGateway.connect(admin)
        .setPlatformFeeInPPM(10)).not.to.be.reverted

    await expect(
      rentalityGateway.connect(host).setPlatformFeeInPPM(10)).to.be.reverted

    await expect(
      rentalityGateway.connect(guest).setPlatformFeeInPPM(10)).to.be.reverted

    await expect(
      rentalityGateway.connect(anonymous).setPlatformFeeInPPM(10)).to.be.reverted

  })

  it('should update platform Fee in PMM', async function() {

    let platformFeeInPMM = 10101

    await expect(
      rentalityGateway.connect(owner)
        .setPlatformFeeInPPM(platformFeeInPMM)).not.to.be.reverted


    expect(await rentalityGateway.getPlatformFeeInPPM(),
    ).to.equal(platformFeeInPMM)

  })
  it('Host can add car to gateway', async function() {

    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0)))
      .not.to.be.reverted
    const myCars = await rentalityGateway
      .connect(host)
      .getMyCars()
    expect(myCars.length).to.equal(1)
  })
  it('Host dont see own cars as available', async function() {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0)))
      .not.to.be.reverted
    const myCars = await rentalityGateway
      .connect(host)
      .getMyCars()
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityGateway
      .connect(host)
      .getAvailableCarsForUser(host.address)
    expect(availableCars.length).to.equal(0)
  })
  it('Guest see cars as available', async function() {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0)))
      .not.to.be.reverted
    const myCars = await rentalityGateway
      .connect(host)
      .getMyCars()
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityGateway
      .connect(guest)
      .getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)
  })
  it('createTripRequest', async function() {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0)))
      .not.to.be.reverted
    const myCars = await rentalityGateway
      .connect(host)
      .getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway
      .connect(guest)
      .getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getEthFromUsdLatest(
        rentPriceInUsdCents,
      )

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
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth },
      ),
    ).not.to.be.reverted
  })

  it('Host can not create trip request for own car ', async function() {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0)))
      .not.to.be.reverted
    const myCars = await rentalityGateway
      .connect(host)
      .getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway
      .connect(guest)
      .getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getEthFromUsdLatest(
        rentPriceInUsdCents,
      )

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
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth },
      ),
    ).to.be.revertedWith('Car is not available for creator')

  })

  it('host can reject created trip', async function() {

    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0)))
      .not.to.be.reverted
    const myCars = await rentalityGateway
      .connect(host)
      .getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway
      .connect(guest)
      .getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getEthFromUsdLatest(
        rentPriceInUsdCents,
      )

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
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth },
      ),
    ).to.changeEtherBalances(
      [guest, rentalityPlatform],
      [-rentPriceInEth, rentPriceInEth],
    )

    await expect(
      rentalityGateway.connect(host).rejectTripRequest(1),
    ).to.changeEtherBalances(
      [guest, rentalityPlatform],
      [rentPriceInEth, -rentPriceInEth],
    )
  })

  it('guest can reject created trip', async function() {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0)))
      .not.to.be.reverted
    const myCars = await rentalityGateway
      .connect(host)
      .getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway
      .connect(guest)
      .getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getEthFromUsdLatest(
        rentPriceInUsdCents,
      )

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
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth },
      ),
    ).to.changeEtherBalances(
      [guest, rentalityPlatform],
      [-rentPriceInEth, rentPriceInEth],
    )

    await expect(
      rentalityGateway.connect(guest).rejectTripRequest(1),
    ).to.changeEtherBalances(
      [guest, rentalityPlatform],
      [rentPriceInEth, -rentPriceInEth],
    )
  })
  it('Only host or guest can reject trip', async function() {

    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0)))
      .not.to.be.reverted
    const myCars = await rentalityGateway
      .connect(host)
      .getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway
      .connect(guest)
      .getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getEthFromUsdLatest(
        rentPriceInUsdCents,
      )

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
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth },
      ),
    ).to.changeEtherBalances(
      [guest, rentalityPlatform],
      [-rentPriceInEth, rentPriceInEth],
    )

    await expect(
      rentalityGateway.connect(anonymous).rejectTripRequest(1),
    ).to.be.reverted

    await expect(
      rentalityGateway.connect(admin).rejectTripRequest(1),
    ).to.be.reverted

    await expect(
      rentalityGateway.connect(owner).rejectTripRequest(1),
    ).to.be.reverted

    let trip = await rentalityGateway.getTrip(1)

    expect(trip.status).to.be.equal(TripStatus.Created)

  })
  it('Only host can approve the trip', async function() {

    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0)))
      .not.to.be.reverted
    const myCars = await rentalityGateway
      .connect(host)
      .getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway
      .connect(guest)
      .getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getEthFromUsdLatest(
        rentPriceInUsdCents,
      )

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
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth },
      ),
    ).to.changeEtherBalances(
      [guest, rentalityPlatform],
      [-rentPriceInEth, rentPriceInEth],
    )

    await expect(
      rentalityGateway.connect(anonymous).approveTripRequest(1),
    ).to.be.reverted

    await expect(
      rentalityGateway.connect(guest).approveTripRequest(1),
    ).to.be.reverted


    await expect(
      rentalityGateway.connect(admin).approveTripRequest(1),
    ).to.be.reverted

    await expect(
      rentalityGateway.connect(owner).approveTripRequest(1),
    ).to.be.reverted

    let trip = await rentalityGateway.getTrip(1)

    expect(trip.status).to.be.equal(TripStatus.Created)


    await expect(
      rentalityGateway.connect(host).approveTripRequest(1),
    ).not.be.reverted

    let trip_approved = await rentalityGateway.getTrip(1)

    expect(trip_approved.status).to.be.equal(1)
  })
  it('Host can not cheng status before approve', async function() {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0)))
      .not.to.be.reverted
    const myCars = await rentalityGateway
      .connect(host)
      .getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway
      .connect(guest)
      .getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getEthFromUsdLatest(
        rentPriceInUsdCents,
      )

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
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth },
      ),
    ).to.changeEtherBalances(
      [guest, rentalityPlatform],
      [-rentPriceInEth, rentPriceInEth],
    )
    await expect(rentalityGateway.connect(host).checkInByHost(1, 0, 0))
      .to.be.reverted

    await expect(rentalityGateway.connect(host).checkOutByHost(1, 0, 0))
      .to.be.reverted

    await expect(
      rentalityPlatform.connect(host).finishTrip(1),
    ).to.be.reverted

    let trip = await rentalityGateway.getTrip(1)

    expect(trip.status).to.be.equal(TripStatus.Created)

  })

  it('Only host can checkin after approve', async function() {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0)))
      .not.to.be.reverted
    const myCars = await rentalityGateway
      .connect(host)
      .getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway
      .connect(guest)
      .getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getEthFromUsdLatest(
        rentPriceInUsdCents,
      )

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
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth },
      ),
    ).to.changeEtherBalances(
      [guest, rentalityPlatform],
      [-rentPriceInEth, rentPriceInEth],
    )
    expect(await rentalityGateway.connect(host).approveTripRequest(1))
      .not.be.reverted

    await expect(rentalityGateway.connect(guest).checkInByHost(1, [0, 0]))
      .to.be.reverted

    await expect(rentalityGateway.connect(anonymous).checkInByHost(1, [0, 0]))
      .to.be.reverted

    await expect(rentalityGateway.connect(admin).checkInByHost(1, [0, 0]))
      .to.be.reverted

    await expect(rentalityGateway.connect(owner).checkInByHost(1, [0, 0]))
      .to.be.reverted

    let trip = await rentalityGateway.getTrip(1)

    expect(trip.status).to.be.equal(TripStatus.Approved)


    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0]))
      .not.be.reverted

    let trip_checkin = await rentalityGateway.getTrip(1)

    expect(trip_checkin.status).to.be.equal(2)

  })

  it('Only guest can checkin after host', async function() {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0)))
      .not.to.be.reverted
    const myCars = await rentalityGateway
      .connect(host)
      .getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway
      .connect(guest)
      .getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getEthFromUsdLatest(
        rentPriceInUsdCents,
      )

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
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth },
      ),
    ).to.changeEtherBalances(
      [guest, rentalityPlatform],
      [-rentPriceInEth, rentPriceInEth],
    )
    expect(await rentalityGateway.connect(host).approveTripRequest(1))
      .not.be.reverted

    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0]))
      .not.be.reverted

    await expect(rentalityGateway.connect(anonymous).checkInByGuest(1, [0, 0]))
      .to.be.reverted

    await expect(rentalityGateway.connect(host).checkInByGuest(1, [0, 0]))
      .to.be.reverted

    await expect(rentalityGateway.connect(admin).checkInByGuest(1, [0, 0]))
      .to.be.reverted

    await expect(rentalityGateway.connect(owner).checkInByGuest(1, [0, 0]))
      .to.be.reverted

    let trip = await rentalityGateway.getTrip(1)

    expect(trip.status).to.be.equal(TripStatus.CheckedInByHost)


    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0]))
      .not.be.reverted

    let trip_checkin = await rentalityGateway.connect(guest).getTrip(1)

    expect(trip_checkin.status).to.be.equal(TripStatus.CheckedInByGuest)

  })
  it('Only guest can checkout after checkin', async function() {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0)))
      .not.to.be.reverted
    const myCars = await rentalityGateway
      .connect(host)
      .getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway
      .connect(guest)
      .getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getEthFromUsdLatest(
        rentPriceInUsdCents,
      )

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
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth },
      ),
    ).to.changeEtherBalances(
      [guest, rentalityPlatform],
      [-rentPriceInEth, rentPriceInEth],
    )
    expect(await rentalityGateway.connect(host).approveTripRequest(1))
      .not.be.reverted

    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0]))
      .not.be.reverted

    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0]))
      .not.be.reverted

    await expect(rentalityGateway.connect(anonymous).checkOutByGuest(1, [0, 0]))
      .to.be.reverted

    await expect(rentalityGateway.connect(host).checkOutByGuest(1, [0, 0]))
      .to.be.reverted

    await expect(rentalityGateway.connect(admin).checkOutByGuest(1, [0, 0]))
      .to.be.reverted

    await expect(rentalityGateway.connect(owner).checkOutByGuest(1, [0, 0]))
      .to.be.reverted

    let trip = await rentalityGateway.getTrip(1)

    expect(trip.status).to.be.equal(TripStatus.CheckedInByGuest)


    await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [0, 0]))
      .not.be.reverted

    let trip_checkout = await rentalityGateway.connect(guest).getTrip(1)

    expect(trip_checkout.status).to.be.equal(TripStatus.CheckedOutByGuest)

  })
  it('Only host can checkout after guest checkout', async function() {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0)))
      .not.to.be.reverted
    const myCars = await rentalityGateway
      .connect(host)
      .getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway
      .connect(guest)
      .getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getEthFromUsdLatest(
        rentPriceInUsdCents,
      )

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
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth },
      ),
    ).to.changeEtherBalances(
      [guest, rentalityPlatform],
      [-rentPriceInEth, rentPriceInEth],
    )
    expect(await rentalityGateway.connect(host).approveTripRequest(1))
      .not.be.reverted

    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0]))
      .not.be.reverted

    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0]))
      .not.be.reverted

    await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [0, 0]))
      .not.be.reverted

    await expect(rentalityGateway.connect(anonymous).checkOutByHost(1, [0, 0]))
      .to.be.reverted

    await expect(rentalityGateway.connect(guest).checkOutByHost(1, [0, 0]))
      .to.be.reverted

    await expect(rentalityGateway.connect(admin).checkOutByHost(1, [0, 0]))
      .to.be.reverted

    await expect(rentalityGateway.connect(owner).checkOutByHost(1, [0, 0]))
      .to.be.reverted

    let trip = await rentalityGateway.getTrip(1)

    expect(trip.status).to.be.equal(TripStatus.CheckedOutByGuest)


    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0]))
      .not.be.reverted

    let trip_checkout = await rentalityGateway.connect(guest).getTrip(1)

    expect(trip_checkout.status).to.be.equal(TripStatus.CheckedOutByHost)

  })

  it('Happy case', async function() {

    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0)))
      .not.to.be.reverted
    const myCars = await rentalityGateway
      .connect(host)
      .getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway
      .connect(guest)
      .getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getEthFromUsdLatest(
        rentPriceInUsdCents,
      )

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
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth },
      ),
    ).to.changeEtherBalances(
      [guest, rentalityPlatform],
      [-rentPriceInEth, rentPriceInEth],
    )

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to
      .be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0]))
      .not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0]))
      .not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [0, 0]))
      .not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0]))
      .not.to.be.reverted
    const returnToHost =
      rentPriceInEth -
      (rentPriceInEth *
        (await rentalityGateway.getPlatformFeeInPPM())) /
      1_000_000

    await expect(
      rentalityGateway.connect(host).finishTrip(1),
    ).to.changeEtherBalances(
      [host, rentalityPlatform],
      [returnToHost, -returnToHost],
    )
  })


  it('should allow only host to update car info', async function() {

    let addCarRequest = getMockCarRequest(0)
    await expect(rentalityGateway.connect(host).addCar(addCarRequest)).not.be.reverted

    let update_params = {
      carId: 1,
      pricePerDayInUsdCents: 2,
      securityDepositPerTripInUsdCents: 2,
      engineParams: [2],
      milesIncludedPerDay: 2,
      currentlyListed: false,
    }

    await expect(rentalityGateway.connect(host).updateCarInfo(update_params)).not.to.be.reverted

    await expect(rentalityGateway.connect(guest).updateCarInfo(update_params)).to.be.revertedWith('User is not a host')

    await expect(rentalityGateway.connect(anonymous).updateCarInfo(update_params)).to.be.revertedWith('User is not a host')

    let carInfo = await rentalityGateway.getCarInfoById(update_params.carId)

    expect(carInfo.currentlyListed).to.be.equal(false)
    expect(carInfo.pricePerDayInUsdCents).to.be.equal(update_params.pricePerDayInUsdCents)
    expect(carInfo.milesIncludedPerDay).to.be.equal(update_params.milesIncludedPerDay)
    expect(carInfo.fuelPricePerGalInUsdCents).to.be.equal(update_params.fuelPricePerGalInUsdCents)
    expect(carInfo.securityDepositPerTripInUsdCents).to.be.equal(update_params.securityDepositPerTripInUsdCents)

  })

  it('should allow only host to update car token URI', async function() {
    let addCarRequest = getMockCarRequest(0)
    await expect(rentalityGateway.connect(host).addCar(addCarRequest)).not.be.reverted

    await expect(rentalityGateway.connect(host).updateCarTokenUri(1, ' ')).not.to.be.reverted

    await expect(rentalityGateway.connect(guest).updateCarTokenUri(1, ' ')).to.be.revertedWith('User is not a host')

    await expect(rentalityGateway.connect(anonymous).updateCarTokenUri(1, ' ')).to.be.revertedWith('User is not a host')
  })


  it('should allow only host to burn car', async function() {

    let addCarRequest = getMockCarRequest(0)
    await expect(rentalityGateway.connect(host).addCar(addCarRequest)).not.be.reverted

    await expect(rentalityGateway.connect(host).burnCar(1)).not.to.be.reverted

    await expect(rentalityGateway.connect(guest).burnCar(1)).to.be.revertedWith('User is not a host')

    await expect(rentalityGateway.connect(anonymous).burnCar(1)).to.be.revertedWith('User is not a host')

  })

  it('should have available cars', async function() {
    let addCarRequest = getMockCarRequest(0)
    await expect(rentalityGateway.connect(host).addCar(addCarRequest)).not.be.reverted


    let available_cars = await rentalityGateway.connect(guest).getAvailableCars()

    expect(available_cars.length).to.be.equal(1)

  })

  it('should have cars owned by user', async function() {
    let addCarRequest = getMockCarRequest(0)
    await expect(rentalityCarToken.connect(host).addCar(addCarRequest)).not.be.reverted


    let available_cars = await rentalityGateway.connect(host).getMyCars()

    expect(available_cars.length).to.be.equal(1)


    let cars_not_created = await rentalityGateway.connect(guest).getMyCars()

    expect(cars_not_created.length).to.be.equal(0)

  })

  it('Should host be able to create KYC', async function() {

    let name = 'name'
    let surname = 'surname'
    let number = '+380'
    let photo = 'photo'
    let licenseNumber = 'licenseNumber'
    let expirationDate = 10

    await
      expect(
        rentalityGateway.connect(host).setKYCInfo(
          name,
          surname,
          number,
          photo,
          licenseNumber,
          expirationDate,
        )).not.be.reverted

    const kycInfo = await rentalityGateway
      .connect(host)
      .getMyKYCInfo()

    expect(kycInfo.name).to.equal(name)
    expect(kycInfo.surname).to.equal(surname)
    expect(kycInfo.mobilePhoneNumber).to.equal(number)
    expect(kycInfo.profilePhoto).to.equal(photo)
    expect(kycInfo.licenseNumber).to.equal(licenseNumber)
    expect(kycInfo.expirationDate).to.equal(expirationDate)


  })
  it('Should guest be able to create KYC', async function() {
    let name = 'name'
    let surname = 'surname'
    let number = '+380'
    let photo = 'photo'
    let licenseNumber = 'licenseNumber'
    let expirationDate = 10

    await
      expect(
        rentalityGateway.connect(guest).setKYCInfo(
          name,
          surname,
          number,
          photo,
          licenseNumber,
          expirationDate,
        )).not.be.reverted

    const kycInfo = await rentalityGateway
      .connect(guest)
      .getMyKYCInfo()

    expect(kycInfo.name).to.equal(name)
    expect(kycInfo.surname).to.equal(surname)
    expect(kycInfo.mobilePhoneNumber).to.equal(number)
    expect(kycInfo.profilePhoto).to.equal(photo)
    expect(kycInfo.licenseNumber).to.equal(licenseNumber)
    expect(kycInfo.expirationDate).to.equal(expirationDate)
  })

  it('Should not anonymous be able to create KYC', async function() {


    let name = 'name'
    let surname = 'surname'
    let number = '+380'
    let photo = 'photo'
    let licenseNumber = 'licenseNumber'
    let expirationDate = 10

    await
      expect(
        rentalityUserService.connect(anonymous).setKYCInfo(
          name,
          surname,
          number,
          photo,
          licenseNumber,
          expirationDate,
        )).to.be.reverted


  })

  it('Guest should be able to get trip contacts', async function() {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0)))
      .not.to.be.reverted
    const myCars = await rentalityGateway
      .connect(host)
      .getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway
      .connect(guest)
      .getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getEthFromUsdLatest(
        rentPriceInUsdCents,
      )

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
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth },
      ),
    ).not.to.be.reverted

    let guestNumber = '+380'
    let hostNumber = '+3801'
    await expect(rentalityUserService.connect(guest).setKYCInfo(
      'name',
      'surname',
      guestNumber,
      'photo',
      'number',
      1,
    ))
      .not.be.reverted

    await expect(rentalityUserService.connect(host).setKYCInfo(
      'name',
      'surname',
      hostNumber,
      'photo',
      'number',
      1,
    ))
      .not.be.reverted

    let [guestPhoneNumber, hostPhoneNumber] = await rentalityGateway.connect(guest).getTripContactInfo(1)

    expect(guestPhoneNumber).to.be.equal(guestNumber)
    expect(hostPhoneNumber).to.be.equal(hostNumber)
  })

  it('Host should be able to get trip contacts', async function() {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0)))
      .not.to.be.reverted
    const myCars = await rentalityGateway
      .connect(host)
      .getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway
      .connect(guest)
      .getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getEthFromUsdLatest(
        rentPriceInUsdCents,
      )

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
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth },
      ),
    ).not.to.be.reverted

    let guestNumber = '+380'
    let hostNumber = '+3801'
    await expect(rentalityGateway.connect(guest).setKYCInfo(
      'name',
      'surname',
      guestNumber,
      'photo',
      'number',
      1,
    ))
      .not.be.reverted

    await expect(rentalityGateway.connect(host).setKYCInfo(
      'name',
      'surname',
      hostNumber,
      'photo',
      'number',
      1,
    ))
      .not.be.reverted

    let [guestPhoneNumber, hostPhoneNumber] = await rentalityGateway.connect(host).getTripContactInfo(1)

    expect(guestPhoneNumber).to.be.equal(guestNumber)
    expect(hostPhoneNumber).to.be.equal(hostNumber)
  })

  it('Only host and guest should be able to get trip contacts', async function() {
    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0)))
      .not.to.be.reverted
    const myCars = await rentalityGateway
      .connect(host)
      .getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway
      .connect(guest)
      .getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getEthFromUsdLatest(
        rentPriceInUsdCents,
      )

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
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth },
      ),
    ).not.to.be.reverted

    let guestNumber = '+380'
    let hostNumber = '+3801'
    await expect(rentalityGateway.connect(guest).setKYCInfo(
      'name',
      'surname',
      guestNumber,
      'photo',
      'number',
      1,
    ))
      .not.be.reverted

    await expect(rentalityGateway.connect(host).setKYCInfo(
      'name',
      'surname',
      hostNumber,
      'photo',
      'number',
      1,
    ))
      .not.be.reverted

    await expect(rentalityGateway.connect(anonymous).getTripContactInfo(1)).to.be.reverted


  })


  it('Should have chat history by guest', async function() {

    let addCarRequest = getMockCarRequest(0)

    await expect(rentalityGateway.connect(host).addCar(addCarRequest))
      .not.to.be.reverted
    const myCars = await rentalityGateway
      .connect(host)
      .getMyCars()

    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityGateway
      .connect(guest)
      .getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getEthFromUsdLatest(
        rentPriceInUsdCents,
      )

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
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
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth },
      ),
    ).not.to.be.reverted

    let name = 'name'
    let surname = 'surname'
    let number = '+380'
    let photo = 'photo'
    let licenseNumber = 'licenseNumber'
    let expirationDate = 10

    await
      expect(
        rentalityGateway.connect(host).setKYCInfo(
          name + 'host',
          surname + 'host',
          number + 'host',
          photo + 'host',
          licenseNumber + 'host',
          expirationDate,
        )).not.be.reverted

    await
      expect(
        rentalityGateway.connect(guest).setKYCInfo(
          name + 'guest',
          surname + 'guest',
          number + 'guest',
          photo + 'guest',
          licenseNumber + 'guest',
          expirationDate,
        )).not.be.reverted


    let chatInfoArray = await rentalityGateway.connect(guest).getChatInfoForGuest()
    expect(chatInfoArray.length).to.be.equal(1)
    let chatInfo = chatInfoArray[0]

    expect(chatInfo.tripId).to.be.equal(1)
    expect(chatInfo.guestAddress).to.be.equal(guest.address)
    expect(chatInfo.guestPhotoUrl).to.be.equal(photo + 'guest')
    expect(chatInfo.hostAddress).to.be.equal(host.address)
    expect(chatInfo.tripStatus).to.be.equal(0)
    expect(chatInfo.carBrand).to.be.equal(addCarRequest.brand)
    expect(chatInfo.carModel).to.be.equal(addCarRequest.model)
    expect(chatInfo.carYearOfProduction).to.be.equal(Number(addCarRequest.yearOfProduction))

  })
  it('Should have chat history by host', async function() {

    let addCarRequest = getMockCarRequest(0)
    await expect(rentalityGateway.connect(host).addCar(addCarRequest))
      .not.to.be.reverted
    const myCars = await rentalityGateway
      .connect(host)
      .getMyCars()
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityGateway
      .connect(guest)
      .getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getEthFromUsdLatest(
        rentPriceInUsdCents,
      )
    let name = 'name'
    let surname = 'surname'
    let number = '+380'
    let photo = 'photo'
    let licenseNumber = 'licenseNumber'
    let expirationDate = 10

    await
      expect(
        rentalityGateway.connect(host).setKYCInfo(
          name + 'host',
          surname + 'host',
          number + 'host',
          photo + 'host',
          licenseNumber + 'host',
          expirationDate,
        )).not.be.reverted

    await
      expect(
        rentalityGateway.connect(guest).setKYCInfo(
          name + 'guest',
          surname + 'guest',
          number + 'guest',
          photo + 'guest',
          licenseNumber + 'guest',
          expirationDate,
        )).not.be.reverted

    await expect(
      rentalityGateway.connect(guest).createTripRequest(
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
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth },
      ),
    ).not.to.be.reverted

    let chatInfoArray = await rentalityGateway.connect(host).getChatInfoForHost()
    expect(chatInfoArray.length).to.be.equal(1)
    let chatInfo = chatInfoArray[0]

    expect(chatInfo.tripId).to.be.equal(1)
    expect(chatInfo.guestAddress).to.be.equal(guest.address)
    expect(chatInfo.guestPhotoUrl).to.be.equal(photo + 'guest')
    expect(chatInfo.hostAddress).to.be.equal(host.address)
    expect(chatInfo.tripStatus).to.be.equal(0)
    expect(chatInfo.carBrand).to.be.equal(addCarRequest.brand)
    expect(chatInfo.carModel).to.be.equal(addCarRequest.model)
    expect(chatInfo.carYearOfProduction).to.be.equal(Number(addCarRequest.yearOfProduction))
  })
  it('Should have host photoUrl and host name in available car response ', async function() {

    let addCarRequest = getMockCarRequest(0)
    await expect(rentalityGateway.connect(host).addCar(addCarRequest))
      .not.to.be.reverted
    const myCars = await rentalityGateway
      .connect(host)
      .getMyCars()
    expect(myCars.length).to.equal(1)

    let name = 'name'
    let surname = 'surname'
    let number = '+380'
    let photo = 'photo'
    let licenseNumber = 'licenseNumber'
    let expirationDate = 10

    await
      expect(
        rentalityGateway.connect(host).setKYCInfo(
          name + 'host',
          surname + 'host',
          number + 'host',
          photo + 'host',
          licenseNumber + 'host',
          expirationDate,
        )).not.be.reverted


    const availableCars = await rentalityGateway
      .connect(guest)
      .searchAvailableCarsForUser(
        guest.address,
        0,
        0,
        getEmptySearchCarParams(0),
      )
    expect(availableCars.length).to.equal(1)

    expect(availableCars[0].hostPhotoUrl).to.be.eq(photo + 'host')
    expect(availableCars[0].hostName).to.be.eq(name + 'host')

  })

  it('Should not be able to create trip request after approve on the same time', async function() {

    let addCarRequest = getMockCarRequest(0)
    await expect(rentalityGateway.connect(host).addCar(addCarRequest))
      .not.to.be.reverted
    const myCars = await rentalityGateway
      .connect(host)
      .getMyCars()
    expect(myCars.length).to.equal(1)

    const oneDayInMilliseconds = 24 * 60 * 60 * 1000

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getEthFromUsdLatest(
        rentPriceInUsdCents,
      )

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
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth },
      ),
    ).not.to.be.reverted

    await expect(rentalityGateway.connect(host).approveTripRequest(1))
      .not.to.be.reverted

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
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth },
      ),
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
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth },
      ),
    ).not.to.be.reverted


  })
  it('Connot checkInBy host while car on the trip', async function() {

    await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0)))
      .not.to.be.reverted
    const myCars = await rentalityGateway
      .connect(host)
      .getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityGateway
      .connect(guest)
      .getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const rentPriceInUsdCents = 1000
    const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
      await rentalityCurrencyConverter.getEthFromUsdLatest(
        rentPriceInUsdCents,
      )
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
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth },
      ),
    ).to.changeEtherBalances(
      [guest, rentalityPlatform],
      [-rentPriceInEth, rentPriceInEth],
    )

    await expect(
      rentalityGateway.connect(host).approveTripRequest(1),
    ).to.not.reverted

    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0]))
      .to.not.reverted

    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0]))
      .to.not.reverted


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
          fuelPrices: [400],
          ethToCurrencyRate: ethToCurrencyRate,
          ethToCurrencyDecimals: ethToCurrencyDecimals,
        },
        { value: rentPriceInEth },
      ),
    ).to.changeEtherBalances(
      [guest, rentalityPlatform],
      [-rentPriceInEth, rentPriceInEth],
    )


    await expect(
      rentalityGateway.connect(host).approveTripRequest(2),
    ).not.be.reverted

    await expect(rentalityGateway.connect(host).checkInByHost(2, [0, 0]))
      .to.be.revertedWith('Car on the trip.')


  })


})
