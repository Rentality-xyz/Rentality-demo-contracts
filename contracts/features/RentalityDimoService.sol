// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../Schemas.sol';
import {UUPSAccess} from '../proxy/UUPSAccess.sol';
import {EIP712Upgradeable} from '@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import {RentalityCarToken} from '../RentalityCarToken.sol';
import {IRentalityAccessControl} from '../abstract/IRentalityAccessControl.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import {RentalityUserService} from '../RentalityUserService.sol';

/// @title Rentality Dimo integration service
contract RentalityDimoService is UUPSAccess, EIP712Upgradeable {
  mapping(uint => uint) private carIdToDimoTokenId;

  RentalityCarToken private carToken;

  uint[] private dimoVihicles;

  function saveDimoTokenId(uint dimoTokenId, uint carId, address user, bytes memory signature) public {
    if (dimoTokenId == 0) return require(userService.isManager(msg.sender), 'only Manager');
    require(carToken.ownerOf(carId) == user, 'Not car owner');

    bool isCorrectSignature = RentalityUserService(address(userService)).isSignatureManager(
      ECDSA.recover(ECDSA.toEthSignedMessageHash(bytes(Strings.toString(dimoTokenId))), signature)
    );
    require(isCorrectSignature, 'dimo: wrong signature');

    carIdToDimoTokenId[carId] = dimoTokenId;
  }

  function saveButch(uint[] memory dimoTokenIds, uint[] memory carIds) public {
    require(dimoTokenIds.length == carIds.length, 'Wrong length');
    for (uint i = 0; i < dimoTokenIds.length; i++) {
      require(carToken.ownerOf(carIds[i]) == tx.origin, 'Not car owner');
      carIdToDimoTokenId[carIds[i]] = dimoTokenIds[i];
      dimoVihicles.push(dimoTokenIds[i]);
    }
  }
  function getDimoVihicles() public view returns (uint[] memory) {
    return dimoVihicles;
  }
  function getDimoTokenId(uint carId) public view returns (uint) {
    return carIdToDimoTokenId[carId];
  }

  function initialize(address _userService, address _carToken, address _admin) public initializer {
    userService = IRentalityAccessControl(_userService);
    carToken = RentalityCarToken(_carToken);
  }
}
