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
import {TripServiceStorage} from '../TripServiceStorage.sol';
import {PaymentsStorage} from '../PaymentsStorage.sol';

import {RentalityCarTokenHelper} from './RentalityCarTokenHelper.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';
import {RentalityTripsQueryDiamond} from './RentalityTripsQueryDiamond.sol';

library RentalityQueryDiamond {



  /// @notice Searches for available cars for a user based on specified search parameters.
  /// @dev This function checks for car availability, trip intersection, and delivery options.
  /// @param user The address of the user searching for cars.
  /// @param startDateTime The start time for the search period.
  /// @param endDateTime The end time for the search period.
  /// @param searchParams The parameters to filter the search (e.g., car type, price).
  /// @param pickUpInfo The location info for car pick-up.
  /// @param returnInfo The location info for car return.
  /// @return result An array of SearchCar structures containing available cars that meet the criteria.
  function searchAvailableCarsForUser(
    address user,
    uint64 startDateTime,
    uint64 endDateTime,
    Schemas.SearchCarParams memory searchParams,
    Schemas.LocationInfo memory pickUpInfo,
    Schemas.LocationInfo memory returnInfo
  ) internal view returns (Schemas.SearchCar[] memory result) {
    Schemas.CarInfo[] memory availableCars = RentalityCarTokenHelper.fetchAvailableCarsForUser(user, searchParams);
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
      Schemas.CarInfo memory carInfo = CarTokenStorage.getCarInfoById(temp[i].carId);
      if (bytes(pickUpInfo.latitude).length != 0 || bytes(returnInfo.longitude).length != 0) {
        (pickUp, dropOf) = DeliveryStorage.calculatePricesByDeliveryDataInUsdCents(
          pickUpInfo,
          returnInfo,
          GeoServiceStorage.getCarLocationLatitude(
            carInfo.locationHash
          ),
          GeoServiceStorage.getCarLocationLongitude(
            carInfo.locationHash
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
        GeoServiceStorage.getLocationInfo(carInfo.locationHash),
        InsuranceServiceStorage.getCarInsuranceInfo(temp[i].carId),
        isGuestHasInsurance,
        DimoServiceStorage.getDimoTokenId(temp[i].carId),
        CurrencyConverterStorage.getUserCurrency(temp[i].createdBy)
      );
    }
    return result;
  }

  /// @notice Searches for available cars and sorts them by distance from the user.
  /// @dev This function first searches for available cars and then sorts the results by distance.
  /// @param user The address of the user searching for cars.
  /// @param startDateTime The start time for the search period.
  /// @param endDateTime The end time for the search period.
  /// @param searchParams The parameters to filter the search (e.g., car type, price).
  /// @param pickUpInfo The location info for car pick-up.
  /// @param returnInfo The location info for car return.
  /// @return An array of SearchCarWithDistance structures containing available cars sorted by distance.
  function searchSortedCars(
    address user,
    uint64 startDateTime,
    uint64 endDateTime,
    Schemas.SearchCarParams memory searchParams,
    Schemas.LocationInfo memory pickUpInfo,
    Schemas.LocationInfo memory returnInfo
  ) internal view returns (Schemas.SearchCarWithDistance[] memory) {
    return
      DeliveryStorage.sortCarsByDistance(
        searchAvailableCarsForUser(
          user,
          startDateTime,
          endDateTime,
          searchParams,
          pickUpInfo,
          returnInfo
        ),
        searchParams.userLocation
      );
  }

   /// @dev Retrieves delivery data for a given car.
  /// @param carId The ID of the car for which delivery data is requested.
  /// @return deliveryData The delivery data including location details and delivery prices.
  function getDeliveryData(
    uint carId
  ) internal view returns (Schemas.DeliveryData memory) {

    Schemas.DeliveryPrices memory deliveryPrices = DeliveryStorage.getUserDeliveryPrices(CarTokenStorage.ownerOf(carId));
    Schemas.CarInfo memory carInfo = CarTokenStorage.getCarInfoById(carId);
    return
      Schemas.DeliveryData(
        GeoServiceStorage.getLocationInfo(carInfo.locationHash),
        deliveryPrices.underTwentyFiveMilesInUsdCents,
        deliveryPrices.aboveTwentyFiveMilesInUsdCents,
        carInfo.insuranceIncluded
      );
  }

  function calculateDelivery(
    Schemas.CreateTripRequestWithDelivery memory request
  ) internal view returns (uint64, uint64) {
    Schemas.CarInfo memory carInfo = CarTokenStorage.getCarInfoById(request.carId);
    bytes32 locationHash = carInfo.locationHash;
    (uint64 pickUp, uint64 dropOf) = DeliveryStorage.calculatePricesByDeliveryDataInUsdCents(
      request.pickUpInfo.locationInfo,
      request.returnInfo.locationInfo,
      GeoServiceStorage.getCarLocationLatitude(locationHash),
      GeoServiceStorage.getCarLocationLongitude(locationHash),
      carInfo.createdBy
    );
    if (pickUp > 0) GeoServiceStorage.verifySignedLocationInfo(request.pickUpInfo);
    if (dropOf > 0) GeoServiceStorage.verifySignedLocationInfo(request.returnInfo);
    return (pickUp, dropOf);
  }



  /// @notice Retrieves detailed information about a specific car.
  /// @dev This function fetches all relevant data for a car including geo-location and user information.
  /// @param carId The ID of the car to retrieve.
  /// @return details A CarDetails structure containing all relevant information about the car.
  function getCarDetails(
    uint carId
  ) internal view returns (Schemas.CarDetails memory details) {

    Schemas.CarInfo memory car = CarTokenStorage.getCarInfoById(carId);

    details = Schemas.CarDetails(
      carId,
      UserServiceStorage.getKYCInfo(car.createdBy).name,
      UserServiceStorage.getKYCInfo(car.createdBy).profilePhoto,
      car.createdBy,
      car.brand,
      car.model,
      car.yearOfProduction,
      car.pricePerDayInUsdCents,
      car.securityDepositPerTripInUsdCents,
      car.milesIncludedPerDay,
      car.engineType,
      car.engineParams,
      true,
      car.currentlyListed,
      GeoServiceStorage.getLocationInfo(car.locationHash),
      car.carVinNumber,
      CarTokenStorage.tokenUri(carId),
      DimoServiceStorage.getDimoTokenId(carId)
    );
  }
  /// @notice Retrieves all cars owned by the user with information about editability.
  /// @dev This function fetches the user's cars and checks if they can be edited.
  /// @return An array of CarInfoDTO structures containing information about the user's cars and whether they are editable.
  function getCarsOwnedByUserWithEditability(
    address user
  ) internal view returns (Schemas.CarInfoDTO[] memory) {

    Schemas.CarInfo[] memory carInfoes = RentalityCarTokenHelper.getCarsOwnedByUser(user);

    Schemas.CarInfoDTO[] memory result = new Schemas.CarInfoDTO[](carInfoes.length);
    for (uint i = 0; i < carInfoes.length; i++) {
      result[i].carInfo = carInfoes[i];
      result[i].metadataURI = CarTokenStorage.tokenUri(carInfoes[i].carId);
      result[i].isEditable = isCarEditable(carInfoes[i].carId);
      result[i].dimoTokenId = DimoServiceStorage.getDimoTokenId(carInfoes[i].carId);
    }

    return result;
  }

  /// @notice Checks if a car is editable based on its associated trips.
  /// @dev This function checks the status of trips associated with the car to determine if it can be edited.
  /// @param carId The ID of the car to check for editability.
  /// @return Returns true if the car is editable, otherwise false.
  function isCarEditable(uint carId) internal view returns (bool) {
    uint[] memory carTrips = TripServiceStorage.getActiveTrips(carId);

    for (uint i = 0; i < carTrips.length; i++) {
      Schemas.Trip memory tripInfo = TripServiceStorage.getTrip(carTrips[i]);

      if (
        tripInfo.carId == carId &&
        (tripInfo.status != Schemas.TripStatus.Finished &&
          tripInfo.status != Schemas.TripStatus.Canceled &&
          (tripInfo.status != Schemas.TripStatus.CheckedOutByHost && tripInfo.host != tripInfo.tripFinishedBy))
      ) {
        return false;
      }
    }

    return true;
  }
}