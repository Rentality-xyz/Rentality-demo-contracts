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
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';
import {RentalityTripsQueryDiamond} from './RentalityTripsQueryDiamond.sol';


library RentalityTripsQueryDiamond {
  /// @notice Checks if a trip intersects with the specified time interval.
  /// @dev This function checks whether the trip's scheduled time overlaps with the given time interval,
  /// taking into account any buffer time between trips.
  /// @param tripId The ID of the trip to check.
  /// @param startDateTime The start time of the interval to check for intersection.
  /// @param endDateTime The end time of the interval to check for intersection.
  /// @return Returns true if the trip intersects with the specified time interval, otherwise false.
  function isTripThatIntersect(
    uint256 tripId,
    uint64 startDateTime,
    uint64 endDateTime
  ) internal view returns (bool) {
    Schemas.Trip memory trip = TripServiceStorage.getTrip(tripId);
    Schemas.CarInfo memory carInfo = CarTokenStorage.getCarInfoById(trip.carId);
    return
      (trip.endDateTime + carInfo.timeBufferBetweenTripsInSec > startDateTime) && (trip.startDateTime < endDateTime);
  }

  /// @notice Retrieves all trips for a specific car that intersect with the given time interval.
  /// @dev This function checks all trips associated with a car and returns those that overlap with the specified time period.
  /// @param carId The ID of the car to check.
  /// @param startDateTime The start time of the interval to check for intersection.
  /// @param endDateTime The end time of the interval to check for intersection.
  /// @return An array of Trip structures representing trips that intersect with the specified time interval.
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
      if (isCarThatIntersect(currentId, carId, startDateTime, endDateTime + timeBuffer)) {
        itemCount += 1;
      }
    }

    Schemas.Trip[] memory result = new Schemas.Trip[](itemCount);
    uint currentIndex = 0;

    for (uint i = 0; i < trips.length; i++) {
      uint currentId = i + 1;
      if (isCarThatIntersect(currentId, carId, startDateTime, endDateTime + timeBuffer)) {
        result[currentIndex] = TripServiceStorage.getTrip(currentId);
        currentIndex += 1;
      }
    }

    return result;
  }

  /// @notice Retrieves all trips associated with a specific car.
  /// @dev This function fetches all trips where the car with the specified ID is used.
  /// @param carId The ID of the car to check.
  /// @return An array of Trip structures representing all trips associated with the specified car.
  function getTripsByCar(
    uint256 carId
  ) internal view returns (Schemas.Trip[] memory) {

    uint[] memory trips = TripServiceStorage.getCarTrips(carId);

    Schemas.Trip[] memory result = new Schemas.Trip[](trips.length);
    uint currentIndex = 0;

    for (uint i = 1; i <= trips.length; i++) {
      Schemas.Trip memory currentItem = TripServiceStorage.getTrip(trips[i]);
      result[currentIndex] = currentItem;
      currentIndex += 1;
    }

    return result;
  }

  /// @notice Retrieves all trips that intersect with the specified time interval.
  /// @dev This function checks all trips and returns those that overlap with the specified time period.
  /// @param startDateTime The start time of the interval to check for intersection.
  /// @param endDateTime The end time of the interval to check for intersection.
  /// @return An array of Trip structures representing trips that intersect with the specified time interval.
  function getTripsThatIntersect(
    uint64 startDateTime,
    uint64 endDateTime
  ) internal view returns (Schemas.Trip[] memory) {
    CarTokenStorage.CarTokenFaucetStorage storage carStorage = CarTokenStorage.accessStorage();
    uint itemCount = 0;
    uint carCount = carStorage._carIdCounter;

    for (uint carId = 1; carId <= carCount; carId++) {
      uint[] memory activeTrips = TripServiceStorage.getActiveTrips(carId);

      if (activeTrips.length > 0) {
        for (uint i = 0; i < activeTrips.length; i++) {
          uint tripId = activeTrips[i];

          if (isTripThatIntersect(tripId, startDateTime, endDateTime)) {
            itemCount += 1;
          }
        }
      }
    }

    if (itemCount == 0) return new Schemas.Trip[](0);
    Schemas.Trip[] memory result = new Schemas.Trip[](itemCount);
    uint currentIndex = 0;

    for (uint carId = 1; carId <= carCount; carId++) {
      uint[] memory activeTrips = TripServiceStorage.getActiveTrips(carId);

      if (activeTrips.length > 0) {
        for (uint i = 0; i < activeTrips.length; i++) {
          uint tripId = activeTrips[i];

          if (isTripThatIntersect(tripId, startDateTime, endDateTime)) {
            result[currentIndex] = TripServiceStorage.getTrip(tripId);
            currentIndex += 1;
          }
        }
      }
    }

    return result;
  }

  /// @notice Retrieves contact information for a specific trip.
  /// @dev This function returns the phone numbers of the guest and host for a given trip.
  /// @param tripId The ID of the trip to retrieve contact information for.
  /// @return guestPhoneNumber The phone number of the guest on the trip.
  /// @return hostPhoneNumber The phone number of the host on the trip.
  function getTripContactInfo(
    uint256 tripId
  ) internal view returns (string memory guestPhoneNumber, string memory hostPhoneNumber) {
    Schemas.Trip memory trip = TripServiceStorage.getTrip(tripId);

    Schemas.KYCInfo memory guestInfo = UserServiceStorage.getKYCInfo(trip.guest);
    Schemas.KYCInfo memory hostInfo = UserServiceStorage.getKYCInfo(trip.host);

    return (guestInfo.mobilePhoneNumber, hostInfo.mobilePhoneNumber);
  }

  function getTripsAs(
    address user,
    bool host
  ) internal view returns (Schemas.TripDTO[] memory) {
    return
      host
        ? getTripsByHost(user)
        : getTripsByGuest(user);
  }

  /// @notice Retrieves all trips associated with a specific guest.
  /// @dev This function fetches all trips where the specified guest is involved.
  /// @param guest The address of the guest to check.
  /// @return An array of TripDTO structures representing all trips associated with the specified guest.
  function getTripsByGuest(
    address guest
  ) private view returns (Schemas.TripDTO[] memory) {

    uint[] memory guestTrips = TripServiceStorage.getTripsByUser(guest);

    Schemas.TripDTO[] memory result = new Schemas.TripDTO[](guestTrips.length);
    uint currentIndex = 0;

    for (uint i = 0; i < guestTrips.length; i++) {
      Schemas.Trip memory trip = TripServiceStorage.getTrip(guestTrips[i]);
      if (trip.guest == guest) {
        result[currentIndex] = getTripDTO(
          guestTrips[i],
          guest,
          trip
        );
        currentIndex += 1;
      }
    }
    assembly ('memory-safe') {
      mstore(result, currentIndex)
    }

    return result;
  }

  /// @notice Retrieves all trips associated with a specific host.
  /// @dev This function fetches all trips where the specified host is involved.
  /// @param host The address of the host to check.
  /// @return An array of TripDTO structures representing all trips associated with the specified host.
  function getTripsByHost(
    address host
  ) private view returns (Schemas.TripDTO[] memory) {
    uint[] memory hostTrips = TripServiceStorage.getTripsByUser(host);

    Schemas.TripDTO[] memory result = new Schemas.TripDTO[](hostTrips.length);
    uint currentIndex = 0;

    for (uint i = 0; i < hostTrips.length; i++) {
      Schemas.Trip memory trip = TripServiceStorage.getTrip(hostTrips[i]);
      if (trip.host == host) {
        result[currentIndex] = getTripDTO(
          hostTrips[i],
          host,
          trip
        );
        currentIndex += 1;
      }
    }
    assembly ('memory-safe') {
      mstore(result, currentIndex)
    }

    return result;
  }

  /// @notice Retrieves detailed information about a specific trip.
  /// @dev This function fetches all relevant data for a trip including car, user, and location information.
  /// @param tripId The ID of the trip to retrieve.
  /// @return An instance of TripDTO containing all relevant information about the trip.
  function getTripDTO(
    uint tripId,
    address user,
    Schemas.Trip memory trip
  ) internal view returns (Schemas.TripDTO memory) {

    Schemas.CarInfo memory car = CarTokenStorage.getCarInfoById(trip.carId);

    Schemas.LocationInfo memory pickUpLocation = GeoServiceStorage
      .getLocationInfo(trip.pickUpHash);
    Schemas.LocationInfo memory returnLocation = GeoServiceStorage
      .getLocationInfo(trip.returnHash);
    (string memory guestPhoneNumber, string memory hostPhoneNumber) = getTripContactInfo(
      tripId
    );
    trip.guestInsuranceCompanyName = '';
    trip.guestInsurancePolicyNumber = '';
    Schemas.KYCInfo memory guestKYC = UserServiceStorage.getKYCInfo(trip.guest);
    Schemas.KYCInfo memory hostKYC = UserServiceStorage.getKYCInfo(trip.host);
    return
      Schemas.TripDTO(
        trip,
        guestKYC.profilePhoto,
        hostKYC.profilePhoto,
        CarTokenStorage.tokenUri(trip.carId),
        GeoServiceStorage.getCarTimeZoneId(car.locationHash),
        hostKYC.licenseNumber,
        hostKYC.expirationDate,
        guestKYC.licenseNumber,
        guestKYC.expirationDate,
        car.model,
        car.brand,
        car.yearOfProduction,
        bytes(pickUpLocation.latitude).length == 0
          ? GeoServiceStorage.getLocationInfo(car.locationHash)
          : pickUpLocation,
        bytes(pickUpLocation.latitude).length == 0
          ? GeoServiceStorage.getLocationInfo(car.locationHash)
          : returnLocation,
        guestPhoneNumber,
        hostPhoneNumber,
        InsuranceServiceStorage.getTripInsurances(tripId),
        InsuranceServiceStorage.getInsurancePriceByTrip(tripId),
        UserServiceStorage.getMyFullKYCInfo(user).additionalKYC.issueCountry,
        0,
        // promoService.getTripDiscount(tripId),
        DimoServiceStorage.getDimoTokenId(trip.carId),
        TaxesStorage.getTripTaxesDTO(tripId)
      );
  }
  function getTripInsurancesBy(
    bool host,
    address user
  ) internal view returns (Schemas.InsuranceDTO[] memory) {
    return
      host
        ? getTripInsurancesByHost(user)
        : getTripInsurancesByGuest(user);
  }

  function getTripInsurancesByGuest(
    address guest
  ) internal view returns (Schemas.InsuranceDTO[] memory) {
    uint itemCount = 0;
    uint[] memory userTrips = TripServiceStorage.getTripsByUser(guest);
    for (uint i = 0; i < userTrips.length; i++) {
      itemCount += InsuranceServiceStorage.getTripInsurances(userTrips[i]).length;
    }
    Schemas.InsuranceInfo[] memory guestInsurances = InsuranceServiceStorage.getMyInsurancesAsGuest(guest);
    uint itemCountWithoutGuestInsurances = itemCount;
    itemCount += guestInsurances.length;

    Schemas.InsuranceDTO[] memory insurances = new Schemas.InsuranceDTO[](itemCount);
    uint counter = 0;
    for (uint i = 0; i < userTrips.length; i++) {
      Schemas.Trip memory trip = TripServiceStorage.getTrip(userTrips[i]);
      Schemas.InsuranceInfo[] memory tripInsurances = InsuranceServiceStorage.getTripInsurances(userTrips[i]);
      for (uint j = 0; j < tripInsurances.length; j++) {
        insurances[counter] = fullFillInsuranceDTO(
          tripInsurances[j],
          false,
          trip.startDateTime,
          trip.endDateTime,
          userTrips[i],
          tripInsurances[j].createdBy == trip.host,
          trip.carId,
          tripInsurances[j].createdBy
        );

        counter += 1;
      }
    }

    return _addGuestInsurances(insurances, guestInsurances, guest, itemCountWithoutGuestInsurances);
  }

  function _addGuestInsurances(
    Schemas.InsuranceDTO[] memory insurances,
    Schemas.InsuranceInfo[] memory guestInsurances,
    address guest,
    uint currentCount
  ) internal view returns (Schemas.InsuranceDTO[] memory result) {
    uint lastOneTimeTimestamp = 0;
    uint lastGeneralTimestamp = 0;
    uint lastOneTimeIndex = 0;
    uint lastGeneralIndex = 0;
    uint counter = currentCount;

    for (uint i = 0; i < guestInsurances.length; i++) {
      bool alreadyExists = false;
      for (uint j = 0; j < currentCount; j++) {
        if (insurances[j].insuranceInfo.insuranceType == Schemas.InsuranceType.OneTime) {
          if (lastOneTimeTimestamp < insurances[j].insuranceInfo.createdTime) {
            lastOneTimeTimestamp = insurances[j].insuranceInfo.createdTime;
            lastOneTimeIndex = j;
          }
        }
        if (insurances[j].insuranceInfo.insuranceType == Schemas.InsuranceType.General) {
          if (lastGeneralTimestamp < insurances[j].insuranceInfo.createdTime) {
            lastGeneralTimestamp = insurances[j].insuranceInfo.createdTime;
            lastGeneralIndex = j;
          }
          if (guestInsurances[i].createdTime == insurances[j].insuranceInfo.createdTime) {
            alreadyExists = true;
            break;
          }
        }
      }
      if (!alreadyExists) {
        if (lastGeneralTimestamp < guestInsurances[i].createdTime) {
          lastGeneralTimestamp = guestInsurances[i].createdTime;
          lastGeneralIndex = counter;
        }
        insurances[counter] = fullFillInsuranceDTO(
          guestInsurances[i],
          false,
          0,
          0,
          0,
          false,
          type(uint).max,
          guest
        );
        counter += 1;
      }
    }

    if (currentCount > 0 || counter > 0) {
      if (lastGeneralIndex < insurances.length) {
        insurances[lastGeneralIndex].isActual = true;
      }
      if (lastOneTimeIndex < insurances.length) {
        insurances[lastOneTimeIndex].isActual = true;
      }
    }
    assembly ('memory-safe') {
      mstore(insurances, counter)
    }
    return insurances;
  }
  function fullFillInsuranceDTO(
    Schemas.InsuranceInfo memory insuranceInfo,
    bool isActual,
    uint64 startDateTime,
    uint64 endDateTime,
    uint tripId,
    bool createdByHost,
    uint carId,
    address creator
  ) internal view returns (Schemas.InsuranceDTO memory result) {
    Schemas.KYCInfo memory kyc = UserServiceStorage.getKYCInfo(creator);
    Schemas.CarInfo memory car = CarTokenStorage.getCarInfoById(carId);
    result.tripId = tripId;
    result.carBrand = car.brand;
    result.carModel = car.model;
    result.carYear = car.yearOfProduction;
    result.insuranceInfo = insuranceInfo;
    result.createdByHost = createdByHost;
    result.creatorPhoneNumber = kyc.mobilePhoneNumber;
    result.creatorFullName = kyc.surname;
    result.startDateTime = startDateTime;
    result.endDateTime = endDateTime;
    result.isActual = isActual;
  }

  function getTripInsurancesByHost(
    address host
  ) internal view returns (Schemas.InsuranceDTO[] memory) {
    uint itemCount = 0;

    uint[] memory userTrips = TripServiceStorage.getTripsByUser(host);
    for (uint i = 0; i < userTrips.length; i++) {
      itemCount += InsuranceServiceStorage.getTripInsurances(userTrips[i]).length;
    }
    Schemas.InsuranceDTO[] memory insurances = new Schemas.InsuranceDTO[](itemCount);
    uint counter = 0;
    for (uint i = 0; i < userTrips.length; i++) {
      Schemas.Trip memory trip = TripServiceStorage.getTrip(userTrips[i]);
      Schemas.InsuranceInfo[] memory tripInsurances = InsuranceServiceStorage.getTripInsurances(userTrips[i]);
      (uint oneTimeActual, uint generalActual) = InsuranceServiceStorage.findActualInsurance(tripInsurances);
      for (uint j = 0; j < tripInsurances.length; j++) {
        Schemas.KYCInfo memory kyc = UserServiceStorage.getKYCInfo(tripInsurances[j].createdBy);

        Schemas.CarInfo memory car = CarTokenStorage.getCarInfoById(trip.carId);
        insurances[counter].tripId = userTrips[i];
        insurances[counter].carBrand = car.brand;
        insurances[counter].carModel = car.model;
        insurances[counter].carYear = car.yearOfProduction;
        insurances[counter].insuranceInfo = tripInsurances[j];
        insurances[counter].createdByHost = tripInsurances[j].createdBy == trip.host;
        insurances[counter].creatorPhoneNumber = kyc.mobilePhoneNumber;
        insurances[counter].creatorFullName = kyc.surname;
        insurances[counter].startDateTime = trip.startDateTime;
        insurances[counter].endDateTime = trip.endDateTime;
        insurances[counter].isActual =
          (j == oneTimeActual && tripInsurances[j].insuranceType == Schemas.InsuranceType.OneTime) ||
          (j == generalActual && tripInsurances[j].insuranceType == Schemas.InsuranceType.General);
        counter += 1;
      }
    }

    return insurances;
  }

  /// @notice Populates an array of chat information using data from trips, user service, and car service.
  /// @return chatInfoList Array of IRentalityGateway.ChatInfo structures.

  function populateChatInfo(
    address user,
    bool host
  ) internal view returns (Schemas.ChatInfo[] memory) {
    Schemas.TripDTO[] memory trips = getTripsAs(user, host);

  
    Schemas.ChatInfo[] memory chatInfoList = new Schemas.ChatInfo[](trips.length);

    for (uint i = 0; i < trips.length; i++) {
      Schemas.KYCInfo memory guestInfo = UserServiceStorage.getKYCInfo(trips[i].trip.guest);
      Schemas.KYCInfo memory hostInfo = UserServiceStorage.getKYCInfo(trips[i].trip.host);

      chatInfoList[i].tripId = trips[i].trip.tripId;
      chatInfoList[i].guestAddress = trips[i].trip.guest;
      chatInfoList[i].guestName = guestInfo.surname;
      chatInfoList[i].guestPhotoUrl = guestInfo.profilePhoto;
      chatInfoList[i].hostAddress = trips[i].trip.host;
      chatInfoList[i].hostName = hostInfo.surname;
      chatInfoList[i].hostPhotoUrl = hostInfo.profilePhoto;
      chatInfoList[i].tripStatus = uint256(trips[i].trip.status);

      Schemas.CarInfo memory carInfo = CarTokenStorage.getCarInfoById(trips[i].trip.carId);
      chatInfoList[i].carBrand = carInfo.brand;
      chatInfoList[i].carModel = carInfo.model;
      chatInfoList[i].carYearOfProduction = carInfo.yearOfProduction;
      chatInfoList[i].carMetadataUrl = CarTokenStorage.tokenUri(trips[i].trip.carId);
      chatInfoList[i].startDateTime = trips[i].trip.startDateTime;
      chatInfoList[i].endDateTime = trips[i].trip.endDateTime;
      chatInfoList[i].timeZoneId = GeoServiceStorage.getCarTimeZoneId(
        carInfo.locationHash
      );
    }
    return chatInfoList;
  }

  function isCarThatIntersect(
    uint256 tripId,
    uint256 carId,
    uint64 startDateTime,
    uint64 endDateTime
  ) internal view returns (bool) {
    Schemas.Trip memory trip = TripServiceStorage.getTrip(tripId);
    return (trip.carId == carId) && (trip.endDateTime > startDateTime) && (trip.startDateTime < endDateTime);
  }
}
