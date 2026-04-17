// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

enum InsuranceType {
    None,
    General,
    OneTime
}

struct InsuranceRequirement {
    bool required;
    uint256 priceInUsdCents;
}

struct InsuranceInfo {
    string companyName;
    string policyNumber;
    string photo;
    string comment;
    InsuranceType insuranceType;
    uint256 createdTime;
    address createdBy;
}

struct InsuranceRule {
    uint256 partToInsurance;
    uint256 insuranceId;
}

struct InsuranceAverage {
    uint256 totalTripsCount;
    uint256 totalPercents;
}
