// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../Schemas.sol';
import {UUPSAccess} from '../proxy/UUPSAccess.sol';
import {EIP712Upgradeable} from '@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import {RentalityCarToken} from '../RentalityCarToken.sol';
import {IRentalityAccessControl} from '../abstract/IRentalityAccessControl.sol'; 



/// @title Rentality Dimo integration service
contract RentalityDimoService is UUPSAccess, EIP712Upgradeable {
 
 mapping(uint => uint) private carIdToDimoTokenId;

 
 RentalityCarToken private carToken;
 address private adminAddress;


  function verifySignedLocationInfo(Schemas.SignedLocationInfo memory locationInfo) public view {
    require(_verify(locationInfo) == adminAddress, 'Wrong signature');
  }

  function _verify(Schemas.SignedLocationInfo memory location) internal view returns (address) {
    // bytes32 digest = _hash(location.locationInfo);
    return address(0);
    // return ECDSA.recover(digest, location.signature);
  }
  function verify(Schemas.SignedLocationInfo memory location) public view returns (address) {
    // bytes32 digest = _hash(location.locationInfo);
    // return ECDSA.recover(digest, location.signature);
    return address(0);
  }

  function _hash() internal view returns (bytes32) {
    return bytes32('');
    // return
    //   _hashTypedDataV4(
    //     keccak256(
    //       abi.encode(
    //         keccak256(
    //           'DimoData(uint tokenId,string vinNumber)'
    //         ),
    //         data.tokeId,
    //         keccak256(bytes(data.vinNumber))
    //       )
    //     )
    //   );
  }

function saveDimoTokenIds(Schemas.DimoTokensData[] memory tokensData) public {
    for (uint i = 0; i < tokensData.length; i++) {
        carIdToDimoTokenId[tokensData[i].rentalityTokenId] = tokensData[i].dimoTokenId;
    }
}
function getDimoTokenId(uint carId) public view returns(uint) {
       return carIdToDimoTokenId[carId];
}

  function initialize(address _userService, address _carToken, address _admin) public initializer {
    userService = IRentalityAccessControl(_userService);
    carToken = RentalityCarToken(_carToken);
    adminAddress = _admin;
  }
}
