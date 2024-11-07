const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const {
  deployDefaultFixture,
  getMockCarRequest,
  createMockClaimRequest,
  ethToken,
  calculatePayments,
} = require('../utils')
const { expect } = require('chai')
const { ethers } = require('hardhat')
describe('RentalityClaim', function () {
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
      claimService,
      owner,
      admin,
      manager,
      host,
      guest,
      anonymous,
      rentalityLocationVerifier,
      rentalityView,
    } = await loadFixture(deployDefaultFixture))
  })

  it('Host can not create claim before approve', async function () {
    await expect(
      rentalityPlatform.connect(host).addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).not.to.be.reverted
    const myCars = await rentalityView.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityView.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const oneDayInSeconds = 86400

    const result = await rentalityView.calculatePayments(1, 1, ethToken)
    await expect(
      await rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          currencyType: ethToken,
        },
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    const amountToClaimInUsdCents = 10000
    let mockClaimRequest = createMockClaimRequest(1, amountToClaimInUsdCents)
    await expect(rentalityPlatform.connect(host).createClaim(mockClaimRequest)).to.be.revertedWith('Wrong trip status.')
  })
  it('Only host can create claim ', async function () {
    await expect(
      rentalityPlatform.connect(host).addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).not.to.be.reverted
    const myCars = await rentalityView.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityView.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const oneDayInSeconds = 86400

    const result = await rentalityView.calculatePayments(1, 1, ethToken)
    await expect(
      await rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          currencyType: ethToken,
        },
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    await expect(rentalityPlatform.connect(host).approveTripRequest(1)).not.to.be.reverted

    const amountToClaimInUsdCents = 10000
    let mockClaimRequest = createMockClaimRequest(1, amountToClaimInUsdCents)
    await expect(rentalityPlatform.connect(guest).createClaim(mockClaimRequest)).to.be.revertedWith(
      'Only for trip host or guest, or wrong claim type.'
    )

    await expect(rentalityGateway.connect(admin).createClaim(mockClaimRequest)).to.be.revertedWith(
      'Only for trip host or guest, or wrong claim type.'
    )

    await expect(rentalityGateway.connect(anonymous).createClaim(mockClaimRequest)).to.be.revertedWith(
      'Only for trip host or guest, or wrong claim type.'
    )

    await expect(rentalityPlatform.connect(host).createClaim(mockClaimRequest)).to.not.reverted
  })

  it('Only host and guest can reject claim', async function () {
    await expect(
      rentalityPlatform.connect(host).addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).not.to.be.reverted
    const myCars = await rentalityView.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityView.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const oneDayInSeconds = 86400

    const result = await rentalityView.calculatePayments(1, 1, ethToken)
    await expect(
      await rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          currencyType: ethToken,
        },
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])
    await expect(rentalityPlatform.connect(host).approveTripRequest(1)).not.to.be.reverted

    const amountToClaimInUsdCents = 10000
    let mockClaimRequest = createMockClaimRequest(1, amountToClaimInUsdCents)

    await expect(rentalityPlatform.connect(host).createClaim(mockClaimRequest)).to.not.reverted
    await expect(rentalityPlatform.connect(anonymous).rejectClaim(1)).to.be.revertedWith('Only for trip guest or host.')

    await expect(rentalityPlatform.connect(host).rejectClaim(1)).to.not.reverted

    await expect(rentalityPlatform.connect(host).createClaim(mockClaimRequest)).to.not.reverted

    await expect(rentalityPlatform.connect(guest).rejectClaim(2)).to.not.reverted
  })
  it('has correct claim Info', async function () {
    const createCarRequest = getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityPlatform.connect(host).addCar(createCarRequest)).not.to.be.reverted
    const myCars = await rentalityView.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityView.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const oneDayInSeconds = 86400

    const dailyPriceInUsdCents = 1000

    const result = await rentalityView.calculatePayments(1, 1, ethToken)
    await expect(
      await rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          currencyType: ethToken,
        },
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])
    await expect(rentalityPlatform.connect(host).approveTripRequest(1)).not.to.be.reverted

    const amountToClaimInUsdCents = 10000
    let mockClaimRequest = createMockClaimRequest(1, amountToClaimInUsdCents)

    await expect(rentalityPlatform.connect(host).createClaim(mockClaimRequest)).to.not.reverted

    const claimInfo = (await rentalityView.connect(host).getMyClaimsAsHost())[0]

    expect(claimInfo.carInfo.model).to.be.eq(createCarRequest.model)
    expect(claimInfo.carInfo.brand).to.be.eq(createCarRequest.brand)
    expect(claimInfo.carInfo.yearOfProduction.toString()).to.be.eq(createCarRequest.yearOfProduction)
    expect(claimInfo.claim.tripId).to.be.eq(1)
    expect(claimInfo.claim.amountInUsdCents).to.be.eq(amountToClaimInUsdCents)
    const currentTimeInSeconds = Math.floor(Date.now() / 1000)
    const deadline = currentTimeInSeconds + 259200

    expect(claimInfo.claim.deadlineDateInSec).to.be.approximately(deadline, 2400)
  })
  it('Get all trip claims', async function () {
    const createCarRequest = getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityPlatform.connect(host).addCar(createCarRequest)).not.to.be.reverted
    const myCars = await rentalityView.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityView.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const oneDayInSeconds = 86400

    const dailyPriceInUsdCents = 1000

    const result = await rentalityView.calculatePayments(1, 1, ethToken)

    await expect(
      await rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          currencyType: ethToken,
        },
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])
    await expect(rentalityPlatform.connect(host).approveTripRequest(1)).not.to.be.reverted

    const amountToClaimInUsdCents = 10000
    let mockClaimRequest = createMockClaimRequest(1, amountToClaimInUsdCents)

    await expect(rentalityPlatform.connect(host).createClaim(mockClaimRequest)).to.not.reverted
    await expect(rentalityPlatform.connect(host).createClaim(mockClaimRequest)).to.not.reverted
    await expect(rentalityPlatform.connect(host).createClaim(mockClaimRequest)).to.not.reverted

    const claimInfos = await rentalityView.connect(host).getMyClaimsAsHost()

    expect(claimInfos.length).to.be.eq(3)
    expect(claimInfos[0].claim.claimId).to.be.eq(1)
    expect(claimInfos[1].claim.claimId).to.be.eq(2)
    expect(claimInfos[2].claim.claimId).to.be.eq(3)
  })

  it('Refund test', async function () {
    const createCarRequest = getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityPlatform.connect(host).addCar(createCarRequest)).not.to.be.reverted
    const myCars = await rentalityView.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityView.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const oneDayInSeconds = 86400

    const dailyPriceInUsdCents = 1000

    const result = await rentalityView.calculatePayments(1, 1, ethToken)
    await expect(
      await rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          currencyType: ethToken,
        },
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    await expect(rentalityPlatform.connect(host).approveTripRequest(1)).not.to.be.reverted

    const amountToClaimInUsdCents = 362120

    let mockClaimRequest = createMockClaimRequest(1, amountToClaimInUsdCents)

    await expect(rentalityPlatform.connect(host).createClaim(mockClaimRequest)).to.not.reverted

    const [claimPriceInEth] = await rentalityCurrencyConverter.getFromUsdLatest(ethToken, amountToClaimInUsdCents)

    const claimInEth = ethers.parseEther(claimPriceInEth.toString())
    const total = claimInEth / BigInt(1e18)
    let value = await rentalityGateway.calculateClaimValue(1)

    await expect(rentalityPlatform.connect(guest).payClaim(1, { value })).to.changeEtherBalances(
      [guest, host],
      [BigInt(-value), claimPriceInEth]
    )
  })
  it('Should return all my claims ', async function () {
    const claimsCreate = 4
    let counter = 0
    for (i = 1; i <= claimsCreate; i++) {
      counter++
      const createCarRequest = getMockCarRequest(i, await rentalityLocationVerifier.getAddress(), admin)
      await expect(rentalityPlatform.connect(host).addCar(createCarRequest)).not.to.be.reverted
      const myCars = await rentalityView.connect(host).getMyCars()
      expect(myCars.length).to.equal(i)

      const oneDayInSeconds = 86400
      const { rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals, rentalityFee } = await calculatePayments(
        rentalityCurrencyConverter,
        rentalityPaymentService,
        createCarRequest.pricePerDayInUsdCents,
        1,
        createCarRequest.securityDepositPerTripInUsdCents
      )
      await expect(
        await rentalityPlatform.connect(guest).createTripRequest(
          {
            carId: i,
            startDateTime: Date.now() + oneDayInSeconds * i,
            endDateTime: Date.now() + (oneDayInSeconds * i + 1),
            currencyType: ethToken,
          },
          { value: rentPriceInEth }
        )
      ).to.changeEtherBalances([guest, rentalityPaymentService], [-rentPriceInEth, rentPriceInEth])

      await expect(rentalityPlatform.connect(host).approveTripRequest(i)).not.to.be.reverted

      const amountToClaimInUsdCents = 10000
      let mockClaimRequest = createMockClaimRequest(i, amountToClaimInUsdCents)

      await expect(rentalityPlatform.connect(host).createClaim(mockClaimRequest)).to.not.reverted
    }
    // Owner should not have claims
    const ownerClaims = await rentalityGateway.getMyClaimsAsHost()
    const ownerClaims2 = await rentalityGateway.getMyClaimsAsGuest()

    expect(ownerClaims.length).to.be.eq(0)
    expect(ownerClaims2.length).to.be.eq(0)

    const hostClaims = await rentalityView.connect(host).getMyClaimsAsHost()

    expect(hostClaims.length).to.be.eq(claimsCreate)

    const guestClaims = await rentalityView.connect(guest).getMyClaimsAsGuest()

    expect(guestClaims.length).to.be.eq(claimsCreate)
  })
  it('Only host and guest can reject claim', async function () {
    await expect(
      rentalityPlatform.connect(host).addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin))
    ).not.to.be.reverted
    const myCars = await rentalityView.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityView.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    const oneDayInSeconds = 86400

    const result = await rentalityView.calculatePayments(1, 1, ethToken)
    await expect(
      await rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + oneDayInSeconds,
          currencyType: ethToken,
        },
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])
    await expect(rentalityPlatform.connect(host).approveTripRequest(1)).not.to.be.reverted

    const amountToClaimInUsdCents = 10000
    let mockClaimRequest = createMockClaimRequest(1, amountToClaimInUsdCents)

    await expect(rentalityPlatform.connect(host).createClaim(mockClaimRequest)).to.not.reverted
    await expect(rentalityPlatform.connect(anonymous).rejectClaim(1)).to.be.revertedWith('Only for trip guest or host.')

    await expect(rentalityPlatform.connect(host).rejectClaim(1)).to.not.reverted

    await expect(rentalityPlatform.connect(host).createClaim(mockClaimRequest)).to.not.reverted

    await expect(rentalityPlatform.connect(guest).rejectClaim(2)).to.not.reverted
  })
  it('Host not able to create claim with guest status', async function () {
    const request = getMockCarRequest(51, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityPlatform.connect(host).addCar(request)).not.to.be.reverted
    const myCars = await rentalityView.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityView.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    let sumToPayInUsdCents = request.pricePerDayInUsdCents
    let dayInTrip = 7
    let sumToPayWithDiscount = sumToPayInUsdCents * dayInTrip - (sumToPayInUsdCents * dayInTrip * 10) / 100

    let totalTaxes = (sumToPayWithDiscount * 7) / 100 + dayInTrip * 200

    let sevenDays = 86400 * 7

    const payments = await rentalityView.calculatePayments(1, 7, ethToken)
    await expect(
      await rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + sevenDays,
          currencyType: ethToken,
        },
        { value: payments.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-payments.totalPrice, payments.totalPrice])
    await expect(rentalityPlatform.connect(host).approveTripRequest(1)).not.to.be.reverted
    let claim = {
      tripId: 1,
      claimType: 9,
      description: 'Some des',
      amountInUsdCents: 10,
      photosUrl: '',
    }
    let claim2 = {
      tripId: 1,
      claimType: 8,
      description: 'Some des',
      amountInUsdCents: 10,
      photosUrl: '',
    }
    let claim3 = {
      tripId: 1,
      claimType: 2,
      description: 'Some des',
      amountInUsdCents: 10,
      photosUrl: '',
    }
    await expect(rentalityPlatform.connect(host).createClaim(claim)).to.be.reverted
    await expect(rentalityPlatform.connect(host).createClaim(claim2)).to.be.reverted
    await expect(rentalityPlatform.connect(host).createClaim(claim3)).to.not.be.reverted
  })
  it('Guest can not create claim with host type', async function () {
    const request = getMockCarRequest(51, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityPlatform.connect(host).addCar(request)).not.to.be.reverted
    const myCars = await rentalityView.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityView.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    let sumToPayInUsdCents = request.pricePerDayInUsdCents
    let dayInTrip = 7
    let sumToPayWithDiscount = sumToPayInUsdCents * dayInTrip - (sumToPayInUsdCents * dayInTrip * 10) / 100

    let totalTaxes = (sumToPayWithDiscount * 7) / 100 + dayInTrip * 200

    let sevenDays = 86400 * 7

    const payments = await rentalityView.calculatePayments(1, 7, ethToken)
    await expect(
      await rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + sevenDays,
          currencyType: ethToken,
        },
        { value: payments.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-payments.totalPrice, payments.totalPrice])
    await expect(rentalityPlatform.connect(host).approveTripRequest(1)).not.to.be.reverted
    let claim = {
      tripId: 1,
      claimType: 0,
      description: 'Some des',
      amountInUsdCents: 10,
      photosUrl: '',
    }
    let claim2 = {
      tripId: 1,
      claimType: 1,
      description: 'Some des',
      amountInUsdCents: 10,
      photosUrl: '',
    }
    let claim3 = {
      tripId: 1,
      claimType: 5,
      description: 'Some des',
      amountInUsdCents: 10,
      photosUrl: '',
    }
    await expect(rentalityPlatform.connect(guest).createClaim(claim)).to.be.reverted
    await expect(rentalityPlatform.connect(guest).createClaim(claim2)).to.be.reverted
    await expect(rentalityPlatform.connect(guest).createClaim(claim3)).to.not.be.reverted
  })
  it('Host can pay claim', async function () {
    const request = getMockCarRequest(51, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityPlatform.connect(host).addCar(request)).not.to.be.reverted
    const myCars = await rentalityView.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const availableCars = await rentalityView.connect(guest).getAvailableCarsForUser(guest.address)
    expect(availableCars.length).to.equal(1)

    let sumToPayInUsdCents = request.pricePerDayInUsdCents
    let dayInTrip = 7
    let sumToPayWithDiscount = sumToPayInUsdCents * dayInTrip - (sumToPayInUsdCents * dayInTrip * 10) / 100

    let totalTaxes = (sumToPayWithDiscount * 7) / 100 + dayInTrip * 200

    let sevenDays = 86400 * 7

    const payments = await rentalityView.calculatePayments(1, 7, ethToken)
    await expect(
      await rentalityPlatform.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: Date.now(),
          endDateTime: Date.now() + sevenDays,
          currencyType: ethToken,
        },
        { value: payments.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-payments.totalPrice, payments.totalPrice])
    await expect(rentalityPlatform.connect(host).approveTripRequest(1)).not.to.be.reverted
    let claim = {
      tripId: 1,
      claimType: 0,
      description: 'Some des',
      amountInUsdCents: 10,
      photosUrl: '',
    }
    let claim2 = {
      tripId: 1,
      claimType: 1,
      description: 'Some des',
      amountInUsdCents: 10,
      photosUrl: '',
    }
    let claim3 = {
      tripId: 1,
      claimType: 5,
      description: 'Some des',
      amountInUsdCents: 10,
      photosUrl: '',
    }
    await expect(rentalityPlatform.connect(guest).createClaim(claim)).to.be.reverted
    await expect(rentalityPlatform.connect(guest).createClaim(claim2)).to.be.reverted
    await expect(rentalityPlatform.connect(guest).createClaim(claim3)).to.not.be.reverted

    let value = await rentalityView.calculateClaimValue(1)

    await expect(rentalityPlatform.connect(host).payClaim(1, { value })).to.not.reverted
  })
})
