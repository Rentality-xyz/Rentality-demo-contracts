// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../proxy/UUPSAccess.sol';
import './abstract/IRentalityTaxes.sol';
import '../Schemas.sol';

/// @title RentalityFloridaTaxes
/// @notice This contract implements tax calculation specific to the state of Florida.
contract RentalityPennsylvaniaTaxes is IRentalityTaxes, Initializable, UUPSAccess {
  Schemas.PennsylvaniaTaxes public taxes;
  mapping(uint => Schemas.PennsylvaniaTaxes) private tripIdToPennsylvaniaTaxes;

  /// @notice Retrieves the location hash and type for Florida taxes.
  /// @return The location hash for Florida and the taxes location type (State).
  function getLocation() public pure returns (bytes32, Schemas.TaxesLocationType) {
    return (keccak256(abi.encode('Pennsylvania')), Schemas.TaxesLocationType.State);
  }

  /// @notice Sets the taxes for Florida.
  /// @dev Only callable by an admin.
  /// @param newTaxes The new taxes data.
  function setTaxes(bytes memory newTaxes) public {
    require(userService.isAdmin(tx.origin), 'Only admin.');

    taxes = abi.decode(newTaxes, (Schemas.PennsylvaniaTaxes));
  }

   function calculateAndSaveTaxes(uint64 tripDays, uint64 totalCost, uint tripId) public returns (uint64) {
    uint64 salesTax = getSalesTaxFrom(totalCost);
    uint64 govTax = getGovernmentTaxPerDayFrom(tripDays);
    uint64 rentTax = getRentalTaxFrom(totalCost);
    tripIdToPennsylvaniaTaxes[tripId] = Schemas.PennsylvaniaTaxes(uint32(salesTax), uint32(govTax), uint32(rentTax));
    return salesTax + govTax + rentTax; 
  }
   function calculateTaxes(uint64 tripDays, uint64 totalCost) public view returns (uint64) {
    uint64 salesTax = getSalesTaxFrom(totalCost);
    uint64 govTax = getGovernmentTaxPerDayFrom(tripDays);
    uint64 rentTax = getRentalTaxFrom(totalCost);
    return salesTax + govTax + rentTax; 
  }

  function calculateTaxesDTO(uint64 tripDays, uint64 totalCost) public view returns (bytes memory data, string memory dataName, uint64 totalTax) {
    uint64 salesTax = getSalesTaxFrom(totalCost);
    uint64 govTax = getGovernmentTaxPerDayFrom(tripDays);
    uint64 rentTax = getRentalTaxFrom(totalCost);
    data = abi.encode(Schemas.PennsylvaniaTaxes(uint32(salesTax), uint32(govTax), uint32(rentTax)));
    totalTax = salesTax + govTax + rentTax;
    dataName = "PennsylvaniaTaxes";
  }

      function getTripTaxesDTO(uint tripId) public view returns (bytes memory data, string memory dataName, uint64 totalTax) {
   Schemas.PennsylvaniaTaxes memory pTaxes = tripIdToPennsylvaniaTaxes[tripId];
    data = abi.encode(pTaxes);
    totalTax = pTaxes.salesTaxPPM + pTaxes.governmentTaxPerDayInUsdCents + pTaxes.rentalTax;
    dataName = "FloridaTaxes";
  }
    function getTotalTripTax(uint tripId) public view returns(uint64) {
    Schemas.PennsylvaniaTaxes memory tripTaxes = tripIdToPennsylvaniaTaxes[tripId]; 
    return tripTaxes.salesTaxPPM + tripTaxes.governmentTaxPerDayInUsdCents + tripTaxes.rentalTax;
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

  function getRentalTaxFrom(uint64 value) public view returns(uint64) {
     return (value * taxes.rentalTax) / 1_000_000;
  }

  /// @notice Initializes the RentalityPennsylvaniaTaxes contract.
  /// @param _userService The address of the RentalityUserService contract.
  function initialize(address _userService) public initializer {
    userService = IRentalityAccessControl(_userService);

    taxes = Schemas.PennsylvaniaTaxes(60_000, 2 , 20_000); // Default tax values for Pennsylvania
  }
}
