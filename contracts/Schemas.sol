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
    bool geoVerified; // unused
    string timeZoneId;
    bool insuranceIncluded; // unused
    bytes32 locationHash;
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
    uint dimoTokenId;
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
    string geoApiKey;
    SignedLocationInfo locationInfo;
    bool currentlyListed;
    bool insuranceRequired;
    uint insurancePriceInUsdCents;
    uint dimoTokenId;
    bytes signedDimoTokenId;
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
    bool insuranceRequired;
    uint insurancePriceInUsdCents;
    uint8 engineType;
    string tokenUri;
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
    LocationInfo userLocation;
  }

  /// Trip Service

  /// @dev Struct representing the parameters for creating a trip request.
  struct CreateTripRequest {
    uint256 carId;
    uint64 startDateTime;
    uint64 endDateTime;
    address currencyType;
  }

  struct CreateTripRequestWithDelivery {
    uint256 carId;
    uint64 startDateTime;
    uint64 endDateTime;
    address currencyType;
    SignedLocationInfo pickUpInfo;
    SignedLocationInfo returnInfo;
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
    uint64 milesIncludedPerDay;
    uint64 fuelPrice;
    PaymentInfo paymentInfo;
    uint createdDateTime;
    uint approvedDateTime;
    uint rejectedDateTime;
    string guestInsuranceCompanyName;
    string guestInsurancePolicyNumber;
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
    uint finishDateTime;
    bytes32 pickUpHash;
    bytes32 returnHash;
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
    InsuranceInfo[] insurancesInfo;
    uint paidForInsuranceInUsdCents;
    string guestDrivingLicenseIssueCountry;
    uint promoDiscount;
    uint dimoTokenId;
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
    string timeZoneId;
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
    string photosUrl;
    bool isHostClaims;
  }

  // Struct to represent a request to create a new claim
  struct CreateClaimRequest {
    uint256 tripId;
    ClaimType claimType;
    string description;
    uint64 amountInUsdCents;
    string photosUrl;
  }

  // Enumeration for types of claims
  enum ClaimType {
    Tolls,
    Tickets,
    LateReturn,
    Smoking,
    Cleanliness,
    ExteriorDamage,
    InteriorDamage,
    Other,
    FaultyVehicle,
    ListingMismatch
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
    uint64 salesTax;
    uint64 governmentTax;
    uint64 priceWithDiscount;
    uint64 depositInUsdCents;
    uint64 resolveAmountInUsdCents;
    address currencyType; // tokenAddress, address(0) if eth
    int256 currencyRate;
    uint8 currencyDecimals;
    uint64 resolveFuelAmountInUsdCents;
    uint64 resolveMilesAmountInUsdCents;
    uint128 pickUpFee;
    uint128 dropOfFee;
  }

  struct TripReceiptDTO {
    uint64 totalDayPriceInUsdCents;
    uint64 totalTripDays;
    uint64 tripPrice;
    uint64 discountAmount;
    uint64 salesTax;
    uint64 governmentTax;
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
    uint insuranceFee;
  }

  struct CalculatePaymentsDTO {
    uint totalPrice;
    int currencyRate;
    uint8 currencyDecimals;
  }

  /// User service

  // Struct to store KYC (Know Your Customer) information for each user
  struct KYCInfo {
    string name; //nickName
    string surname; //fullName
    string mobilePhoneNumber;
    string profilePhoto;
    string licenseNumber;
    uint64 expirationDate;
    uint createDate;
    bool isTCPassed;
    bytes TCSignature;
  }

  struct CivicKYCInfo {
    string fullName;
    string licenseNumber;
    uint64 expirationDate;
    string issueCountry;
    string email;
  }
  struct AdditionalKYCInfo {
    string issueCountry;
    string email;
  }
  struct FullKYCInfoDTO {
    KYCInfo kyc;
    AdditionalKYCInfo additionalKYC;
  }
  struct AdminKYCInfoDTO {
    KYCInfo kyc;
    AdditionalKYCInfo additionalKYC;
    address wallet;
  }

  /// Query
  struct SearchCarWithDistance {
    SearchCar car;
    int distance;
  }

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
    string metadataURI;
    uint64 underTwentyFiveMilesInUsdCents;
    uint64 aboveTwentyFiveMilesInUsdCents;
    uint64 pickUp;
    uint64 dropOf;
    bool insuranceIncluded;
    LocationInfo locationInfo;
    InsuranceCarInfo insuranceInfo;
    bool isGuestHasInsurance;
    uint dimoTokenId;
  }
  struct AvailableCarDTO {
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
    string metadataURI;
    uint64 underTwentyFiveMilesInUsdCents;
    uint64 aboveTwentyFiveMilesInUsdCents;
    uint64 pickUp;
    uint64 dropOf;
    bool insuranceIncluded;
    LocationInfo locationInfo;
    InsuranceCarInfo insuranceInfo;
    uint fuelPrice;
    BaseDiscount carDiscounts;
    uint64 salesTax;
    uint64 governmentTax;
    int128 distance;
    bool isGuestHasInsurance;
    uint dimoTokenId;
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
    LocationInfo locationInfo;
    string carVinNumber;
    string carMetadataURI;
    uint dimoTokenId;
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

  // Delivery
  struct DeliveryPrices {
    uint64 underTwentyFiveMilesInUsdCents;
    uint64 aboveTwentyFiveMilesInUsdCents;
    bool initialized;
  }

  struct DeliveryLocations {
    string pickUpLat;
    string pickUpLon;
    string returnLat;
    string returnLon;
  }

  struct DeliveryData {
    LocationInfo locationInfo;
    uint64 underTwentyFiveMilesInUsdCents;
    uint64 aboveTwentyFiveMilesInUsdCents;
    bool insuranceIncluded;
  }

  struct LocationInfo {
    string userAddress;
    string country;
    string state;
    string city;
    string latitude;
    string longitude;
    string timeZoneId;
  }

  struct SignedLocationInfo {
    LocationInfo locationInfo;
    bytes signature;
  }

  struct KycCommissionData {
    uint paidTime;
    bool commissionPaid;
  }
  // investment

  struct CarInvestment {
    CreateCarRequest car;
    uint priceInUsd;
    bool inProgress;
    uint creatorPercents;
  }

  struct ClaimInvestmentDTO {
    string tokenURI;
    uint income;
    uint myIncome;
  }

  struct InvestmentDTO {
    CarInvestment investment;
    address nft;
    uint investmentId;
    uint payedInUsd;
    address creator;
    bool isCarBought;
    uint income;
    uint myIncome;
    uint myInvestingSum;
    uint listingDate;
    uint myTokens;
    uint myPart;
    uint totalHolders;
    uint totalTokens;
  }

  struct TripFilter {
    PaymentStatus paymentStatus;
    AdminTripStatus status;
    LocationInfo location;
    uint startDateTime;
    uint endDateTime;
  }
  enum PaymentStatus {
    Any,
    PaidToHost,
    Unpaid,
    RefundToGuest,
    Prepayment
  }
  enum AdminTripStatus {
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
  struct AdminTripDTO {
    Trip trip;
    string carMetadataURI;
    LocationInfo carLocation;
    PromoDTO promoInfo;
  }

  struct AllTripsDTO {
    AdminTripDTO[] trips;
    uint totalPageCount;
  }

  struct AdminCarDTO {
    CarDetails car;
    string carMetadataURI;
  }

  struct AllCarsDTO {
    AdminCarDTO[] cars;
    uint totalPageCount;
  }

  enum Role {
    Guest,
    Host,
    Manager,
    Admin,
    KYCManager,
    AdminView
  }
  enum RefferalProgram {
    SetKYC,
    PassCivic,
    AddCar,
    CreateTrip,
    FinishTripAsGuest,
    UnlistedCar,
    Daily,
    DailyListing
  }

  enum Tear {
    Tear1,
    Tear2,
    Tear3,
    Tear4
  }
  enum RefferalAccrualType {
    OneTime,
    Permanent
  }

  struct ReadyToClaim {
    uint points;
    RefferalProgram refType;
    bool oneTime;
  }
  struct ReadyToClaimRefferalHash {
    uint points;
    RefferalProgram refType;
    bool oneTime;
    bool claimed;
  }

  struct ReadyToClaimFromHash {
    uint points;
    RefferalProgram refType;
    bool oneTime;
    bool claimed;
    address user;
  }
  struct TearPoints {
    uint from;
    uint to;
  }

  struct RefferalDiscount {
    uint pointsCosts;
    uint percents;
  }

  struct TearDTO {
    TearPoints points;
    Tear tear;
  }

  struct ReadyToClaimDTO {
    ReadyToClaim[] toClaim;
    uint totalPoints;
    uint toNextDailyClaim;
  }
  struct RefferalHashDTO {
    ReadyToClaimFromHash[] toClaim;
    uint totalPoints;
    bytes4 hash;
  }

  /// admin panel ref program info
  struct RefferalProgramInfoDTO {
    RefferalAccrualType refferalType;
    RefferalProgram method;
    int points;
  }

  struct HashPointsDTO {
    RefferalProgram method;
    uint points;
  }
  struct RefferalDiscountsDTO {
    RefferalProgram method;
    Tear tear;
    RefferalDiscount discount;
  }

  struct AllRefferalInfoDTO {
    RefferalProgramInfoDTO[] programPoints;
    HashPointsDTO[] hashPoints;
    RefferalDiscountsDTO[] discounts;
    TearDTO[] tear;
  }
  struct RefferalHistory {
    int points;
    RefferalProgram method;
  }

  struct MyRefferalInfoDTO {
    bytes4 myHash;
    bytes4 savedHash;
  }

  struct History {
    int points;
    uint date;
    RefferalProgram method;
  }

  struct ProgramHistory {
    int points;
    uint date;
    RefferalProgram method;
    bool oneTime;
  }
  enum CarUpdateStatus {
    Add,
    Update,
    Burn
  }
  enum EventType {
    Car,
    Claim,
    Trip
  }
  struct FilterInfoDTO {
    uint64 maxCarPrice;
    uint minCarYearOfProduction;
  }

  /// Insurance Info
  struct InsuranceCarInfo {
    bool required;
    uint priceInUsdCents;
  }

  struct SaveInsuranceRequest {
    string companyName;
    string policyNumber;
    string photo;
    string comment;
    InsuranceType insuranceType;
  }

  struct InsuranceInfo {
    string companyName;
    string policyNumber;
    string photo;
    string comment;
    InsuranceType insuranceType;
    uint createdTime;
    address createdBy;
  }
  enum InsuranceType {
    None,
    General,
    OneTime
  }
  struct InsuranceDTO {
    uint tripId;
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
  struct CarInfoWithInsurance {
    CarInfo carInfo;
    InsuranceCarInfo insuranceInfo;
    string carMetadataURI;
  }

  struct PromoUsedInfo {
    Promo promo;
    string promoCode;
    uint usedAt;
  }

  struct Promo {
    PromoType promoType;
    string code;
    uint startDate;
    uint expireDate;
    address createdBy;
    uint createdAt;
    PromoStatus status;
  }

  enum PromoType {
    OneTime,
    Wildcard
  }

  enum PromoStatus {
    Active,
    Idle,
    Used
  }
  struct PromoTripData {
    string promo;
    uint hostEarningsInCurrency;
    uint hostEarnings;
  }
  struct CheckPromoDTO {
    bool isFound;
    bool isValid;
    bool isDiscount;
    uint value;
  }

  struct DimoTokensData {
    uint dimoTokenId;
    uint rentalityTokenId;
}

  struct PromoDTO {
    string promoCode;
    uint promoCodeValueInPercents;
    uint promoCodeEnterDate;
  }

}
