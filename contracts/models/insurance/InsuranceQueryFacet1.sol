// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../car/CarTypes.sol';
import '../profile/UserProfileTypes.sol';
import '../base/insurance/InsuranceTypes.sol';
import './InsuranceTypes.sol';
import '../trip/TripTypes.sol';

interface IInsuranceQueryFacet1CarService {
  function getCarInfoById(uint256 carId) external view returns (CarGatewayTypes.GatewayCarInfo memory);
}

interface IInsuranceQueryFacet1TripQuery {
  function getTripsByUser(address user) external view returns (uint256[] memory);
  function getTrip(uint256 tripId) external view returns (Trip memory);
}

interface IInsuranceQueryFacet1UserService {
  function getKYCInfo(address user) external view returns (UserProfileKYCInfo memory);
}

interface IInsuranceQueryFacet1InsuranceService {
  function getTripInsurances(uint256 tripId) external view returns (InsuranceInfo[] memory);
  function getMyInsurancesAsGuest(address user) external view returns (InsuranceInfo[] memory);
  function findActualInsurance(InsuranceInfo[] memory insurances) external pure returns (uint256, uint256);
}

contract InsuranceQueryFacet1 {
  IInsuranceQueryFacet1CarService public immutable carService;
  IInsuranceQueryFacet1TripQuery public immutable tripQuery;
  IInsuranceQueryFacet1UserService public immutable userService;
  IInsuranceQueryFacet1InsuranceService public immutable insuranceService;

  constructor(
    address carServiceAddress,
    address tripQueryAddress,
    address userServiceAddress,
    address insuranceServiceAddress
  ) {
    carService = IInsuranceQueryFacet1CarService(carServiceAddress);
    tripQuery = IInsuranceQueryFacet1TripQuery(tripQueryAddress);
    userService = IInsuranceQueryFacet1UserService(userServiceAddress);
    insuranceService = IInsuranceQueryFacet1InsuranceService(insuranceServiceAddress);
  }

  function getInsurancesBy(bool host, address user) external view returns (InsuranceDTO[] memory) {
    return host ? _getTripInsurancesByHost(user) : _getTripInsurancesByGuest(user);
  }

  function getMyInsurancesAsGuest(address user) external view returns (InsuranceInfo[] memory) {
    return insuranceService.getMyInsurancesAsGuest(user);
  }

  function _getTripInsurancesByGuest(address guest) internal view returns (InsuranceDTO[] memory) {
    uint256 itemCount;
    uint256[] memory userTrips = tripQuery.getTripsByUser(guest);
    for (uint256 i = 0; i < userTrips.length; i++) {
      itemCount += insuranceService.getTripInsurances(userTrips[i]).length;
    }

    InsuranceInfo[] memory guestInsurances = insuranceService.getMyInsurancesAsGuest(guest);
    uint256 itemCountWithoutGuestInsurances = itemCount;
    itemCount += guestInsurances.length;

    InsuranceDTO[] memory insurances = new InsuranceDTO[](itemCount);
    uint256 counter;
    for (uint256 i = 0; i < userTrips.length; i++) {
      Trip memory trip = tripQuery.getTrip(userTrips[i]);
      InsuranceInfo[] memory tripInsurances = insuranceService.getTripInsurances(userTrips[i]);
      for (uint256 j = 0; j < tripInsurances.length; j++) {
        insurances[counter] = _fullFillInsuranceDTO(
          tripInsurances[j],
          false,
          trip.booking.startDateTime,
          trip.booking.endDateTime,
          userTrips[i],
          tripInsurances[j].createdBy == trip.booking.provider,
          trip.booking.resourceId,
          tripInsurances[j].createdBy
        );
        counter += 1;
      }
    }

    return _addGuestInsurances(insurances, guestInsurances, guest, itemCountWithoutGuestInsurances);
  }

  function _addGuestInsurances(
    InsuranceDTO[] memory insurances,
    InsuranceInfo[] memory guestInsurances,
    address guest,
    uint256 currentCount
  ) internal view returns (InsuranceDTO[] memory result) {
    uint256 lastOneTimeTimestamp;
    uint256 lastGeneralTimestamp;
    uint256 lastOneTimeIndex;
    uint256 lastGeneralIndex;
    uint256 counter = currentCount;

    for (uint256 i = 0; i < guestInsurances.length; i++) {
      bool alreadyExists = false;
      for (uint256 j = 0; j < currentCount; j++) {
        if (insurances[j].insuranceInfo.insuranceType == InsuranceType.OneTime) {
          if (lastOneTimeTimestamp < insurances[j].insuranceInfo.createdTime) {
            lastOneTimeTimestamp = insurances[j].insuranceInfo.createdTime;
            lastOneTimeIndex = j;
          }
        }
        if (insurances[j].insuranceInfo.insuranceType == InsuranceType.General) {
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
    InsuranceInfo memory insuranceInfo,
    bool isActual,
    uint64 startDateTime,
    uint64 endDateTime,
    uint256 tripId,
    bool createdByHost,
    uint256 carId,
    address creator
  ) internal view returns (InsuranceDTO memory result) {
    UserProfileKYCInfo memory kyc = userService.getKYCInfo(creator);
    CarGatewayTypes.GatewayCarInfo memory car = carService.getCarInfoById(carId);
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

  function _getTripInsurancesByHost(address host) internal view returns (InsuranceDTO[] memory) {
    uint256 itemCount;
    uint256[] memory userTrips = tripQuery.getTripsByUser(host);
    for (uint256 i = 0; i < userTrips.length; i++) {
      itemCount += insuranceService.getTripInsurances(userTrips[i]).length;
    }

    InsuranceDTO[] memory insurances = new InsuranceDTO[](itemCount);
    uint256 counter;
    for (uint256 i = 0; i < userTrips.length; i++) {
      Trip memory trip = tripQuery.getTrip(userTrips[i]);
      InsuranceInfo[] memory tripInsurances = insuranceService.getTripInsurances(userTrips[i]);
      (uint256 oneTimeActual, uint256 generalActual) = insuranceService.findActualInsurance(tripInsurances);
      for (uint256 j = 0; j < tripInsurances.length; j++) {
        UserProfileKYCInfo memory kyc = userService.getKYCInfo(tripInsurances[j].createdBy);
        CarGatewayTypes.GatewayCarInfo memory car = carService.getCarInfoById(trip.booking.resourceId);
        insurances[counter].tripId = userTrips[i];
        insurances[counter].carBrand = car.brand;
        insurances[counter].carModel = car.model;
        insurances[counter].carYear = car.yearOfProduction;
        insurances[counter].insuranceInfo = tripInsurances[j];
        insurances[counter].createdByHost = tripInsurances[j].createdBy == trip.booking.provider;
        insurances[counter].creatorPhoneNumber = kyc.mobilePhoneNumber;
        insurances[counter].creatorFullName = kyc.surname;
        insurances[counter].startDateTime = trip.booking.startDateTime;
        insurances[counter].endDateTime = trip.booking.endDateTime;
        insurances[counter].isActual =
          (j == oneTimeActual && tripInsurances[j].insuranceType == InsuranceType.OneTime) ||
          (j == generalActual && tripInsurances[j].insuranceType == InsuranceType.General);
        counter += 1;
      }
    }

    return insurances;
  }
}
