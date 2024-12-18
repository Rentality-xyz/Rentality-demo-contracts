// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../../abstract/IRentalityAccessControl.sol';
import '../../Schemas.sol';
import {ARentalityRefferal} from './ARentalityRefferal.sol';

abstract contract ARentalityRefferalHasher is ARentalityRefferal {
  mapping(address => bytes32) public referralHash;
  mapping(bytes32 => address) private hashToOwner;
  mapping(Schemas.RefferalProgram => uint) internal selectorHashToPoints;

  function generateReferralHash() public {
    bytes32 hash = createReferralHash();
    hashToOwner[hash] = tx.origin;
    referralHash[tx.origin] = hash;
  }
  function hashExists(bytes32 hash) public view returns (bool) {
    return hashToOwner[hash] != address(0);
  }

  function createReferralHash() internal view returns (bytes32) {
    return keccak256(abi.encode(this.generateReferralHash.selector, tx.origin));
  }
  function manageRefHashesProgram(Schemas.RefferalProgram selector, uint points) public {
    require(getUserService().isManager(msg.sender), 'only Manager');
    selectorHashToPoints[selector] = points;
  }
  function _getHashProgramInfoIfExists(
    Schemas.RefferalProgram programSelector,
    bytes32 hash
  ) internal view returns (address, uint) {
    require(createReferralHash() != hash, 'own hash');
    (address resultAddress, uint resultPoints) = (address(0), 0);
    if (selectorHashToPoints[programSelector] > 0) {
      (resultAddress, resultPoints) = (hashToOwner[hash], selectorHashToPoints[programSelector]);
    }
    return (resultAddress, resultPoints);
  }
}
