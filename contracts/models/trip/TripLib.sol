pragma solidity ^0.8.20;

import "./TripMain.sol";
import "./TripTypes.sol";
import "../car/CarTypes.sol";
import "../profile/UserProfileTypes.sol";
import "../insurance/RentalInsuranceTypes.sol";
import "../common/Schemas.sol";
import "../../infrastructure/geo/IRentalityGeoService.sol";

interface ITripLibUserService {
    function hasPassedKYCAndTC(address user) external view returns (bool);
}

interface ITripLibCurrencyConverter {
    function currencyTypeIsAvailable(address tokenAddress) external view returns (bool);
    function getFromUsdCentsLatest(address currencyType, uint256 amount) external view returns (uint256, int256, uint8);
    function getFromUsdCents(address currencyType, uint256 amountInUsdCents, int256 rate) external view returns (uint256);
}

interface ITripLibPromoService {
    function getDiscountByPromo(string memory promoCode, address user) external view returns (uint);
}

interface ITripLibPricingService {
    function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 value) external view returns (uint64);
    function defineTaxesType(address carService, uint256 carId) external view returns (uint256);
    function calculateTaxes(uint256 taxId, uint64 tripDays, uint64 totalCost) external view returns (uint64);
}

interface ITripLibInsuranceService {
    function getInsurancePriceByCar(uint256 carId) external view returns (uint256);
    function isGuestHasInsurance(address guest) external view returns (bool);
}

interface ITripLibCarQuery {
    function exists(uint256 id) external view returns (bool);
    function getOwner(uint256 id) external view returns (address);
    function getCar(uint256 id) external view returns (CarInfo memory);
    function getGeoVerifierAddress() external view returns (address);
    function verifySignedLocationInfo(SignedLocationInfo memory locationInfo) external view;
    function calculateDeliveryPrices(
        uint256 carId,
        LocationInfo memory pickUpLocation,
        LocationInfo memory returnLocation
    ) external view returns (uint64 pickUp, uint64 dropOf);
}
interface ITripLibUserProfileMain {
    function isAdmin(address user) external view returns (bool);
    function getKYCProfile(address user) external view returns (UserProfileKYCInfo memory);
    function hasPassedKYCAndTC(address user) external view returns (bool);
    function getUserCurrency(address user) external view returns (address currency, bool initialized);
}

interface ITripLibWriteCarQuery is ITripLibCarQuery {
    function getCar(uint256 id) external view returns (CarInfo memory);
}

interface ITripLibWritePricingService {
    function getPlatformFeeFrom(uint256 value) external view returns (uint256);
    function getTotalTripTax(uint256 tripId) external view returns (uint64);
    function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 value) external view returns (uint64);
    function defineTaxesType(address carService, uint carId) external view returns (uint);
    function calculateAndSaveTaxes(uint taxId, uint64 daysOfTrip, uint64 value, uint tripId) external returns (uint64);
}

interface ITripLibWritePaymentService {
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

interface ITripLibWriteCurrencyConverter {
    function getDefaultCurrency() external view returns (Schemas.UserCurrencyDTO memory);
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

interface ITripLibWriteInsuranceService {
    function getInsurancePriceByTrip(uint256 tripId) external view returns (uint256);
    function calculateInsuranceForTrip(uint256 carId, uint64 startDateTime, uint64 endDateTime, address user) external view returns (uint256);
    function saveGuestInsurancePayment(uint256 tripId, uint256 carId, uint256 totalSum, address user) external;
    function saveTripInsuranceInfo(uint256 tripId, RentalSaveInsuranceRequest memory insuranceInfo, address user) external;
}

interface ITripLibWritePromoService {
    function usePromo(string memory promoCode, uint tripId, address user, uint totalPriceInCurrency, uint totalPrice, uint startDateTime, uint endDateTime) external;
    function rejectDiscountByTrip(uint256 tripId, address user) external;
}

interface ITripLibWriteNotificationService {
    function emitEvent(Schemas.EventType eType, uint256 id, uint8 objectStatus, address from, address to) external;
}

interface ITripLibWriteEngineService {
    function getFuelPriceFromEngineParams(uint8 eType, uint64[] memory engineParams) external view returns (uint64);
    function getPanelParamsAmount(uint8 eType) external view returns (uint256);
}
library TripLib {
    function validateTripRequest(
        address userServiceAddress,
        address currencyConverterAddress,
        ITripLibCarQuery carQuery,
        TripMain tripMain,
        address currencyType,
        uint256 carId,
        uint64 startDateTime,
        uint64 endDateTime,
        address user
    ) internal view {
        require(ITripLibUserService(userServiceAddress).hasPassedKYCAndTC(user), "KYC or TC not passed.");
        require(
            ITripLibCurrencyConverter(currencyConverterAddress).currencyTypeIsAvailable(currencyType),
            "Token is not available."
        );
        require(carQuery.exists(carId), "Car with this id does not exist.");
        require(carQuery.getOwner(carId) != user, "Car is not available for creator");
        require(!isCarUnavailable(carQuery, tripMain, carId, startDateTime, endDateTime), "Unavailable for current date.");
    }

    function isCarUnavailable(
        ITripLibCarQuery carQuery,
        TripMain tripMain,
        uint256 carId,
        uint64 startDateTime,
        uint64 endDateTime
    ) public view returns (bool) {
        uint256[] memory carTrips = tripMain.getCarTrips(carId);
        uint32 timeBuffer = carQuery.getCar(carId).car.timeBufferBetweenTripsInSec;

        for (uint256 i = 0; i < carTrips.length; i++) {
            Trip memory trip = tripMain.getTrip(carTrips[i]);
            if (
                trip.booking.resourceId == carId &&
                trip.booking.endDateTime + timeBuffer > startDateTime &&
                trip.booking.startDateTime < endDateTime
            ) {
                bool isActiveTrip =
                    trip.status != TripStatus.Created &&
                    trip.status != TripStatus.Finished &&
                    trip.status != TripStatus.Canceled;

                if (isActiveTrip) {
                    return true;
                }
            }
        }

        return false;
    }

    function calculateDelivery(
        ITripLibCarQuery carQuery,
        Schemas.CreateTripRequestWithDelivery memory request
    ) internal view returns (uint64 pickUp, uint64 dropOf) {
        (pickUp, dropOf) = carQuery.calculateDeliveryPrices(
            request.carId,
            _toCommonLocationInfo(request.pickUpInfo.locationInfo),
            _toCommonLocationInfo(request.returnInfo.locationInfo)
        );

        if (pickUp > 0) {
            carQuery.verifySignedLocationInfo(_toCommonSignedLocationInfo(request.pickUpInfo));
        }
        if (dropOf > 0) {
            carQuery.verifySignedLocationInfo(_toCommonSignedLocationInfo(request.returnInfo));
        }
    }

    function calculatePaymentsWithDelivery(
        address carQueryAddress,
        address pricingServiceAddress,
        address insuranceServiceAddress,
        address promoServiceAddress,
        address currencyConverterAddress,
        address carTaxAdapterAddress,
        uint256 carId,
        uint64 daysOfTrip,
        address currency,
        Schemas.LocationInfo memory pickUpLocation,
        Schemas.LocationInfo memory returnLocation,
        string memory promo,
        address user
    ) external view returns (Schemas.CalculatePaymentsDTO memory) {
        ITripLibCarQuery carQuery = ITripLibCarQuery(carQueryAddress);
        CarInfo memory car = carQuery.getCar(carId);
        address carOwner = car.asset.owner;

        (uint64 pickUp, uint64 dropOf) = carQuery.calculateDeliveryPrices(
            carId,
            _toCommonLocationInfo(pickUpLocation),
            _toCommonLocationInfo(returnLocation)
        );
        uint64 deliveryFee = pickUp + dropOf;

        uint64 discount = uint64(ITripLibPromoService(promoServiceAddress).getDiscountByPromo(promo, user));
        uint64 sumWithDiscount = ITripLibPricingService(pricingServiceAddress).calculateSumWithDiscount(
            carOwner,
            daysOfTrip,
            car.car.pricePerDayInUsdCents
        );
        uint256 taxId = ITripLibPricingService(pricingServiceAddress).defineTaxesType(carTaxAdapterAddress, carId);
        uint64 totalTaxes = ITripLibPricingService(pricingServiceAddress).calculateTaxes(
            taxId,
            daysOfTrip,
            sumWithDiscount + deliveryFee
        );

        uint64 priceBeforePromo = sumWithDiscount + totalTaxes + deliveryFee;
        uint64 discountedPrice = discount > 0
            ? priceBeforePromo - ((priceBeforePromo * discount) / 100)
            : priceBeforePromo;

        uint256 totalPrice = car.car.securityDepositPerTripInUsdCents + discountedPrice;
        if (!ITripLibInsuranceService(insuranceServiceAddress).isGuestHasInsurance(user)) {
            totalPrice += ITripLibInsuranceService(insuranceServiceAddress).getInsurancePriceByCar(carId) * daysOfTrip;
        }

        (uint256 valueSumInCurrency, int256 rate, uint8 decimals) = ITripLibCurrencyConverter(currencyConverterAddress)
            .getFromUsdCentsLatest(currency, totalPrice);
        if (discount == 100) {
            valueSumInCurrency = 0;
        }

        return Schemas.CalculatePaymentsDTO(valueSumInCurrency, rate, decimals);
    }

    function createPaymentInfo(
        address promoServiceAddress,
        address currencyConverterAddress,
        CarInfo memory carInfo,
        address currencyType,
        uint64 pickUp,
        uint64 dropOf,
        string memory promo,
        address user,
        uint256 insurance,
        uint64 taxesSum,
        uint64 daysOfTrip,
        uint64 priceWithDiscount,
        address paymentRecipient
    )
        internal
        view
        returns (TripPaymentInfo memory paymentInfo, uint256, uint256, uint256, bool)
    {
        bool usePromo = false;
        uint64 discount = uint64(ITripLibPromoService(promoServiceAddress).getDiscountByPromo(promo, user));

        uint256 valueSum =
            priceWithDiscount + taxesSum + carInfo.car.securityDepositPerTripInUsdCents + pickUp + dropOf + insurance;

        uint256 priceWithPromo = 0;
        if (discount > 0) {
            require(discount == 100 || (pickUp == 0 && pickUp == 0), "PickUp and DropOf should be 0");
            usePromo = true;
            uint256 sumBeforePromo = priceWithDiscount + taxesSum + pickUp + dropOf;
            priceWithPromo = sumBeforePromo - ((sumBeforePromo * discount) / 100);
        }

        (uint256 valueSumInCurrency, int256 rate, uint8 decimals) = ITripLibCurrencyConverter(currencyConverterAddress)
            .getFromUsdCentsLatest(currencyType, valueSum);

        uint256 valueSumInCurrencyBeforePromo = valueSumInCurrency;
        uint256 hostEarnings = valueSum;
        if (discount > 0) {
            hostEarnings = priceWithPromo;
            valueSumInCurrency = ITripLibCurrencyConverter(currencyConverterAddress).getFromUsdCents(
                currencyType,
                priceWithPromo + carInfo.car.securityDepositPerTripInUsdCents + insurance,
                rate
            );
        }

        paymentInfo = TripPaymentInfo({
            tripId: 0,
            from: user,
            to: paymentRecipient,
            totalDayPriceInUsdCents: carInfo.car.pricePerDayInUsdCents * daysOfTrip,
            salesTax: 0,
            governmentTax: 0,
            priceWithDiscount: priceWithDiscount,
            depositInUsdCents: carInfo.car.securityDepositPerTripInUsdCents,
            resolveAmountInUsdCents: 0,
            currencyType: currencyType,
            currencyRate: rate,
            currencyDecimals: decimals,
            resolveFuelAmountInUsdCents: 0,
            resolveMilesAmountInUsdCents: 0,
            pickUpFee: pickUp,
            dropOfFee: dropOf
        });

        if (discount == 100) {
            valueSumInCurrency = 0;
        }

        return (paymentInfo, valueSumInCurrency, valueSumInCurrencyBeforePromo, hostEarnings, usePromo);
    }

    function getCeilDays(uint64 startDateTime, uint64 endDateTime) internal pure returns (uint64) {
        uint64 duration = endDateTime - startDateTime;
        return uint64((duration + 1 days - 1) / 1 days);
    }


    function createTripRequestWithDelivery(
        TripMain tripMain,
        address userProfileMainAddress,
        address carQueryAddress,
        address carTaxAdapterAddress,
        address pricingServiceAddress,
        address paymentServiceAddress,
        address currencyConverterAddress,
        address insuranceServiceAddress,
        address promoServiceAddress,
        Schemas.CreateTripRequestWithDelivery memory request,
        string memory promo,
        address sender
    ) external {
        ITripLibWriteCarQuery carQuery = ITripLibWriteCarQuery(carQueryAddress);
        require(carTaxAdapterAddress != address(0), "Car tax adapter is not configured.");
        require(carQuery.exists(request.carId), "Car with this id does not exist.");

        address host = carQuery.getOwner(request.carId);
        (address hostCurrency, bool hasHostCurrency) = ITripLibUserProfileMain(userProfileMainAddress)
            .getUserCurrency(host);
        address currencyType = hasHostCurrency
            ? hostCurrency
            : ITripLibWriteCurrencyConverter(currencyConverterAddress).getDefaultCurrency().currency;

        validateTripRequest(
            userProfileMainAddress,
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
        (uint64 pickUp, uint64 dropOf) = calculateDelivery(carQuery, request);

        IRentalityGeoService geoService = IRentalityGeoService(carQuery.getGeoVerifierAddress());
        bytes32 pickUpHash = geoService.createSignedLocationInfo(request.pickUpInfo);
        bytes32 returnHash = geoService.createSignedLocationInfo(request.returnInfo);

        uint64 daysOfTrip = getCeilDays(request.startDateTime, request.endDateTime);
        uint256 insurance = ITripLibWriteInsuranceService(insuranceServiceAddress).calculateInsuranceForTrip(
            request.carId,
            request.startDateTime,
            request.endDateTime,
            sender
        );
        uint64 priceWithDiscount = ITripLibWritePricingService(pricingServiceAddress).calculateSumWithDiscount(
            host,
            daysOfTrip,
            carInfo.car.pricePerDayInUsdCents
        );
        uint256 tripId = tripMain.totalSupply() + 1;

        uint64 taxesSum = ITripLibWritePricingService(pricingServiceAddress).calculateAndSaveTaxes(
            ITripLibWritePricingService(pricingServiceAddress).defineTaxesType(carTaxAdapterAddress, request.carId),
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
        ) = createPaymentInfo(
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

        ITripLibWritePaymentService(paymentServiceAddress).payCreateTrip{value: msg.value}(
            currencyType,
            valueSumInCurrency,
            sender,
            request.carId,
            request.currencyType,
            request.amountIn,
            request.fee
        );

        ITripLibWriteEngineService engineService = ITripLibWriteEngineService(address(tripMain.engineService()));
        UserProfileKYCInfo memory guestInfo = ITripLibUserProfileMain(userProfileMainAddress).getKYCProfile(sender);
        UserProfileKYCInfo memory hostInfo = ITripLibUserProfileMain(userProfileMainAddress).getKYCProfile(host);

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

        ITripLibWriteInsuranceService(insuranceServiceAddress).saveGuestInsurancePayment(
            tripId,
            request.carId,
            insurance,
            sender
        );

        if (usePromo) {
            ITripLibWritePromoService(promoServiceAddress).usePromo(
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
        address pricingServiceAddress,
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
        uint32 timeBuffer = ITripLibWriteCarQuery(carQueryAddress).getCar(trip.booking.resourceId).car.timeBufferBetweenTripsInSec;

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
                    pricingServiceAddress,
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
        address pricingServiceAddress,
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
            pricingServiceAddress,
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
        address userProfileMainAddress,
        address pricingServiceAddress,
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
            trip.booking.customer == sender || ITripLibUserProfileMain(userProfileMainAddress).isAdmin(sender),
            "For trip guest or admin"
        );
        require(trip.booking.provider == trip.tripFinishedBy, "No needs to confirm.");
        require(trip.status == TripStatus.CheckedOutByHost, "The trip is not in status CheckedOutByHost");

        _finishTrip(
            tripMain,
            pricingServiceAddress,
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
        address pricingServiceAddress,
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
            pricingServiceAddress,
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
        address pricingServiceAddress,
        address paymentServiceAddress,
        address currencyConverterAddress,
        address insuranceServiceAddress,
        address promoServiceAddress,
        address notificationServiceAddress,
        uint256 tripId,
        address sender
    ) private {
        Trip memory trip = tripMain.getTrip(tripId);
        Schemas.Trip memory legacyTrip = toLegacyTrip(trip);

        uint256 insurance = ITripLibWriteInsuranceService(insuranceServiceAddress).getInsurancePriceByTrip(tripId);
        uint64 totalTax = ITripLibWritePricingService(pricingServiceAddress).getTotalTripTax(tripId);
        uint256 valueToReturnInUsdCents = ITripLibWriteCurrencyConverter(currencyConverterAddress)
            .calculateTripReject(legacyTrip.paymentInfo, insurance, totalTax);

        tripMain.rejectTrip(tripId, 0, valueToReturnInUsdCents, 0, sender);
        ITripLibWritePaymentService(paymentServiceAddress).payRejectTrip(
            legacyTrip,
            tripMain.getEthSumInTripCreation(tripId)
        );
        ITripLibWritePromoService(promoServiceAddress).rejectDiscountByTrip(tripId, trip.booking.customer);

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
        address pricingServiceAddress,
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
        Schemas.Trip memory legacyTrip = toLegacyTrip(trip);

        uint256 rentalityFee = ITripLibWritePricingService(pricingServiceAddress).getPlatformFeeFrom(
            trip.paymentInfo.priceWithDiscount + trip.paymentInfo.pickUpFee + trip.paymentInfo.dropOfFee
        );
        uint256 insurancePrice = ITripLibWriteInsuranceService(insuranceServiceAddress).getInsurancePriceByTrip(tripId);

        (
            uint256 valueToHost,
            uint256 valueToGuest,
            uint256 valueToHostInUsdCents,
            uint256 valueToGuestInUsdCents,
            uint256 totalIncome,
            uint256 tripCostValue
        ) = ITripLibWriteCurrencyConverter(currencyConverterAddress).calculateTripFinsish(
            legacyTrip.paymentInfo,
            rentalityFee,
            ITripLibWritePricingService(pricingServiceAddress).getPlatformFeeFrom(trip.paymentInfo.priceWithDiscount),
            insurancePrice,
            promoServiceAddress
        );

        ITripLibWritePaymentService(paymentServiceAddress).payFinishTrip(
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
        ITripLibWriteNotificationService(notificationServiceAddress).emitEvent(
            Schemas.EventType.Trip,
            tripId,
            uint8(status),
            from,
            to
        );
    }

    function toLegacyTrip(Trip memory trip) internal pure returns (Schemas.Trip memory) {
        return Schemas.Trip({
            tripId: trip.booking.id,
            carId: trip.booking.resourceId,
            status: Schemas.TripStatus(uint8(trip.status)),
            guest: trip.booking.customer,
            host: trip.booking.provider,
            guestName: trip.guestName,
            hostName: trip.hostName,
            pricePerDayInUsdCents: trip.pricePerDayInUsdCents,
            startDateTime: trip.booking.startDateTime,
            endDateTime: trip.booking.endDateTime,
            engineType: trip.engineType,
            milesIncludedPerDay: trip.milesIncludedPerDay,
            fuelPrice: trip.fuelPrice,
            paymentInfo: toLegacyPaymentInfo(trip.paymentInfo),
            createdDateTime: trip.booking.createdAt,
            approvedDateTime: trip.approvedDateTime,
            rejectedDateTime: trip.rejectedDateTime,
            guestInsuranceCompanyName: trip.guestInsuranceCompanyName,
            guestInsurancePolicyNumber: trip.guestInsurancePolicyNumber,
            rejectedBy: trip.rejectedBy,
            checkedInByHostDateTime: trip.checkedInByHostDateTime,
            startParamLevels: trip.startParamLevels,
            checkedInByGuestDateTime: trip.checkedInByGuestDateTime,
            tripStartedBy: trip.tripStartedBy,
            checkedOutByGuestDateTime: trip.checkedOutByGuestDateTime,
            tripFinishedBy: trip.tripFinishedBy,
            endParamLevels: trip.endParamLevels,
            checkedOutByHostDateTime: trip.checkedOutByHostDateTime,
            transactionInfo: toLegacyTransactionInfo(trip.transactionInfo),
            finishDateTime: trip.finishDateTime,
            pickUpHash: trip.pickUpHash,
            returnHash: trip.returnHash
        });
    }

    function toLegacyPaymentInfo(TripPaymentInfo memory paymentInfo) internal pure returns (Schemas.PaymentInfo memory) {
        return Schemas.PaymentInfo({
            tripId: paymentInfo.tripId,
            from: paymentInfo.from,
            to: paymentInfo.to,
            totalDayPriceInUsdCents: paymentInfo.totalDayPriceInUsdCents,
            salesTax: paymentInfo.salesTax,
            governmentTax: paymentInfo.governmentTax,
            priceWithDiscount: paymentInfo.priceWithDiscount,
            depositInUsdCents: paymentInfo.depositInUsdCents,
            resolveAmountInUsdCents: paymentInfo.resolveAmountInUsdCents,
            currencyType: paymentInfo.currencyType,
            currencyRate: paymentInfo.currencyRate,
            currencyDecimals: paymentInfo.currencyDecimals,
            resolveFuelAmountInUsdCents: paymentInfo.resolveFuelAmountInUsdCents,
            resolveMilesAmountInUsdCents: paymentInfo.resolveMilesAmountInUsdCents,
            pickUpFee: paymentInfo.pickUpFee,
            dropOfFee: paymentInfo.dropOfFee
        });
    }

    function toLegacyTransactionInfo(TripTransactionInfo memory transactionInfo)
        internal
        pure
        returns (Schemas.TransactionInfo memory)
    {
        return Schemas.TransactionInfo({
            rentalityFee: transactionInfo.rentalityFee,
            depositRefund: transactionInfo.depositRefund,
            tripEarnings: transactionInfo.tripEarnings,
            dateTime: transactionInfo.dateTime,
            statusBeforeCancellation: Schemas.TripStatus(uint8(transactionInfo.statusBeforeCancellation))
        });
    }
    function _toCommonLocationInfo(Schemas.LocationInfo memory location) private pure returns (LocationInfo memory) {
        return LocationInfo({
            userAddress: location.userAddress,
            country: location.country,
            state: location.state,
            city: location.city,
            latitude: location.latitude,
            longitude: location.longitude,
            timeZoneId: location.timeZoneId
        });
    }

    function _toCommonSignedLocationInfo(Schemas.SignedLocationInfo memory location)
        private
        pure
        returns (SignedLocationInfo memory)
    {
        return SignedLocationInfo({
            locationInfo: _toCommonLocationInfo(location.locationInfo),
            signature: location.signature
        });
    }
}






