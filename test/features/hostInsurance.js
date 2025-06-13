const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const {
  deployDefaultFixture,
  getMockCarRequest,
  createMockClaimRequest,
  ethToken,
  calculatePayments,
  zeroHash,
  emptyLocationInfo,
  getEmptySearchCarParams,
  emptySignedLocationInfo,
} = require('../utils')
const { expect } = require('chai')
const { ethers } = require('hardhat')
describe.only('HostInsurance', function () {
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
    rentalityAdminGateway,
    hostInsurance

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
      rentalityAdminGateway,
      hostInsurance
    } = await loadFixture(deployDefaultFixture))
  })

  it('With no rule, host do not pay insurance', async function () {


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
        emptyLocationInfo,0,10
      )
    expect(availableCars.cars.length).to.equal(1)

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

    const depositValue = await rentalityCurrencyConverter.getFromUsdCents(
      ethToken,
      request.securityDepositPerTripInUsdCents,
      ethToCurrencyRate
    )

    const returnToHost = rentPriceInEth - depositValue - rentalityFee - taxes

    await expect(rentalityGateway.connect(host).finishTrip(1)).to.changeEtherBalances(
      [host, rentalityPaymentService],
      [returnToHost, -(rentPriceInEth - rentalityFee - taxes)]
    )

  })
  it('Host can set rule and pay for insurance', async function () {

    await expect(rentalityGateway.connect(host).setHostInsurance(1)).to.not.reverted

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
        emptyLocationInfo,0,10
      )
    expect(availableCars.cars.length).to.equal(1)

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

    const depositValue = await rentalityCurrencyConverter.getFromUsdCents(
      ethToken,
      request.securityDepositPerTripInUsdCents,
      ethToCurrencyRate
    )

    const returnToHost = rentPriceInEth - depositValue - rentalityFee - taxes
    const insurancePayment =  (returnToHost * BigInt(40) / BigInt(100));
    await expect(rentalityGateway.connect(host).finishTrip(1)).to.changeEtherBalances(
      [host, rentalityPaymentService, hostInsurance],
      [returnToHost - (insurancePayment), -(rentPriceInEth - rentalityFee - taxes), insurancePayment]
    )

  })

  it('Host can remove rule', async function () {

    await expect(rentalityGateway.connect(host).setHostInsurance(1)).to.not.reverted

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
        emptyLocationInfo,0,10
      )
    expect(availableCars.cars.length).to.equal(1)

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

    const depositValue = await rentalityCurrencyConverter.getFromUsdCents(
      ethToken,
      request.securityDepositPerTripInUsdCents,
      ethToCurrencyRate
    )


    const returnToHost = rentPriceInEth - depositValue - rentalityFee - taxes
    const insurancePayment  = returnToHost * BigInt(40) / BigInt(100);
    await expect(rentalityGateway.connect(host).finishTrip(1)).to.changeEtherBalances(
      [host, rentalityPaymentService, hostInsurance],
      [returnToHost - (insurancePayment), -(rentPriceInEth - rentalityFee - taxes), insurancePayment]
    )
    await expect(rentalityGateway.connect(host).setHostInsurance(0)).to.not.reverted


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
  
      await expect(rentalityGateway.connect(host).approveTripRequest(2)).not.to.be.reverted
      await expect(rentalityGateway.connect(host).checkInByHost(2, [0, 0], '', '')).not.to.be.reverted
      await expect(rentalityGateway.connect(guest).checkInByGuest(2, [0, 0])).not.to.be.reverted
      await expect(rentalityGateway.connect(guest).checkOutByGuest(2, [0, 0])).not.to.be.reverted
      await expect(rentalityGateway.connect(host).checkOutByHost(2, [0, 0])).not.to.be.reverted
  
     
      const returnToHost2 = rentPriceInEth - depositValue - rentalityFee - taxes
      await expect(rentalityGateway.connect(host).finishTrip(2)).to.changeEtherBalances(
        [host, rentalityPaymentService],
        [returnToHost2, -(rentPriceInEth - rentalityFee - taxes)]
      )

  })

  it('Host can be paid from claim by insurance service', async function () {

    await expect(rentalityGateway.connect(host).setHostInsurance(1)).to.not.reverted

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
        emptyLocationInfo,0,10
      )
    expect(availableCars.cars.length).to.equal(1)

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

    const depositValue = await rentalityCurrencyConverter.getFromUsdCents(
      ethToken,
      request.securityDepositPerTripInUsdCents,
      ethToCurrencyRate
    )


    const returnToHost = rentPriceInEth - depositValue - rentalityFee - taxes
    const insurancePayment  = returnToHost * BigInt(40) / BigInt(100);
    await expect(rentalityGateway.connect(host).finishTrip(1)).to.changeEtherBalances(
      [host, rentalityPaymentService, hostInsurance],
      [returnToHost - (insurancePayment), -(rentPriceInEth - rentalityFee - taxes), insurancePayment]
    )

    const amountToClaimInUsdCents = 362120

    let mockClaimRequest = createMockClaimRequest(1, amountToClaimInUsdCents)

    await expect(rentalityGateway.connect(host).createClaim(mockClaimRequest, true)).to.not.reverted

    const [claimPriceInEth] = await rentalityCurrencyConverter.getFromUsdCentsLatest(ethToken, amountToClaimInUsdCents)

    const claimInEth = ethers.parseEther(claimPriceInEth.toString())
    const total = claimInEth / BigInt(1e18)
    let value = await rentalityGateway.calculateClaimValue(1)

    const balance = await ethers.provider.getBalance(await hostInsurance.getAddress());
    let willBePaid = claimPriceInEth;
    if(balance < claimPriceInEth) {
        willBePaid = balance;
        }
    await expect(rentalityGateway.connect(admin).payClaim(1)).to.changeEtherBalances(
      [hostInsurance, host],
      [BigInt(-willBePaid), willBePaid]
    )

    

  })

  it('Host will get avarage percents', async function () {

    await expect(rentalityGateway.connect(host).setHostInsurance(1)).to.not.reverted

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
        emptyLocationInfo,0,10
      )
    expect(availableCars.cars.length).to.equal(1)

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

    const depositValue = await rentalityCurrencyConverter.getFromUsdCents(
      ethToken,
      request.securityDepositPerTripInUsdCents,
      ethToCurrencyRate
    )


    const returnToHost = rentPriceInEth - depositValue - rentalityFee - taxes
    const insurancePayment  = returnToHost * BigInt(40) / BigInt(100);
    await expect(rentalityGateway.connect(host).finishTrip(1)).to.changeEtherBalances(
      [host, rentalityPaymentService, hostInsurance],
      [returnToHost - (insurancePayment), -(rentPriceInEth - rentalityFee - taxes), insurancePayment]
    )

    await expect(rentalityGateway.connect(host).setHostInsurance(0)).to.not.reverted
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
  
      await expect(rentalityGateway.connect(host).approveTripRequest(2)).not.to.be.reverted
      await expect(rentalityGateway.connect(host).checkInByHost(2, [0, 0], '', '')).not.to.be.reverted
      await expect(rentalityGateway.connect(guest).checkInByGuest(2, [0, 0])).not.to.be.reverted
      await expect(rentalityGateway.connect(guest).checkOutByGuest(2, [0, 0])).not.to.be.reverted
      await expect(rentalityGateway.connect(host).checkOutByHost(2, [0, 0])).not.to.be.reverted
  
    
  
  
      const returnToHost2 = rentPriceInEth - depositValue - rentalityFee - taxes
      await expect(rentalityGateway.connect(host).finishTrip(2)).to.changeEtherBalances(
        [host, rentalityPaymentService],
        [returnToHost2 , -(rentPriceInEth - rentalityFee - taxes)]
      )
      await expect(rentalityGateway.connect(host).setHostInsurance(1)).to.not.reverted



    const amountToClaimInUsdCents = 1000

    let mockClaimRequest = createMockClaimRequest(1, amountToClaimInUsdCents)

    await expect(rentalityGateway.connect(host).createClaim(mockClaimRequest, true)).to.not.reverted

    const [claimPriceInEth] = await rentalityCurrencyConverter.getFromUsdCentsLatest(ethToken, amountToClaimInUsdCents)

    const claimInEth = ethers.parseEther(claimPriceInEth.toString())
    const total = claimInEth / BigInt(1e18)
    let value = await rentalityGateway.calculateClaimValue(1)

    const balance = await ethers.provider.getBalance(await hostInsurance.getAddress());
    let willBePaid = claimPriceInEth / BigInt(2);
    if(balance < claimPriceInEth) {
        willBePaid = balance;
        }
    await expect(rentalityGateway.connect(admin).payClaim(1)).to.changeEtherBalances(
      [hostInsurance, host],
      [BigInt(-willBePaid), willBePaid]
    )


})

it('Guesr can not create insurance claim', async function () {

    await expect(rentalityGateway.connect(host).setHostInsurance(1)).to.not.reverted

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
        emptyLocationInfo,0,10
      )
    expect(availableCars.cars.length).to.equal(1)

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

    const depositValue = await rentalityCurrencyConverter.getFromUsdCents(
      ethToken,
      request.securityDepositPerTripInUsdCents,
      ethToCurrencyRate
    )


    const returnToHost = rentPriceInEth - depositValue - rentalityFee - taxes
    const insurancePayment  = returnToHost * BigInt(40) / BigInt(100);
    await expect(rentalityGateway.connect(host).finishTrip(1)).to.changeEtherBalances(
      [host, rentalityPaymentService, hostInsurance],
      [returnToHost - (insurancePayment), -(rentPriceInEth - rentalityFee - taxes), insurancePayment]
    )

    const amountToClaimInUsdCents = 362120

    let mockClaimRequest = createMockClaimRequest(1, amountToClaimInUsdCents)

    await expect(rentalityGateway.connect(guest).createClaim(mockClaimRequest, true)).to.be.reverted

    

    

  })

  it('Only admin can pay claim', async function () {

    await expect(rentalityGateway.connect(host).setHostInsurance(1)).to.not.reverted

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
        emptyLocationInfo,0,10
      )
    expect(availableCars.cars.length).to.equal(1)

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

    const depositValue = await rentalityCurrencyConverter.getFromUsdCents(
      ethToken,
      request.securityDepositPerTripInUsdCents,
      ethToCurrencyRate
    )


    const returnToHost = rentPriceInEth - depositValue - rentalityFee - taxes
    const insurancePayment  = returnToHost * BigInt(40) / BigInt(100);
    await expect(rentalityGateway.connect(host).finishTrip(1)).to.changeEtherBalances(
      [host, rentalityPaymentService, hostInsurance],
      [returnToHost - (insurancePayment), -(rentPriceInEth - rentalityFee - taxes), insurancePayment]
    )

    await expect(rentalityGateway.connect(host).setHostInsurance(0)).to.not.reverted
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
  
      await expect(rentalityGateway.connect(host).approveTripRequest(2)).not.to.be.reverted
      await expect(rentalityGateway.connect(host).checkInByHost(2, [0, 0], '', '')).not.to.be.reverted
      await expect(rentalityGateway.connect(guest).checkInByGuest(2, [0, 0])).not.to.be.reverted
      await expect(rentalityGateway.connect(guest).checkOutByGuest(2, [0, 0])).not.to.be.reverted
      await expect(rentalityGateway.connect(host).checkOutByHost(2, [0, 0])).not.to.be.reverted
  
    
  
  
      const returnToHost2 = rentPriceInEth - depositValue - rentalityFee - taxes
      await expect(rentalityGateway.connect(host).finishTrip(2)).to.changeEtherBalances(
        [host, rentalityPaymentService],
        [returnToHost2 , -(rentPriceInEth - rentalityFee - taxes)]
      )
      await expect(rentalityGateway.connect(host).setHostInsurance(1)).to.not.reverted



    const amountToClaimInUsdCents = 1000

    let mockClaimRequest = createMockClaimRequest(1, amountToClaimInUsdCents)

    await expect(rentalityGateway.connect(host).createClaim(mockClaimRequest, true)).to.not.reverted

    const [claimPriceInEth] = await rentalityCurrencyConverter.getFromUsdCentsLatest(ethToken, amountToClaimInUsdCents)

    const claimInEth = ethers.parseEther(claimPriceInEth.toString())
    const total = claimInEth / BigInt(1e18)
    let value = await rentalityGateway.calculateClaimValue(1)

    const balance = await ethers.provider.getBalance(await hostInsurance.getAddress());
    let willBePaid = claimPriceInEth / BigInt(2);
    if(balance < claimPriceInEth) {
        willBePaid = balance;
        }

        await expect(rentalityGateway.connect(guest).payClaim(1)).to.be.reverted
        await expect(rentalityGateway.connect(host).payClaim(1)).to.be.reverted

        
    await expect(rentalityGateway.connect(admin).payClaim(1)).to.changeEtherBalances(
      [hostInsurance, host],
      [BigInt(-willBePaid), willBePaid]
    )

})

it('admin can get claims list', async function () {

    await expect(rentalityGateway.connect(host).setHostInsurance(1)).to.not.reverted

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
        emptyLocationInfo,0,10
      )
    expect(availableCars.cars.length).to.equal(1)

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

    const depositValue = await rentalityCurrencyConverter.getFromUsdCents(
      ethToken,
      request.securityDepositPerTripInUsdCents,
      ethToCurrencyRate
    )


    const returnToHost = rentPriceInEth - depositValue - rentalityFee - taxes
    const insurancePayment  = returnToHost * BigInt(40) / BigInt(100);
    await expect(rentalityGateway.connect(host).finishTrip(1)).to.changeEtherBalances(
      [host, rentalityPaymentService, hostInsurance],
      [returnToHost - (insurancePayment), -(rentPriceInEth - rentalityFee - taxes), insurancePayment]
    )

    await expect(rentalityGateway.connect(host).setHostInsurance(0)).to.not.reverted
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
  
      await expect(rentalityGateway.connect(host).approveTripRequest(2)).not.to.be.reverted
      await expect(rentalityGateway.connect(host).checkInByHost(2, [0, 0], '', '')).not.to.be.reverted
      await expect(rentalityGateway.connect(guest).checkInByGuest(2, [0, 0])).not.to.be.reverted
      await expect(rentalityGateway.connect(guest).checkOutByGuest(2, [0, 0])).not.to.be.reverted
      await expect(rentalityGateway.connect(host).checkOutByHost(2, [0, 0])).not.to.be.reverted
  
    
  
  
      const returnToHost2 = rentPriceInEth - depositValue - rentalityFee - taxes
      await expect(rentalityGateway.connect(host).finishTrip(2)).to.changeEtherBalances(
        [host, rentalityPaymentService],
        [returnToHost2 , -(rentPriceInEth - rentalityFee - taxes)]
      )
      await expect(rentalityGateway.connect(host).setHostInsurance(1)).to.not.reverted



    const amountToClaimInUsdCents = 1000

    let mockClaimRequest = createMockClaimRequest(1, amountToClaimInUsdCents)

    await expect(rentalityGateway.connect(host).createClaim(mockClaimRequest, true)).to.not.reverted
    await expect(rentalityGateway.connect(host).createClaim(mockClaimRequest, false)).to.not.reverted
    await expect(rentalityGateway.connect(host).createClaim(mockClaimRequest, false)).to.not.reverted
    await expect(rentalityGateway.connect(host).createClaim(mockClaimRequest, true)).to.not.reverted

    const [claimPriceInEth] = await rentalityCurrencyConverter.getFromUsdCentsLatest(ethToken, amountToClaimInUsdCents)

    const claimInEth = ethers.parseEther(claimPriceInEth.toString())
    const total = claimInEth / BigInt(1e18)
    let value = await rentalityGateway.calculateClaimValue(1)

    const balance = await ethers.provider.getBalance(await hostInsurance.getAddress());
    let willBePaid = claimPriceInEth / BigInt(2);
    if(balance < claimPriceInEth) {
        willBePaid = balance;
        }
        
    await expect(rentalityGateway.connect(admin).payClaim(1)).to.changeEtherBalances(
      [hostInsurance, host],
      [BigInt(-willBePaid), willBePaid]
    )
    let claims = await rentalityGateway.getHostInsuranceClaims()
    expect(claims.length).to.be.eq(2)
    expect(claims[0].claimId).to.be.eq(1)
    expect(claims[1].claimId).to.be.eq(4)

})


it('host can get all his claims list', async function () {

    await expect(rentalityGateway.connect(host).setHostInsurance(1)).to.not.reverted

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
        emptyLocationInfo,0,10
      )
    expect(availableCars.cars.length).to.equal(1)

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

    const depositValue = await rentalityCurrencyConverter.getFromUsdCents(
      ethToken,
      request.securityDepositPerTripInUsdCents,
      ethToCurrencyRate
    )


    const returnToHost = rentPriceInEth - depositValue - rentalityFee - taxes
    const insurancePayment  = returnToHost * BigInt(40) / BigInt(100);
    await expect(rentalityGateway.connect(host).finishTrip(1)).to.changeEtherBalances(
      [host, rentalityPaymentService, hostInsurance],
      [returnToHost - (insurancePayment), -(rentPriceInEth - rentalityFee - taxes), insurancePayment]
    )

    await expect(rentalityGateway.connect(host).setHostInsurance(0)).to.not.reverted
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
  
      await expect(rentalityGateway.connect(host).approveTripRequest(2)).not.to.be.reverted
      await expect(rentalityGateway.connect(host).checkInByHost(2, [0, 0], '', '')).not.to.be.reverted
      await expect(rentalityGateway.connect(guest).checkInByGuest(2, [0, 0])).not.to.be.reverted
      await expect(rentalityGateway.connect(guest).checkOutByGuest(2, [0, 0])).not.to.be.reverted
      await expect(rentalityGateway.connect(host).checkOutByHost(2, [0, 0])).not.to.be.reverted
  
    
  
  
      const returnToHost2 = rentPriceInEth - depositValue - rentalityFee - taxes
      await expect(rentalityGateway.connect(host).finishTrip(2)).to.changeEtherBalances(
        [host, rentalityPaymentService],
        [returnToHost2 , -(rentPriceInEth - rentalityFee - taxes)]
      )
      await expect(rentalityGateway.connect(host).setHostInsurance(1)).to.not.reverted



    const amountToClaimInUsdCents = 1000

    let mockClaimRequest = createMockClaimRequest(1, amountToClaimInUsdCents)

    await expect(rentalityGateway.connect(host).createClaim(mockClaimRequest, true)).to.not.reverted
    await expect(rentalityGateway.connect(host).createClaim(mockClaimRequest, false)).to.not.reverted
    await expect(rentalityGateway.connect(host).createClaim(mockClaimRequest, false)).to.not.reverted
    await expect(rentalityGateway.connect(host).createClaim(mockClaimRequest, true)).to.not.reverted

    const [claimPriceInEth] = await rentalityCurrencyConverter.getFromUsdCentsLatest(ethToken, amountToClaimInUsdCents)

    const claimInEth = ethers.parseEther(claimPriceInEth.toString())
    const total = claimInEth / BigInt(1e18)
    let value = await rentalityGateway.calculateClaimValue(1)

    const balance = await ethers.provider.getBalance(await hostInsurance.getAddress());
    let willBePaid = claimPriceInEth / BigInt(2);
    if(balance < claimPriceInEth) {
        willBePaid = balance;
        }
        
    await expect(rentalityGateway.connect(admin).payClaim(1)).to.changeEtherBalances(
      [hostInsurance, host],
      [BigInt(-willBePaid), willBePaid]
    )
    let claims = await rentalityGateway.connect(host).getMyClaimsAs(true)
    expect(claims.length).to.be.eq(4)

})

it('host can get his insurance info', async function () {

    await expect(rentalityGateway.connect(host).setHostInsurance(1)).to.not.reverted

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
        emptyLocationInfo,0,10
      )
    expect(availableCars.cars.length).to.equal(1)

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

    const depositValue = await rentalityCurrencyConverter.getFromUsdCents(
      ethToken,
      request.securityDepositPerTripInUsdCents,
      ethToCurrencyRate
    )


    const returnToHost = rentPriceInEth - depositValue - rentalityFee - taxes
    const insurancePayment  = returnToHost * BigInt(40) / BigInt(100);
    await expect(rentalityGateway.connect(host).finishTrip(1)).to.changeEtherBalances(
      [host, rentalityPaymentService, hostInsurance],
      [returnToHost - (insurancePayment), -(rentPriceInEth - rentalityFee - taxes), insurancePayment]
    )

    await expect(rentalityGateway.connect(host).setHostInsurance(0)).to.not.reverted
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
  
      await expect(rentalityGateway.connect(host).approveTripRequest(2)).not.to.be.reverted
      await expect(rentalityGateway.connect(host).checkInByHost(2, [0, 0], '', '')).not.to.be.reverted
      await expect(rentalityGateway.connect(guest).checkInByGuest(2, [0, 0])).not.to.be.reverted
      await expect(rentalityGateway.connect(guest).checkOutByGuest(2, [0, 0])).not.to.be.reverted
      await expect(rentalityGateway.connect(host).checkOutByHost(2, [0, 0])).not.to.be.reverted
  
    
  
  
      const returnToHost2 = rentPriceInEth - depositValue - rentalityFee - taxes
      await expect(rentalityGateway.connect(host).finishTrip(2)).to.changeEtherBalances(
        [host, rentalityPaymentService],
        [returnToHost2 , -(rentPriceInEth - rentalityFee - taxes)]
      )
      await expect(rentalityGateway.connect(host).setHostInsurance(1)).to.not.reverted
      let rule = await rentalityGateway.getHostInsuranceRule(host.address)
      expect(rule.partToInsurance).to.be.eq(40)

      await expect(rentalityGateway.connect(host).setHostInsurance(0)).to.not.reverted
      rule = await rentalityGateway.getHostInsuranceRule(host.address)
      expect(rule.partToInsurance).to.be.eq(0)

})
})