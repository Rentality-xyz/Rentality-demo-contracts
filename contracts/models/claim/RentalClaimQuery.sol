// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../rentality_old/Schemas.sol';
import '../../rentality_old/abstract/IRentalityGeoService.sol';
import '../trip/TripLib.sol';
import '../trip/TripTypes.sol';

interface IRentalClaimQueryCarService {
  function getCarInfoById(uint256 carId) external view returns (Schemas.CarInfo memory);
  function getGeoServiceAddress() external view returns (address);
}

interface IRentalClaimQueryCurrencyConverter {
  function getFromUsdCents(address tokenAddress, uint256 amount, int256 currencyRate) external view returns (uint256);
  function getFromUsdCentsLatest(address tokenAddress, uint256 valueInUsdCents)
    external
    view
    returns (uint256, int256, uint8);
  function getCurrencyInfo(address currency) external view returns (Schemas.UserCurrencyDTO memory);
}

interface IRentalClaimQueryTripQuery {
  function getTrip(uint256 tripId) external view returns (Trip memory);
}

interface IRentalClaimQueryUserService {
  function getKYCInfo(address user) external view returns (Schemas.KYCInfo memory);
  function getMyFullKYCInfo(address user) external view returns (Schemas.FullKYCInfoDTO memory);
}

interface IRentalClaimQueryClaimService {
  function getClaimsAmount() external view returns (uint256);
  function getClaim(uint256 claimId) external view returns (Schemas.ClaimV2 memory);
  function getPlatformFeeFrom(uint256 value) external view returns (uint256);
  function getClaimTypeInfo(uint8 claimType) external view returns (Schemas.ClaimTypeV2 memory);
  function claimIdToCurrencyRate(uint256 claimId) external view returns (int256 rate, uint8 decimals);
}

interface IRentalClaimQueryAiDamageService {
  function getLatestCaseId() external view returns (uint256 latestCaseId);
  function getCaseTokenForTrip(uint256 tripId, Schemas.CaseType caseType) external view returns (string memory caseToken);
}

contract RentalClaimQuery {
  IRentalClaimQueryCarService public immutable carService;
  IRentalClaimQueryCurrencyConverter public immutable currencyConverter;
  IRentalClaimQueryTripQuery public immutable tripQuery;
  IRentalClaimQueryUserService public immutable userService;
  IRentalClaimQueryClaimService public immutable claimService;
  IRentalClaimQueryAiDamageService public immutable aiDamageService;

  constructor(
    address carServiceAddress,
    address currencyConverterAddress,
    address tripQueryAddress,
    address userServiceAddress,
    address claimServiceAddress,
    address aiDamageServiceAddress
  ) {
    carService = IRentalClaimQueryCarService(carServiceAddress);
    currencyConverter = IRentalClaimQueryCurrencyConverter(currencyConverterAddress);
    tripQuery = IRentalClaimQueryTripQuery(tripQueryAddress);
    userService = IRentalClaimQueryUserService(userServiceAddress);
    claimService = IRentalClaimQueryClaimService(claimServiceAddress);
    aiDamageService = IRentalClaimQueryAiDamageService(aiDamageServiceAddress);
  }

  function getMyClaimsAs(bool host, address user) external view returns (Schemas.FullClaimInfo[] memory) {
    return host ? _getClaimsByHost(user) : _getClaimsByGuest(user);
  }

  function getClaim(uint256 claimId) external view returns (Schemas.ClaimV2 memory) {
    return claimService.getClaim(claimId);
  }

  function calculateClaimValue(uint256 claimId) external view returns (uint256) {
    Schemas.ClaimV2 memory claim = claimService.getClaim(claimId);
    if (claim.status == Schemas.ClaimStatus.Paid || claim.status == Schemas.ClaimStatus.Cancel) {
      return 0;
    }

    uint256 commission = claimService.getPlatformFeeFrom(claim.amountInUsdCents);
    (uint256 result, , ) = currencyConverter.getFromUsdCentsLatest(
      TripLib.toLegacyTrip(tripQuery.getTrip(claim.tripId)).paymentInfo.currencyType,
      claim.amountInUsdCents + commission
    );

    return result;
  }

  function getAiDamageAnalyzeCaseRequest(uint tripId, Schemas.CaseType caseType, address user)
    external
    view
    returns (Schemas.AiDamageAnalyzeCaseRequestDTO memory aiDamageAnalyzeCaseRequest)
  {
    Schemas.CarInfo memory car = carService.getCarInfoById(TripLib.toLegacyTrip(tripQuery.getTrip(tripId)).carId);
    Schemas.FullKYCInfoDTO memory kyc = userService.getMyFullKYCInfo(user);

    return Schemas.AiDamageAnalyzeCaseRequestDTO(
      aiDamageService.getLatestCaseId(),
      kyc.additionalKYC.email,
      kyc.kyc.surname,
      aiDamageService.getCaseTokenForTrip(tripId, caseType),
      car.carVinNumber
    );
  }

  function _getClaimsByHost(address host) internal view returns (Schemas.FullClaimInfo[] memory) {
    uint256 claimsAmount = claimService.getClaimsAmount();
    uint256 arraySize;

    for (uint256 i = 1; i <= claimsAmount; i++) {
      Schemas.ClaimV2 memory claim = claimService.getClaim(i);
      Schemas.Trip memory trip = TripLib.toLegacyTrip(tripQuery.getTrip(claim.tripId));
      if (trip.host == host) {
        arraySize++;
      }
    }

    Schemas.FullClaimInfo[] memory claimInfos = new Schemas.FullClaimInfo[](arraySize);
    uint256 counter;

    for (uint256 i = 1; i <= claimsAmount; i++) {
      Schemas.ClaimV2 memory claim = claimService.getClaim(i);
      Schemas.Trip memory trip = TripLib.toLegacyTrip(tripQuery.getTrip(claim.tripId));
      if (trip.host == host) {
        claimInfos[counter++] = _toFullClaimInfo(claim, trip);
      }
    }

    return claimInfos;
  }

  function _getClaimsByGuest(address guest) internal view returns (Schemas.FullClaimInfo[] memory) {
    uint256 claimsAmount = claimService.getClaimsAmount();
    uint256 arraySize;

    for (uint256 i = 1; i <= claimsAmount; i++) {
      Schemas.ClaimV2 memory claim = claimService.getClaim(i);
      Schemas.Trip memory trip = TripLib.toLegacyTrip(tripQuery.getTrip(claim.tripId));
      if (trip.guest == guest) {
        arraySize++;
      }
    }

    Schemas.FullClaimInfo[] memory claimInfos = new Schemas.FullClaimInfo[](arraySize);
    uint256 counter;

    for (uint256 i = 1; i <= claimsAmount; i++) {
      Schemas.ClaimV2 memory claim = claimService.getClaim(i);
      Schemas.Trip memory trip = TripLib.toLegacyTrip(tripQuery.getTrip(claim.tripId));
      if (trip.guest == guest) {
        claimInfos[counter++] = _toFullClaimInfo(claim, trip);
      }
    }

    return claimInfos;
  }

  function _toFullClaimInfo(Schemas.ClaimV2 memory claim, Schemas.Trip memory trip)
    internal
    view
    returns (Schemas.FullClaimInfo memory)
  {
    Schemas.CarInfo memory car = carService.getCarInfoById(trip.carId);
    return Schemas.FullClaimInfo(
      claim,
      trip.host,
      trip.guest,
      userService.getKYCInfo(trip.guest).mobilePhoneNumber,
      userService.getKYCInfo(trip.host).mobilePhoneNumber,
      car,
      _getClaimValueInCurrency(trip.paymentInfo.currencyType, claim.amountInUsdCents, claim),
      IRentalityGeoService(carService.getGeoServiceAddress()).getCarTimeZoneId(car.locationHash),
      claimService.getClaimTypeInfo(claim.claimType),
      currencyConverter.getCurrencyInfo(trip.paymentInfo.currencyType)
    );
  }

  function _getClaimValueInCurrency(
    address currency,
    uint256 amount,
    Schemas.ClaimV2 memory claim
  ) internal view returns (uint256 valueInCurrency) {
    if (claim.status == Schemas.ClaimStatus.Paid) {
      (int256 rate, ) = claimService.claimIdToCurrencyRate(claim.claimId);
      if (rate > 0) {
        valueInCurrency = currencyConverter.getFromUsdCents(currency, amount, rate);
      }
    } else {
      (valueInCurrency, , ) = currencyConverter.getFromUsdCentsLatest(currency, amount);
    }
  }
}
