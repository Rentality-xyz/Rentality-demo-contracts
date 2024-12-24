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
  InsuranceType,
  emptySignedLocationInfo,
  zeroHash,
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
    mockRequestWithInsurance,
    insuranceService,
    tripsQuery

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
      mockRequestWithInsurance,
      insuranceService,
      tripsQuery
    } = await loadFixture(deployDefaultFixture))
  })

  it('Should take additional 2500 cents per day, when insurance required', async function () {
    await expect(rentalityGateway.connect(host).addCar(mockRequestWithInsurance,zeroHash)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const result = await rentalityGateway.connect(guest).calculatePaymentsWithDelivery(1, 1, ethToken,emptyLocationInfo,emptyLocationInfo)
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
        { value: result.totalPrice }
      )
    ).to.changeEtherBalances([guest, rentalityPaymentService], [-result.totalPrice, result.totalPrice])
  }),
    it('Insurance payment should get back to guest after rejection', async function () {
      await expect(rentalityGateway.connect(host).addCar(mockRequestWithInsurance,zeroHash)).not.to.be.reverted
      const myCars = await rentalityGateway.connect(host).getMyCars()
      expect(myCars.length).to.equal(1)

      const result = await rentalityGateway.connect(guest).calculatePaymentsWithDelivery(1, 1, ethToken,emptyLocationInfo,emptyLocationInfo)
      await expect(
        await rentalityGateway.connect(guest).createTripRequestWithDelivery(
          {
            carId: 1,
            startDateTime: 123,
            endDateTime: 321,
            currencyType: ethToken,
            insurancePaid: true,
            photo: '',
            pickUpInfo: emptySignedLocationInfo,
            returnInfo: emptySignedLocationInfo
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
    await expect(rentalityGateway.connect(host).addCar(mockRequestWithInsurance,zeroHash)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const result = await rentalityGateway.calculatePaymentsWithDelivery(1, 3, ethToken,emptyLocationInfo,emptyLocationInfo)
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 1,
          endDateTime: 1 + 86400 * 3,
          currencyType: ethToken,
          insurancePaid: true,
          photo: '',
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo
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
    await expect(rentalityGateway.connect(host).addCar(mockRequestWithInsurance,zeroHash)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const result = await rentalityGateway.connect(guest).calculatePaymentsWithDelivery(1, 1, ethToken,emptyLocationInfo,emptyLocationInfo)
    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          insurancePaid: true,
          photo: '',
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo
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
    await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [0, 0],zeroHash)).not.to.be.reverted
    await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted

    const depositValue = await rentalityCurrencyConverter.getFromUsd(
      ethToken,
      mockRequestWithInsurance.securityDepositPerTripInUsdCents,
      payments.ethToCurrencyRate,
      payments.ethToCurrencyDecimals
    )

    const returnToHost = result.totalPrice - depositValue - payments.rentalityFee - payments.taxes

    await expect(rentalityGateway.connect(host).finishTrip(1,zeroHash)).to.changeEtherBalances([host], [returnToHost])
  })
  it('guest can add insurance', async function () {
    let insurance = {
      companyName: 'myCo',
      policyNumber: '12124-124-124',
      photo: 'url',
      comment: 'comment',
      insuranceType: InsuranceType.General,
    }
    await expect(rentalityGateway.connect(guest).saveGuestInsurance(insurance)).to.not.reverted

    let insurances = await rentalityGateway.connect(guest).getMyInsurancesAsGuest()
    expect(insurances[0].companyName).to.be.eq(insurance.companyName)
    expect(insurances[0].photo).to.be.eq(insurance.photo)
    expect(insurances[0].policyNumber).to.be.eq(insurance.policyNumber)

  })
  it('guest add second insurance, second has none status', async function () {
    let insurance = {
      companyName: 'myCo',
      policyNumber: '12124-124-124',
      photo: 'url',
      comment: 'comment',
      insuranceType: InsuranceType.General,
    }
    await expect(rentalityGateway.connect(guest).saveGuestInsurance(insurance)).to.not.reverted
    await expect(rentalityGateway.connect(guest).saveGuestInsurance(insurance)).to.not.reverted

    let insurances = await rentalityGateway.connect(guest).getMyInsurancesAsGuest()
    expect(insurances[0].insuranceType).to.be.eq(0)
    expect(insurances[1].insuranceType).to.be.eq(1)
  })
  it('guest can not add one time insurance in profile', async function () {
    let insurance = {
      companyName: 'myCo',
      policyNumber: '12124-124-124',
      photo: 'url',
      comment: 'comment',
      insuranceType: InsuranceType.OneTime,
    }
    await expect(rentalityGateway.connect(guest).saveGuestInsurance(insurance)).to.be.reverted
  })

  it('guest will not pay for insurance if he have one in profile', async function () {
    await expect(rentalityGateway.connect(host).addCar(mockRequestWithInsurance,zeroHash)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    let insurance = {
      companyName: 'myCo',
      policyNumber: '12124-124-124',
      photo: 'url',
      comment: 'comment',
      insuranceType: InsuranceType.General,
    }
    let noneInsurance = {
      companyName: 'myCo',
      policyNumber: '12124-124-124',
      photo: 'url',
      comment: 'comment',
      insuranceType: InsuranceType.None,
    }

    await expect(rentalityGateway.connect(guest).saveGuestInsurance(insurance)).to.not.reverted

    const result1 = await rentalityGateway.connect(guest).calculatePaymentsWithDelivery(1, 1, ethToken,emptyLocationInfo,emptyLocationInfo)

    await expect(rentalityGateway.connect(guest).saveGuestInsurance(noneInsurance)).to.not.reverted

    const result2 = await rentalityGateway.connect(guest).calculatePaymentsWithDelivery(1, 1, ethToken,emptyLocationInfo,emptyLocationInfo)
    expect(result1 < result2).to.be.eq(true)

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
        { value: result2.totalPrice }
      )
    ).to.not.reverted

    await expect(
      rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        { value: result1.totalPrice }
      )
    ).to.be.reverted
  })
  it('guest can add insurance to the trip', async function () {
    await expect(rentalityGateway.connect(host).addCar(mockRequestWithInsurance,zeroHash)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const result = await rentalityGateway.connect(guest).calculatePaymentsWithDelivery(1, 1, ethToken,emptyLocationInfo,emptyLocationInfo)

    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          currencyType: ethToken,
        },
        { value: result.totalPrice }
      )
    ).to.not.reverted

    await expect(
      rentalityGateway.connect(guest).saveTripInsuranceInfo(1, {
        companyName: 'myCo',
        policyNumber: '12124-124-124',
        photo: 'url',
        comment: 'comment',
        insuranceType: InsuranceType.General,
      })
    ).to.not.reverted

    let insurances = await rentalityGateway.connect(guest).getInsurancesBy(false)
    expect(insurances.length).to.be.eq(1)
  })
  it('host can add insurance to the trip', async function () {
    await expect(rentalityGateway.connect(host).addCar(mockRequestWithInsurance,zeroHash)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const result = await rentalityGateway.connect(guest).calculatePaymentsWithDelivery(1, 1, ethToken,emptyLocationInfo,emptyLocationInfo)

    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          currencyType: ethToken,
        },
        { value: result.totalPrice }
      )
    ).to.not.reverted

    await expect(
      rentalityGateway.connect(host).saveTripInsuranceInfo(1, {
        companyName: 'myCo',
        policyNumber: '12124-124-124',
        photo: 'url',
        comment: 'comment',
        
        insuranceType: InsuranceType.General,
      })
    ).to.not.reverted

    let insurances = await rentalityGateway.connect(host).getInsurancesBy(true)
    expect(insurances.length).to.be.eq(1)
  })
  it('host can see guest general insurance', async function () {
    await expect(rentalityGateway.connect(host).addCar(mockRequestWithInsurance,zeroHash)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    let insurance = {
      companyName: 'myCo',
      policyNumber: '12124-124-124',
      photo: 'url',
      comment: 'comment',
      insuranceType: InsuranceType.General,
    }

    await expect(rentalityGateway.connect(guest).saveGuestInsurance(insurance)).to.not.reverted

    const result = await rentalityGateway.connect(guest).calculatePaymentsWithDelivery(1, 1, ethToken,emptyLocationInfo,emptyLocationInfo)

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
        { value: result.totalPrice }
      )
    ).to.not.reverted

    let insurances = await rentalityGateway.connect(host).getInsurancesBy(true)
    expect(insurances.length).to.be.eq(1)
  })

  it('host can see guest added insurances', async function () {
    await expect(rentalityGateway.connect(host).addCar(mockRequestWithInsurance,zeroHash)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    let insurance = {
      companyName: 'myCo',
      policyNumber: '12124-124-124',
      photo: 'url',
      comment: 'comment',
      insuranceType: InsuranceType.General,
    }

    await expect(rentalityGateway.connect(guest).saveGuestInsurance(insurance)).to.not.reverted

    const result = await rentalityGateway.connect(guest).calculatePaymentsWithDelivery(1, 1, ethToken,emptyLocationInfo,emptyLocationInfo)

    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          currencyType: ethToken,
        },
        { value: result.totalPrice }
      )
    ).to.not.reverted

    await expect(
      rentalityGateway.connect(guest).saveTripInsuranceInfo(1, {
        companyName: 'myCo',
        policyNumber: '12124-124-124',
        photo: 'url',
        comment: 'comment',
        insuranceType: InsuranceType.OneTime,
      })
    ).to.not.reverted

    let insurances = await rentalityGateway.connect(host).getInsurancesBy(true)
    expect(insurances.length).to.be.eq(2)
  })

  it('guest can see host added insurances', async function () {
    await expect(rentalityGateway.connect(host).addCar(mockRequestWithInsurance,zeroHash)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    const result = await rentalityGateway.connect(guest).calculatePaymentsWithDelivery(1, 1, ethToken,emptyLocationInfo,emptyLocationInfo)

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
        { value: result.totalPrice }
      )
    ).to.not.reverted

    await expect(
      rentalityGateway.connect(host).saveTripInsuranceInfo(1, {
        companyName: 'myCo',
        policyNumber: '12124-124-124',
        photo: 'url',
        comment: 'comment',
        insuranceType: InsuranceType.OneTime,
      })
    ).to.not.reverted

    let insurances = await rentalityGateway.connect(guest).getInsurancesBy(false)
    expect(insurances.length).to.be.eq(1)
  })

  it('guest and host see all insurances', async function () {
    await expect(rentalityGateway.connect(host).addCar(mockRequestWithInsurance,zeroHash)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    let insurance = {
      companyName: 'myCo',
      policyNumber: '12124-124-124',
      photo: 'url',
      comment: 'comment',
      insuranceType: InsuranceType.General,
    }

    await expect(rentalityGateway.connect(guest).saveGuestInsurance(insurance)).to.not.reverted

    const result = await rentalityGateway.connect(guest).calculatePaymentsWithDelivery(1, 1, ethToken,emptyLocationInfo,emptyLocationInfo)

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
        { value: result.totalPrice }
      )
    ).to.not.reverted

    await expect(
      rentalityGateway.connect(host).saveTripInsuranceInfo(1, {
        companyName: 'myCo',
        policyNumber: '12124-124-124',
        photo: 'url',
        comment: 'comment',
        insuranceType: InsuranceType.OneTime,
      })
    ).to.not.reverted

    let insurances = await rentalityGateway.connect(guest).getInsurancesBy(false)
    expect(insurances.length).to.be.eq(2)
    let res = await insuranceService.getTripInsurances(1)
    expect(insurances[0].tripId).to.be.eq(1)
    expect(insurances[1].tripId).to.be.eq(1)
    expect(insurances[1].carBrand).to.be.eq(mockRequestWithInsurance.brand)
    expect(insurances[0].carBrand).to.be.eq(mockRequestWithInsurance.brand)
    expect(insurances[1].carModel).to.be.eq(mockRequestWithInsurance.model)
    expect(insurances[0].createdByHost).to.be.eq(false)
    expect(insurances[1].createdByHost).to.be.eq(true)

    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          currencyType: ethToken,
        },
        { value: result.totalPrice }
      )
    ).to.not.reverted

    let insurance2 = {
      companyName: 'myCo2',
      policyNumber: '12124-124-1242',
      photo: 'url',
      comment: 'comment2',
      insuranceType: InsuranceType.OneTime,
    }

    await expect(rentalityGateway.connect(host).saveTripInsuranceInfo(2, insurance2)).to.not.reverted
    insurances = await rentalityGateway.connect(host).getInsurancesBy(true)

    await expect(
      rentalityGateway.connect(host).saveTripInsuranceInfo(2, {
        companyName: 'myCo',
        policyNumber: '12124-124-124',
        photo: 'url',
        comment: 'comment',
        insuranceType: InsuranceType.OneTime,
      })
    ).to.not.reverted
    await ethers.provider.send('evm_increaseTime', [3600]);
    await expect(
      rentalityGateway.connect(host).saveTripInsuranceInfo(2, {
        companyName: 'myCo',
        policyNumber: '12124-124-124',
        photo: 'url',
        comment: 'comment',
        insuranceType: InsuranceType.OneTime,
      })
    ).to.not.reverted
    await ethers.provider.send('evm_increaseTime', [3600]);
    await expect(
      rentalityGateway.connect(host).saveTripInsuranceInfo(2, {
        companyName: 'myCo',
        policyNumber: '12124-124-124124',
        photo: 'url',
        comment: 'comment',
        insuranceType: InsuranceType.OneTime,
      })
    ).to.not.reverted
    await expect(
      rentalityGateway.connect(host).saveTripInsuranceInfo(2, {
        companyName: 'myCo',
        policyNumber: '12124-124-121244',
        photo: 'url',
        comment: 'comment',
        insuranceType: InsuranceType.OneTime,
      })
    ).to.not.reverted
    await ethers.provider.send('evm_increaseTime', [3600]);
    await expect(
      rentalityGateway.connect(host).saveTripInsuranceInfo(2, {
        companyName: 'myCo',
        policyNumber: '12124-124-1241214',
        photo: 'url',
        comment: 'comment',
        insuranceType: InsuranceType.OneTime,
      })
    ).to.not.reverted
    await ethers.provider.send('evm_increaseTime', [3600]);
    await expect(
      rentalityGateway.connect(host).saveTripInsuranceInfo(2, {
        companyName: 'myCo',
        policyNumber: '12124-124-124124',
        photo: 'url',
        comment: 'comment',
        insuranceType: InsuranceType.General,
      })
    ).to.not.reverted
  
    insurances = await rentalityGateway.connect(host).getInsurancesBy(true)
   
    expect(insurances.length).to.be.eq(10)
    expect(insurances[2].tripId).to.be.eq(2)
    expect(insurances[3].tripId).to.be.eq(2)
    expect(insurances[2].carBrand).to.be.eq(mockRequestWithInsurance.brand)
    expect(insurances[3].carBrand).to.be.eq(mockRequestWithInsurance.brand)
    expect(insurances[2].carModel).to.be.eq(mockRequestWithInsurance.model)
    expect(insurances[2].createdByHost).to.be.eq(false)
    expect(insurances[3].createdByHost).to.be.eq(true)
    expect(insurances[3].insuranceInfo.companyName).to.be.eq(insurance2.companyName)
    expect(insurances[3].insuranceInfo.policyNumber).to.be.eq(insurance2.policyNumber)
  })
  it('check in by host add insurance to list', async function () {
    await expect(rentalityGateway.connect(host).addCar(mockRequestWithInsurance,zeroHash)).not.to.be.reverted
    const myCars = await rentalityGateway.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    let insurance = {
      companyName: 'myCo',
      policyNumber: '12124-124-124',
      photo: 'url',
      comment: 'comment',
      insuranceType: InsuranceType.General,
    }

    const result = await rentalityGateway.connect(guest).calculatePaymentsWithDelivery(1, 1, ethToken,emptyLocationInfo,emptyLocationInfo)

    await expect(
      await rentalityGateway.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
          currencyType: ethToken,
        },
        { value: result.totalPrice }
      )
    ).to.not.reverted

    await expect(rentalityGateway.connect(host).approveTripRequest(1)).to.not.reverted
    await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], insurance.companyName, insurance.policyNumber))
      .to.not.reverted
    let insurances = await rentalityGateway.connect(host).getInsurancesBy(true)
    expect(insurances.length).to.be.eq(1)
    expect(insurances[0].insuranceInfo.companyName).to.be.eq(insurance.companyName)
    expect(insurances[0].insuranceInfo.policyNumber).to.be.eq(insurance.policyNumber)
  })
})
