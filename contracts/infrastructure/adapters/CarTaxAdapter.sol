// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../models/car/CarQuery.sol";
import "../../models/car/CarTypes.sol";
import "../../models/base/asset/AssetTypes.sol";
import "../../rentality_old/Schemas.sol";

contract CarTaxAdapter {
    CarQuery public immutable carQuery;

    constructor(address carQueryAddress) {
        carQuery = CarQuery(carQueryAddress);
    }

    function getGeoServiceAddress() external view returns (address) {
        return carQuery.getGeoVerifierAddress();
    }

    function getCarInfoById(uint256 carId) external view returns (Schemas.CarInfo memory) {
        if (!carQuery.exists(carId)) {
            Schemas.CarInfo memory empty;
            return empty;
        }

        CarInfo memory car = carQuery.getCar(carId);
        return _toLegacyCarInfo(car.asset, car.car);
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
}
