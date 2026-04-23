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

struct RentalInsuranceDTO {
    uint256 tripId;
    string carBrand;
    string carModel;
    uint32 carYear;
    InsuranceInfo insuranceInfo;
    bool createdByHost;
    string creatorPhoneNumber;
    string creatorFullName;
    uint64 startDateTime;
    uint64 endDateTime;
    bool isActual;
}

struct RentalHostInsuranceRuleDTO {
    uint256 partToInsurance;
    uint256 insuranceId;
}
