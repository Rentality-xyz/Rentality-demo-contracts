// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Schemas } from "../../../Schemas.sol";
import { GeoServiceStorage } from "../../libraries/GeoServiceStorage.sol";
import { CarTokenStorage } from "../CarTokenStorage.sol";
import { DeliveryStorage } from "../../libraries/DeliveryStorage.sol";
import { UserServiceStorage } from "../../libraries/UserServiceStorage.sol";
import { CurrencyConverterStorage } from "../../libraries/CurrencyConverterStorage.sol";
import { TripServiceStorage } from "../../libraries/TripServiceStorage.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
library RentalityTripsHelperDiamond {
    
    
    

  function validateTripRequest(
    address currencyType,
    uint carId,
    uint64 startDateTime,
    uint64 endDateTime,
    address user
  ) internal view {
    require(UserServiceStorage.hasPassedKYCAndTC(user), 'KYC or TC not passed.');
    require(CurrencyConverterStorage.currencyTypeIsAvailable(currencyType), 'Token is not available.');
    require(CarTokenStorage.ownerOf(carId) != user, 'Car is not available for creator');
    require(!isCarUnavailable(carId, startDateTime, endDateTime), 'Unavailable for current date.');
  }


    function isCarUnavailable(
    uint256 carId,
    uint64 startDateTime,
    uint64 endDateTime
  ) private view returns (bool) {
    uint[] memory activeTrips = TripServiceStorage.getCarTrips(carId);
    for (uint256 i = 0; i < activeTrips.length; i++) {
      Schemas.Trip memory trip = TripServiceStorage.getTrip(activeTrips[i]);
      Schemas.CarInfo memory car = CarTokenStorage.getCarInfoById(trip.carId);

      if (
        trip.carId == carId &&
        trip.endDateTime + car.timeBufferBetweenTripsInSec > startDateTime &&
        trip.startDateTime < endDateTime
      ) {
        Schemas.TripStatus tripStatus = trip.status;

        // Check if the trip is active (not in Created, Finished, or Canceled status).
        bool isActiveTrip = (tripStatus != Schemas.TripStatus.Created &&
          tripStatus != Schemas.TripStatus.Finished &&
          tripStatus != Schemas.TripStatus.Canceled);

        // Return true if an active trip is found.
        if (isActiveTrip) {
          return true;
        }
      }
    }

    // If no active trips are found, return false indicating the car is available.
    return false;
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


    function createPaymentInfo(
    uint256 carId,
    address currencyType,
    uint64 pickUp,
    uint64 dropOf,
    // RentalityPromoService promoService,
    string memory promo,
    address user,
    uint insurance,
    uint64 taxesSum,
    uint64 daysOfTrip,
    uint64 priceWithDiscount
  ) internal view returns (Schemas.PaymentInfo memory, uint, uint, uint, bool) {
    bool usePromo = false;
    Schemas.CarInfo memory carInfo = CarTokenStorage.getCarInfoById(carId);

    // uint64 discount = uint64(promoService.getDiscountByPromo(promo, user));
    uint64 discount = 0;

    uint valueSum = priceWithDiscount +
      taxesSum +
      carInfo.securityDepositPerTripInUsdCents +
      pickUp +
      dropOf +
      insurance;

    uint priceWithPromo = 0;
    if (discount > 0) {
      require(discount == 100 || (pickUp == 0 && pickUp == 0), 'PickUp and DropOf should be 0');
      usePromo = true;
      uint sumBeforePromo = priceWithDiscount + taxesSum + pickUp + dropOf;
      priceWithPromo = (sumBeforePromo - ((sumBeforePromo * discount) / 100));
    }

    (uint valueSumInCurrency, int rate, uint8 decimals) = CurrencyConverterStorage.getFromUsdLatest(
      currencyType,
      valueSum
    );

    uint valueSumInCurrencyBeforePromo = valueSumInCurrency;
    uint valueSumWithPromo = valueSum;
    if (discount > 0) {
      valueSumWithPromo = priceWithPromo;

      valueSumInCurrency = CurrencyConverterStorage.getFromUsd(
        currencyType,
        priceWithPromo + carInfo.securityDepositPerTripInUsdCents + insurance,
        rate,
        decimals
      );
    }

    Schemas.PaymentInfo memory paymentInfo = Schemas.PaymentInfo(
      0,
      user,
      address(this),
      carInfo.pricePerDayInUsdCents * daysOfTrip,
      0,
      0,
      priceWithDiscount,
      carInfo.securityDepositPerTripInUsdCents,
      0,
      currencyType,
      rate,
      decimals,
      0,
      0,
      pickUp,
      dropOf
    );
    if (discount == 100) valueSumInCurrency = 0;

    return (paymentInfo, valueSumInCurrency, valueSumInCurrencyBeforePromo, priceWithPromo, usePromo);
  }

    function getTripsForCarThatIntersect(
    uint256 carId,
    uint64 startDateTime,
    uint64 endDateTime
  ) internal view returns (Schemas.Trip[] memory) {
    uint itemCount = 0;
    uint32 timeBuffer = CarTokenStorage.getCarInfoById(carId).timeBufferBetweenTripsInSec;
    uint[] memory trips = TripServiceStorage.getActiveTrips(carId);
    for (uint i = 0; i < trips.length; i++) {
      uint currentId = i + 1;
      Schemas.Trip memory trip = TripServiceStorage.getTrip(currentId);
      if (isCarThatIntersect(trip, carId, startDateTime, endDateTime + timeBuffer)) {
        itemCount += 1;
      }
    }

    Schemas.Trip[] memory result = new Schemas.Trip[](itemCount);
    uint currentIndex = 0;

    for (uint i = 0; i < trips.length; i++) {
      uint currentId = i + 1;
      Schemas.Trip memory trip = TripServiceStorage.getTrip(currentId);
      if (isCarThatIntersect(trip, carId, startDateTime, endDateTime + timeBuffer)) {
        result[currentIndex] = trip;
        currentIndex += 1;
      }
    }

    return result;
  }

   function isCarThatIntersect(
    Schemas.Trip memory trip,
    uint256 carId,
    uint64 startDateTime,
    uint64 endDateTime
  ) internal view returns (bool) {
    return (trip.carId == carId) && (trip.endDateTime > startDateTime) && (trip.startDateTime < endDateTime);
  }

    function getResolveAmountInUsdCents(
    uint8 eType,
    Schemas.Trip memory tripInfo,
    uint64[] memory engineParams
  ) internal view returns (uint64, uint64) {
    uint64 duration = tripInfo.endDateTime - tripInfo.startDateTime;
    uint64 tripDays = uint64(Math.ceilDiv(duration, 1 days));
    CarTokenStorage.CarTokenFaucetStorage storage s = CarTokenStorage.accessStorage();

    return
      s.enginesService.getResolveAmountInUsdCents(
        eType,
        tripInfo.fuelPrice,
        tripInfo.startParamLevels,
        tripInfo.endParamLevels,
        engineParams,
        tripInfo.milesIncludedPerDay,
        tripInfo.pricePerDayInUsdCents,
        tripDays
      );
  }


}