// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/profile/ProfileTypes.sol";

struct UserProfileKYCInfo {
    string name;
    string surname;
    string mobilePhoneNumber;
    string profilePhoto;
    string licenseNumber;
    uint64 expirationDate;
    uint256 createDate;
    bool isTermsPassed;
    bytes termsSignature;
}

struct UserProfileAdditionalInfo {
    string issueCountry;
    string email;
}

struct FullUserProfileInfo {
    UserProfileKYCInfo kyc;
    UserProfileAdditionalInfo additionalKYC;
    ProfileContactInfo contact;
}

struct AdminUserProfileInfo {
    UserProfileKYCInfo kyc;
    UserProfileAdditionalInfo additionalKYC;
    address wallet;
    bool isEmailVerified;
    string pushToken;
}

struct AdminUserProfilePage {
    AdminUserProfileInfo[] profiles;
    uint256 totalPageCount;
}

struct CivicUserProfileInfo {
    string fullName;
    string licenseNumber;
    uint64 expirationDate;
    string issueCountry;
    string email;
}

struct GatewayUserProfileKYCInfo {
    string name;
    string surname;
    string mobilePhoneNumber;
    string profilePhoto;
    string licenseNumber;
    uint64 expirationDate;
    uint256 createDate;
    bool isTCPassed;
    bytes TCSignature;
}

struct GatewayUserProfileAdditionalInfo {
    string issueCountry;
    string email;
}

struct GatewayFullUserProfileInfo {
    GatewayUserProfileKYCInfo kyc;
    GatewayUserProfileAdditionalInfo additionalKYC;
    bool isPhoneVerified;
    bool isEmailVerified;
    string pushToken;
}

struct GatewayAdminUserProfileInfo {
    GatewayUserProfileKYCInfo kyc;
    GatewayUserProfileAdditionalInfo additionalKYC;
    address wallet;
    bool isEmailVerified;
    string pushToken;
}

struct GatewayAdminUserProfilePage {
    GatewayAdminUserProfileInfo[] kycInfos;
    uint256 totalPageCount;
}

struct GatewayCivicUserProfileInfo {
    string fullName;
    string licenseNumber;
    uint64 expirationDate;
    string issueCountry;
    string email;
}

struct PlatformInfoDTO {
    uint256 totalUsers;
    uint256 totalTrips;
    uint256 totalCars;
}

struct SetUserProfileRequest {
    string nickName;
    string mobilePhoneNumber;
    string profilePhoto;
    string email;
    bytes termsSignature;
}

struct UserProfileCommissionRecord {
    uint256 paidTime;
    bool commissionPaid;
}

enum UserProfileRole {
    Guest,
    Host,
    Manager,
    Admin,
    KYCManager,
    AdminView,
    InvestmentManager,
    OracleManager
}
