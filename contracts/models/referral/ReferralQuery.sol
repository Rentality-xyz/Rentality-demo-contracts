// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../infrastructure/geo/IRentalityGeoService.sol';
import '../../infrastructure/services/AiDamageTypes.sol';
import '../car/CarTypes.sol';
import '../common/CommonTypes.sol';
import '../profile/UserProfileTypes.sol';
import '../trip/TripLib.sol';
import '../trip/TripTypes.sol';
import './ReferralMain.sol';
import './ReferralMainFacet1.sol';
import './ReferralTypes.sol';

interface IReferralQueryCarService {
  function getCarInfoById(uint256 carId) external view returns (CarGatewayTypes.GatewayCarInfo memory);
  function getGeoServiceAddress() external view returns (address);
}

interface IReferralQueryCurrencyConverter {
  function getFromUsdCents(address tokenAddress, uint256 amount, int256 currencyRate) external view returns (uint256);
  function getFromUsdCentsLatest(address tokenAddress, uint256 valueInUsdCents)
    external
    view
    returns (uint256, int256, uint8);
  function getCurrencyInfo(address currency) external view returns (UserCurrencyInfo memory);
}

interface IReferralQueryTripQuery {
  function getTrip(uint256 tripId) external view returns (Trip memory);
}

interface IReferralQueryUserService {
  function getKYCInfo(address user) external view returns (UserProfileKYCInfo memory);
  function getMyFullKYCInfo(address user) external view returns (FullUserProfileInfo memory);
}

interface IReferralQueryAiDamageService {
  function getLatestCaseId() external view returns (uint256 latestCaseId);
  function getCaseTokenForTrip(uint256 tripId, CaseType caseType) external view returns (string memory caseToken);
}

contract ReferralQuery {
  ReferralMain public immutable referralMain;
  ReferralMainFacet1 public immutable referralMainFacet1;
  IReferralQueryCarService public immutable carService;
  IReferralQueryCurrencyConverter public immutable currencyConverter;
  IReferralQueryTripQuery public immutable tripQuery;
  IReferralQueryUserService public immutable userService;
  IReferralQueryAiDamageService public immutable aiDamageService;

  constructor(
    address referralMainAddress,
    address carServiceAddress,
    address currencyConverterAddress,
    address tripQueryAddress,
    address userServiceAddress,
    address referralMainFacet1Address,
    address aiDamageServiceAddress
  ) {
    referralMain = ReferralMain(referralMainAddress);
    referralMainFacet1 = ReferralMainFacet1(referralMainFacet1Address);
    carService = IReferralQueryCarService(carServiceAddress);
    currencyConverter = IReferralQueryCurrencyConverter(currencyConverterAddress);
    tripQuery = IReferralQueryTripQuery(tripQueryAddress);
    userService = IReferralQueryUserService(userServiceAddress);
    aiDamageService = IReferralQueryAiDamageService(aiDamageServiceAddress);
  }

  function getPointsBalance(address user) external view returns (uint256) {
    return referralMain.getPointsBalance(user);
  }

  function getReferralHash(address user) external view returns (bytes4) {
    return referralMain.getReferralHash(user);
  }

  function hashExists(bytes4 hash) external view returns (bool) {
    return referralMain.hashExists(hash);
  }

  function getReadyToClaim(address user) external view returns (ReadyToClaimDTO memory) {
    return referralMain.getReadyToClaim(user);
  }

  function getReadyToClaimFromHash(address user) external view returns (ReferralHashDTO memory) {
    return referralMain.getReadyToClaimFromHash(user);
  }

  function getPointsHistory(address user) external view returns (ReferralProgramHistory[] memory) {
    return referralMain.getPointsHistory(user);
  }

  function getMyStartDiscount(address user) external view returns (uint256) {
    return referralMain.getMyStartDiscount(user);
  }

  function getMyReferralInfo(address user) external view returns (MyReferralInfoDTO memory) {
    return referralMain.getMyReferralInfo(user);
  }

  function getReferralPointsInfo() external view returns (AllReferralInfoDTO memory) {
    return referralMain.getReferralPointsInfo();
  }

  function getCarDailyClaimedTime(uint256 carId) external view returns (uint256) {
    return referralMain.getCarDailyClaimedTime(carId);
  }

  function getMyClaimsAs(bool host, address user) external view returns (FullReferralClaimInfo[] memory) {
    return host ? _getClaimsByHost(user) : _getClaimsByGuest(user);
  }

  function getClaim(uint256 claimId) external view returns (ReferralClaimInfoV2 memory) {
    return referralMainFacet1.getClaim(claimId);
  }

  function calculateClaimValue(uint256 claimId) external view returns (uint256) {
    ReferralClaimInfoV2 memory claim = referralMainFacet1.getClaim(claimId);
    if (claim.status == ReferralClaimStatus.Paid || claim.status == ReferralClaimStatus.Cancel) {
      return 0;
    }

    uint256 commission = referralMainFacet1.getPlatformFeeFrom(claim.amountInUsdCents);
    (uint256 result, , ) = currencyConverter.getFromUsdCentsLatest(
      TripLib.toLegacyTrip(tripQuery.getTrip(claim.tripId)).paymentInfo.currencyType,
      claim.amountInUsdCents + commission
    );

    return result;
  }

  function getAiDamageAnalyzeCaseRequest(uint tripId, CaseType caseType, address user)
    external
    view
    returns (AiDamageAnalyzeCaseRequestDTO memory aiDamageAnalyzeCaseRequest)
  {
    CarGatewayTypes.GatewayCarInfo memory car = carService.getCarInfoById(TripLib.toLegacyTrip(tripQuery.getTrip(tripId)).carId);
    FullUserProfileInfo memory kyc = userService.getMyFullKYCInfo(user);

    return AiDamageAnalyzeCaseRequestDTO(
      aiDamageService.getLatestCaseId(),
      kyc.additionalKYC.email,
      kyc.kyc.surname,
      aiDamageService.getCaseTokenForTrip(tripId, caseType),
      car.carVinNumber
    );
  }

  function _getClaimsByHost(address host) internal view returns (FullReferralClaimInfo[] memory) {
    uint256 claimsAmount = referralMainFacet1.getClaimsAmount();
    uint256 arraySize;

    for (uint256 i = 1; i <= claimsAmount; i++) {
      ReferralClaimInfoV2 memory claim = referralMainFacet1.getClaim(i);
      TripGatewayTypes.GatewayTrip memory trip = TripLib.toLegacyTrip(tripQuery.getTrip(claim.tripId));
      if (trip.host == host) {
        arraySize++;
      }
    }

    FullReferralClaimInfo[] memory claimInfos = new FullReferralClaimInfo[](arraySize);
    uint256 counter;

    for (uint256 i = 1; i <= claimsAmount; i++) {
      ReferralClaimInfoV2 memory claim = referralMainFacet1.getClaim(i);
      TripGatewayTypes.GatewayTrip memory trip = TripLib.toLegacyTrip(tripQuery.getTrip(claim.tripId));
      if (trip.host == host) {
        claimInfos[counter++] = _toFullReferralClaimInfo(claim, trip);
      }
    }

    return claimInfos;
  }

  function _getClaimsByGuest(address guest) internal view returns (FullReferralClaimInfo[] memory) {
    uint256 claimsAmount = referralMainFacet1.getClaimsAmount();
    uint256 arraySize;

    for (uint256 i = 1; i <= claimsAmount; i++) {
      ReferralClaimInfoV2 memory claim = referralMainFacet1.getClaim(i);
      TripGatewayTypes.GatewayTrip memory trip = TripLib.toLegacyTrip(tripQuery.getTrip(claim.tripId));
      if (trip.guest == guest) {
        arraySize++;
      }
    }

    FullReferralClaimInfo[] memory claimInfos = new FullReferralClaimInfo[](arraySize);
    uint256 counter;

    for (uint256 i = 1; i <= claimsAmount; i++) {
      ReferralClaimInfoV2 memory claim = referralMainFacet1.getClaim(i);
      TripGatewayTypes.GatewayTrip memory trip = TripLib.toLegacyTrip(tripQuery.getTrip(claim.tripId));
      if (trip.guest == guest) {
        claimInfos[counter++] = _toFullReferralClaimInfo(claim, trip);
      }
    }

    return claimInfos;
  }

  function _toFullReferralClaimInfo(ReferralClaimInfoV2 memory claim, TripGatewayTypes.GatewayTrip memory trip)
    internal
    view
    returns (FullReferralClaimInfo memory)
  {
    CarGatewayTypes.GatewayCarInfo memory car = carService.getCarInfoById(trip.carId);
    return FullReferralClaimInfo(
      claim,
      trip.host,
      trip.guest,
      userService.getKYCInfo(trip.guest).mobilePhoneNumber,
      userService.getKYCInfo(trip.host).mobilePhoneNumber,
      car,
      _getClaimValueInCurrency(trip.paymentInfo.currencyType, claim.amountInUsdCents, claim),
      IRentalityGeoService(carService.getGeoServiceAddress()).getCarTimeZoneId(car.locationHash),
      referralMainFacet1.getClaimTypeInfo(claim.claimType),
      currencyConverter.getCurrencyInfo(trip.paymentInfo.currencyType)
    );
  }

  function _getClaimValueInCurrency(
    address currency,
    uint256 amount,
    ReferralClaimInfoV2 memory claim
  ) internal view returns (uint256 valueInCurrency) {
    if (claim.status == ReferralClaimStatus.Paid) {
      (int256 rate, ) = referralMainFacet1.claimIdToCurrencyRate(claim.claimId);
      if (rate > 0) {
        valueInCurrency = currencyConverter.getFromUsdCents(currency, amount, rate);
      }
    } else {
      (valueInCurrency, , ) = currencyConverter.getFromUsdCentsLatest(currency, amount);
    }
  }
}
