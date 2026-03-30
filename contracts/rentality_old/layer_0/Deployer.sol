// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import './RentalitySender.sol';

contract RentalityDeployer is Ownable {
  bytes private salt;
  address private sender;
  constructor() Ownable() {}

  function initialize(bytes32 salt, address owner, bytes memory init) public payable returns (address r) {
    _transferOwnership(owner);
    r = address(new RentalitySender{salt: salt}());
    sender = r;
    (bool success, ) = r.call(init);
    require(success, 'Fail to deploy');
  }

  function getDeployedAddress() public view returns (address s) {
    s = sender;
  }

  function destruct() public {
    return selfdestruct(payable(owner()));
  }
}
