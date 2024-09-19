// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../proxy/UUPSAccess.sol';
import '../Schemas.sol';
import '../RentalityCarToken.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

/// Todo add geter to host insurance required
contract RentalityInsurance is Initializable, UUPSAccess {
  mapping(uint => Schemas.InsuranceCarInfo) private carIdToInsuranceRequired;
  mapping(address => Schemas.InsuranceInfo[]) private guestToInsuranceInfo;
  mapping(uint => uint) private tripIdToInsurancePaid;
  mapping(uint => Schemas.InsuranceInfo[]) private tripIdToInsuranceInfo;
  RentalityCarToken private carService;

  function saveInsuranceRequired(uint carId, uint priceInUsdCents, bool required) public {
    require(userService.isManager(msg.sender), 'Only Manager');
    require(carService.ownerOf(carId) == tx.origin, 'For car owner');

    carIdToInsuranceRequired[carId] = Schemas.InsuranceCarInfo(required, priceInUsdCents);
  }

  function saveGuestInsurance(Schemas.SaveInsuranceRequest memory insuranceInfo) public {
    require(userService.isManager(msg.sender), 'Only Manager');

    require(insuranceInfo.insuranceType != Schemas.InsuranceType.OneTime, 'Wrong Insurance type');
    Schemas.InsuranceInfo[] storage insurances = guestToInsuranceInfo[tx.origin];
    if (insuranceInfo.insuranceType == Schemas.InsuranceType.None) {
      if (insurances.length > 0) 
      insurances[insurances.length - 1].insuranceType = insuranceInfo.insuranceType;
    }
    insurances.push(Schemas.InsuranceInfo(
      insuranceInfo.companyName,
      insuranceInfo.policyNumber,
      insuranceInfo.photo,
      insuranceInfo.comment,
      insuranceInfo.insuranceType,
      block.timestamp,
      tx.origin

    ));
  }

  function saveTripInsuranceInfo(uint tripId, Schemas.SaveInsuranceRequest memory insuranceInfo) public {
    require(userService.isManager(msg.sender), 'Only Manager');
    require(insuranceInfo.insuranceType != Schemas.InsuranceType.None, 'Wrong insurance type');
    Schemas.InsuranceInfo[] storage insurances = tripIdToInsuranceInfo[tripId];
    
    insurances.push(Schemas.InsuranceInfo(
      insuranceInfo.companyName,
      insuranceInfo.policyNumber,
      insuranceInfo.photo,
      insuranceInfo.comment,
      insuranceInfo.insuranceType,
      block.timestamp,
      tx.origin

    ));
  }

  function getInsurancePriceByCar(uint carId) public view returns (uint) {
    Schemas.InsuranceCarInfo memory info = carIdToInsuranceRequired[carId];
    return info.required ? info.priceInUsdCents : 0;
  }
  function saveGuestinsurancePayment(uint tripId, uint carId, uint totalSum) public {
    require(userService.isManager(msg.sender), 'Only Manager');

    if(carIdToInsuranceRequired[carId].required) {
    Schemas.InsuranceInfo[] memory insurances = guestToInsuranceInfo[tx.origin];

    bool guestHasInsurance = (insurances.length > 0 &&
      insurances[insurances.length - 1].insuranceType == Schemas.InsuranceType.General);
      if(guestHasInsurance) 
      tripIdToInsuranceInfo[tripId] = guestToInsuranceInfo[tx.origin];

    tripIdToInsurancePaid[tripId] = totalSum;
    }
  }

  function calculateInsuranceForTrip(uint carId, uint64 startDateTime, uint64 endDateTime) public view returns (uint) {
    uint price = getInsurancePriceByCar(carId);
    Schemas.InsuranceInfo[] memory insurances = guestToInsuranceInfo[tx.origin];
    if (
      price == 0 ||
      (insurances.length > 0 &&
      insurances[insurances.length - 1].insuranceType == Schemas.InsuranceType.General)
    ) return 0;

    uint64 duration = endDateTime - startDateTime;
    uint tripInDays = Math.ceilDiv(duration, 1 days);
    return tripInDays * price;
  }

  function getInsurancePriceByTrip(uint tripId) public view returns (uint) {
    return tripIdToInsurancePaid[tripId];
  }
  function getTripInsurances(uint tripId) public view returns(Schemas.InsuranceInfo[] memory) {
  return tripIdToInsuranceInfo[tripId];
  }
  function isGuestHasInsurance(address guest) public view returns(bool) {
    Schemas.InsuranceInfo[] memory insurances = guestToInsuranceInfo[guest];
    return insurances.length > 0 &&
      insurances[insurances.length - 1].insuranceType == Schemas.InsuranceType.General;

  } 

  /// @notice Initializes the RentalityFloridaTaxes contract.
  /// @param _userService The address of the RentalityUserService contract.
  function initialize(address _userService, address _carService) public initializer {
    userService = IRentalityAccessControl(_userService);

    carService = RentalityCarToken(_carService);
  }
}
