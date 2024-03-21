// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './ARentalityEngine.sol';

/// @title RentalityElectricEngine - Implementation of an electric engine in the Rentality system.
/// @notice This contract extends ARentalityEngine and adds functionality specific to electric engines.
contract RentalityElectricEngine is ARentalityEngine {
  /// @dev Constructor to set the RentalityUserService address during deployment.
  constructor(address _userService) {
    userService = IRentalityAccessControl(_userService);
  }

  /// @dev Sets the engine type. Only callable by an admin.
  /// @param _eType The new engine type to be set.
  function setEType(uint8 _eType) public override {
    require(userService.isAdmin(tx.origin), 'Only Admin.');
    eType = _eType;
  }
  /// @notice Retrieves the fuel prices of electric car.
  /// @param engineParams The array of engine parameters used to retrieve fuel prices.
  /// @return A fuel price corresponding to the provided engine parameters.
  function getFuelPriceFromEngineParams(uint64[] memory engineParams) public pure override returns (uint64) {
    return engineParams[0];
  }

  /// @dev Verify patrol engine params
  /// @param params An array of four uint64 values representing charge price scales.
  function verifyCreateParams(uint64[] memory params) public pure override {
    isCorrectArgs(params.length == 1);
  }

  /// @dev verify and return new electric engine data
  /// @param newParams An array of four uint64 values representing updated charge price scales.
  function verifyUpdateParams(
    uint64[] memory newParams,
    uint64[] memory /*oldParams*/
  ) public pure override returns (uint64[] memory) {
    isCorrectArgs(newParams.length == 1);

    return newParams;
  }

  /// @dev Returns zero extra costs for electric cars.
  function extraCosts(uint64[] memory /*params*/) public pure override returns (uint64) {
    return 0;
  }

  /// @dev Calculates the resolve amount in USD cents for an electric car rental.
  /// @param startParams An array of uint64 values representing the initial parameters of the rental.
  /// @param endParams An array of uint64 values representing the final parameters of the rental.
  /// @param milesIncludedPerDay The number of miles included per day in the rental.
  /// @param pricePerDayInUsdCents The rental price per day in USD cents.
  /// @param tripDays The total number of days in the rental trip.
  /// @return The total resolve amount and the fuel-specific resolve amount in USD cents.
  function getResolveAmountInUsdCents(
    uint64 priceForFullBatteryCharge,
    uint64[] memory startParams,
    uint64[] memory endParams,
    uint64[] memory,
    uint64 milesIncludedPerDay,
    uint64 pricePerDayInUsdCents,
    uint64 tripDays
  ) public pure override returns (uint64, uint64) {
    return (
      getDrivenMilesResolveAmountInUsdCents(
        startParams[1],
        endParams[1],
        milesIncludedPerDay,
        pricePerDayInUsdCents,
        tripDays
      ),
      getFuelResolveAmountInUsdCents(endParams[0], startParams[0], priceForFullBatteryCharge)
    );
  }

  /// @dev Calculates the resolve amount in USD cents based on the remaining charge of an electric car.
  /// @param endFuelLevelInPercents The final fuel level of the electric car in percentages.
  /// @param priceForFullBatteryCharge Representing fuel prices.
  /// @return The fuel-specific resolve amount in USD cents.
  function getFuelResolveAmountInUsdCents(
    uint64 endFuelLevelInPercents,
    uint startFuelLevelInPercents,
    uint64 priceForFullBatteryCharge
  ) public pure returns (uint64) {
    if (endFuelLevelInPercents >= startFuelLevelInPercents) {
      return 0;
    }
    uint256 difference = startFuelLevelInPercents - endFuelLevelInPercents;

    return (uint64(difference) * priceForFullBatteryCharge) / 100;
  }
}
