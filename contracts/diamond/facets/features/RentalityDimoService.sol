// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DimoServiceStorage} from "../../libraries/DimoServiceStorage.sol";
import {CarTokenStorage} from "../../libraries/CarTokenStorage.sol";
contract RentalityDimoServiceFacet {

  function getDimoVihicles() external view returns (uint[] memory dimoVihicles){
    DimoServiceStorage.DimoServiceFaucetStorage storage s = DimoServiceStorage.accessStorage();
    return s.dimoVihicles;

  }
  function saveDimoTokenIds(uint[] memory dimoTokenIds, uint[] memory carIds) public {
    for (uint i = 0; i < dimoTokenIds.length; i++) {
        require(CarTokenStorage.ownerOf(carIds[i]) == msg.sender, "only car owner");
        DimoServiceStorage.saveDimoTokenId(dimoTokenIds[i], carIds[i]);
    }
  }
}