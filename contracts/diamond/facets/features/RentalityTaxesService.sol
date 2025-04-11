
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

 import { UserServiceStorage } from "../../libraries/UserServiceStorage.sol";
 import { TaxesStorage } from "../../libraries/TaxesStorage.sol";
 import "../../../Schemas.sol";
 
 contract RentalityTaxes {

   function addTaxes(
    uint taxId,
    string memory location,
     Schemas.TaxValue[] memory taxes) public { 
           require(UserServiceStorage.isAdmin(msg.sender),"only Admin");
           TaxesStorage.addTaxes(taxId, location, taxes);
         }
 }