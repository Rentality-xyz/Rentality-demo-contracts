// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../models/common/CommonTypes.sol";
import "../../models/base/asset/AssetTypes.sol";
import "../../models/car/CarMain.sol";
import "../../models/car/CarTypes.sol";
import "../../models/car/CarQuery.sol";
import "./ICarGateway.sol";
import "../Schemas.sol";
import "../abstract/IRentalityGeoService.sol";

contract CarGatewayAdapter is ICarGateway {
    CarMain public immutable carMain;
    CarQuery public immutable carQuery;

    constructor(address carMainAddress, address carQueryAddress) {
        carMain = CarMain(carMainAddress);
        carQuery = CarQuery(carQueryAddress);
    }

    function updateEventServiceAddress(address eventEmitterAddress) public {
        carMain.updateEventEmitterAddress(eventEmitterAddress);
    }

    function updateEngineServiceAddress(address engineValidatorAddress) public {
        carMain.updateEngineValidatorAddress(engineValidatorAddress);
    }

    function getGeoServiceAddress() public view returns (address) {
        return carMain.getGeoVerifierAddress();
    }

    function tokenURI(uint256 carId) public view returns (string memory) {
        return carMain.tokenURI(carId);
    }

    function updateGeoServiceAddress(address geoVerifierAddress) public {
        carMain.updateGeoVerifierAddress(geoVerifierAddress);
    }

    function getEngineService() public view returns (address) {
        return carMain.getEngineValidatorAddress();
    }

    function totalSupply() public view returns (uint256) {
        return carMain.totalSupply();
    }

    function getCarInfoById(uint256 carId) public view returns (Schemas.CarInfo memory) {
        if (!carMain.exists(carId)) {
            Schemas.CarInfo memory empty;
            return empty;
        }

        return _toLegacyCarInfo(carMain.getAsset(carId), carMain.getCarData(carId));
    }

    function getCarsOfHost(address host) public view returns (Schemas.PublicHostCarDTO[] memory) {
        CarInfo[] memory cars = carQuery.getCarsOfOwner(host);
        Schemas.PublicHostCarDTO[] memory result = new Schemas.PublicHostCarDTO[](cars.length);

        for (uint256 i = 0; i < cars.length; i++) {
            result[i] = Schemas.PublicHostCarDTO({
                carId: cars[i].asset.id,
                metadataURI: cars[i].asset.metadataURI,
                brand: cars[i].car.brand,
                model: cars[i].car.model,
                yearOfProduction: cars[i].car.yearOfProduction,
                pricePerDayInUsdCents: cars[i].car.pricePerDayInUsdCents,
                securityDepositPerTripInUsdCents: cars[i].car.securityDepositPerTripInUsdCents,
                milesIncludedPerDay: cars[i].car.milesIncludedPerDay,
                currentlyListed: cars[i].car.currentlyListed
            });
        }

        return result;
    }

    function isUniqueVinNumber(string memory carVinNumber) public view returns (bool) {
        return carMain.isUniqueVinNumber(carVinNumber);
    }

    function addCar(Schemas.CreateCarRequest memory request, address user) public returns (uint256) {
        CreateCarRequest memory createRequest = CreateCarRequest({
            asset: CreateAssetRequest({name: "", metadataURI: request.tokenUri}),
            carVinNumber: request.carVinNumber,
            brand: request.brand,
            model: request.model,
            yearOfProduction: request.yearOfProduction,
            pricePerDayInUsdCents: request.pricePerDayInUsdCents,
            securityDepositPerTripInUsdCents: request.securityDepositPerTripInUsdCents,
            engineParams: request.engineParams,
            engineType: request.engineType,
            milesIncludedPerDay: request.milesIncludedPerDay,
            timeBufferBetweenTripsInSec: request.timeBufferBetweenTripsInSec,
            locationInfo: _toCommonSignedLocationInfo(request.locationInfo),
            currentlyListed: request.currentlyListed
        });

        return carMain.createCar(createRequest, user);
    }

    function updateCarInfo(
        Schemas.UpdateCarInfoRequest memory request,
        Schemas.LocationInfo memory location,
        bool updateLocation,
        address user
    ) public {
        Asset memory asset = carMain.getAsset(request.carId);

        UpdateCarRequest memory updateRequest = UpdateCarRequest({
            asset: UpdateAssetRequest({
                name: asset.name,
                metadataURI: bytes(request.tokenUri).length == 0 ? asset.metadataURI : request.tokenUri
            }),
            pricePerDayInUsdCents: request.pricePerDayInUsdCents,
            securityDepositPerTripInUsdCents: request.securityDepositPerTripInUsdCents,
            engineParams: request.engineParams,
            milesIncludedPerDay: request.milesIncludedPerDay,
            timeBufferBetweenTripsInSec: request.timeBufferBetweenTripsInSec,
            currentlyListed: request.currentlyListed,
            engineType: request.engineType,
            location: _toCommonLocationInfo(location),
            updateLocation: updateLocation
        });

        carMain.updateCar(request.carId, updateRequest, user);
    }

    function getListingMoment(uint256 carId) public view returns (uint256) {
        return carMain.getListingMoment(carId);
    }

    function updateCarTokenUri(uint256 carId, string memory tokenUri, address user) public {
        carMain.updateCarTokenUri(carId, tokenUri, user);
    }

    function burnCar(uint256 carId) public {
        carMain.burnCar(carId);
    }

    function getAllCars() public view returns (Schemas.CarInfo[] memory) {
        CarInfo[] memory cars = carQuery.getAllCars();
        Schemas.CarInfo[] memory result = new Schemas.CarInfo[](cars.length);

        for (uint256 i = 0; i < cars.length; i++) {
            result[i] = _toLegacyCarInfo(cars[i].asset, cars[i].car);
        }

        return result;
    }

    function getAvailableCarsForUser(address user) public view returns (Schemas.CarInfo[] memory) {
        CarInfo[] memory cars = carQuery.getAvailableCarsForUser(user);
        Schemas.CarInfo[] memory result = new Schemas.CarInfo[](cars.length);

        for (uint256 i = 0; i < cars.length; i++) {
            result[i] = _toLegacyCarInfo(cars[i].asset, cars[i].car);
        }

        return result;
    }

    function isCarAvailableForUser(
        uint256 carId,
        address sender,
        Schemas.SearchCarParams memory searchCarParams
    ) public view returns (bool) {
        if (!exists(carId)) {
            return false;
        }

        Schemas.CarInfo memory car = getCarInfoById(carId);
        if (!car.currentlyListed || ownerOf(carId) == sender) {
            return false;
        }

        IRentalityGeoService geoService = IRentalityGeoService(getGeoServiceAddress());

        return
            (bytes(searchCarParams.brand).length == 0 || _containWord(_toLower(car.brand), _toLower(searchCarParams.brand))) &&
            (bytes(searchCarParams.model).length == 0 || _containWord(_toLower(car.model), _toLower(searchCarParams.model))) &&
            (bytes(searchCarParams.country).length == 0 ||
                _compareStrings(_toLower(geoService.getCarCountry(car.locationHash)), _toLower(searchCarParams.country))) &&
            (bytes(searchCarParams.state).length == 0 ||
                _compareStrings(_toLower(geoService.getCarState(car.locationHash)), _toLower(searchCarParams.state))) &&
            (bytes(searchCarParams.city).length == 0 ||
                _compareStrings(_toLower(geoService.getCarCity(car.locationHash)), _toLower(searchCarParams.city))) &&
            (searchCarParams.yearOfProductionFrom == 0 || car.yearOfProduction >= searchCarParams.yearOfProductionFrom) &&
            (searchCarParams.yearOfProductionTo == 0 || car.yearOfProduction <= searchCarParams.yearOfProductionTo) &&
            (searchCarParams.pricePerDayInUsdCentsFrom == 0 ||
                car.pricePerDayInUsdCents >= searchCarParams.pricePerDayInUsdCentsFrom) &&
            (searchCarParams.pricePerDayInUsdCentsTo == 0 ||
                car.pricePerDayInUsdCents <= searchCarParams.pricePerDayInUsdCentsTo);
    }

    function fetchAvailableCarsForUser(
        address user,
        Schemas.SearchCarParams memory searchCarParams,
        uint256 from,
        uint256 to
    ) public view returns (Schemas.CarInfo[] memory) {
        uint256 total = totalSupply();
        if (from > total) from = 0;
        if (to > total) to = total;

        uint256[] memory temp = new uint256[](to - from);
        uint256 itemCount;

        for (uint256 i = from; i < to; i++) {
            uint256 currentId = i + 1;
            if (isCarAvailableForUser(currentId, user, searchCarParams)) {
                temp[itemCount++] = currentId;
            }
        }

        Schemas.CarInfo[] memory result = new Schemas.CarInfo[](itemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            result[i] = getCarInfoById(temp[i]);
        }

        return result;
    }

    function ownerOf(uint256 carId) public view returns (address) {
        if (!exists(carId)) {
            return address(0);
        }

        return carMain.getOwner(carId);
    }

    function exists(uint256 carId) public view returns (bool) {
        return carMain.exists(carId);
    }

    function getCarsOwnedByUser(address user) public view returns (Schemas.CarInfo[] memory) {
        CarInfo[] memory cars = carQuery.getCarsOfOwner(user);
        Schemas.CarInfo[] memory result = new Schemas.CarInfo[](cars.length);

        for (uint256 i = 0; i < cars.length; i++) {
            result[i] = _toLegacyCarInfo(cars[i].asset, cars[i].car);
        }

        return result;
    }

    function verifySignedLocationInfo(Schemas.SignedLocationInfo memory locationInfo) public view {
        carMain.verifySignedLocationInfo(_toCommonSignedLocationInfo(locationInfo));
    }

    function balanceOf(address owner) public view returns (uint256) {
        return carMain.balanceOf(owner);
    }

    function _toLegacyCarInfo(Asset memory asset, CarData memory car) internal pure returns (Schemas.CarInfo memory) {
        return Schemas.CarInfo({
            carId: asset.id,
            carVinNumber: car.carVinNumber,
            carVinNumberHash: car.carVinNumberHash,
            createdBy: asset.owner,
            brand: car.brand,
            model: car.model,
            yearOfProduction: car.yearOfProduction,
            pricePerDayInUsdCents: car.pricePerDayInUsdCents,
            securityDepositPerTripInUsdCents: car.securityDepositPerTripInUsdCents,
            engineType: car.engineType,
            engineParams: car.engineParams,
            milesIncludedPerDay: car.milesIncludedPerDay,
            timeBufferBetweenTripsInSec: car.timeBufferBetweenTripsInSec,
            currentlyListed: car.currentlyListed,
            geoVerified: car.geoVerified,
            timeZoneId: car.timeZoneId,
            insuranceIncluded: car.insuranceIncluded,
            locationHash: car.locationHash
        });
    }

    function _toCommonLocationInfo(Schemas.LocationInfo memory location) internal pure returns (LocationInfo memory) {
        return LocationInfo({
            userAddress: location.userAddress,
            country: location.country,
            state: location.state,
            city: location.city,
            latitude: location.latitude,
            longitude: location.longitude,
            timeZoneId: location.timeZoneId
        });
    }

    function _toCommonSignedLocationInfo(Schemas.SignedLocationInfo memory location)
        internal
        pure
        returns (SignedLocationInfo memory)
    {
        return SignedLocationInfo({
            locationInfo: _toCommonLocationInfo(location.locationInfo),
            signature: location.signature
        });
    }

    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory source = bytes(str);
        bytes memory lowered = new bytes(source.length);

        for (uint256 i = 0; i < source.length; i++) {
            uint8 charCode = uint8(source[i]);
            if (charCode >= 65 && charCode <= 90) {
                lowered[i] = bytes1(charCode + 32);
            } else {
                lowered[i] = source[i];
            }
        }

        return string(lowered);
    }

    function _containWord(string memory where, string memory what) internal pure returns (bool found) {
        bytes memory needle = bytes(what);
        bytes memory haystack = bytes(where);

        if (haystack.length < needle.length) {
            return false;
        }

        for (uint256 i = 0; i <= haystack.length - needle.length; i++) {
            bool matches = true;
            for (uint256 j = 0; j < needle.length; j++) {
                if (haystack[i + j] != needle[j]) {
                    matches = false;
                    break;
                }
            }

            if (matches) {
                return true;
            }
        }

        return false;
    }

    function _compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}


