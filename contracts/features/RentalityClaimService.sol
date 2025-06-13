// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../proxy/UUPSAccess.sol';
import '../RentalityCarToken.sol';
import '../Schemas.sol';
import './RentalityNotificationService.sol';

struct CurrencyRate {
  int rate;
  uint8 decimals;
}
/// @title RentalityClaimService - Manages claims and related operations.
/// @dev This contract allows users with manager roles to create, reject, and pay claims.
contract RentalityClaimService is Initializable, UUPSAccess {
  // Private variables for platform configuration
  uint256 private waitingTimeForApproveInSec;
  uint256 private claimId;
  uint private platformFeeInPPM;
  // Mapping to store claims using claimId as the key
  mapping(uint256 => Schemas.Claim) private claimIdToClaim;

  mapping(uint => CurrencyRate) public claimIdToCurrencyRate;
  RentalityNotificationService private eventManager;

  event WaitingTimeChanged(uint256 newWaitingTime);

  mapping(uint256 => Schemas.ClaimV2) private claimIdToClaimV2;
  mapping(uint8 => Schemas.ClaimTypeV2) private claimTypeNumberToClaimType;
  uint8 private claimTypeNumber;

  // Modifier to restrict access to only Rentality platforms contracts
  modifier onlyManager() {
    require(userService.isRentalityPlatform(msg.sender), 'only Rentality platform.');
    _;
  }
  /// @dev Updates the address of the RentalityEventManager contract.
  /// @param _eventManager The address of the new RentalityEventManager contract.
  function updateEventServiceAddress(address _eventManager) public {
    require(userService.isAdmin(msg.sender), 'Only admin.');
    eventManager = RentalityNotificationService(_eventManager);
  }
  /// @dev Sets the waiting time, only callable by administrators.
  /// @param newWaitingTimeInSec, set old value to this
  function setWaitingTime(uint256 newWaitingTimeInSec) public onlyManager {
    require(userService.isAdmin(tx.origin), 'Only admin.');
    waitingTimeForApproveInSec = newWaitingTimeInSec;

    emit WaitingTimeChanged(newWaitingTimeInSec);
  }

  /// @dev get waiting time to approval
  /// @return waiting time to approval in sec
  function getWaitingTime() public view returns (uint) {
    return waitingTimeForApproveInSec;
  }

  /// @dev Creates a new claim, only callable by managers contracts.
  /// @param request Details of the claim to be created.
  function createClaim(
    Schemas.CreateClaimRequest memory request,
    address host,
    address guest,
    address user
  ) public onlyManager returns(uint) {
    require(request.amountInUsdCents > 0, 'Amount can not be null.');

    claimId += 1;
    uint256 newClaimId = claimId;

    uint256 deadline = block.timestamp + waitingTimeForApproveInSec;

    Schemas.ClaimV2 memory newClaim = Schemas.ClaimV2(
      request.tripId,
      newClaimId,
      deadline,
      request.claimType,
      Schemas.ClaimStatus.NotPaid,
      request.description,
      request.amountInUsdCents,
      0,
      address(0),
      0,
      request.photosUrl,
      user == host ? true : false
    );
    claimIdToClaimV2[newClaimId] = newClaim;

    eventManager.emitEvent(
      Schemas.EventType.Claim,
      newClaimId,
      uint8(Schemas.ClaimStatus.NotPaid),
      host == user ? guest : host,
      host == user ? host : guest
    );
    return claimId;
  }

  /// @dev Rejects a claim, only callable by managers contracts.
  /// @param _claimId ID of the claim to be rejected.
  /// @param rejectedBy Address of the user rejecting the claim.
  function rejectClaim(uint256 _claimId, address rejectedBy, address host, address guest) public onlyManager {
    Schemas.ClaimV2 storage claim = claimIdToClaimV2[_claimId];
    require(
      claim.status != Schemas.ClaimStatus.Paid && claim.status != Schemas.ClaimStatus.Cancel,
      'Wrong claim status.'
    );

    claim.status = Schemas.ClaimStatus.Cancel;
    claim.rejectedBy = rejectedBy;
    claim.rejectedDateInSec = block.timestamp;

    eventManager.emitEvent(
      Schemas.EventType.Claim,
      _claimId,
      uint8(Schemas.ClaimStatus.Cancel),
      rejectedBy,
      host == rejectedBy ? host : guest
    );
  }

  /// @dev Pays a claim, only callable by managers contracts.
  /// @param _claimId ID of the claim to be paid.
  function payClaim(uint256 _claimId, address host, address guest, int rate, uint8 dec) public onlyManager {
    Schemas.ClaimV2 storage claim = claimIdToClaimV2[_claimId];

    uint256 time = block.timestamp;

    claim.payDateInSec = time;
    claim.status = Schemas.ClaimStatus.Paid;
    claimIdToCurrencyRate[_claimId] = CurrencyRate(rate, dec);

    eventManager.emitEvent(Schemas.EventType.Claim, _claimId, uint8(Schemas.ClaimStatus.Paid), guest, host);
  }

  /// @dev Updates the status of a claim based on the current timestamp.
  /// @param _claimId ID of the claim to be updated.
  function updateClaim(uint256 _claimId, address host, address guest) public {
    Schemas.ClaimV2 storage claim = claimIdToClaimV2[_claimId];

    uint256 time = block.timestamp;

    if (time >= claim.deadlineDateInSec) {
      claim.status = Schemas.ClaimStatus.Overdue;
      eventManager.emitEvent(Schemas.EventType.Claim, _claimId, uint8(Schemas.ClaimStatus.Overdue), host, guest);
    }
  }

  function getClaimTypeInfo(uint8 claimType) public view returns (Schemas.ClaimTypeV2 memory) {
    return claimTypeNumberToClaimType[claimType];
  }

  /// @dev Gets the details of a claim by its ID.
  /// @param _claimId ID of the claim.
  /// @return Details of the claim.
  function getClaim(uint256 _claimId) public view returns (Schemas.ClaimV2 memory) {
    return claimIdToClaimV2[_claimId];
  }

  /// @dev Gets the total number of claims.
  /// @return Total number of claims.
  function getClaimsAmount() public view returns (uint256) {
    return claimId;
  }

  /// @dev Checks if a claim with a specific ID exists.
  /// @param _claimId ID of the claim.
  /// @return True if the claim exists, false otherwise.
  function exists(uint256 _claimId) public view returns (bool) {
    return claimIdToClaimV2[_claimId].deadlineDateInSec > 0;
  }

  function getPlatformFeeFrom(uint256 value) public view returns (uint256) {
    return (value * platformFeeInPPM) / 1_000_000;
  }

  function setPlatformFee(uint value) public {
    require(userService.isAdmin(tx.origin), 'Only admin.');
    platformFeeInPPM = value;
  }

  function addClaimType(string memory name, Schemas.ClaimCreator creator) public {
    require(userService.isAdmin(tx.origin), 'Only admin.');
    claimTypeNumber += 1;
    claimTypeNumberToClaimType[claimTypeNumber] = Schemas.ClaimTypeV2(claimTypeNumber, name, creator);
  }
  function removeClaimType(uint8 claimType) public {
    require(userService.isAdmin(tx.origin), 'Only admin');
    delete claimTypeNumberToClaimType[claimType];
  }
  function getClaimTypesForGuest() public view returns (Schemas.ClaimTypeV2[] memory) {
    Schemas.ClaimTypeV2[] memory claims = new Schemas.ClaimTypeV2[](uint(claimTypeNumber));
    uint counter = 0;
    for (uint8 i = 0; i <= claimTypeNumber; i++) {
      Schemas.ClaimTypeV2 memory claimType = claimTypeNumberToClaimType[i];
      if (
        bytes(claimType.claimName).length > 0 &&
        (Schemas.ClaimCreator.Guest == claimType.creator || Schemas.ClaimCreator.Both == claimType.creator)
      ) {
        claims[counter] = claimTypeNumberToClaimType[i];
        counter++;
      }
    }
    assembly ('memory-safe') {
      mstore(claims, counter)
    }
    return claims;
  }
  function getClaimTypesForHost() public view returns (Schemas.ClaimTypeV2[] memory) {
    Schemas.ClaimTypeV2[] memory claims = new Schemas.ClaimTypeV2[](uint(claimTypeNumber));
    uint counter = 0;
    for (uint8 i = 0; i <= claimTypeNumber; i++) {
      Schemas.ClaimTypeV2 memory claimType = claimTypeNumberToClaimType[i];
      if (
        bytes(claimType.claimName).length > 0 &&
        (Schemas.ClaimCreator.Host == claimType.creator || Schemas.ClaimCreator.Both == claimType.creator)
      ) {
        claims[counter] = claimTypeNumberToClaimType[i];
        counter++;
      }
    }
    assembly ('memory-safe') {
      mstore(claims, counter)
    }
    return claims;
  }
  function claimTypeExists(uint8 claimType, bool forHost) public view returns (bool) {
    Schemas.ClaimTypeV2 memory claimTypeInfo = claimTypeNumberToClaimType[claimType];
    Schemas.ClaimCreator creator = forHost ? Schemas.ClaimCreator.Host : Schemas.ClaimCreator.Guest;
    return
      bytes(claimTypeInfo.claimName).length > 0 &&
      (claimTypeInfo.creator == creator || claimTypeInfo.creator == Schemas.ClaimCreator.Both);
  }
  function _findClaimType(uint8 claimType) private view returns (bool) {
    return bytes(claimTypeNumberToClaimType[claimType].claimName).length == 0;
  }

  function migrateFromV1() public {
    require(userService.isAdmin(tx.origin), 'Only admin');
    claimTypeNumberToClaimType[uint8(Schemas.ClaimType.Tolls)] = Schemas.ClaimTypeV2(
      uint8(Schemas.ClaimType.Tolls),
      'Tolls',
      Schemas.ClaimCreator.Host
    );
    claimTypeNumberToClaimType[uint8(Schemas.ClaimType.Tickets)] = Schemas.ClaimTypeV2(
      uint8(Schemas.ClaimType.Tickets),
      'Tickets',
      Schemas.ClaimCreator.Host
    );
    claimTypeNumberToClaimType[uint8(Schemas.ClaimType.LateReturn)] = Schemas.ClaimTypeV2(
      uint8(Schemas.ClaimType.LateReturn),
      'LateReturn',
      Schemas.ClaimCreator.Host
    );

    claimTypeNumberToClaimType[uint8(Schemas.ClaimType.Smoking)] = Schemas.ClaimTypeV2(
      uint8(Schemas.ClaimType.Smoking),
      'Smoking',
      Schemas.ClaimCreator.Both
    );
    claimTypeNumberToClaimType[uint8(Schemas.ClaimType.Cleanliness)] = Schemas.ClaimTypeV2(
      uint8(Schemas.ClaimType.Cleanliness),
      'Cleanliness',
      Schemas.ClaimCreator.Both
    );
    claimTypeNumberToClaimType[uint8(Schemas.ClaimType.ExteriorDamage)] = Schemas.ClaimTypeV2(
      uint8(Schemas.ClaimType.ExteriorDamage),
      'ExteriorDamage',
      Schemas.ClaimCreator.Both
    );
    claimTypeNumberToClaimType[uint8(Schemas.ClaimType.InteriorDamage)] = Schemas.ClaimTypeV2(
      uint8(Schemas.ClaimType.InteriorDamage),
      'InteriorDamage',
      Schemas.ClaimCreator.Both
    );
    claimTypeNumberToClaimType[uint8(Schemas.ClaimType.Other)] = Schemas.ClaimTypeV2(
      uint8(Schemas.ClaimType.Other),
      'Other',
      Schemas.ClaimCreator.Both
    );

    claimTypeNumberToClaimType[uint8(Schemas.ClaimType.FaultyVehicle)] = Schemas.ClaimTypeV2(
      uint8(Schemas.ClaimType.FaultyVehicle),
      'FaultyVehicle',
      Schemas.ClaimCreator.Guest
    );
    claimTypeNumberToClaimType[uint8(Schemas.ClaimType.ListingMismatch)] = Schemas.ClaimTypeV2(
      uint8(Schemas.ClaimType.ListingMismatch),
      'ListingMismatch',
      Schemas.ClaimCreator.Guest
    );
    claimTypeNumber = 9;
    uint totalClaimsCount = claimId;
    for (uint i = 1; i <= totalClaimsCount; i++) {
      Schemas.Claim memory oldClaim = claimIdToClaim[i];
      claimIdToClaimV2[i] = Schemas.ClaimV2({
        tripId: oldClaim.tripId,
        claimId: oldClaim.claimId,
        deadlineDateInSec: oldClaim.deadlineDateInSec,
        claimType: uint8(oldClaim.claimType),
        status: oldClaim.status,
        description: oldClaim.description,
        amountInUsdCents: oldClaim.amountInUsdCents,
        payDateInSec: oldClaim.payDateInSec,
        rejectedBy: oldClaim.rejectedBy,
        rejectedDateInSec: oldClaim.rejectedDateInSec,
        photosUrl: oldClaim.photosUrl,
        isHostClaims: oldClaim.isHostClaims
      });
    }
  }
  /// @dev constructor to initialize proxy contract
  /// @param _userService, contract for access control
  function initialize(address _userService, address _eventManager) public initializer {
    userService = IRentalityAccessControl(_userService);
    waitingTimeForApproveInSec = 259_200;
    platformFeeInPPM = 0;
    eventManager = RentalityNotificationService(_eventManager);

        claimTypeNumberToClaimType[uint8(Schemas.ClaimType.Tolls)] = Schemas.ClaimTypeV2(
      uint8(Schemas.ClaimType.Tolls),
      'Tolls',
      Schemas.ClaimCreator.Host
    );
    claimTypeNumberToClaimType[uint8(Schemas.ClaimType.Tickets)] = Schemas.ClaimTypeV2(
      uint8(Schemas.ClaimType.Tickets),
      'Tickets',
      Schemas.ClaimCreator.Host
    );
    claimTypeNumberToClaimType[uint8(Schemas.ClaimType.LateReturn)] = Schemas.ClaimTypeV2(
      uint8(Schemas.ClaimType.LateReturn),
      'LateReturn',
      Schemas.ClaimCreator.Host
    );

    claimTypeNumberToClaimType[uint8(Schemas.ClaimType.Smoking)] = Schemas.ClaimTypeV2(
      uint8(Schemas.ClaimType.Smoking),
      'Smoking',
      Schemas.ClaimCreator.Both
    );
    claimTypeNumberToClaimType[uint8(Schemas.ClaimType.Cleanliness)] = Schemas.ClaimTypeV2(
      uint8(Schemas.ClaimType.Cleanliness),
      'Cleanliness',
      Schemas.ClaimCreator.Both
    );
    claimTypeNumberToClaimType[uint8(Schemas.ClaimType.ExteriorDamage)] = Schemas.ClaimTypeV2(
      uint8(Schemas.ClaimType.ExteriorDamage),
      'ExteriorDamage',
      Schemas.ClaimCreator.Both
    );
    claimTypeNumberToClaimType[uint8(Schemas.ClaimType.InteriorDamage)] = Schemas.ClaimTypeV2(
      uint8(Schemas.ClaimType.InteriorDamage),
      'InteriorDamage',
      Schemas.ClaimCreator.Both
    );
    claimTypeNumberToClaimType[uint8(Schemas.ClaimType.Other)] = Schemas.ClaimTypeV2(
      uint8(Schemas.ClaimType.Other),
      'Other',
      Schemas.ClaimCreator.Both
    );

    claimTypeNumberToClaimType[uint8(Schemas.ClaimType.FaultyVehicle)] = Schemas.ClaimTypeV2(
      uint8(Schemas.ClaimType.FaultyVehicle),
      'FaultyVehicle',
      Schemas.ClaimCreator.Guest
    );
    claimTypeNumberToClaimType[uint8(Schemas.ClaimType.ListingMismatch)] = Schemas.ClaimTypeV2(
      uint8(Schemas.ClaimType.ListingMismatch),
      'ListingMismatch',
      Schemas.ClaimCreator.Guest
    );
    claimTypeNumber = 9;
  }
}
