// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Schemas } from "../../Schemas.sol";
import { LibDiamond } from "./LibDiamond.sol";
import '@openzeppelin/contracts/utils/math/Math.sol';

library InsuranceServiceStorage { 
    struct InsuranceServiceFaucetStorage {
        
        mapping(uint => Schemas.InsuranceCarInfo) carIdToInsuranceRequired;
        mapping(address => Schemas.InsuranceInfo[]) guestToInsuranceInfo;
        mapping(uint => uint) tripIdToInsurancePaid;
        mapping(uint => Schemas.InsuranceInfo[]) tripIdToInsuranceInfo;
    }

    function saveInsuranceRequired(uint carId, uint priceInUsdCents, bool required) internal {
    InsuranceServiceFaucetStorage storage s = accessStorage();
    s.carIdToInsuranceRequired[carId] = Schemas.InsuranceCarInfo(required, priceInUsdCents);
  }
    function calculateInsuranceForTrip(
    uint carId,
    uint64 startDateTime,
    uint64 endDateTime,
    address user
  ) internal view returns (uint) {
     InsuranceServiceFaucetStorage storage s = accessStorage();
    uint price = getInsurancePriceByCar(carId);
    Schemas.InsuranceInfo[] memory insurances = s.guestToInsuranceInfo[user];
    if (
      price == 0 ||
      (insurances.length > 0 && insurances[insurances.length - 1].insuranceType == Schemas.InsuranceType.General)
    ) return 0;

    uint64 duration = endDateTime - startDateTime;
    uint tripInDays = Math.ceilDiv(duration, 1 days);
    return tripInDays * price;
  }
     function getInsurancePriceByCar(uint carId) public view returns (uint) {
    InsuranceServiceFaucetStorage storage s = accessStorage();
    Schemas.InsuranceCarInfo memory info = s.carIdToInsuranceRequired[carId];
    return info.required ? info.priceInUsdCents : 0;
  }

  function saveGuestinsurancePayment(uint tripId, uint carId, uint totalSum, address user) internal {
    InsuranceServiceFaucetStorage storage s = accessStorage();
    if (s.carIdToInsuranceRequired[carId].required) {
      Schemas.InsuranceInfo[] memory insurances = s.guestToInsuranceInfo[user];

      bool guestHasInsurance = (insurances.length > 0 &&
        insurances[insurances.length - 1].insuranceType == Schemas.InsuranceType.General);
      if (guestHasInsurance) {
        Schemas.InsuranceInfo[] memory tripInsurances = new Schemas.InsuranceInfo[](1);
        tripInsurances[0] = insurances[insurances.length - 1];
        s.tripIdToInsuranceInfo[tripId] = tripInsurances;
      }

      s.tripIdToInsurancePaid[tripId] = totalSum;
    }
  }

    function accessStorage() internal pure returns (InsuranceServiceFaucetStorage storage ds) {
        bytes32 position = LibDiamond.INSURANCE_STORAGE_POSITION;
        assembly { ds.slot := position }
    }
    }