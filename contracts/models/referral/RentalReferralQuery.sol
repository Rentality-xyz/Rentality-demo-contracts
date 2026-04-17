// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './RentalReferralMain.sol';

contract RentalReferralQuery {
    RentalReferralMain public immutable rentalReferralMain;

    constructor(address rentalReferralMainAddress) {
        rentalReferralMain = RentalReferralMain(rentalReferralMainAddress);
    }

    function getPointsBalance(address user) external view returns (uint256) {
        return rentalReferralMain.getPointsBalance(user);
    }

    function getReferralHash(address user) external view returns (bytes4) {
        return rentalReferralMain.getReferralHash(user);
    }

    function hashExists(bytes4 hash) external view returns (bool) {
        return rentalReferralMain.hashExists(hash);
    }

    function getReadyToClaim(address user) external view returns (ReadyToClaimDTO memory) {
        return rentalReferralMain.getReadyToClaim(user);
    }

    function getReadyToClaimFromHash(address user) external view returns (ReferralHashDTO memory) {
        return rentalReferralMain.getReadyToClaimFromHash(user);
    }

    function getPointsHistory(address user) external view returns (ReferralProgramHistory[] memory) {
        return rentalReferralMain.getPointsHistory(user);
    }

    function getMyStartDiscount(address user) external view returns (uint256) {
        return rentalReferralMain.getMyStartDiscount(user);
    }

    function getMyReferralInfo(address user) external view returns (MyReferralInfoDTO memory) {
        return rentalReferralMain.getMyReferralInfo(user);
    }

    function getReferralPointsInfo() external view returns (AllReferralInfoDTO memory) {
        return rentalReferralMain.getReferralPointsInfo();
    }

    function getCarDailyClaimedTime(uint256 carId) external view returns (uint256) {
        return rentalReferralMain.getCarDailyClaimedTime(carId);
    }
}
