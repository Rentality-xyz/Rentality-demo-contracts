// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

enum PricingTaxesLocationType {
    State,
    City,
    Country
}

enum PricingTaxesType {
    InUsdCentsPerDay,
    InUsdCents,
    PPM
}

struct PricingBaseDiscount {
    uint32 threeDaysDiscount;
    uint32 sevenDaysDiscount;
    uint32 thirtyDaysDiscount;
    bool initialized;
}

struct PricingTaxValue {
    string name;
    uint32 value;
    PricingTaxesType tType;
}

struct PricingTaxesInfo {
    string location;
    PricingTaxesLocationType locationType;
    PricingTaxValue[] taxes;
}

struct PricingCheckPromoDTO {
    bool isFound;
    bool isValid;
    bool isDiscount;
    uint256 value;
}
