// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../../abstract/IRentalityAccessControl.sol';
import '../../Schemas.sol';
import {ARentalityRefferal} from './ARentalityRefferal.sol';

abstract contract ARentalityRefferalHasher is ARentalityRefferal {
  mapping(address => bytes32) public referralHash; //unused
  mapping(bytes32 => address) private hashToOwner; // unused
  mapping(Schemas.RefferalProgram => uint) internal selectorHashToPoints;

  function manageRefHashesProgram(Schemas.RefferalProgram selector, uint points) public {
    require(getUserService().isRentalityPlatform(msg.sender), 'only Rentality platform');
    selectorHashToPoints[selector] = points;
  }
}
