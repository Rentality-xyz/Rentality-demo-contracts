// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../models/car/CarTypes.sol';
import '../../models/claim/RentalClaimTypes.sol';
import '../../models/base/referral/ReferralTypes.sol';
import '../../models/pricing/RentalPricingTypes.sol';
import '../../models/profile/UserProfileTypes.sol';
import '../../models/trip/TripTypes.sol';

interface IAdminGatewayFacet {
  function getCarServiceAddress() external view returns (address);
  function getPaymentService() external view returns (address);
  function getClaimServiceAddress() external view returns (address);
  function getRentalityPlatformAddress() external view returns (address);
  function getCurrencyConverterServiceAddress() external view returns (address);
  function getTripServiceAddress() external view returns (address);
  function getUserServiceAddress() external view returns (address);
  function getDeliveryServiceAddress() external view returns (address);
  function getInvestmentAddress() external view returns (address investmentAddress);
  function updateNotificationService(address contractAddress) external;
  function withdrawFromPlatform(uint256 amount, address currencyType) external;
  function withdrawAllFromPlatform(address currencyType) external;
  function setPlatformFeeInPPM(uint32 valueInPPM) external;
  function updatePromoData(string memory prefix, uint discount) external;
  function setClaimsWaitingTime(uint timeInSec) external;
  function getClaimWaitingTime() external view returns (uint);
  function getPlatformFeeInPPM() external view returns (uint32);
  function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 value) external view returns (uint64);
  function calculateTaxes(uint taxesId, uint64 daysOfTrip, uint64 value) external view returns (uint64);
  function calculateTaxesDTO(uint taxesId, uint64 daysOfTrip, uint64 value)
    external
    view
    returns (uint64 totalTax, RentalTaxValue[] memory taxValues);
  function setPlatformFee(uint value) external;
  function payToHost(uint256 tripId) external;
  function refundToGuest(uint256 tripId) external;
  function setCivicData(address _civicVerifier, uint _civicGatekeeperNetwork) external;
  function setKycCommission(uint value) external;
  function getAllTrips(TripGatewayTypes.GatewayTripFilter memory filter, uint page, uint itemsPerPage)
    external
    view
    returns (TripGatewayTypes.GatewayAllTripsDTO memory allTrips);
  function manageRole(UserProfileRole role, address user, bool grant) external;
  function getAllCars(uint page, uint itemsPerPage) external view returns (CarGatewayTypes.AllCarsDTO memory allCars);
  function manageRefferalBonusAccrual(
    ReferralAccrualType accrualType,
    ReferralProgram program,
    int points,
    int pointsWithReffHash
  ) external;
  function manageRefferalHashPoints(ReferralProgram program, uint points) external;
  function manageRefferalDiscount(ReferralProgram program, ReferralTier tear, uint points, uint percents)
    external;
  function manageTearInfo(ReferralTier tear, uint from, uint to) external;
  function getPlatformUsersInfo(uint page, uint itemsPerPage)
    external
    view
    returns (GatewayAdminUserProfilePage memory result);
  function getAllClaimTypes(bool byHost) external view returns (RentalClaimTypeInfo[] memory claimTypes);
  function addClaimType(string memory name, RentalClaimCreator creator) external;
  function removeClaimType(uint8 claimType) external;
  function setDefaultCurrencyType(address currency) external;
  function setDefaultPrices(uint64 underTwentyFiveMilesInUsdCents, uint64 aboveTwentyFiveMilesInUsdCents) external;
  function setDefaultDiscount(RentalBaseDiscount memory newDiscounts) external;
  function addTaxes(string memory location, RentalPricingTaxesLocationType locationType, RentalTaxValue[] memory taxes)
    external;
}
