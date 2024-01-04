// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ARentalityEngine.sol";

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
        require(userService.isAdmin(tx.origin), "Only Admin.");
        eType = _eType;
    }

    /// @dev Verify patrol engine params
    /// @param params An array of four uint64 values representing charge price scales.
    function verifyCreateParams(uint64[] memory params) public view override {
        isCorrectArgs(params.length == 4);
    }

    /// @dev verify and return new electric engine data
    /// @param newParams An array of four uint64 values representing updated charge price scales.
    function verifyUpdateParams(uint64[] memory newParams, uint64[] memory/*oldParams*/)
    public view override returns(uint64[] memory) {
        isCorrectArgs(newParams.length == 4);

      return newParams;
    }


    /// @dev Returns zero extra costs for electric cars.
    function extraCosts(uint64[] memory /*params*/) public pure override returns (uint64) {
        return 0;
    }


    /// @dev Calculates the resolve amount in USD cents for an electric car rental.
    /// @param startParams An array of uint64 values representing the initial parameters of the rental.
    /// @param endParams An array of uint64 values representing the final parameters of the rental.
    /// @param engineParams represent electric engineParams
    /// @param milesIncludedPerDay The number of miles included per day in the rental.
    /// @param pricePerDayInUsdCents The rental price per day in USD cents.
    /// @param tripDays The total number of days in the rental trip.
    /// @return The total resolve amount and the fuel-specific resolve amount in USD cents.
    function getResolveAmountInUsdCents(
        uint64[] memory /*_fuelPrices*/,
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
            getFuelResolveAmountInUsdCents(endParams[0], engineParams)
        );
    }

    /// @dev Calculates the resolve amount in USD cents based on the remaining charge of an electric car.
    /// @param endFuelLevelInPercents The final fuel level of the electric car in percentages.
    /// @param engineParams represent electric engine type
    /// @return The fuel-specific resolve amount in USD cents.
    function getFuelResolveAmountInUsdCents(uint64 endFuelLevelInPercents, uint64[] memory engineParams)
    public
    pure
    returns (uint64)
    {
        if (endFuelLevelInPercents >= 0 && endFuelLevelInPercents <= 20) {
            return engineParams[0];
        } else if (
            endFuelLevelInPercents >= 21 && endFuelLevelInPercents <= 50
        ) {
            return engineParams[1];
        } else if (
            endFuelLevelInPercents >= 51 && endFuelLevelInPercents <= 80
        ) {
            return engineParams[2];
        }

        return engineParams[3];
    }
}
