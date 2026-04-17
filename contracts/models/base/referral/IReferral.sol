// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './ReferralTypes.sol';

interface IReferral {
    function getPointsBalance(address user) external view returns (uint256);
    function getReferralHash(address user) external view returns (bytes4);
    function hashExists(bytes4 hash) external view returns (bool);
    function getReadyToClaim(address user) external view returns (ReadyToClaimDTO memory);
    function getReadyToClaimFromHash(address user) external view returns (ReferralHashDTO memory);
    function getPointsHistory(address user) external view returns (ReferralProgramHistory[] memory);
}
