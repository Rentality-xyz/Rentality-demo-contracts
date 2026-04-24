// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../infrastructure/upgradeable/UUPSOwnable.sol';
import '../../models/common/CommonTypes.sol';
import '../../models/pricing/PricingMain.sol';
import '../../models/pricing/PricingTypes.sol';
import '../GatewayContext.sol';
import './IPricingGatewayFacet.sol';

interface IPricingGatewayFacetAccess {
  function isRentalityPlatform(address user) external view returns (bool);
}

interface IPricingGatewayFacetNotificationService {
  function emitEvent(EventType eType, uint256 id, uint8 objectStatus, address from, address to) external;
}

contract PricingGatewayFacet is UUPSOwnable, GatewayContext, IPricingGatewayFacet {
  PricingMain public pricingMain;
  IPricingGatewayFacetAccess public userAccess;
  IPricingGatewayFacetNotificationService public notificationService;

  constructor() {
    _disableInitializers();
  }

  function initialize(address pricingMainAddress, address userAccessAddress, address notificationServiceAddress)
    public
    initializer
  {
    __Ownable_init();
    _setServiceAddresses(pricingMainAddress, userAccessAddress, notificationServiceAddress);
  }

  function updateServiceAddresses(address pricingMainAddress, address userAccessAddress, address notificationServiceAddress)
    external
    onlyOwner
  {
    _setServiceAddresses(pricingMainAddress, userAccessAddress, notificationServiceAddress);
  }

  function setPlatformFeeInPPM(uint32 valueInPPM) external {
    pricingMain.setPlatformFeeInPPM(valueInPPM);
  }

  function getPlatformFeeInPPM() external view returns (uint32) {
    return pricingMain.getPlatformFeeInPPM();
  }

  function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 value) external view returns (uint64) {
    return pricingMain.calculateSumWithDiscount(user, daysOfTrip, value);
  }

  function calculateTaxes(uint256 taxesId, uint64 daysOfTrip, uint64 value) external view returns (uint64) {
    return pricingMain.calculateTaxes(taxesId, daysOfTrip, value);
  }

  function calculateTaxesDTO(uint256 taxesId, uint64 daysOfTrip, uint64 value)
    external
    view
    returns (uint64 totalTax, PricingTaxValue[] memory taxValues)
  {
    return pricingMain.calculateTaxesDTO(taxesId, daysOfTrip, value);
  }

  function setDefaultDiscount(PricingBaseDiscount memory newDiscounts) external {
    address sender = _msgGatewaySender();
    pricingMain.setDefaultDiscount(newDiscounts);
    _emitAdminEvent(EventType.Discount, 0, sender);
  }

  function addTaxes(string memory location, PricingTaxesLocationType locationType, PricingTaxValue[] memory taxes)
    external
  {
    address sender = _msgGatewaySender();
    uint256 taxId = pricingMain.addTaxes(location, locationType, taxes);
    _emitAdminEvent(EventType.Taxes, taxId, sender);
  }

  function isTrustedForwarder(address forwarder) internal view override returns (bool) {
    return address(userAccess) != address(0) && userAccess.isRentalityPlatform(forwarder);
  }

  function _setServiceAddresses(address pricingMainAddress, address userAccessAddress, address notificationServiceAddress)
    internal
  {
    pricingMain = PricingMain(pricingMainAddress);
    userAccess = IPricingGatewayFacetAccess(userAccessAddress);
    notificationService = IPricingGatewayFacetNotificationService(notificationServiceAddress);
  }

  function _emitAdminEvent(EventType eType, uint256 id, address sender) internal {
    if (address(notificationService) == address(0)) {
      return;
    }
    notificationService.emitEvent(eType, id, uint8(EventCreator.Admin), sender, sender);
  }
}
