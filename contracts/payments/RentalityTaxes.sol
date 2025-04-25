// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../proxy/UUPSAccess.sol';
import './abstract/IRentalityTaxes.sol';
import '../Schemas.sol';
import '../RentalityTripService.sol';


/// @title RentalityTaxes
/// @notice This contract implements tax calculation specific to the state of Florida.
contract RentalityTaxes is Initializable, UUPSAccess {
  mapping(uint => Schemas.TaxValue[]) private tripIdToTaxes;
  mapping(uint => Schemas.TaxValue[]) private taxIdToTaxes;

  mapping(bytes32 => uint) private taxesLocationHashToTaxId;

  mapping(uint => Schemas.TaxesLocationType) private taxIdToLocationType;



  /// @notice Retrieves the location hash and type for Florida taxes.
  /// @return The location hash for Florida and the taxes location type (State).
  // function getLocation(uint taxId) public view returns (bytes32, Schemas.TaxesLocationType) {
  //  Schemas.TaxesData memory taxesData = tripIdToTaxes[taxId];
  //   return (taxesData.locationHash, taxesData.locationType);
  // }

 

  /// @notice Calculates the total taxes for a trip based on trip duration and total cost.
  /// @param tripDays The duration of the trip in days.
  /// @param totalCost The total cost of the trip.
  /// @return The total taxes for the trip.
  function calculateAndSaveTaxes(uint taxId, uint64 tripDays, uint64 totalCost, uint tripId) public returns (uint64) {
    require(userService.isRentalityPlatform(msg.sender), "only Rentality platform");
   Schemas.TaxValue[] memory values = taxIdToTaxes[taxId];
   Schemas.TaxValue[] memory tripTaxes = new Schemas.TaxValue[](values.length);
      uint64 totalTax = 0;
      for(uint i = 0; i < values.length; i++) {
        uint64 currentTax = 0;
        if(values[i].tType == Schemas.TaxesType.PPM) {
           currentTax = totalCost * values[i].value / 1_000_000;
     
        }
        else if(values[i].tType == Schemas.TaxesType.InUsdCents) {
          currentTax = values[i].value;
        }
        else if(values[i].tType == Schemas.TaxesType.InUsdCentsPerDay) {
           currentTax = tripDays * values[i].value;
        }
             totalTax += currentTax;
          tripTaxes[i] = values[i];
          tripTaxes[i].tType = Schemas.TaxesType.InUsdCents;
          tripTaxes[i].value = uint32(currentTax);
      }
      tripIdToTaxes[tripId] = tripTaxes;
      return totalTax;
  }
   function calculateTaxes(uint taxId, uint64 tripDays, uint64 totalCost) public view returns ( uint64 totalTax) {
      Schemas.TaxValue[] memory values = taxIdToTaxes[taxId];
      totalTax = 0;
      for(uint i = 0; i < values.length; i++) {
        if(values[i].tType == Schemas.TaxesType.PPM) {
          totalTax += totalCost * values[i].value / 1_000_000;
        }
        else if(values[i].tType == Schemas.TaxesType.InUsdCents) {
          totalTax += values[i].value;
        }
        else if(values[i].tType == Schemas.TaxesType.InUsdCentsPerDay) {
           totalTax += tripDays * values[i].value;
        }
      }
  }

    function getTripTaxesDTO(uint tripId) public view returns (Schemas.TaxValue[] memory) {
   return tripIdToTaxes[tripId];
  }
   function calculateTaxesDTO(uint taxId, uint64 tripDays, uint64 totalCost) public view returns ( uint64 totalTax, Schemas.TaxValue[] memory) {
       Schemas.TaxValue[] memory values = taxIdToTaxes[taxId];
         Schemas.TaxValue[] memory returnValues = new Schemas.TaxValue[](values.length);
      totalTax = 0;
      for(uint i = 0; i < values.length; i++) {
         uint64 currentTax = 0;
        if(values[i].tType == Schemas.TaxesType.PPM) {
          currentTax = totalCost * values[i].value / 1_000_000;
          totalTax += currentTax;
        }
        else if(values[i].tType == Schemas.TaxesType.InUsdCents) {
          currentTax = values[i].value;
          totalTax += currentTax;
        }
        else if(values[i].tType == Schemas.TaxesType.InUsdCentsPerDay) {
          currentTax = tripDays * values[i].value;
           totalTax += currentTax;
        }
        returnValues[i] = Schemas.TaxValue(
          values[i].name,
          uint32(currentTax),
          Schemas.TaxesType.InUsdCents
        );
      }
  return (totalTax, returnValues);
  }

  function getTotalTripTax(uint tripId) public view returns(uint64) {
      Schemas.TaxValue[] memory values = tripIdToTaxes[tripId];
      uint64 totalTax = 0;
      for(uint i = 0; i < values.length; i++) 
          totalTax += values[i].value;

          return totalTax;
       }
  function getTaxesIdByHash(bytes32 hash) public view returns(uint, Schemas.TaxesLocationType) {
    uint taxId = taxesLocationHashToTaxId[hash];
    Schemas.TaxesLocationType locationType = taxIdToLocationType[taxId];
    return (taxId, locationType);
  }
 
  function addTaxes(
    uint taxId,
    string memory location,
    Schemas.TaxesLocationType locationType,
     Schemas.TaxValue[] memory taxes
      ) public {
        require(userService.isAdmin(tx.origin),"only Admin");
        bytes32 hash = keccak256(abi.encode(location));
        taxesLocationHashToTaxId[hash] = taxId;
        taxIdToTaxes[taxId] = taxes;
        taxIdToLocationType[taxId] = locationType;
      }

   
      function migration(RentalityTripService tripService, uint from, uint to) public {
        if (from == 0) {
          from = 1;
        }
        uint totalTrips = tripService.totalTripCount();
        if(to > totalTrips) {
          to = totalTrips;
        }
        for (uint i = from; i <= to; i++) {
          Schemas.PaymentInfo memory paymentInfo = tripService.getTrip(i).paymentInfo;
          Schemas.TaxValue[] memory taxes = new Schemas.TaxValue[](2);
          taxes[0] = Schemas.TaxValue(
            'salesTax',
            uint32(paymentInfo.salesTax),
            Schemas.TaxesType.InUsdCents
          );
             taxes[1] = Schemas.TaxValue(
            'governmentTax',
            uint32(paymentInfo.governmentTax),
            Schemas.TaxesType.InUsdCents
          );
           tripIdToTaxes[i] = taxes;
        }
      }


  /// @notice Initializes the RentalityFloridaTaxes contract.
  /// @param _userService The address of the RentalityUserService contract.
  function initialize(address _userService) public initializer {
    userService = IRentalityAccessControl(_userService);

  }
}