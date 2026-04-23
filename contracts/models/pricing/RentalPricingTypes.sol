// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

enum RentalPricingTaxesLocationType {
    State,
    City,
    Country
}

enum RentalPricingTaxesType {
    InUsdCentsPerDay,
    InUsdCents,
    PPM
}

struct RentalBaseDiscount {
    uint32 threeDaysDiscount;
    uint32 sevenDaysDiscount;
    uint32 thirtyDaysDiscount;
    bool initialized;
}

struct RentalTaxValue {
    string name;
    uint32 value;
    RentalPricingTaxesType tType;
}

struct RentalTaxesInfo {
    string location;
    RentalPricingTaxesLocationType locationType;
    RentalTaxValue[] taxes;
}

struct RentalCheckPromoDTO {
    bool isFound;
    bool isValid;
    bool isDiscount;
    uint256 value;
}
