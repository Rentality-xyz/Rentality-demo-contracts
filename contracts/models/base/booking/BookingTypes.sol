// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct Booking {
    uint256 id;
    uint256 resourceId;
    address customer;
    address provider;
    uint64 startDateTime;
    uint64 endDateTime;
    uint64 createdAt;
}

struct BookingWindow {
    uint64 startDateTime;
    uint64 endDateTime;
}

struct BookingParties {
    address customer;
    address provider;
}

struct BookingPaymentSnapshot {
    address currencyType;
    int256 currencyRate;
    uint8 currencyDecimals;
}
