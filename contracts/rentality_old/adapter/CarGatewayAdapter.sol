// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../models/common/CommonTypes.sol";
import "../../models/base/asset/AssetTypes.sol";
import "../../models/car/CarMain.sol";
import "../../models/car/CarTypes.sol";
import "../../models/car/CarQuery.sol";
import "./ICarGateway.sol";
import "../Schemas.sol";

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
        PublicHostCarInfo[] memory cars = carQuery.getCarsOfHost(host);
        Schemas.PublicHostCarDTO[] memory result = new Schemas.PublicHostCarDTO[](cars.length);

        for (uint256 i = 0; i < cars.length; i++) {
            result[i] = Schemas.PublicHostCarDTO({
                carId: cars[i].carId,
                metadataURI: cars[i].metadataURI,
                brand: cars[i].brand,
                model: cars[i].model,
                yearOfProduction: cars[i].yearOfProduction,
                pricePerDayInUsdCents: cars[i].pricePerDayInUsdCents,
                securityDepositPerTripInUsdCents: cars[i].securityDepositPerTripInUsdCents,
                milesIncludedPerDay: cars[i].milesIncludedPerDay,
                currentlyListed: cars[i].currentlyListed
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
        return carQuery.isCarAvailableForUser(carId, sender, _toModelSearchParams(searchCarParams));
    }

    function fetchAvailableCarsForUser(
        address user,
        Schemas.SearchCarParams memory searchCarParams,
        uint256 from,
        uint256 to
    ) public view returns (Schemas.CarInfo[] memory) {
        CarInfo[] memory cars = carQuery.fetchAvailableCarsForUser(user, _toModelSearchParams(searchCarParams), from, to);
        Schemas.CarInfo[] memory result = new Schemas.CarInfo[](cars.length);

        for (uint256 i = 0; i < cars.length; i++) {
            result[i] = _toLegacyCarInfo(cars[i].asset, cars[i].car);
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

    function _toModelSearchParams(Schemas.SearchCarParams memory searchCarParams)
        internal
        pure
        returns (CarSearchParams memory)
    {
        return CarSearchParams({
            country: searchCarParams.country,
            state: searchCarParams.state,
            city: searchCarParams.city,
            brand: searchCarParams.brand,
            model: searchCarParams.model,
            yearOfProductionFrom: searchCarParams.yearOfProductionFrom,
            yearOfProductionTo: searchCarParams.yearOfProductionTo,
            pricePerDayInUsdCentsFrom: searchCarParams.pricePerDayInUsdCentsFrom,
            pricePerDayInUsdCentsTo: searchCarParams.pricePerDayInUsdCentsTo,
            userLocation: _toCommonLocationInfo(searchCarParams.userLocation)
        });
    }
}
