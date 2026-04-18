// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../infrastructure/upgradeable/UUPSOwnable.sol";
import "../../models/base/referral/ReferralTypes.sol";
import "../../models/trip/TripMain.sol";
import "../../models/trip/TripTypes.sol";
import "../../models/trip/TripQuery.sol";
import "../../models/car/CarTypes.sol";
import "../../models/common/CommonTypes.sol";
import "../../models/profile/UserProfileTypes.sol";
import "../../models/insurance/RentalInsuranceTypes.sol";
import "../../rentality_old/Schemas.sol";
import "../../rentality_old/abstract/ARentalityContext.sol";
import "./TripGatewayFacetLib.sol";
import "./TripGatewayWriteLib.sol";

interface ITripGatewayFacetUserProfileMain {
    function isRentalityPlatform(address user) external view returns (bool);
    function isAdmin(address user) external view returns (bool);
    function hasPassedKYCAndTC(address user) external view returns (bool);
    function getKYCProfile(address user) external view returns (UserProfileKYCInfo memory);
}

interface ITripGatewayFacetCarQuery {
    function getCar(uint256 id) external view returns (CarInfo memory);
    function calculateDeliveryPrices(
        uint256 carId,
        LocationInfo memory pickUpLocation,
        LocationInfo memory returnLocation
    ) external view returns (uint64 pickUp, uint64 dropOf);
}

interface ITripGatewayFacetPricingService {
    function getPlatformFeeFrom(uint256 value) external view returns (uint256);
    function getTotalTripTax(uint256 tripId) external view returns (uint64);
    function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 value) external view returns (uint64);
    function defineTaxesType(address carService, uint carId) external view returns (uint);
    function calculateTaxes(uint256 taxId, uint64 tripDays, uint64 totalCost) external view returns (uint64);
    function calculateAndSaveTaxes(uint taxId, uint64 daysOfTrip, uint64 value, uint tripId) external returns (uint64);
}

interface ITripGatewayFacetPaymentService {
    function payCreateTrip(address currencyType, uint valueSumInCurrency, address user, uint carId, address currencyFrom, uint256 amountIn, uint24 fee) external payable;
    function payFinishTrip(
        Schemas.Trip memory trip,
        uint256 valueToHost,
        uint256 valueToGuest,
        uint256 totalIncome,
        uint256 tripCostValue
    ) external payable;
    function payRejectTrip(Schemas.Trip memory trip, uint256 valueToReturnInToken) external;
}

interface ITripGatewayFacetCurrencyConverter {
    function getUserCurrency(address user) external view returns (Schemas.UserCurrencyDTO memory);
    function currencyTypeIsAvailable(address tokenAddress) external view returns (bool);
    function getFromUsdCentsLatest(address currencyType, uint256 amount) external view returns (uint256, int256, uint8);
    function getFromUsdCents(address currencyType, uint256 amountInUsdCents, int256 rate) external view returns (uint256);
    function calculateTripReject(
        Schemas.PaymentInfo memory paymentInfo,
        uint256 insurance,
        uint64 totalTax
    ) external pure returns (uint256);

    function calculateTripFinsish(
        Schemas.PaymentInfo memory paymentInfo,
        uint256 rentalityFee,
        uint256 feeOfPriceWithDiscount,
        uint256 insurancePriceInUsdCents,
        address promoServiceAddress
    ) external view returns (uint256, uint256, uint256, uint256, uint256, uint256);
}

interface ITripGatewayFacetInsuranceService {
    function getInsurancePriceByTrip(uint256 tripId) external view returns (uint256);
    function getInsurancePriceByCar(uint256 carId) external view returns (uint256);
    function isGuestHasInsurance(address guest) external view returns (bool);
    function calculateInsuranceForTrip(uint256 carId, uint64 startDateTime, uint64 endDateTime, address user) external view returns (uint256);
    function saveGuestInsurancePayment(uint256 tripId, uint256 carId, uint256 totalSum, address user) external;
    function saveTripInsuranceInfo(
        uint256 tripId,
        RentalSaveInsuranceRequest memory insuranceInfo,
        address user
    ) external;
}

interface ITripGatewayFacetPromoService {
    function getDiscountByPromo(string memory promoCode, address user) external view returns (uint);
    function rejectDiscountByTrip(uint256 tripId, address user) external;
    function usePromo(string memory promoCode, uint tripId, address user, uint totalPriceInCurrency, uint totalPrice, uint startDateTime, uint endDateTime) external;
}

interface ITripGatewayFacetReferralProgram {
    function passReferralProgram(
        ReferralProgram selector,
        bytes memory callbackArgs,
        address user,
        address promoServiceAddress
    ) external;
}

interface ITripGatewayFacetNotificationService {
    function emitEvent(Schemas.EventType eType, uint256 id, uint8 objectStatus, address from, address to) external;
}


contract TripGatewayFacet is UUPSOwnable, ARentalityContext {
    TripMain public tripMain;
    TripQuery public tripQuery;
    ITripGatewayFacetUserProfileMain public userProfileMain;
    ITripGatewayFacetCarQuery public carQuery;
    address public carTaxAdapter;
    ITripGatewayFacetPricingService public pricingService;
    ITripGatewayFacetPaymentService public paymentService;
    ITripGatewayFacetCurrencyConverter public currencyConverter;
    ITripGatewayFacetInsuranceService public insuranceService;
    ITripGatewayFacetPromoService public promoService;
    ITripGatewayFacetReferralProgram public referralProgram;
    ITripGatewayFacetNotificationService public notificationService;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address tripMainAddress,
        address tripQueryAddress,
        address userProfileMainAddress,
        address carQueryAddress,
        address carTaxAdapterAddress,
        address pricingServiceAddress,
        address paymentServiceAddress,
        address currencyConverterAddress,
        address insuranceServiceAddress,
        address promoServiceAddress,
        address referralProgramAddress,
        address notificationServiceAddress
    ) public initializer {
        __Ownable_init();
        _setServiceAddresses(
            tripMainAddress,
            tripQueryAddress,
            userProfileMainAddress,
            carQueryAddress,
            carTaxAdapterAddress,
            pricingServiceAddress,
            paymentServiceAddress,
            currencyConverterAddress,
            insuranceServiceAddress,
            promoServiceAddress,
            referralProgramAddress,
            notificationServiceAddress
        );
    }

    function updateServiceAddresses(
        address tripMainAddress,
        address tripQueryAddress,
        address userProfileMainAddress,
        address carQueryAddress,
        address carTaxAdapterAddress,
        address pricingServiceAddress,
        address paymentServiceAddress,
        address currencyConverterAddress,
        address insuranceServiceAddress,
        address promoServiceAddress,
        address referralProgramAddress,
        address notificationServiceAddress
    ) external onlyOwner {
        _setServiceAddresses(
            tripMainAddress,
            tripQueryAddress,
            userProfileMainAddress,
            carQueryAddress,
            carTaxAdapterAddress,
            pricingServiceAddress,
            paymentServiceAddress,
            currencyConverterAddress,
            insuranceServiceAddress,
            promoServiceAddress,
            referralProgramAddress,
            notificationServiceAddress
        );
    }

    function getTripContactInfo(uint256 tripId)
        external
        view
        returns (string memory guestPhoneNumber, string memory hostPhoneNumber)
    {
        return tripQuery.getTripContactInfo(tripId);
    }

    function getTrip(uint256 tripId) external view returns (Schemas.TripDTO memory) {
        return TripGatewayFacetLib.toLegacyTripDTO(tripQuery.getTripDTO(tripId, _msgGatewaySender()));
    }

    function getTripsAs(bool host) external view returns (Schemas.TripDTO[] memory result) {
        TripDTO[] memory trips = tripQuery.getTripsAs(_msgGatewaySender(), host);
        result = new Schemas.TripDTO[](trips.length);
        for (uint256 i = 0; i < trips.length; i++) {
            result[i] = TripGatewayFacetLib.toLegacyTripDTO(trips[i]);
        }
    }

    function getChatInfoFor(bool host) external view returns (Schemas.ChatInfo[] memory result) {
        return tripQuery.getChatInfoFor(_msgGatewaySender(), host);
    }

    function createTripRequestWithDelivery(
        Schemas.CreateTripRequestWithDelivery memory request,
        string memory promo
    ) external payable {
        TripGatewayWriteLib.createTripRequestWithDelivery(
            tripMain,
            address(userProfileMain),
            address(carQuery),
            carTaxAdapter,
            address(pricingService),
            address(paymentService),
            address(currencyConverter),
            address(insuranceService),
            address(promoService),
            request,
            promo,
            _msgGatewaySender()
        );
    }


    function calculatePaymentsWithDelivery(
        uint256 carId,
        uint64 daysOfTrip,
        address currency,
        Schemas.LocationInfo memory pickUpLocation,
        Schemas.LocationInfo memory returnLocation,
        string memory promo
    ) external view returns (Schemas.CalculatePaymentsDTO memory) {
        return TripLib.calculatePaymentsWithDelivery(
            address(carQuery),
            address(pricingService),
            address(insuranceService),
            address(promoService),
            address(currencyConverter),
            carTaxAdapter,
            carId,
            daysOfTrip,
            currency,
            pickUpLocation,
            returnLocation,
            promo,
            _msgGatewaySender()
        );
    }
    function approveTripRequest(uint256 tripId) external {
        TripGatewayWriteLib.approveTripRequest(
            tripMain,
            address(carQuery),
            address(pricingService),
            address(paymentService),
            address(currencyConverter),
            address(insuranceService),
            address(promoService),
            address(notificationService),
            tripId,
            _msgGatewaySender()
        );
    }

    function rejectTripRequest(uint256 tripId) external {
        TripGatewayWriteLib.rejectTripRequest(
            tripMain,
            address(pricingService),
            address(paymentService),
            address(currencyConverter),
            address(insuranceService),
            address(promoService),
            address(notificationService),
            tripId,
            _msgGatewaySender()
        );
    }

    function confirmCheckOut(uint256 tripId) external {
        TripGatewayWriteLib.confirmCheckOut(
            tripMain,
            address(userProfileMain),
            address(pricingService),
            address(paymentService),
            address(currencyConverter),
            address(insuranceService),
            address(promoService),
            address(notificationService),
            tripId,
            _msgGatewaySender()
        );
    }

    function finishTrip(uint256 tripId) external {
        TripGatewayWriteLib.finishTrip(
            tripMain,
            address(pricingService),
            address(paymentService),
            address(currencyConverter),
            address(insuranceService),
            address(promoService),
            address(notificationService),
            tripId,
            _msgGatewaySender()
        );
    }

    function checkInByHost(
        uint256 tripId,
        uint64[] memory panelParams,
        string memory insuranceCompany,
        string memory insuranceNumber
    ) external {
        address sender = _msgGatewaySender();

        if (bytes(insuranceNumber).length > 0 || bytes(insuranceCompany).length > 0) {
            insuranceService.saveTripInsuranceInfo(
                tripId,
                RentalSaveInsuranceRequest(
                    insuranceCompany,
                    insuranceNumber,
                    "",
                    "",
                    InsuranceType.OneTime
                ),
                sender
            );
        }

        tripMain.checkInByHost(tripId, panelParams, insuranceCompany, insuranceNumber, sender);
        Trip memory trip = tripMain.getTrip(tripId);
        _emitTripEvent(tripId, Schemas.TripStatus.CheckedInByHost, trip.booking.provider, trip.booking.customer);
    }

    function checkInByGuest(uint256 tripId, uint64[] memory panelParams) external {
        address sender = _msgGatewaySender();
        tripMain.checkInByGuest(tripId, panelParams, sender);
        Trip memory trip = tripMain.getTrip(tripId);
        _emitTripEvent(tripId, Schemas.TripStatus.CheckedInByGuest, trip.booking.customer, trip.booking.provider);
    }

    function checkOutByGuest(uint256 tripId, uint64[] memory panelParams) external {
        address sender = _msgGatewaySender();
        Trip memory tripBefore = tripMain.getTrip(tripId);

        referralProgram.passReferralProgram(
            ReferralProgram.FinishTripAsGuest,
            abi.encode(tripBefore.booking.startDateTime, tripBefore.booking.endDateTime),
            sender,
            address(promoService)
        );

        tripMain.checkOutByGuest(tripId, panelParams, sender);
        Trip memory trip = tripMain.getTrip(tripId);
        _emitTripEvent(tripId, Schemas.TripStatus.CheckedOutByGuest, trip.booking.customer, trip.booking.provider);
    }

    function checkOutByHost(uint256 tripId, uint64[] memory panelParams) external {
        address sender = _msgGatewaySender();
        tripMain.checkOutByHost(tripId, panelParams, sender);
        Trip memory trip = tripMain.getTrip(tripId);
        _emitTripEvent(tripId, Schemas.TripStatus.CheckedOutByHost, trip.booking.provider, trip.booking.customer);
    }

    function isTrustedForwarder(address forwarder) internal view override returns (bool) {
        return address(userProfileMain) != address(0) && userProfileMain.isRentalityPlatform(forwarder);
    }


    function _emitTripEvent(uint256 tripId, Schemas.TripStatus status, address from, address to) internal {
        if (address(notificationService) == address(0)) {
            return;
        }
        notificationService.emitEvent(Schemas.EventType.Trip, tripId, uint8(status), from, to);
    }

    function _setServiceAddresses(
        address tripMainAddress,
        address tripQueryAddress,
        address userProfileMainAddress,
        address carQueryAddress,
        address carTaxAdapterAddress,
        address pricingServiceAddress,
        address paymentServiceAddress,
        address currencyConverterAddress,
        address insuranceServiceAddress,
        address promoServiceAddress,
        address referralProgramAddress,
        address notificationServiceAddress
    ) internal {
        tripMain = TripMain(tripMainAddress);
        tripQuery = TripQuery(tripQueryAddress);
        userProfileMain = ITripGatewayFacetUserProfileMain(userProfileMainAddress);
        carQuery = ITripGatewayFacetCarQuery(carQueryAddress);
        carTaxAdapter = carTaxAdapterAddress;
        pricingService = ITripGatewayFacetPricingService(pricingServiceAddress);
        paymentService = ITripGatewayFacetPaymentService(paymentServiceAddress);
        currencyConverter = ITripGatewayFacetCurrencyConverter(currencyConverterAddress);
        insuranceService = ITripGatewayFacetInsuranceService(insuranceServiceAddress);
        promoService = ITripGatewayFacetPromoService(promoServiceAddress);
        referralProgram = ITripGatewayFacetReferralProgram(referralProgramAddress);
        notificationService = ITripGatewayFacetNotificationService(notificationServiceAddress);
    }


}












