// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Schemas } from "../../Schemas.sol";
import { LibDiamond } from "./LibDiamond.sol";

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
    function accessStorage() internal pure returns (InsuranceServiceFaucetStorage storage ds) {
        bytes32 position = LibDiamond.INSURANCE_STORAGE_POSITION;
        assembly { ds.slot := position }
    }
    }