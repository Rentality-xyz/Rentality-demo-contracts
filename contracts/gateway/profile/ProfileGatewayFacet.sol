// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../infrastructure/upgradeable/UUPSOwnable.sol';
import '../../models/base/referral/ReferralTypes.sol';
import '../../models/profile/UserProfileMain.sol';
import '../../models/profile/UserProfileQuery.sol';
import '../../models/profile/UserProfileTypes.sol';
import '../../rentality_old/Schemas.sol';
import '../../rentality_old/abstract/ARentalityContext.sol';
import './ProfileGatewayFacetLib.sol';

interface IProfileGatewayFacetReferralProgram {
    function generateReferralHash(address user) external;
    function saveReferralHash(bytes4 hash, bool isGuest, address user) external;
    function passReferralProgram(
        ReferralProgram selector,
        bytes memory callbackArgs,
        address user,
        address promoServiceAddress
    ) external;
}

interface IProfileGatewayFacetPromoService {}

interface IProfileGatewayFacetNotificationService {
    function emitEvent(Schemas.EventType eType, uint256 id, uint8 objectStatus, address from, address to) external;
}

interface IProfileGatewayFacetPaymentService {
    function payKycCommission(uint256 valueInCurrency, address currencyType, address user) external payable;
}

interface IProfileGatewayFacetCurrencyConverter {
    function getFromUsdCentsLatest(address currencyType, uint256 amount)
        external
        view
        returns (uint256, int256, uint8);
}

contract ProfileGatewayFacet is UUPSOwnable, ARentalityContext {
    UserProfileMain public userProfileMain;
    UserProfileQuery public userProfileQuery;
    IProfileGatewayFacetReferralProgram public referralProgram;
    IProfileGatewayFacetPromoService public promoService;
    IProfileGatewayFacetNotificationService public notificationService;
    IProfileGatewayFacetPaymentService public paymentService;
    IProfileGatewayFacetCurrencyConverter public currencyConverter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address userProfileMainAddress,
        address userProfileQueryAddress,
        address referralProgramAddress,
        address promoServiceAddress,
        address notificationServiceAddress,
        address paymentServiceAddress,
        address currencyConverterAddress
    ) public initializer {
        __Ownable_init();
        _setServiceAddresses(
            userProfileMainAddress,
            userProfileQueryAddress,
            referralProgramAddress,
            promoServiceAddress,
            notificationServiceAddress,
            paymentServiceAddress,
            currencyConverterAddress
        );
    }

    function updateServiceAddresses(
        address userProfileMainAddress,
        address userProfileQueryAddress,
        address referralProgramAddress,
        address promoServiceAddress,
        address notificationServiceAddress,
        address paymentServiceAddress,
        address currencyConverterAddress
    ) external onlyOwner {
        _setServiceAddresses(
            userProfileMainAddress,
            userProfileQueryAddress,
            referralProgramAddress,
            promoServiceAddress,
            notificationServiceAddress,
            paymentServiceAddress,
            currencyConverterAddress
        );
    }

    function getMyFullKYCInfo() external view returns (Schemas.FullKYCInfoDTO memory) {
        return ProfileGatewayFacetLib.toLegacyFull(userProfileQuery.getMyFullKYCInfo(_msgGatewaySender()));
    }

    function getPlatformUsersKYCInfos(uint256 page, uint256 itemsPerPage)
        external
        view
        returns (Schemas.AdminKYCInfosDTO memory)
    {
        return ProfileGatewayFacetLib.toLegacyAdminPage(userProfileQuery.getPlatformUsersKYCInfos(page, itemsPerPage));
    }

    function getUserFullKYCInfo(address user) external view returns (Schemas.FullKYCInfoDTO memory) {
        return ProfileGatewayFacetLib.toLegacyFull(userProfileQuery.getMyFullKYCInfo(user));
    }

    function getKycCommission() external view returns (uint256) {
        return userProfileQuery.getKycCommission();
    }

    function isKycCommissionPaid(address user) external view returns (bool) {
        return userProfileQuery.isCommissionPaidForUser(user);
    }

    function payKycCommission(address currency) external payable {
        (uint256 valueToPay, , ) = currencyConverter.getFromUsdCentsLatest(currency, userProfileQuery.getKycCommission());
        paymentService.payKycCommission{value: msg.value}(valueToPay, currency, _msgGatewaySender());
    }

    function setKYCInfo(
        string memory nickName,
        string memory mobilePhoneNumber,
        string memory profilePhoto,
        string memory email,
        bytes memory tcSignature,
        bytes4 hash
    ) external {
        address sender = _msgGatewaySender();
        referralProgram.generateReferralHash(sender);
        bool isGuest = userProfileMain.isGuest(sender);
        referralProgram.saveReferralHash(hash, isGuest, sender);
        referralProgram.passReferralProgram(ReferralProgram.SetKYC, bytes(''), sender, address(promoService));

        userProfileMain.setKYCInfo(
            SetUserProfileRequest({
                nickName: nickName,
                mobilePhoneNumber: mobilePhoneNumber,
                profilePhoto: profilePhoto,
                email: email,
                termsSignature: tcSignature
            }),
            sender
        );

        notificationService.emitEvent(Schemas.EventType.User, 0, 0, sender, sender);
    }

    function setPhoneNumber(address user, string memory phone, bool isVerified) external {
        userProfileMain.setPhoneNumber(user, phone, isVerified);
    }

    function setEmail(address user, string memory email, bool isVerified) external {
        userProfileMain.setEmail(user, email, isVerified);
    }

    function setCivicKYCInfo(address user, Schemas.CivicKYCInfo memory civicKycInfo) external {
        referralProgram.passReferralProgram(ReferralProgram.PassCivic, bytes(''), user, address(promoService));
        userProfileMain.setCivicKYCInfo(user, ProfileGatewayFacetLib.toUserCivicInfo(civicKycInfo));
    }

    function setPushToken(address user, string memory pushToken) external {
        userProfileMain.setPushToken(user, pushToken);
    }

    function useKycCommission(address user) external {
        userProfileMain.useKycCommission(user);
    }

    function isTrustedForwarder(address forwarder) internal view override returns (bool) {
        return address(userProfileMain) != address(0) && userProfileMain.isRentalityPlatform(forwarder);
    }

    function _setServiceAddresses(
        address userProfileMainAddress,
        address userProfileQueryAddress,
        address referralProgramAddress,
        address promoServiceAddress,
        address notificationServiceAddress,
        address paymentServiceAddress,
        address currencyConverterAddress
    ) internal {
        userProfileMain = UserProfileMain(userProfileMainAddress);
        userProfileQuery = UserProfileQuery(userProfileQueryAddress);
        referralProgram = IProfileGatewayFacetReferralProgram(referralProgramAddress);
        promoService = IProfileGatewayFacetPromoService(promoServiceAddress);
        notificationService = IProfileGatewayFacetNotificationService(notificationServiceAddress);
        paymentService = IProfileGatewayFacetPaymentService(paymentServiceAddress);
        currencyConverter = IProfileGatewayFacetCurrencyConverter(currencyConverterAddress);
    }
}


