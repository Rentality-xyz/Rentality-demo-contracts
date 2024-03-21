const { expect } = require('chai')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')

const { getMockCarRequest, deployDefaultFixture, ethToken, calculatePayments } = require('../utils')

describe('RentalityGateway: chat', function () {
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

  it('Should have chat history by guest', async function () {
    let addCarRequest = getMockCarRequest(0)

    await expect(rentalityGateway.connect(host).addCar(addCarRequest)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()

    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
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
      await rentalityPlatform.connect(guest).createTripRequest(
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
        },
        { value: rentPriceInEth }
      )
    ).to.changeEtherBalances([guest, rentalityPlatform], [-rentPriceInEth, rentPriceInEth])

    let name = 'name'
    let surname = 'surname'
    let number = '+380'
    let photo = 'photo'
    let licenseNumber = 'licenseNumber'
    let expirationDate = 10

    await expect(
      rentalityGateway
        .connect(host)
        .setKYCInfo(
          name + 'host',
          surname + 'host',
          number + 'host',
          photo + 'host',
          licenseNumber + 'host',
          expirationDate,
          true
        )
    ).not.be.reverted

    await expect(
      rentalityGateway
        .connect(guest)
        .setKYCInfo(
          name + 'guest',
          surname + 'guest',
          number + 'guest',
          photo + 'guest',
          licenseNumber + 'guest',
          expirationDate,
          true
        )
    ).not.be.reverted

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
  it('Should have chat history by host', async function () {
    let addCarRequest = getMockCarRequest(0)
    await expect(rentalityGateway.connect(host).addCar(addCarRequest)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityGateway.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    let name = 'name'
    let surname = 'surname'
    let number = '+380'
    let photo = 'photo'
    let licenseNumber = 'licenseNumber'
    let expirationDate = 10

    await expect(
      rentalityGateway
        .connect(host)
        .setKYCInfo(
          name + 'host',
          surname + 'host',
          number + 'host',
          photo + 'host',
          licenseNumber + 'host',
          expirationDate,
          true
        )
    ).not.be.reverted

    await expect(
      rentalityGateway
        .connect(guest)
        .setKYCInfo(
          name + 'guest',
          surname + 'guest',
          number + 'guest',
          photo + 'guest',
          licenseNumber + 'guest',
          expirationDate,
          true
        )
    ).not.be.reverted

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
      await rentalityPlatform.connect(guest).createTripRequest(
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
        },
        { value: rentPriceInEth }
      )
    ).to.changeEtherBalances([guest, rentalityPlatform], [-rentPriceInEth, rentPriceInEth])

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
})
