// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../models/common/CommonTypes.sol';
import '../upgradeable/UUPSOwnable.sol';

interface IRentalityNotificationAccess {
  function isRentalityPlatform(address user) external view returns (bool);
}

struct RentalityEventInfo {
  EventType eType;
  uint256 id;
  uint8 objectStatus;
  address from;
  address to;
}

contract RentalityNotificationService is UUPSOwnable {
  IRentalityNotificationAccess public userAccess;

  event RentalityEvent(
    EventType indexed eType,
    uint256 id,
    uint8 objectStatus,
    address indexed from,
    address indexed to,
    uint256 timestamp
  );

  constructor() {
    _disableInitializers();
  }

  function initialize(address userAccessAddress) public initializer {
    __Ownable_init();
    userAccess = IRentalityNotificationAccess(userAccessAddress);
  }

  function emitEvent(EventType eType, uint256 id, uint8 objectStatus, address from, address to) public {
    require(userAccess.isRentalityPlatform(msg.sender), 'only Rentality platform');
    emit RentalityEvent(eType, id, objectStatus, from, to, block.timestamp);
  }

  function emitAll(RentalityEventInfo[] memory events) public {
    require(userAccess.isRentalityPlatform(msg.sender), 'only Rentality platform');
    for (uint256 i = 0; i < events.length; i++) {
      emit RentalityEvent(events[i].eType, events[i].id, events[i].objectStatus, events[i].from, events[i].to, block.timestamp);
    }
  }

  function updateUserAccess(address userAccessAddress) external onlyOwner {
    userAccess = IRentalityNotificationAccess(userAccessAddress);
  }
}
