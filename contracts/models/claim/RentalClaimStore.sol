// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../infrastructure/upgradeable/UUPSOwnable.sol';
import '../../models/common/CommonTypes.sol';
import './RentalClaimTypes.sol';

interface IRentalClaimStoreAccess {
  function isAdmin(address user) external view returns (bool);
  function isRentalityPlatform(address user) external view returns (bool);
}

interface IRentalClaimStoreNotificationService {
  function emitEvent(EventType eType, uint256 id, uint8 objectStatus, address from, address to) external;
}

struct CurrencyRate {
  int256 rate;
  uint8 decimals;
}

contract RentalClaimStore is UUPSOwnable {
  IRentalClaimStoreAccess public userAccess;
  IRentalClaimStoreNotificationService public notificationService;
  uint256 private waitingTimeForApproveInSec;
  uint256 private claimId;
  uint256 private platformFeeInPPM;
  uint8 private claimTypeNumber;
  mapping(uint256 => RentalClaimInfoV2) private claimIdToClaim;
  mapping(uint256 => CurrencyRate) public claimIdToCurrencyRate;
  mapping(uint8 => RentalClaimTypeInfo) private claimTypeNumberToClaimType;

  event WaitingTimeChanged(uint256 newWaitingTime);

  constructor() {
    _disableInitializers();
  }

  modifier onlyPlatform() {
    require(userAccess.isRentalityPlatform(msg.sender), 'only Rentality platform.');
    _;
  }

  function initialize(address userAccessAddress, address notificationServiceAddress) public initializer {
    __Ownable_init();
    userAccess = IRentalClaimStoreAccess(userAccessAddress);
    notificationService = IRentalClaimStoreNotificationService(notificationServiceAddress);
    waitingTimeForApproveInSec = 259_200;
    _seedDefaultClaimTypes();
  }

  function setWaitingTime(uint256 newWaitingTimeInSec) public onlyPlatform {
    require(userAccess.isAdmin(tx.origin), 'Only admin.');
    waitingTimeForApproveInSec = newWaitingTimeInSec;
    emit WaitingTimeChanged(newWaitingTimeInSec);
  }

  function getWaitingTime() public view returns (uint256) {
    return waitingTimeForApproveInSec;
  }

  function createClaim(CreateClaimRequest memory request, address host, address guest, address user)
    public
    onlyPlatform
    returns (uint256)
  {
    require(request.amountInUsdCents > 0, 'Amount can not be null.');
    claimId += 1;
    uint256 newClaimId = claimId;
    claimIdToClaim[newClaimId] = RentalClaimInfoV2({
      tripId: request.tripId,
      claimId: newClaimId,
      deadlineDateInSec: block.timestamp + waitingTimeForApproveInSec,
      claimType: request.claimType,
      status: RentalClaimStatus.NotPaid,
      description: request.description,
      amountInUsdCents: request.amountInUsdCents,
      payDateInSec: 0,
      rejectedBy: address(0),
      rejectedDateInSec: 0,
      photosUrl: request.photosUrl,
      isHostClaims: user == host
    });

    notificationService.emitEvent(
      EventType.Claim,
      newClaimId,
      uint8(RentalClaimStatus.NotPaid),
      host == user ? guest : host,
      host == user ? host : guest
    );
    return newClaimId;
  }

  function rejectClaim(uint256 targetClaimId, address rejectedBy, address host, address guest) public onlyPlatform {
    RentalClaimInfoV2 storage claim = claimIdToClaim[targetClaimId];
    require(claim.status != RentalClaimStatus.Paid && claim.status != RentalClaimStatus.Cancel, 'Wrong claim status.');
    claim.status = RentalClaimStatus.Cancel;
    claim.rejectedBy = rejectedBy;
    claim.rejectedDateInSec = block.timestamp;
    notificationService.emitEvent(
      EventType.Claim,
      targetClaimId,
      uint8(RentalClaimStatus.Cancel),
      rejectedBy,
      host == rejectedBy ? host : guest
    );
  }

  function payClaim(uint256 targetClaimId, address host, address guest, int256 rate, uint8 dec) public onlyPlatform {
    RentalClaimInfoV2 storage claim = claimIdToClaim[targetClaimId];
    claim.payDateInSec = block.timestamp;
    claim.status = RentalClaimStatus.Paid;
    claimIdToCurrencyRate[targetClaimId] = CurrencyRate(rate, dec);
    notificationService.emitEvent(EventType.Claim, targetClaimId, uint8(RentalClaimStatus.Paid), guest, host);
  }

  function getClaim(uint256 targetClaimId) public view returns (RentalClaimInfoV2 memory) {
    return claimIdToClaim[targetClaimId];
  }

  function getClaimsAmount() public view returns (uint256) {
    return claimId;
  }

  function exists(uint256 targetClaimId) public view returns (bool) {
    return claimIdToClaim[targetClaimId].deadlineDateInSec > 0;
  }

  function getPlatformFeeFrom(uint256 value) public view returns (uint256) {
    return (value * platformFeeInPPM) / 1_000_000;
  }

  function setPlatformFee(uint256 value) public {
    require(userAccess.isAdmin(tx.origin), 'Only admin.');
    platformFeeInPPM = value;
  }

  function addClaimType(string memory name, RentalClaimCreator creator) public returns (uint256) {
    require(userAccess.isAdmin(tx.origin), 'Only admin.');
    claimTypeNumber += 1;
    claimTypeNumberToClaimType[claimTypeNumber] = RentalClaimTypeInfo(claimTypeNumber, name, creator);
    return claimTypeNumber;
  }

  function removeClaimType(uint8 claimType) public {
    require(userAccess.isAdmin(tx.origin), 'Only admin');
    delete claimTypeNumberToClaimType[claimType];
  }

  function getClaimTypesForGuest() public view returns (RentalClaimTypeInfo[] memory) {
    return _getClaimTypes(false);
  }

  function getClaimTypesForHost() public view returns (RentalClaimTypeInfo[] memory) {
    return _getClaimTypes(true);
  }

  function claimTypeExists(uint8 claimType, bool forHost) public view returns (bool) {
    RentalClaimTypeInfo memory claimTypeInfo = claimTypeNumberToClaimType[claimType];
    RentalClaimCreator creator = forHost ? RentalClaimCreator.Host : RentalClaimCreator.Guest;
    return
      bytes(claimTypeInfo.claimName).length > 0 &&
      (claimTypeInfo.creator == creator || claimTypeInfo.creator == RentalClaimCreator.Both);
  }

  function updateNotificationService(address notificationServiceAddress) external onlyOwner {
    notificationService = IRentalClaimStoreNotificationService(notificationServiceAddress);
  }

  function updateUserAccess(address userAccessAddress) external onlyOwner {
    userAccess = IRentalClaimStoreAccess(userAccessAddress);
  }

  function _getClaimTypes(bool forHost) private view returns (RentalClaimTypeInfo[] memory) {
    RentalClaimTypeInfo[] memory claims = new RentalClaimTypeInfo[](uint256(claimTypeNumber));
    uint256 counter = 0;
    for (uint8 i = 0; i <= claimTypeNumber; i++) {
      RentalClaimTypeInfo memory claimType = claimTypeNumberToClaimType[i];
      RentalClaimCreator creator = forHost ? RentalClaimCreator.Host : RentalClaimCreator.Guest;
      if (
        bytes(claimType.claimName).length > 0 &&
        (claimType.creator == creator || claimType.creator == RentalClaimCreator.Both)
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

  function _seedDefaultClaimTypes() private {
    claimTypeNumberToClaimType[uint8(RentalClaimType.Tolls)] = RentalClaimTypeInfo(
      uint8(RentalClaimType.Tolls),
      'Tolls',
      RentalClaimCreator.Host
    );
    claimTypeNumberToClaimType[uint8(RentalClaimType.Tickets)] = RentalClaimTypeInfo(
      uint8(RentalClaimType.Tickets),
      'Tickets',
      RentalClaimCreator.Host
    );
    claimTypeNumberToClaimType[uint8(RentalClaimType.LateReturn)] = RentalClaimTypeInfo(
      uint8(RentalClaimType.LateReturn),
      'Late return',
      RentalClaimCreator.Host
    );
    claimTypeNumberToClaimType[uint8(RentalClaimType.Smoking)] = RentalClaimTypeInfo(
      uint8(RentalClaimType.Smoking),
      'Smoking',
      RentalClaimCreator.Both
    );
    claimTypeNumberToClaimType[uint8(RentalClaimType.Cleanliness)] = RentalClaimTypeInfo(
      uint8(RentalClaimType.Cleanliness),
      'Cleanliness',
      RentalClaimCreator.Both
    );
    claimTypeNumberToClaimType[uint8(RentalClaimType.ExteriorDamage)] = RentalClaimTypeInfo(
      uint8(RentalClaimType.ExteriorDamage),
      'Exterior damage',
      RentalClaimCreator.Both
    );
    claimTypeNumberToClaimType[uint8(RentalClaimType.InteriorDamage)] = RentalClaimTypeInfo(
      uint8(RentalClaimType.InteriorDamage),
      'Interior damage',
      RentalClaimCreator.Both
    );
    claimTypeNumberToClaimType[uint8(RentalClaimType.Other)] = RentalClaimTypeInfo(
      uint8(RentalClaimType.Other),
      'Other',
      RentalClaimCreator.Both
    );
    claimTypeNumberToClaimType[uint8(RentalClaimType.FaultyVehicle)] = RentalClaimTypeInfo(
      uint8(RentalClaimType.FaultyVehicle),
      'Faulty vehicle',
      RentalClaimCreator.Guest
    );
    claimTypeNumberToClaimType[uint8(RentalClaimType.ListingMismatch)] = RentalClaimTypeInfo(
      uint8(RentalClaimType.ListingMismatch),
      'Listing mismatch',
      RentalClaimCreator.Guest
    );
    claimTypeNumber = 9;
  }
}
