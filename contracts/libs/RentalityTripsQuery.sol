/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../RentalityCarToken.sol';
import '../payments/RentalityCurrencyConverter.sol';
import '../payments/RentalityPaymentService.sol';
import '../RentalityTripService.sol';
import '../RentalityUserService.sol';
import '../RentalityPlatform.sol';
import '../features/RentalityClaimService.sol';
import '../RentalityAdminGateway.sol';
import '../RentalityGateway.sol';
import {IRentalityGeoService} from '../abstract/IRentalityGeoService.sol';
import {RentalityCarDelivery} from '../features/RentalityCarDelivery.sol';
import '../Schemas.sol';
import './RentalityUtils.sol';
import './RentalityQuery.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

library RentalityTripsQuery {
  function isTripThatIntersect(
    RentalityContract memory contracts,
    uint256 tripId,
    uint64 startDateTime,
    uint64 endDateTime
  ) internal view returns (bool) {
    Schemas.Trip memory trip = contracts.tripService.getTrip(tripId);
    Schemas.CarInfo memory carInfo = contracts.carService.getCarInfoById(trip.carId);
    return
      (trip.endDateTime + carInfo.timeBufferBetweenTripsInSec > startDateTime) && (trip.startDateTime < endDateTime);
  }

  function getTripsForCarThatIntersect(
    RentalityContract memory contracts,
    uint256 carId,
    uint64 startDateTime,
    uint64 endDateTime
  ) internal view returns (Schemas.Trip[] memory) {
    uint itemCount = 0;
    RentalityTripService tripService = contracts.tripService;

    uint32 timeBuffer = contracts.carService.getCarInfoById(carId).timeBufferBetweenTripsInSec;

    for (uint i = 0; i < tripService.totalTripCount(); i++) {
      uint currentId = i + 1;
      if (RentalityQuery.isCarThatIntersect(contracts, currentId, carId, startDateTime, endDateTime + timeBuffer)) {
        itemCount += 1;
      }
    }

    Schemas.Trip[] memory result = new Schemas.Trip[](itemCount);
    uint currentIndex = 0;

    for (uint i = 0; i < tripService.totalTripCount(); i++) {
      uint currentId = i + 1;
      if (RentalityQuery.isCarThatIntersect(contracts, currentId, carId, startDateTime, endDateTime + timeBuffer)) {
        result[currentIndex] = tripService.getTrip(currentId);
        currentIndex += 1;
      }
    }

    return result;
  }
  /// @dev Retrieves an array of trips associated with a specific car ID.
  /// @param carId The ID of the car.
  /// @return trips An array of trips associated with the specified car ID.
  function getTripsByCar(
    RentalityContract memory contracts,
    uint256 carId
  ) public view returns (Schemas.Trip[] memory) {
    RentalityTripService tripService = contracts.tripService;
    uint itemCount = 0;

    for (uint i = 1; i <= tripService.totalTripCount(); i++) {
      if (tripService.getTrip(i).carId == carId) {
        itemCount += 1;
      }
    }

    Schemas.Trip[] memory result = new Schemas.Trip[](itemCount);
    uint currentIndex = 0;

    for (uint i = 1; i <= tripService.totalTripCount(); i++) {
      if (tripService.getTrip(i).carId == carId) {
        Schemas.Trip memory currentItem = tripService.getTrip(i);
        result[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }

    return result;
  }

  function getTripsThatIntersect(
    RentalityContract memory contracts,
    uint64 startDateTime,
    uint64 endDateTime
  ) internal view returns (Schemas.Trip[] memory) {
    uint itemCount = 0;
    RentalityTripService tripService = contracts.tripService;

    for (uint i = 0; i < tripService.totalTripCount(); i++) {
      uint currentId = i + 1;
      if (isTripThatIntersect(contracts, currentId, startDateTime, endDateTime)) {
        itemCount += 1;
      }
    }

    Schemas.Trip[] memory result = new Schemas.Trip[](itemCount);
    uint currentIndex = 0;

    for (uint i = 0; i < tripService.totalTripCount(); i++) {
      uint currentId = i + 1;
      if (isTripThatIntersect(contracts, currentId, startDateTime, endDateTime)) {
        result[currentIndex] = tripService.getTrip(currentId);
        currentIndex += 1;
      }
    }

    return result;
  }
  /// @notice This function computes various aspects of the trip receipt, including pricing, mileage, and fuel charges.
  /// @param tripId The ID of the trip for which the receipt is calculated.
  /// @param tripServiceAddress The address of the trip service contract.
  /// @return tripReceipt An instance of `Schemas.TripReceiptDTO` containing the detailed trip receipt information.
  function fullFillTripReceipt(
    uint tripId,
    address tripServiceAddress
  ) public view returns (Schemas.TripReceiptDTO memory) {
    RentalityTripService tripService = RentalityTripService(tripServiceAddress);

    Schemas.Trip memory trip = tripService.getTrip(tripId);
    uint64 ceilDays = RentalityUtils.getCeilDays(trip.startDateTime, trip.endDateTime);

    uint64 allowedMiles = trip.milesIncludedPerDay * ceilDays;

    uint64 totalMilesDriven = trip.endParamLevels[1] - trip.startParamLevels[1];

    uint64 overmiles = allowedMiles >= totalMilesDriven ? 0 : totalMilesDriven - allowedMiles;

    return
      Schemas.TripReceiptDTO(
        trip.paymentInfo.totalDayPriceInUsdCents,
        ceilDays,
        trip.paymentInfo.priceWithDiscount,
        trip.paymentInfo.totalDayPriceInUsdCents - trip.paymentInfo.priceWithDiscount,
        trip.paymentInfo.salesTax,
        trip.paymentInfo.governmentTax,
        trip.paymentInfo.depositInUsdCents,
        trip.paymentInfo.resolveAmountInUsdCents,
        trip.paymentInfo.depositInUsdCents - trip.paymentInfo.resolveAmountInUsdCents,
        trip.startParamLevels[0] >= trip.endParamLevels[0] ? 0 : trip.endParamLevels[0] - trip.startParamLevels[0],
        trip.fuelPrice,
        trip.paymentInfo.resolveFuelAmountInUsdCents,
        allowedMiles,
        overmiles,
        overmiles > 0 ? uint64(Math.ceilDiv(trip.paymentInfo.totalDayPriceInUsdCents, trip.milesIncludedPerDay)) : 0,
        trip.paymentInfo.resolveMilesAmountInUsdCents,
        trip.startParamLevels[0],
        trip.endParamLevels[0],
        trip.startParamLevels[1],
        trip.endParamLevels[1]
      );
  }

  /// @notice Get contact information for a specific trip on the Rentality platform.
  /// @param tripId The ID of the trip to retrieve contact information for.
  /// @return guestPhoneNumber The phone number of the guest on the trip.
  /// @return hostPhoneNumber The phone number of the host on the trip.
  //// Refactoring for getTripContactInfo with RentalityContract
  function getTripContactInfo(
    uint256 tripId,
    address tripService,
    address userService
  ) public view returns (string memory guestPhoneNumber, string memory hostPhoneNumber) {
    require(RentalityUserService(userService).isHostOrGuest(tx.origin), 'User is not a host or guest');

    Schemas.Trip memory trip = RentalityTripService(tripService).getTrip(tripId);

    Schemas.KYCInfo memory guestInfo = RentalityUserService(userService).getKYCInfo(trip.guest);
    Schemas.KYCInfo memory hostInfo = RentalityUserService(userService).getKYCInfo(trip.host);

    return (guestInfo.mobilePhoneNumber, hostInfo.mobilePhoneNumber);
  }

  function getTripsByGuest(
    RentalityContract memory contracts,
    address guest
  ) public view returns (Schemas.TripDTO[] memory) {
    RentalityTripService tripService = contracts.tripService;
    uint itemCount = 0;

    for (uint i = 1; i <= tripService.totalTripCount(); i++) {
      if (tripService.getTrip(i).guest == guest) {
        itemCount += 1;
      }
    }

    Schemas.TripDTO[] memory result = new Schemas.TripDTO[](itemCount);
    uint currentIndex = 0;

    for (uint i = 1; i <= tripService.totalTripCount(); i++) {
      if (tripService.getTrip(i).guest == guest) {
        result[currentIndex] = getTripDTO(contracts, i);

        currentIndex += 1;
      }
    }

    return result;
  }

  function getTripsByHost(
    RentalityContract memory contracts,
    address host
  ) public view returns (Schemas.TripDTO[] memory) {
    RentalityTripService tripService = contracts.tripService;
    uint itemCount = 0;

    for (uint i = 1; i <= tripService.totalTripCount(); i++) {
      if (tripService.getTrip(i).host == host) {
        itemCount += 1;
      }
    }

    Schemas.TripDTO[] memory result = new Schemas.TripDTO[](itemCount);
    uint currentIndex = 0;

    for (uint i = 1; i <= tripService.totalTripCount(); i++) {
      if (tripService.getTrip(i).host == host) {
        result[currentIndex] = getTripDTO(contracts, i);
        currentIndex += 1;
      }
    }

    return result;
  }

  // Updated function getTripDTO with RentalityContract parameter
  function getTripDTO(RentalityContract memory contracts, uint tripId) public view returns (Schemas.TripDTO memory) {
    RentalityTripService tripService = contracts.tripService;
    RentalityCarToken carService = contracts.carService;
    RentalityUserService userService = contracts.userService;

    Schemas.Trip memory trip = tripService.getTrip(tripId);
    Schemas.CarInfo memory car = carService.getCarInfoById(trip.carId);

    Schemas.LocationInfo memory pickUpLocation = IRentalityGeoService(carService.getGeoServiceAddress())
      .getLocationInfo(trip.pickUpHash);
    Schemas.LocationInfo memory returnLocation = IRentalityGeoService(carService.getGeoServiceAddress())
      .getLocationInfo(trip.returnHash);
    return
      Schemas.TripDTO(
        trip,
        userService.getKYCInfo(trip.guest).profilePhoto,
        userService.getKYCInfo(trip.host).profilePhoto,
        carService.tokenURI(trip.carId),
        IRentalityGeoService(carService.getGeoServiceAddress()).getCarTimeZoneId(trip.carId),
        userService.getKYCInfo(trip.host).licenseNumber,
        userService.getKYCInfo(trip.host).expirationDate,
        userService.getKYCInfo(trip.guest).licenseNumber,
        userService.getKYCInfo(trip.guest).expirationDate,
        car.model,
        car.brand,
        car.yearOfProduction,
        bytes(pickUpLocation.latitude).length == 0
          ? IRentalityGeoService(carService.getGeoServiceAddress()).getLocationInfo(car.locationHash)
          : pickUpLocation,
        bytes(pickUpLocation.latitude).length == 0
          ? IRentalityGeoService(carService.getGeoServiceAddress()).getLocationInfo(car.locationHash)
          : returnLocation
      );
  }
}
