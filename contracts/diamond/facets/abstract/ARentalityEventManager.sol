// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "../../../Schemas.sol";

abstract contract ARentalityEventManager {
  event RentalityEvent(
    Schemas.EventType indexed eType,
    uint256 id,
    uint8 objectStatus,
    address indexed from,
    address indexed to,
    uint timestamp
  );
  function emitEvent(Schemas.EventType eType, uint256 id, uint8 objectStatus, address from, address to) internal {
    emit RentalityEvent(eType, id, objectStatus, from, to, block.timestamp);
  }
}