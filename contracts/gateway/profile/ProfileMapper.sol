// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../models/profile/UserProfileTypes.sol';
import '../../models/common/Schemas.sol';

library ProfileMapper {
    function toLegacyKyc(UserProfileKYCInfo memory profile)
        internal
        pure
        returns (Schemas.KYCInfo memory)
    {
        return Schemas.KYCInfo({
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
        returns (Schemas.AdditionalKYCInfo memory)
    {
        return Schemas.AdditionalKYCInfo({issueCountry: info.issueCountry, email: info.email});
    }

    function toLegacyFull(FullUserProfileInfo memory profile)
        internal
        pure
        returns (Schemas.FullKYCInfoDTO memory)
    {
        return Schemas.FullKYCInfoDTO({
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
        returns (Schemas.AdminKYCInfoDTO memory)
    {
        return Schemas.AdminKYCInfoDTO({
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
        returns (Schemas.AdminKYCInfosDTO memory result)
    {
        Schemas.AdminKYCInfoDTO[] memory items = new Schemas.AdminKYCInfoDTO[](page.profiles.length);
        for (uint256 i = 0; i < page.profiles.length; i++) {
            items[i] = toLegacyAdmin(page.profiles[i]);
        }
        result = Schemas.AdminKYCInfosDTO({kycInfos: items, totalPageCount: page.totalPageCount});
    }

    function toUserCivicInfo(Schemas.CivicKYCInfo memory info)
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


