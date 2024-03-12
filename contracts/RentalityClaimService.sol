// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import './proxy/UUPSAccess.sol';
import './RentalityCarToken.sol';
import './Schemas.sol';

/// @title RentalityClaimService - Manages claims and related operations.
/// @dev This contract allows users with manager roles to create, reject, and pay claims.
contract RentalityClaimService is Initializable, UUPSAccess {
  // Private variables for platform configuration
  uint256 private waitingTimeForApproveInSec;
  uint256 private claimId;

  // Mapping to store claims using claimId as the key
  mapping(uint256 => Schemas.Claim) private claimIdToClaim;

  event ClaimStatusChanged(
    uint256 claimId,
    Schemas.ClaimStatus claimStatus,
    address indexed host,
    address indexed guest
  );

  event WaitingTimeChanged(uint256 newWaitingTime);

  // Modifier to restrict access to only managers contracts
  modifier onlyManager() {
    require(userService.isManager(msg.sender), 'Only manager.');
    _;
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
  function createClaim(Schemas.CreateClaimRequest memory request, address host, address guest) public onlyManager {
    require(request.amountInUsdCents > 0, 'Amount can not be null.');

    claimId += 1;
    uint256 newClaimId = claimId;

    uint256 deadline = block.timestamp + waitingTimeForApproveInSec;

    Schemas.Claim memory newClaim = Schemas.Claim(
      request.tripId,
      newClaimId,
      deadline,
      request.claimType,
      Schemas.ClaimStatus.NotPaid,
      request.description,
      request.amountInUsdCents,
      0,
      address(0),
      0
    );
    claimIdToClaim[newClaimId] = newClaim;

    emit ClaimStatusChanged(newClaimId, Schemas.ClaimStatus.NotPaid, host, guest);
  }

  /// @dev Rejects a claim, only callable by managers contracts.
  /// @param _claimId ID of the claim to be rejected.
  /// @param rejectedBy Address of the user rejecting the claim.
  function rejectClaim(uint256 _claimId, address rejectedBy, address host, address guest) public onlyManager {
    Schemas.Claim storage claim = claimIdToClaim[_claimId];
    require(
      claim.status != Schemas.ClaimStatus.Paid && claim.status != Schemas.ClaimStatus.Cancel,
      'Wrong claim status.'
    );

    claim.status = Schemas.ClaimStatus.Cancel;
    claim.rejectedBy = rejectedBy;
    claim.rejectedDateInSec = block.timestamp;

    emit ClaimStatusChanged(_claimId, Schemas.ClaimStatus.Cancel, host, guest);
  }

  /// @dev Pays a claim, only callable by managers contracts.
  /// @param _claimId ID of the claim to be paid.
  function payClaim(uint256 _claimId, address host, address guest) public onlyManager {
    Schemas.Claim storage claim = claimIdToClaim[_claimId];

    uint256 time = block.timestamp;

    claim.payDateInSec = time;
    claim.status = Schemas.ClaimStatus.Paid;

    emit ClaimStatusChanged(_claimId, Schemas.ClaimStatus.Paid, host, guest);
  }

  /// @dev Updates the status of a claim based on the current timestamp.
  /// @param _claimId ID of the claim to be updated.
  function updateClaim(uint256 _claimId, address host, address guest) public {
    Schemas.Claim storage claim = claimIdToClaim[_claimId];

    uint256 time = block.timestamp;

    if (time >= claim.deadlineDateInSec) {
      claim.status = Schemas.ClaimStatus.Overdue;
      emit ClaimStatusChanged(_claimId, Schemas.ClaimStatus.Overdue, host, guest);
    }
  }

  /// @dev Gets the details of a claim by its ID.
  /// @param _claimId ID of the claim.
  /// @return Details of the claim.
  function getClaim(uint256 _claimId) public view returns (Schemas.Claim memory) {
    return claimIdToClaim[_claimId];
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
    return claimIdToClaim[_claimId].deadlineDateInSec > 0;
  }

  /// @dev constructor to initialize proxy contract
  /// @param _userService, contract for access control
  function initialize(address _userService) public initializer {
    userService = IRentalityAccessControl(_userService);
    waitingTimeForApproveInSec = 259_200;
  }
}
