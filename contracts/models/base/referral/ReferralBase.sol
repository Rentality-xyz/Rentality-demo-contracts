// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './IReferral.sol';

struct ReferralPointsRule {
    bytes4 callback;
    int256 points;
    int256 pointsWithReferralCode;
}

struct TripDiscounts {
    uint256 host;
    uint256 guest;
}

abstract contract ReferralBase is IReferral {
    mapping(address => uint256) internal addressToPoints;
    mapping(uint256 => TripDiscounts) internal tripIdToDiscount;
    mapping(address => ReadyToClaim[]) internal addressToReadyToClaim;
    mapping(uint256 => uint256) internal carIdToDailyClaimed;
    mapping(address => ReferralProgramHistory[]) internal userProgramHistory;
    mapping(address => ReadyToClaimFromHash[]) internal userToReadyToClaimFromHash;
    mapping(address => bytes4) internal userToSavedHash;
    mapping(address => bytes4) internal referralHashV2;
    mapping(bytes4 => address) internal hashToOwnerV2;

    mapping(ReferralProgram => mapping(address => bool)) internal selectorToPassedAddress;
    mapping(ReferralProgram => ReferralPointsRule) internal selectorToPoints;
    mapping(ReferralProgram => ReferralPointsRule) internal permanentSelectorToPoints;
    mapping(address => uint256) internal addressToLastDailyClaim;
    mapping(ReferralProgram => uint256) internal selectorHashToPoints;
    mapping(ReferralProgram => mapping(ReferralTier => ReferralDiscount)) internal selectorToDiscounts;
    mapping(ReferralTier => TierPoints) internal tierToPoints;

    function getPointsBalance(address user) public view virtual returns (uint256) {
        return addressToPoints[user];
    }

    function getReferralHash(address user) public view virtual returns (bytes4) {
        return referralHashV2[user];
    }

    function hashExists(bytes4 hash) public view virtual returns (bool) {
        return hashToOwnerV2[hash] != address(0);
    }

    function getReadyToClaim(address user) public view virtual returns (ReadyToClaimDTO memory) {
        ReadyToClaim[] memory toClaim = addressToReadyToClaim[user];
        uint256 total;
        for (uint256 i = 0; i < toClaim.length; i++) {
            total += toClaim[i].points;
        }

        uint256 toNextDailyClaim = 0;
        uint256 last = addressToLastDailyClaim[user];
        if (block.timestamp < last + 1 days) {
            toNextDailyClaim = last + 1 days - block.timestamp;
        }

        return ReadyToClaimDTO({toClaim: toClaim, totalPoints: total, toNextDailyClaim: toNextDailyClaim});
    }

    function getReadyToClaimFromHash(address user) public view virtual returns (ReferralHashDTO memory) {
        ReadyToClaimFromHash[] memory toClaim = userToReadyToClaimFromHash[user];
        uint256 total;
        for (uint256 i = 0; i < toClaim.length; i++) {
            if (!toClaim[i].claimed) {
                total += toClaim[i].points;
            }
        }

        return ReferralHashDTO({toClaim: toClaim, totalPoints: total, hash: referralHashV2[user]});
    }

    function getPointsHistory(address user) public view virtual returns (ReferralProgramHistory[] memory) {
        return userProgramHistory[user];
    }
}
