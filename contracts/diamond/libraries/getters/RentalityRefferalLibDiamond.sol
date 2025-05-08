// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {RefferalServiceStorage} from "../RefferalServiceStorage.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Schemas} from "../../../Schemas.sol";
import {CarTokenStorage} from "../CarTokenStorage.sol";


        
library RentalityRefferalLibDiamond {
   
function finishTrip(int points, bytes memory data) public pure returns (int) {
    (uint64 startDateTime, uint64 endDateTime) = abi.decode(data, (uint64, uint64));
    uint64 duration = endDateTime - startDateTime;
    return points * int(Math.ceilDiv(duration, 1 days));
  }

  function updateCar(int points, bytes memory data) public pure returns (int) {
    (bool wasListed, bool toBeListed) = abi.decode(data, (bool, bool));
    if (!wasListed) return 0;
    if (!toBeListed) return points;

    return 0;
  }
  function calculateListedCarsPoints(
    int points,
    address user
  ) internal view returns (uint, uint[] memory) {
    CarTokenStorage.CarTokenFaucetStorage storage carServiceStorage = CarTokenStorage.accessStorage();
    RefferalServiceStorage.RefferalFaucetStorage storage RefferalServiceStorage = RefferalServiceStorage.accessStorage();
    uint totalPoints = 0;
    uint counter = 0;
    uint carTotalSupply = carServiceStorage._carIdCounter;
    if (carServiceStorage._balances[user] == 0) return (0, new uint[](0));
    for (uint i = 1; i <= carTotalSupply; i++) {
      if (CarTokenStorage.ownerOf(i) == user) {
        uint listingMoment = carServiceStorage.carIdToListingMoment[i];
        if (listingMoment != 0) {
          uint updateTime = RefferalServiceStorage.carIdToDailyClaimed[i];
          if (updateTime > listingMoment) listingMoment = updateTime;

          uint duration = block.timestamp - listingMoment;
          uint pointsToGet = duration == 0 ? 0 : uint(points) * (duration / 1 days);
          if (pointsToGet > 0) {
            totalPoints += pointsToGet;
            counter += 1;
          }
        }
      }
    }
    uint[] memory carIds = new uint[](counter);
    uint index = 0;
    for (uint i = 1; i <= carTotalSupply; i++) {
      if (CarTokenStorage.ownerOf(i) == user) {
        uint listingMoment = carServiceStorage.carIdToListingMoment[i];
        if (listingMoment != 0) {
          uint updateTime = RefferalServiceStorage.carIdToDailyClaimed[i];
          if (updateTime > listingMoment) listingMoment = updateTime;
          uint duration = block.timestamp - listingMoment;
          uint pointsToGet = duration == 0 ? 0 : uint(points) * (duration / 1 days);
          if (pointsToGet > 0) {
            carIds[index] = i;
            index += 1;
          }
        }
      }
    }
    return (totalPoints, carIds);
  }


    function _checkDaily(address user) internal view returns (uint) {
    RefferalServiceStorage.RefferalFaucetStorage storage RefferalServiceStorage = RefferalServiceStorage.accessStorage();
    uint result = 0;
    uint last = RefferalServiceStorage.addressToLastDailyClaim[user];
    uint current = block.timestamp;
    if (current >= last + 1 days) {
      result = uint(RefferalServiceStorage.permanentSelectorToPoints[Schemas.RefferalProgram.Daily].points);
    }
    return result;
  }



}