// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../../abstract/IRentalityAccessControl.sol';
import '../../Schemas.sol';
import {ARentalityRefferal} from './ARentalityRefferal.sol';

struct Points {
  bytes4 callback;
  int points;
  int pointsWithRefferalCode;
}

abstract contract ARentalityRefferalPointsSetter is ARentalityRefferal {
  address internal refferalLib;

  mapping(Schemas.RefferalProgram => mapping(address => bool)) private selectorToPassedAddress;
  mapping(Schemas.RefferalProgram => Points) internal selectorToPoints;
  mapping(Schemas.RefferalProgram => Points) internal permanentSelectorToPoints;

  mapping(address => uint) internal addressToLastDailyClaim;

  mapping(uint => uint) internal carIdToListedClaimTime;

  function updateDaily(address user) public returns (uint) {
    uint result = 0;
    uint last = addressToLastDailyClaim[user];
    uint current = block.timestamp;
    if (current >= last + 1 days) {
      addressToLastDailyClaim[user] = block.timestamp;
      result = uint(permanentSelectorToPoints[Schemas.RefferalProgram.Daily].points);
    }
    return result;
  }
  function _checkDaily(address user) internal view returns (uint) {
    uint result = 0;
    uint last = addressToLastDailyClaim[user];
    uint current = block.timestamp;
    if (current >= last + 1 days) {
      result = uint(permanentSelectorToPoints[Schemas.RefferalProgram.Daily].points);
    }
    return result;
  }
  function addPermanentProgram(Schemas.RefferalProgram selector, int points, bytes4 calback) public {
    require(getUserService().isManager(msg.sender), 'only Manager');

    Points storage oldPoints = permanentSelectorToPoints[selector];

    oldPoints.callback = calback;
    oldPoints.points = points;
  }
  function addOneTimeProgram(Schemas.RefferalProgram selector, int points, int refPoints, bytes4 calback) public {
    require(getUserService().isManager(msg.sender), 'only Manager');
    Points storage oldPoints = selectorToPoints[selector];

    oldPoints.callback = calback;
    oldPoints.points = points;
    oldPoints.pointsWithRefferalCode = refPoints;
  }

  function _setPassedIfExists(
    Schemas.RefferalProgram selector,
    bytes memory callbackArgs,
    bool hasRefferalCode,
    address user
  ) internal returns (int, bool) {
    Points memory points = selectorToPoints[selector];

    bool isOneTime = true;
    if (points.points != 0) {
      bool passed = selectorToPassedAddress[selector][user];
      if (passed) {
        points = permanentSelectorToPoints[selector];
        isOneTime = false;
      } else {
        selectorToPassedAddress[selector][user] = true;
        if (hasRefferalCode) points.points = points.pointsWithRefferalCode;
      }
    } else {
      points = permanentSelectorToPoints[selector];
      isOneTime = false;
    }
    if (points.callback != bytes4('')) {
      (bool ok, bytes memory callbackResult) = refferalLib.staticcall(
        abi.encodeWithSelector(points.callback, points.points, callbackArgs)
      );
      require(ok, 'Fail to calculate points');
      points.points = abi.decode(callbackResult, (int));
    }
    return (points.points, isOneTime);
  }

  function getEmptyToClaim() public view returns(Schemas.ReadyToClaim[] memory) {
  
   Schemas.ReadyToClaim[] memory programs;
    uint counter = 0;
    uint max = uint(type(Schemas.RefferalProgram).max) + 1;
for (uint i = 0; i < max; i++) {
    Schemas.RefferalProgram program = Schemas.RefferalProgram(i);

    if (selectorToPoints[program].points != 0) 
        counter += 1;
    
    if (permanentSelectorToPoints[program].points != 0) 
        counter += 1;
    
}
    programs = new Schemas.ReadyToClaim[](counter);
    uint index = 0;
      for (uint i = 0; i < max; i++ ) {
      if(permanentSelectorToPoints[Schemas.RefferalProgram(i)].points != 0)
      {
        programs[index].refType = Schemas.RefferalProgram(i);
        programs[index].oneTime = false;
        index += 1;
      }
  
    }
       for (uint i = 0; i < max; i++ ) {
      if(selectorToPoints[Schemas.RefferalProgram(i)].points != 0)
      {
        programs[index].refType = Schemas.RefferalProgram(i);
        programs[index].oneTime = true;
        index += 1;
      }
  
    }
    return programs;
  
  }

  function _isOneTimeProgramExists(Schemas.RefferalProgram selector) internal view returns (bool) {
    return selectorToPoints[selector].points != 0;
  }

  function _isPermanentProgramExists(Schemas.RefferalProgram selector) internal view returns (bool) {
    return permanentSelectorToPoints[selector].points != 0;
  }
}
