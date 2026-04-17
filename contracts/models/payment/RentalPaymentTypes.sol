// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct RentalTripCreationPaymentRequest {
    address currencyType;
    uint256 valueSumInCurrency;
    address user;
    uint256 carId;
    address currencyFrom;
    uint256 amountIn;
    uint24 fee;
}

struct RentalTripSettlement {
    uint256 valueToHost;
    uint256 valueToGuest;
    uint256 totalIncome;
    uint256 tripCostValue;
}

struct RentalClaimPaymentRequest {
    uint256 valueToPay;
    uint256 feeInCurrency;
    uint256 commission;
    address user;
}
