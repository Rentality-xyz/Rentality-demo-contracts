// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TripMain.sol";
import "./TripTypes.sol";
import "../car/CarTypes.sol";
import "../../rentality_old/Schemas.sol";
import "../../rentality_old/abstract/IRentalityGeoService.sol";

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

interface ITripLibDeliveryService {
    function calculatePricesByDeliveryDataInUsdCents(
        Schemas.LocationInfo memory pickUpLocation,
        Schemas.LocationInfo memory returnLocation,
        string memory carLat,
        string memory carLon,
        address host
    ) external view returns (uint64 pickUpPriceInUsdCents, uint64 returnPriceInUsdCents);
}

interface ITripLibCarQuery {
    function exists(uint256 id) external view returns (bool);
    function getOwner(uint256 id) external view returns (address);
    function getCar(uint256 id) external view returns (CarInfo memory);
    function getGeoVerifierAddress() external view returns (address);
    function verifySignedLocationInfo(SignedLocationInfo memory locationInfo) external view;
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
    ) external view {
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
        address deliveryServiceAddress,
        ITripLibCarQuery carQuery,
        Schemas.CreateTripRequestWithDelivery memory request,
        CarInfo memory carInfo
    ) external view returns (uint64 pickUp, uint64 dropOf) {
        IRentalityGeoService geoService = IRentalityGeoService(carQuery.getGeoVerifierAddress());

        (pickUp, dropOf) = ITripLibDeliveryService(deliveryServiceAddress).calculatePricesByDeliveryDataInUsdCents(
            request.pickUpInfo.locationInfo,
            request.returnInfo.locationInfo,
            geoService.getCarLocationLatitude(carInfo.car.locationHash),
            geoService.getCarLocationLongitude(carInfo.car.locationHash),
            carInfo.asset.owner
        );

        if (pickUp > 0) {
            carQuery.verifySignedLocationInfo(_toCommonSignedLocationInfo(request.pickUpInfo));
        }
        if (dropOf > 0) {
            carQuery.verifySignedLocationInfo(_toCommonSignedLocationInfo(request.returnInfo));
        }
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
        external
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

    function getCeilDays(uint64 startDateTime, uint64 endDateTime) external pure returns (uint64) {
        uint64 duration = endDateTime - startDateTime;
        return uint64((duration + 1 days - 1) / 1 days);
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
