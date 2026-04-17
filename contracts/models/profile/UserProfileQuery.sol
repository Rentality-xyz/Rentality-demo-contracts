// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './UserProfileMain.sol';
import './UserProfileTypes.sol';

contract UserProfileQuery {
    UserProfileMain public immutable userProfileMain;

    constructor(address userProfileMainAddress) {
        userProfileMain = UserProfileMain(userProfileMainAddress);
    }

    function getKYCInfo(address user) external view returns (UserProfileKYCInfo memory) {
        return userProfileMain.getKYCProfile(user);
    }

    function getMyFullKYCInfo(address user) public view returns (FullUserProfileInfo memory) {
        return FullUserProfileInfo({
            kyc: userProfileMain.getKYCProfile(user),
            additionalKYC: userProfileMain.getAdditionalProfile(user),
            contact: userProfileMain.getProfileContact(user)
        });
    }

    function getPlatformUsersKYCInfos(uint256 page, uint256 itemsPerPage)
        external
        view
        returns (AdminUserProfilePage memory)
    {
        require(userProfileMain.isAdminViewRole(tx.origin), 'Only Admin');
        require(page > 0, 'Page must be positive');
        require(itemsPerPage > 0, 'Items per page must be positive');

        uint256 totalUsersAmount = userProfileMain.getPlatformUsersCount();
        uint256 totalPageCount = (totalUsersAmount + itemsPerPage - 1) / itemsPerPage;

        if (page > totalPageCount && totalPageCount > 0) {
            page = totalPageCount;
        }

        uint256 startIndex = (page - 1) * itemsPerPage;
        uint256 endIndex = startIndex + itemsPerPage;
        if (endIndex > totalUsersAmount) {
            endIndex = totalUsersAmount;
        }

        if (startIndex >= endIndex) {
            return AdminUserProfilePage({profiles: new AdminUserProfileInfo[](0), totalPageCount: totalPageCount});
        }

        AdminUserProfileInfo[] memory result = new AdminUserProfileInfo[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            address user = userProfileMain.getPlatformUserAt(i);
            FullUserProfileInfo memory profile = getMyFullKYCInfo(user);
            result[i - startIndex] = AdminUserProfileInfo({
                kyc: profile.kyc,
                additionalKYC: profile.additionalKYC,
                wallet: user,
                isEmailVerified: profile.contact.isEmailVerified,
                pushToken: profile.contact.pushToken
            });
        }

        return AdminUserProfilePage({profiles: result, totalPageCount: totalPageCount});
    }

    function hasValidKYC(address user) external view returns (bool) {
        UserProfileKYCInfo memory kycInfo = userProfileMain.getKYCProfile(user);
        return kycInfo.createDate > 0 && kycInfo.expirationDate > block.timestamp;
    }

    function getPlatformUsersCount() external view returns (uint256) {
        return userProfileMain.getPlatformUsersCount();
    }

    function getPlatformUsers() external view returns (address[] memory) {
        return userProfileMain.getPlatformUsers();
    }

    function getKycCommission() external view returns (uint256) {
        return userProfileMain.getKycCommission();
    }

    function isCommissionPaidForUser(address user) external view returns (bool) {
        return userProfileMain.isCommissionPaidForUser(user);
    }
}
