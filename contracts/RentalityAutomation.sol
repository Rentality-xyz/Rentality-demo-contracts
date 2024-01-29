// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './IRentalityAccessControl.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import './Schemas.sol';
import './proxy/UUPSAccess.sol';

/// @title RentalityAutomation
/// @notice Manages automation for trip-related operations.
contract RentalityAutomation is Initializable, UUPSAccess {
  Schemas.AutomationData[] private waitingToCall;

  uint8 private autoCancellationTimeInHours;
  uint8 private autoStatusChangeTimeInHours;

  /// @notice Ensures that the caller is either an admin or an admin from the origin transaction.
  modifier onlyAdmin() {
    require(userService.isAdmin(msg.sender) || userService.isAdmin(tx.origin), 'User is not an admin');
    _;
  }

  /// @notice Sets the auto-cancellation time for all trips.
  /// @param time The new auto-cancellation time in hours. Must be between 1 and 24.
  /// @notice Only the administrator can call this function.
  function setAutoCancellationTime(uint8 time) public onlyAdmin {
    require(time >= 1 && time <= 24, 'From 1 to 24 h.');
    autoCancellationTimeInHours = time;
  }

  /// @notice Retrieves the current auto-cancellation time for all trips.
  /// @return The current auto-cancellation time in hours.
  function getAutoCancellationTimeInSec() public view returns (uint64) {
    return uint64(autoCancellationTimeInHours) * 60 * 60;
  }

  /// @notice Sets the auto status change time for all trips.
  /// @param time The new auto status change time in hours. Must be between 1 and 3.
  /// @notice Only the administrator can call this function.
  function setAutoStatusChangeTime(uint8 time) public onlyAdmin {
    require(time >= 1 && time <= 3, 'From 1 to 3 h.');
    autoStatusChangeTimeInHours = time;
  }

  /// @notice Retrieves the current auto status change time for all trips.
  /// @return The current auto status change time in hours.
  function getAutoStatusChangeTimeInSec() public view returns (uint64) {
    return uint64(autoStatusChangeTimeInHours) * 60 * 60;
  }

  /// @notice Adds automation for a specific trip.
  ///  @param tripId The ID of the trip.
  ///  @param whenToCallInSec The time in seconds when the automation should be triggered.
  ///  @param aType The type of automation.
  function addAutomation(uint256 tripId, uint256 whenToCallInSec, Schemas.AutomationType aType) public {
    require(userService.isManager(msg.sender), 'Only from manager contract.');

    Schemas.AutomationData memory newData = Schemas.AutomationData(tripId, whenToCallInSec, aType);
    waitingToCall.push(newData);
  }

  /// @notice Removes automation for a specific trip and type.
  /// @param tripId The ID of the trip.
  /// @param aType The type of automation to be removed.
  function removeAutomation(uint256 tripId, Schemas.AutomationType aType) public {
    require(userService.isManager(msg.sender), 'Only from manager contract.');

    for (uint256 i = 0; i < waitingToCall.length; i++) {
      Schemas.AutomationData memory newData = waitingToCall[i];
      if (newData.tripId == tripId && newData.aType == aType) {
        if (waitingToCall.length - 1 == i) {
          waitingToCall.pop();
        } else {
          Schemas.AutomationData memory last = waitingToCall[waitingToCall.length - 1];
          waitingToCall[i] = last;
        }
        break;
      }
    }
  }

  /// @notice Retrieves automation details for a specific trip and type.
  /// @param tripId The ID of the trip.
  /// @param aType The type of automation to retrieve.
  /// @return The details of the automation.
  function getAutomation(
    uint256 tripId,
    Schemas.AutomationType aType
  ) public view returns (Schemas.AutomationData memory) {
    for (uint256 i = 0; i < waitingToCall.length; i++) {
      if (waitingToCall[i].tripId == tripId && waitingToCall[i].aType == aType) {
        return waitingToCall[i];
      }
    }
    return (Schemas.AutomationData(0, 0, Schemas.AutomationType.Rejection));
  }

  /// @notice Retrieves all waiting automations.
  /// @return An array of waiting automations.
  function getAllAutomations() public view returns (Schemas.AutomationData[] memory) {
    return waitingToCall;
  }

  /// @dev Retrieves outdated automations.
  /// @return An array of outdated automations.
  function getOutdatedAutomations() public view returns (Schemas.AutomationData[] memory) {
    uint256 counter = 0;
    for (uint256 i = 0; i < waitingToCall.length; i++) {
      if (waitingToCall[i].whenToCallInSec != 0 && waitingToCall[i].whenToCallInSec <= block.timestamp) {
        counter++;
      }
    }
    Schemas.AutomationData[] memory resultArray = new Schemas.AutomationData[](counter);
    uint256 arrayCounter = 0;
    for (uint256 i = 0; i < waitingToCall.length; i++) {
      {
        if (waitingToCall[i].whenToCallInSec != 0 && waitingToCall[i].whenToCallInSec <= block.timestamp) {
          resultArray[arrayCounter++] = waitingToCall[i];
        }
      }
    }
    return resultArray;
  }

  /// @dev Initializes the contract.
  /// @param userServiceAddress The address of the user service contract.
  function initialize(address userServiceAddress) public initializer {
    userService = IRentalityAccessControl(userServiceAddress);
    autoCancellationTimeInHours = 1;
    autoStatusChangeTimeInHours = 1;
  }
}
