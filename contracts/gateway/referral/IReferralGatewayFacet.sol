// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../infrastructure/services/ai-damage/AiDamageTypes.sol';
import '../../models/base/referral/ReferralTypes.sol';
import '../../models/referral/ReferralTypes.sol';

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
    function getMyClaimsAs(bool host) external view returns (FullReferralClaimInfo[] memory);
    function getClaim(uint256 claimId) external view returns (ReferralClaimInfoV2 memory);
    function calculateClaimValue(uint256 claimId) external view returns (uint256);
    function setClaimsWaitingTime(uint256 timeInSec) external;
    function getClaimWaitingTime() external view returns (uint256);
    function setPlatformFee(uint256 value) external;
    function getAllClaimTypes(bool byHost) external view returns (ReferralClaimTypeInfo[] memory claimTypes);
    function addClaimType(string memory name, ReferralClaimCreator creator) external;
    function removeClaimType(uint8 claimType) external;
    function manageRefferalBonusAccrual(
        ReferralAccrualType accrualType,
        ReferralProgram program,
        int256 points,
        int256 pointsWithReffHash
    ) external;
    function manageRefferalHashPoints(ReferralProgram program, uint256 points) external;
    function manageRefferalDiscount(ReferralProgram program, ReferralTier tear, uint256 points, uint256 percents)
        external;
    function manageTearInfo(ReferralTier tear, uint256 from, uint256 to) external;
    function getAiDamageAnalyzeCaseRequest(uint tripId, CaseType caseType)
        external
        view
        returns (AiDamageAnalyzeCaseRequestDTO memory aiDamageAnalyzeCaseRequest);
    function createClaim(CreateReferralClaimRequest memory request, bool isInsuranceClaim) external;
    function rejectClaim(uint256 claimId) external;
    function payClaim(uint256 claimId) external payable;
}
