// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Schemas } from "../../Schemas.sol";
import { LibDiamond } from "./LibDiamond.sol";
import { RentalityEnginesService } from "../../engine/RentalityEnginesService.sol";
import {GeoServiceStorage} from "./GeoServiceStorage.sol";
import {CarTokenStorage} from "./CarTokenStorage.sol";

library TaxesStorage { 

    struct TaxesFaucetStorage {
        mapping(uint => Schemas.TaxValue[]) tripIdToTaxes;
        mapping(uint => Schemas.TaxValue[]) taxIdToTaxes;
        mapping(bytes32 => uint) taxesLocationHashToTaxId;
        
        uint defaultTax;
    }

    /// @notice Calculates the total taxes for a trip based on trip duration and total cost.
  /// @param tripDays The duration of the trip in days.
  /// @param totalCost The total cost of the trip.
  /// @return The total taxes for the trip.
  function calculateAndSaveTaxes(uint taxId, uint64 tripDays, uint64 totalCost, uint tripId) internal returns (uint64) {
   TaxesFaucetStorage storage s = accessStorage();
   Schemas.TaxValue[] memory values = s.taxIdToTaxes[taxId];
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
      s.tripIdToTaxes[tripId] = tripTaxes;
      return totalTax;
  }
   function calculateTaxes(uint taxId, uint64 tripDays, uint64 totalCost) internal view returns ( uint64 totalTax) {
      TaxesFaucetStorage storage s = accessStorage();
      Schemas.TaxValue[] memory values = s.taxIdToTaxes[taxId];
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

    function getTripTaxesDTO(uint tripId) internal view returns (Schemas.TaxValue[] memory) {
   TaxesFaucetStorage storage s = accessStorage();
   return s.tripIdToTaxes[tripId];
  }
   function calculateTaxesDTO(uint taxId, uint64 tripDays, uint64 totalCost) internal view returns ( uint64 totalTax, Schemas.TaxValue[] memory) {
       TaxesFaucetStorage storage s = accessStorage();
       Schemas.TaxValue[] memory values = s.taxIdToTaxes[taxId];
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

  function getTotalTripTax(uint tripId) internal view returns(uint64) {
      TaxesFaucetStorage storage s = accessStorage();
      Schemas.TaxValue[] memory values = s.tripIdToTaxes[tripId];
      uint64 totalTax = 0;
      for(uint i = 0; i < values.length; i++) 
          totalTax += values[i].value;

          return totalTax;
       }
  function getTaxesIdByHash(bytes32 hash) internal view returns(uint)
  { TaxesFaucetStorage storage s = accessStorage();
    return s.taxesLocationHashToTaxId[hash];
  }
  function addTaxes(
    uint taxId,
    string memory location,
     Schemas.TaxValue[] memory taxes
      ) internal {
        TaxesFaucetStorage storage s = accessStorage();
        bytes32 hash = keccak256(abi.encode(location));
        s.taxesLocationHashToTaxId[hash] = taxId;
        s.taxIdToTaxes[taxId] = taxes;
      }

  function taxExists(Schemas.LocationInfo memory locationInfo) internal view returns (uint) {
    bytes32 cityHash =  keccak256(abi.encode(locationInfo.city));
    bytes32 stateHash = keccak256(abi.encode(locationInfo.state));
    bytes32 countryHash = keccak256(abi.encode(locationInfo.country));

       uint taxId = getTaxesIdByHash(cityHash);
      if (taxId > 0) {
       return taxId;
      }
      taxId = getTaxesIdByHash(stateHash);
      if (taxId > 0) {
         return taxId;
      }
       taxId = getTaxesIdByHash(countryHash);
        if (taxId > 0) {
          return taxId;
        }
      

    return 0;
  }

   function defineTaxesType(uint carId) internal view returns (uint) {
    TaxesFaucetStorage storage s = accessStorage();
    bytes32 carLocationHash = CarTokenStorage.getCarInfoById(carId).locationHash;

    bytes32 cityHash = keccak256(abi.encode(GeoServiceStorage.getCarCity(carLocationHash)));
    bytes32 stateHash = keccak256(abi.encode(GeoServiceStorage.getCarState(carLocationHash)));
    bytes32 countryHash = keccak256(abi.encode(GeoServiceStorage.getCarCountry(carLocationHash)));

    uint taxId = getTaxesIdByHash(cityHash);
      if (taxId > 0) {
       return taxId;
      }
      taxId =  getTaxesIdByHash(stateHash);
      if (taxId > 0) {
         return taxId;
      }
       taxId =  getTaxesIdByHash(countryHash);
        if (taxId > 0) {
          return taxId;
        }
      

    return s.defaultTax;
  }

     function accessStorage() internal pure returns (TaxesFaucetStorage storage ds) {
        bytes32 position = LibDiamond.TAXES_STORAGE_POSITION;
        assembly { ds.slot := position }
    }

}