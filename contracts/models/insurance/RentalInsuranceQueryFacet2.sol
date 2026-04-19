// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../rentality_old/Schemas.sol';
import '../../rentality_old/abstract/IRentalityGeoService.sol';

interface IRentalInsuranceQueryFacet2InsuranceService {
  function getMyInsurancesAsGuest(address user) external view returns (Schemas.InsuranceInfo[] memory);
}

interface IRentalInsuranceQueryFacet2HostInsurance {
  function getInsuranceClaims() external view returns (uint256[] memory);
  function getHostInsuranceRule(address host) external view returns (Schemas.HostInsuranceRuleDTO memory);
  function getAllInsuranceRules() external view returns (Schemas.HostInsuranceRuleDTO[] memory);
}

interface IRentalInsuranceQueryFacet2ClaimService {
  function getClaim(uint256 claimId) external view returns (Schemas.ClaimV2 memory);
  function getClaimTypeInfo(uint8 claimType) external view returns (Schemas.ClaimTypeV2 memory);
  function claimIdToCurrencyRate(uint256 claimId) external view returns (int256 rate, uint8 decimals);
}

interface IRentalInsuranceQueryFacet2TripService {
  function getTrip(uint256 tripId) external view returns (Schemas.Trip memory);
}

interface IRentalInsuranceQueryFacet2UserService {
  function getKYCInfo(address user) external view returns (Schemas.KYCInfo memory);
}

interface IRentalInsuranceQueryFacet2CarService {
  function getCarInfoById(uint256 carId) external view returns (Schemas.CarInfo memory);
  function getGeoServiceAddress() external view returns (address);
}

interface IRentalInsuranceQueryFacet2CurrencyConverter {
  function getFromUsdCents(address tokenAddress, uint256 amount, int256 currencyRate) external view returns (uint256);
  function getFromUsdCentsLatest(address tokenAddress, uint256 valueInUsdCents)
    external
    view
    returns (uint256, int256, uint8);
  function getCurrencyInfo(address currency) external view returns (Schemas.UserCurrencyDTO memory);
}

contract RentalInsuranceQueryFacet2 {
  IRentalInsuranceQueryFacet2InsuranceService public immutable insuranceService;
  IRentalInsuranceQueryFacet2HostInsurance public immutable hostInsurance;
  IRentalInsuranceQueryFacet2ClaimService public immutable claimService;
  IRentalInsuranceQueryFacet2TripService public immutable tripService;
  IRentalInsuranceQueryFacet2UserService public immutable userService;
  IRentalInsuranceQueryFacet2CarService public immutable carService;
  IRentalInsuranceQueryFacet2CurrencyConverter public immutable currencyConverter;
  address payable public immutable hostInsuranceAddress;

  constructor(
    address insuranceServiceAddress,
    address hostInsuranceContractAddress,
    address claimServiceAddress,
    address tripServiceAddress,
    address userServiceAddress,
    address carServiceAddress,
    address currencyConverterAddress
  ) {
    insuranceService = IRentalInsuranceQueryFacet2InsuranceService(insuranceServiceAddress);
    hostInsurance = IRentalInsuranceQueryFacet2HostInsurance(hostInsuranceContractAddress);
    claimService = IRentalInsuranceQueryFacet2ClaimService(claimServiceAddress);
    tripService = IRentalInsuranceQueryFacet2TripService(tripServiceAddress);
    userService = IRentalInsuranceQueryFacet2UserService(userServiceAddress);
    carService = IRentalInsuranceQueryFacet2CarService(carServiceAddress);
    currencyConverter = IRentalInsuranceQueryFacet2CurrencyConverter(currencyConverterAddress);
    hostInsuranceAddress = payable(hostInsuranceContractAddress);
  }

  function getGuestInsurance(address guest) external view returns (Schemas.InsuranceInfo[] memory) {
    return insuranceService.getMyInsurancesAsGuest(guest);
  }

  function getHostInsuranceClaims() external view returns (Schemas.FullClaimInfo[] memory claimInfos) {
    uint256[] memory claimIds = hostInsurance.getInsuranceClaims();
    claimInfos = new Schemas.FullClaimInfo[](claimIds.length);

    for (uint256 i = 0; i < claimIds.length; i++) {
      Schemas.ClaimV2 memory claim = claimService.getClaim(claimIds[i]);
      Schemas.Trip memory trip = tripService.getTrip(claim.tripId);
      Schemas.CarInfo memory car = carService.getCarInfoById(trip.carId);

      claimInfos[i] = Schemas.FullClaimInfo(
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
  }

  function getHostInsuranceRule(address host) external view returns (Schemas.HostInsuranceRuleDTO memory insuranceRules) {
    return hostInsurance.getHostInsuranceRule(host);
  }

  function getAllInsuranceRules() external view returns (Schemas.HostInsuranceRuleDTO[] memory insuranceRules) {
    return hostInsurance.getAllInsuranceRules();
  }

  function getHostInsuranceBalance() external view returns (uint256) {
    return hostInsuranceAddress.balance;
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

