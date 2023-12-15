// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ARentalityEngine.sol";
import "../RentalityUserService.sol";

/// @title RentalityEnginesService - Manages different types of Rentality engines.
/// @notice This contract allows the addition, update, and interaction with various Rentality engines.
contract RentalityEnginesService {
    RentalityUserService private userService;
    uint8 private eTypeCounter = 1;
    mapping(uint8 => ARentalityEngine) private engineTypeToEngineContract;

    error Overflow();

    /// @notice Constructor to initialize the RentalityEnginesService contract.
    /// @param _userService The address of the RentalityUserService contract.
    /// @param engineServices An array of addresses representing existing engine contracts.
    constructor(address _userService, address[] memory engineServices) {
        if (engineServices.length >= type(uint8).max - 1) {
            revert Overflow();
        }

        for (uint256 i = 0; i < engineServices.length; i++) {
            engineTypeToEngineContract[eTypeCounter] = ARentalityEngine(engineServices[i]);
            engineTypeToEngineContract[eTypeCounter].setEType(eTypeCounter);
            eTypeCounter += 1;
        }
        userService = RentalityUserService(_userService);
    }

    /// @notice Modifier to restrict access to only administrators.
    modifier onlyAdmin() {
        require(userService.isAdmin(msg.sender), "Only for Admin.");
        _;
    }

    /// @notice Modifier to restrict access to only managers.
    modifier onlyManager() {
        require(userService.isManager(msg.sender), "Only for Manager.");
        _;
    }

    /// @notice Adds a new engine service contract to the system.
    /// @param engineService The address of the new engine service contract.
    function addEngineService(address engineService) public onlyAdmin {
        if (eTypeCounter == type(uint8).max - 1) {
            revert Overflow();
        }
        engineTypeToEngineContract[eTypeCounter] = ARentalityEngine(engineService);
        engineTypeToEngineContract[eTypeCounter].setEType(eTypeCounter);
        eTypeCounter += 1;
    }

    /// @notice Updates an existing engine service contract in the system.
    /// @param engineService The address of the updated engine service contract.
    /// @param eType The engine type associated with the contract.
    function updateEngineService(address engineService, uint8 eType) public onlyAdmin {
        engineTypeToEngineContract[eType] = ARentalityEngine(engineService);
    }

    /// @notice Retrieves the address of an engine contract based on its engine type.
    /// @param eType The engine type for which to retrieve the address.
    /// @return The address of the specified engine contract.
    function getEngineAddressById(uint8 eType) public view returns (address) {
        return address(engineTypeToEngineContract[eType]);
    }

    /// @notice Adds a new car to the system using a specific engine type.
    /// @param carId The unique identifier of the car.
    /// @param eType The engine type associated with the car.
    /// @param params An array of parameters required for adding the car.
    function addCar(uint256 carId, uint8 eType, uint64[] memory params) public onlyManager {
        engineTypeToEngineContract[eType].addCar(carId, params);
    }

    /// @notice Updates an existing car in the system using a specific engine type.
    /// @param carId The unique identifier of the car.
    /// @param eType The engine type associated with the car.
    /// @param params An array of parameters required for updating the car.
    function updateCar(uint256 carId, uint8 eType, uint64[] memory params) public onlyManager {
        engineTypeToEngineContract[eType].updateCar(carId, params);
    }

    /// @notice Removes a car from the system using a specific engine type.
    /// @param carId The unique identifier of the car.
    /// @param eType The engine type associated with the car.
    function burnCar(uint256 carId, uint8 eType) public onlyManager {
        engineTypeToEngineContract[eType].burnCar(carId);
    }

    /// @notice Verifies resource prices for a specific engine type.
    /// @param prices An array of uint64 values representing resource prices.
    /// @param eType The engine type for which to verify the resource prices.
    function verifyResourcePrice(uint64[] memory prices, uint8 eType) public view {
        engineTypeToEngineContract[eType].verifyResourcePrice(prices);
    }

    /// @notice Verifies the start parameters for a specific engine type.
    /// @param params An array of uint64 values representing start parameters.
    /// @param eType The engine type for which to verify the start parameters.
    function verifyStartParams(uint64[] memory params, uint8 eType) public {
        engineTypeToEngineContract[eType].verifyStartParams(params);
    }

    /// @notice Verifies the end parameters for a specific engine type.
    /// @param startParams An array of uint64 values representing start parameters.
    /// @param endParams An array of uint64 values representing end parameters.
    /// @param eType The engine type for which to verify the end parameters.
    function verifyEndParams(uint64[] memory startParams, uint64[] memory endParams, uint8 eType) public {
        engineTypeToEngineContract[eType].verifyEndParams(startParams, endParams);
    }

    /// @notice Compares parameters for a specific engine type.
    /// @param startParams An array of uint64 values representing start parameters.
    /// @param endParams An array of uint64 values representing end parameters.
    /// @param eType The engine type for which to compare the parameters.
    function compareParams(uint64[] memory startParams, uint64[] memory endParams, uint8 eType) public view {
        engineTypeToEngineContract[eType].compareParams(startParams, endParams);
    }

    /// @notice Retrieves the number of parameters expected by the panel for a specific engine type.
    /// @param eType The engine type for which to get the panel parameters amount.
    /// @return The number of parameters expected by the panel.
    function getPanelParamsAmount(uint8 eType) public returns (uint256) {
        return engineTypeToEngineContract[eType].getParamsAmount();
    }

    /// @notice Computes extra costs for a specific engine type.
    /// @param eType The engine type for which to compute extra costs.
    /// @param params An array of uint64 values representing parameters.
    /// @return The computed extra costs in USD cents.
    function extraCosts(uint8 eType, uint64[] memory params) public returns (uint64) {
        return engineTypeToEngineContract[eType].extraCosts(params);
    }

    /// @notice Computes the resolve amount in USD cents for a specific engine type and car rental.
    /// @param engineType The engine type associated with the car.
    /// @param fuelPrices An array of uint64 values representing fuel prices.
    /// @param startParams An array of uint64 values representing the initial parameters of the rental.
    /// @param endParams An array of uint64 values representing the final parameters of the rental.
    /// @param carId The unique identifier of the car.
    /// @param milesIncludedPerDay The number of miles included per day in the rental.
    /// @param pricePerDayInUsdCents The rental price per day in USD cents.
    /// @param tripDays The total number of days in the rental trip.
    /// @return The total resolve amount and the fuel-specific resolve amount in USD cents.
    function getResolveAmountInUsdCents(
        uint8 engineType,
        uint64[] memory fuelPrices,
        uint64[] memory startParams,
        uint64[] memory endParams,
        uint256 carId,
        uint64 milesIncludedPerDay,
        uint64 pricePerDayInUsdCents,
        uint64 tripDays
    ) public returns (uint64, uint64) {
        return engineTypeToEngineContract[engineType].getResolveAmountInUsdCents(
            fuelPrices,
            startParams,
            endParams,
            carId,
            milesIncludedPerDay,
            pricePerDayInUsdCents,
            tripDays);
    }
}
