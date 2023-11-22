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
    const COUNTRY = 'COUNTRY' + seedStr
    const STATE = 'STATE' + seedStr
    const CITY = 'CITY' + seedStr
    const LOCATION_LATITUDE = seedInt * 100 + 7
    const LOCATION_LONGITUDE = seedInt * 100 + 8

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
        country: COUNTRY,
        state: STATE,
        city: CITY,
        locationLatitudeInPPM: LOCATION_LATITUDE,
        locationLongitudeInPPM: LOCATION_LONGITUDE,
    }
}

module.exports = {
    getMockCarRequest,
};