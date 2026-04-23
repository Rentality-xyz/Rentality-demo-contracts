// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../infrastructure/upgradeable/UUPSOwnable.sol';
import '../insurance/InsuranceTypes.sol';
import '../trip/TripLib.sol';
import '../trip/TripTypes.sol';
import './ReferralTypes.sol';

interface IReferralMainFacet1Access {
  function isRentalityPlatform(address user) external view returns (bool);
  function isAdmin(address user) external view returns (bool);
}

interface IReferralMainFacet1TripQuery {
  function getTrip(uint256 tripId) external view returns (Trip memory);
}

interface IReferralMainFacet1CurrencyConverter {
  function calculateLatestValueWithFee(address currencyType, uint256 valueInUsdCents, uint256 feeInUsdCents)
    external
    view
    returns (uint256 valueToPay, uint256 feeInCurrency, int256 rate, uint8 decimals);
}

interface IReferralMainFacet1PaymentService {
  function payClaim(
    TripGatewayTypes.GatewayTrip memory trip,
    uint256 valueToPay,
    uint256 feeInCurrency,
    uint256 commission,
    address user
  ) external payable;
}

interface IReferralMainFacet1InsuranceMain {
  function createInsuranceClaim(uint256 claimId, address sender) external;
  function isInsuranceClaim(uint256 claimId) external view returns (bool);
  function payHostInsuranceClaim(uint256 amountToPay, HostInsurancePayoutContext memory context) external payable;
}

interface IReferralMainFacet1NotificationService {
  function emitEvent(EventType eType, uint256 id, uint8 objectStatus, address from, address to) external;
}

contract ReferralMainFacet1 is UUPSOwnable {
  IReferralMainFacet1Access public userAccess;
  IReferralMainFacet1NotificationService public notificationService;
  IReferralMainFacet1TripQuery public tripQuery;
  IReferralMainFacet1CurrencyConverter public currencyConverter;
  IReferralMainFacet1PaymentService public paymentService;
  IReferralMainFacet1InsuranceMain public insuranceMain;
  uint256 private waitingTimeForApproveInSec;
  uint256 private claimCounter;
  uint256 private platformFeeInPPM;
  uint8 private claimTypeNumber;
  mapping(uint256 => ReferralClaimInfoV2) private claimIdToClaim;
  mapping(uint256 => CurrencyRate) public claimIdToCurrencyRate;
  mapping(uint8 => ReferralClaimTypeInfo) private claimTypeNumberToClaimType;

  event WaitingTimeChanged(uint256 newWaitingTime);

  constructor() {
    _disableInitializers();
  }

  modifier onlyPlatform() {
    require(userAccess.isRentalityPlatform(msg.sender), 'only Rentality platform.');
    _;
  }

  function initialize(
    address userAccessAddress,
    address notificationServiceAddress,
    address tripQueryAddress,
    address currencyConverterAddress,
    address paymentServiceAddress,
    address insuranceMainAddress
  ) public initializer {
    __Ownable_init();
    userAccess = IReferralMainFacet1Access(userAccessAddress);
    notificationService = IReferralMainFacet1NotificationService(notificationServiceAddress);
    tripQuery = IReferralMainFacet1TripQuery(tripQueryAddress);
    currencyConverter = IReferralMainFacet1CurrencyConverter(currencyConverterAddress);
    paymentService = IReferralMainFacet1PaymentService(paymentServiceAddress);
    insuranceMain = IReferralMainFacet1InsuranceMain(insuranceMainAddress);
    waitingTimeForApproveInSec = 259_200;
    _seedDefaultClaimTypes();
  }

  function updateServiceAddresses(
    address userAccessAddress,
    address notificationServiceAddress,
    address tripQueryAddress,
    address currencyConverterAddress,
    address paymentServiceAddress,
    address insuranceMainAddress
  ) external onlyOwner {
    userAccess = IReferralMainFacet1Access(userAccessAddress);
    notificationService = IReferralMainFacet1NotificationService(notificationServiceAddress);
    tripQuery = IReferralMainFacet1TripQuery(tripQueryAddress);
    currencyConverter = IReferralMainFacet1CurrencyConverter(currencyConverterAddress);
    paymentService = IReferralMainFacet1PaymentService(paymentServiceAddress);
    insuranceMain = IReferralMainFacet1InsuranceMain(insuranceMainAddress);
  }

  function setWaitingTime(uint256 newWaitingTimeInSec) public onlyPlatform {
    require(userAccess.isAdmin(tx.origin), 'Only admin.');
    waitingTimeForApproveInSec = newWaitingTimeInSec;
    emit WaitingTimeChanged(newWaitingTimeInSec);
  }

  function getWaitingTime() public view returns (uint256) {
    return waitingTimeForApproveInSec;
  }

  function getClaim(uint256 targetClaimId) public view returns (ReferralClaimInfoV2 memory) {
    return claimIdToClaim[targetClaimId];
  }

  function getClaimsAmount() public view returns (uint256) {
    return claimCounter;
  }

  function exists(uint256 targetClaimId) public view returns (bool) {
    return claimIdToClaim[targetClaimId].deadlineDateInSec > 0;
  }

  function getPlatformFeeFrom(uint256 value) public view returns (uint256) {
    return (value * platformFeeInPPM) / 1_000_000;
  }

  function setPlatformFee(uint256 value) public onlyPlatform {
    require(userAccess.isAdmin(tx.origin), 'Only admin.');
    platformFeeInPPM = value;
  }

  function addClaimType(string memory name, ReferralClaimCreator creator) public onlyPlatform returns (uint256) {
    require(userAccess.isAdmin(tx.origin), 'Only admin.');
    claimTypeNumber += 1;
    claimTypeNumberToClaimType[claimTypeNumber] = ReferralClaimTypeInfo(claimTypeNumber, name, creator);
    return claimTypeNumber;
  }

  function removeClaimType(uint8 claimType) public onlyPlatform {
    require(userAccess.isAdmin(tx.origin), 'Only admin');
    delete claimTypeNumberToClaimType[claimType];
  }

  function getClaimTypesForGuest() public view returns (ReferralClaimTypeInfo[] memory) {
    return _getClaimTypes(false);
  }

  function getClaimTypesForHost() public view returns (ReferralClaimTypeInfo[] memory) {
    return _getClaimTypes(true);
  }

  function getClaimTypeInfo(uint8 claimType) public view returns (ReferralClaimTypeInfo memory) {
    return claimTypeNumberToClaimType[claimType];
  }

  function claimTypeExists(uint8 claimType, bool forHost) public view returns (bool) {
    ReferralClaimTypeInfo memory claimTypeInfo = claimTypeNumberToClaimType[claimType];
    ReferralClaimCreator creator = forHost ? ReferralClaimCreator.Host : ReferralClaimCreator.Guest;
    return
      bytes(claimTypeInfo.claimName).length > 0 &&
      (claimTypeInfo.creator == creator || claimTypeInfo.creator == ReferralClaimCreator.Both);
  }

  function createClaim(CreateReferralClaimRequest memory request, bool isInsuranceClaim, address sender)
    external
    onlyPlatform
    returns (uint256 newClaimId)
  {
    TripGatewayTypes.GatewayTrip memory trip = TripLib.toLegacyTrip(tripQuery.getTrip(request.tripId));
    require(!isInsuranceClaim || trip.host == sender, 'ReferralMainFacet1: insurance claim only for hosts');
    require(
      (trip.host == sender && claimTypeExists(request.claimType, true)) ||
        (trip.guest == sender && claimTypeExists(request.claimType, false)),
      'Only for trip host or guest, or wrong claim type.'
    );
    require(
      trip.status != TripGatewayTypes.GatewayTripStatus.Canceled && trip.status != TripGatewayTypes.GatewayTripStatus.Created,
      'Wrong trip status.'
    );
    require(request.amountInUsdCents > 0, 'Amount can not be null.');

    claimCounter += 1;
    newClaimId = claimCounter;
    claimIdToClaim[newClaimId] = ReferralClaimInfoV2({
      tripId: request.tripId,
      claimId: newClaimId,
      deadlineDateInSec: block.timestamp + waitingTimeForApproveInSec,
      claimType: request.claimType,
      status: ReferralClaimStatus.NotPaid,
      description: request.description,
      amountInUsdCents: request.amountInUsdCents,
      payDateInSec: 0,
      rejectedBy: address(0),
      rejectedDateInSec: 0,
      photosUrl: request.photosUrl,
      isHostClaims: sender == trip.host
    });

    _emitClaimEvent(
      newClaimId,
      uint8(ReferralClaimStatus.NotPaid),
      trip.host == sender ? trip.guest : trip.host,
      trip.host == sender ? trip.host : trip.guest
    );

    if (isInsuranceClaim) {
      insuranceMain.createInsuranceClaim(newClaimId, sender);
    }
  }

  function rejectClaim(uint256 targetClaimId, address sender) external onlyPlatform {
    ReferralClaimInfoV2 memory claim = getClaim(targetClaimId);
    TripGatewayTypes.GatewayTrip memory trip = TripLib.toLegacyTrip(tripQuery.getTrip(claim.tripId));
    require(trip.host == sender || trip.guest == sender, 'For trip guest or host.');
    require(claim.status != ReferralClaimStatus.Paid && claim.status != ReferralClaimStatus.Cancel, 'Wrong claim status.');

    ReferralClaimInfoV2 storage claimToUpdate = claimIdToClaim[targetClaimId];
    claimToUpdate.status = ReferralClaimStatus.Cancel;
    claimToUpdate.rejectedBy = sender;
    claimToUpdate.rejectedDateInSec = block.timestamp;

    _emitClaimEvent(
      targetClaimId,
      uint8(ReferralClaimStatus.Cancel),
      sender,
      trip.host == sender ? trip.host : trip.guest
    );
  }

  function payClaim(uint256 targetClaimId, address sender) external payable onlyPlatform {
    ReferralClaimInfoV2 memory claim = getClaim(targetClaimId);
    TripGatewayTypes.GatewayTrip memory trip = TripLib.toLegacyTrip(tripQuery.getTrip(claim.tripId));
    uint256 commission = getPlatformFeeFrom(claim.amountInUsdCents);

    (uint256 valueToPay, uint256 feeInCurrency, int256 rate, uint8 decimals) = currencyConverter.calculateLatestValueWithFee(
      trip.paymentInfo.currencyType,
      claim.amountInUsdCents,
      commission
    );

    ReferralClaimInfoV2 storage claimToUpdate = claimIdToClaim[targetClaimId];
    claimToUpdate.payDateInSec = block.timestamp;
    claimToUpdate.status = ReferralClaimStatus.Paid;
    claimIdToCurrencyRate[targetClaimId] = CurrencyRate(rate, decimals);

    _emitClaimEvent(targetClaimId, uint8(ReferralClaimStatus.Paid), trip.guest, trip.host);

    if (!insuranceMain.isInsuranceClaim(targetClaimId) || trip.guest == sender) {
      paymentService.payClaim{value: msg.value}(trip, valueToPay, feeInCurrency, commission, sender);
      return;
    }

    insuranceMain.payHostInsuranceClaim{value: msg.value}(
      valueToPay,
      HostInsurancePayoutContext({host: trip.host, currencyType: trip.paymentInfo.currencyType, tripId: trip.tripId})
    );
  }

  function _emitClaimEvent(uint256 targetClaimId, uint8 claimStatus, address from, address to) internal {
    if (address(notificationService) != address(0)) {
      notificationService.emitEvent(EventType.Claim, targetClaimId, claimStatus, from, to);
    }
  }

  function _getClaimTypes(bool forHost) internal view returns (ReferralClaimTypeInfo[] memory) {
    ReferralClaimTypeInfo[] memory claims = new ReferralClaimTypeInfo[](uint256(claimTypeNumber));
    uint256 counter = 0;
    for (uint8 i = 0; i <= claimTypeNumber; i++) {
      ReferralClaimTypeInfo memory claimType = claimTypeNumberToClaimType[i];
      ReferralClaimCreator creator = forHost ? ReferralClaimCreator.Host : ReferralClaimCreator.Guest;
      if (
        bytes(claimType.claimName).length > 0 &&
        (claimType.creator == creator || claimType.creator == ReferralClaimCreator.Both)
      ) {
        claims[counter] = claimType;
        counter++;
      }
    }
    assembly ('memory-safe') {
      mstore(claims, counter)
    }
    return claims;
  }

  function _seedDefaultClaimTypes() internal {
    claimTypeNumberToClaimType[uint8(ReferralClaimType.Tolls)] = ReferralClaimTypeInfo(
      uint8(ReferralClaimType.Tolls),
      'Tolls',
      ReferralClaimCreator.Host
    );
    claimTypeNumberToClaimType[uint8(ReferralClaimType.Tickets)] = ReferralClaimTypeInfo(
      uint8(ReferralClaimType.Tickets),
      'Tickets',
      ReferralClaimCreator.Host
    );
    claimTypeNumberToClaimType[uint8(ReferralClaimType.LateReturn)] = ReferralClaimTypeInfo(
      uint8(ReferralClaimType.LateReturn),
      'Late return',
      ReferralClaimCreator.Host
    );
    claimTypeNumberToClaimType[uint8(ReferralClaimType.Smoking)] = ReferralClaimTypeInfo(
      uint8(ReferralClaimType.Smoking),
      'Smoking',
      ReferralClaimCreator.Both
    );
    claimTypeNumberToClaimType[uint8(ReferralClaimType.Cleanliness)] = ReferralClaimTypeInfo(
      uint8(ReferralClaimType.Cleanliness),
      'Cleanliness',
      ReferralClaimCreator.Both
    );
    claimTypeNumberToClaimType[uint8(ReferralClaimType.ExteriorDamage)] = ReferralClaimTypeInfo(
      uint8(ReferralClaimType.ExteriorDamage),
      'Exterior damage',
      ReferralClaimCreator.Both
    );
    claimTypeNumberToClaimType[uint8(ReferralClaimType.InteriorDamage)] = ReferralClaimTypeInfo(
      uint8(ReferralClaimType.InteriorDamage),
      'Interior damage',
      ReferralClaimCreator.Both
    );
    claimTypeNumberToClaimType[uint8(ReferralClaimType.Other)] = ReferralClaimTypeInfo(
      uint8(ReferralClaimType.Other),
      'Other',
      ReferralClaimCreator.Both
    );
    claimTypeNumberToClaimType[uint8(ReferralClaimType.FaultyVehicle)] = ReferralClaimTypeInfo(
      uint8(ReferralClaimType.FaultyVehicle),
      'Faulty vehicle',
      ReferralClaimCreator.Guest
    );
    claimTypeNumberToClaimType[uint8(ReferralClaimType.ListingMismatch)] = ReferralClaimTypeInfo(
      uint8(ReferralClaimType.ListingMismatch),
      'Listing mismatch',
      ReferralClaimCreator.Guest
    );
    claimTypeNumber = 9;
  }
}
