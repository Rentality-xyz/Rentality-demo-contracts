// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../base/referral/ReferralTypes.sol';
import '../car/CarTypes.sol';
import '../common/CommonTypes.sol';

enum ReferralClaimType {
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

enum ReferralClaimCreator {
  Host,
  Guest,
  Both
}

enum ReferralClaimStatus {
  NotPaid,
  Paid,
  Cancel,
  Overdue
}

struct ReferralClaimTypeInfo {
  uint8 claimType;
  string claimName;
  ReferralClaimCreator creator;
}

struct ReferralClaimInfo {
  uint256 tripId;
  uint256 claimId;
  uint256 deadlineDateInSec;
  ReferralClaimType claimType;
  ReferralClaimStatus status;
  string description;
  uint64 amountInUsdCents;
  uint256 payDateInSec;
  address rejectedBy;
  uint256 rejectedDateInSec;
  string photosUrl;
  bool isHostClaims;
}

struct ReferralClaimInfoV2 {
  uint256 tripId;
  uint256 claimId;
  uint256 deadlineDateInSec;
  uint8 claimType;
  ReferralClaimStatus status;
  string description;
  uint64 amountInUsdCents;
  uint256 payDateInSec;
  address rejectedBy;
  uint256 rejectedDateInSec;
  string photosUrl;
  bool isHostClaims;
}

struct CreateReferralClaimRequest {
  uint256 tripId;
  uint8 claimType;
  string description;
  uint64 amountInUsdCents;
  string photosUrl;
}

struct FullReferralClaimInfo {
  ReferralClaimInfoV2 claim;
  address host;
  address guest;
  string guestPhoneNumber;
  string hostPhoneNumber;
  CarGatewayTypes.GatewayCarInfo carInfo;
  uint256 amountInEth;
  string timeZoneId;
  ReferralClaimTypeInfo claimType;
  UserCurrencyInfo currency;
}

struct CurrencyRate {
  int256 rate;
  uint8 decimals;
}

struct ReferralCallbackArgs {
  uint256 tripId;
  uint256 carId;
  address counterparty;
}
