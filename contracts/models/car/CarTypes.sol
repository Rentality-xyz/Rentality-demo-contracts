// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/asset/AssetTypes.sol";
import "../common/CommonTypes.sol";

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

