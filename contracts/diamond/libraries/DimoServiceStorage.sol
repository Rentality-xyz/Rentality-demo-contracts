// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Schemas } from "../../Schemas.sol";
import { LibDiamond } from "./LibDiamond.sol";
import { UserServiceStorage } from "./UserServiceStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library DimoServiceStorage { 
    struct DimoServiceFaucetStorage {
        mapping(uint => uint) carIdToDimoTokenId;
        uint[] dimoVihicles;
        }

    function saveDimoTokenId(uint dimoTokenId, uint carId, address user, bytes memory signature) internal {
        DimoServiceFaucetStorage storage ds = getDimoServiceFaucetStorage();
    bool isCorrectSignature = UserServiceStorage.isSignatureManager(
      ECDSA.recover(ECDSA.toEthSignedMessageHash(bytes(Strings.toString(dimoTokenId))), signature)
    );
    require(isCorrectSignature, 'dimo: wrong signature');

    carIdToDimoTokenId[carId] = dimoTokenId;
  }

  function saveButch(uint[] memory dimoTokenIds, uint[] memory carIds, address user) public {
    require(userService.isRentalityPlatform(msg.sender), 'only Rentality platform');
    require(dimoTokenIds.length == carIds.length, 'Wrong length');
    for (uint i = 0; i < dimoTokenIds.length; i++) {
      require(carToken.ownerOf(carIds[i]) == user, 'Not car owner');
      carIdToDimoTokenId[carIds[i]] = dimoTokenIds[i];
      dimoVihicles.push(dimoTokenIds[i]);
    }
  }
  function getDimoVehicles() public view returns (uint[] memory) {
    return dimoVihicles;
  }
  function getDimoTokenId(uint carId) public view returns (uint) {
    return carIdToDimoTokenId[carId];
  }

    
}