// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable as OZInitializable} from '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../../infrastructure/upgradeable/UUPSOwnable.sol';
import '../ARentalityContext.sol';
import '../../models/referral/ReferralTypes.sol';
import '../../models/common/CommonTypes.sol';
import '../../models/base/insurance/InsuranceTypes.sol';
import '../../models/insurance/InsuranceTypes.sol';
import '../../models/insurance/InsuranceQueryFacet1.sol';
import '../../models/insurance/InsuranceQueryFacet2.sol';
import './IInsuranceGatewayFacet.sol';

interface IInsuranceGatewayUserAccess {
  function isRentalityPlatform(address user) external view returns (bool);
}

interface IInsuranceGatewayMain {
  function saveGuestInsurance(SaveInsuranceRequest memory insuranceInfo, address user) external;
  function saveTripInsuranceInfo(uint256 tripId, SaveInsuranceRequest memory insuranceInfo, address user) external;
  function setHostInsurance(uint256 insuranceIdToUse, address user) external;
}

interface IInsuranceGatewayNotificationService {
  function emitEvent(EventType eType, uint256 id, uint8 objectStatus, address from, address to) external;
}

contract InsuranceGatewayFacet is UUPSOwnable, ARentalityContext, IInsuranceGatewayFacet {
  InsuranceQueryFacet1 public insuranceQueryFacet1;
  InsuranceQueryFacet2 public insuranceQueryFacet2;
  IInsuranceGatewayMain public insuranceMain;
  IInsuranceGatewayUserAccess public userAccess;
  IInsuranceGatewayNotificationService public notificationService;

  constructor() {
    _disableInitializers();
  }

  function initialize(
    address insuranceQueryFacet1Address,
    address insuranceQueryFacet2Address,
    address insuranceMainAddress,
    address userServiceAddress,
    address notificationServiceAddress
  ) public initializer {
    __Ownable_init();
    _setServiceAddresses(
      insuranceQueryFacet1Address,
      insuranceQueryFacet2Address,
      insuranceMainAddress,
      userServiceAddress,
      notificationServiceAddress
    );
  }

  function updateServiceAddresses(
    address insuranceQueryFacet1Address,
    address insuranceQueryFacet2Address,
    address insuranceMainAddress,
    address userServiceAddress,
    address notificationServiceAddress
  ) external onlyOwner {
    _setServiceAddresses(
      insuranceQueryFacet1Address,
      insuranceQueryFacet2Address,
      insuranceMainAddress,
      userServiceAddress,
      notificationServiceAddress
    );
  }

  function getInsurancesBy(bool host) external view returns (InsuranceDTO[] memory) {
    return insuranceQueryFacet1.getInsurancesBy(host, _msgGatewaySender());
  }

  function getMyInsurancesAsGuest() external view returns (InsuranceInfo[] memory) {
    return insuranceQueryFacet1.getMyInsurancesAsGuest(_msgGatewaySender());
  }

  function getGuestInsurance(address guest) external view returns (InsuranceInfo[] memory) {
    return insuranceQueryFacet2.getGuestInsurance(guest);
  }

  function getHostInsuranceClaims() external view returns (FullReferralClaimInfo[] memory claimInfos) {
    return insuranceQueryFacet2.getHostInsuranceClaims();
  }

  function getHostInsuranceRule(address host) external view returns (HostInsuranceRuleDTO memory insuranceRules) {
    return insuranceQueryFacet2.getHostInsuranceRule(host);
  }

  function getAllInsuranceRules() external view returns (HostInsuranceRuleDTO[] memory insuranceRules) {
    return insuranceQueryFacet2.getAllInsuranceRules();
  }

  function getHostInsuranceBalance() external view returns (uint) {
    return insuranceQueryFacet2.getHostInsuranceBalance();
  }

  function saveGuestInsurance(SaveInsuranceRequest memory insuranceInfo) external {
    address sender = _msgGatewaySender();
    insuranceMain.saveGuestInsurance(insuranceInfo, sender);
    notificationService.emitEvent(EventType.Insurance, 0, uint8(insuranceInfo.insuranceType), sender, sender);
  }

  function saveTripInsuranceInfo(uint tripId, SaveInsuranceRequest memory insuranceInfo) external {
    address sender = _msgGatewaySender();
    insuranceMain.saveTripInsuranceInfo(tripId, insuranceInfo, sender);
    notificationService.emitEvent(EventType.SaveTripInsurance, tripId, 0, sender, sender);
  }

  function setHostInsurance(uint insuranceId) external {
    insuranceMain.setHostInsurance(insuranceId, _msgGatewaySender());
  }

  function isTrustedForwarder(address forwarder) internal view override returns (bool) {
    return address(userAccess) != address(0) && userAccess.isRentalityPlatform(forwarder);
  }

  function _setServiceAddresses(
    address insuranceQueryFacet1Address,
    address insuranceQueryFacet2Address,
    address insuranceMainAddress,
    address userServiceAddress,
    address notificationServiceAddress
  ) internal {
    insuranceQueryFacet1 = InsuranceQueryFacet1(insuranceQueryFacet1Address);
    insuranceQueryFacet2 = InsuranceQueryFacet2(insuranceQueryFacet2Address);
    insuranceMain = IInsuranceGatewayMain(insuranceMainAddress);
    userAccess = IInsuranceGatewayUserAccess(userServiceAddress);
    notificationService = IInsuranceGatewayNotificationService(notificationServiceAddress);
  }
}
