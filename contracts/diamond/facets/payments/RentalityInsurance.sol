// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../Schemas.sol";
import {UserServiceStorage} from "../../libraries/UserServiceStorage.sol";
import {InsuranceServiceStorage} from "../../libraries/InsuranceServiceStorage.sol";
import {TripServiceStorage} from "../../libraries/TripServiceStorage.sol";
contract RentalityInsuranceFacet {

    function saveGuestInsurance(Schemas.SaveInsuranceRequest memory insuranceInfo) public {
      address user = msg.sender;
      InsuranceServiceStorage.InsuranceServiceFaucetStorage storage s = InsuranceServiceStorage.accessStorage();

    require(insuranceInfo.insuranceType != Schemas.InsuranceType.OneTime, 'Wrong Insurance type');
    Schemas.InsuranceInfo[] storage insurances = s.guestToInsuranceInfo[user];
    if (insuranceInfo.insuranceType == Schemas.InsuranceType.None) {
      if (insurances.length > 0) insurances[insurances.length - 1].insuranceType = insuranceInfo.insuranceType;
    } else {
      if (insurances.length > 0) insurances[insurances.length - 1].insuranceType = Schemas.InsuranceType.None;

      insurances.push(
        Schemas.InsuranceInfo(
          insuranceInfo.companyName,
          insuranceInfo.policyNumber,
          insuranceInfo.photo,
          insuranceInfo.comment,
          insuranceInfo.insuranceType,
          block.timestamp,
          user
        )
      );
    }
  }
  function getMyInsurancesAsGuest() public view returns (Schemas.InsuranceInfo[] memory) {
    InsuranceServiceStorage.InsuranceServiceFaucetStorage storage s = InsuranceServiceStorage.accessStorage();
    return s.guestToInsuranceInfo[msg.sender];
  }
  
  

  function saveTripInsuranceInfo(uint tripId, Schemas.SaveInsuranceRequest memory insuranceInfo, address user) public {
    require(insuranceInfo.insuranceType != Schemas.InsuranceType.None, 'Wrong insurance type');
    Schemas.Trip memory tripInfo = TripServiceStorage.getTrip(tripId);
    require(tripInfo.host == msg.sender || tripInfo.guest == msg.sender, 'For trip host or guest');

    InsuranceServiceStorage.InsuranceServiceFaucetStorage storage s = InsuranceServiceStorage.accessStorage();
    Schemas.InsuranceInfo[] storage insurances = s.tripIdToInsuranceInfo[tripId];

    insurances.push(
      Schemas.InsuranceInfo(
        insuranceInfo.companyName,
        insuranceInfo.policyNumber,
        insuranceInfo.photo,
        insuranceInfo.comment,
        insuranceInfo.insuranceType,
        block.timestamp,
        user
      )
    );
  }


}