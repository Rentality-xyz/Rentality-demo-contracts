// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Schemas } from "../../../Schemas.sol";
import {CarTokenStorage} from '../CarTokenStorage.sol';
import {GeoServiceStorage} from '../GeoServiceStorage.sol';
import {DeliveryStorage} from '../DeliveryStorage.sol';
import {DimoServiceStorage} from '../DimoServiceStorage.sol';
import {InsuranceServiceStorage} from '../InsuranceServiceStorage.sol';
import {CurrencyConverterStorage} from '../CurrencyConverterStorage.sol';
import {UserServiceStorage} from '../UserServiceStorage.sol';
import {TaxesStorage} from '../TaxesStorage.sol';
import {PaymentsStorage} from '../PaymentsStorage.sol';
import {RentalityUtilsDiamond} from './RentalityUtilsDiamond.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';
import {RentalityTripsQueryDiamond} from './RentalityTripsQueryDiamond.sol';

library RentalityCarTokenHelper {
    using RentalityUtilsDiamond for string;

    /// @notice Retrieves information about all cars in the system.
  /// @return An array containing information about all cars.
  function getAllCars() internal view returns (Schemas.CarInfo[] memory) {
    CarTokenStorage.CarTokenFaucetStorage storage s = CarTokenStorage.accessStorage();
    uint itemCount = 0;

    for (uint i = 0; i < s._carIdCounter; i++) {
      uint currentId = i + 1;
      if (CarTokenStorage._exists(currentId)) {
        itemCount += 1;
      }
    }

    Schemas.CarInfo[] memory result = new Schemas.CarInfo[](itemCount);

    uint elementsCounter = 0;
    for (uint i = 0; i < s._carIdCounter; i++) {
      if (CarTokenStorage._exists(i + 1)) {
        result[elementsCounter++] = s.idToCarInfo[i + 1];
      }
    }

    return result;
  }



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


  function isCarAvailableForUser(uint256 carId, address user) private view returns (bool) {
     CarTokenStorage.CarTokenFaucetStorage storage s = CarTokenStorage.accessStorage();
    return CarTokenStorage._exists(carId) && s.idToCarInfo[carId].currentlyListed && CarTokenStorage.ownerOf(carId) != user;
  }

  /// @notice Retrieves available cars for a specific user.
  /// @dev Only used by main contract
  /// @param user The address of the user.
  /// @return An array containing information about available cars for the user.
  function getAvailableCarsForUser(address user) internal view returns (Schemas.CarInfo[] memory) {
    CarTokenStorage.CarTokenFaucetStorage storage s = CarTokenStorage.accessStorage();
    uint itemCount = 0;

    for (uint i = 0; i < s._carIdCounter; i++) {
      uint currentId = i + 1;
      if (isCarAvailableForUser(currentId, user)) {
        itemCount += 1;
      }
    }

    Schemas.CarInfo[] memory result = new Schemas.CarInfo[](itemCount);
    uint currentIndex = 0;

    for (uint i = 0; i < s._carIdCounter; i++) {
      uint currentId = i + 1;
      if (isCarAvailableForUser(currentId, user)) {
        Schemas.CarInfo storage currentItem = s.idToCarInfo[currentId];
        result[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }

    return result;
  }
  /// @notice Checks if a car is available for a specific user based on search parameters.
  /// @dev Determines availability based on several conditions, including ownership and search parameters.
  /// @param carId The ID of the car being checked.
  /// @param searchCarParams The parameters used to filter available cars.
  /// @return A boolean indicating whether the car is available for the user.
  function isCarAvailableForUser(
    uint256 carId,
    address user,
    Schemas.SearchCarParams memory searchCarParams
  ) internal view returns (bool) {
    CarTokenStorage.CarTokenFaucetStorage storage s = CarTokenStorage.accessStorage();
    return
      CarTokenStorage._exists(carId) &&
      s.idToCarInfo[carId].currentlyListed &&
      CarTokenStorage.ownerOf(carId) != user &&
      RentalityCarTokenHelper._isCarAvailableForUser(carId, searchCarParams);
  }

  /// @notice Fetches available cars for a specific user based on search parameters.
  /// @dev Iterates through all cars to find those that are available for the user.
  /// @param user The address of the user for whom to fetch available cars.
  /// @param searchCarParams The parameters used to filter available cars.
  /// @return An array of CarInfo representing the available cars for the user.
  function fetchAvailableCarsForUser(
    address user,
    Schemas.SearchCarParams memory searchCarParams
  ) internal view returns (Schemas.CarInfo[] memory) {
    CarTokenStorage.CarTokenFaucetStorage storage s = CarTokenStorage.accessStorage();
    uint itemCount = 0;

    // Count the number of available cars for the user.
    for (uint i = 0; i < s._carIdCounter; i++) {
      uint currentId = i + 1;
      if (isCarAvailableForUser(currentId, user, searchCarParams)) {
        itemCount += 1;
      }
    }

    // Create an array to store the available cars.
    Schemas.CarInfo[] memory result = new Schemas.CarInfo[](itemCount);
    uint currentIndex = 0;

    // Populate the array with available cars.
    for (uint i = 0; i < s._carIdCounter; i++) {
      uint currentId = i + 1;
      if (isCarAvailableForUser(currentId, user, searchCarParams)) {
        Schemas.CarInfo memory currentItem = s.idToCarInfo[currentId];
        result[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }

    return result;
  }

  /// @notice Checks if a car belongs to a specific user.
  /// @dev Determines ownership of a car.
  /// @param carId The ID of the car being checked.
  /// @param user The address of the user being checked.
  /// @return A boolean indicating whether the car belongs to the user.
  function isCarOfUser(uint256 carId, address user) private view returns (bool) {
    return CarTokenStorage._exists(carId) && (CarTokenStorage.ownerOf(carId) == user);
  }

  /// @notice Gets the cars owned by a specific user.
  /// @dev Iterates through all cars to find those owned by the user.
  /// @param user The address of the user for whom to fetch owned cars.
  /// @return An array of CarInfo representing the cars owned by the user.
  function getCarsOwnedByUser(address user) internal view returns (Schemas.CarInfo[] memory) {
    CarTokenStorage.CarTokenFaucetStorage storage s = CarTokenStorage.accessStorage();
    uint itemCount = 0;

    // Count the number of cars owned by the user.
    for (uint i = 0; i < s._carIdCounter; i++) {
      uint currentId = i + 1;
      if (isCarOfUser(currentId, user)) {
        itemCount += 1;
      }
    }

    // Create an array to store the owned cars.
    Schemas.CarInfo[] memory result = new Schemas.CarInfo[](itemCount);
    uint currentIndex = 0;

    // Populate the array with owned cars.
    for (uint i = 0; i < s._carIdCounter; i++) {
      uint currentId = i + 1;
      if (isCarOfUser(currentId, user)) {
        Schemas.CarInfo memory currentItem = s.idToCarInfo[currentId];
        result[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }

    return result;
  }



  /// @notice Searches for available cars for a user based on specified search parameters.
  /// @dev This function checks for car availability, trip intersection, and delivery options.
  /// @param startDateTime The start time for the search period.
  /// @param endDateTime The end time for the search period.
  /// @param searchParams The parameters to filter the search (e.g., car type, price).
  /// @param pickUpInfo The location info for car pick-up.
  /// @param returnInfo The location info for car return.
  /// @return result An array of SearchCar structures containing available cars that meet the criteria.
  function searchAvailableCarsForUser(
    uint64 startDateTime,
    uint64 endDateTime,
    Schemas.SearchCarParams memory searchParams,
    Schemas.LocationInfo memory pickUpInfo,
    Schemas.LocationInfo memory returnInfo
  ) internal view returns (Schemas.SearchCar[] memory result) {
    address user = msg.sender;
    CarTokenStorage.CarTokenFaucetStorage storage carTokenStorage = CarTokenStorage.accessStorage();
    DimoServiceStorage.DimoServiceFaucetStorage storage dimoService = DimoServiceStorage.accessStorage();
    Schemas.CarInfo[] memory availableCars = fetchAvailableCarsForUser(user, searchParams);
    if (availableCars.length == 0) return new Schemas.SearchCar[](0);

    Schemas.Trip[] memory trips = RentalityTripsQueryDiamond.getTripsThatIntersect(startDateTime, endDateTime);
    Schemas.CarInfo[] memory temp;
    uint256 resultCount;

    if (trips.length == 0) {
      temp = availableCars;
      resultCount = availableCars.length;
    } else {
      temp = new Schemas.CarInfo[](availableCars.length);
      resultCount = 0;

      for (uint i = 0; i < availableCars.length; i++) {
        bool hasIntersectTrip = false;

        for (uint j = 0; j < trips.length; j++) {
          if (
            trips[j].status == Schemas.TripStatus.Created ||
            trips[j].status == Schemas.TripStatus.Finished ||
            trips[j].status == Schemas.TripStatus.Canceled ||
            (trips[j].status == Schemas.TripStatus.CheckedOutByHost && trips[j].host == trips[j].tripFinishedBy)
          ) {
            continue;
          }

          if (trips[j].carId == availableCars[i].carId) {
            hasIntersectTrip = true;
            break;
          }
        }

        if (!hasIntersectTrip) {
          temp[resultCount] = availableCars[i];
          resultCount++;
        }
      }
    }
    result = new Schemas.SearchCar[](resultCount);
    bool isGuestHasInsurance = InsuranceServiceStorage.isGuestHasInsurance(user);
    for (uint i = 0; i < resultCount; i++) {
      uint64 totalTripDays = uint64(Math.ceilDiv(endDateTime - startDateTime, 1 days));
      totalTripDays = totalTripDays == 0 ? 1 : totalTripDays;

      Schemas.DeliveryPrices memory deliveryPrices = DeliveryStorage.getUserDeliveryPrices(
        temp[i].createdBy
      );
      uint64 priceWithDiscount = PaymentsStorage.calculateSumWithDiscount(
        CarTokenStorage.ownerOf(temp[i].carId),
        totalTripDays,
        temp[i].pricePerDayInUsdCents
      );
      uint64 pickUp = 0;
      uint64 dropOf = 0;
      if (bytes(pickUpInfo.latitude).length != 0 || bytes(returnInfo.longitude).length != 0) {
        (pickUp, dropOf) = DeliveryStorage.calculatePricesByDeliveryDataInUsdCents(
          pickUpInfo,
          returnInfo,
          GeoServiceStorage.getCarLocationLatitude(
            CarTokenStorage.getCarInfoById(temp[i].carId).locationHash
          ),
          GeoServiceStorage.getCarLocationLongitude(
            CarTokenStorage.getCarInfoById(temp[i].carId).locationHash
          ),
          temp[i].createdBy
        );
      }

      uint taxId = TaxesStorage.defineTaxesType(temp[i].carId);

      uint64 totalTax = taxId == 0
        ? 0
        : TaxesStorage.calculateTaxes(taxId, totalTripDays, priceWithDiscount + pickUp + dropOf);

      result[i] = Schemas.SearchCar(
        temp[i].carId,
        temp[i].brand,
        temp[i].model,
        temp[i].yearOfProduction,
        temp[i].pricePerDayInUsdCents,
        priceWithDiscount / totalTripDays,
        totalTripDays,
        priceWithDiscount,
        totalTax,
        temp[i].securityDepositPerTripInUsdCents,
        temp[i].engineType,
        temp[i].milesIncludedPerDay,
        temp[i].createdBy,
        UserServiceStorage.getKYCInfo(temp[i].createdBy).name,
        UserServiceStorage.getKYCInfo(temp[i].createdBy).profilePhoto,
        CarTokenStorage.tokenUri(temp[i].carId),
        deliveryPrices.underTwentyFiveMilesInUsdCents,
        deliveryPrices.aboveTwentyFiveMilesInUsdCents,
        pickUp,
        dropOf,
        temp[i].insuranceIncluded,
        GeoServiceStorage.getLocationInfo(temp[i].locationHash),
        InsuranceServiceStorage.getCarInsuranceInfo(temp[i].carId),
        isGuestHasInsurance,
        dimoService.carIdToDimoTokenId[temp[i].carId],
        CurrencyConverterStorage.accessStorage().userToCurrency[temp[i].createdBy]
      );
    }
    return result;
  }

  /// @notice Searches for available cars and sorts them by distance from the user.
  /// @dev This function first searches for available cars and then sorts the results by distance.
  /// @param startDateTime The start time for the search period.
  /// @param endDateTime The end time for the search period.
  /// @param searchParams The parameters to filter the search (e.g., car type, price).
  /// @param pickUpInfo The location info for car pick-up.
  /// @param returnInfo The location info for car return.
  /// @return An array of SearchCarWithDistance structures containing available cars sorted by distance.
  function searchSortedCars(
    uint64 startDateTime,
    uint64 endDateTime,
    Schemas.SearchCarParams memory searchParams,
    Schemas.LocationInfo memory pickUpInfo,
    Schemas.LocationInfo memory returnInfo
  ) internal view returns (Schemas.SearchCarWithDistance[] memory) {
    return
      DeliveryStorage.sortCarsByDistance(
        searchAvailableCarsForUser(
          startDateTime,
          endDateTime,
          searchParams,
          pickUpInfo,
          returnInfo
        ),
        searchParams.userLocation
      );
  }

}