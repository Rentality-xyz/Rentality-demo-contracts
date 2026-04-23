// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../models/trip/TripTypes.sol";
import "../../models/common/CommonTypes.sol";

library TripMapper {
    function toLegacyTripDTO(TripDTO memory tripDto) external pure returns (TripGatewayTypes.GatewayTripDTO memory) {
        return TripGatewayTypes.GatewayTripDTO({
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

    function toLegacyTrip(Trip memory trip) public pure returns (TripGatewayTypes.GatewayTrip memory) {
        return TripGatewayTypes.GatewayTrip({
            tripId: trip.booking.id,
            carId: trip.booking.resourceId,
            status: TripGatewayTypes.GatewayTripStatus(uint8(trip.status)),
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

    function toLegacyPaymentInfo(TripPaymentInfo memory paymentInfo) public pure returns (TripGatewayTypes.GatewayPaymentInfo memory) {
        return TripGatewayTypes.GatewayPaymentInfo({
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
        returns (TripGatewayTypes.GatewayTransactionInfo memory)
    {
        return TripGatewayTypes.GatewayTransactionInfo({
            rentalityFee: transactionInfo.rentalityFee,
            depositRefund: transactionInfo.depositRefund,
            tripEarnings: transactionInfo.tripEarnings,
            dateTime: transactionInfo.dateTime,
            statusBeforeCancellation: TripGatewayTypes.GatewayTripStatus(uint8(transactionInfo.statusBeforeCancellation))
        });
    }

    function toLegacyLocation(LocationInfo memory location) public pure returns (LocationInfo memory) {
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

    function toLegacyInsuranceInfos(TripInsuranceInfo[] memory insurances)
        public
        pure
        returns (TripGatewayTypes.GatewayInsuranceInfo[] memory result)
    {
        result = new TripGatewayTypes.GatewayInsuranceInfo[](insurances.length);
        for (uint256 i = 0; i < insurances.length; i++) {
            result[i] = TripGatewayTypes.GatewayInsuranceInfo({
                companyName: insurances[i].companyName,
                policyNumber: insurances[i].policyNumber,
                photo: insurances[i].photo,
                comment: insurances[i].comment,
                insuranceType: TripGatewayTypes.GatewayInsuranceType(insurances[i].insuranceType),
                createdTime: insurances[i].createdTime,
                createdBy: insurances[i].createdBy
            });
        }
    }

    function toLegacyTaxValues(TripTaxValue[] memory taxes)
        public
        pure
        returns (TripGatewayTypes.GatewayTaxValue[] memory result)
    {
        result = new TripGatewayTypes.GatewayTaxValue[](taxes.length);
        for (uint256 i = 0; i < taxes.length; i++) {
            result[i] = TripGatewayTypes.GatewayTaxValue({
                name: taxes[i].name,
                value: taxes[i].value,
                tType: TripGatewayTypes.GatewayTaxesType(taxes[i].taxType)
            });
        }
    }

    function toLegacyUserCurrency(TripUserCurrency memory currency)
        public
        pure
        returns (TripGatewayTypes.GatewayUserCurrencyDTO memory)
    {
        return TripGatewayTypes.GatewayUserCurrencyDTO({
            currency: currency.currency,
            name: currency.name,
            initialized: currency.initialized
        });
    }
}


