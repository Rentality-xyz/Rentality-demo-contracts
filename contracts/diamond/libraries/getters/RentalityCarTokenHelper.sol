// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Schemas } from "../../../Schemas.sol";
import {CarTokenStorage} from '../CarTokenStorage.sol';
import {GeoServiceStorage} from '../GeoServiceStorage.sol';
import {RentalityUtils} from './RentalityUtils.sol';

library RentalityCarTokenHelper {
    using RentalityUtils for string;

  function _isCarAvailableForUser(
    uint256 carId,
    Schemas.SearchCarParams memory searchCarParams
  ) internal view returns (bool) {
  CarTokenStorage.CarTokenFaucetStorage storage s = CarTokenStorage.accessStorage();
    Schemas.CarInfo memory car = s.idToCarInfo[carId];
    return
      (bytes(searchCarParams.brand).length == 0 || car.brand.toLower().containWord(searchCarParams.brand.toLower())) &&
      (bytes(searchCarParams.model).length == 0 || car.model.toLower().containWord( searchCarParams.model.toLower())) &&
      (bytes(searchCarParams.country).length == 0 ||
        GeoServiceStorage.getCarCountry(car.locationHash).toLower().containWord(searchCarParams.country.toLower())) &&
      (bytes(searchCarParams.state).length == 0 ||
        GeoServiceStorage.getCarState(car.locationHash).toLower().containWord(searchCarParams.state.toLower())) &&
      (bytes(searchCarParams.city).length == 0 ||
        GeoServiceStorage.getCarCity(car.locationHash).toLower().containWord(searchCarParams.city.toLower())) &&
      (searchCarParams.yearOfProductionFrom == 0 || car.yearOfProduction >= searchCarParams.yearOfProductionFrom) &&
      (searchCarParams.yearOfProductionTo == 0 || car.yearOfProduction <= searchCarParams.yearOfProductionTo) &&
      (searchCarParams.pricePerDayInUsdCentsFrom == 0 ||
        car.pricePerDayInUsdCents >= searchCarParams.pricePerDayInUsdCentsFrom) &&
      (searchCarParams.pricePerDayInUsdCentsTo == 0 ||
        car.pricePerDayInUsdCents <= searchCarParams.pricePerDayInUsdCentsTo);
  }
}