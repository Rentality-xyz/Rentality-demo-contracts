// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../infrastructure/upgradeable/UUPSOwnable.sol';
import '../models/base/referral/ReferralTypes.sol';
import '../models/referral/ReferralMain.sol';
import '../models/referral/ReferralQuery.sol';
import './ARentalityContext.sol';
import './referral/IReferralGatewayFacet.sol';

interface IReferralGatewayFacetAccess {
    function isRentalityPlatform(address user) external view returns (bool);
}

contract AppGatewayFacet2 is UUPSOwnable, ARentalityContext, IReferralGatewayFacet {
    ReferralMain public referralMain;
    ReferralQuery public referralQuery;
    IReferralGatewayFacetAccess public userAccess;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address referralMainAddress, address referralQueryAddress, address userAccessAddress)
        public
        initializer
    {
        __Ownable_init();
        _setServiceAddresses(referralMainAddress, referralQueryAddress, userAccessAddress);
    }

    function updateServiceAddresses(
        address referralMainAddress,
        address referralQueryAddress,
        address userAccessAddress
    ) external onlyOwner {
        _setServiceAddresses(referralMainAddress, referralQueryAddress, userAccessAddress);
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

    function hashExists(bytes32 referralHash) external view returns (bool) {
        return referralQuery.hashExists(bytes4(referralHash));
    }

    function isTrustedForwarder(address forwarder) internal view override returns (bool) {
        return address(userAccess) != address(0) && userAccess.isRentalityPlatform(forwarder);
    }

    function _setServiceAddresses(
        address referralMainAddress,
        address referralQueryAddress,
        address userAccessAddress
    ) internal {
        referralMain = ReferralMain(referralMainAddress);
        referralQuery = ReferralQuery(referralQueryAddress);
        userAccess = IReferralGatewayFacetAccess(userAccessAddress);
    }
}

