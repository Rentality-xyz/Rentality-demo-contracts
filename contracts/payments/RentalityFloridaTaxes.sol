// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../proxy/UUPSAccess.sol';
import './abstract/IRentalityTaxes.sol';
import '../Schemas.sol';

/// @title RentalityFloridaTaxes
/// @notice This contract implements tax calculation specific to the state of Florida.
contract RentalityFloridaTaxes is IRentalityTaxes, Initializable, UUPSAccess {
  Schemas.FloridaTaxes public taxes;

  /// @notice Retrieves the location hash and type for Florida taxes.
  /// @return The location hash for Florida and the taxes location type (State).
  function getLocation() public pure returns (bytes32, Schemas.TaxesLocationType) {
    return (keccak256(abi.encode('Florida')), Schemas.TaxesLocationType.State);
  }

  /// @notice Sets the taxes for Florida.
  /// @dev Only callable by an admin.
  /// @param newTaxes The new taxes data.
  function setTaxes(bytes memory newTaxes) public {
    require(userService.isAdmin(tx.origin), 'Only admin.');

    taxes = abi.decode(newTaxes, (Schemas.FloridaTaxes));
  }

  /// @notice Calculates the total taxes for a trip based on trip duration and total cost.
  /// @param tripDays The duration of the trip in days.
  /// @param totalCost The total cost of the trip.
  /// @return The total taxes for the trip.
  function calculateTaxes(uint64 tripDays, uint64 totalCost) public view returns (uint64) {
    return getSalesTaxFrom(totalCost) + getGovernmentTaxPerDayFrom(tripDays);
  }
  function calculateTaxesInPMM(uint64 tripDays, uint64 totalCost) public view returns (uint64) {
    return getSalesTaxFrom(totalCost * 1_000_000) + getGovernmentTaxPerDayFrom(tripDays) * 1_000_000;
  }

  /// @notice Retrieves the current sales tax in parts per million (PPM).
  /// @return The current sales tax in PPM.
  function getSalesTaxPPM() public view returns (uint32) {
    return taxes.salesTaxPPM;
  }

  /// @notice Calculates the sales tax from a given value.
  /// @param value The value from which to calculate the sales tax.
  /// @return The sales tax calculated from the given value.
  function getSalesTaxFrom(uint64 value) public view returns (uint64) {
    return (value * taxes.salesTaxPPM) / 1_000_000;
  }

  /// @notice Retrieves the government tax per day in USD cents.
  /// @return The current government tax per day.
  function getGovernmentTaxPerDay() public view returns (uint32) {
    return taxes.governmentTaxPerDayInUsdCents;
  }

  /// @notice Calculates the government tax per day from the given number of days.
  /// @param daysAmount The number of days.
  /// @return The government tax per day calculated from the given days.
  function getGovernmentTaxPerDayFrom(uint64 daysAmount) public view returns (uint64) {
    return uint64(taxes.governmentTaxPerDayInUsdCents) * daysAmount;
  }

  /// @notice Initializes the RentalityFloridaTaxes contract.
  /// @param _userService The address of the RentalityUserService contract.
  function initialize(address _userService) public initializer {
    userService = IRentalityAccessControl(_userService);

    taxes = Schemas.FloridaTaxes(70_000, 200); // Default tax values for Florida
  }
}
