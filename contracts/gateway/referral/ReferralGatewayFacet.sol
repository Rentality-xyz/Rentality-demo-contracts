// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../infrastructure/upgradeable/UUPSOwnable.sol';
import '../../infrastructure/services/ai-damage/AiDamageTypes.sol';
import '../../models/base/referral/ReferralTypes.sol';
import '../../models/referral/ReferralMain.sol';
import '../../models/referral/ReferralMainFacet1.sol';
import '../../models/referral/ReferralQuery.sol';
import '../GatewayContext.sol';
import './IReferralGatewayFacet.sol';

interface IReferralGatewayFacetAccess {
    function isRentalityPlatform(address user) external view returns (bool);
    function isAdmin(address user) external view returns (bool);
}

interface IReferralGatewayFacetNotificationService {
    function emitEvent(EventType eType, uint256 id, uint8 objectStatus, address from, address to) external;
}

contract ReferralGatewayFacet is UUPSOwnable, GatewayContext, IReferralGatewayFacet {
    ReferralMain public referralMain;
    ReferralMainFacet1 public referralMainFacet1;
    ReferralQuery public referralQuery;
    IReferralGatewayFacetAccess public userAccess;
    IReferralGatewayFacetNotificationService public notificationService;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address referralMainAddress,
        address referralMainFacet1Address,
        address referralQueryAddress,
        address userAccessAddress,
        address notificationServiceAddress
    )
        public
        initializer
    {
        __Ownable_init();
        _setServiceAddresses(
            referralMainAddress,
            referralMainFacet1Address,
            referralQueryAddress,
            userAccessAddress,
            notificationServiceAddress
        );
    }

    function updateServiceAddresses(
        address referralMainAddress,
        address referralMainFacet1Address,
        address referralQueryAddress,
        address userAccessAddress,
        address notificationServiceAddress
    ) external onlyOwner {
        _setServiceAddresses(
            referralMainAddress,
            referralMainFacet1Address,
            referralQueryAddress,
            userAccessAddress,
            notificationServiceAddress
        );
    }

    modifier onlyAdmin() {
        require(userAccess.isAdmin(_msgGatewaySender()) || userAccess.isAdmin(tx.origin), 'only Admin');
        _;
    }

    function addressToPoints(address user) external view returns (uint256) {
        return referralQuery.getPointsBalance(user);
    }

    function referralHashV2(address user) external view returns (bytes4) {
        return referralQuery.getReferralHash(user);
    }

    function getCarDailyClaimedTime(uint256 carId) external view returns (uint64) {
        return uint64(referralQuery.getCarDailyClaimedTime(carId));
    }

    function getMyStartDiscount(address user) external view returns (ReferralDiscount memory) {
        return ReferralDiscount({pointsCosts: 0, percents: referralQuery.getMyStartDiscount(user)});
    }

    function getReadyToClaim(address user) external view returns (ReadyToClaimDTO memory readyToClaimDTO) {
        return referralQuery.getReadyToClaim(user);
    }

    function getReadyToClaimFromRefferalHash(address user)
        external
        view
        returns (ReferralHashDTO memory refferalHashDTO)
    {
        return referralQuery.getReadyToClaimFromHash(user);
    }

    function getRefferalPointsInfo()
        external
        view
        returns (AllReferralInfoDTO memory allRefferalInfoDTO)
    {
        return referralQuery.getReferralPointsInfo();
    }

    function getPointsHistory() external view returns (ReferralProgramHistory[] memory) {
        return referralQuery.getPointsHistory(_msgGatewaySender());
    }

    function getMyRefferalInfo() external view returns (MyReferralInfoDTO memory myRefferalInfoDTO) {
        return referralQuery.getMyReferralInfo(_msgGatewaySender());
    }

    function claimPoints(address user) external {
        referralMain.claimPoints(user);
    }

    function claimRefferalPoints(address user) external {
        referralMain.claimReferralPoints(user);
    }

    function getMyClaimsAs(bool host) external view returns (FullReferralClaimInfo[] memory) {
        return referralQuery.getMyClaimsAs(host, _msgGatewaySender());
    }

    function getClaim(uint256 claimId) external view returns (ReferralClaimInfoV2 memory) {
        return referralQuery.getClaim(claimId);
    }

    function calculateClaimValue(uint256 claimId) external view returns (uint256) {
        return referralQuery.calculateClaimValue(claimId);
    }

    function setClaimsWaitingTime(uint256 timeInSec) external onlyAdmin {
        referralMainFacet1.setWaitingTime(timeInSec);
    }

    function getClaimWaitingTime() external view returns (uint256) {
        return referralMainFacet1.getWaitingTime();
    }

    function setPlatformFee(uint256 value) external onlyAdmin {
        referralMainFacet1.setPlatformFee(value);
    }

    function getAllClaimTypes(bool byHost) external view returns (ReferralClaimTypeInfo[] memory claimTypes) {
        return byHost ? referralMainFacet1.getClaimTypesForHost() : referralMainFacet1.getClaimTypesForGuest();
    }

    function addClaimType(string memory name, ReferralClaimCreator creator) external onlyAdmin {
        uint256 claimTypeId = referralMainFacet1.addClaimType(name, creator);
        _emitAdminEvent(EventType.AddClaimType, claimTypeId, uint8(EventCreator.Admin));
    }

    function removeClaimType(uint8 claimType) external onlyAdmin {
        referralMainFacet1.removeClaimType(claimType);
    }

    function manageRefferalBonusAccrual(
        ReferralAccrualType accrualType,
        ReferralProgram program,
        int256 points,
        int256 pointsWithReffHash
    ) external onlyAdmin {
        if (ReferralAccrualType.OneTime == accrualType) {
            referralMain.addOneTimeProgram(program, points, pointsWithReffHash, bytes4(''));
        } else {
            referralMain.addPermanentProgram(program, points, bytes4(''));
        }
    }

    function manageRefferalHashPoints(ReferralProgram program, uint256 points) external onlyAdmin {
        referralMain.manageReferralHashProgram(program, points);
    }

    function manageRefferalDiscount(ReferralProgram program, ReferralTier tear, uint256 points, uint256 percents)
        external
        onlyAdmin
    {
        referralMain.manageReferralDiscount(program, tear, points, percents);
    }

    function manageTearInfo(ReferralTier tear, uint256 from, uint256 to) external onlyAdmin {
        referralMain.manageTierInfo(tear, from, to);
    }

    function getAiDamageAnalyzeCaseRequest(uint tripId, CaseType caseType)
        external
        view
        returns (AiDamageAnalyzeCaseRequestDTO memory aiDamageAnalyzeCaseRequest)
    {
        return referralQuery.getAiDamageAnalyzeCaseRequest(tripId, caseType, _msgGatewaySender());
    }

    function createClaim(CreateReferralClaimRequest memory request, bool isInsuranceClaim) external {
        referralMainFacet1.createClaim(request, isInsuranceClaim, _msgGatewaySender());
    }

    function rejectClaim(uint256 claimId) external {
        referralMainFacet1.rejectClaim(claimId, _msgGatewaySender());
    }

    function payClaim(uint256 claimId) external payable {
        referralMainFacet1.payClaim{value: msg.value}(claimId, _msgGatewaySender());
    }

    function hashExists(bytes32 referralHash) external view returns (bool) {
        return referralQuery.hashExists(bytes4(referralHash));
    }

    function isTrustedForwarder(address forwarder) internal view override returns (bool) {
        return address(userAccess) != address(0) && userAccess.isRentalityPlatform(forwarder);
    }

    function _setServiceAddresses(
        address referralMainAddress,
        address referralMainFacet1Address,
        address referralQueryAddress,
        address userAccessAddress,
        address notificationServiceAddress
    ) internal {
        referralMain = ReferralMain(referralMainAddress);
        referralMainFacet1 = ReferralMainFacet1(referralMainFacet1Address);
        referralQuery = ReferralQuery(referralQueryAddress);
        userAccess = IReferralGatewayFacetAccess(userAccessAddress);
        notificationService = IReferralGatewayFacetNotificationService(notificationServiceAddress);
    }

    function _emitAdminEvent(EventType eType, uint256 id, uint8 objectStatus) internal {
        if (address(notificationService) == address(0)) {
            return;
        }
        address sender = _msgGatewaySender();
        notificationService.emitEvent(eType, id, objectStatus, sender, sender);
    }
}

