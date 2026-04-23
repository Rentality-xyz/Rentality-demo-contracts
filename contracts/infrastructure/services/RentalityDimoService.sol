// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '../upgradeable/UUPSOwnable.sol';

interface IRentalityDimoAccess {
  function isRentalityPlatform(address user) external view returns (bool);
  function isSignatureManager(address user) external view returns (bool);
}

interface IRentalityDimoCar {
  function ownerOf(uint256 carId) external view returns (address);
}

contract RentalityDimoService is EIP712Upgradeable, UUPSOwnable {
  mapping(uint256 => uint256) private carIdToDimoTokenId;
  uint256[] private dimoVehicles;
  IRentalityDimoAccess private userAccess;
  IRentalityDimoCar private carToken;

  constructor() {
    _disableInitializers();
  }

  function initialize(address userAccessAddress, address carTokenAddress) public initializer {
    __Ownable_init();
    __EIP712_init('RentalityDimoService', '1');
    userAccess = IRentalityDimoAccess(userAccessAddress);
    carToken = IRentalityDimoCar(carTokenAddress);
  }

  function saveDimoTokenId(uint256 dimoTokenId, uint256 carId, address user, bytes memory signature) public {
    require(userAccess.isRentalityPlatform(msg.sender), 'only Rentality platform');
    if (dimoTokenId == 0) {
      return;
    }
    require(carToken.ownerOf(carId) == user, 'Not car owner');
    address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(bytes(Strings.toString(dimoTokenId))), signature);
    require(userAccess.isSignatureManager(signer), 'dimo: wrong signature');
    carIdToDimoTokenId[carId] = dimoTokenId;
  }

  function saveButch(uint256[] memory dimoTokenIds, uint256[] memory carIds, address user) public {
    require(userAccess.isRentalityPlatform(msg.sender), 'only Rentality platform');
    require(dimoTokenIds.length == carIds.length, 'Wrong length');
    for (uint256 i = 0; i < dimoTokenIds.length; i++) {
      require(carToken.ownerOf(carIds[i]) == user, 'Not car owner');
      carIdToDimoTokenId[carIds[i]] = dimoTokenIds[i];
      dimoVehicles.push(dimoTokenIds[i]);
    }
  }

  function getDimoVehicles() public view returns (uint256[] memory) {
    return dimoVehicles;
  }

  function getDimoTokenId(uint256 carId) public view returns (uint256) {
    return carIdToDimoTokenId[carId];
  }
}
