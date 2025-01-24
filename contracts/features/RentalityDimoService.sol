// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../Schemas.sol';
import {UUPSAccess} from '../proxy/UUPSAccess.sol';
import {EIP712Upgradeable} from '@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import {RentalityCarToken} from '../RentalityCarToken.sol';
import {IRentalityAccessControl} from '../abstract/IRentalityAccessControl.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import "@openzeppelin/contracts/utils/Strings.sol";



/// @title Rentality Dimo integration service
contract RentalityDimoService is UUPSAccess, EIP712Upgradeable {
 
 mapping(uint => uint) private carIdToDimoTokenId;

 
 RentalityCarToken private carToken;

uint[] private dimoVihicles;

function saveDimoTokenId(uint dimoTokenId, uint carId, bytes memory signature) public {
        require(carToken.ownerOf(carId) == tx.origin, "Not car owner");
        bool isTCPassed = ECDSA.recover(TCMessageHash, TCSignature) == tx.origin;
        carIdToDimoTokenId[carId] = dimoTokenId;
}
function verifySignature(bytes memory signature, uint dimoToken) public view {
   bool isCorrectSignature = ECDSA.recover(Strings.toString(dimoToken), signature) == tx.origin;
  
}
function saveButch(uint[] memory dimoTokenIds, uint[] memory carIds) public {
  require(dimoTokenIds.length == carIds.length, "Wrong length");
  for (uint i = 0; i < dimoTokenIds.length; i++) {
      require(carToken.ownerOf(carIds[i]) == tx.origin, "Not car owner");
        carIdToDimoTokenId[carIds[i]] = dimoTokenIds[i];
       dimoVihicles.push(dimoTokenIds[i]);
  }
}
function getDimoVihicles() public view returns(uint[] memory) {
  return dimoVihicles;
}
function getDimoTokenId(uint carId) public view returns(uint) {
       return carIdToDimoTokenId[carId];
}

  function initialize(address _userService, address _carToken, address _admin) public initializer {
    userService = IRentalityAccessControl(_userService);
    carToken = RentalityCarToken(_carToken);
  }
}
