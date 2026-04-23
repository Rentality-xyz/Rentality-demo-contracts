// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../models/profile/UserProfileTypes.sol';

library ProfileMapper {
    function toLegacyKyc(UserProfileKYCInfo memory profile)
        internal
        pure
        returns (GatewayUserProfileKYCInfo memory)
    {
        return GatewayUserProfileKYCInfo({
            name: profile.name,
            surname: profile.surname,
            mobilePhoneNumber: profile.mobilePhoneNumber,
            profilePhoto: profile.profilePhoto,
            licenseNumber: profile.licenseNumber,
            expirationDate: profile.expirationDate,
            createDate: profile.createDate,
            isTCPassed: profile.isTermsPassed,
            TCSignature: profile.termsSignature
        });
    }

    function toLegacyAdditional(UserProfileAdditionalInfo memory info)
        internal
        pure
        returns (GatewayUserProfileAdditionalInfo memory)
    {
        return GatewayUserProfileAdditionalInfo({issueCountry: info.issueCountry, email: info.email});
    }

    function toLegacyFull(FullUserProfileInfo memory profile)
        internal
        pure
        returns (GatewayFullUserProfileInfo memory)
    {
        return GatewayFullUserProfileInfo({
            kyc: toLegacyKyc(profile.kyc),
            additionalKYC: toLegacyAdditional(profile.additionalKYC),
            isPhoneVerified: profile.contact.isPhoneVerified,
            isEmailVerified: profile.contact.isEmailVerified,
            pushToken: profile.contact.pushToken
        });
    }

    function toLegacyAdmin(AdminUserProfileInfo memory profile)
        internal
        pure
        returns (GatewayAdminUserProfileInfo memory)
    {
        return GatewayAdminUserProfileInfo({
            kyc: toLegacyKyc(profile.kyc),
            additionalKYC: toLegacyAdditional(profile.additionalKYC),
            wallet: profile.wallet,
            isEmailVerified: profile.isEmailVerified,
            pushToken: profile.pushToken
        });
    }

    function toLegacyAdminPage(AdminUserProfilePage memory page)
        internal
        pure
        returns (GatewayAdminUserProfilePage memory result)
    {
        GatewayAdminUserProfileInfo[] memory items = new GatewayAdminUserProfileInfo[](page.profiles.length);
        for (uint256 i = 0; i < page.profiles.length; i++) {
            items[i] = toLegacyAdmin(page.profiles[i]);
        }
        result = GatewayAdminUserProfilePage({kycInfos: items, totalPageCount: page.totalPageCount});
    }

    function toUserCivicInfo(GatewayCivicUserProfileInfo memory info)
        internal
        pure
        returns (CivicUserProfileInfo memory)
    {
        return CivicUserProfileInfo({
            fullName: info.fullName,
            licenseNumber: info.licenseNumber,
            expirationDate: info.expirationDate,
            issueCountry: info.issueCountry,
            email: info.email
        });
    }
}


