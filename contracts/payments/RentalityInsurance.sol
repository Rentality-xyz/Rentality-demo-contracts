// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../proxy/UUPSAccess.sol';
import '../Schemas.sol';
import '../RentalityCarToken.sol';

contract RentalityInsurance is Initializable, UUPSAccess {
  mapping(uint => uint) public carIdToInsurance;
  RentalityCarToken private carService;

  function saveInsurance(uint carId, uint priceInUsdCents) public {
    require(userService.isManager(msg.sender), 'Only Manager');
    require(carService.ownerOf(carId) == tx.origin, 'For car owner');

    carIdToInsurance[carId] = priceInUsdCents;
  }
}
