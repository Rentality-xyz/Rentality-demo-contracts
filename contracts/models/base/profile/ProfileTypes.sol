// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct ProfileIdentity {
    string displayName;
    string avatarURI;
}

struct ProfileContactInfo {
    string phoneNumber;
    string email;
    bool isPhoneVerified;
    bool isEmailVerified;
    string pushToken;
}

struct ProfileConsent {
    bool accepted;
    bytes signature;
}

struct ProfileAccount {
    address wallet;
    uint64 createdAt;
    ProfileIdentity identity;
}
