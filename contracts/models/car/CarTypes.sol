pragma solidity ^0.8.20;

import "../base/asset/AssetTypes.sol";
import "../common/CommonTypes.sol";
import "../pricing/RentalPricingTypes.sol";

enum CarUpdateStatus {
    Add,
    Update,
    Burn
}

struct CarData {
    string carVinNumber;
    bytes32 carVinNumberHash;
    string brand;
    string model;
    uint32 yearOfProduction;
    uint64 pricePerDayInUsdCents;
    uint64 securityDepositPerTripInUsdCents;
    uint8 engineType;
    uint64[] engineParams;
    uint64 milesIncludedPerDay;
    uint32 timeBufferBetweenTripsInSec;
    bool currentlyListed;
    bool geoVerified;
    string timeZoneId;
    bool insuranceIncluded;
    bytes32 locationHash;
}

struct CarInfo {
    Asset asset;
    CarData car;
}

struct CarInsuranceInfo {
    bool required;
    uint256 priceInUsdCents;
}

struct DeliveryPrices {
    uint64 underTwentyFiveMilesInUsdCents;
    uint64 aboveTwentyFiveMilesInUsdCents;
    bool initialized;
}

struct CarInfoWithInsurance {
    CarInfo carInfo;
    CarInsuranceInfo insuranceInfo;
    string carMetadataURI;
}

struct CarFilterInfo {
    uint64 maxCarPrice;
    uint256 minCarYearOfProduction;
}

struct CarDetails {
    uint256 carId;
    string hostName;
    string hostPhotoUrl;
    address host;
    string brand;
    string model;
    uint32 yearOfProduction;
    uint64 pricePerDayInUsdCents;
    uint64 securityDepositPerTripInUsdCents;
    uint64 milesIncludedPerDay;
    uint8 engineType;
    uint64[] engineParams;
    bool geoVerified;
    bool currentlyListed;
    LocationInfo locationInfo;
    string carVinNumber;
    string carMetadataURI;
    uint256 dimoTokenId;
}

struct AdminCarInfo {
    CarDetails car;
    string carMetadataURI;
}

struct AllCarsInfo {
    AdminCarInfo[] cars;
    uint256 totalPageCount;
}

struct AvailableCarInfo {
    uint256 carId;
    string brand;
    string model;
    uint32 yearOfProduction;
    uint64 pricePerDayInUsdCents;
    uint64 pricePerDayWithDiscount;
    uint64 tripDays;
    uint64 totalPriceWithDiscount;
    uint64 securityDepositPerTripInUsdCents;
    uint8 engineType;
    uint64 milesIncludedPerDay;
    address host;
    string hostName;
    string hostPhotoUrl;
    string metadataURI;
    uint64 underTwentyFiveMilesInUsdCents;
    uint64 aboveTwentyFiveMilesInUsdCents;
    uint64 pickUp;
    uint64 dropOf;
    bool insuranceIncluded;
    LocationInfo locationInfo;
    CarInsuranceInfo insuranceInfo;
    uint256 fuelPrice;
    RentalBaseDiscount carDiscounts;
    int128 distance;
    bool isGuestHasInsurance;
    uint256 dimoTokenId;
    RentalTaxValue[] taxes;
    uint64 totalTax;
    UserCurrencyInfo hostCurrency;
}

struct SearchCarInfo {
    uint256 carId;
    string brand;
    string model;
    uint32 yearOfProduction;
    uint64 pricePerDayInUsdCents;
    uint64 pricePerDayWithDiscount;
    uint64 tripDays;
    uint64 totalPriceWithDiscount;
    uint64 taxes;
    uint64 securityDepositPerTripInUsdCents;
    uint8 engineType;
    uint64 milesIncludedPerDay;
    address host;
    string hostName;
    string hostPhotoUrl;
    string metadataURI;
    uint64 underTwentyFiveMilesInUsdCents;
    uint64 aboveTwentyFiveMilesInUsdCents;
    uint64 pickUp;
    uint64 dropOf;
    bool insuranceIncluded;
    LocationInfo locationInfo;
    CarInsuranceInfo insuranceInfo;
    bool isGuestHasInsurance;
    uint256 dimoTokenId;
    UserCurrencyInfo hostCurrency;
    uint256 fuelPrice;
    RentalBaseDiscount carDiscounts;
    RentalTaxValue[] taxesInfo;
    uint64[] engineParams;
}

struct SearchCarWithDistanceInfo {
    SearchCarInfo car;
    int256 distance;
}

struct SearchCarsWithDistanceInfo {
    SearchCarWithDistanceInfo[] cars;
    uint256 totalCarsSupply;
}

struct PublicHostCarInfo {
    uint256 carId;
    string metadataURI;
    string brand;
    string model;
    uint32 yearOfProduction;
    uint64 pricePerDayInUsdCents;
    uint64 securityDepositPerTripInUsdCents;
    uint64 milesIncludedPerDay;
    bool currentlyListed;
}

struct CarSearchParams {
    string country;
    string state;
    string city;
    string brand;
    string model;
    uint32 yearOfProductionFrom;
    uint32 yearOfProductionTo;
    uint64 pricePerDayInUsdCentsFrom;
    uint64 pricePerDayInUsdCentsTo;
    LocationInfo userLocation;
}

struct CarAvailabilityContext {
    address tripQuery;
    address userProfileQuery;
    address pricingService;
    address insuranceService;
    address dimoService;
    address geoService;
    address currencyConverter;
    address carTaxAdapter;
}

struct CreateCarRequest {
    CreateAssetRequest asset;
    string carVinNumber;
    string brand;
    string model;
    uint32 yearOfProduction;
    uint64 pricePerDayInUsdCents;
    uint64 securityDepositPerTripInUsdCents;
    uint64[] engineParams;
    uint8 engineType;
    uint64 milesIncludedPerDay;
    uint32 timeBufferBetweenTripsInSec;
    SignedLocationInfo locationInfo;
    bool currentlyListed;
}

struct UpdateCarRequest {
    UpdateAssetRequest asset;
    uint64 pricePerDayInUsdCents;
    uint64 securityDepositPerTripInUsdCents;
    uint64[] engineParams;
    uint64 milesIncludedPerDay;
    uint32 timeBufferBetweenTripsInSec;
    bool currentlyListed;
    uint8 engineType;
    LocationInfo location;
    bool updateLocation;
}

