// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../../abstract/IRentalityAccessControl.sol';
import '../../Schemas.sol';
import {ARentalityRefferal} from './ARentalityRefferal.sol';

abstract contract ARentalityRefferalTear is ARentalityRefferal {
  // IRentalityAccessControl internal userService;
  mapping(Schemas.Tear => Schemas.TearPoints) private tearTypeToTearPoints;

  function manageTearInfo(Schemas.Tear tear, uint from, uint to) public {
    require(getUserService().isManager(msg.sender), 'only Manager');
    tearTypeToTearPoints[tear] = Schemas.TearPoints(from, to);
  }

  function getTearTypeByPoints(uint points) public view returns (Schemas.Tear) {
    for (uint i = 0; i <= uint(type(Schemas.Tear).max); i++) {
      Schemas.TearPoints memory tear = tearTypeToTearPoints[Schemas.Tear(i)];
      if (tear.from <= points && tear.to >= points) return Schemas.Tear(i);
    }
    /// unreachable
    return Schemas.Tear(0);
  }
  function getAllTearsInfo() public view returns (Schemas.TearDTO[] memory) {
    Schemas.TearDTO[] memory tears = new Schemas.TearDTO[](uint(type(Schemas.Tear).max) + 1);
    for (uint i = 0; i <= uint(type(Schemas.Tear).max); i++) {
      Schemas.Tear tear = Schemas.Tear(i);
      tears[i] = Schemas.TearDTO(tearTypeToTearPoints[tear], tear);
    }
    return tears;
  }
}
