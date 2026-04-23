// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../infrastructure/geo/IRentalityGeoService.sol';
import '../base/insurance/InsuranceTypes.sol';
import '../car/CarTypes.sol';
import '../claim/RentalClaimTypes.sol';
import '../common/CommonTypes.sol';
import '../profile/UserProfileTypes.sol';
import '../trip/TripTypes.sol';
import './RentalInsuranceTypes.sol';

interface IRentalInsuranceQueryFacet2InsuranceService {
  function getMyInsurancesAsGuest(address user) external view returns (InsuranceInfo[] memory);
}

interface IRentalInsuranceQueryFacet2HostInsurance {
  function getInsuranceClaims() external view returns (uint256[] memory);
  function getHostInsuranceRule(address host) external view returns (RentalHostInsuranceRuleDTO memory);
  function getAllInsuranceRules() external view returns (RentalHostInsuranceRuleDTO[] memory);
}

interface IRentalInsuranceQueryFacet2ClaimService {
  function getClaim(uint256 claimId) external view returns (RentalClaimInfoV2 memory);
  function getClaimTypeInfo(uint8 claimType) external view returns (RentalClaimTypeInfo memory);
  function claimIdToCurrencyRate(uint256 claimId) external view returns (int256 rate, uint8 decimals);
}

interface IRentalInsuranceQueryFacet2TripQuery {
  function getTrip(uint256 tripId) external view returns (Trip memory);
}

interface IRentalInsuranceQueryFacet2UserService {
  function getKYCInfo(address user) external view returns (UserProfileKYCInfo memory);
}

interface IRentalInsuranceQueryFacet2CarService {
  function getCarInfoById(uint256 carId) external view returns (CarGatewayTypes.GatewayCarInfo memory);
  function getGeoServiceAddress() external view returns (address);
}

interface IRentalInsuranceQueryFacet2CurrencyConverter {
  function getFromUsdCents(address tokenAddress, uint256 amount, int256 currencyRate) external view returns (uint256);
  function getFromUsdCentsLatest(address tokenAddress, uint256 valueInUsdCents)
    external
    view
    returns (uint256, int256, uint8);
  function getCurrencyInfo(address currency) external view returns (UserCurrencyInfo memory);
}

contract RentalInsuranceQueryFacet2 {
  IRentalInsuranceQueryFacet2InsuranceService public immutable insuranceService;
  IRentalInsuranceQueryFacet2HostInsurance public immutable hostInsurance;
  IRentalInsuranceQueryFacet2ClaimService public immutable claimService;
  IRentalInsuranceQueryFacet2TripQuery public immutable tripQuery;
  IRentalInsuranceQueryFacet2UserService public immutable userService;
  IRentalInsuranceQueryFacet2CarService public immutable carService;
  IRentalInsuranceQueryFacet2CurrencyConverter public immutable currencyConverter;
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
    insuranceService = IRentalInsuranceQueryFacet2InsuranceService(insuranceServiceAddress);
    hostInsurance = IRentalInsuranceQueryFacet2HostInsurance(hostInsuranceContractAddress);
    claimService = IRentalInsuranceQueryFacet2ClaimService(claimServiceAddress);
    tripQuery = IRentalInsuranceQueryFacet2TripQuery(tripQueryAddress);
    userService = IRentalInsuranceQueryFacet2UserService(userServiceAddress);
    carService = IRentalInsuranceQueryFacet2CarService(carServiceAddress);
    currencyConverter = IRentalInsuranceQueryFacet2CurrencyConverter(currencyConverterAddress);
    hostInsuranceAddress = payable(hostInsuranceContractAddress);
  }

  function getGuestInsurance(address guest) external view returns (InsuranceInfo[] memory) {
    return insuranceService.getMyInsurancesAsGuest(guest);
  }

  function getHostInsuranceClaims() external view returns (FullClaimInfo[] memory claimInfos) {
    uint256[] memory claimIds = hostInsurance.getInsuranceClaims();
    claimInfos = new FullClaimInfo[](claimIds.length);

    for (uint256 i = 0; i < claimIds.length; i++) {
      RentalClaimInfoV2 memory claim = claimService.getClaim(claimIds[i]);
      Trip memory trip = tripQuery.getTrip(claim.tripId);
      CarGatewayTypes.GatewayCarInfo memory car = carService.getCarInfoById(trip.booking.resourceId);

      claimInfos[i] = FullClaimInfo(
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

  function getHostInsuranceRule(address host) external view returns (RentalHostInsuranceRuleDTO memory insuranceRules) {
    return hostInsurance.getHostInsuranceRule(host);
  }

  function getAllInsuranceRules() external view returns (RentalHostInsuranceRuleDTO[] memory insuranceRules) {
    return hostInsurance.getAllInsuranceRules();
  }

  function getHostInsuranceBalance() external view returns (uint256) {
    return hostInsuranceAddress.balance;
  }

  function _getClaimValueInCurrency(
    address currency,
    uint256 amount,
    RentalClaimInfoV2 memory claim
  ) internal view returns (uint256 valueInCurrency) {
    if (claim.status == RentalClaimStatus.Paid) {
      (int256 rate, ) = claimService.claimIdToCurrencyRate(claim.claimId);
      if (rate > 0) {
        valueInCurrency = currencyConverter.getFromUsdCents(currency, amount, rate);
      }
    } else {
      (valueInCurrency, , ) = currencyConverter.getFromUsdCentsLatest(currency, amount);
    }
  }
}


