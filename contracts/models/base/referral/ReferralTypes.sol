// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

enum ReferralProgram {
    SetKYC,
    PassCivic,
    AddCar,
    CreateTrip,
    FinishTripAsGuest,
    UnlistedCar,
    Daily,
    DailyListing
}

enum ReferralTier {
    Tier1,
    Tier2,
    Tier3,
    Tier4
}

enum ReferralAccrualType {
    OneTime,
    Permanent
}

struct ReadyToClaim {
    uint256 points;
    ReferralProgram refType;
    bool oneTime;
}

struct ReadyToClaimFromHash {
    uint256 points;
    ReferralProgram refType;
    bool oneTime;
    bool claimed;
    address user;
}

struct TierPoints {
    uint256 from;
    uint256 to;
}

struct ReferralDiscount {
    uint256 pointsCosts;
    uint256 percents;
}

struct TierDTO {
    TierPoints points;
    ReferralTier tier;
}

struct ReadyToClaimDTO {
    ReadyToClaim[] toClaim;
    uint256 totalPoints;
    uint256 toNextDailyClaim;
}

struct ReferralHashDTO {
    ReadyToClaimFromHash[] toClaim;
    uint256 totalPoints;
    bytes4 hash;
}

struct ReferralProgramInfoDTO {
    ReferralAccrualType referralType;
    ReferralProgram method;
    int256 points;
}

struct HashPointsDTO {
    ReferralProgram method;
    uint256 points;
}

struct ReferralDiscountsDTO {
    ReferralProgram method;
    ReferralTier tier;
    ReferralDiscount discount;
}

struct AllReferralInfoDTO {
    ReferralProgramInfoDTO[] programPoints;
    HashPointsDTO[] hashPoints;
    ReferralDiscountsDTO[] discounts;
    TierDTO[] tier;
}

struct ReferralProgramHistory {
    int256 points;
    uint256 date;
    ReferralProgram method;
    bool oneTime;
}

struct MyReferralInfoDTO {
    bytes4 myHash;
    bytes4 savedHash;
}
