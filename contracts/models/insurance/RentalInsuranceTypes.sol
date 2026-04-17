// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../base/insurance/InsuranceTypes.sol';

struct RentalSaveInsuranceRequest {
    string companyName;
    string policyNumber;
    string photo;
    string comment;
    InsuranceType insuranceType;
}

struct RentalHostInsurancePayoutContext {
    address host;
    address currencyType;
    uint256 tripId;
}
