// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../../abstract/IRentalityAccessControl.sol';
import '../../Schemas.sol';
import {ARentalityRefferal} from './ARentalityRefferal.sol';

abstract contract ARentalityRefferalHasher is ARentalityRefferal {
  mapping(address => bytes32) public referralHash; //unused
  mapping(bytes32 => address) private hashToOwner; // unused
  mapping(Schemas.RefferalProgram => uint) internal selectorHashToPoints;

  mapping(address => bytes4) internal userToSavedHash;
    mapping(address => bytes4) public referralHashV2; 
  mapping(bytes4 => address) private hashToOwnerV2; 

  function generateReferralHash() public {
    bytes4 hash = createReferralHash();
    hashToOwnerV2[hash] = tx.origin;
    referralHashV2[tx.origin] = hash;
  }
  function hashExists(bytes4 hash) public view returns (bool) {
    return hashToOwner[hash] != address(0);
  }

  function createReferralHash() internal view returns (bytes4) {
    return bytes4(keccak256(abi.encode(this.generateReferralHash.selector, tx.origin)));
  }
  function manageRefHashesProgram(Schemas.RefferalProgram selector, uint points) public {
    require(getUserService().isManager(msg.sender), 'only Manager');
    selectorHashToPoints[selector] = points;
  }
  function getMyRefferalInfo() public view returns(Schemas.MyRefferalInfoDTO memory) {
    return Schemas.MyRefferalInfoDTO(referralHashV2[msg.sender], userToSavedHash[msg.sender]);
  }
  function saveRefferalHash(bytes4 hash) public {
    userToSavedHash[msg.sender] = hash;
  }
  function _getHashProgramInfoIfExists(
    Schemas.RefferalProgram programSelector,
    bytes4 hash
  ) internal view returns (address, uint) {
    require(createReferralHash() != hash, 'own hash');
    (address resultAddress, uint resultPoints) = (address(0), 0);
    if (selectorHashToPoints[programSelector] > 0) {
      (resultAddress, resultPoints) = (hashToOwnerV2[hash], selectorHashToPoints[programSelector]);
    }
    return (resultAddress, resultPoints);
  }
}
