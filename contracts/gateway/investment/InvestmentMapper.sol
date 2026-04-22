// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../models/base/asset/AssetTypes.sol';
import '../../models/car/CarTypes.sol';
import '../../models/investment/RentalInvestmentTypes.sol';
import '../../models/common/Schemas.sol';

library InvestmentMapper {
    function toModelInvestment(Schemas.CarInvestment memory legacyInvestment)
        internal
        pure
        returns (RentalCarInvestment memory)
    {
        return RentalCarInvestment({
            car: toModelInvestmentCarRequest(legacyInvestment.car),
            priceInCurrency: legacyInvestment.priceInCurrency,
            inProgress: legacyInvestment.inProgress,
            creatorPercents: legacyInvestment.creatorPercents
        });
    }

    function toModelInvestmentCarRequest(Schemas.CreateCarRequest memory legacyRequest)
        internal
        pure
        returns (RentalInvestmentCarRequest memory)
    {
        return RentalInvestmentCarRequest({
            car: CreateCarRequest({
                asset: CreateAssetRequest({name: '', metadataURI: legacyRequest.tokenUri}),
                carVinNumber: legacyRequest.carVinNumber,
                brand: legacyRequest.brand,
                model: legacyRequest.model,
                yearOfProduction: legacyRequest.yearOfProduction,
                pricePerDayInUsdCents: legacyRequest.pricePerDayInUsdCents,
                securityDepositPerTripInUsdCents: legacyRequest.securityDepositPerTripInUsdCents,
                engineParams: legacyRequest.engineParams,
                engineType: legacyRequest.engineType,
                milesIncludedPerDay: legacyRequest.milesIncludedPerDay,
                timeBufferBetweenTripsInSec: legacyRequest.timeBufferBetweenTripsInSec,
                locationInfo: SignedLocationInfo({
                    locationInfo: LocationInfo({
                        userAddress: legacyRequest.locationInfo.locationInfo.userAddress,
                        country: legacyRequest.locationInfo.locationInfo.country,
                        state: legacyRequest.locationInfo.locationInfo.state,
                        city: legacyRequest.locationInfo.locationInfo.city,
                        latitude: legacyRequest.locationInfo.locationInfo.latitude,
                        longitude: legacyRequest.locationInfo.locationInfo.longitude,
                        timeZoneId: legacyRequest.locationInfo.locationInfo.timeZoneId
                    }),
                    signature: legacyRequest.locationInfo.signature
                }),
                currentlyListed: legacyRequest.currentlyListed
            }),
            insuranceRequired: legacyRequest.insuranceRequired,
            insurancePriceInUsdCents: legacyRequest.insurancePriceInUsdCents
        });
    }

    function toLegacyInvestmentDTOs(RentalInvestmentDTO[] memory dtos)
        internal
        pure
        returns (Schemas.InvestmentDTO[] memory result)
    {
        result = new Schemas.InvestmentDTO[](dtos.length);
        for (uint256 i = 0; i < dtos.length; i++) {
            result[i] = toLegacyInvestmentDTO(dtos[i]);
        }
    }

    function toLegacyInvestmentDTO(RentalInvestmentDTO memory dto)
        internal
        pure
        returns (Schemas.InvestmentDTO memory)
    {
        return Schemas.InvestmentDTO({
            investment: toLegacyCarInvestment(dto.investment),
            nft: dto.nft,
            investmentId: dto.investmentId,
            payedInUsd: dto.payedInUsd,
            creator: dto.creator,
            isCarBought: dto.isCarBought,
            income: dto.income,
            myIncome: dto.myIncome,
            myInvestingSum: dto.myInvestingSum,
            listingDate: dto.listingDate,
            myTokens: dto.myTokens,
            myPart: dto.myPart,
            totalHolders: dto.totalHolders,
            totalTokens: dto.totalTokens,
            currency: dto.currency,
            totalEarnings: dto.totalEarnings,
            userReceivedEarnings: dto.userReceivedEarnings,
            name: dto.name,
            symbol: dto.symbol,
            priceInUsdCents: dto.priceInUsdCents,
            payedInCurrency: dto.payedInCurrency,
            listed: dto.listed
        });
    }

    function toLegacyCarInvestment(RentalCarInvestment memory investment)
        internal
        pure
        returns (Schemas.CarInvestment memory)
    {
        return Schemas.CarInvestment({
            car: toLegacyCreateCarRequest(investment.car),
            priceInCurrency: investment.priceInCurrency,
            inProgress: investment.inProgress,
            creatorPercents: investment.creatorPercents
        });
    }

    function toLegacyCreateCarRequest(RentalInvestmentCarRequest memory request)
        internal
        pure
        returns (Schemas.CreateCarRequest memory)
    {
        return Schemas.CreateCarRequest({
            tokenUri: request.car.asset.metadataURI,
            carVinNumber: request.car.carVinNumber,
            brand: request.car.brand,
            model: request.car.model,
            yearOfProduction: request.car.yearOfProduction,
            pricePerDayInUsdCents: request.car.pricePerDayInUsdCents,
            securityDepositPerTripInUsdCents: request.car.securityDepositPerTripInUsdCents,
            engineParams: request.car.engineParams,
            engineType: request.car.engineType,
            milesIncludedPerDay: request.car.milesIncludedPerDay,
            timeBufferBetweenTripsInSec: request.car.timeBufferBetweenTripsInSec,
            geoApiKey: '',
            locationInfo: Schemas.SignedLocationInfo({
                locationInfo: Schemas.LocationInfo({
                    userAddress: request.car.locationInfo.locationInfo.userAddress,
                    country: request.car.locationInfo.locationInfo.country,
                    state: request.car.locationInfo.locationInfo.state,
                    city: request.car.locationInfo.locationInfo.city,
                    latitude: request.car.locationInfo.locationInfo.latitude,
                    longitude: request.car.locationInfo.locationInfo.longitude,
                    timeZoneId: request.car.locationInfo.locationInfo.timeZoneId
                }),
                signature: request.car.locationInfo.signature
            }),
            currentlyListed: request.car.currentlyListed,
            insuranceRequired: request.insuranceRequired,
            insurancePriceInUsdCents: request.insurancePriceInUsdCents,
            dimoTokenId: 0,
            signedDimoTokenId: hex""
        });
    }
}



