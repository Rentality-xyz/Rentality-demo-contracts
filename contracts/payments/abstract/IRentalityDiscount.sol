// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRentalityDiscount {
  /// @notice Calculates the total cost with applied discount for a trip.
  /// @param daysOfTrip The duration of the trip in days.
  /// @param price The original price of the trip.
  /// @param user the address of discount provider
  /// @return The total cost after applying the discount.
  function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 price) external view returns (uint64);

  function calculateSumWithDiscountInPMM(address user, uint64 daysOfTrip, uint64 price) external view returns (uint64);

  /// @notice Sets the default discount values.
  /// @param newDiscounts The new discount data.
  function setDiscount(bytes memory newDiscounts) external;

  /// @notice Adds or updates a discount for a specific user.
  /// @param newDiscounts The new discount data.
  function addUserDiscount(bytes memory newDiscounts) external;

  /// @notice Retrieves the discount data for a specific user.
  /// @param userAddress The address of the user.
  /// @return The discount data.
  function getDiscount(address userAddress) external view returns (bytes memory);
}
