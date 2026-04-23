// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../infrastructure/geo/IRentalityGeoService.sol';
import '../base/insurance/InsuranceTypes.sol';
import '../car/CarTypes.sol';
import '../referral/ReferralTypes.sol';
import '../common/CommonTypes.sol';
import '../profile/UserProfileTypes.sol';
import '../trip/TripTypes.sol';
import './InsuranceTypes.sol';

interface IInsuranceQueryFacet2InsuranceService {
  function getMyInsurancesAsGuest(address user) external view returns (InsuranceInfo[] memory);
}

interface IInsuranceQueryFacet2HostInsurance {
  function getInsuranceClaims() external view returns (uint256[] memory);
  function getHostInsuranceRule(address host) external view returns (HostInsuranceRuleDTO memory);
  function getAllInsuranceRules() external view returns (HostInsuranceRuleDTO[] memory);
}

interface IInsuranceQueryFacet2ClaimService {
  function getClaim(uint256 claimId) external view returns (ReferralClaimInfoV2 memory);
  function getClaimTypeInfo(uint8 claimType) external view returns (ReferralClaimTypeInfo memory);
  function claimIdToCurrencyRate(uint256 claimId) external view returns (int256 rate, uint8 decimals);
}

interface IInsuranceQueryFacet2TripQuery {
  function getTrip(uint256 tripId) external view returns (Trip memory);
}

interface IInsuranceQueryFacet2UserService {
  function getKYCInfo(address user) external view returns (UserProfileKYCInfo memory);
}

interface IInsuranceQueryFacet2CarService {
  function getCarInfoById(uint256 carId) external view returns (CarGatewayTypes.GatewayCarInfo memory);
  function getGeoServiceAddress() external view returns (address);
}

interface IInsuranceQueryFacet2CurrencyConverter {
  function getFromUsdCents(address tokenAddress, uint256 amount, int256 currencyRate) external view returns (uint256);
  function getFromUsdCentsLatest(address tokenAddress, uint256 valueInUsdCents)
    external
    view
    returns (uint256, int256, uint8);
  function getCurrencyInfo(address currency) external view returns (UserCurrencyInfo memory);
}

contract InsuranceQueryFacet2 {
  IInsuranceQueryFacet2InsuranceService public immutable insuranceService;
  IInsuranceQueryFacet2HostInsurance public immutable hostInsurance;
  IInsuranceQueryFacet2ClaimService public immutable claimService;
  IInsuranceQueryFacet2TripQuery public immutable tripQuery;
  IInsuranceQueryFacet2UserService public immutable userService;
  IInsuranceQueryFacet2CarService public immutable carService;
  IInsuranceQueryFacet2CurrencyConverter public immutable currencyConverter;
  address payable public immutable hostInsuranceAddress;

  constructor(
    address insuranceServiceAddress,
    address hostInsuranceContractAddress,
    address claimServiceAddress,
    address tripQueryAddress,
    address userServiceAddress,
    address carServiceAddress,
    address currencyConverterAddress
  ) {
    insuranceService = IInsuranceQueryFacet2InsuranceService(insuranceServiceAddress);
    hostInsurance = IInsuranceQueryFacet2HostInsurance(hostInsuranceContractAddress);
    claimService = IInsuranceQueryFacet2ClaimService(claimServiceAddress);
    tripQuery = IInsuranceQueryFacet2TripQuery(tripQueryAddress);
    userService = IInsuranceQueryFacet2UserService(userServiceAddress);
    carService = IInsuranceQueryFacet2CarService(carServiceAddress);
    currencyConverter = IInsuranceQueryFacet2CurrencyConverter(currencyConverterAddress);
    hostInsuranceAddress = payable(hostInsuranceContractAddress);
  }

  function getGuestInsurance(address guest) external view returns (InsuranceInfo[] memory) {
    return insuranceService.getMyInsurancesAsGuest(guest);
  }

  function getHostInsuranceClaims() external view returns (FullReferralClaimInfo[] memory claimInfos) {
    uint256[] memory claimIds = hostInsurance.getInsuranceClaims();
    claimInfos = new FullReferralClaimInfo[](claimIds.length);

    for (uint256 i = 0; i < claimIds.length; i++) {
      ReferralClaimInfoV2 memory claim = claimService.getClaim(claimIds[i]);
      Trip memory trip = tripQuery.getTrip(claim.tripId);
      CarGatewayTypes.GatewayCarInfo memory car = carService.getCarInfoById(trip.booking.resourceId);

      claimInfos[i] = FullReferralClaimInfo(
        claim,
        trip.booking.provider,
        trip.booking.customer,
        userService.getKYCInfo(trip.booking.customer).mobilePhoneNumber,
        userService.getKYCInfo(trip.booking.provider).mobilePhoneNumber,
        car,
        _getClaimValueInCurrency(trip.paymentInfo.currencyType, claim.amountInUsdCents, claim),
        IRentalityGeoService(carService.getGeoServiceAddress()).getCarTimeZoneId(car.locationHash),
        claimService.getClaimTypeInfo(claim.claimType),
        currencyConverter.getCurrencyInfo(trip.paymentInfo.currencyType)
      );
    }
  }

  function getHostInsuranceRule(address host) external view returns (HostInsuranceRuleDTO memory insuranceRules) {
    return hostInsurance.getHostInsuranceRule(host);
  }

  function getAllInsuranceRules() external view returns (HostInsuranceRuleDTO[] memory insuranceRules) {
    return hostInsurance.getAllInsuranceRules();
  }

  function getHostInsuranceBalance() external view returns (uint256) {
    return hostInsuranceAddress.balance;
  }

  function _getClaimValueInCurrency(
    address currency,
    uint256 amount,
    ReferralClaimInfoV2 memory claim
  ) internal view returns (uint256 valueInCurrency) {
    if (claim.status == ReferralClaimStatus.Paid) {
      (int256 rate, ) = claimService.claimIdToCurrencyRate(claim.claimId);
      if (rate > 0) {
        valueInCurrency = currencyConverter.getFromUsdCents(currency, amount, rate);
      }
    } else {
      (valueInCurrency, , ) = currencyConverter.getFromUsdCentsLatest(currency, amount);
    }
  }
}


