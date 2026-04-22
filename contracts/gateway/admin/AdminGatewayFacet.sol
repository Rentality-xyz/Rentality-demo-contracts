// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {UUPSOwnable as GatewayUUPSOwnable} from '../../infrastructure/upgradeable/UUPSOwnable.sol';
import '../ARentalityContext.sol';
import '../../rentality_old/adapter/ICarGateway.sol';
import '../../rentality_old/abstract/IRentalityAdminGateway.sol';
import '../../rentality_old/features/RentalityCarDelivery.sol';
import '../../rentality_old/features/RentalityClaimService.sol';
import '../../rentality_old/features/RentalityDimoService.sol';
import '../../rentality_old/features/RentalityNotificationService.sol';
import '../../rentality_old/features/RentalityPromo.sol';
import '../../rentality_old/features/refferalProgram/RentalityReferralProgram.sol';
import '../../rentality_old/investment/RentalityInvestment.sol';
import '../../rentality_old/payments/RentalityCurrencyConverter.sol';
import '../../rentality_old/payments/RentalityInsurance.sol';
import '../../rentality_old/payments/RentalityPaymentService.sol';
import '../../rentality_old/payments/abstract/IERC20.sol';
import '../../models/common/Schemas.sol';
import './IAdminGatewayFacet.sol';

interface IAdminGatewayTripQuery {
  function getAllTrips(Schemas.TripFilter memory filter, uint256 page, uint256 itemsPerPage)
    external
    view
    returns (Schemas.AllTripsDTO memory);
}

interface IAdminGatewayCarQueryFacet2 {
  function getAllCarsForAdmin(
    address userProfileQueryAddress,
    address geoServiceAddress,
    address dimoServiceAddress,
    uint256 page,
    uint256 itemsPerPage
  ) external view returns (Schemas.AllCarsDTO memory);
}

interface IAdminGatewayUserAccess {
  function isAdmin(address user) external view returns (bool);
  function isRentalityPlatform(address user) external view returns (bool);
  function setCivicData(address verifier, uint256 gatekeeperNetwork) external;
  function setKycCommission(uint256 newCommission) external;
  function manageRole(Schemas.Role newRole, address user, bool grant) external;
}

interface IAdminGatewayUserProfileQuery {
  function getPlatformUsersKYCInfos(uint256 page, uint256 itemsPerPage)
    external
    view
    returns (Schemas.AdminKYCInfosDTO memory);
}

struct AdminCoreAddresses {
  address carServiceAddress;
  address currencyConverterServiceAddress;
  address userServiceAddress;
  address paymentServiceAddress;
  address claimServiceAddress;
  address carDeliveryAddress;
  address viewServiceAddress;
}

struct AdminFeatureAddresses {
  address insuranceServiceAddress;
  address refferalProgramAddress;
  address promoServiceAddress;
  address dimoServiceAddress;
  address investmentAddress;
  address notificationServiceAddress;
}

struct AdminQueryAddresses {
  address tripGatewayFacetAddress;
  address tripQueryAddress;
  address carQueryFacet2Address;
  address userProfileQueryAddress;
  address geoServiceAddress;
}

/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract AdminGatewayFacet is GatewayUUPSOwnable, ARentalityContext, IAdminGatewayFacet {
  ICarGateway private carService;
  RentalityCurrencyConverter private currencyConverterService;
  IAdminGatewayUserAccess private userService;
  IRentalityAdminGateway private adminService;
  RentalityPaymentService private paymentService;
  RentalityClaimService private claimService;
  RentalityCarDelivery private deliveryService;
  address private viewService;
  RentalityInsurance private insuranceService;
  RentalityReferralProgram private refferalProgram;
  RentalityPromoService private promoService;
  RentalityDimoService private dimoService;
  RentalityInvestment private investment;
  RentalityNotificationService private notificationService;
  address private tripGatewayFacet;
  IAdminGatewayTripQuery private tripQuery;
  IAdminGatewayCarQueryFacet2 private carQueryFacet2;
  IAdminGatewayUserProfileQuery private userProfileQuery;
  address private userProfileQueryAddress;
  address private geoService;

  constructor() {
    _disableInitializers();
  }

  modifier onlyAdmin() {
    address sender = _msgGatewaySender();
    require(userService.isAdmin(sender) || userService.isAdmin(tx.origin) || tx.origin == owner(), 'User is not an admin');
    _;
  }

  function initialize(
    AdminCoreAddresses memory coreAddresses,
    AdminFeatureAddresses memory featureAddresses,
    AdminQueryAddresses memory queryAddresses
  ) public initializer {
    __Ownable_init();
    _setCoreServiceAddresses(coreAddresses);
    _setFeatureServiceAddresses(featureAddresses);
    _setQueryServiceAddresses(queryAddresses);
  }

  function updateServiceAddresses(
    AdminCoreAddresses memory coreAddresses,
    AdminFeatureAddresses memory featureAddresses,
    AdminQueryAddresses memory queryAddresses
  ) external onlyOwner {
    _setCoreServiceAddresses(coreAddresses);
    _setFeatureServiceAddresses(featureAddresses);
    _setQueryServiceAddresses(queryAddresses);
  }

  function getCarServiceAddress() public view returns (address) {
    return address(carService);
  }

  function getPaymentService() public view returns (address) {
    return address(paymentService);
  }

  function getClaimServiceAddress() public view returns (address) {
    return address(claimService);
  }

  function getRentalityPlatformAddress() public pure returns (address) {
    return address(0);
  }

  function getCurrencyConverterServiceAddress() public view returns (address) {
    return address(currencyConverterService);
  }

  function getTripServiceAddress() public view returns (address) {
    return address(tripQuery);
  }

  function getUserServiceAddress() public view returns (address) {
    return address(userService);
  }

  function getDeliveryServiceAddress() public view returns (address) {
    return address(deliveryService);
  }

  function getInvestmentAddress() public view returns (address) {
    return address(investment);
  }

  function updateNotificationService(address contractAddress) public onlyAdmin {
    notificationService = RentalityNotificationService(contractAddress);
  }

  function withdrawFromPlatform(uint256 amount, address tokenAddress) public {
    paymentService.withdrawFromPlatform(amount, tokenAddress);
  }

  function withdrawAllFromPlatform(address tokenAddress) public {
    uint balance = currencyConverterService.isETH(tokenAddress)
      ? address(paymentService).balance
      : IERC20(tokenAddress).balanceOf(address(paymentService));

    paymentService.withdrawFromPlatform(balance, tokenAddress);
  }

  function setPlatformFeeInPPM(uint32 valueInPPM) public onlyAdmin {
    paymentService.setPlatformFeeInPPM(valueInPPM);
  }

  function updatePromoData(string memory prefix, uint discount) public {
    promoService.addPrefix(prefix, discount);
  }

  function setClaimsWaitingTime(uint timeInSec) public {
    claimService.setWaitingTime(timeInSec);
  }

  function getClaimWaitingTime() public view returns (uint) {
    return claimService.getWaitingTime();
  }

  function getPlatformFeeInPPM() public view returns (uint32) {
    return paymentService.getPlatformFeeInPPM();
  }

  function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 value) public view returns (uint64) {
    return paymentService.calculateSumWithDiscount(user, daysOfTrip, value);
  }

  function calculateTaxes(uint taxesId, uint64 daysOfTrip, uint64 value) public view returns (uint64) {
    return paymentService.calculateTaxes(taxesId, daysOfTrip, value);
  }

  function calculateTaxesDTO(uint taxesId, uint64 daysOfTrip, uint64 value)
    public
    view
    returns (uint64 totalTax, Schemas.TaxValue[] memory taxValues)
  {
    return paymentService.calculateTaxesDTO(taxesId, daysOfTrip, value);
  }

  function payToHost(uint256 tripId) public {
    _callTripFacetWithForwarding(abi.encodeWithSignature('confirmCheckOut(uint256)', tripId));
  }

  function refundToGuest(uint256 tripId) public {
    _callTripFacetWithForwarding(abi.encodeWithSignature('rejectTripRequest(uint256)', tripId));
  }

  function setCivicData(address _civicVerifier, uint _civicGatekeeperNetwork) public {
    userService.setCivicData(_civicVerifier, _civicGatekeeperNetwork);
  }

  function setPlatformFee(uint value) public {
    claimService.setPlatformFee(value);
  }

  function setKycCommission(uint value) public {
    userService.setKycCommission(value);
  }

  function getAllTrips(Schemas.TripFilter memory filter, uint page, uint itemsPerPage)
    public
    view
    returns (Schemas.AllTripsDTO memory)
  {
    return tripQuery.getAllTrips(filter, page, itemsPerPage);
  }

  function manageRole(Schemas.Role role, address user, bool grant) public {
    userService.manageRole(role, user, grant);
  }

  function getAllCars(uint page, uint itemsPerPage) public view returns (Schemas.AllCarsDTO memory allCars) {
    return carQueryFacet2.getAllCarsForAdmin(userProfileQueryAddress, geoService, address(dimoService), page, itemsPerPage);
  }

  function manageRefferalBonusAccrual(
    Schemas.RefferalAccrualType accrualType,
    Schemas.RefferalProgram program,
    int points,
    int pointsWithReffHash
  ) public {
    require(userService.isAdmin(_msgGatewaySender()), 'only Admin');
    if (Schemas.RefferalAccrualType.OneTime == accrualType) {
      refferalProgram.addOneTimeProgram(program, points, pointsWithReffHash, bytes4(''));
    } else {
      refferalProgram.addPermanentProgram(program, points, bytes4(''));
    }
  }

  function manageRefferalHashPoints(Schemas.RefferalProgram program, uint points) public {
    require(userService.isAdmin(_msgGatewaySender()), 'only Admin');
    refferalProgram.manageRefHashesProgram(program, points);
  }

  function manageRefferalDiscount(Schemas.RefferalProgram program, Schemas.Tear tear, uint points, uint percents) public {
    require(userService.isAdmin(_msgGatewaySender()), 'only Admin');
    refferalProgram.manageRefferalDiscount(program, tear, points, percents);
  }

  function manageTearInfo(Schemas.Tear tear, uint from, uint to) public {
    require(userService.isAdmin(_msgGatewaySender()), 'only Admin');
    refferalProgram.manageTearInfo(tear, from, to);
  }

  function getPlatformUsersInfo(uint page, uint itemsPerPage)
    public
    view
    returns (Schemas.AdminKYCInfosDTO memory)
  {
    return userProfileQuery.getPlatformUsersKYCInfos(page, itemsPerPage);
  }

  function getAllClaimTypes(bool byHost) public view returns (Schemas.ClaimTypeV2[] memory) {
    return byHost ? claimService.getClaimTypesForHost() : claimService.getClaimTypesForGuest();
  }

  function addClaimType(string memory name, Schemas.ClaimCreator creator) public {
    address sender = _msgGatewaySender();
    uint claimTypeId = claimService.addClaimType(name, creator);
    notificationService.emitEvent(Schemas.EventType.AddClaimType, claimTypeId, uint8(Schemas.EventCreator.Admin), sender, sender);
  }

  function removeClaimType(uint8 claimType) public {
    claimService.removeClaimType(claimType);
  }

  function setDefaultCurrencyType(address currency) public {
    address sender = _msgGatewaySender();
    currencyConverterService.setDefaultCurrencyType(currency);
    notificationService.emitEvent(Schemas.EventType.Currency, 0, uint8(Schemas.EventCreator.Admin), sender, sender);
  }

  function setDefaultPrices(uint64 underTwentyFiveMilesInUsdCents, uint64 aboveTwentyFiveMilesInUsdCents) public {
    address sender = _msgGatewaySender();
    deliveryService.setDefaultPrices(underTwentyFiveMilesInUsdCents, aboveTwentyFiveMilesInUsdCents);
    notificationService.emitEvent(Schemas.EventType.Delivery, 0, uint8(Schemas.EventCreator.Admin), sender, sender);
  }

  function setDefaultDiscount(Schemas.BaseDiscount memory newDiscounts) public {
    address sender = _msgGatewaySender();
    paymentService.setDefaultDiscount(newDiscounts);
    notificationService.emitEvent(Schemas.EventType.Discount, 0, uint8(Schemas.EventCreator.Admin), sender, sender);
  }

  function addTaxes(string memory location, Schemas.TaxesLocationType locationType, Schemas.TaxValue[] memory taxes) public {
    address sender = _msgGatewaySender();
    uint taxId = paymentService.addTaxes(location, locationType, taxes);
    notificationService.emitEvent(Schemas.EventType.Taxes, taxId, uint8(locationType), sender, sender);
  }

  function isTrustedForwarder(address forwarder) internal view override returns (bool) {
    return address(userService) != address(0) && userService.isRentalityPlatform(forwarder);
  }

  function _callTripFacetWithForwarding(bytes memory data) private returns (bytes memory) {
    require(tripGatewayFacet != address(0), 'AdminGatewayFacet: trip facet is not set');
    bytes memory dataToSend = abi.encodePacked(data, _msgGatewaySender());
    (bool ok, bytes memory res) = tripGatewayFacet.call{value: 0}(dataToSend);
    return _parseResult(ok, res);
  }

  function _parseResult(bool flag, bytes memory result) internal pure returns (bytes memory) {
    if (!flag)
      assembly ('memory-safe') {
        revert(add(32, result), mload(result))
      }
    return result;
  }

  function _setCoreServiceAddresses(AdminCoreAddresses memory coreAddresses) internal {
    carService = ICarGateway(coreAddresses.carServiceAddress);
    currencyConverterService = RentalityCurrencyConverter(coreAddresses.currencyConverterServiceAddress);
    userService = IAdminGatewayUserAccess(coreAddresses.userServiceAddress);
    adminService = IRentalityAdminGateway(address(this));
    paymentService = RentalityPaymentService(payable(coreAddresses.paymentServiceAddress));
    claimService = RentalityClaimService(coreAddresses.claimServiceAddress);
    deliveryService = RentalityCarDelivery(coreAddresses.carDeliveryAddress);
    viewService = coreAddresses.viewServiceAddress;
  }

  function _setFeatureServiceAddresses(AdminFeatureAddresses memory featureAddresses) internal {
    promoService = RentalityPromoService(featureAddresses.promoServiceAddress);
    dimoService = RentalityDimoService(featureAddresses.dimoServiceAddress);
    refferalProgram = RentalityReferralProgram(featureAddresses.refferalProgramAddress);
    insuranceService = RentalityInsurance(featureAddresses.insuranceServiceAddress);
    investment = RentalityInvestment(featureAddresses.investmentAddress);
    notificationService = RentalityNotificationService(featureAddresses.notificationServiceAddress);
  }

  function _setQueryServiceAddresses(AdminQueryAddresses memory queryAddresses) internal {
    tripGatewayFacet = queryAddresses.tripGatewayFacetAddress;
    tripQuery = IAdminGatewayTripQuery(queryAddresses.tripQueryAddress);
    carQueryFacet2 = IAdminGatewayCarQueryFacet2(queryAddresses.carQueryFacet2Address);
    userProfileQuery = IAdminGatewayUserProfileQuery(queryAddresses.userProfileQueryAddress);
    userProfileQueryAddress = queryAddresses.userProfileQueryAddress;
    geoService = queryAddresses.geoServiceAddress;
  }
}
