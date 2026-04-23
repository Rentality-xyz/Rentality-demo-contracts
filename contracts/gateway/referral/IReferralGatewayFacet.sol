// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../models/base/referral/ReferralTypes.sol';

interface IReferralGatewayFacet {
    function addressToPoints(address user) external view returns (uint256);
    function referralHashV2(address user) external view returns (bytes4);
    function getCarDailyClaimedTime(uint256 carId) external view returns (uint64);
    function getMyStartDiscount(address user) external view returns (ReferralDiscount memory);
    function getReadyToClaim(address user) external view returns (ReadyToClaimDTO memory readyToClaimDTO);
    function getReadyToClaimFromRefferalHash(address user)
        external
        view
        returns (ReferralHashDTO memory refferalHashDTO);
    function getRefferalPointsInfo()
        external
        view
        returns (AllReferralInfoDTO memory allRefferalInfoDTO);
    function getPointsHistory() external view returns (ReferralProgramHistory[] memory);
    function getMyRefferalInfo() external view returns (MyReferralInfoDTO memory myRefferalInfoDTO);
    function claimPoints(address user) external;
    function claimRefferalPoints(address user) external;
    function hashExists(bytes32 referralHash) external view returns (bool);
}
