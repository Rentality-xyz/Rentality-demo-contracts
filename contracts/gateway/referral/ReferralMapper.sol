// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../models/base/referral/ReferralTypes.sol';
import '../../models/common/Schemas.sol';

library ReferralMapper {
    function toLegacyReadyToClaimDTO(ReadyToClaimDTO memory dto)
        internal
        pure
        returns (Schemas.ReadyToClaimDTO memory)
    {
        Schemas.ReadyToClaim[] memory toClaim = new Schemas.ReadyToClaim[](dto.toClaim.length);
        for (uint256 i = 0; i < dto.toClaim.length; i++) {
            toClaim[i] = Schemas.ReadyToClaim({
                points: dto.toClaim[i].points,
                refType: toLegacyProgram(dto.toClaim[i].refType),
                oneTime: dto.toClaim[i].oneTime
            });
        }

        return Schemas.ReadyToClaimDTO({
            toClaim: toClaim,
            totalPoints: dto.totalPoints,
            toNextDailyClaim: dto.toNextDailyClaim
        });
    }

    function toLegacyReferralHashDTO(ReferralHashDTO memory dto)
        internal
        pure
        returns (Schemas.RefferalHashDTO memory)
    {
        Schemas.ReadyToClaimFromHash[] memory toClaim = new Schemas.ReadyToClaimFromHash[](dto.toClaim.length);
        for (uint256 i = 0; i < dto.toClaim.length; i++) {
            toClaim[i] = Schemas.ReadyToClaimFromHash({
                points: dto.toClaim[i].points,
                refType: toLegacyProgram(dto.toClaim[i].refType),
                oneTime: dto.toClaim[i].oneTime,
                claimed: dto.toClaim[i].claimed,
                user: dto.toClaim[i].user
            });
        }

        return Schemas.RefferalHashDTO({toClaim: toClaim, totalPoints: dto.totalPoints, hash: dto.hash});
    }

    function toLegacyAllReferralInfoDTO(AllReferralInfoDTO memory dto)
        internal
        pure
        returns (Schemas.AllRefferalInfoDTO memory)
    {
        Schemas.RefferalProgramInfoDTO[] memory programPoints =
            new Schemas.RefferalProgramInfoDTO[](dto.programPoints.length);
        for (uint256 i = 0; i < dto.programPoints.length; i++) {
            programPoints[i] = Schemas.RefferalProgramInfoDTO({
                refferalType: toLegacyAccrualType(dto.programPoints[i].referralType),
                method: toLegacyProgram(dto.programPoints[i].method),
                points: dto.programPoints[i].points
            });
        }

        Schemas.HashPointsDTO[] memory hashPoints = new Schemas.HashPointsDTO[](dto.hashPoints.length);
        for (uint256 i = 0; i < dto.hashPoints.length; i++) {
            hashPoints[i] = Schemas.HashPointsDTO({
                method: toLegacyProgram(dto.hashPoints[i].method),
                points: dto.hashPoints[i].points
            });
        }

        Schemas.RefferalDiscountsDTO[] memory discounts =
            new Schemas.RefferalDiscountsDTO[](dto.discounts.length);
        for (uint256 i = 0; i < dto.discounts.length; i++) {
            discounts[i] = Schemas.RefferalDiscountsDTO({
                method: toLegacyProgram(dto.discounts[i].method),
                tear: toLegacyTier(dto.discounts[i].tier),
                discount: toLegacyDiscount(dto.discounts[i].discount)
            });
        }

        Schemas.TearDTO[] memory tiers = new Schemas.TearDTO[](dto.tier.length);
        for (uint256 i = 0; i < dto.tier.length; i++) {
            tiers[i] = Schemas.TearDTO({
                points: Schemas.TearPoints({from: dto.tier[i].points.from, to: dto.tier[i].points.to}),
                tear: toLegacyTier(dto.tier[i].tier)
            });
        }

        return Schemas.AllRefferalInfoDTO({
            programPoints: programPoints,
            hashPoints: hashPoints,
            discounts: discounts,
            tear: tiers
        });
    }

    function toLegacyHistory(ReferralProgramHistory[] memory history)
        internal
        pure
        returns (Schemas.RefferalHistory[] memory)
    {
        Schemas.RefferalHistory[] memory result = new Schemas.RefferalHistory[](history.length);
        for (uint256 i = 0; i < history.length; i++) {
            result[i] = Schemas.RefferalHistory({
                points: history[i].points,
                method: toLegacyProgram(history[i].method)
            });
        }
        return result;
    }

    function toLegacyMyReferralInfo(MyReferralInfoDTO memory info)
        internal
        pure
        returns (Schemas.MyRefferalInfoDTO memory)
    {
        return Schemas.MyRefferalInfoDTO({myHash: info.myHash, savedHash: info.savedHash});
    }

    function toLegacyDiscount(ReferralDiscount memory discount)
        internal
        pure
        returns (Schemas.RefferalDiscount memory)
    {
        return Schemas.RefferalDiscount({pointsCosts: discount.pointsCosts, percents: discount.percents});
    }

    function toLegacyProgram(ReferralProgram program) internal pure returns (Schemas.RefferalProgram) {
        return Schemas.RefferalProgram(uint8(program));
    }

    function toLegacyTier(ReferralTier tier) internal pure returns (Schemas.Tear) {
        return Schemas.Tear(uint8(tier));
    }

    function toLegacyAccrualType(ReferralAccrualType accrualType)
        internal
        pure
        returns (Schemas.RefferalAccrualType)
    {
        return Schemas.RefferalAccrualType(uint8(accrualType));
    }
}


