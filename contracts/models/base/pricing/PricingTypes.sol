// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct PricingPolicy {
    uint32 platformFeeInPPM;
    bool initialized;
}

struct PricingQuote {
    uint256 subtotal;
    uint256 discount;
    uint256 tax;
    uint256 total;
    address currency;
}
