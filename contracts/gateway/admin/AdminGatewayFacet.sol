// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {UUPSOwnable as GatewayUUPSOwnable} from '../../infrastructure/upgradeable/UUPSOwnable.sol';
import '../ARentalityContext.sol';
import '../../models/base/referral/ReferralTypes.sol';
import '../../models/car/CarTypes.sol';
import '../../models/claim/RentalClaimTypes.sol';
import '../../models/common/CommonTypes.sol';
import '../../models/pricing/RentalPricingTypes.sol';
import '../../models/profile/UserProfileTypes.sol';
import '../../models/trip/TripTypes.sol';
import '../car/CarMapper.sol';
import '../profile/ProfileMapper.sol';
import './IAdminGatewayFacet.sol';

interface IAdminGatewayTripQuery {
  function getAllTrips(TripGatewayTypes.GatewayTripFilter memory filter, uint256 page, uint256 itemsPerPage)
    external
    view
    returns (TripGatewayTypes.GatewayAllTripsDTO memory);
}

interface IAdminGatewayCarQueryFacet2 {
  function getAllCarsForAdmin(
    address userProfileQueryAddress,
    address geoServiceAddress,
    address dimoServiceAddress,
    uint256 page,
    uint256 itemsPerPage
  ) external view returns (AllCarsInfo memory);
}

interface IAdminGatewayUserAccess {
  function isAdmin(address user) external view returns (bool);
  function isRentalityPlatform(address user) external view returns (bool);
  function setCivicData(address verifier, uint256 gatekeeperNetwork) external;
  function setKycCommission(uint256 newCommission) external;
  function manageRole(UserProfileRole newRole, address user, bool grant) external;
}

interface IAdminGatewayUserProfileQuery {
  function getPlatformUsersKYCInfos(uint256 page, uint256 itemsPerPage)
    external
    view
    returns (AdminUserProfilePage memory);
}

interface IAdminGatewayClaimService {
  function setWaitingTime(uint256 timeInSec) external;
  function getWaitingTime() external view returns (uint256);
  function setPlatformFee(uint256 value) external;
  function getClaimTypesForHost() external view returns (RentalClaimTypeInfo[] memory);
  function getClaimTypesForGuest() external view returns (RentalClaimTypeInfo[] memory);
  function addClaimType(string memory name, RentalClaimCreator creator) external returns (uint256);
  function removeClaimType(uint8 claimType) external;
}

interface IAdminGatewayPaymentService {
  function withdrawFromPlatform(uint256 amount, address tokenAddress) external;
}

interface IAdminGatewayPricingService {
  function setPlatformFeeInPPM(uint32 valueInPPM) external;
  function getPlatformFeeInPPM() external view returns (uint32);
  function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 value) external view returns (uint64);
  function calculateTaxes(uint256 taxesId, uint64 daysOfTrip, uint64 value) external view returns (uint64);
  function calculateTaxesDTO(uint256 taxesId, uint64 daysOfTrip, uint64 value)
    external
    view
    returns (uint64 totalTax, RentalTaxValue[] memory taxValues);
  function setDefaultDiscount(RentalBaseDiscount memory data) external;
  function addTaxes(
    string memory location,
    RentalPricingTaxesLocationType locationType,
    RentalTaxValue[] memory taxes
  ) external returns (uint256);
}

interface IAdminGatewayCurrencyConverter {
  function isETH(address tokenAddress) external view returns (bool);
  function setDefaultCurrencyType(address currency) external;
}

interface IAdminGatewayDeliveryService {
  function setDefaultPrices(uint64 underTwentyFiveMilesInUsdCents, uint64 aboveTwentyFiveMilesInUsdCents) external;
}

interface IAdminGatewayPromoService {
  function addPrefix(string memory prefix, uint256 discount) external;
}

interface IAdminGatewayReferralProgram {
  function addOneTimeProgram(ReferralProgram program, int256 points, int256 pointsWithReffHash, bytes4 selector) external;
  function addPermanentProgram(ReferralProgram program, int256 points, bytes4 selector) external;
  function manageReferralHashProgram(ReferralProgram program, uint256 points) external;
  function manageReferralDiscount(ReferralProgram program, ReferralTier tier, uint256 points, uint256 percents) external;
  function manageTierInfo(ReferralTier tier, uint256 from, uint256 to) external;
}

interface IAdminGatewayNotificationService {
  function emitEvent(EventType eType, uint256 id, uint8 objectStatus, address from, address to) external;
}

interface IAdminGatewayERC20 {
  function balanceOf(address account) external view returns (uint256);
}

struct AdminCoreAddresses {
  address carServiceAddress;
  address currencyConverterServiceAddress;
  address userServiceAddress;
  address paymentServiceAddress;
  address pricingServiceAddress;
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
  address private carService;
  IAdminGatewayCurrencyConverter private currencyConverterService;
  IAdminGatewayUserAccess private userService;
  IAdminGatewayPaymentService private paymentService;
  IAdminGatewayPricingService private pricingService;
  IAdminGatewayClaimService private claimService;
  IAdminGatewayDeliveryService private deliveryService;
  address private viewService;
  address private insuranceService;
  IAdminGatewayReferralProgram private refferalProgram;
  IAdminGatewayPromoService private promoService;
  address private dimoService;
  address private investment;
  IAdminGatewayNotificationService private notificationService;
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
    return carService;
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
    notificationService = IAdminGatewayNotificationService(contractAddress);
  }

  function withdrawFromPlatform(uint256 amount, address tokenAddress) public {
    paymentService.withdrawFromPlatform(amount, tokenAddress);
  }

  function withdrawAllFromPlatform(address tokenAddress) public {
    uint balance = currencyConverterService.isETH(tokenAddress)
      ? address(paymentService).balance
      : IAdminGatewayERC20(tokenAddress).balanceOf(address(paymentService));

    paymentService.withdrawFromPlatform(balance, tokenAddress);
  }

  function setPlatformFeeInPPM(uint32 valueInPPM) public onlyAdmin {
    pricingService.setPlatformFeeInPPM(valueInPPM);
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
    return pricingService.getPlatformFeeInPPM();
  }

  function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 value) public view returns (uint64) {
    return pricingService.calculateSumWithDiscount(user, daysOfTrip, value);
  }

  function calculateTaxes(uint taxesId, uint64 daysOfTrip, uint64 value) public view returns (uint64) {
    return pricingService.calculateTaxes(taxesId, daysOfTrip, value);
  }

  function calculateTaxesDTO(uint taxesId, uint64 daysOfTrip, uint64 value)
    public
    view
    returns (uint64 totalTax, RentalTaxValue[] memory taxValues)
  {
    return pricingService.calculateTaxesDTO(taxesId, daysOfTrip, value);
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

  function getAllTrips(TripGatewayTypes.GatewayTripFilter memory filter, uint page, uint itemsPerPage)
    public
    view
    returns (TripGatewayTypes.GatewayAllTripsDTO memory)
  {
    return tripQuery.getAllTrips(filter, page, itemsPerPage);
  }

  function manageRole(UserProfileRole role, address user, bool grant) public {
    userService.manageRole(role, user, grant);
  }

  function getAllCars(uint page, uint itemsPerPage) public view returns (CarGatewayTypes.AllCarsDTO memory allCars) {
    return CarMapper.toLegacyAllCarsInfo(
      carQueryFacet2.getAllCarsForAdmin(userProfileQueryAddress, geoService, dimoService, page, itemsPerPage)
    );
  }

  function manageRefferalBonusAccrual(
    ReferralAccrualType accrualType,
    ReferralProgram program,
    int points,
    int pointsWithReffHash
  ) public {
    require(userService.isAdmin(_msgGatewaySender()), 'only Admin');
    if (ReferralAccrualType.OneTime == accrualType) {
      refferalProgram.addOneTimeProgram(program, points, pointsWithReffHash, bytes4(''));
    } else {
      refferalProgram.addPermanentProgram(program, points, bytes4(''));
    }
  }

  function manageRefferalHashPoints(ReferralProgram program, uint points) public {
    require(userService.isAdmin(_msgGatewaySender()), 'only Admin');
    refferalProgram.manageReferralHashProgram(program, points);
  }

  function manageRefferalDiscount(ReferralProgram program, ReferralTier tear, uint points, uint percents) public {
    require(userService.isAdmin(_msgGatewaySender()), 'only Admin');
    refferalProgram.manageReferralDiscount(program, tear, points, percents);
  }

  function manageTearInfo(ReferralTier tear, uint from, uint to) public {
    require(userService.isAdmin(_msgGatewaySender()), 'only Admin');
    refferalProgram.manageTierInfo(tear, from, to);
  }

  function getPlatformUsersInfo(uint page, uint itemsPerPage)
    public
    view
    returns (GatewayAdminUserProfilePage memory)
  {
    return ProfileMapper.toLegacyAdminPage(userProfileQuery.getPlatformUsersKYCInfos(page, itemsPerPage));
  }

  function getAllClaimTypes(bool byHost) public view returns (RentalClaimTypeInfo[] memory) {
    return byHost ? claimService.getClaimTypesForHost() : claimService.getClaimTypesForGuest();
  }

  function addClaimType(string memory name, RentalClaimCreator creator) public {
    address sender = _msgGatewaySender();
    uint claimTypeId = claimService.addClaimType(name, creator);
    notificationService.emitEvent(EventType.AddClaimType, claimTypeId, uint8(EventCreator.Admin), sender, sender);
  }

  function removeClaimType(uint8 claimType) public {
    claimService.removeClaimType(claimType);
  }

  function setDefaultCurrencyType(address currency) public {
    address sender = _msgGatewaySender();
    currencyConverterService.setDefaultCurrencyType(currency);
    notificationService.emitEvent(EventType.Currency, 0, uint8(EventCreator.Admin), sender, sender);
  }

  function setDefaultPrices(uint64 underTwentyFiveMilesInUsdCents, uint64 aboveTwentyFiveMilesInUsdCents) public {
    address sender = _msgGatewaySender();
    deliveryService.setDefaultPrices(underTwentyFiveMilesInUsdCents, aboveTwentyFiveMilesInUsdCents);
    notificationService.emitEvent(EventType.Delivery, 0, uint8(EventCreator.Admin), sender, sender);
  }

  function setDefaultDiscount(RentalBaseDiscount memory newDiscounts) public {
    address sender = _msgGatewaySender();
    pricingService.setDefaultDiscount(newDiscounts);
    notificationService.emitEvent(EventType.Discount, 0, uint8(EventCreator.Admin), sender, sender);
  }

  function addTaxes(string memory location, RentalPricingTaxesLocationType locationType, RentalTaxValue[] memory taxes) public {
    address sender = _msgGatewaySender();
    uint taxId = pricingService.addTaxes(location, locationType, taxes);
    notificationService.emitEvent(EventType.Taxes, taxId, uint8(locationType), sender, sender);
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
    carService = coreAddresses.carServiceAddress;
    currencyConverterService = IAdminGatewayCurrencyConverter(coreAddresses.currencyConverterServiceAddress);
    userService = IAdminGatewayUserAccess(coreAddresses.userServiceAddress);
    paymentService = IAdminGatewayPaymentService(coreAddresses.paymentServiceAddress);
    pricingService = IAdminGatewayPricingService(coreAddresses.pricingServiceAddress);
    claimService = IAdminGatewayClaimService(coreAddresses.claimServiceAddress);
    deliveryService = IAdminGatewayDeliveryService(coreAddresses.carDeliveryAddress);
    viewService = coreAddresses.viewServiceAddress;
  }

  function _setFeatureServiceAddresses(AdminFeatureAddresses memory featureAddresses) internal {
    promoService = IAdminGatewayPromoService(featureAddresses.promoServiceAddress);
    dimoService = featureAddresses.dimoServiceAddress;
    refferalProgram = IAdminGatewayReferralProgram(featureAddresses.refferalProgramAddress);
    insuranceService = featureAddresses.insuranceServiceAddress;
    investment = featureAddresses.investmentAddress;
    notificationService = IAdminGatewayNotificationService(featureAddresses.notificationServiceAddress);
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
