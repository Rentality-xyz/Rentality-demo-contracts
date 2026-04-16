// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../models/trip/TripMain.sol";
import "../../models/trip/TripTypes.sol";
import "../../rentality_old/Schemas.sol";
import "../../rentality_old/abstract/IRentalityGeoService.sol";
import "../../rentality_old/adapter/ICarGateway.sol";

interface ITripGatewayFacetLibUserService {
    function hasPassedKYCAndTC(address user) external view returns (bool);
}

interface ITripGatewayFacetLibCurrencyConverter {
    function currencyTypeIsAvailable(address tokenAddress) external view returns (bool);
    function getFromUsdCentsLatest(address currencyType, uint256 amount) external view returns (uint256, int256, uint8);
    function getFromUsdCents(address currencyType, uint256 amountInUsdCents, int256 rate) external view returns (uint256);
}

interface ITripGatewayFacetLibPromoService {
    function getDiscountByPromo(string memory promoCode, address user) external view returns (uint);
}

interface ITripGatewayFacetLibDeliveryService {
    function calculatePricesByDeliveryDataInUsdCents(
        Schemas.LocationInfo memory pickUpLocation,
        Schemas.LocationInfo memory returnLocation,
        string memory carLat,
        string memory carLon,
        address host
    ) external view returns (uint64 pickUpPriceInUsdCents, uint64 returnPriceInUsdCents);
}

library TripGatewayFacetLib {
    function validateTripRequest(
        address userServiceAddress,
        address currencyConverterAddress,
        ICarGateway legacyCarGateway,
        TripMain tripMain,
        address currencyType,
        uint256 carId,
        uint64 startDateTime,
        uint64 endDateTime,
        address user
    ) external view {
        require(
            ITripGatewayFacetLibUserService(userServiceAddress).hasPassedKYCAndTC(user),
            "KYC or TC not passed."
        );
        require(
            ITripGatewayFacetLibCurrencyConverter(currencyConverterAddress).currencyTypeIsAvailable(currencyType),
            "Token is not available."
        );
        require(legacyCarGateway.ownerOf(carId) != user, "Car is not available for creator");
        require(
            !isCarUnavailable(legacyCarGateway, tripMain, carId, startDateTime, endDateTime),
            "Unavailable for current date."
        );
    }

    function isCarUnavailable(
        ICarGateway legacyCarGateway,
        TripMain tripMain,
        uint256 carId,
        uint64 startDateTime,
        uint64 endDateTime
    ) public view returns (bool) {
        uint256[] memory carTrips = tripMain.getCarTrips(carId);
        uint32 timeBuffer = legacyCarGateway.getCarInfoById(carId).timeBufferBetweenTripsInSec;

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
        address deliveryServiceAddress,
        ICarGateway legacyCarGateway,
        Schemas.CreateTripRequestWithDelivery memory request,
        Schemas.CarInfo memory carInfo,
        IRentalityGeoService geoService
    ) external view returns (uint64 pickUp, uint64 dropOf) {
        (pickUp, dropOf) = ITripGatewayFacetLibDeliveryService(deliveryServiceAddress)
            .calculatePricesByDeliveryDataInUsdCents(
                request.pickUpInfo.locationInfo,
                request.returnInfo.locationInfo,
                geoService.getCarLocationLatitude(carInfo.locationHash),
                geoService.getCarLocationLongitude(carInfo.locationHash),
                carInfo.createdBy
            );

        if (pickUp > 0) {
            legacyCarGateway.verifySignedLocationInfo(request.pickUpInfo);
        }
        if (dropOf > 0) {
            legacyCarGateway.verifySignedLocationInfo(request.returnInfo);
        }
    }

    function createPaymentInfo(
        address promoServiceAddress,
        address currencyConverterAddress,
        Schemas.CarInfo memory carInfo,
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
        external
        view
        returns (TripPaymentInfo memory paymentInfo, uint256, uint256, uint256, bool)
    {
        bool usePromo = false;
        uint64 discount = uint64(ITripGatewayFacetLibPromoService(promoServiceAddress).getDiscountByPromo(promo, user));

        uint256 valueSum =
            priceWithDiscount + taxesSum + carInfo.securityDepositPerTripInUsdCents + pickUp + dropOf + insurance;

        uint256 priceWithPromo = 0;
        if (discount > 0) {
            require(discount == 100 || (pickUp == 0 && pickUp == 0), "PickUp and DropOf should be 0");
            usePromo = true;
            uint256 sumBeforePromo = priceWithDiscount + taxesSum + pickUp + dropOf;
            priceWithPromo = sumBeforePromo - ((sumBeforePromo * discount) / 100);
        }

        (uint256 valueSumInCurrency, int256 rate, uint8 decimals) = ITripGatewayFacetLibCurrencyConverter(
            currencyConverterAddress
        ).getFromUsdCentsLatest(currencyType, valueSum);

        uint256 valueSumInCurrencyBeforePromo = valueSumInCurrency;
        uint256 hostEarnings = valueSum;
        if (discount > 0) {
            hostEarnings = priceWithPromo;
            valueSumInCurrency = ITripGatewayFacetLibCurrencyConverter(currencyConverterAddress).getFromUsdCents(
                currencyType,
                priceWithPromo + carInfo.securityDepositPerTripInUsdCents + insurance,
                rate
            );
        }

        paymentInfo = TripPaymentInfo({
            tripId: 0,
            from: user,
            to: paymentRecipient,
            totalDayPriceInUsdCents: carInfo.pricePerDayInUsdCents * daysOfTrip,
            salesTax: 0,
            governmentTax: 0,
            priceWithDiscount: priceWithDiscount,
            depositInUsdCents: carInfo.securityDepositPerTripInUsdCents,
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

    function getCeilDays(uint64 startDateTime, uint64 endDateTime) external pure returns (uint64) {
        uint64 duration = endDateTime - startDateTime;
        return uint64((duration + 1 days - 1) / 1 days);
    }

    function toLegacyTripDTO(TripDTO memory tripDto) external pure returns (Schemas.TripDTO memory) {
        return Schemas.TripDTO({
            trip: toLegacyTrip(tripDto.trip),
            guestPhotoUrl: tripDto.guestPhotoUrl,
            hostPhotoUrl: tripDto.hostPhotoUrl,
            metadataURI: tripDto.metadataURI,
            timeZoneId: tripDto.timeZoneId,
            hostDrivingLicenseNumber: tripDto.hostDrivingLicenseNumber,
            hostDrivingLicenseExpirationDate: tripDto.hostDrivingLicenseExpirationDate,
            guestDrivingLicenseNumber: tripDto.guestDrivingLicenseNumber,
            guestDrivingLicenseExpirationDate: tripDto.guestDrivingLicenseExpirationDate,
            model: tripDto.model,
            brand: tripDto.brand,
            yearOfProduction: tripDto.yearOfProduction,
            pickUpLocation: toLegacyLocation(tripDto.pickUpLocation),
            returnLocation: toLegacyLocation(tripDto.returnLocation),
            guestPhoneNumber: tripDto.guestPhoneNumber,
            hostPhoneNumber: tripDto.hostPhoneNumber,
            insurancesInfo: toLegacyInsuranceInfos(tripDto.insurancesInfo),
            paidForInsuranceInUsdCents: tripDto.paidForInsuranceInUsdCents,
            guestDrivingLicenseIssueCountry: tripDto.guestDrivingLicenseIssueCountry,
            promoDiscount: tripDto.promoDiscount,
            dimoTokenId: tripDto.dimoTokenId,
            taxesData: toLegacyTaxValues(tripDto.taxesData),
            currency: toLegacyUserCurrency(tripDto.currency),
            guestNickName: tripDto.guestNickName,
            hostNickName: tripDto.hostNickName,
            paidToInsuranceInUsdCents: tripDto.paidToInsuranceInUsdCents
        });
    }

    function toLegacyTrip(Trip memory trip) public pure returns (Schemas.Trip memory) {
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

    function toLegacyPaymentInfo(TripPaymentInfo memory paymentInfo) public pure returns (Schemas.PaymentInfo memory) {
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
        public
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

    function toLegacyLocation(LocationInfo memory location) public pure returns (Schemas.LocationInfo memory) {
        return Schemas.LocationInfo({
            userAddress: location.userAddress,
            country: location.country,
            state: location.state,
            city: location.city,
            latitude: location.latitude,
            longitude: location.longitude,
            timeZoneId: location.timeZoneId
        });
    }

    function toLegacyInsuranceInfos(TripInsuranceInfo[] memory insurances)
        public
        pure
        returns (Schemas.InsuranceInfo[] memory result)
    {
        result = new Schemas.InsuranceInfo[](insurances.length);
        for (uint256 i = 0; i < insurances.length; i++) {
            result[i] = Schemas.InsuranceInfo({
                companyName: insurances[i].companyName,
                policyNumber: insurances[i].policyNumber,
                photo: insurances[i].photo,
                comment: insurances[i].comment,
                insuranceType: Schemas.InsuranceType(insurances[i].insuranceType),
                createdTime: insurances[i].createdTime,
                createdBy: insurances[i].createdBy
            });
        }
    }

    function toLegacyTaxValues(TripTaxValue[] memory taxes)
        public
        pure
        returns (Schemas.TaxValue[] memory result)
    {
        result = new Schemas.TaxValue[](taxes.length);
        for (uint256 i = 0; i < taxes.length; i++) {
            result[i] = Schemas.TaxValue({
                name: taxes[i].name,
                value: taxes[i].value,
                tType: Schemas.TaxesType(taxes[i].taxType)
            });
        }
    }

    function toLegacyUserCurrency(TripUserCurrency memory currency)
        public
        pure
        returns (Schemas.UserCurrencyDTO memory)
    {
        return Schemas.UserCurrencyDTO({
            currency: currency.currency,
            name: currency.name,
            initialized: currency.initialized
        });
    }
}
