// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import './ARentalityEngine.sol';
import '../proxy/UUPSAccess.sol';

/// @title RentalityEnginesService - Manages different types of Rentality engines.
/// @notice This contract allows the addition, update, and interaction with various Rentality engines.
contract RentalityEnginesService is Initializable, UUPSAccess {
  uint8 private eTypeCounter;
  mapping(uint8 => ARentalityEngine) private engineTypeToEngineContract;

  error Overflow();

  /// @notice Constructor to initialize the RentalityEnginesService contract.
  /// @param _userService The address of the RentalityUserService contract.
  /// @param engineServices An array of addresses representing existing engine contracts.

  /// @notice Modifier to restrict access to only administrators.
  modifier onlyAdmin() {
    require(userService.isAdmin(msg.sender), 'Only for Admin.');
    _;
  }

  /// @notice Modifier to restrict access to only managers.
  modifier onlyManager() {
    // require(userService.isManager(msg.sender), 'Only for Manager.');
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
  /// @param eType The engine type for which to retrieve the address
  /// @return The address of the specified engine contract.
  function getEngineAddressById(uint8 eType) public view returns (address) {
    return address(engineTypeToEngineContract[eType]);
  }

  /// @notice Retrieves the fuel prices based on the engine type and engine parameters.
  /// @param eType The engine type for which fuel prices are requested.
  /// @param engineParams The array of engine parameters used to retrieve fuel prices.
  /// @return A fuel price corresponding to the provided engine parameters.
  function getFuelPriceFromEngineParams(uint8 eType, uint64[] memory engineParams) public view returns (uint64) {
    return engineTypeToEngineContract[eType].getFuelPriceFromEngineParams(engineParams);
  }

  /// @notice Verify engine params
  /// @param eType The engine type associated with the car.
  /// @param params An array of parameters required for adding the car.
  function verifyCreateParams(uint8 eType, uint64[] memory params) public view onlyManager {
    engineTypeToEngineContract[eType].verifyCreateParams(params);
  }

  /// @notice Verify end return engine params
  /// @param eType The engine type associated with the car.
  /// @param newParams An array of new parameters required for updating the car.
  /// @param oldParams An array of old engine params
  function verifyUpdateParams(
    uint8 eType,
    uint64[] memory newParams,
    uint64[] memory oldParams
  ) public view onlyManager returns (uint64[] memory) {
    return engineTypeToEngineContract[eType].verifyUpdateParams(newParams, oldParams);
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
  function getPanelParamsAmount(uint8 eType) public view returns (uint256) {
    return engineTypeToEngineContract[eType].getParamsAmount();
  }

  function isEmptyParams(uint8 eType, uint64[] memory params) public view returns (bool) {
    return engineTypeToEngineContract[eType].isEmptyParams(params);
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
  /// @param fuelPrice Representing fuel prices.
  /// @param startParams An array of uint64 values representing the initial parameters of the rental.
  /// @param endParams An array of uint64 values representing the final parameters of the rental.
  /// @param engineParams represent engine params
  /// @param milesIncludedPerDay The number of miles included per day in the rental.
  /// @param pricePerDayInUsdCents The rental price per day in USD cents.
  /// @param tripDays The total number of days in the rental trip.
  /// @return The total resolve amount and the fuel-specific resolve amount in USD cents.
  function getResolveAmountInUsdCents(
    uint8 engineType,
    uint64 fuelPrice,
    uint64[] memory startParams,
    uint64[] memory endParams,
    uint64[] memory engineParams,
    uint64 milesIncludedPerDay,
    uint64 pricePerDayInUsdCents,
    uint64 tripDays
  ) public view returns (uint64, uint64) {
    return
      engineTypeToEngineContract[engineType].getResolveAmountInUsdCents(
        fuelPrice,
        startParams,
        endParams,
        engineParams,
        milesIncludedPerDay,
        pricePerDayInUsdCents,
        tripDays
      );
  }

  function initialize(address _userService, address[] memory engineServices) public virtual initializer {
    if (engineServices.length >= type(uint8).max - 1) {
      revert Overflow();
    }
    userService = IRentalityAccessControl(_userService);
    eTypeCounter = 1;

    for (uint256 i = 0; i < engineServices.length; i++) {
      engineTypeToEngineContract[eTypeCounter] = ARentalityEngine(engineServices[i]);
      engineTypeToEngineContract[eTypeCounter].setEType(eTypeCounter);
      eTypeCounter += 1;
    }
  }
}
