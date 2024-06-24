const {ethers, upgrades} = require('hardhat')
const {keccak256} = require('hardhat/internal/util/keccak')
const ethToken = ethers.getAddress('0x0000000000000000000000000000000000000000')

const signTCMessage = async (user) => {
    const message = keccak256(
        Buffer.from(
            'I have read and I agree with Terms of service, Cancellation policy, Prohibited uses and Privacy policy of Rentality.'
        )
    )
    return await user.signMessage(message)
}
const calculatePayments = async (currencyConverter, paymentService, value, tripDays, deposit, token = ethToken) => {
    let priceWithDiscount = await paymentService.calculateSumWithDiscount(
        '0x0000000000000000000000000000000000000000',
        tripDays,
        value
    )
    let [salesTaxes, govTaxes] = await paymentService.calculateTaxes(1, tripDays, priceWithDiscount)

    const [rate, decimals] = await currencyConverter.getCurrentRate(token)

    const rentPriceInEth = await currencyConverter.getFromUsd(
        token,
        priceWithDiscount + salesTaxes + govTaxes + BigInt(deposit),
        rate,
        decimals
    )
    const taxes = await currencyConverter.getFromUsd(token, salesTaxes + govTaxes, rate, decimals)

    const feeInUsdCents = await paymentService.getPlatformFeeFrom(priceWithDiscount)

    const rentalityFee = await currencyConverter.getFromUsd(token, feeInUsdCents, rate, decimals)

    return {
        rentPriceInEth,
        ethToCurrencyRate: rate,
        ethToCurrencyDecimals: decimals,
        rentalityFee,
        taxes,
    }
}

const calculatePaymentsFrom = async (currencyConverter, paymentService, value, tripDays, deposit, token) => {
    let priceWithDiscount = await paymentService.calculateSumWithDiscount(
        '0x0000000000000000000000000000000000000000',
        tripDays,
        value
    )
    let [salesTaxes, govTaxes] = await paymentService.calculateTaxes(1, tripDays, priceWithDiscount)
    const [rate, decimals] = await currencyConverter.getCurrentRate(token)

    const rentPriceInEth = await currencyConverter.getFromUsd(
        token,
        priceWithDiscount + salesTaxes + govTaxes + BigInt(deposit),
        rate,
        decimals
    )
    const taxes = await currencyConverter.getFromUsd(token, salesTaxes + govTaxes, rate, decimals)

    const feeInUsdCents = await paymentService.getPlatformFeeFrom(priceWithDiscount)

    const rentalityFee = await currencyConverter.getFromUsd(token, feeInUsdCents, rate, decimals)

    return {
        rentPrice: rentPriceInEth,
        currencyRate: rate,
        currencyDecimals: decimals,
        rentalityFee,
        taxes,
    }
}

function getMockCarRequest(seed) {
    const seedStr = seed?.toString() ?? ''
    const seedInt = Number(seed) ?? 0

    const TOKEN_URI = 'TOKEN_URI' + seedStr
    const VIN_NUMBER = 'VIN_NUMBER' + seedStr
    const BRAND = 'BRAND' + seedStr
    const MODEL = 'MODEL' + seedStr
    const YEAR = '200' + seedStr
    const PRICE_PER_DAY = seedInt * 100 + 2
    const DEPOSIT = seedInt * 100 + 3
    const ENGINE_PARAMS = [seedInt * 100 + 4, seedInt * 100 + 5]
    const ETYPE = 1
    const DISTANCE_INCLUDED = seedInt * 100 + 6
    const location = 'kyiv ukraine'
    const locationCoordinates = ' ' + seedInt
    const apiKey = process.env.GOOGLE_API_KEY || ' '
    const timeBufferBetweenTripsInSec = 0
    const locationLatitude = seedStr
    const locationLongitude = seedStr

    return {
        tokenUri: TOKEN_URI,
        carVinNumber: VIN_NUMBER,
        brand: BRAND,
        model: MODEL,
        yearOfProduction: YEAR,
        pricePerDayInUsdCents: PRICE_PER_DAY,
        securityDepositPerTripInUsdCents: DEPOSIT,
        engineParams: ENGINE_PARAMS,
        engineType: ETYPE,
        milesIncludedPerDay: DISTANCE_INCLUDED,
        timeBufferBetweenTripsInSec: timeBufferBetweenTripsInSec,
        locationAddress: location,
        locationLatitude,
        locationLongitude,
        geoApiKey: apiKey,
        insuranceIncluded: true,
    }
}

const locationInfo = {
    userAddress: 'Miami Riverwalk, Miami, Florida, USA',
    country: 'USA',
    state: 'Florida',
    city: 'Miami',
    latitude: '45.509248',
    longitude: '-122.682653',
    timeZoneId: 'id',
}

function getMockCarRequestWithAddress(seed, address) {
    let locationInfo2 = {...locationInfo, userAddress: address}
    return {...getMockCarRequest(seed), locationInfo: locationInfo2}
}

function getMockCarRequest(seed) {
    const seedStr = seed?.toString() ?? ''
    const seedInt = Number(seed) ?? 0

    const TOKEN_URI = 'TOKEN_URI' + seedStr
    const VIN_NUMBER = 'VIN_NUMBER' + seedStr
    const BRAND = 'BRAND' + seedStr
    const MODEL = 'MODEL' + seedStr
    const YEAR = '200' + seedStr
    const PRICE_PER_DAY = seedInt * 100 + 2
    const DEPOSIT = seedInt * 100 + 3
    const ENGINE_PARAMS = [seedInt * 100 + 4, seedInt * 100 + 5]
    const ETYPE = 1
    const DISTANCE_INCLUDED = seedInt * 100 + 6
    const location = 'Miami Riverwalk, Miami, Florida, USA'
    const locationCoordinates = ' ' + seedInt
    const apiKey = process.env.GOOGLE_API_KEY || ' '
    const timeBufferBetweenTripsInSec = 0
    const locationLatitude = seedStr
    const locationLongitude = seedStr

    return {
        tokenUri: TOKEN_URI,
        carVinNumber: VIN_NUMBER,
        brand: BRAND,
        model: MODEL,
        yearOfProduction: YEAR,
        pricePerDayInUsdCents: PRICE_PER_DAY,
        securityDepositPerTripInUsdCents: DEPOSIT,
        engineParams: ENGINE_PARAMS,
        engineType: ETYPE,
        milesIncludedPerDay: DISTANCE_INCLUDED,
        timeBufferBetweenTripsInSec: timeBufferBetweenTripsInSec,
        geoApiKey: apiKey,
        insuranceIncluded: true,
        locationInfo,
    }
}

function createMockClaimRequest(tripId, amountToClaim) {
    return {
        tripId: tripId,
        claimType: 1,
        description: 'Some des',
        amountInUsdCents: amountToClaim,
        photosUrl: '',
    }
}

const TripStatus = {
    Created: 0,
    Approved: 1,
    CheckedInByHost: 2,
    CheckedInByGuest: 3,
    CheckedOutByGuest: 4,
    CheckedOutByHost: 5,
    Finished: 6,
    Canceled: 7,
}

function getEmptySearchCarParams(seed) {
    return {
        country: '',
        state: '',
        city: '',
        brand: '',
        model: '',
        yearOfProductionFrom: 0,
        yearOfProductionTo: 0,
        pricePerDayInUsdCentsFrom: 0,
        pricePerDayInUsdCentsTo: 0,
        userLocation: locationInfo,
    }
}

async function deployDefaultFixture() {
    const [owner, admin, manager, host, guest, anonymous] = await ethers.getSigners()

    const chainId = (await owner.provider?.getNetwork())?.chainId ?? -1

    if (chainId !== 1337n) {
        console.log('Can be running only on localhost')
        process.exit(1)
    }

    const RentalityUtils = await ethers.getContractFactory('RentalityUtils')
    const utils = await RentalityUtils.deploy()

    const RentalityQuery = await ethers.getContractFactory('RentalityQuery')
    const query = await RentalityQuery.deploy()

    const RentalityMockPriceFeed = await ethers.getContractFactory('RentalityMockPriceFeed')
    const RentalityUserService = await ethers.getContractFactory('RentalityUserService')
    const RentalityTripService = await ethers.getContractFactory('RentalityTripService', {
        libraries: {
        },
    })

    const RentalityCurrencyConverter = await ethers.getContractFactory('RentalityCurrencyConverter')
    const RentalityPaymentService = await ethers.getContractFactory('RentalityPaymentService')
    const RentalityCarToken = await ethers.getContractFactory('RentalityCarToken', {
        libraries: {
            RentalityUtils: await utils.getAddress(),
        },
    })
    let TripsQuery = await ethers.getContractFactory('RentalityTripsQuery')
    let tripsQuery = await TripsQuery.deploy()

    const RentalityPlatform = await ethers.getContractFactory('RentalityPlatform', {
        libraries: {
            RentalityUtils: await utils.getAddress(),
            RentalityQuery: await query.getAddress(),
            RentalityTripsQuery: await tripsQuery.getAddress()

        },
    })
    const RentalityGeoService = await ethers.getContractFactory('RentalityGeoService')

    let RentalityGateway = await ethers.getContractFactory('RentalityGateway', {
        libraries: {
        },
    })

    let rentalityMockPriceFeed = await RentalityMockPriceFeed.deploy(8, 200000000000)
    await rentalityMockPriceFeed.waitForDeployment()

    let rentalityMockUsdtPriceFeed = await RentalityMockPriceFeed.deploy(6, 100)
    await rentalityMockPriceFeed.waitForDeployment()

    const MockCivic = await ethers.getContractFactory('CivicMockVerifier')
    const mockCivic = await MockCivic.deploy()
    await mockCivic.waitForDeployment()

    const rentalityUserService = await upgrades.deployProxy(RentalityUserService, [await mockCivic.getAddress(), 0])

    await rentalityUserService.waitForDeployment()

    const electricEngine = await ethers.getContractFactory('RentalityElectricEngine')
    const elEngine = await electricEngine.deploy(await rentalityUserService.getAddress())

    const patrolEngine = await ethers.getContractFactory('RentalityPatrolEngine')
    const pEngine = await patrolEngine.deploy(await rentalityUserService.getAddress())

    const hybridEngine = await ethers.getContractFactory('RentalityHybridEngine')
    const hEngine = await hybridEngine.deploy(await rentalityUserService.getAddress())

    const EngineService = await ethers.getContractFactory('RentalityEnginesService')
    const engineService = await upgrades.deployProxy(EngineService, [
        await rentalityUserService.getAddress(),
        [await pEngine.getAddress(), await elEngine.getAddress(), await hEngine.getAddress()],
    ])
    await engineService.waitForDeployment()

    await rentalityUserService.connect(owner).grantAdminRole(admin.address)
    await rentalityUserService.connect(owner).grantManagerRole(manager.address)
    await rentalityUserService.connect(owner).grantHostRole(host.address)
    await rentalityUserService.connect(owner).grantGuestRole(guest.address)

    const RentalityEth = await ethers.getContractFactory('RentalityETHConvertor')

    const ethContract = await upgrades.deployProxy(RentalityEth, [
        await rentalityUserService.getAddress(),
        ethToken,
        await rentalityMockPriceFeed.getAddress(),
    ])

    await ethContract.waitForDeployment()

    const TestUsdt = await ethers.getContractFactory('RentalityTestUSDT')
    const usdtContract = await TestUsdt.deploy()
    await usdtContract.waitForDeployment()

    const RentalityUSDT = await ethers.getContractFactory('RentalityUSDTConverter')

    const usdtPaymentContract = await upgrades.deployProxy(RentalityUSDT, [
        await rentalityUserService.getAddress(),
        await usdtContract.getAddress(),
        await rentalityMockUsdtPriceFeed.getAddress(),
    ])
    await usdtContract.waitForDeployment()

    const rentalityCurrencyConverter = await upgrades.deployProxy(RentalityCurrencyConverter, [
        await rentalityUserService.getAddress(),
        await ethContract.getAddress(),
    ])
    await rentalityCurrencyConverter.waitForDeployment()

    const GeoParserMock = await ethers.getContractFactory('RentalityGeoMock')
    const geoParserMock = await GeoParserMock.deploy()
    await geoParserMock.waitForDeployment()

    const rentalityGeoService = await upgrades.deployProxy(RentalityGeoService, [
        await rentalityUserService.getAddress(),
        await geoParserMock.getAddress(),
    ])
    await rentalityGeoService.waitForDeployment()
    await geoParserMock.setGeoService(await rentalityGeoService.getAddress())

    const rentalityCarToken = await upgrades.deployProxy(RentalityCarToken, [
        await rentalityGeoService.getAddress(),
        await engineService.getAddress(),
        await rentalityUserService.getAddress(),
    ])
    await rentalityCarToken.waitForDeployment()

    const RentalityFloridaTaxes = await ethers.getContractFactory('RentalityFloridaTaxes')

    const rentalityFloridaTaxes = await upgrades.deployProxy(RentalityFloridaTaxes, [
        await rentalityUserService.getAddress(),
    ])

    const RentalityBaseDiscount = await ethers.getContractFactory('RentalityBaseDiscount')

    const rentalityBaseDiscount = await upgrades.deployProxy(RentalityBaseDiscount, [
        await rentalityUserService.getAddress(),
    ])

    const rentalityPaymentService = await upgrades.deployProxy(RentalityPaymentService, [
        await rentalityUserService.getAddress(),
        await rentalityFloridaTaxes.getAddress(),
        await rentalityBaseDiscount.getAddress(),
    ])
    await rentalityPaymentService.waitForDeployment()

    const rentalityTripService = await upgrades.deployProxy(RentalityTripService, [
        await rentalityCurrencyConverter.getAddress(),
        await rentalityCarToken.getAddress(),
        await rentalityPaymentService.getAddress(),
        await rentalityUserService.getAddress(),
        await engineService.getAddress(),
    ])
    await rentalityTripService.waitForDeployment()

    const RentalityClaimService = await ethers.getContractFactory('RentalityClaimService')
    const claimService = await upgrades.deployProxy(RentalityClaimService, [await rentalityUserService.getAddress()])
    await claimService.waitForDeployment()

    const RealMath = await ethers.getContractFactory('RealMath')
    const realMath = await RealMath.deploy()

    const DeliveryService = await ethers.getContractFactory('RentalityCarDelivery', {
        libraries: {
            RealMath: await realMath.getAddress(),
            RentalityUtils: await utils.getAddress(),
        },
    })
    const deliveryService = await upgrades.deployProxy(DeliveryService, [await rentalityUserService.getAddress()])

    let RentalityView = await ethers.getContractFactory('RentalityView',{
        libraries:{
            RentalityUtils: await utils.getAddress(),
            RentalityQuery: await query.getAddress(),
            RentalityTripsQuery: await tripsQuery.getAddress()
        }
    });
    const rentalityView = await upgrades.deployProxy(RentalityView, [
        await rentalityCarToken.getAddress(),
        await rentalityCurrencyConverter.getAddress(),
        await rentalityTripService.getAddress(),
        await rentalityUserService.getAddress(),
        await rentalityPaymentService.getAddress(),
        await claimService.getAddress(),
        await deliveryService.getAddress(),
    ])
    await rentalityView.waitForDeployment()


    const rentalityPlatform = await upgrades.deployProxy(RentalityPlatform, [
        await rentalityCarToken.getAddress(),
        await rentalityCurrencyConverter.getAddress(),
        await rentalityTripService.getAddress(),
        await rentalityUserService.getAddress(),
        await rentalityPaymentService.getAddress(),
        await claimService.getAddress(),
        await deliveryService.getAddress(),
        await rentalityView.getAddress()
    ])
    await rentalityPlatform.waitForDeployment()

    const RentalityAdminGateway = await ethers.getContractFactory('RentalityAdminGateway')
    const rentalityAdminGateway = await upgrades.deployProxy(RentalityAdminGateway, [
        await rentalityCarToken.getAddress(),
        await rentalityCurrencyConverter.getAddress(),
        await rentalityTripService.getAddress(),
        await rentalityUserService.getAddress(),
        await rentalityPlatform.getAddress(),
        await rentalityPaymentService.getAddress(),
        await claimService.getAddress(),
        await deliveryService.getAddress(),
        await rentalityView.getAddress()
    ])
    await rentalityAdminGateway.waitForDeployment()

    await rentalityUserService.connect(owner).grantHostRole(await rentalityPlatform.getAddress())

    await rentalityUserService.connect(owner).grantManagerRole(await rentalityPlatform.getAddress())

    await rentalityUserService.connect(owner).grantManagerRole(await rentalityTripService.getAddress())

    await rentalityUserService.connect(owner).grantManagerRole(await rentalityPlatform.getAddress())

    let rentalityGateway = await upgrades.deployProxy(RentalityGateway.connect(owner), [
        await rentalityCarToken.getAddress(),
        await rentalityCurrencyConverter.getAddress(),
        await rentalityTripService.getAddress(),
        await rentalityUserService.getAddress(),
        await rentalityPlatform.getAddress(),
        await rentalityPaymentService.getAddress(),
        await claimService.getAddress(),
        await rentalityAdminGateway.getAddress(),
        await deliveryService.getAddress(),
        await rentalityView.getAddress()
    ])
    await rentalityGateway.waitForDeployment()

    rentalityGateway = await ethers.getContractAt('IRentalityGateway', await rentalityGateway.getAddress())

    await rentalityUserService.connect(owner).grantManagerRole(await rentalityAdminGateway.getAddress())
    await rentalityUserService.connect(owner).grantManagerRole(await rentalityGateway.getAddress())
    await rentalityUserService.connect(owner).grantAdminRole(await rentalityGateway.getAddress())
    await rentalityUserService.connect(owner).grantAdminRole(await rentalityAdminGateway.getAddress())
    await rentalityUserService.connect(owner).grantManagerRole(await rentalityCarToken.getAddress())
    await rentalityUserService.connect(owner).grantManagerRole(await engineService.getAddress())
    await rentalityUserService.connect(owner).grantManagerRole(await rentalityPaymentService.getAddress())

    const hostSignature = await signTCMessage(host)
    const guestSignature = await signTCMessage(guest)
    await rentalityGateway.connect(host).setKYCInfo(' ', ' ', ' ', ' ', ' ', 1, hostSignature)
    await rentalityGateway.connect(guest).setKYCInfo(' ', ' ', ' ', ' ', ' ', 1, guestSignature)

    await rentalityCurrencyConverter.addCurrencyType(
        await usdtContract.getAddress(),
        await usdtPaymentContract.getAddress()
    )

    return {
        rentalityGateway,
        rentalityMockPriceFeed,
        rentalityUserService,
        rentalityTripService,
        rentalityCurrencyConverter,
        rentalityCarToken,
        rentalityPaymentService,
        rentalityPlatform,
        rentalityAdminGateway,
        deliveryService,
        utils,
        query,
        engineService,
        elEngine,
        pEngine,
        hEngine,
        owner,
        admin,
        manager,
        host,
        guest,
        anonymous,
        usdtContract,
        geoParserMock,
        rentalityFloridaTaxes,
        rentalityBaseDiscount,
        rentalityGeoService,
    }
}

module.exports = {
    getMockCarRequest,
    getEmptySearchCarParams,
    createMockClaimRequest,
    deployDefaultFixture,
    TripStatus,
    ethToken,
    getMockCarRequestWithAddress,
    calculatePayments,
    calculatePaymentsFrom,
    signTCMessage,
    locationInfo,
}
