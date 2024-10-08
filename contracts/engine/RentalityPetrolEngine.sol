// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './ARentalityEngine.sol';

/// @title RentalityPetrolEngine.sol - Implementation of a patrol engine in the Rentality system.
/// @notice This contract extends ARentalityEngine and adds functionality specific to patrol engines.
contract RentalityPetrolEngine is ARentalityEngine {
  constructor(address _userService) {
    userService = IRentalityAccessControl(_userService);
  }

  /// @notice Sets the engine type. Only callable by an admin.
  /// @param _eType The new engine type to be set.
  function setEType(uint8 _eType) public override {
    require(userService.isAdmin(tx.origin), 'Only Admin.');
    eType = _eType;
  }

  /// @notice Retrieves the fuel prices of patrol car.
  /// @param engineParams The array of engine parameters used to retrieve fuel prices.
  /// @return A fuel price corresponding to the provided engine parameters.
  function getFuelPriceFromEngineParams(uint64[] memory engineParams) public pure override returns (uint64) {
    return engineParams[1];
  }

  /// @notice Verify a new patrol car tank volume, and fuel price.
  /// @param params An array of two uint64 values representing tank volume and fuel price.
  /// @param params[0] The tank volume of the patrol car in liters.
  /// @param params[1] The initial fuel price per gallon in USD cents.
  function verifyCreateParams(uint64[] memory params) public view override onlyManager {
    isCorrectArgs((params[0] != 0 && params[1] != 0));
  }

  /// @notice Updates the fuel price for an existing patrol car in the system.
  /// @param newParams An array containing the new fuel price.
  /// @param newParams[0] The new fuel price per gallon in USD cents.
  /// @param oldParams An array containing the existing fuel price.
  /// @param oldParams[1] The existing fuel price per gallon in USD cents.
  /// @return Updated oldParams array with the new fuel price.
  function verifyUpdateParams(
    uint64[] memory newParams,
    uint64[] memory oldParams
  ) public view override onlyManager returns (uint64[] memory) {
    // Ensure that the new fuel price is not zero.
    isCorrectArgs(newParams[0] != 0);

    // Update the existing fuel price with the new fuel price.
    oldParams[1] = newParams[0];

    // Return the updated parameters array.
    return oldParams;
  }

  /// @notice Returns zero extra costs for patrol cars.
  function extraCosts(uint64[] memory /*params*/) public pure override returns (uint64) {
    return 0;
  }

  /// @notice Calculates the resolve amount in USD cents for a patrol car rental.
  /// @param fuelPrice Representing fuel prices.
  /// @param startParams An array of uint64 values representing the initial parameters of the rental.
  /// @param endParams An array of uint64 values representing the final parameters of the rental.
  /// @param engineParams, represent the patrol engine params
  /// @param milesIncludedPerDay The number of miles included per day in the rental.
  /// @param pricePerDayInUsdCents The rental price per day in USD cents.
  /// @param tripDays The total number of days in the rental trip.
  /// @return The total resolve amount and the fuel-specific resolve amount in USD cents.
  function getResolveAmountInUsdCents(
    uint64 fuelPrice,
    uint64[] memory startParams,
    uint64[] memory endParams,
    uint64[] memory engineParams,
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
      getFuelResolveAmountInUsdCents(endParams[0], startParams[0], engineParams, fuelPrice)
    );
  }

  /// @notice Calculates the resolve amount in USD cents based on fuel consumption for a patrol car.
  /// @param endFuelLevelInPercents The final fuel level of the patrol car in percentages.
  /// @param startFuelLevelInPercents The initial fuel level of the patrol car in percentages.
  /// @param engineParams, represent the patrol engine params
  /// @param fuelPricePerGalInUsdCents The fuel price per gallon in USD cents.
  /// @return The fuel-specific resolve amount in USD cents.
  function getFuelResolveAmountInUsdCents(
    uint64 endFuelLevelInPercents,
    uint64 startFuelLevelInPercents,
    uint64[] memory engineParams,
    uint64 fuelPricePerGalInUsdCents
  ) public pure returns (uint64) {
    if (endFuelLevelInPercents >= startFuelLevelInPercents) return 0;
    uint priceFor10PercentsMultipliedOn1000 = ((engineParams[0] * fuelPricePerGalInUsdCents) * 1000) / 10;
    uint diffInPercents = startFuelLevelInPercents - endFuelLevelInPercents;

    return uint64(Math.ceilDiv(((priceFor10PercentsMultipliedOn1000 * diffInPercents) / 10), 1000));
  }
}
