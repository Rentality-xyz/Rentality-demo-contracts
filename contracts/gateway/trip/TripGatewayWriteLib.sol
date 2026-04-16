// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../models/trip/TripMain.sol";
import "../../models/trip/TripTypes.sol";
import "../../models/trip/TripLib.sol";
import "../../models/car/CarTypes.sol";
import "../../rentality_old/Schemas.sol";
import "../../rentality_old/abstract/IRentalityGeoService.sol";
import "./TripGatewayFacetLib.sol";

interface ITripGatewayWriteLibUserService {
    function isAdmin(address user) external view returns (bool);
    function getKYCInfo(address user) external view returns (Schemas.KYCInfo memory);
    function hasPassedKYCAndTC(address user) external view returns (bool);
}

interface ITripGatewayWriteLibCarQuery is ITripLibCarQuery {
    function getCar(uint256 id) external view returns (CarInfo memory);
}

interface ITripGatewayWriteLibPaymentService {
    function getPlatformFeeFrom(uint256 value) external view returns (uint256);
    function getTotalTripTax(uint256 tripId) external view returns (uint64);
    function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 value) external view returns (uint64);
    function defineTaxesType(address carService, uint carId) external view returns (uint);
    function calculateAndSaveTaxes(uint taxId, uint64 daysOfTrip, uint64 value, uint tripId) external returns (uint64);
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

interface ITripGatewayWriteLibCurrencyConverter {
    function getUserCurrency(address user) external view returns (Schemas.UserCurrencyDTO memory);
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
        address promoService
    ) external view returns (uint256, uint256, uint256, uint256, uint256, uint256);
}

interface ITripGatewayWriteLibInsuranceService {
    function getInsurancePriceByTrip(uint256 tripId) external view returns (uint256);
    function calculateInsuranceForTrip(uint256 carId, uint64 startDateTime, uint64 endDateTime, address user) external view returns (uint256);
    function saveGuestinsurancePayment(uint tripId, uint carId, uint totalSum, address user) external;
    function saveTripInsuranceInfo(uint256 tripId, Schemas.SaveInsuranceRequest memory insuranceInfo, address user) external;
}

interface ITripGatewayWriteLibPromoService {
    function usePromo(string memory promoCode, uint tripId, address user, uint totalPriceInCurrency, uint totalPrice, uint startDateTime, uint endDateTime) external;
    function rejectDiscountByTrip(uint256 tripId, address user) external;
}

interface ITripGatewayWriteLibReferralProgram {
    function passReferralProgram(
        Schemas.RefferalProgram selector,
        bytes memory callbackArgs,
        address user,
        address promoService
    ) external;
}

interface ITripGatewayWriteLibNotificationService {
    function emitEvent(Schemas.EventType eType, uint256 id, uint8 objectStatus, address from, address to) external;
}

interface ITripGatewayWriteLibEngineService {
    function getFuelPriceFromEngineParams(uint8 eType, uint64[] memory engineParams) external view returns (uint64);
    function getPanelParamsAmount(uint8 eType) external view returns (uint256);
}

library TripGatewayWriteLib {
    function createTripRequestWithDelivery(
        TripMain tripMain,
        address userServiceAddress,
        address carQueryAddress,
        address carTaxAdapterAddress,
        address paymentServiceAddress,
        address currencyConverterAddress,
        address insuranceServiceAddress,
        address promoServiceAddress,
        address deliveryServiceAddress,
        Schemas.CreateTripRequestWithDelivery memory request,
        string memory promo,
        address sender
    ) external {
        ITripGatewayWriteLibCarQuery carQuery = ITripGatewayWriteLibCarQuery(carQueryAddress);
        require(carTaxAdapterAddress != address(0), "Car tax adapter is not configured.");
        require(carQuery.exists(request.carId), "Car with this id does not exist.");

        address host = carQuery.getOwner(request.carId);
        address currencyType = ITripGatewayWriteLibCurrencyConverter(currencyConverterAddress).getUserCurrency(host).currency;

        TripLib.validateTripRequest(
            userServiceAddress,
            currencyConverterAddress,
            carQuery,
            tripMain,
            currencyType,
            request.carId,
            request.startDateTime,
            request.endDateTime,
            sender
        );

        CarInfo memory carInfo = carQuery.getCar(request.carId);
        (uint64 pickUp, uint64 dropOf) = TripLib.calculateDelivery(
            deliveryServiceAddress,
            carQuery,
            request,
            carInfo
        );

        IRentalityGeoService geoService = IRentalityGeoService(carQuery.getGeoVerifierAddress());
        bytes32 pickUpHash = geoService.createSignedLocationInfo(request.pickUpInfo);
        bytes32 returnHash = geoService.createSignedLocationInfo(request.returnInfo);

        uint64 daysOfTrip = TripLib.getCeilDays(request.startDateTime, request.endDateTime);
        uint256 insurance = ITripGatewayWriteLibInsuranceService(insuranceServiceAddress).calculateInsuranceForTrip(
            request.carId,
            request.startDateTime,
            request.endDateTime,
            sender
        );
        uint64 priceWithDiscount = ITripGatewayWriteLibPaymentService(paymentServiceAddress).calculateSumWithDiscount(
            host,
            daysOfTrip,
            carInfo.car.pricePerDayInUsdCents
        );
        uint256 tripId = tripMain.totalSupply() + 1;

        uint64 taxesSum = ITripGatewayWriteLibPaymentService(paymentServiceAddress).calculateAndSaveTaxes(
            ITripGatewayWriteLibPaymentService(paymentServiceAddress).defineTaxesType(carTaxAdapterAddress, request.carId),
            daysOfTrip,
            priceWithDiscount + pickUp + dropOf,
            tripId
        );

        (
            TripPaymentInfo memory paymentInfo,
            uint256 valueSumInCurrency,
            uint256 hostEarningsInCurrency,
            uint256 hostEarnings,
            bool usePromo
        ) = TripLib.createPaymentInfo(
            promoServiceAddress,
            currencyConverterAddress,
            carInfo,
            currencyType,
            pickUp,
            dropOf,
            promo,
            sender,
            insurance,
            taxesSum,
            daysOfTrip,
            priceWithDiscount,
            address(this)
        );

        ITripGatewayWriteLibPaymentService(paymentServiceAddress).payCreateTrip{value: msg.value}(
            currencyType,
            valueSumInCurrency,
            sender,
            request.carId,
            request.currencyType,
            request.amountIn,
            request.fee
        );

        ITripGatewayWriteLibEngineService engineService = ITripGatewayWriteLibEngineService(address(tripMain.engineService()));
        Schemas.KYCInfo memory guestInfo = ITripGatewayWriteLibUserService(userServiceAddress).getKYCInfo(sender);
        Schemas.KYCInfo memory hostInfo = ITripGatewayWriteLibUserService(userServiceAddress).getKYCInfo(host);

        tripMain.createTrip(
            CreateTripRecordRequest({
                carId: request.carId,
                guest: sender,
                host: host,
                guestName: guestInfo.name,
                hostName: hostInfo.name,
                pricePerDayInUsdCents: carInfo.car.pricePerDayInUsdCents,
                startDateTime: request.startDateTime,
                endDateTime: request.endDateTime,
                engineType: carInfo.car.engineType,
                milesIncludedPerDay: carInfo.car.milesIncludedPerDay,
                fuelPrice: engineService.getFuelPriceFromEngineParams(carInfo.car.engineType, carInfo.car.engineParams),
                paymentInfo: paymentInfo,
                pickUpHash: pickUpHash,
                returnHash: returnHash,
                panelParamsCount: engineService.getPanelParamsAmount(carInfo.car.engineType),
                ethSumInTripCreation: currencyType == address(0) ? msg.value : valueSumInCurrency
            })
        );

        ITripGatewayWriteLibInsuranceService(insuranceServiceAddress).saveGuestinsurancePayment(
            tripId,
            request.carId,
            insurance,
            sender
        );

        if (usePromo) {
            ITripGatewayWriteLibPromoService(promoServiceAddress).usePromo(
                promo,
                tripId,
                sender,
                hostEarningsInCurrency,
                hostEarnings,
                uint(request.startDateTime),
                uint(request.endDateTime)
            );
        }
    }

    function approveTripRequest(
        TripMain tripMain,
        address carQueryAddress,
        address paymentServiceAddress,
        address currencyConverterAddress,
        address insuranceServiceAddress,
        address promoServiceAddress,
        address notificationServiceAddress,
        uint256 tripId,
        address sender
    ) external {
        tripMain.approveTrip(tripId, sender);

        Trip memory trip = tripMain.getTrip(tripId);
        uint256[] memory tripIds = tripMain.getCarTrips(trip.booking.resourceId);
        uint32 timeBuffer = ITripGatewayWriteLibCarQuery(carQueryAddress).getCar(trip.booking.resourceId).car.timeBufferBetweenTripsInSec;

        for (uint256 i = 0; i < tripIds.length; i++) {
            if (tripIds[i] == tripId) {
                continue;
            }

            Trip memory otherTrip = tripMain.getTrip(tripIds[i]);
            bool intersects =
                otherTrip.booking.resourceId == trip.booking.resourceId &&
                otherTrip.booking.endDateTime + timeBuffer > trip.booking.startDateTime &&
                otherTrip.booking.startDateTime < trip.booking.endDateTime;

            if (intersects && otherTrip.status == TripStatus.Created) {
                _rejectTripRequest(
                    tripMain,
                    paymentServiceAddress,
                    currencyConverterAddress,
                    insuranceServiceAddress,
                    promoServiceAddress,
                    notificationServiceAddress,
                    tripIds[i],
                    sender
                );
            }
        }

        _emitTripEvent(notificationServiceAddress, tripId, Schemas.TripStatus.Approved, sender, trip.booking.customer);
    }

    function rejectTripRequest(
        TripMain tripMain,
        address paymentServiceAddress,
        address currencyConverterAddress,
        address insuranceServiceAddress,
        address promoServiceAddress,
        address notificationServiceAddress,
        uint256 tripId,
        address sender
    ) external {
        _rejectTripRequest(
            tripMain,
            paymentServiceAddress,
            currencyConverterAddress,
            insuranceServiceAddress,
            promoServiceAddress,
            notificationServiceAddress,
            tripId,
            sender
        );
    }

    function confirmCheckOut(
        TripMain tripMain,
        address userServiceAddress,
        address paymentServiceAddress,
        address currencyConverterAddress,
        address insuranceServiceAddress,
        address promoServiceAddress,
        address notificationServiceAddress,
        uint256 tripId,
        address sender
    ) external {
        Trip memory trip = tripMain.getTrip(tripId);
        require(
            trip.booking.customer == sender || ITripGatewayWriteLibUserService(userServiceAddress).isAdmin(sender),
            "For trip guest or admin"
        );
        require(trip.booking.provider == trip.tripFinishedBy, "No needs to confirm.");
        require(trip.status == TripStatus.CheckedOutByHost, "The trip is not in status CheckedOutByHost");

        _finishTrip(
            tripMain,
            paymentServiceAddress,
            currencyConverterAddress,
            insuranceServiceAddress,
            promoServiceAddress,
            notificationServiceAddress,
            tripId,
            sender
        );
    }

    function finishTrip(
        TripMain tripMain,
        address paymentServiceAddress,
        address currencyConverterAddress,
        address insuranceServiceAddress,
        address promoServiceAddress,
        address notificationServiceAddress,
        uint256 tripId,
        address sender
    ) external {
        Trip memory trip = tripMain.getTrip(tripId);
        require(
            trip.status == TripStatus.CheckedOutByHost && trip.tripFinishedBy == trip.booking.customer,
            "The trip is not CheckedOutByHost"
        );
        _finishTrip(
            tripMain,
            paymentServiceAddress,
            currencyConverterAddress,
            insuranceServiceAddress,
            promoServiceAddress,
            notificationServiceAddress,
            tripId,
            sender
        );
    }

    function _rejectTripRequest(
        TripMain tripMain,
        address paymentServiceAddress,
        address currencyConverterAddress,
        address insuranceServiceAddress,
        address promoServiceAddress,
        address notificationServiceAddress,
        uint256 tripId,
        address sender
    ) private {
        Trip memory trip = tripMain.getTrip(tripId);
        Schemas.Trip memory legacyTrip = TripGatewayFacetLib.toLegacyTrip(trip);

        uint256 insurance = ITripGatewayWriteLibInsuranceService(insuranceServiceAddress).getInsurancePriceByTrip(tripId);
        uint64 totalTax = ITripGatewayWriteLibPaymentService(paymentServiceAddress).getTotalTripTax(tripId);
        uint256 valueToReturnInUsdCents = ITripGatewayWriteLibCurrencyConverter(currencyConverterAddress)
            .calculateTripReject(legacyTrip.paymentInfo, insurance, totalTax);

        tripMain.rejectTrip(tripId, 0, valueToReturnInUsdCents, 0, sender);
        ITripGatewayWriteLibPaymentService(paymentServiceAddress).payRejectTrip(
            legacyTrip,
            tripMain.getEthSumInTripCreation(tripId)
        );
        ITripGatewayWriteLibPromoService(promoServiceAddress).rejectDiscountByTrip(tripId, trip.booking.customer);

        Trip memory updatedTrip = tripMain.getTrip(tripId);
        _emitTripEvent(
            notificationServiceAddress,
            tripId,
            Schemas.TripStatus.Canceled,
            sender,
            sender == updatedTrip.booking.customer ? updatedTrip.booking.customer : updatedTrip.booking.provider
        );
    }

    function _finishTrip(
        TripMain tripMain,
        address paymentServiceAddress,
        address currencyConverterAddress,
        address insuranceServiceAddress,
        address promoServiceAddress,
        address notificationServiceAddress,
        uint256 tripId,
        address sender
    ) private {
        tripMain.finishTrip(tripId, sender);
        Trip memory trip = tripMain.getTrip(tripId);
        Schemas.Trip memory legacyTrip = TripGatewayFacetLib.toLegacyTrip(trip);

        uint256 rentalityFee = ITripGatewayWriteLibPaymentService(paymentServiceAddress).getPlatformFeeFrom(
            trip.paymentInfo.priceWithDiscount + trip.paymentInfo.pickUpFee + trip.paymentInfo.dropOfFee
        );
        uint256 insurancePrice = ITripGatewayWriteLibInsuranceService(insuranceServiceAddress).getInsurancePriceByTrip(tripId);

        (
            uint256 valueToHost,
            uint256 valueToGuest,
            uint256 valueToHostInUsdCents,
            uint256 valueToGuestInUsdCents,
            uint256 totalIncome,
            uint256 tripCostValue
        ) = ITripGatewayWriteLibCurrencyConverter(currencyConverterAddress).calculateTripFinsish(
            legacyTrip.paymentInfo,
            rentalityFee,
            ITripGatewayWriteLibPaymentService(paymentServiceAddress).getPlatformFeeFrom(trip.paymentInfo.priceWithDiscount),
            insurancePrice,
            promoServiceAddress
        );

        ITripGatewayWriteLibPaymentService(paymentServiceAddress).payFinishTrip(
            legacyTrip,
            valueToHost,
            valueToGuest,
            totalIncome,
            tripCostValue
        );
        tripMain.saveTransactionInfo(
            tripId,
            rentalityFee,
            TripStatus.Finished,
            valueToGuestInUsdCents,
            valueToHostInUsdCents - trip.paymentInfo.resolveAmountInUsdCents - insurancePrice
        );

        _emitTripEvent(notificationServiceAddress, tripId, Schemas.TripStatus.Finished, trip.booking.provider, trip.booking.customer);
    }

    function _emitTripEvent(
        address notificationServiceAddress,
        uint256 tripId,
        Schemas.TripStatus status,
        address from,
        address to
    ) private {
        if (notificationServiceAddress == address(0)) {
            return;
        }
        ITripGatewayWriteLibNotificationService(notificationServiceAddress).emitEvent(
            Schemas.EventType.Trip,
            tripId,
            uint8(status),
            from,
            to
        );
    }
}





