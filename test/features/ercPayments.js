const {loadFixture} = require('@nomicfoundation/hardhat-network-helpers')
const {deployDefaultFixture, getMockCarRequest, createMockClaimRequest, nativeToken} = require('../utils')
const {expect} = require('chai')
const {ethers, network} = require('hardhat')


async function mintTo(contract, address, amount) {
    await expect(contract.mint(address, amount * 10 ** 6)).to.not.be.reverted;
}

describe.only('ERC20 payments', function () {
    let rentalityGateway,
        rentalityCurrencyConverter,
        rentalityPlatform,
        usdtContract,
        owner,
        guest,
        host,
        rentalityAdminGateway
            =

            beforeEach(async function () {
                ;({
                    rentalityGateway,
                    rentalityCurrencyConverter,
                    rentalityPlatform,
                    usdtContract,
                    owner,
                    guest,
                    host,
                    rentalityAdminGateway

                } = await loadFixture(deployDefaultFixture))
            })
    it('Should correctly сreate trip and pay deposit with usdt', async function () {

        let usdt = await usdtContract.getAddress();
        await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
        const rentPriceInUsdCents = 1000

        const [rentPriceInUsdt, rate, decimals] =
            await rentalityCurrencyConverter.getFromUsdLatest(await usdtContract.getAddress(), rentPriceInUsdCents)
        await mintTo(usdtContract, guest.address, 1000);
        const balanceBeforeTrip = await usdtContract.balanceOf(guest);


        await usdtContract.connect(guest).approve(await rentalityPlatform.getAddress(), rentPriceInUsdt);


        await expect(
            rentalityGateway.connect(guest).createTripRequest(
                {
                    carId: 1,
                    host: owner.address,
                    startDateTime: 1,
                    endDateTime: 1,
                    startLocation: '',
                    endLocation: '',
                    totalDayPriceInUsdCents: rentPriceInUsdCents,
                    taxPriceInUsdCents: 0,
                    depositInUsdCents: 0,
                    currencyRate: rate,
                    currencyDecimals: decimals,
                    currencyType: usdt
                },
            )
        ).to.not.reverted


        const balanceAfterTrip = await usdtContract.balanceOf(guest.address);

        const rentalityPlatformBalance = await usdtContract.balanceOf(await rentalityPlatform.getAddress());

        expect(balanceAfterTrip + rentPriceInUsdt).to.be.eq(balanceBeforeTrip);
        expect(rentalityPlatformBalance).to.be.eq(rentPriceInUsdt)

    })

    it('should correctly finish trip with usdt, and send tokens to the host', async function () {

        let usdt = await usdtContract.getAddress();
        await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
        const rentPriceInUsdCents = 1000

        const [rentPriceInUsdt, rate, decimals] =
            await rentalityCurrencyConverter.getFromUsdLatest(await usdtContract.getAddress(), rentPriceInUsdCents)
        await mintTo(usdtContract, guest.address, 1000);

        const guestBalanceBeforeTrip = await usdtContract.balanceOf(guest.address);
        const hostBalanceBeforeTrip = await usdtContract.balanceOf(host.address);

        await usdtContract.connect(guest).approve(await rentalityPlatform.getAddress(), rentPriceInUsdt);


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
                    currencyRate: rate,
                    currencyDecimals: decimals,
                    currencyType: usdt
                },
            )
        ).to.not.reverted

        await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
        await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0])).not.to.be.reverted
        await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
        await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [0, 0])).not.to.be.reverted
        await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted

        const platformFee = rentPriceInUsdt * await rentalityGateway.getPlatformFeeInPPM() / BigInt(1_000_000);
        const returnToHost =
            rentPriceInUsdt - platformFee

        await expect(rentalityGateway.connect(host).finishTrip(1)).to.not.reverted

        const guestBalanceAfterTrip = await usdtContract.balanceOf(guest.address)
        const hostBalanceAfterTrip = await usdtContract.balanceOf(host.address);

        const platformBalance = await usdtContract.balanceOf(await rentalityPlatform.getAddress());

        expect(guestBalanceAfterTrip).to.be.eq(guestBalanceBeforeTrip - rentPriceInUsdt)
        expect(hostBalanceAfterTrip).to.be.eq(hostBalanceBeforeTrip + returnToHost)
        expect(platformBalance).to.be.eq(platformFee)

    })

    it('should not be able to create trip with wrong currency type', async function () {

        let usdt = await usdtContract.getAddress();
        await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
        const rentPriceInUsdCents = 1000

        const [rentPriceInUsdt, rate, decimals] =
            await rentalityCurrencyConverter.getFromUsdLatest(await usdtContract.getAddress(), rentPriceInUsdCents)
        await mintTo(usdtContract, guest.address, 1000);

        await usdtContract.connect(guest).approve(await rentalityPlatform.getAddress(), rentPriceInUsdt);


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
                    currencyRate: rate,
                    currencyDecimals: decimals,
                    currencyType: await rentalityPlatform.getAddress()
                },
            )
        ).to.be.revertedWith('Token is not available.')


    })

    it('should correctly pay claim with usdt', async function () {

        let usdt = await usdtContract.getAddress();
        await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
        const rentPriceInUsdCents = 1000

        const [rentPriceInUsdt, rate, decimals] =
            await rentalityCurrencyConverter.getFromUsdLatest(await usdtContract.getAddress(), rentPriceInUsdCents)
        await mintTo(usdtContract, guest.address, 10000);

        await usdtContract.connect(guest).approve(await rentalityPlatform.getAddress(), rentPriceInUsdt);


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
                    currencyRate: rate,
                    currencyDecimals: decimals,
                    currencyType: usdt
                },
            )
        ).to.not.reverted

        await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted

        const amountToPayForClaim = 1000

        const [claimPriceInUsdt, ,] =
            await rentalityCurrencyConverter.getFromUsdLatest(await usdtContract.getAddress(), amountToPayForClaim)

        await usdtContract.connect(guest).approve(await rentalityPlatform.getAddress(), claimPriceInUsdt);
        await expect(rentalityGateway.connect(host).createClaim(createMockClaimRequest(1, amountToPayForClaim))).not.to.be.reverted
        const hostBalanceBeforeClaim = await usdtContract.balanceOf(host.address);
        const guestBalanceBeforeClaim = await usdtContract.balanceOf(guest.address);

        await expect(rentalityGateway.connect(guest).payClaim(1)).to.not.reverted

        const hostBalanceAfterClaim = await usdtContract.balanceOf(host.address);
        const guestBalanceAfterClaim = await usdtContract.balanceOf(guest.address);

        expect(hostBalanceAfterClaim).to.be.eq(hostBalanceBeforeClaim + claimPriceInUsdt)
        expect(guestBalanceAfterClaim).to.be.eq(guestBalanceBeforeClaim - claimPriceInUsdt)

    })
    it('should be able withdraw usdt from platform ', async function () {

        let usdt = await usdtContract.getAddress();
        await expect(rentalityGateway.connect(host).addCar(getMockCarRequest(0))).not.to.be.reverted
        const rentPriceInUsdCents = 1000

        const [rentPriceInUsdt, rate, decimals] =
            await rentalityCurrencyConverter.getFromUsdLatest(await usdtContract.getAddress(), rentPriceInUsdCents)
        await mintTo(usdtContract, guest.address, 1000);


        await usdtContract.connect(guest).approve(await rentalityPlatform.getAddress(), rentPriceInUsdt);


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
                    currencyRate: rate,
                    currencyDecimals: decimals,
                    currencyType: usdt
                },
            )
        ).to.not.reverted

        await expect(rentalityGateway.connect(host).approveTripRequest(1)).not.to.be.reverted
        await expect(rentalityGateway.connect(host).checkInByHost(1, [0, 0])).not.to.be.reverted
        await expect(rentalityGateway.connect(guest).checkInByGuest(1, [0, 0])).not.to.be.reverted
        await expect(rentalityGateway.connect(guest).checkOutByGuest(1, [0, 0])).not.to.be.reverted
        await expect(rentalityGateway.connect(host).checkOutByHost(1, [0, 0])).not.to.be.reverted


        await expect(rentalityGateway.connect(host).finishTrip(1)).to.not.reverted

        await expect(rentalityAdminGateway.connect(host).withdrawAllFromPlatform(usdt)).to.not.reverted

        const ownerBalance = await usdtContract.balanceOf(owner);
        expect(ownerBalance).to.be.gt(0)

    })

})
