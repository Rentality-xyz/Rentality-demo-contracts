// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../abstract/IRentalityAccessControl.sol';
import '../Schemas.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

/// @title ARentalityEngine - Abstract contract for a rental engine in the Rentality system.
/// @notice This contract defines the basic structure and functions required for a rental engine.
abstract contract ARentalityEngine {
  // Error events
  /// @notice Emitted when incorrect arguments are passed to a function.
  error WrongEngineArgs();

  /// @notice Emitted when engine parameters do not match expectations.
  error EngineParamsNotMatch();

  // Internal state variables
  /// @notice The RentalityUserService contract used for user management.
  IRentalityAccessControl internal userService;

  /// @notice The type of the engine.
  uint8 internal eType;

  // Modifiers
  /// @notice Ensures that only a manager can execute the function.
  modifier onlyManager() {
    require(userService.isRentalityPlatform(msg.sender), 'Only for Manager.');
    _;
  }

  // Abstract functions
  /// @notice Sets the engine type.
  function setEType(uint8 _eType) public virtual;

  /// @notice Retrieves the fuel prices of car.
  /// @param engineParams The array of engine parameters used to retrieve fuel prices.
  /// @return A fuel price corresponding to the provided engine parameters.
  function getFuelPriceFromEngineParams(uint64[] memory engineParams) public view virtual returns (uint64);

  /// @notice Verify engine params
  function verifyCreateParams(uint64[] memory params) public view virtual;

  /// @notice Verify end return engine params.
  function verifyUpdateParams(
    uint64[] memory newParams,
    uint64[] memory oldParams
  ) public view virtual returns (uint64[] memory);

  /// @notice Calculates and returns extra costs based on given parameters.
  function extraCosts(uint64[] memory params) public virtual returns (uint64);

  /// @notice Calculates the resolve amount in USD cents for a rental transaction.
  function getResolveAmountInUsdCents(
    uint64 fuelPrice,
    uint64[] memory startParams,
    uint64[] memory endParams,
    uint64[] memory engineParams,
    uint64 milesIncludedPerDay,
    uint64 pricePerDayInUsdCents,
    uint64 tripDays
  ) public view virtual returns (uint64, uint64);

  // Public functions
  /// @notice Retrieves the engine type.
  function getEType() public view returns (uint8) {
    return eType;
  }

  /// @notice Calculates the resolve amount in USD cents based on driven miles.
  function getDrivenMilesResolveAmountInUsdCents(
    uint64 startOdometr,
    uint64 endOdometr,
    uint64 milesIncludedPerDay,
    uint64 pricePerDayInUsdCents,
    uint64 tripDays
  ) public pure virtual returns (uint64) {
    if (endOdometr - startOdometr <= milesIncludedPerDay * tripDays) return 0;

    return
      uint64(
        Math.ceilDiv(pricePerDayInUsdCents, milesIncludedPerDay) *
          ((endOdometr - startOdometr - milesIncludedPerDay * tripDays))
      );
  }

  /// @notice Verifies the correctness of start parameters.
  function verifyStartParams(uint64[] memory params) public virtual {
    isCorrectArgs(params.length == getParamsAmount() && params[0] <= 100);
  }

  /// @notice Verifies the correctness of end parameters.
  function verifyEndParams(uint64[] memory startParams, uint64[] memory endParams) public virtual {
    isCorrectArgs(startParams.length == getParamsAmount() && endParams.length == getParamsAmount());
    isCorrectArgs(endParams[0] <= 100);

    uint64 startOdometr = startParams[1];
    uint64 endOdometr = endParams[1];

    require(endOdometr >= startOdometr, 'End odometr cannot be less.');
  }

  /// @notice Compares two sets of parameters to ensure they match.
  function compareParams(uint64[] memory start, uint64[] memory end) public pure {
    isMatch(start.length == end.length);

    for (uint256 i = 0; i < start.length; i++) {
      isMatch(start[i] == end[i]);
    }
  }

  /// @notice Gets the number of parameters expected for this engine.
  function getParamsAmount() public pure virtual returns (uint256) {
    return 2;
  }

  /// @notice Checks if the given array of parameters is empty.
  /// @param params An array of uint64 parameters.
  /// @return A boolean indicating whether the parameters array is empty.
  function isEmptyParams(uint64[] memory params) public pure returns (bool) {
    for (uint256 i = 0; i < params.length; i++) {
      if (params[i] != 0) {
        return false;
      }
    }
    return true;
  }
  // Internal helper functions
  /// @notice Reverts if the provided condition is not met, indicating incorrect arguments.
  function isCorrectArgs(bool eq) internal pure {
    if (!eq) {
      revert WrongEngineArgs();
    }
  }

  /// @notice Reverts if the provided condition is not met, indicating mismatched parameters.
  function isMatch(bool eq) internal pure {
    if (!eq) {
      revert EngineParamsNotMatch();
    }
  }
}
