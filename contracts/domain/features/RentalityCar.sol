// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/asset/AssetBase.sol";
import "../base/asset/AssetTypes.sol";
import "../../rentality_old/Schemas.sol";

interface IRentalityCarUserService {
    function isRentalityPlatform(address user) external view returns (bool);
    function isAdmin(address user) external view returns (bool);
    function hasPassedKYCAndTC(address user) external view returns (bool);
    function isHost(address user) external view returns (bool);
    function grantHostRole(address user) external;
}

interface IRentalityCarEngineService {
    function verifyCreateParams(uint8 eType, uint64[] memory params) external view;
}

interface IRentalityCarGeoService {
    function createLocationInfo(Schemas.LocationInfo memory info) external returns (bytes32);
    function verifySignedLocationInfo(Schemas.SignedLocationInfo memory signed) external view;
}

struct RentalityCarData {
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

struct RentalityCarInfo {
    Asset asset;
    RentalityCarData car;
}

struct CreateRentalityCarRequest {
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
    Schemas.SignedLocationInfo locationInfo;
    bool currentlyListed;
}

struct UpdateRentalityCarRequest {
    UpdateAssetRequest asset;
    uint64 pricePerDayInUsdCents;
    uint64 securityDepositPerTripInUsdCents;
    uint64[] engineParams;
    uint64 milesIncludedPerDay;
    uint32 timeBufferBetweenTripsInSec;
    bool currentlyListed;
    uint8 engineType;
    Schemas.LocationInfo location;
    bool updateLocation;
}

contract RentalityCar is AssetBase {
    IRentalityCarGeoService public geoService;
    IRentalityCarEngineService public engineService;
    IRentalityCarUserService public userService;

    mapping(uint256 => RentalityCarData) internal cars;
    mapping(bytes32 => uint256) internal vinHashToAssetId;
    mapping(uint256 => uint256) internal listingMomentByAssetId;

    error UnsupportedGenericAssetCreation();
    error UnsupportedGenericAssetUpdate();
    error OnlyPlatform();
    error OnlyAdmin();
    error InvalidCarPrice();
    error InvalidMilesIncluded();
    error DuplicateVin(bytes32 vinHash);
    error UserDidNotPassKyc(address user);

    event RentalityCarCreated(uint256 indexed id, address indexed owner, string brand, string model);
    event RentalityCarUpdated(uint256 indexed id);

    modifier onlyPlatform() {
        if (!userService.isRentalityPlatform(msg.sender)) {
            revert OnlyPlatform();
        }
        _;
    }

    modifier onlyAdmin() {
        if (!(userService.isAdmin(msg.sender) || userService.isAdmin(tx.origin))) {
            revert OnlyAdmin();
        }
        _;
    }

    constructor(
        address geoServiceAddress,
        address engineServiceAddress,
        address userServiceAddress
    ) {
        geoService = IRentalityCarGeoService(geoServiceAddress);
        engineService = IRentalityCarEngineService(engineServiceAddress);
        userService = IRentalityCarUserService(userServiceAddress);
    }

    function createAsset(CreateAssetRequest calldata) external pure override returns (uint256) {
        revert UnsupportedGenericAssetCreation();
    }

    function updateAsset(uint256, UpdateAssetRequest calldata) external pure override {
        revert UnsupportedGenericAssetUpdate();
    }

    function createCar(CreateRentalityCarRequest calldata request, address user) external onlyPlatform returns (uint256) {
        if (!userService.hasPassedKYCAndTC(user)) {
            revert UserDidNotPassKyc(user);
        }
        if (request.pricePerDayInUsdCents == 0) {
            revert InvalidCarPrice();
        }
        if (request.milesIncludedPerDay == 0) {
            revert InvalidMilesIncluded();
        }

        bytes32 vinHash = keccak256(abi.encodePacked(request.carVinNumber));
        if (vinHashToAssetId[vinHash] != 0) {
            revert DuplicateVin(vinHash);
        }

        geoService.verifySignedLocationInfo(request.locationInfo);
        engineService.verifyCreateParams(request.engineType, request.engineParams);

        if (!userService.isHost(user)) {
            userService.grantHostRole(user);
        }

        string memory assetName = bytes(request.asset.name).length > 0
            ? request.asset.name
            : string.concat(request.brand, " ", request.model);

        uint256 id = _createAsset(user, assetName, request.asset.metadataURI);
        bytes32 locationHash = geoService.createLocationInfo(request.locationInfo.locationInfo);

        cars[id] = RentalityCarData({
            carVinNumber: request.carVinNumber,
            carVinNumberHash: vinHash,
            brand: request.brand,
            model: request.model,
            yearOfProduction: request.yearOfProduction,
            pricePerDayInUsdCents: request.pricePerDayInUsdCents,
            securityDepositPerTripInUsdCents: request.securityDepositPerTripInUsdCents,
            engineType: request.engineType,
            engineParams: request.engineParams,
            milesIncludedPerDay: request.milesIncludedPerDay,
            timeBufferBetweenTripsInSec: request.timeBufferBetweenTripsInSec,
            currentlyListed: request.currentlyListed,
            geoVerified: true,
            timeZoneId: request.locationInfo.locationInfo.timeZoneId,
            insuranceIncluded: false,
            locationHash: locationHash
        });

        vinHashToAssetId[vinHash] = id;
        if (request.currentlyListed) {
            listingMomentByAssetId[id] = block.timestamp;
        }

        emit RentalityCarCreated(id, user, request.brand, request.model);
        return id;
    }

    function updateCarInfo(
        uint256 id,
        UpdateRentalityCarRequest calldata request,
        address user
    ) external onlyPlatform assetExists(id) {
        _checkCanManageAsset(id, user);

        if (request.pricePerDayInUsdCents == 0) {
            revert InvalidCarPrice();
        }
        if (request.milesIncludedPerDay == 0) {
            revert InvalidMilesIncluded();
        }

        _updateAsset(id, request.asset.name, request.asset.metadataURI);

        if (request.updateLocation) {
            bytes32 locationHash = geoService.createLocationInfo(request.location);
            cars[id].geoVerified = true;
            cars[id].locationHash = locationHash;
            cars[id].timeZoneId = request.location.timeZoneId;
        }

        engineService.verifyCreateParams(request.engineType, request.engineParams);

        bool wasListed = cars[id].currentlyListed;

        cars[id].pricePerDayInUsdCents = request.pricePerDayInUsdCents;
        cars[id].securityDepositPerTripInUsdCents = request.securityDepositPerTripInUsdCents;
        cars[id].milesIncludedPerDay = request.milesIncludedPerDay;
        cars[id].engineParams = request.engineParams;
        cars[id].engineType = request.engineType;
        cars[id].timeBufferBetweenTripsInSec = request.timeBufferBetweenTripsInSec;
        cars[id].currentlyListed = request.currentlyListed;

        if (!wasListed && request.currentlyListed) {
            listingMomentByAssetId[id] = block.timestamp;
        }
        if (wasListed && !request.currentlyListed) {
            listingMomentByAssetId[id] = 0;
        }

        emit RentalityCarUpdated(id);
    }

    function getCar(uint256 id) external view assetExists(id) returns (RentalityCarInfo memory) {
        return RentalityCarInfo({asset: assets[id], car: cars[id]});
    }

    function getCarData(uint256 id) external view assetExists(id) returns (RentalityCarData memory) {
        return cars[id];
    }

    function isUniqueVinNumber(string memory carVinNumber) external view returns (bool) {
        return vinHashToAssetId[keccak256(abi.encodePacked(carVinNumber))] == 0;
    }

    function getListingMoment(uint256 id) external view returns (uint256) {
        if (!exists(id)) {
            return 0;
        }
        return listingMomentByAssetId[id];
    }

    function getAllCars() external view returns (RentalityCarInfo[] memory) {
        return _collectCars(address(0), false, false);
    }

    function getCarsOfOwner(address owner) external view returns (RentalityCarInfo[] memory) {
        return _collectCars(owner, true, false);
    }

    function getAvailableCarsForUser(address user) external view returns (RentalityCarInfo[] memory) {
        return _collectCars(user, false, true);
    }

    function verifySignedLocationInfo(Schemas.SignedLocationInfo memory locationInfo) external view {
        geoService.verifySignedLocationInfo(locationInfo);
    }

    function updateGeoServiceAddress(address geoServiceAddress) external onlyAdmin {
        geoService = IRentalityCarGeoService(geoServiceAddress);
    }

    function updateEngineServiceAddress(address engineServiceAddress) external onlyAdmin {
        engineService = IRentalityCarEngineService(engineServiceAddress);
    }

    function updateUserServiceAddress(address userServiceAddress) external onlyAdmin {
        userService = IRentalityCarUserService(userServiceAddress);
    }

    function _collectCars(
        address user,
        bool onlyOwnerCars,
        bool onlyAvailableForUser
    ) internal view returns (RentalityCarInfo[] memory) {
        uint256 count;

        for (uint256 i = 1; i <= nextAssetId; i++) {
            if (!exists(i)) {
                continue;
            }

            if (onlyOwnerCars && assets[i].owner != user) {
                continue;
            }

            if (onlyAvailableForUser && (!cars[i].currentlyListed || assets[i].owner == user)) {
                continue;
            }

            count++;
        }

        RentalityCarInfo[] memory result = new RentalityCarInfo[](count);
        uint256 index;

        for (uint256 i = 1; i <= nextAssetId; i++) {
            if (!exists(i)) {
                continue;
            }

            if (onlyOwnerCars && assets[i].owner != user) {
                continue;
            }

            if (onlyAvailableForUser && (!cars[i].currentlyListed || assets[i].owner == user)) {
                continue;
            }

            result[index++] = RentalityCarInfo({asset: assets[i], car: cars[i]});
        }

        return result;
    }
}
