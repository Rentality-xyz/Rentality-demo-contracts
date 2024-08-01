const {loadFixture} = require('@nomicfoundation/hardhat-network-helpers')
const {expect} = require('chai')
const {
    getMockCarRequest,
    deployDefaultFixture, ethToken, calculatePayments,
} = require('../utils')
const {applyProviderWrappers} = require("hardhat/internal/core/providers/construction");
let mockCarInvestment = {
    car: getMockCarRequest(0),
    priceInUsd: 10000,
    inProgress: true,
    creatorPercents: 10
}
describe.only('Rentality investment', function () {
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
        investorsService

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
            investorsService
        } = await loadFixture(deployDefaultFixture))
    })
    it('Host can create investment', async function () {
        await expect(
            await investorsService.connect(host).createCarInvestment(mockCarInvestment, "name", "sym")).to.not.reverted

    })
    it('Guest can invest', async function () {
        await expect(
            await investorsService.connect(host).createCarInvestment(mockCarInvestment, "name", "sym")).to.not.reverted

        await expect(
            investorsService.connect(guest).invest(1, {value: 10000})).to.not.reverted
        let investment = await investorsService.getAllInvestments()

    })
    it('Possible to create car after investment', async function () {
        await expect(
            await investorsService.connect(host).createCarInvestment(mockCarInvestment, "name", "sym")).to.not.reverted

        let fromUsd = await rentalityCurrencyConverter.getFromUsdLatest(ethToken, mockCarInvestment.priceInUsd)
        await expect(
            investorsService.connect(guest).invest(1, {value: fromUsd[0]})).to.not.reverted

        await expect(
            investorsService.connect(host).claimAndCreatePool(1)).to.not.reverted
        let cars = await rentalityGateway.getAllCars()
        expect(cars.length).to.be.eq(1)
    })

    it('Has claims after pool creating', async function () {
        await expect(
            await investorsService.connect(host).createCarInvestment(mockCarInvestment, "name", "sym")).to.not.reverted

        let fromUsd = await rentalityCurrencyConverter.getFromUsdLatest(ethToken, mockCarInvestment.priceInUsd)
        await expect(
            investorsService.connect(guest).invest(1, {value: fromUsd[0]})).to.not.reverted

        await expect(
            investorsService.connect(host).claimAndCreatePool(1)).to.not.reverted

        let claimsGuestCanDo = await investorsService.connect(guest).getMyInvestmentsToClaim()
        expect(claimsGuestCanDo.length).to.be.eq(1)
    })

    it('Happy case with investors car', async function () {
        await expect(
            await investorsService.connect(host).createCarInvestment(mockCarInvestment, "name", "sym")).to.not.reverted

        let fromUsd = await rentalityCurrencyConverter.getFromUsdLatest(ethToken, mockCarInvestment.priceInUsd)
        await expect(
            investorsService.connect(guest).invest(1, {value: fromUsd[0]})).to.not.reverted

        await expect(
            investorsService.connect(host).claimAndCreatePool(1)).to.not.reverted
        let cars = await rentalityGateway.getAllCars()
        expect(cars.length).to.be.eq(1)


        const oneDayInSeconds = 86400

        let result = await rentalityGateway.calculatePayments(1, 1, ethToken)

        await expect(
            await rentalityGateway.connect(guest).createTripRequest(
                {
                    carId: 1,
                    startDateTime: Date.now(),
                    endDateTime: Date.now() + oneDayInSeconds,
                    currencyType: ethToken,
                },
                {value: result[0]}
            )
        ).to.not.reverted

        await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
        await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
        await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
        await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [0, 0])).not.to.be.reverted
        await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted

        await expect(await rentalityGateway.connect(host).finishTrip(1)).to.not.reverted

        let claimsGuestCanDo = await investorsService.connect(guest).getMyInvestmentsToClaim()
        expect(claimsGuestCanDo.length).to.be.eq(1)

    })

    it('Investor can claim after income', async function () {
        await expect(
            await investorsService.connect(host).createCarInvestment(mockCarInvestment, "name", "sym")).to.not.reverted

        let fromUsd = await rentalityCurrencyConverter.getFromUsdLatest(ethToken, mockCarInvestment.priceInUsd)
        await expect(
            investorsService.connect(guest).invest(1, {value: fromUsd[0]})).to.not.reverted

        await expect(
            investorsService.connect(host).claimAndCreatePool(1)).to.not.reverted
        let cars = await rentalityGateway.getAllCars()
        expect(cars.length).to.be.eq(1)


        const oneDayInSeconds = 86400
        const request = getMockCarRequest(1)

        let result = await rentalityGateway.calculatePayments(1, 1, ethToken)

        await expect(
            await rentalityGateway.connect(guest).createTripRequest(
                {
                    carId: 1,
                    startDateTime: Date.now(),
                    endDateTime: Date.now() + oneDayInSeconds,
                    currencyType: ethToken,
                },
                {value: result[0]}
            )
        ).to.not.reverted

        await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
        await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
        await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
        await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [0, 0])).not.to.be.reverted
        await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted

        await expect(await rentalityGateway.connect(host).finishTrip(1)).to.not.reverted

        let claimsGuestCanDo = await investorsService.connect(guest).getMyInvestmentsToClaim()
        expect(claimsGuestCanDo.length).to.be.eq(1)

        console.log(claimsGuestCanDo)
        await expect(investorsService.connect(guest).claimAllMy(1)).to.changeEtherBalance(
            guest,9000000000000

        )

    })
    it('Calculation test: 1 investor has 2 investments', async function () {
        await expect(
            await investorsService.connect(host).createCarInvestment(mockCarInvestment, "name", "sym")).to.not.reverted

        let fromUsd = await rentalityCurrencyConverter.getFromUsdLatest(ethToken, mockCarInvestment.priceInUsd)
        await expect(
            investorsService.connect(guest).invest(1, {value: fromUsd[0]})).to.not.reverted

        await expect(
            investorsService.connect(host).claimAndCreatePool(1)).to.not.reverted
        let cars = await rentalityGateway.getAllCars()
        expect(cars.length).to.be.eq(1)


        const oneDayInSeconds = 86400

        let result = await rentalityGateway.calculatePayments(1, 1, ethToken)

        await expect(
            await rentalityGateway.connect(guest).createTripRequest(
                {
                    carId: 1,
                    startDateTime: Date.now(),
                    endDateTime: Date.now() + oneDayInSeconds,
                    currencyType: ethToken,
                },
                {value: result[0]}
            )
        ).to.not.reverted

        await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
        await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0], '', '')).not.to.be.reverted
        await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
        await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [0, 0])).not.to.be.reverted
        await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted

        await expect(await rentalityGateway.connect(host).finishTrip(1)).to.not.reverted


    // getFromUsdLatest

})
    })