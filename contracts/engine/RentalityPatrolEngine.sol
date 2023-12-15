// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ARentalityEngine.sol";

/// @title RentalityPatrolEngine - Implementation of a patrol engine in the Rentality system.
/// @notice This contract extends ARentalityEngine and adds functionality specific to patrol engines.
contract RentalityPatrolEngine is ARentalityEngine {

    // Struct to store patrol engine details.
    struct PatrolEngine {
        uint64 tankVolumeInGal;
        uint64 fuelPricePerGalInUsdCents;
    }

    // Mapping from car ID to patrol engine details.
    mapping(uint256 => PatrolEngine) private carIdToPatrolEngine;

    /// @notice Constructor to set the RentalityUserService address during deployment.
    constructor(address _userService) {
        userService = RentalityUserService(_userService);
    }

    /// @notice Sets the engine type. Only callable by an admin.
    /// @param _eType The new engine type to be set.
    function setEType(uint8 _eType) public override {
        require(userService.isAdmin(tx.origin), "only Admin.");
        eType = _eType;
    }

    /// @notice Adds a new patrol car to the system with specified tank volume and fuel price.
    /// @param carId The unique identifier of the patrol car.
    /// @param params An array of two uint64 values representing tank volume and fuel price.
    function addCar(uint256 carId, uint64[] memory params) public override onlyManager {
        isCorrectArgs((params[0] != 0 && params[1] != 0));

        PatrolEngine storage engine = carIdToPatrolEngine[carId];
        engine.tankVolumeInGal = params[0];
        engine.fuelPricePerGalInUsdCents = params[1];
    }

    /// @notice Updates the fuel price for an existing patrol car in the system.
    /// @param carId The unique identifier of the patrol car.
    /// @param params An array containing the new fuel price.
    /// @param params[0] The new fuel price per gallon in USD cents.
    function updateCar(uint256 carId, uint64[] memory params) public override onlyManager {
        isCorrectArgs(params[0] != 0);
        carIdToPatrolEngine[carId].fuelPricePerGalInUsdCents = params[0];
    }

    /// @notice Removes a patrol car from the system.
    /// @param carId The unique identifier of the patrol car to be removed.
    function burnCar(uint256 carId) public override onlyManager {
        delete carIdToPatrolEngine[carId];
    }

    /// @notice Returns zero extra costs for patrol cars.
    /// @param params An array of uint64 values representing parameters (not used for patrol engines).
    function extraCosts(uint64[] memory params) public pure override returns (uint64) {
        return 0;
    }

    /// @notice Retrieves patrol engine details for a specific patrol car.
    /// @param carId The unique identifier of the patrol car.
    function getEngineData(uint256 carId) public view returns (PatrolEngine memory) {
        return carIdToPatrolEngine[carId];
    }

    /// @notice Calculates the resolve amount in USD cents for a patrol car rental.
    /// @param fuelPrices An array of uint64 values representing fuel prices (not used for patrol engines).
    /// @param startParams An array of uint64 values representing the initial parameters of the rental.
    /// @param endParams An array of uint64 values representing the final parameters of the rental.
    /// @param carId The unique identifier of the patrol car.
    /// @param milesIncludedPerDay The number of miles included per day in the rental.
    /// @param pricePerDayInUsdCents The rental price per day in USD cents.
    /// @param tripDays The total number of days in the rental trip.
    /// @return The total resolve amount and the fuel-specific resolve amount in USD cents.
    function getResolveAmountInUsdCents(
        uint64[] memory fuelPrices,
        uint64[] memory startParams,
        uint64[] memory endParams,
        uint256 carId,
        uint64 milesIncludedPerDay,
        uint64 pricePerDayInUsdCents,
        uint64 tripDays
    ) public view override returns (uint64, uint64) {
        return (
            getDrivenMilesResolveAmountInUsdCents(
            startParams[1],
            endParams[1],
            milesIncludedPerDay,
            pricePerDayInUsdCents,
            tripDays
        ),
            getFuelResolveAmountInUsdCents(
            endParams[0],
            startParams[0],
            carIdToPatrolEngine[carId].tankVolumeInGal,
            fuelPrices[0]
        )
        );
    }

    /// @notice Calculates the resolve amount in USD cents based on fuel consumption for a patrol car.
    /// @param endFuelLevelInPercents The final fuel level of the patrol car in percentages.
    /// @param startFuelLevelInPercents The initial fuel level of the patrol car in percentages.
    /// @param tankVolume The tank volume of the patrol car in gallons.
    /// @param fuelPricePerGalInUsdCents The fuel price per gallon in USD cents.
    /// @return The fuel-specific resolve amount in USD cents.
    function getFuelResolveAmountInUsdCents(
        uint64 endFuelLevelInPercents,
        uint64 startFuelLevelInPercents,
        uint64 tankVolume,
        uint64 fuelPricePerGalInUsdCents
    ) public pure returns (uint64) {
        if (endFuelLevelInPercents >= startFuelLevelInPercents) return 0;

        return (
            (((startFuelLevelInPercents - endFuelLevelInPercents) * tankVolume ) * 1000 / 100)
            * fuelPricePerGalInUsdCents / 1000);
    }
}
