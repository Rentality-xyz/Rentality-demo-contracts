const { expect } = require('chai')
const {
  deployDefaultFixture,
  ethToken,
  locationInfo,
  getEmptySearchCarParams,
  signTCMessage,
  getMockCarRequest,
  calculatePayments,
  emptyLocationInfo,
} = require('../utils')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { ethers } = require('hardhat')
const { applyProviderWrappers } = require('hardhat/internal/core/providers/construction')

describe('Rentality insurance', function () {
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
    rentalityLocationVerifier,
    mockRequestWithInsurance

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
      rentalityLocationVerifier,
      mockRequestWithInsurance
    } = await loadFixture(deployDefaultFixture))
  })

  it('Should take additional 2500 cents per day, when insurance required', async function () {
    await expect(rentalityGateway.connect(host).addCar(mockRequestWithInsurance)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const result = await rentalityGateway.calculatePayments(1, 1, ethToken, true)
    await expect(
      await rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          insurancePaid: true,
          photo: '',
          pickUpInfo: {
            signature: guest.address,
            locationInfo: emptyLocationInfo,
          },
          returnInfo: {
            signature: guest.address,
            locationInfo: emptyLocationInfo,
          },
        },
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])
  }),
    it('Insurance payment should get back to guest after rejection', async function () {
      await expect(rentalityGateway.connect(host).addCar(mockRequestWithInsurance)).not.to.be.reverted
      const myCars = await rentalityGateway.connect(host).getMyCars()
      expect(myCars.length).to.equal(1)

      const result = await rentalityGateway.calculatePayments(1, 1, ethToken, true)
      await expect(
        await rentalityGateway.connect(guest).createTripRequest(
          {
            carId: 1,
            startDateTime: 123,
            endDateTime: 321,
            currencyType: ethToken,
            insurancePaid: true,
            photo: '',
            pickUpInfo: {
              signature: guest.address,
              locationInfo: emptyLocationInfo,
            },
            returnInfo: {
              signature: guest.address,
              locationInfo: emptyLocationInfo,
            },
          },
          { value: result.totalPrice }
        )
      ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

      await expect(await rentalityGateway.connect(guest).rejectTripRequest(1)).to.changeEtherBalances(
        [guest, rentalityPaymentService],
        [result.totalPrice, -result.totalPrice]
      )
    })
  it('Insurance payment should get back to guest after rejection for several days', async function () {
    await expect(rentalityGateway.connect(host).addCar(mockRequestWithInsurance)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const result = await rentalityGateway.calculatePayments(1, 3, ethToken, true)
    await expect(
      await rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: 1,
          endDateTime: 1 + 86400 * 3,
          currencyType: ethToken,
          insurancePaid: true,
          photo: '',
          pickUpInfo: {
            signature: guest.address,
            locationInfo: emptyLocationInfo,
          },
          returnInfo: {
            signature: guest.address,
            locationInfo: emptyLocationInfo,
          },
        },
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])

    await expect(await rentalityGateway.connect(guest).rejectTripRequest(1)).to.changeEtherBalances(
      [guest, rentalityPaymentService],
      [result.totalPrice, -result.totalPrice]
    )
  })
  it('Insurance payment should come to host after trip finish', async function () {
    await expect(rentalityGateway.connect(host).addCar(mockRequestWithInsurance)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const result = await rentalityGateway.calculatePayments(1, 1, ethToken, true)
    await expect(
      await rentalityGateway.connect(guest).createTripRequest(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          insurancePaid: true,
          photo: '',
          pickUpInfo: {
            signature: guest.address,
            locationInfo: emptyLocationInfo,
          },
          returnInfo: {
            signature: guest.address,
            locationInfo: emptyLocationInfo,
          },
        },
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])
    let payments = await calculatePayments(
      rentalityCurrencyConverter,
      rentalityPaymentService,
      mockRequestWithInsurance.pricePerDayInUsdCents,
      1,
      mockRequestWithInsurance.securityDepositPerTripInUsdCents
    )

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [0, 0])).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted

    const depositValue = await rentalityCurrencyConverter.getFromUsd(
      ethToken,
      mockRequestWithInsurance.securityDepositPerTripInUsdCents,
      payments.ethToCurrencyRate,
      payments.ethToCurrencyDecimals
    )

    const returnToHost = result.totalPrice - depositValue - payments.rentalityFee - payments.taxes

    await expect(rentalityGateway.connect(host).finishTrip(1)).to.changeEtherBalances([host], [returnToHost])
  })
})
