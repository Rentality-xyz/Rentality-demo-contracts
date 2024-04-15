const {expect} = require('chai')
const {deployDefaultFixture, getMockCarRequest, ethToken, calculatePayments} = require('../utils')
const {loadFixture} = require('@nomicfoundation/hardhat-network-helpers')
const {ethers} = require('hardhat')

describe('Rentality taxes & discounts', function () {
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
        elEngine,
        pEngine,
        hEngine,
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
            engineService,
            rentalityAutomationService,
            elEngine,
            pEngine,
            hEngine,
            owner,
            admin,
            manager,
            host,
            guest,
            anonymous,
        } = await loadFixture(deployDefaultFixture))
    })

    it('should correctly calculate taxes', async function () {
        let sumToPayInUsdCents = 19500
        let dayInTrip = 3
        let totalTaxes = (sumToPayInUsdCents * 7) / 100 + dayInTrip * 200

        let calculatedTaxes = await rentalityPaymentService.calculateTaxes(1, dayInTrip, sumToPayInUsdCents)

        expect(totalTaxes).to.be.eq(calculatedTaxes)
    })
    it('should correctly calculate discount', async function () {
        let sumToPay = 37800
        let threeDayDiscount = sumToPay * 3 - (sumToPay * 3 * 2) / 100
        let sevenDayDiscount = sumToPay * 7 - (sumToPay * 7 * 10) / 100
        let thirtyDiscount = sumToPay * 31 - (sumToPay * 31 * 15) / 100

        let threeDayCalculatedDiscountPrice = await rentalityPaymentService.calculateSumWithDiscount(
            ethToken /*address(0)*/,
            3,
            sumToPay
        )
        expect(threeDayCalculatedDiscountPrice).to.be.eq(threeDayDiscount)

        let sevenDayCalculatedDiscountPrice = await rentalityPaymentService.calculateSumWithDiscount(
            ethToken /*address(0)*/,
            7,
            sumToPay
        )
        expect(sevenDayCalculatedDiscountPrice).to.be.eq(sevenDayDiscount)

        let thirtyDayCalculatedDiscountPrice = await rentalityPaymentService.calculateSumWithDiscount(
            ethToken /*address(0)*/,
            31,
            sumToPay
        )
        expect(thirtyDayCalculatedDiscountPrice).to.be.eq(thirtyDiscount)
    })
    it('guest payed correct value with taxes, without discount', async function () {
        const request = getMockCarRequest(10)
        await expect(rentalityCarToken.connect(host).addCar(request)).not.to.be.reverted
        const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
        expect(myCars.length).to.equal(1)

        const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
        expect(availableCars.length).to.equal(1)

        let sumToPayInUsdCents = 19500
        let dayInTrip = 2
        let totalTaxes = (sumToPayInUsdCents * dayInTrip * 7) / 100 + dayInTrip * 200

        const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
            await rentalityCurrencyConverter.getFromUsdLatest(ethToken, sumToPayInUsdCents * dayInTrip + totalTaxes + request.securityDepositPerTripInUsdCents)

        let twoDaysInSec = 172800

        await expect(
            await rentalityPlatform.connect(guest).createTripRequest(
                {
                    carId: 1,
                    startDateTime: Date.now(),
                    endDateTime: Date.now() + twoDaysInSec,
                    currencyType: ethToken,
                },
                {value: rentPriceInEth}
            )
        ).to.changeEtherBalances([guest, rentalityPlatform], [-rentPriceInEth, rentPriceInEth])
    })

    it('guest payed correct value with taxes and 3 days discount', async function () {
        const request = getMockCarRequest(10)
        await expect(rentalityCarToken.connect(host).addCar(request)).not.to.be.reverted
        const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
        expect(myCars.length).to.equal(1)

        const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
        expect(availableCars.length).to.equal(1)

        let sumToPayInUsdCents = request.pricePerDayInUsdCents
        let dayInTrip = 4
        let sumToPayWithDiscount = sumToPayInUsdCents * dayInTrip - (sumToPayInUsdCents * dayInTrip * 2) / 100

        let totalTaxes = (sumToPayWithDiscount * 7) / 100 + dayInTrip * 200

        const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
            await rentalityCurrencyConverter.getFromUsdLatest(ethToken, Math.floor(sumToPayWithDiscount + totalTaxes + request.pricePerDayInUsdCents))

        let fourDaysInSec = 345600

        await expect(
            await rentalityPlatform.connect(guest).createTripRequest(
                {
                    carId: 1,
                    startDateTime: Date.now(),
                    endDateTime: Date.now() + fourDaysInSec,
                    currencyType: ethToken,
                },
                {value: rentPriceInEth}
            )
        ).to.changeEtherBalances([guest, rentalityPlatform], [-rentPriceInEth, rentPriceInEth])
    })
    it.only('guest payed correct value with taxes and 7 days discount', async function () {
        const request = getMockCarRequest(10)
        await expect(rentalityCarToken.connect(host).addCar(request)).not.to.be.reverted
        const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
        expect(myCars.length).to.equal(1)

        const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
        expect(availableCars.length).to.equal(1)

        let sumToPayInUsdCents = request.pricePerDayInUsdCents
        let dayInTrip = 8
        let sumToPayWithDiscount = (sumToPayInUsdCents * dayInTrip - (sumToPayInUsdCents * dayInTrip * 10)) * 1000 / 100

        let totalTaxes = ((sumToPayWithDiscount * 7) / 100) + (dayInTrip * 200);

        const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
            await rentalityCurrencyConverter.getFromUsdLatest(ethToken, sumToPayWithDiscount + totalTaxes + (request.securityDepositPerTripInUsdCents * 1000))

        let eightDaysInSec = 691200

        const result = await rentalityPlatform.calculatePayments(1, 8, ethToken);
        console.log(result)
        console.log( rentPriceInEth / BigInt(10_000))
        await expect(
            await rentalityPlatform.connect(guest).createTripRequest(
                {
                    carId: 1,
                    startDateTime: Date.now(),
                    endDateTime: Date.now() + eightDaysInSec,
                    currencyType: ethToken,
                },
                {value: rentPriceInEth / BigInt(1000)}
            )
        ).to.changeEtherBalances([guest, rentalityPlatform], [-rentPriceInEth, rentPriceInEth])
    })

    it('guest payed correct value with taxes and 30 days discount', async function () {
        const request = getMockCarRequest(10)
        await expect(rentalityCarToken.connect(host).addCar(request)).not.to.be.reverted
        const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
        expect(myCars.length).to.equal(1)

        const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
        expect(availableCars.length).to.equal(1)

        let sumToPayInUsdCents = request.pricePerDayInUsdCents

        let dayInTrip = 31
        let sumToPayWithDiscount = sumToPayInUsdCents * dayInTrip - (sumToPayInUsdCents * dayInTrip * 15) / 100

        let totalTaxes = (sumToPayWithDiscount * 7) / 100 + dayInTrip * 200

        const [rentPriceInEth, ,] = await rentalityCurrencyConverter.getFromUsdLatest(
            ethToken,
            Math.floor(totalTaxes + sumToPayWithDiscount + request.securityDepositPerTripInUsdCents)
        )

        let thirtyOneDayInSec = 86400 * 31

        const result = await rentalityPlatform.calculatePayments(1, 31, ethToken);

        await expect(
            await rentalityPlatform.connect(guest).createTripRequest(
                {
                    carId: 1,
                    startDateTime: Date.now(),
                    endDateTime: Date.now() + thirtyOneDayInSec,
                    currencyType: ethToken,
                },
                {value: rentPriceInEth}
            )
        ).to.changeEtherBalances([guest, rentalityPlatform], [-rentPriceInEth, rentPriceInEth])

    })
    it('after trip host get correct value', async function () {
        const request = getMockCarRequest(91)
        await expect(rentalityCarToken.connect(host).addCar(request)).not.to.be.reverted
        const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
        expect(myCars.length).to.equal(1)

        const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
        expect(availableCars.length).to.equal(1)

        let sumToPayInUsdCents = request.pricePerDayInUsdCents
        let dayInTrip = 31
        let sumToPayWithDiscount = sumToPayInUsdCents * dayInTrip - (sumToPayInUsdCents * dayInTrip * 15) / 100


        let thirtyOneDayInSec = 86400 * 31
        const result = await rentalityPlatform.calculatePayments(1, 31, ethToken);
        await expect(
            await rentalityPlatform.connect(guest).createTripRequest(
                {
                    carId: 1,
                    startDateTime: Date.now(),
                    endDateTime: Date.now() + thirtyOneDayInSec,
                    currencyType: ethToken,
                },
                {value: result.totalPrice}
            )
        ).to.changeEtherBalances([guest, rentalityPlatform], [-result.totalPrice, result.totalPrice])


        await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
        await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0])).not.to.be.reverted
        await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
        await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [0, 0])).not.to.be.reverted
        await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted

        const [valueInEthWithoutTaxes, ,] = await rentalityCurrencyConverter.getFromUsdLatest(
            ethToken,
            Math.floor(sumToPayWithDiscount)
        )
        const [deposit, ,] = await rentalityCurrencyConverter.getFromUsdLatest(
            ethToken,
           request.securityDepositPerTripInUsdCents
        )
        const fee = await rentalityPaymentService.getPlatformFeeFrom(valueInEthWithoutTaxes)

        const returnToHost = result.totalPrice - deposit - fee

        await expect(rentalityGateway.connect(host).finishTrip(1)).to.changeEtherBalances(
            [host, rentalityPlatform],
            [returnToHost, -(result.totalPrice - fee)]
        )
    })

    it('Should return user discount, if it exists', async function () {
        await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
        const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
        expect(myCars.length).to.equal(1)

        const availableCars = await rentalityCarToken.connect(guest).getAvailableCarsForUser(guest.address)
        expect(availableCars.length).to.equal(1)

        const data = {
            threeDaysDiscount: 100_000,
            sevenDaysDiscount: 200_000,
            thirtyDaysDiscount: 1_000_000,
            initialized: true,
        }

        let abiEncoder = ethers.AbiCoder.defaultAbiCoder()
        const encodedData = abiEncoder.encode(
            ['uint32', 'uint32', 'uint32', 'bool'],
            [data.threeDaysDiscount, data.sevenDaysDiscount, data.thirtyDaysDiscount, data.initialized]
        )

        await expect(await rentalityPaymentService.connect(owner).addUserDiscount(encodedData)).to.not.reverted

        let first = await rentalityPaymentService.connect(owner).calculateSumWithDiscount(owner.address, 3, 1000)
        expect(first).to.be.eq(1000 * 3 - (1000 * 3 * 10) / 100)
        let second = await rentalityPaymentService.connect(owner).calculateSumWithDiscount(owner.address, 8, 1000)
        expect(second).to.be.eq(1000 * 8 - (1000 * 8 * 20) / 100)
        let last = await rentalityPaymentService.connect(owner).calculateSumWithDiscount(owner.address, 31, 1000)
        expect(last).to.be.eq(0)
    })

    it('Calculate payments should return correct calculation', async function () {
        const request = getMockCarRequest(10)
        await expect(rentalityCarToken.connect(host).addCar(request)).not.to.be.reverted

        const tripDays = 7

        const {rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals, rentalityFee} = await calculatePayments(
            rentalityCurrencyConverter,
            rentalityPaymentService,
            request.pricePerDayInUsdCents,
            7,
            request.securityDepositPerTripInUsdCents
        )

        const contractResult = await rentalityGateway.calculatePayments(
            1,
            tripDays,
            '0x0000000000000000000000000000000000000000'
        )
        expect(contractResult.totalPrice).to.be.eq(rentPriceInEth)
    })

    it('Calculate payments: can create trip request with calculated sum', async function () {
        const request = getMockCarRequest(10)
        await expect(rentalityCarToken.connect(host).addCar(request)).not.to.be.reverted

        const tripDays = 31
        const oneDayInSeconds = 86400

        const {rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals, rentalityFee} = await calculatePayments(
            rentalityCurrencyConverter,
            rentalityPaymentService,
            request.pricePerDayInUsdCents,
            31,
            request.securityDepositPerTripInUsdCents
        )

        const contractResult = await rentalityGateway.calculatePayments(
            1,
            tripDays,
            '0x0000000000000000000000000000000000000000'
        )
        expect(contractResult.totalPrice).to.be.eq(rentPriceInEth)

        await expect(
            rentalityPlatform.connect(guest).createTripRequest(
                {
                    carId: 1,
                    host: host.address,
                    startDateTime: Date.now(),
                    endDateTime: Date.now() + oneDayInSeconds * tripDays,
                    startLocation: '',
                    endLocation: '',
                    totalDayPriceInUsdCents: request.pricePerDayInUsdCents,
                    depositInUsdCents: request.securityDepositPerTripInUsdCents,
                    currencyRate: contractResult.currencyRate,
                    currencyDecimals: contractResult.currencyDecimals,
                    currencyType: ethToken,
                },
                {value: contractResult.totalPrice}
            )
        ).to.changeEtherBalances([guest, rentalityPlatform], [-contractResult.totalPrice, contractResult.totalPrice])
    })
})
