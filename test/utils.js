const env = require('hardhat')
const { ethers } = require('hardhat')
const { Contract } = require('hardhat/internal/hardhat-network/stack-traces/model')
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
    const ETYPE = 1;
    const DISTANCE_INCLUDED = seedInt * 100 + 6
    const location = 'kyiv ukraine'
    const apiKey = process.env.GOOGLE_API_KEY || " "


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
        locationAddress: location,
        geoApiKey: apiKey,
    }
}


function getMockCarRequestWithEngineType(seed, engineParams, eType) {

    const seedStr = seed?.toString() ?? ''
    const seedInt = Number(seed) ?? 0

    const TOKEN_URI = 'TOKEN_URI' + seedStr
    const VIN_NUMBER = 'VIN_NUMBER' + seedStr
    const BRAND = 'BRAND' + seedStr
    const MODEL = 'MODEL' + seedStr
    const YEAR = '200' + seedStr
    const PRICE_PER_DAY = seedInt * 100 + 2
    const DEPOSIT = seedInt * 100 + 3
    const ENGINE_PARAMS = engineParams
    const ETYPE = eType;
    const DISTANCE_INCLUDED = seedInt * 100 + 6
    const location = 'kyiv ukraine'
    const apiKey = process.env.GOOGLE_API_KEY || " "


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
        locationAddress: location,
        geoApiKey: apiKey,
    }
}


function createMockClaimRequest(tripId, amountToClaim) {

    return {
        tripId: tripId,
        claimType: 1,
        description: "Some des",
        amountInUsdCents: amountToClaim

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
    Canceled: 7
};
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
    }
}



async function deployDefaultFixture() {
    const [owner, admin, manager, host, guest, anonymous] =
      await ethers.getSigners()

    const RentalityUtils = await ethers.getContractFactory('RentalityUtils')
    const utils = await RentalityUtils.deploy()
    const RentalityMockPriceFeed = await ethers.getContractFactory(
      'RentalityMockPriceFeed',
    )
    const RentalityUserService = await ethers.getContractFactory(
      'RentalityUserService',
    )
    const RentalityTripService = await ethers.getContractFactory(
      'RentalityTripService',
      { libraries: { RentalityUtils: utils.address } },
    )
    const RentalityCurrencyConverter = await ethers.getContractFactory(
      'RentalityCurrencyConverter',
    )
    const RentalityPaymentService = await ethers.getContractFactory(
      'RentalityPaymentService',
    )
    const RentalityCarToken =
      await ethers.getContractFactory('RentalityCarToken')

    const RentalityPlatform =
      await ethers.getContractFactory('RentalityPlatform',
        {
            libraries:
              {
                  RentalityUtils: utils.address,
              },
        })
    const RentalityGeoService =
      await ethers.getContractFactory('RentalityGeoMock')

    let RentalityGateway = await ethers.getContractFactory(
      'RentalityGateway',
      {
          libraries:
            {
                RentalityUtils: utils.address,
            },
      },
    )

    let rentalityMockPriceFeed = await RentalityMockPriceFeed.deploy(
      8,
      200000000000,
    )
    await rentalityMockPriceFeed.deployed()

    const rentalityUserService = await RentalityUserService.deploy()
    await rentalityUserService.deployed()

    const electricEngine = await ethers.getContractFactory('RentalityElectricEngine')
    const elEngine = await electricEngine.deploy(rentalityUserService.address)

    const patrolEngine = await ethers.getContractFactory('RentalityPatrolEngine')
    const pEngine = await patrolEngine.deploy(rentalityUserService.address)

    const hybridEngine = await ethers.getContractFactory('RentalityHybridEngine')
    const hEngine = await hybridEngine.deploy(rentalityUserService.address)

    const EngineService = await ethers.getContractFactory('RentalityEnginesService')
    const engineService = await EngineService.deploy(
      rentalityUserService.address,
      [pEngine.address, elEngine.address, hEngine.address]
    );
    await engineService.deployed();

    await rentalityUserService.connect(owner).grantAdminRole(admin.address)
    await rentalityUserService.connect(owner).grantManagerRole(manager.address)
    await rentalityUserService.connect(owner).grantHostRole(host.address)
    await rentalityUserService.connect(owner).grantGuestRole(guest.address)

    const rentalityCurrencyConverter = await RentalityCurrencyConverter.deploy(
      rentalityMockPriceFeed.address,
    )
    await rentalityCurrencyConverter.deployed()
    const rentalityGeoService = await RentalityGeoService.deploy()
    await rentalityGeoService.deployed()

    const rentalityCarToken = await RentalityCarToken.deploy(rentalityGeoService.address, engineService.address)
    await rentalityCarToken.deployed()
    const rentalityPaymentService = await RentalityPaymentService.deploy(rentalityUserService.address)
    await rentalityPaymentService.deployed()

    const rentalityTripService = await RentalityTripService.deploy(
      rentalityCurrencyConverter.address,
      rentalityCarToken.address,
      rentalityPaymentService.address,
      rentalityUserService.address,
      engineService.address
    )
    await rentalityTripService.deployed()

    const RentalityClaimService = await ethers.getContractFactory('RentalityClaimService')
    const claimService = await RentalityClaimService.deploy(rentalityUserService.address)
    await claimService.deployed()

    const rentalityPlatform = await RentalityPlatform.deploy(
      rentalityCarToken.address,
      rentalityCurrencyConverter.address,
      rentalityTripService.address,
      rentalityUserService.address,
      rentalityPaymentService.address,
      claimService.address,
    )
    await rentalityPlatform.deployed()

    await rentalityUserService
      .connect(owner)
      .grantHostRole(rentalityPlatform.address)
    await rentalityUserService.connect(owner).grantManagerRole(rentalityPlatform.address)
    await rentalityUserService
      .connect(owner)
      .grantManagerRole(rentalityTripService.address)
    await rentalityUserService.connect(owner).grantManagerRole(rentalityPlatform.address)

    let rentalityGateway = await RentalityGateway.connect(owner).deploy(
      rentalityCarToken.address,
      rentalityCurrencyConverter.address,
      rentalityTripService.address,
      rentalityUserService.address,
      rentalityPlatform.address,
      rentalityPaymentService.address,
    )
    await rentalityGateway.deployed()

    await rentalityUserService.connect(owner).grantManagerRole(rentalityGateway.address)
    await rentalityUserService.connect(owner).grantAdminRole(rentalityGateway.address)
    await rentalityUserService
      .connect(owner)
      .grantManagerRole(rentalityCarToken.address)
    await rentalityUserService
      .connect(owner)
      .grantManagerRole(engineService.address)

    return {
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
    }
}


module.exports = {
    getMockCarRequest,
    TripStatus,
    getEmptySearchCarParams,
    createMockClaimRequest,
    deployDefaultFixture
};