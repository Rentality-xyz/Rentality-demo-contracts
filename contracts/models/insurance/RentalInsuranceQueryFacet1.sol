// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../rentality_old/Schemas.sol';

interface IRentalInsuranceQueryFacet1CarService {
  function getCarInfoById(uint256 carId) external view returns (Schemas.CarInfo memory);
}

interface IRentalInsuranceQueryFacet1TripService {
  function getTripsByUser(address user) external view returns (uint256[] memory);
  function getTrip(uint256 tripId) external view returns (Schemas.Trip memory);
}

interface IRentalInsuranceQueryFacet1UserService {
  function getKYCInfo(address user) external view returns (Schemas.KYCInfo memory);
}

interface IRentalInsuranceQueryFacet1InsuranceService {
  function getTripInsurances(uint256 tripId) external view returns (Schemas.InsuranceInfo[] memory);
  function getMyInsurancesAsGuest(address user) external view returns (Schemas.InsuranceInfo[] memory);
  function findActualInsurance(Schemas.InsuranceInfo[] memory insurances) external pure returns (uint256, uint256);
}

contract RentalInsuranceQueryFacet1 {
  IRentalInsuranceQueryFacet1CarService public immutable carService;
  IRentalInsuranceQueryFacet1TripService public immutable tripService;
  IRentalInsuranceQueryFacet1UserService public immutable userService;
  IRentalInsuranceQueryFacet1InsuranceService public immutable insuranceService;

  constructor(
    address carServiceAddress,
    address tripServiceAddress,
    address userServiceAddress,
    address insuranceServiceAddress
  ) {
    carService = IRentalInsuranceQueryFacet1CarService(carServiceAddress);
    tripService = IRentalInsuranceQueryFacet1TripService(tripServiceAddress);
    userService = IRentalInsuranceQueryFacet1UserService(userServiceAddress);
    insuranceService = IRentalInsuranceQueryFacet1InsuranceService(insuranceServiceAddress);
  }

  function getInsurancesBy(bool host, address user) external view returns (Schemas.InsuranceDTO[] memory) {
    return host ? _getTripInsurancesByHost(user) : _getTripInsurancesByGuest(user);
  }

  function getMyInsurancesAsGuest(address user) external view returns (Schemas.InsuranceInfo[] memory) {
    return insuranceService.getMyInsurancesAsGuest(user);
  }

  function _getTripInsurancesByGuest(address guest) internal view returns (Schemas.InsuranceDTO[] memory) {
    uint256 itemCount;
    uint256[] memory userTrips = tripService.getTripsByUser(guest);
    for (uint256 i = 0; i < userTrips.length; i++) {
      itemCount += insuranceService.getTripInsurances(userTrips[i]).length;
    }

    Schemas.InsuranceInfo[] memory guestInsurances = insuranceService.getMyInsurancesAsGuest(guest);
    uint256 itemCountWithoutGuestInsurances = itemCount;
    itemCount += guestInsurances.length;

    Schemas.InsuranceDTO[] memory insurances = new Schemas.InsuranceDTO[](itemCount);
    uint256 counter;
    for (uint256 i = 0; i < userTrips.length; i++) {
      Schemas.Trip memory trip = tripService.getTrip(userTrips[i]);
      Schemas.InsuranceInfo[] memory tripInsurances = insuranceService.getTripInsurances(userTrips[i]);
      for (uint256 j = 0; j < tripInsurances.length; j++) {
        insurances[counter] = _fullFillInsuranceDTO(
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
    uint256 currentCount
  ) internal view returns (Schemas.InsuranceDTO[] memory result) {
    uint256 lastOneTimeTimestamp;
    uint256 lastGeneralTimestamp;
    uint256 lastOneTimeIndex;
    uint256 lastGeneralIndex;
    uint256 counter = currentCount;

    for (uint256 i = 0; i < guestInsurances.length; i++) {
      bool alreadyExists = false;
      for (uint256 j = 0; j < currentCount; j++) {
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
        insurances[counter] = _fullFillInsuranceDTO(
          guestInsurances[i],
          false,
          0,
          0,
          0,
          false,
          type(uint256).max,
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

  function _fullFillInsuranceDTO(
    Schemas.InsuranceInfo memory insuranceInfo,
    bool isActual,
    uint64 startDateTime,
    uint64 endDateTime,
    uint256 tripId,
    bool createdByHost,
    uint256 carId,
    address creator
  ) internal view returns (Schemas.InsuranceDTO memory result) {
    Schemas.KYCInfo memory kyc = userService.getKYCInfo(creator);
    Schemas.CarInfo memory car = carService.getCarInfoById(carId);
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

  function _getTripInsurancesByHost(address host) internal view returns (Schemas.InsuranceDTO[] memory) {
    uint256 itemCount;
    uint256[] memory userTrips = tripService.getTripsByUser(host);
    for (uint256 i = 0; i < userTrips.length; i++) {
      itemCount += insuranceService.getTripInsurances(userTrips[i]).length;
    }

    Schemas.InsuranceDTO[] memory insurances = new Schemas.InsuranceDTO[](itemCount);
    uint256 counter;
    for (uint256 i = 0; i < userTrips.length; i++) {
      Schemas.Trip memory trip = tripService.getTrip(userTrips[i]);
      Schemas.InsuranceInfo[] memory tripInsurances = insuranceService.getTripInsurances(userTrips[i]);
      (uint256 oneTimeActual, uint256 generalActual) = insuranceService.findActualInsurance(tripInsurances);
      for (uint256 j = 0; j < tripInsurances.length; j++) {
        Schemas.KYCInfo memory kyc = userService.getKYCInfo(tripInsurances[j].createdBy);
        Schemas.CarInfo memory car = carService.getCarInfoById(trip.carId);
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
}
