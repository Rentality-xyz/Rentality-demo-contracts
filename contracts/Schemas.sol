// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

interface Schemas {
  /// Car Service

  /// @notice Struct to store information about a listed car.
  struct CarInfo {
    uint256 carId;
    string carVinNumber;
    bytes32 carVinNumberHash;
    address createdBy;
    string brand;
    string model;
    uint32 yearOfProduction;
    uint64 pricePerDayInUsdCents;
    uint64 securityDepositPerTripInUsdCents;
    uint8 engineType;
    uint64[] engineParams;
    uint64 milesIncludedPerDay;
    uint32 timeBufferBetweenTripsInSec;
    bool currentlyListed;
    bool geoVerified;
    string timeZoneId;
  }

  struct PublicHostCarDTO {
    uint carId;
    string metadataURI;
    string brand;
    string model;
    uint32 yearOfProduction;
    uint64 pricePerDayInUsdCents;
    uint64 securityDepositPerTripInUsdCents;
    uint64 milesIncludedPerDay;
    bool currentlyListed;
  }

  /// @notice Holds the car information with current ability to update.
  struct CarInfoDTO {
    CarInfo carInfo;
    string metadataURI;
    bool isEditable;
  }

  /// @notice Struct to store input parameters for creating a new car.
  struct CreateCarRequest {
    string tokenUri;
    string carVinNumber;
    string brand;
    string model;
    uint32 yearOfProduction;
    uint64 pricePerDayInUsdCents;
    uint64 securityDepositPerTripInUsdCents;
    uint64[] engineParams;
    uint8 engineType;
    uint64 milesIncludedPerDay;
    uint32 timeBufferBetweenTripsInSec;
    string locationAddress;
    string locationLatitude;
    string locationLongitude;
    string geoApiKey;
  }

  /// @notice Struct to store input parameters for updating car information.
  struct UpdateCarInfoRequest {
    uint256 carId;
    uint64 pricePerDayInUsdCents;
    uint64 securityDepositPerTripInUsdCents;
    uint64[] engineParams;
    uint64 milesIncludedPerDay;
    uint32 timeBufferBetweenTripsInSec;
    bool currentlyListed;
  }

  /// @notice Struct to store search parameters for querying cars.
  struct SearchCarParams {
    string country;
    string state;
    string city;
    string brand;
    string model;
    uint32 yearOfProductionFrom;
    uint32 yearOfProductionTo;
    uint64 pricePerDayInUsdCentsFrom;
    uint64 pricePerDayInUsdCentsTo;
  }

  /// Trip Service

  /// @dev Struct representing the parameters for creating a trip request.
  struct CreateTripRequest {
    uint256 carId;
    uint64 startDateTime;
    uint64 endDateTime;
    address currencyType;
  }

  /// @dev Enumeration representing verious states of a trip.
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

  // Struct to store transaction history details for a trip
  // Earnings from the trip (cancellation or completion)
  // datetime: Timestamp of the transaction
  // Status before trip cancellation, will be 'Finished' in case of completed trip.
  struct TransactionInfo {
    uint256 rentalityFee;
    uint256 depositRefund;
    uint256 tripEarnings;
    uint256 dateTime;
    TripStatus statusBeforeCancellation;
  }
  /// @dev Struct containing information about a trip.
  struct Trip {
    uint256 tripId;
    uint256 carId;
    TripStatus status;
    address guest;
    address host;
    string guestName;
    string hostName;
    uint64 pricePerDayInUsdCents;
    uint64 startDateTime;
    uint64 endDateTime;
    uint8 engineType;
    string startLocation;
    string endLocation;
    uint64 milesIncludedPerDay;
    uint64 fuelPrice;
    PaymentInfo paymentInfo;
    uint createdDateTime;
    uint approvedDateTime;
    uint rejectedDateTime;
    address rejectedBy;
    uint checkedInByHostDateTime;
    uint64[] startParamLevels;
    uint checkedInByGuestDateTime;
    address tripStartedBy;
    uint checkedOutByGuestDateTime;
    address tripFinishedBy;
    uint64[] endParamLevels;
    uint checkedOutByHostDateTime;
    TransactionInfo transactionInfo;
  }

  struct TripDTO {
    Trip trip;
    string guestPhotoUrl;
    string hostPhotoUrl;
    string metadataURI;
    string timeZoneId;
  }

  /// CHAT LOGIC

  /// @dev Struct representing information about a chat related to a trip.
  struct ChatInfo {
    uint256 tripId;
    address guestAddress;
    string guestName;
    string guestPhotoUrl;
    address hostAddress;
    string hostName;
    string hostPhotoUrl;
    uint256 tripStatus;
    string carBrand;
    string carModel;
    uint32 carYearOfProduction;
    string carMetadataUrl;
    uint64 startDateTime;
    uint64 endDateTime;
    string timeZoneId;
  }

  /// @dev Struct to represent a pair of private and public chat keys
  struct ChatKeyPair {
    string privateKey;
    string publicKey;
  }

  /// @dev Struct to associate an Ethereum address with a public chat key
  struct AddressPublicKey {
    address userAddress;
    string publicKey;
  }

  /// Claims

  // Struct to represent additional information about a claim
  struct FullClaimInfo {
    Claim claim;
    address host;
    address guest;
    string guestPhoneNumber;
    string hostPhoneNumber;
    CarInfo carInfo;
    uint amountInEth;
  }

  // Struct to represent a claim
  struct Claim {
    uint256 tripId;
    uint256 claimId;
    uint256 deadlineDateInSec;
    ClaimType claimType;
    ClaimStatus status;
    string description;
    uint64 amountInUsdCents;
    uint256 payDateInSec;
    address rejectedBy;
    uint256 rejectedDateInSec;
  }

  // Struct to represent a request to create a new claim
  struct CreateClaimRequest {
    uint256 tripId;
    ClaimType claimType;
    string description;
    uint64 amountInUsdCents;
  }

  // Enumeration for types of claims
  enum ClaimType {
    Tolls,
    Tickets,
    LateReturn,
    Cleanliness,
    Smoking,
    ExteriorDamage,
    InteriorDamage,
    Other
  }

  // Enumeration for claim statuses
  enum ClaimStatus {
    NotPaid,
    Paid,
    Cancel,
    Overdue
  }

  /// GEO

  /// @dev Struct to store parsed geolocation data.
  struct ParsedGeolocationData {
    string status;
    bool validCoordinates;
    string locationLat;
    string locationLng;
    string northeastLat;
    string northeastLng;
    string southwestLat;
    string southwestLng;
    string city;
    string state;
    string country;
    string timeZoneId;
  }

  /// Payments

  /// @dev Enumeration representing the currency type used for payments.
  enum CurrencyType {
    ETH
  }

  /// @dev Struct containing payment information for a trip.

  /// @dev Struct containing payment information for a trip.
  struct PaymentInfo {
    uint256 tripId;
    address from;
    address to;
    uint64 totalDayPriceInUsdCents;
    uint64 taxPriceInUsdCents;
    uint64 priceWithDiscount;
    uint64 depositInUsdCents;
    uint64 resolveAmountInUsdCents;
    address currencyType; // tokenAddress, address(0) if eth
    int256 currencyRate;
    uint8 currencyDecimals;
    uint64 resolveFuelAmountInUsdCents;
    uint64 resolveMilesAmountInUsdCents;
  }

  struct TripReceiptDTO {
    uint64 totalDayPriceInUsdCents;
    uint64 totalTripDays;
    uint64 tripPrice;
    uint64 discountAmount;
    uint64 taxes;
    uint64 depositReceived;
    uint64 reimbursement;
    uint64 depositReturned;
    uint64 refuel;
    uint64 refuelPricePerUnit;
    uint64 refuelOrRechargeTotalPrice;
    uint64 milesIncluded;
    uint64 overmiles;
    uint64 pricePerOvermileInCents;
    uint64 overmileCharge;
    uint64 startFuelLevel;
    uint64 endFuelLevel;
    uint64 startOdometer;
    uint64 endOdometer;
  }

  struct CalculatePaymentsDTO {
    uint totalPrice;
    int currencyRate;
    uint8 currencyDecimals;
  }

  /// User service

  // Struct to store KYC (Know Your Customer) information for each user
  struct KYCInfo {
    string name;
    string surname;
    string mobilePhoneNumber;
    string profilePhoto;
    string licenseNumber;
    uint64 expirationDate;
    uint createDate;
    bool isTCPassed;
    bytes TCSignature;
  }

  /// Query

  struct SearchCar {
    uint carId;
    string brand;
    string model;
    uint32 yearOfProduction;
    uint64 pricePerDayInUsdCents;
    uint64 pricePerDayWithDiscount;
    uint64 tripDays;
    uint64 totalPriceWithDiscount;
    uint64 taxes;
    uint64 securityDepositPerTripInUsdCents;
    uint8 engineType;
    uint64 milesIncludedPerDay;
    address host;
    string hostName;
    string hostPhotoUrl;
    string city;
    string country;
    string state;
    string locationLatitude;
    string locationLongitude;
    string timeZoneId;
    string metadataURI;
  }

  struct GeoData {
    string city;
    string country;
    string state;
    string locationLatitude;
    string locationLongitude;
    string timeZoneId;
    string metadataURI;
  }

  struct CarDetails {
    uint carId;
    string hostName;
    string hostPhotoUrl;
    address host;
    string brand;
    string model;
    uint32 yearOfProduction;
    uint64 pricePerDayInUsdCents;
    uint64 securityDepositPerTripInUsdCents;
    uint64 milesIncludedPerDay;
    uint8 engineType;
    uint64[] engineParams;
    bool geoVerified;
    bool currentlyListed;
    string timeZoneId;
    string city;
    string country;
    string state;
    string locationLatitude;
    string locationLongitude;
  }

  // Taxes
  struct FloridaTaxes {
    uint32 salesTaxPPM;
    uint32 governmentTaxPerDayInUsdCents;
  }

  // Discounts
  struct BaseDiscount {
    uint32 threeDaysDiscount;
    uint32 sevenDaysDiscount;
    uint32 thirtyDaysDiscount;
    bool initialized;
  }

  enum TaxesLocationType {
    City,
    State,
    Country
  }
}
