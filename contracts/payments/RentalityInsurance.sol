// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../proxy/UUPSAccess.sol';
import '../Schemas.sol';
import '../RentalityCarToken.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

contract RentalityInsurance is Initializable, UUPSAccess {
  mapping(uint => Schemas.InsuranceCarInfo) private carIdToInsurance;
  mapping(uint => Schemas.InsuranceTripInfo) private tripIdToInsuranceTripInfo;
  RentalityCarToken private carService;

  function saveInsurance(uint carId, uint priceInUsdCents, bool required) public {
    require(userService.isManager(msg.sender), 'Only Manager');
    require(carService.ownerOf(carId) == tx.origin, 'For car owner');

    carIdToInsurance[carId] = Schemas.InsuranceCarInfo(required, priceInUsdCents);
  }

  function guestSaveTripInsurance(uint tripId, bool guestPay, string memory photo, uint totalPaid) public {
    require(userService.isManager(msg.sender), 'Only Manager');
    totalPaid = guestPay ? totalPaid : 0;
    tripIdToInsuranceTripInfo[tripId] = Schemas.InsuranceTripInfo(guestPay, photo, totalPaid);
  }

  function hostSaveTripInsurance(uint tripId, string memory photo) public {
    require(userService.isManager(msg.sender), 'Only Manager');
    Schemas.InsuranceTripInfo storage insuranceInfo = tripIdToInsuranceTripInfo[tripId];
    require(insuranceInfo.payedByGuest, 'Guest not payed');
    insuranceInfo.insurancePhoto = photo;
  }

  function getInsurancePriceByCar(uint carId) public view returns (uint) {
    Schemas.InsuranceCarInfo memory info = carIdToInsurance[carId];
    return info.required ? info.priceInUsdCents : 0;
  }

  function calculateInsuranceForTrip(uint carId, uint64 startDateTime, uint64 endDateTime) public view returns (uint) {
    uint64 duration = endDateTime - startDateTime;
    uint tripInDays = Math.ceilDiv(duration, 1 days);
    return tripInDays * carIdToInsurance[carId].priceInUsdCents;
  }

  function getInsurancePriceByTrip(uint tripId, uint carId) public view returns (uint) {
    Schemas.InsuranceCarInfo memory info = carIdToInsurance[carId];
    if (info.required) {
      Schemas.InsuranceTripInfo memory tripInfo = tripIdToInsuranceTripInfo[tripId];
      return tripInfo.payedByGuest ? tripInfo.totalPaid : 0;
    }
    return 0;
  }

  /// @notice Initializes the RentalityFloridaTaxes contract.
  /// @param _userService The address of the RentalityUserService contract.
  function initialize(address _userService, address _carService) public initializer {
    userService = IRentalityAccessControl(_userService);

    carService = RentalityCarToken(_carService);
  }
}
