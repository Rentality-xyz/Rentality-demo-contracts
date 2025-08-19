// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import {IRentalityAccessControl} from '../abstract/IRentalityAccessControl.sol';
import {UUPSAccess} from '../proxy/UUPSAccess.sol';
import '../Schemas.sol';


struct RentaityEvent {
    Schemas.EventType eType;
    uint256 id;
    uint8 objectStatus;
    address from;
    address to;
}

contract RentalityNotificationService is UUPSAccess, Initializable {
  /// @notice Rentality event for all types of сontracts
  /// eType: Type of event, represent smart contract, where it heppens
  /// id of object (trip id/car id/claim id)
  /// parsed to uint8 object new status (uint8(Schemas.TripStatus))
  event RentalityEvent(
    Schemas.EventType indexed eType,
    uint256 id,
    uint8 objectStatus,
    address indexed from,
    address indexed to,
    uint timestamp
  );

  function emitEvent(Schemas.EventType eType, uint256 id, uint8 objectStatus, address from, address to) public {
    require(userService.isRentalityPlatform(msg.sender), 'only Rentality platform');
    emit RentalityEvent(eType, id, objectStatus, from, to, block.timestamp);
  }

  function emitAll(RentaityEvent[] memory events) public {
    for (uint i = 0; i < events.length; i++) {
    emit RentalityEvent(events[i].eType, events[i].id, events[i].objectStatus, events[i].from, events[i].to, block.timestamp);
    }
  }

  /// @param userServiceAddress The address of the RentalityUserService contract.
  function initialize(address userServiceAddress) public initializer {
    userService = IRentalityAccessControl(userServiceAddress);
  }
}
