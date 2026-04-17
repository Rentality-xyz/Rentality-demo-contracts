// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../infrastructure/upgradeable/UUPSOwnable.sol';
import '../../models/referral/RentalReferralMain.sol';
import '../../models/referral/RentalReferralQuery.sol';
import '../../rentality_old/Schemas.sol';
import '../../rentality_old/abstract/ARentalityContext.sol';
import './IReferralGatewayFacet.sol';
import './ReferralGatewayFacetLib.sol';

interface IReferralGatewayFacetAccess {
    function isRentalityPlatform(address user) external view returns (bool);
}

contract ReferralGatewayFacet is UUPSOwnable, ARentalityContext, IReferralGatewayFacet {
    RentalReferralMain public rentalReferralMain;
    RentalReferralQuery public rentalReferralQuery;
    IReferralGatewayFacetAccess public userAccess;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address rentalReferralMainAddress, address rentalReferralQueryAddress, address userAccessAddress)
        public
        initializer
    {
        __Ownable_init();
        _setServiceAddresses(rentalReferralMainAddress, rentalReferralQueryAddress, userAccessAddress);
    }

    function updateServiceAddresses(
        address rentalReferralMainAddress,
        address rentalReferralQueryAddress,
        address userAccessAddress
    ) external onlyOwner {
        _setServiceAddresses(rentalReferralMainAddress, rentalReferralQueryAddress, userAccessAddress);
    }

    function addressToPoints(address user) external view returns (uint256) {
        return rentalReferralQuery.getPointsBalance(user);
    }

    function referralHashV2(address user) external view returns (bytes4) {
        return rentalReferralQuery.getReferralHash(user);
    }

    function getCarDailyClaimedTime(uint256 carId) external view returns (uint64) {
        return uint64(rentalReferralQuery.getCarDailyClaimedTime(carId));
    }

    function getMyStartDiscount(address user) external view returns (Schemas.RefferalDiscount memory) {
        return Schemas.RefferalDiscount({pointsCosts: 0, percents: rentalReferralQuery.getMyStartDiscount(user)});
    }

    function getReadyToClaim(address user) external view returns (Schemas.ReadyToClaimDTO memory readyToClaimDTO) {
        return ReferralGatewayFacetLib.toLegacyReadyToClaimDTO(rentalReferralQuery.getReadyToClaim(user));
    }

    function getReadyToClaimFromRefferalHash(address user)
        external
        view
        returns (Schemas.RefferalHashDTO memory refferalHashDTO)
    {
        return ReferralGatewayFacetLib.toLegacyReferralHashDTO(rentalReferralQuery.getReadyToClaimFromHash(user));
    }

    function getRefferalPointsInfo()
        external
        view
        returns (Schemas.AllRefferalInfoDTO memory allRefferalInfoDTO)
    {
        return ReferralGatewayFacetLib.toLegacyAllReferralInfoDTO(rentalReferralQuery.getReferralPointsInfo());
    }

    function getPointsHistory() external view returns (Schemas.RefferalHistory[] memory) {
        return ReferralGatewayFacetLib.toLegacyHistory(rentalReferralQuery.getPointsHistory(_msgGatewaySender()));
    }

    function getMyRefferalInfo() external view returns (Schemas.MyRefferalInfoDTO memory myRefferalInfoDTO) {
        return ReferralGatewayFacetLib.toLegacyMyReferralInfo(
            rentalReferralQuery.getMyReferralInfo(_msgGatewaySender())
        );
    }

    function claimPoints(address user) external {
        rentalReferralMain.claimPoints(user);
    }

    function claimRefferalPoints(address user) external {
        rentalReferralMain.claimReferralPoints(user);
    }

    function hashExists(bytes32 referralHash) external view returns (bool) {
        return rentalReferralQuery.hashExists(bytes4(referralHash));
    }

    function isTrustedForwarder(address forwarder) internal view override returns (bool) {
        return address(userAccess) != address(0) && userAccess.isRentalityPlatform(forwarder);
    }

    function _setServiceAddresses(
        address rentalReferralMainAddress,
        address rentalReferralQueryAddress,
        address userAccessAddress
    ) internal {
        rentalReferralMain = RentalReferralMain(rentalReferralMainAddress);
        rentalReferralQuery = RentalReferralQuery(rentalReferralQueryAddress);
        userAccess = IReferralGatewayFacetAccess(userAccessAddress);
    }
}
