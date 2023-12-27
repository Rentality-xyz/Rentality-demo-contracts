const env = require('hardhat')

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

module.exports = {
    getMockCarRequest,
    TripStatus,
    getEmptySearchCarParams,
    createMockClaimRequest
};