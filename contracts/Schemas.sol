// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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
    string location;
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

  struct AvailableCarResponse {
    CarInfo car;
    string hostPhotoUrl;
    string hostName;
  }

  /// Trip Service

  /// @dev Struct representing the parameters for creating a trip request.
  struct CreateTripRequest {
    uint256 carId;
    address host;
    uint64 startDateTime;
    uint64 endDateTime;
    string startLocation;
    string endLocation;
    uint64 totalDayPriceInUsdCents;
    uint64 taxPriceInUsdCents;
    uint64 depositInUsdCents;
    uint64[] fuelPrices;
    int256 ethToCurrencyRate;
    uint8 ethToCurrencyDecimals;
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
  struct TransactionInfo {
    uint256 rentalityFee;
    uint256 depositRefund;
    // Earnings from the trip (cancellation or completion)
    uint256 tripEarnings;
    // Timestamp of the transaction
    uint256 dateTime;
    // Status before trip cancellation, will be 'Finished' in case of completed trip.
    Schemas.TripStatus statusBeforeCancellation;
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
    string startLocation;
    string endLocation;
    uint64 milesIncludedPerDay;
    uint64[] fuelPrices;
    PaymentInfo paymentInfo;
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
    address rejectedBy; // if so
    uint256 rejectedDateInSec; // if so
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
  struct PaymentInfo {
    uint256 tripId;
    address from;
    address to;
    uint64 totalDayPriceInUsdCents;
    uint64 taxPriceInUsdCents;
    uint64 depositInUsdCents;
    uint64 resolveAmountInUsdCents;
    CurrencyType currencyType;
    int256 ethToCurrencyRate;
    uint8 ethToCurrencyDecimals;
    uint64 resolveFuelAmountInUsdCents;
    uint64 resolveMilesAmountInUsdCents;
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
    bool isKYCPassed;
    bool isTCPassed;
  }

  /// Automation

  struct AutomationData {
    uint256 tripId;
    uint256 whenToCallInSec;
    AutomationType aType;
  }
  enum AutomationType {
    Rejection,
    StartTrip,
    FinishTrip
  }
}
