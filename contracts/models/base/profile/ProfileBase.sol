// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ProfileTypes.sol";
import "./IProfile.sol";

abstract contract ProfileBase is IProfile {
    mapping(address => ProfileAccount) internal profileAccounts;
    mapping(address => ProfileContactInfo) internal profileContacts;
    mapping(address => ProfileConsent) internal profileConsents;

    error ProfileDoesNotExist(address user);
    error InvalidProfileUser(address user);

    event ProfileTouched(address indexed user);
    event ProfileIdentityUpdated(address indexed user, string displayName, string avatarURI);
    event ProfileContactUpdated(address indexed user, string phoneNumber, string email);
    event ProfileVerificationUpdated(address indexed user, bool isPhoneVerified, bool isEmailVerified);
    event ProfilePushTokenUpdated(address indexed user, string pushToken);
    event ProfileConsentUpdated(address indexed user, bool accepted);

    modifier profileExists(address user) {
        if (!exists(user)) {
            revert ProfileDoesNotExist(user);
        }
        _;
    }

    function exists(address user) public view virtual returns (bool) {
        return profileAccounts[user].wallet != address(0);
    }

    function getProfileAccount(address user) external view virtual profileExists(user) returns (ProfileAccount memory) {
        return profileAccounts[user];
    }

    function getProfileContact(address user) external view virtual profileExists(user) returns (ProfileContactInfo memory) {
        return profileContacts[user];
    }

    function getProfileConsent(address user) external view virtual profileExists(user) returns (ProfileConsent memory) {
        return profileConsents[user];
    }

    function _touchProfile(address user) internal virtual {
        _validateProfileUser(user);

        if (!exists(user)) {
            profileAccounts[user].wallet = user;
            profileAccounts[user].createdAt = uint64(block.timestamp);
            emit ProfileTouched(user);
        }
    }

    function _setProfileIdentity(
        address user,
        string memory displayName,
        string memory avatarURI
    ) internal virtual {
        _touchProfile(user);
        profileAccounts[user].identity = ProfileIdentity({displayName: displayName, avatarURI: avatarURI});
        emit ProfileIdentityUpdated(user, displayName, avatarURI);
    }

    function _setProfileContact(
        address user,
        string memory phoneNumber,
        string memory email
    ) internal virtual {
        _touchProfile(user);
        profileContacts[user].phoneNumber = phoneNumber;
        profileContacts[user].email = email;
        emit ProfileContactUpdated(user, phoneNumber, email);
    }

    function _setPhoneVerified(address user, bool isVerified) internal virtual {
        _touchProfile(user);
        profileContacts[user].isPhoneVerified = isVerified;
        emit ProfileVerificationUpdated(user, profileContacts[user].isPhoneVerified, profileContacts[user].isEmailVerified);
    }

    function _setEmailVerified(address user, bool isVerified) internal virtual {
        _touchProfile(user);
        profileContacts[user].isEmailVerified = isVerified;
        emit ProfileVerificationUpdated(user, profileContacts[user].isPhoneVerified, profileContacts[user].isEmailVerified);
    }

    function _setPushToken(address user, string memory pushToken) internal virtual {
        _touchProfile(user);
        profileContacts[user].pushToken = pushToken;
        emit ProfilePushTokenUpdated(user, pushToken);
    }

    function _setProfileConsent(address user, bool accepted, bytes memory signature) internal virtual {
        _touchProfile(user);
        profileConsents[user] = ProfileConsent({accepted: accepted, signature: signature});
        emit ProfileConsentUpdated(user, accepted);
    }

    function _validateProfileUser(address user) internal pure virtual {
        if (user == address(0)) {
            revert InvalidProfileUser(user);
        }
    }
}
