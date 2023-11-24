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
    const TANK_VOLUME = seedInt * 100 + 4
    const FUEL_PRICE = seedInt * 100 + 5
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
        tankVolumeInGal: TANK_VOLUME,
        fuelPricePerGalInUsdCents: FUEL_PRICE,
        milesIncludedPerDay: DISTANCE_INCLUDED,
        locationAddress: location,
        geoApiKey: apiKey,
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

module.exports = {
    getMockCarRequest,
    TripStatus
};