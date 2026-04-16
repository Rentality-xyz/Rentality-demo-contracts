// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/booking/BookingTypes.sol";
import "../common/CommonTypes.sol";

struct CreateTripRequest {
    uint256 carId;
    uint64 startDateTime;
    uint64 endDateTime;
}

struct CreateTripRequestWithDelivery {
    uint256 carId;
    uint64 startDateTime;
    uint64 endDateTime;
    address currencyType;
    SignedLocationInfo pickUpInfo;
    SignedLocationInfo returnInfo;
    uint256 amountIn;
    uint24 fee;
}

struct CreateTripRecordRequest {
    uint256 carId;
    address guest;
    address host;
    string guestName;
    string hostName;
    uint64 pricePerDayInUsdCents;
    uint64 startDateTime;
    uint64 endDateTime;
    uint8 engineType;
    uint64 milesIncludedPerDay;
    uint64 fuelPrice;
    TripPaymentInfo paymentInfo;
    bytes32 pickUpHash;
    bytes32 returnHash;
    uint256 panelParamsCount;
    uint256 ethSumInTripCreation;
}

enum TripStatus {
    Created,
    Approved,
    CheckedInByHost,
    CheckedInByGuest,
    CheckedOutByGuest,
    CheckedOutByHost,
    Finished,
    Canceled
}

struct TripPaymentInfo {
    uint256 tripId;
    address from;
    address to;
    uint64 totalDayPriceInUsdCents;
    uint64 salesTax;
    uint64 governmentTax;
    uint64 priceWithDiscount;
    uint64 depositInUsdCents;
    uint64 resolveAmountInUsdCents;
    address currencyType;
    int256 currencyRate;
    uint8 currencyDecimals;
    uint64 resolveFuelAmountInUsdCents;
    uint64 resolveMilesAmountInUsdCents;
    uint128 pickUpFee;
    uint128 dropOfFee;
}

struct TripTransactionInfo {
    uint256 rentalityFee;
    uint256 depositRefund;
    uint256 tripEarnings;
    uint256 dateTime;
    TripStatus statusBeforeCancellation;
}

struct Trip {
    Booking booking;
    TripStatus status;
    string guestName;
    string hostName;
    uint64 pricePerDayInUsdCents;
    uint8 engineType;
    uint64 milesIncludedPerDay;
    uint64 fuelPrice;
    TripPaymentInfo paymentInfo;
    uint256 approvedDateTime;
    uint256 rejectedDateTime;
    string guestInsuranceCompanyName;
    string guestInsurancePolicyNumber;
    address rejectedBy;
    uint256 checkedInByHostDateTime;
    uint64[] startParamLevels;
    uint256 checkedInByGuestDateTime;
    address tripStartedBy;
    uint256 checkedOutByGuestDateTime;
    address tripFinishedBy;
    uint64[] endParamLevels;
    uint256 checkedOutByHostDateTime;
    TripTransactionInfo transactionInfo;
    uint256 finishDateTime;
    bytes32 pickUpHash;
    bytes32 returnHash;
}

struct TripInsuranceInfo {
    string companyName;
    string policyNumber;
    string photo;
    string comment;
    uint8 insuranceType;
    uint256 createdTime;
    address createdBy;
}

struct TripTaxValue {
    string name;
    uint32 value;
    uint8 taxType;
}

struct TripUserCurrency {
    address currency;
    string name;
    bool initialized;
}

struct TripDTO {
    Trip trip;
    string guestPhotoUrl;
    string hostPhotoUrl;
    string metadataURI;
    string timeZoneId;
    string hostDrivingLicenseNumber;
    uint64 hostDrivingLicenseExpirationDate;
    string guestDrivingLicenseNumber;
    uint64 guestDrivingLicenseExpirationDate;
    string model;
    string brand;
    uint32 yearOfProduction;
    LocationInfo pickUpLocation;
    LocationInfo returnLocation;
    string guestPhoneNumber;
    string hostPhoneNumber;
    TripInsuranceInfo[] insurancesInfo;
    uint256 paidForInsuranceInUsdCents;
    string guestDrivingLicenseIssueCountry;
    uint256 promoDiscount;
    uint256 dimoTokenId;
    TripTaxValue[] taxesData;
    TripUserCurrency currency;
    string guestNickName;
    string hostNickName;
    uint256 paidToInsuranceInUsdCents;
}

struct TripListItemDTO {
    Trip trip;
    string metadataURI;
    string timeZoneId;
    string model;
    string brand;
    uint32 yearOfProduction;
    string guestPhotoUrl;
    string hostPhotoUrl;
    string guestNickName;
    string hostNickName;
}

enum TripPaymentStatus {
    Any,
    PaidToHost,
    Unpaid,
    RefundToGuest,
    Prepayment
}

enum TripAdminStatus {
    Any,
    Created,
    Approved,
    CheckedInByHost,
    CheckedInByGuest,
    CheckedOutByGuest,
    CheckedOutByHost,
    Finished,
    GuestCanceledBeforeApprove,
    HostCanceledBeforeApprove,
    GuestCanceledAfterApprove,
    HostCanceledAfterApprove,
    CompletedWithoutGuestConfirmation,
    CompletedByGuest,
    CompletedByAdmin
}

struct TripFilter {
    TripPaymentStatus paymentStatus;
    TripAdminStatus status;
    LocationInfo location;
    uint256 startDateTime;
    uint256 endDateTime;
}
