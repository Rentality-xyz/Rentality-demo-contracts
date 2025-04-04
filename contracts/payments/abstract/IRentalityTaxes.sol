// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../../Schemas.sol';

/// @title IRentalityTaxes
/// @notice This interface defines the functions for managing taxes in the Rentality platform.
interface IRentalityTaxes {
  /// @notice Calculates the taxes for a given trip duration and total cost.
  /// @param tripDays The duration of the trip in days.
  /// @param totalCost The total cost of the trip.
  /// @return The calculated taxes.
  function calculateAndSaveTaxes(uint64 tripDays, uint64 totalCost, uint tripId) external returns (uint64);

  function calculateTaxes(uint64 tripDays, uint64 totalCost) external view returns (uint64);

  
  function calculateTaxesDTO(uint64 tripDays, uint64 totalCost) external view returns (bytes memory data, string memory dataType, uint64);

  function getTripTaxesDTO(uint tripId) external view returns (bytes memory data, string memory dataType, uint64);
  /// @notice Sets the taxes data.
  /// @dev Only callable by an admin.
  /// @param newTaxes The new taxes data.
  function setTaxes(bytes memory newTaxes) external;

  /// @notice Retrieves the location and type of taxes.
  /// @return The location hash and type of taxes.
  function getLocation() external pure returns (bytes32, Schemas.TaxesLocationType);

  function getTotalTripTax(uint tripId) external view returns(uint64);
}
