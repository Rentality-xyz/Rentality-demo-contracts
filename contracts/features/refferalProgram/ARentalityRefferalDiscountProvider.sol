// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../../abstract/IRentalityAccessControl.sol';
import '../../Schemas.sol';
import {ARentalityRefferal} from './ARentalityRefferal.sol';

abstract contract ARentalityRefferalDiscountProvider is ARentalityRefferal {
  mapping(Schemas.RefferalProgram => mapping(Schemas.Tear => Schemas.RefferalDiscount))
    internal selectorToDiscountsPercentsToConstInPoints;

  function manageRefferalDiscount(
    Schemas.RefferalProgram selector,
    Schemas.Tear tear,
    uint points,
    uint percents
  ) public {
    require(getUserService().isManager(msg.sender), 'only Manager');
    selectorToDiscountsPercentsToConstInPoints[selector][tear] = Schemas.RefferalDiscount(points, percents);
  }
  function getDiscount(Schemas.RefferalProgram selector, Schemas.Tear tear) public returns (uint, uint) {
    Schemas.RefferalDiscount memory discount = selectorToDiscountsPercentsToConstInPoints[selector][tear];
    return (discount.percents, discount.pointsCosts);
  }
}
