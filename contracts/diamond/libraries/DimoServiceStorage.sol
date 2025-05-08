// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Schemas } from "../../Schemas.sol";
import { LibDiamond } from "./LibDiamond.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library DimoServiceStorage { 
    struct DimoServiceFaucetStorage {
        mapping(uint => uint) carIdToDimoTokenId;
        uint[] dimoVihicles;
        }

    function saveDimoTokenId(uint dimoTokenId, uint carId) internal {
    DimoServiceFaucetStorage storage s = accessStorage();

    s.carIdToDimoTokenId[carId] = dimoTokenId;
  }

  function getDimoVehicles() internal view returns (uint[] memory) {
    return accessStorage().dimoVihicles;
  }
  function getDimoTokenId(uint carId) internal view returns (uint) {
    DimoServiceFaucetStorage storage s = accessStorage();
    return s.carIdToDimoTokenId[carId];
  }

    function accessStorage() internal pure returns (DimoServiceFaucetStorage storage ds) {
        bytes32 position = LibDiamond.DIMO_STORAGE_POSITION;
        assembly { ds.slot := position }
    }


    
}