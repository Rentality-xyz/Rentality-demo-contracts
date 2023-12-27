// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ARentalityEngine.sol";

/// @title RentalityElectricEngine - Implementation of an electric engine in the Rentality system.
/// @notice This contract extends ARentalityEngine and adds functionality specific to electric engines.
contract RentalityElectricEngine is ARentalityEngine {

    // Struct to store charge price scales in USD cents based on fuel level percentages.
    struct ChargePriceScaleInUsdCents {
        uint64 fromEmptyToTwenty;
        uint64 fromTwentyOneToFifty;
        uint64 fromFiftyOneToEighty;
        uint64 fromEightyOneToOneHundred;
    }

    // Mapping from car ID to electric engine charge price scales.
    mapping(uint256 => ChargePriceScaleInUsdCents) private carIdToElectricEngine;

    /// @dev Constructor to set the RentalityUserService address during deployment.
    constructor(address _userService) {
        userService = RentalityUserService(_userService);
    }

    /// @dev Sets the engine type. Only callable by an admin.
    /// @param _eType The new engine type to be set.
    function setEType(uint8 _eType) public override {
        require(userService.isAdmin(tx.origin), "Only Admin.");
        eType = _eType;
    }

    /// @dev Adds a new electric car to the system with charge price scales.
    /// @param carId The unique identifier of the electric car.
    /// @param params An array of four uint64 values representing charge price scales.
    function addCar(uint256 carId, uint64[] memory params) public override onlyManager {
        isCorrectArgs(params.length == 4);

        ChargePriceScaleInUsdCents storage engine = carIdToElectricEngine[carId];
        engine.fromEmptyToTwenty = params[0];
        engine.fromTwentyOneToFifty = params[1];
        engine.fromFiftyOneToEighty = params[2];
        engine.fromEightyOneToOneHundred = params[3];
    }

    /// @dev Updates charge price scales for an existing electric car in the system.
    /// @param carId The unique identifier of the electric car.
    /// @param params An array of four uint64 values representing updated charge price scales.
    function updateCar(uint256 carId, uint64[] memory params) public override onlyManager {
        isCorrectArgs(params.length == 4);

        carIdToElectricEngine[carId].fromEmptyToTwenty = params[0];
        carIdToElectricEngine[carId].fromTwentyOneToFifty = params[1];
        carIdToElectricEngine[carId].fromFiftyOneToEighty = params[2];
        carIdToElectricEngine[carId].fromEightyOneToOneHundred = params[3];
    }

    /// @dev Removes an electric car from the system.
    /// @param carId The unique identifier of the electric car to be removed.
    function burnCar(uint256 carId) public override onlyManager {
        delete carIdToElectricEngine[carId];
    }

    /// @dev Returns zero extra costs for electric cars.
    /// @param params An array of uint64 values representing parameters (not used for electric engines).
    function extraCosts(uint64[] memory params) public pure override returns (uint64) {
        return 0;
    }

    /// @dev Retrieves charge price scales for a specific electric car.
    /// @param carId The unique identifier of the electric car.
    function getEngineData(uint256 carId) public view returns (ChargePriceScaleInUsdCents memory) {
        return carIdToElectricEngine[carId];
    }

    /// @dev Calculates the resolve amount in USD cents for an electric car rental.
    /// @param _fuelPrices An array of uint64 values representing fuel prices (not used for electric engines).
    /// @param startParams An array of uint64 values representing the initial parameters of the rental.
    /// @param endParams An array of uint64 values representing the final parameters of the rental.
    /// @param carId The unique identifier of the electric car.
    /// @param milesIncludedPerDay The number of miles included per day in the rental.
    /// @param pricePerDayInUsdCents The rental price per day in USD cents.
    /// @param tripDays The total number of days in the rental trip.
    /// @return The total resolve amount and the fuel-specific resolve amount in USD cents.
    function getResolveAmountInUsdCents(
        uint64[] memory _fuelPrices,
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
            getFuelResolveAmountInUsdCents(endParams[0], carId)
        );
    }

    /// @dev Calculates the resolve amount in USD cents based on the remaining charge of an electric car.
    /// @param endFuelLevelInPercents The final fuel level of the electric car in percentages.
    /// @param carId The unique identifier of the electric car.
    /// @return The fuel-specific resolve amount in USD cents.
    function getFuelResolveAmountInUsdCents(uint64 endFuelLevelInPercents, uint256 carId)
    public
    view
    returns (uint64)
    {
        if (endFuelLevelInPercents >= 0 && endFuelLevelInPercents <= 20) {
            return carIdToElectricEngine[carId].fromEmptyToTwenty;
        } else if (
            endFuelLevelInPercents >= 21 && endFuelLevelInPercents <= 50
        ) {
            return carIdToElectricEngine[carId].fromTwentyOneToFifty;
        } else if (
            endFuelLevelInPercents >= 51 && endFuelLevelInPercents <= 80
        ) {
            return carIdToElectricEngine[carId].fromFiftyOneToEighty;
        }

        return carIdToElectricEngine[carId].fromEightyOneToOneHundred;
    }
}
