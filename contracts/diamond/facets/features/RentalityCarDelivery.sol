// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Schemas} from "../../../Schemas.sol";
import { DeliveryStorage } from "../../libraries/DeliveryStorage.sol";
import { UserServiceStorage } from "../../libraries/UserServiceStorage.sol";

contract RentalityCarDeliveryFacet {


  /// @notice Sets delivery prices for a user
  /// @param underTwentyFiveMilesInUsdCents Price in USD cents for distances under 25 miles
  /// @param aboveTwentyFiveMilesInUsdCents Price in USD cents for distances above 25 miles
  function addUserDeliveryPrices(
    uint64 underTwentyFiveMilesInUsdCents,
    uint64 aboveTwentyFiveMilesInUsdCents
  ) public {
    address user = msg.sender;
    DeliveryStorage.DeliveryFaucetStorage storage s = DeliveryStorage.accessStorage();
    if (!UserServiceStorage.isHost(user)) {
      UserServiceStorage.grantHostRole(user);
    }
    s.userToDeliveryPrice[user] = Schemas.DeliveryPrices(
      underTwentyFiveMilesInUsdCents,
      aboveTwentyFiveMilesInUsdCents,
      true
    );
  }

   /// @notice Retrieves delivery prices for a user
  /// @param user Address of the user
  /// @return DeliveryPrices struct containing the user's delivery prices
  function getUserDeliveryPrices(address user) public view returns (Schemas.DeliveryPrices memory) {
   return DeliveryStorage.getUserDeliveryPrices(user);
  }


}