// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../car/CarTypes.sol';
import '../common/CommonTypes.sol';

enum RentalClaimType {
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

enum RentalClaimCreator {
  Host,
  Guest,
  Both
}

enum RentalClaimStatus {
  NotPaid,
  Paid,
  Cancel,
  Overdue
}

struct RentalClaimTypeInfo {
  uint8 claimType;
  string claimName;
  RentalClaimCreator creator;
}

struct RentalClaimInfo {
  uint256 tripId;
  uint256 claimId;
  uint256 deadlineDateInSec;
  RentalClaimType claimType;
  RentalClaimStatus status;
  string description;
  uint64 amountInUsdCents;
  uint256 payDateInSec;
  address rejectedBy;
  uint256 rejectedDateInSec;
  string photosUrl;
  bool isHostClaims;
}

struct RentalClaimInfoV2 {
  uint256 tripId;
  uint256 claimId;
  uint256 deadlineDateInSec;
  uint8 claimType;
  RentalClaimStatus status;
  string description;
  uint64 amountInUsdCents;
  uint256 payDateInSec;
  address rejectedBy;
  uint256 rejectedDateInSec;
  string photosUrl;
  bool isHostClaims;
}

struct CreateClaimRequest {
  uint256 tripId;
  uint8 claimType;
  string description;
  uint64 amountInUsdCents;
  string photosUrl;
}

struct FullClaimInfo {
  RentalClaimInfoV2 claim;
  address host;
  address guest;
  string guestPhoneNumber;
  string hostPhoneNumber;
  CarGatewayTypes.GatewayCarInfo carInfo;
  uint256 amountInEth;
  string timeZoneId;
  RentalClaimTypeInfo claimType;
  UserCurrencyInfo currency;
}
